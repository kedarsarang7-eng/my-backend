// License Service - Enterprise License Validation & Management
// Handles license validation, activation, and offline-first caching
//
// SECURITY NOTES:
// - All license checks are performed both locally AND remotely
// - Offline grace period of 7 days before requiring online validation
// - Device fingerprint must match for license to be valid
// - Business type must match exactly - wrong type = app blocked

import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../models/business_type.dart';
import 'device_fingerprint_service.dart';

/// License validation result
enum LicenseStatus {
  valid,
  expired,
  suspended,
  blocked,
  deviceMismatch,
  businessTypeMismatch,
  notFound,
  networkError,
  offlineGraceExpired,
}

/// Result of license validation
class LicenseValidationResult {
  final bool isValid;
  final LicenseStatus status;
  final String? message;
  final LicenseCacheEntity? license;
  final List<String> enabledModules;
  final int? daysUntilExpiry;
  final bool isOfflineValidation;

  const LicenseValidationResult({
    required this.isValid,
    required this.status,
    this.message,
    this.license,
    this.enabledModules = const [],
    this.daysUntilExpiry,
    this.isOfflineValidation = false,
  });

  factory LicenseValidationResult.invalid(
    LicenseStatus status, [
    String? message,
  ]) =>
      LicenseValidationResult(
        isValid: false,
        status: status,
        message: message,
      );

  factory LicenseValidationResult.valid({
    required LicenseCacheEntity license,
    required List<String> enabledModules,
    int? daysUntilExpiry,
    bool isOfflineValidation = false,
  }) =>
      LicenseValidationResult(
        isValid: true,
        status: LicenseStatus.valid,
        license: license,
        enabledModules: enabledModules,
        daysUntilExpiry: daysUntilExpiry,
        isOfflineValidation: isOfflineValidation,
      );
}

/// License activation result
class LicenseActivationResult {
  final bool isSuccess;
  final String? errorCode;
  final String? errorMessage;
  final LicenseCacheEntity? license;

  const LicenseActivationResult({
    required this.isSuccess,
    this.errorCode,
    this.errorMessage,
    this.license,
  });

  factory LicenseActivationResult.success(LicenseCacheEntity license) =>
      LicenseActivationResult(isSuccess: true, license: license);

  factory LicenseActivationResult.failure(String errorCode, String message) =>
      LicenseActivationResult(
        isSuccess: false,
        errorCode: errorCode,
        errorMessage: message,
      );
}

/// Enterprise License Service
class LicenseService {
  final AppDatabase _db;
  final FirebaseFunctions _functions;
  final DeviceFingerprintService _fingerprintService;

  // API endpoints (configure in production)
  // static const String _apiBaseUrl = 'https://api.dukanx.com/v1';

  LicenseService(
    this._db, {
    FirebaseFunctions? functions,
    DeviceFingerprintService? fingerprintService,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _fingerprintService = fingerprintService ?? DeviceFingerprintService();

// ... (skipping to sendHeartbeat) ...

  /// Send periodic heartbeat to update license status
  Future<void> sendHeartbeat() async {
    try {
      final license = await _getCachedLicense();
      if (license == null) return;

      // final fingerprint = await _fingerprintService.getFingerprint();

      // Call heartbeat API
      // In production, this updates last_seen_at and validates license
      // For now, just update local timestamp
      await _updateLastValidated(license.id);
    } catch (e) {
      debugPrint('LicenseService: Heartbeat error: $e');
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get cached license from local database
  Future<LicenseCacheEntity?> _getCachedLicense() async {
    try {
      final query = _db.select(_db.licenseCache);
      final results = await query.get();
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      debugPrint('LicenseService: Cache read error: $e');
      return null;
    }
  }

  /// Cache license in local database
  Future<LicenseCacheEntity> _cacheLicense({
    required String licenseKey,
    required String businessType,
    required String fingerprint,
    required Map<String, dynamic> response,
  }) async {
    final now = DateTime.now();
    final id = const Uuid().v4();

    // Parse response data
    final expiryDate = DateTime.parse(response['expiryDate'] ??
        now.add(const Duration(days: 365)).toIso8601String());
    final enabledModules =
        jsonEncode(response['enabledModules'] ?? ['billing', 'inventory']);

    // Generate validation token
    final tokenData = '$licenseKey|$fingerprint|${now.toIso8601String()}';
    final token = _generateToken(tokenData);
    final signature = _signToken(token);

    await _db.into(_db.licenseCache).insert(
          LicenseCacheCompanion.insert(
            id: id,
            licenseKey: licenseKey,
            businessType: businessType,
            customerId: Value(response['customerId']),
            enabledModulesJson: Value(enabledModules),
            issueDate: now,
            expiryDate: expiryDate,
            deviceFingerprint: fingerprint,
            deviceId: Value(response['deviceId']),
            lastValidatedAt: now,
            validationToken: token,
            tokenSignature: signature,
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Fetch and return the created entity
    return (await _getCachedLicense())!;
  }

  /// Remove cached license
  Future<void> _removeCachedLicense() async {
    try {
      await _db.delete(_db.licenseCache).go();
    } catch (e) {
      debugPrint('LicenseService: Cache delete error: $e');
    }
  }

  /// Update license status
  Future<void> _updateLicenseStatus(String id, String status) async {
    try {
      await (_db.update(_db.licenseCache)..where((t) => t.id.equals(id)))
          .write(LicenseCacheCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ));
    } catch (e) {
      debugPrint('LicenseService: Status update error: $e');
    }
  }

  /// Update last validated timestamp
  Future<void> _updateLastValidated(String id) async {
    try {
      await (_db.update(_db.licenseCache)..where((t) => t.id.equals(id)))
          .write(LicenseCacheCompanion(
        lastValidatedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(true),
        lastSyncAt: Value(DateTime.now()),
      ));
    } catch (e) {
      debugPrint('LicenseService: Validation update error: $e');
    }
  }

  // ============================================================
  // CLOUD FUNCTION CALLS
  // ============================================================

  /// Call activation API
  Future<Map<String, dynamic>> _callActivationApi({
    required String licenseKey,
    required DeviceFingerprint fingerprint,
    required BusinessType businessType,
  }) async {
    try {
      final callable = _functions.httpsCallable('activateLicense');
      final result = await callable.call({
        'licenseKey': licenseKey,
        'deviceFingerprint': fingerprint.fingerprint,
        'platform': fingerprint.platform,
        'businessType': businessType.name,
        'deviceName': fingerprint.deviceName ??
            'Unknown', // Pass device name if available
      });

      final data = result.data as Map<Object?, Object?>;
      return data.cast<String, dynamic>();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'errorCode': e.code,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'errorCode': 'UNKNOWN',
        'message': e.toString(),
      };
    }
  }

  /// Validate license online
  Future<LicenseValidationResult?> _validateOnline({
    required LicenseCacheEntity cachedLicense,
    required DeviceFingerprint fingerprint,
    required BusinessType businessType,
  }) async {
    try {
      final callable = _functions.httpsCallable('validateLicense');
      final result = await callable.call({
        'licenseKey': cachedLicense.licenseKey,
        'deviceFingerprint': fingerprint.fingerprint,
      });

      final data = result.data as Map<Object?, Object?>;
      final status = data['status'] as String;

      if (status == 'valid') {
        await _updateLastValidated(cachedLicense.id);

        final enabledModules = (data['features'] as List? ?? []).cast<String>();
        // Update local modules if changed?
        // Ideally we should sync changes. For now we use returned modules.

        final expiryDateStr = data['expiryDate'] as String?;
        final expiryDate = expiryDateStr != null
            ? DateTime.parse(expiryDateStr)
            : cachedLicense.expiryDate;

        final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;

        return LicenseValidationResult.valid(
          license:
              cachedLicense, // Might be slightly stale on fields like expiry if not updated locally yet
          enabledModules: enabledModules,
          daysUntilExpiry: daysUntilExpiry,
          isOfflineValidation: false,
        );
      } else {
        // Handle invalid status (blocked, expired, etc)
        await _updateLicenseStatus(cachedLicense.id, status);
        return LicenseValidationResult.invalid(
          _mapStatusString(status),
          data['message'] as String?,
        );
      }
    } catch (e) {
      debugPrint('LicenseService: Online validation error: $e');
      return null; // Fallback to offline if error
    }
  }

  /// Background online validation (non-blocking)
  void _validateOnlineBackground({
    required LicenseCacheEntity cachedLicense,
    required DeviceFingerprint fingerprint,
    required BusinessType businessType,
  }) {
    // Fire and forget - update cache if successful
    Future.microtask(() async {
      try {
        await _validateOnline(
          cachedLicense: cachedLicense,
          fingerprint: fingerprint,
          businessType: businessType,
        );
      } catch (e) {
        // Silently fail for background validation
      }
    });
  }

  LicenseStatus _mapStatusString(String status) {
    switch (status) {
      case 'expired':
        return LicenseStatus.expired;
      case 'blocked':
        return LicenseStatus.blocked;
      case 'suspended':
        return LicenseStatus.suspended;
      case 'device_mismatch':
        return LicenseStatus.deviceMismatch;
      default:
        return LicenseStatus.networkError;
    }
  }

  /// Validate license key format
  bool _isValidLicenseKeyFormat(String key) {
    // Format: APP-{TYPE}-{PLATFORM}-{CODE}-{YEAR}
    // Example: APP-PETROL-DESK-A9F3K-2026
    final pattern = RegExp(
      r'^APP-[A-Z]+-(?:DESK|MOB|BOTH)-[A-Z0-9]{5}-\d{4}$',
      caseSensitive: false,
    );
    return pattern.hasMatch(key.toUpperCase());
  }

  /// Parse modules JSON
  List<String> _parseModules(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// Generate validation token
  String _generateToken(String data) {
    final bytes = utf8.encode(data);
    return base64Encode(bytes);
  }

  /// Sign token with secret
  String _signToken(String token) {
    // In production, use a proper signing key
    const secret = 'dukanx_license_secret_key_v1';
    final data = utf8.encode('$token|$secret');
    return sha256.convert(data).toString();
  }

  /// Check if license needs renewal soon (within 30 days)
  Future<bool> needsRenewalSoon() async {
    try {
      final license = await _getCachedLicense();
      if (license == null) return false;

      final daysUntilExpiry =
          license.expiryDate.difference(DateTime.now()).inDays;
      return daysUntilExpiry <= 30;
    } catch (e) {
      return false;
    }
  }

  /// Get days until license expires
  Future<int?> getDaysUntilExpiry() async {
    try {
      final license = await _getCachedLicense();
      if (license == null) return null;

      return license.expiryDate.difference(DateTime.now()).inDays;
    } catch (e) {
      return null;
    }
  }

  /// Check if currently has valid cached license
  Future<bool> hasValidCachedLicense() async {
    try {
      final license = await _getCachedLicense();
      if (license == null) return false;

      // Check expiry
      if (license.expiryDate.isBefore(DateTime.now())) return false;

      // Check status
      if (license.status != 'active') return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get current license info (for display)
  Future<Map<String, dynamic>?> getLicenseInfo() async {
    try {
      final license = await _getCachedLicense();
      if (license == null) return null;

      return {
        'licenseKey': _maskLicenseKey(license.licenseKey),
        'businessType': license.businessType,
        'status': license.status,
        'expiryDate': license.expiryDate.toIso8601String(),
        'daysUntilExpiry': license.expiryDate.difference(DateTime.now()).inDays,
        'enabledModules': _parseModules(license.enabledModulesJson),
        'lastValidated': license.lastValidatedAt.toIso8601String(),
      };
    } catch (e) {
      return null;
    }
  }

  /// Mask license key for display (show only partial)
  String _maskLicenseKey(String key) {
    if (key.length < 10) return '***';
    return '${key.substring(0, 4)}****${key.substring(key.length - 4)}';
  }
}
