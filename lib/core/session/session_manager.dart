// ============================================================================
// SESSION MANAGER - CENTRALIZED AUTH STATE
// ============================================================================
// Singleton service for managing user authentication state
// Injected via DI - NEVER instantiated directly
// Consistent auth state across entire app
//
// CRITICAL: Role is IMMUTABLE after first assignment
// Role stored in: users/{uid}.role with roleLocked=true
//
import '../../models/business_type.dart';
export '../../models/business_type.dart';

// Version: 3.0.0 - Role Fix
// ============================================================================

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_intent_service.dart';

/// User role in the system
/// CRITICAL: 'unknown' is ONLY used for unauthenticated state - NEVER after signup
enum UserRole { owner, customer, patient, unknown }

/// Application Operation Mode
enum AppMode {
  normal, // Standard mode (Vendor can login, Customer can login)
  customerOnly, // Locked Customer Mode (Vendor login disallowed)
}

// Local storage keys
const String _kRoleKey = 'user_role';
const String _kUserIdKey = 'user_id';
const String _kAppModeKey = 'app_mode';
const String _kLockedVendorIdKey = 'locked_vendor_id';

/// User session data
class UserSession {
  final String odId;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final String?
  ownerId; // For owners, same as odId. For customers, their linked owner
  final BusinessType? businessType; // Single Source of Truth for Business Type
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? metadata;

  // App Mode State
  final AppMode appMode;
  final String? lockedVendorId; // If in customerOnly mode

  const UserSession({
    required this.odId,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.role,
    this.ownerId,
    this.businessType,
    this.lastLoginAt,
    this.metadata,
    this.appMode = AppMode.normal,
    this.lockedVendorId,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isCustomer => role == UserRole.customer;
  bool get isPatient => role == UserRole.patient;
  bool get isAuthenticated => role != UserRole.unknown && odId.isNotEmpty;

  UserSession copyWith({
    String? odId,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    String? ownerId,
    BusinessType? businessType,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
    AppMode? appMode,
    String? lockedVendorId,
  }) {
    return UserSession(
      odId: odId ?? this.odId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      ownerId: ownerId ?? this.ownerId,
      businessType: businessType ?? this.businessType,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
      appMode: appMode ?? this.appMode,
      lockedVendorId: lockedVendorId ?? this.lockedVendorId,
    );
  }

  static const empty = UserSession(odId: '', role: UserRole.unknown);
}

/// Session Manager - Singleton for auth state
class SessionManager extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserSession _currentSession = UserSession.empty;
  StreamSubscription<User?>? _authSubscription;
  bool _isInitialized = false;
  bool _isLoading = false;

  SessionManager({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore {
    _initAppMode(); // Load app mode first
    _initAuthListener();
  }

  /// Load persisted App Mode
  Future<void> _initAppMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_kAppModeKey);
      final vendorId = prefs.getString(_kLockedVendorIdKey);

      if (modeStr == 'customerOnly' && vendorId != null) {
        _currentSession = _currentSession.copyWith(
          appMode: AppMode.customerOnly,
          lockedVendorId: vendorId,
        );
        debugPrint(
          '[SessionManager] App locked to Customer Mode for vendor: $vendorId',
        );
      }
    } catch (e) {
      debugPrint('[SessionManager] Error loading app mode: $e');
    }
  }

  // ============================================
  // PUBLIC GETTERS
  // ============================================

  /// Current user session
  UserSession get currentSession => _currentSession;

  /// Current user ID (Firebase UID)
  String? get userId =>
      _currentSession.isAuthenticated ? _currentSession.odId : null;

  /// Current owner ID (for Firestore paths)
  String? get ownerId => _currentSession.ownerId ?? userId;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentSession.isAuthenticated;

  /// Check if user is an owner
  bool get isOwner => _currentSession.isOwner;

  /// Check if user is a customer
  bool get isCustomer => _currentSession.isCustomer;

  /// Check if user is a patient
  bool get isPatient => _currentSession.isPatient;

  /// Check if session is initialized
  bool get isInitialized => _isInitialized;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Check if App is in Customer-Only Mode
  bool get isCustomerOnlyMode =>
      _currentSession.appMode == AppMode.customerOnly;

  /// Get Locked Vendor ID (if in customerOnly mode)
  String? get lockedVendorId => _currentSession.lockedVendorId;

  /// Get current Firebase user
  User? get firebaseUser => _auth.currentUser;

  // ============================================
  // APP MODE MANAGEMENT
  // ============================================

  /// ENTER Customer-Only Mode (Locked)
  /// Triggers via Deep Link / QR Scan
  Future<void> enterCustomerMode(String vendorId) async {
    if (isCustomerOnlyMode && lockedVendorId == vendorId) return;

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAppModeKey, 'customerOnly');
      await prefs.setString(_kLockedVendorIdKey, vendorId);

      _currentSession = _currentSession.copyWith(
        appMode: AppMode.customerOnly,
        lockedVendorId: vendorId,
      );

      // If currently logged in as Owner, force logout
      if (isOwner) {
        await signOut();
      }

      debugPrint(
        '[SessionManager] Enforced Customer Mode for vendor: $vendorId',
      );
    } catch (e) {
      debugPrint('[SessionManager] Failed to set customer mode: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// EXIT Customer-Only Mode
  /// (Only accessible via Developer/Admin backdoor or clear data)
  Future<void> exitCustomerMode() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAppModeKey);
      await prefs.remove(_kLockedVendorIdKey);

      _currentSession = _currentSession.copyWith(
        appMode: AppMode.normal,
        lockedVendorId: null, // explicit null
      );

      debugPrint('[SessionManager] Exited Customer Mode');
    } catch (e) {
      debugPrint('[SessionManager] Failed to exit customer mode: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // AUTHENTICATION METHODS
  // ============================================

  void _initAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _currentSession = UserSession.empty;
        _isInitialized = true;
        notifyListeners();
      } else {
        await _loadUserSession(user);
      }
    });
  }

  /// Load user session from Firestore
  /// PRIORITY: users/{uid} → owners/{uid} → customers/{uid} → create from intent
  Future<void> _loadUserSession(User user) async {
    _isLoading = true;
    notifyListeners();

    try {
      bool sessionFound = false;
      String? cachedRole;

      // 0. Try local cache first (for offline support)
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedUserId = prefs.getString(_kUserIdKey);
        if (cachedUserId == user.uid) {
          cachedRole = prefs.getString(_kRoleKey);
          debugPrint('[SessionManager] Cached role: $cachedRole');
        }
      } catch (e) {
        debugPrint('[SessionManager] Cache read error: $e');
      }

      // 1. FIRST: Check users collection (single source of truth for role)
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && userDoc.data()?['role'] != null) {
          final data = userDoc.data()!;
          final roleStr = data['role'] as String;
          UserRole role;
          if (roleStr == 'customer') {
            role = UserRole.customer;
          } else if (roleStr == 'patient') {
            role = UserRole.patient;
          } else {
            role = UserRole.owner;
          }

          _currentSession = UserSession(
            odId: user.uid,
            email: user.email,
            displayName: data['name'] ?? user.displayName,
            photoUrl: data['photoUrl'] ?? user.photoURL,
            role: role,
            ownerId: role == UserRole.owner ? user.uid : data['linkedOwnerId'],
            businessType: _parseBusinessType(data['businessType']),
            lastLoginAt: DateTime.now(),
            metadata: data,
          );
          sessionFound = true;

          // Cache role locally
          await _cacheRole(user.uid, roleStr);
          debugPrint('[SessionManager] Role from users collection: $role');
        }
      } catch (e) {
        debugPrint('[SessionManager] users collection error: $e');
      }

      // 2. Try Owners Collection (if not found in users)
      if (!sessionFound) {
        try {
          final ownerDoc = await _firestore
              .collection('owners')
              .doc(user.uid)
              .get();
          if (ownerDoc.exists) {
            final data = ownerDoc.data()!;
            _currentSession = UserSession(
              odId: user.uid,
              email: user.email,
              displayName:
                  data['businessName'] ?? data['name'] ?? user.displayName,
              photoUrl: data['photoUrl'] ?? user.photoURL,
              role: UserRole.owner,
              ownerId: user.uid,
              businessType: _parseBusinessType(data['businessType']),
              lastLoginAt: DateTime.now(),
              metadata: data,
            );
            sessionFound = true;

            // Sync to users collection for future
            await _ensureUserDocument(user.uid, 'owner');
            debugPrint('[SessionManager] Role from owners collection: owner');
          }
        } catch (e) {
          debugPrint('[SessionManager] owners collection error: $e');
        }
      }

      // 3. Try Customers Collection (if still not found)
      if (!sessionFound) {
        try {
          final customerDoc = await _firestore
              .collection('customers')
              .doc(user.uid)
              .get();
          if (customerDoc.exists) {
            final data = customerDoc.data()!;
            _currentSession = UserSession(
              odId: user.uid,
              email: user.email,
              displayName: data['name'] ?? user.displayName,
              photoUrl: data['photoUrl'] ?? user.photoURL,
              role: UserRole.customer,
              ownerId: data['linkedOwnerId'],
              businessType: _parseBusinessType(data['businessType']),
              lastLoginAt: DateTime.now(),
              metadata: data,
            );
            sessionFound = true;

            // Sync to users collection for future
            await _ensureUserDocument(user.uid, 'customer');
            debugPrint(
              '[SessionManager] Role from customers collection: customer',
            );
          }
        } catch (e) {
          debugPrint('[SessionManager] customers collection error: $e');
        }
      }

      // 4. New user - determine role from intent and create atomically
      if (!sessionFound) {
        debugPrint('[SessionManager] New user, checking intent...');
        await authIntent.initialize();

        String roleStr;
        UserRole role;
        String? linkedOwnerId;

        if (authIntent.isVendorIntent) {
          roleStr = 'owner';
          role = UserRole.owner;
          linkedOwnerId = user.uid;
        } else if (authIntent.isCustomerIntent) {
          roleStr = 'customer';
          role = UserRole.customer;
          linkedOwnerId = null;
        } else if (cachedRole != null) {
          // Use cached role if no intent
          roleStr = cachedRole;
          role = cachedRole == 'customer'
              ? UserRole.customer
              : cachedRole == 'patient'
              ? UserRole.patient
              : UserRole.owner;
          linkedOwnerId = role == UserRole.owner ? user.uid : null;
          debugPrint('[SessionManager] Using cached role: $role');
        } else {
          // Default to owner for new users without intent (safety)
          roleStr = 'owner';
          role = UserRole.owner;
          linkedOwnerId = user.uid;
          debugPrint('[SessionManager] No intent, defaulting to owner');
        }

        // ATOMIC WRITE - Create user document with role locked
        await _ensureUserDocument(user.uid, roleStr);

        _currentSession = UserSession(
          odId: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          role: role,
          ownerId: linkedOwnerId,
          lastLoginAt: DateTime.now(),
        );

        debugPrint('[SessionManager] Created new user with role: $role');
      }

      _isInitialized = true;
      debugPrint(
        '[SessionManager] Session loaded: ${_currentSession.role} - ${_currentSession.odId}',
      );
    } catch (e) {
      debugPrint('[SessionManager] Critical error: $e');

      // Try using cached role for offline recovery
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedUserId = prefs.getString(_kUserIdKey);
        final cachedRole = prefs.getString(_kRoleKey);

        if (cachedUserId == user.uid && cachedRole != null) {
          final role = cachedRole == 'customer'
              ? UserRole.customer
              : cachedRole == 'patient'
              ? UserRole.patient
              : UserRole.owner;
          _currentSession = UserSession(
            odId: user.uid,
            email: user.email,
            displayName: user.displayName,
            role: role,
            ownerId: role == UserRole.owner ? user.uid : null,
            lastLoginAt: DateTime.now(),
          );
          _isInitialized = true;
          debugPrint('[SessionManager] Recovered from cache: $role');
          return;
        }
      } catch (_) {}

      // Last resort - use intent if available
      try {
        await authIntent.initialize();
        final role = authIntent.isCustomerIntent
            ? UserRole.customer
            : UserRole.owner;
        _currentSession = UserSession(
          odId: user.uid,
          email: user.email,
          displayName: user.displayName,
          role: role,
          ownerId: role == UserRole.owner ? user.uid : null,
          lastLoginAt: DateTime.now(),
        );
        _isInitialized = true;
        debugPrint('[SessionManager] Emergency fallback: $role');
      } catch (_) {
        // CRITICAL: Even in worst case, use owner role instead of unknown
        _currentSession = UserSession(
          odId: user.uid,
          email: user.email,
          role: UserRole.owner, // NEVER unknown for authenticated users
          ownerId: user.uid,
        );
        _isInitialized = true;
        debugPrint('[SessionManager] Ultimate fallback: owner');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cache role locally for offline access
  Future<void> _cacheRole(String uid, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUserIdKey, uid);
      await prefs.setString(_kRoleKey, role);
      debugPrint('[SessionManager] Role cached: $role');
    } catch (e) {
      debugPrint('[SessionManager] Cache write error: $e');
    }
  }

  /// Ensure user document exists with role locked
  Future<void> _ensureUserDocument(String uid, String role) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final doc = await userRef.get();

      if (!doc.exists) {
        // ATOMIC WRITE - merge: false to prevent overwrite
        await userRef.set({
          'uid': uid,
          'role': role,
          'roleLocked': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[SessionManager] Created user doc with role: $role');
      } else if (doc.data()?['role'] == null) {
        // Update only if role is missing
        await userRef.update({
          'role': role,
          'roleLocked': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[SessionManager] Updated user doc with role: $role');
      }

      // Cache role locally
      await _cacheRole(uid, role);
    } catch (e) {
      debugPrint('[SessionManager] Error ensuring user document: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // Clear cached role
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_kRoleKey);
        await prefs.remove(_kUserIdKey);
      } catch (_) {}

      await _auth.signOut();
      _currentSession = UserSession.empty;
      notifyListeners();
    } catch (e) {
      debugPrint('[SessionManager] Error signing out: $e');
      rethrow;
    }
  }

  /// Switch active shop context for customer
  Future<void> switchShop(String newOwnerId) async {
    final user = _auth.currentUser;
    if (user == null || !isCustomer) return;

    try {
      _isLoading = true;
      notifyListeners();

      // 1. Update Firestore persistence
      await _firestore.collection('users').doc(user.uid).update({
        'linkedOwnerId': newOwnerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update local session state
      _currentSession = _currentSession.copyWith(ownerId: newOwnerId);

      // 3. Update active customer doc if needed (optional sync)
      // This ensures the backend knows which shop is "active" for notifications etc.

      debugPrint('[SessionManager] Switched shop context to: $newOwnerId');
    } catch (e) {
      debugPrint('[SessionManager] Error switching shop: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh current session
  Future<void> refreshSession() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserSession(user);
    }
  }

  /// Update session metadata
  void updateMetadata(Map<String, dynamic> metadata) {
    _currentSession = _currentSession.copyWith(
      metadata: {...?_currentSession.metadata, ...metadata},
    );
    // If business type changed in metadata, update session
    if (metadata.containsKey('businessType')) {
      _currentSession = _currentSession.copyWith(
        businessType: _parseBusinessType(metadata['businessType']),
      );
    }
    notifyListeners();
  }

  /// Get the active Business Type (defaults to Grocery if unknown)
  BusinessType get activeBusinessType =>
      _currentSession.businessType ?? BusinessType.grocery;

  // Helper to parse business type string
  BusinessType _parseBusinessType(dynamic value) {
    if (value == null) return BusinessType.grocery;
    final str = value.toString().toLowerCase();
    for (final type in BusinessType.values) {
      if (type.name.toLowerCase() == str) return type;
    }
    return BusinessType.grocery;
  }

  /// Check if user has permission for owner-only features
  bool hasOwnerPermission() => isOwner;

  /// Get Firestore path prefix for current user
  String get userCollectionPath {
    if (isOwner) {
      return 'owners/$ownerId';
    } else if (isCustomer) {
      return 'customers/${_currentSession.odId}';
    }
    throw StateError('User role not determined');
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
