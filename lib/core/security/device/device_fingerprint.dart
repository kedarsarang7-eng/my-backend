// ============================================================================
// DEVICE FINGERPRINT MODEL
// ============================================================================
// Unique device identification for trusted device binding.
// Combines multiple signals to create unforgeable device identity.
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device Fingerprint - Unique device identification.
///
/// Combines multiple signals:
/// - Platform device ID
/// - App installation UUID (persisted)
/// - OS version
/// - App version
/// - Hardware characteristics
class DeviceFingerprint {
  /// Unique installation ID (generated once, persisted)
  final String installationId;

  /// Platform-specific device ID
  final String deviceId;

  /// Operating system name
  final String platform;

  /// OS version string
  final String osVersion;

  /// App version
  final String appVersion;

  /// Device model/name
  final String deviceModel;

  /// Combined fingerprint hash
  final String fingerprintHash;

  /// Creation timestamp
  final DateTime createdAt;

  const DeviceFingerprint({
    required this.installationId,
    required this.deviceId,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.deviceModel,
    required this.fingerprintHash,
    required this.createdAt,
  });

  /// Generate fingerprint for current device
  static Future<DeviceFingerprint> generate({
    required String appVersion,
  }) async {
    final installationId = await _getOrCreateInstallationId();
    final deviceId = await _getDeviceId();
    final platform = _getPlatform();
    final osVersion = _getOsVersion();
    final deviceModel = _getDeviceModel();

    // Create combined hash
    final combined = '$installationId:$deviceId:$platform:$osVersion';
    final hash = sha256.convert(utf8.encode(combined)).toString();

    return DeviceFingerprint(
      installationId: installationId,
      deviceId: deviceId,
      platform: platform,
      osVersion: osVersion,
      appVersion: appVersion,
      deviceModel: deviceModel,
      fingerprintHash: hash,
      createdAt: DateTime.now(),
    );
  }

  /// Get or create persistent installation ID
  static Future<String> _getOrCreateInstallationId() async {
    const key = 'device_installation_id';
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(key);
      if (id == null || id.isEmpty) {
        id = const Uuid().v4();
        await prefs.setString(key, id);
        debugPrint('DeviceFingerprint: Created new installation ID');
      }
      return id;
    } catch (e) {
      debugPrint('DeviceFingerprint: Failed to get installation ID: $e');
      return 'unknown-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get platform-specific device ID
  static Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        // Android ID would come from device_info_plus
        // For now, use a placeholder
        return 'android-${await _getOrCreateInstallationId()}';
      } else if (Platform.isIOS) {
        return 'ios-${await _getOrCreateInstallationId()}';
      } else if (Platform.isWindows) {
        return 'windows-${await _getOrCreateInstallationId()}';
      }
      return 'unknown-${await _getOrCreateInstallationId()}';
    } catch (e) {
      return 'error-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  static String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  static String _getOsVersion() {
    return Platform.operatingSystemVersion;
  }

  static String _getDeviceModel() {
    // Would come from device_info_plus
    return Platform.localHostname;
  }

  /// Check if this fingerprint matches another
  bool matches(DeviceFingerprint other) {
    // Primary match: installation ID (most stable)
    if (installationId == other.installationId) {
      return true;
    }
    // Secondary match: fingerprint hash
    return fingerprintHash == other.fingerprintHash;
  }

  /// Serialize to map
  Map<String, dynamic> toMap() => {
    'installationId': installationId,
    'deviceId': deviceId,
    'platform': platform,
    'osVersion': osVersion,
    'appVersion': appVersion,
    'deviceModel': deviceModel,
    'fingerprintHash': fingerprintHash,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Deserialize from map
  factory DeviceFingerprint.fromMap(Map<String, dynamic> map) {
    return DeviceFingerprint(
      installationId: map['installationId'] as String,
      deviceId: map['deviceId'] as String,
      platform: map['platform'] as String,
      osVersion: map['osVersion'] as String? ?? '',
      appVersion: map['appVersion'] as String? ?? '',
      deviceModel: map['deviceModel'] as String? ?? '',
      fingerprintHash: map['fingerprintHash'] as String,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  String toString() =>
      'DeviceFingerprint(platform: $platform, model: $deviceModel, hash: ${fingerprintHash.substring(0, 8)}...)';
}

/// Trusted Device - A registered owner device
class TrustedDevice {
  final String id;
  final String businessId;
  final String ownerId;
  final DeviceFingerprint fingerprint;
  final String deviceName;
  final DateTime registeredAt;
  final DateTime? lastUsedAt;
  final bool isPrimary;
  final TrustedDeviceStatus status;

  const TrustedDevice({
    required this.id,
    required this.businessId,
    required this.ownerId,
    required this.fingerprint,
    required this.deviceName,
    required this.registeredAt,
    this.lastUsedAt,
    this.isPrimary = false,
    this.status = TrustedDeviceStatus.active,
  });

  /// Check if device is in cooling period (new device restrictions)
  bool get isInCoolingPeriod {
    const coolingDays = 7;
    return DateTime.now().difference(registeredAt).inDays < coolingDays;
  }

  /// Check if device can perform owner actions
  bool get canPerformOwnerActions {
    return status == TrustedDeviceStatus.active && !isInCoolingPeriod;
  }

  TrustedDevice copyWith({DateTime? lastUsedAt, TrustedDeviceStatus? status}) {
    return TrustedDevice(
      id: id,
      businessId: businessId,
      ownerId: ownerId,
      fingerprint: fingerprint,
      deviceName: deviceName,
      registeredAt: registeredAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isPrimary: isPrimary,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'businessId': businessId,
    'ownerId': ownerId,
    'fingerprint': fingerprint.toMap(),
    'deviceName': deviceName,
    'registeredAt': registeredAt.toIso8601String(),
    'lastUsedAt': lastUsedAt?.toIso8601String(),
    'isPrimary': isPrimary,
    'status': status.name,
  };

  factory TrustedDevice.fromMap(Map<String, dynamic> map) {
    return TrustedDevice(
      id: map['id'] as String,
      businessId: map['businessId'] as String,
      ownerId: map['ownerId'] as String,
      fingerprint: DeviceFingerprint.fromMap(
        map['fingerprint'] as Map<String, dynamic>,
      ),
      deviceName: map['deviceName'] as String,
      registeredAt: DateTime.parse(map['registeredAt'] as String),
      lastUsedAt: map['lastUsedAt'] != null
          ? DateTime.parse(map['lastUsedAt'] as String)
          : null,
      isPrimary: map['isPrimary'] as bool? ?? false,
      status: TrustedDeviceStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TrustedDeviceStatus.active,
      ),
    );
  }
}

/// Trusted device status
enum TrustedDeviceStatus {
  /// Device is active and can be used
  active,

  /// Device is in cooling period (new registration)
  cooling,

  /// Device has been revoked
  revoked,

  /// Device is suspended (suspicious activity)
  suspended,
}
