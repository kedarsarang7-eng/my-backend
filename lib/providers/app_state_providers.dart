// ============================================================================
// APP STATE PROVIDERS - RIVERPOD ONLY
// ============================================================================
// Centralized state management using Riverpod
// Replaces Provider completely for consistent architecture
//
// Author: DukanX Engineering
// Version: 1.0.0
// ============================================================================

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added by user
import '../features/onboarding/onboarding_models.dart';

import '../core/di/service_locator.dart';
import '../core/session/session_manager.dart';

import '../core/sync/engine/sync_engine.dart'; // Added
import '../core/sync/models/sync_types.dart'; // Added
import '../core/repository/customers_repository.dart';
import '../core/repository/patients_repository.dart';
import '../core/repository/visits_repository.dart';
// import '../core/sync/sync_manager.dart'; // Removed
import '../models/patient.dart';
import '../models/visit.dart';
import '../core/monitoring/monitoring_service.dart';
import '../core/database/app_database.dart';
import '../core/database/daos/pharmacy_dao.dart';

// ============================================================================
// THEME STATE
// ============================================================================

import 'package:google_fonts/google_fonts.dart';

class AppColorPalette {
  final String name;
  final Color leafGreen;
  final Color sunYellow;
  final Color tomatoRed;
  final Color royalBlue;
  final Color offWhite;
  final Color creamCard;
  final Color mutedGray;
  final Color darkGray;

  Color get textPrimary => mutedGray;
  Color get skyBlue => const Color(0xFF38BDF8); // Light Blue 400
  Color get glassBorder => darkGray.withOpacity(0.1);
  Color get subtleSurface => creamCard.withOpacity(0.5);

  const AppColorPalette({
    required this.name,
    required this.leafGreen,
    required this.sunYellow,
    required this.tomatoRed,
    required this.royalBlue,
    required this.offWhite,
    required this.creamCard,
    required this.mutedGray,
    required this.darkGray,
  });

  static const fresh = AppColorPalette(
    name: 'Fresh Market',
    leafGreen: Color(0xFF0EA5E9), // Ocean Blue
    sunYellow: Color(0xFFFFC107), // Amber 500
    tomatoRed: Color(0xFFEF4444), // Red 500
    royalBlue: Color(0xFF2563EB), // Blue 600
    offWhite: Color(0xFFF8FAFC), // Slate 50
    creamCard: Color(0xFFFFFFFF),
    mutedGray: Color(0xFF1E293B), // Slate 800
    darkGray: Color(0xFF64748B), // Slate 500
  );

  static const ocean = AppColorPalette(
    name: 'Ocean Vibes',
    leafGreen: Color(0xFF0284C7), // Sky 600
    sunYellow: Color(0xFFF59E0B), // Amber 600
    tomatoRed: Color(0xFFDC2626), // Red 600
    royalBlue: Color(0xFF0369A1), // Sky 700
    offWhite: Color(0xFFF0F9FF), // Sky 50
    creamCard: Color(0xFFFFFFFF),
    mutedGray: Color(0xFF0C4A6E), // Sky 900
    darkGray: Color(0xFF7DD3FC), // Sky 300
  );

  static const sunset = AppColorPalette(
    name: 'Sunset Glow',
    leafGreen: Color(0xFF7C3AED), // Violet 600
    sunYellow: Color(0xFFDB2777), // Pink 600
    tomatoRed: Color(0xFFBE123C), // Rose 700
    royalBlue: Color(0xFF9333EA), // Purple 600
    offWhite: Color(0xFFFFF1F2), // Rose 50
    creamCard: Color(0xFFFFFFFF),
    mutedGray: Color(0xFF4C0519), // Rose 900
    darkGray: Color(0xFFFDA4AF), // Rose 300
  );

  static const futuristic = AppColorPalette(
    name: 'DukanX Premium',
    leafGreen: Color(0xFF6366F1), // Indigo 500 (Primary)
    sunYellow: Color(0xFFF59E0B), // Amber 500 (Warning)
    tomatoRed: Color(0xFFF97316), // Orange 500 (Error)
    royalBlue: Color(0xFF0EA5E9), // Sky 500 (Accent)
    offWhite: Color(0xFFF8FAFC), // Slate 50
    creamCard: Color(0xFFFFFFFF),
    mutedGray: Color(0xFF0F172A), // Slate 900
    darkGray: Color(0xFF64748B), // Slate 500
  );

  static const List<AppColorPalette> all = [futuristic, fresh, ocean, sunset];
}

class ThemeState {
  final bool isDark;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final AppColorPalette palette;

  ThemeState({
    required this.isDark,
    required this.lightTheme,
    required this.darkTheme,
    required this.palette,
  });

  ThemeState copyWith({
    bool? isDark,
    AppColorPalette? palette,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) {
    return ThemeState(
      isDark: isDark ?? this.isDark,
      palette: palette ?? this.palette,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
    );
  }
}

class ThemeStateNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    // Default initial state
    final defaultPalette = AppColorPalette.futuristic;
    return ThemeState(
      isDark: false,
      palette: defaultPalette,
      lightTheme: _buildTheme(false, defaultPalette),
      darkTheme: _buildTheme(true, defaultPalette),
    );
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('theme_dark') ?? false;

    // We could load palette from prefs too if we saved it
    // For now defaulting to futuristic as per legacy code

    state = ThemeState(
      isDark: isDark,
      palette: state.palette,
      lightTheme: _buildTheme(isDark, state.palette),
      darkTheme: _buildTheme(true, state.palette), // Dark theme is always dark
    );
  }

  Future<void> toggleTheme() async {
    final newValue = !state.isDark;
    state = state.copyWith(
      isDark: newValue,
      lightTheme: _buildTheme(newValue, state.palette),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_dark', newValue);
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(
      isDark: value,
      lightTheme: _buildTheme(value, state.palette),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_dark', value);
  }

  // Ported from legacy ThemeProvider to ensure matching UI
  ThemeData _buildTheme(bool isDark, AppColorPalette palette) {
    // Note: We are simplifying slightly by not passing Locale here for fonts
    // If dynamic language fonts are critical, we need to inject LocaleState
    // For this migration, we'll use the default Google Font (Outfit)

    final baseTextTheme = GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: palette.mutedGray,
          letterSpacing: -1,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: palette.mutedGray,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: palette.mutedGray,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: palette.mutedGray,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: palette.darkGray,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
      ),
    );

    if (isDark) {
      return ThemeData.dark(useMaterial3: true).copyWith(
        textTheme: baseTextTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        primaryColor: palette.leafGreen,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B), // Slate 800
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.dark(
          primary: palette.leafGreen,
          secondary: palette.sunYellow,
          error: palette.tomatoRed,
          surface: const Color(0xFF1E293B),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF334155),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: palette.leafGreen,
        scaffoldBackgroundColor: palette.offWhite,
        textTheme: baseTextTheme,
        colorScheme: ColorScheme.fromSeed(
          seedColor: palette.royalBlue,
          brightness: Brightness.light,
          primary: palette.leafGreen,
          secondary: palette.sunYellow,
          error: palette.tomatoRed,
          surface: palette.creamCard,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: palette.offWhite,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: palette.textPrimary,
        ),
        cardTheme: CardThemeData(
          color: palette.creamCard,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

final themeStateProvider = NotifierProvider<ThemeStateNotifier, ThemeState>(() {
  final notifier = ThemeStateNotifier();
  // Side effect: load settings immediately if possible
  // In Riverpod 2.x, async initialization is better handled by explicit calls
  // or AsyncNotifier. For now, we fire and forget the load.
  notifier.loadSettings();
  return notifier;
});

// ============================================================================
// LOCALE STATE
// ============================================================================

class LocaleState {
  final Locale locale;

  LocaleState({required this.locale});

  LocaleState copyWith({Locale? locale}) {
    return LocaleState(locale: locale ?? this.locale);
  }
}

class LocaleStateNotifier extends Notifier<LocaleState> {
  @override
  LocaleState build() {
    _loadFromPrefs();
    return LocaleState(locale: const Locale('en'));
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Check for new key first
    if (prefs.containsKey('locale')) {
      final langCode = prefs.getString('locale') ?? 'en';
      state = state.copyWith(locale: Locale(langCode));
      return;
    }

    // Fallback/Migrate from legacy key 'app_locale' or 'app_language' (OnboardingService key)
    // OnboardingService uses 'app_language', LocaleProvider used 'app_locale'
    String? legacyName =
        prefs.getString('app_locale') ?? prefs.getString('app_language');

    if (legacyName != null) {
      try {
        final appLang = AppLanguage.values.firstWhere(
            (l) => l.name == legacyName,
            orElse: () => AppLanguage.english);

        final config = LanguageConfig.all.firstWhere(
            (c) => c.language == appLang,
            orElse: () => LanguageConfig.all.first);

        // Save to new key for future
        await prefs.setString('locale', config.code);
        state = state.copyWith(locale: Locale(config.code));
        return;
      } catch (e) {
        debugPrint('Error migrating locale: $e');
      }
    }

    // Default
    state = state.copyWith(locale: const Locale('en'));
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }
}

final localeStateProvider =
    NotifierProvider<LocaleStateNotifier, LocaleState>(LocaleStateNotifier.new);

// ============================================================================
// AUTH STATE
// ============================================================================

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final UserSession? session;
  final bool isLoading;

  AuthState({
    required this.status,
    this.user,
    this.session,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    UserSession? session,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isOwner => session?.isOwner ?? false;
  bool get isCustomer => session?.isCustomer ?? false;
  String? get userId => session?.odId ?? user?.uid;
  String? get ownerId => session?.ownerId;
}

class AuthStateNotifier extends Notifier<AuthState> {
  late SessionManager _sessionManager;

  @override
  AuthState build() {
    _sessionManager = sl<SessionManager>();
    _init();
    return AuthState(status: AuthStatus.unknown);
  }

  void _init() {
    // Listen to Firebase auth changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          session: null,
        );
      } else {
        // Get session from SessionManager
        final session = _sessionManager.currentSession;
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          session: session.isAuthenticated ? session : null,
        );
      }
    });

    // Listen to session changes
    _sessionManager.addListener(() {
      final session = _sessionManager.currentSession;
      if (session.isAuthenticated) {
        state = state.copyWith(session: session);
      }
    });
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _sessionManager.signOut();
      state = AuthState(status: AuthStatus.unauthenticated);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshSession() async {
    await _sessionManager.refreshSession();
    final session = _sessionManager.currentSession;
    state = state.copyWith(session: session);
  }
}

final authStateProvider =
    NotifierProvider<AuthStateNotifier, AuthState>(AuthStateNotifier.new);

// ============================================================================
// CUSTOMERS STATE
// ============================================================================

class CustomersState {
  final List<Customer> customers;
  final bool isLoading;
  final String? error;

  CustomersState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
  });

  CustomersState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? error,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final customersStreamProvider =
    StreamProvider.family<List<Customer>, String?>((ref, userId) {
  if (userId == null || userId.isEmpty) {
    return const Stream.empty();
  }
  return sl<CustomersRepository>().watchAll(userId: userId);
});

final patientsStreamProvider =
    StreamProvider.family<List<Patient>, String?>((ref, userId) async* {
  if (userId == null || userId.isEmpty) {
    yield [];
    return;
  }
  final result = await sl<PatientsRepository>().search('', userId: userId);
  if (result.isSuccess && result.data != null) {
    yield result.data!;
  } else {
    yield [];
  }
});

final todaysVisitsProvider =
    FutureProvider.autoDispose<List<Visit>>((ref) async {
  final user = ref.watch(authStateProvider).user;
  if (user == null) return [];

  final repo = sl<VisitsRepository>();
  final result = await repo.getDailyVisits(user.uid, DateTime.now());

  if (result.isSuccess) {
    return result.data ?? [];
  }
  return [];
});

// ============================================================================
// SYNC STATUS
// ============================================================================

final syncStatusProvider = StreamProvider<SyncStats>((ref) {
  return SyncEngine.instance.statsStream;
});

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final items = await sl<AppDatabase>().getPendingSyncEntries();
  return items.length;
});

// ============================================================================
// BUSINESS TYPE
// ============================================================================

// ENUM MOVED TO lib/models/business_type.dart

class BusinessTypeState {
  final BusinessType type;
  final String? customName;

  BusinessTypeState({
    this.type = BusinessType.other,
    this.customName,
  });

  BusinessTypeState copyWith({BusinessType? type, String? customName}) {
    return BusinessTypeState(
      type: type ?? this.type,
      customName: customName ?? this.customName,
    );
  }

  String get displayName => type.displayName;

  // Feature Flags
  bool get showExpiry =>
      type == BusinessType.pharmacy || type == BusinessType.wholesale;
  bool get showBatch =>
      type == BusinessType.pharmacy || type == BusinessType.wholesale;
  bool get showTableInfo => type == BusinessType.restaurant;
  bool get showDimensions => type == BusinessType.hardware;
  bool get showServiceDetails => type == BusinessType.service;
  bool get showWeight =>
      type == BusinessType.grocery || type == BusinessType.wholesale;
  bool get isPetrolPump => type == BusinessType.petrolPump;
  bool get isClinic => type == BusinessType.clinic;
}

class BusinessTypeNotifier extends Notifier<BusinessTypeState> {
  @override
  BusinessTypeState build() {
    _loadFromPrefs();
    return BusinessTypeState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Attempt to read as String first (New Standard)
    try {
      final typeName = prefs.getString('business_type');
      if (typeName != null) {
        // Handle migration if needed, similar to OnboardingService
        // But since we use same core enum, mapping is simple logic if we want to be safe
        // For now, assume simple mapping or default
        try {
          final type = BusinessType.values.byName(typeName);
          state = BusinessTypeState(
            type: type,
            customName: prefs.getString('business_custom_name'),
          );
          return;
        } catch (_) {
          // Fallback if name doesn't match
        }
      }
    } catch (e) {
      // Might be int (Legacy)
    }

    // Fallback: Try reading as Int (Legacy)
    try {
      final typeIndex = prefs.getInt('business_type');
      if (typeIndex != null &&
          typeIndex >= 0 &&
          typeIndex < BusinessType.values.length) {
        state = BusinessTypeState(
          type: BusinessType.values[typeIndex],
          customName: prefs.getString('business_custom_name'),
        );
        // Auto-migrate to string?
        // await setBusinessType(state.type, customName: state.customName);
        // Better not to trigger write in read, but good for lazy migration
        return;
      }
    } catch (_) {}

    // Default
    state = BusinessTypeState(
      type: BusinessType.other,
      customName: prefs.getString('business_custom_name'),
    );
  }

  Future<void> setBusinessType(BusinessType type, {String? customName}) async {
    state = BusinessTypeState(type: type, customName: customName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('business_type', type.name);
    if (customName != null) {
      await prefs.setString('business_custom_name', customName);
    }
  }
}

final businessTypeProvider =
    NotifierProvider<BusinessTypeNotifier, BusinessTypeState>(
        BusinessTypeNotifier.new);

// ============================================================================
// APP DATABASE PROVIDER (for direct access if needed)
// ============================================================================

final appDatabaseProvider =
    Provider<AppDatabase>((ref) => AppDatabase.instance);

// Modular DAOs
final pharmacyDaoProvider = Provider<PharmacyDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PharmacyDao(db);
});

// ============================================================================
// MONITORING PROVIDER
// ============================================================================

final monitoringProvider = Provider<MonitoringService>((ref) {
  return monitoring;
});

// ============================================================================
// SETTINGS STATE (Dashboard Mode & Profile)
// ============================================================================

class SettingsState {
  final bool isOwnerDashboard;
  final String? userName;
  final String? profileImageUrl;
  final bool isLoading;

  SettingsState({
    this.isOwnerDashboard = true,
    this.userName,
    this.profileImageUrl,
    this.isLoading = false,
  });

  SettingsState copyWith({
    bool? isOwnerDashboard,
    String? userName,
    String? profileImageUrl,
    bool? isLoading,
  }) {
    return SettingsState(
      isOwnerDashboard: isOwnerDashboard ?? this.isOwnerDashboard,
      userName: userName ?? this.userName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsStateNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadFromPrefs();
    return SettingsState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isOwner = prefs.getBool('is_owner_dashboard') ?? true;
    final name = prefs.getString('user_name');
    final image = prefs.getString('profile_image_url');

    // Also sync from Firestore if user is logged in (background)
    unawaited(_syncFromFirestore(prefs));

    state = state.copyWith(
      isOwnerDashboard: isOwner,
      userName: name,
      profileImageUrl: image,
    );
  }

  Future<void> setDashboardMode(bool isOwner) async {
    final session = sl<SessionManager>();
    if (!isOwner && session.isOwner) {
      // Owner switching to Customer view - Allowed
    } else if (isOwner && session.isOwner) {
      // Owner switching to Owner view - Allowed
    } else if (isOwner && session.isCustomer) {
      // Customer trying to access Owner view - BLOCKED
      final context = sl<GlobalKey<NavigatorState>>().currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Permission Denied: Customers cannot access Owner Dashboard.')));
      }
      return;
    }

    state = state.copyWith(isOwnerDashboard: isOwner);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_owner_dashboard', isOwner);
  }

  Future<void> setUserName(String name) async {
    state = state.copyWith(userName: name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      unawaited(
          FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
      }, SetOptions(merge: true)));
    }
  }

  Future<void> updateProfileImage(String url) async {
    state = state.copyWith(profileImageUrl: url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_url', url);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      unawaited(
          FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profileImageUrl': url,
      }, SetOptions(merge: true)));
    }
  }

  Future<void> _syncFromFirestore(SharedPreferences prefs) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final name = data['name'] as String?;
          final image = data['profileImageUrl'] as String?;

          if (name != null) {
            unawaited(prefs.setString('user_name', name));
          }
          if (image != null) {
            unawaited(prefs.setString('profile_image_url', image));
          }

          state = state.copyWith(userName: name, profileImageUrl: image);
        }
      }
    } catch (e) {
      // Silent fail on sync
    }
  }
}

final settingsStateProvider =
    NotifierProvider<SettingsStateNotifier, SettingsState>(
        SettingsStateNotifier.new);
// Convenience provider for current user (Firebase User)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});
