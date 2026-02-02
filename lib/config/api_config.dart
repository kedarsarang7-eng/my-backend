import 'dart:io';
import 'package:flutter/foundation.dart';

/// Environment types for API configuration
enum Environment { dev, staging, production }

/// API Configuration with environment-based URL selection
///
/// Usage:
/// - Debug builds: Uses DEV environment by default
/// - Release builds: Uses PRODUCTION environment by default
/// - Override: flutter run --dart-define=DUKANX_ENV=staging
class ApiConfig {
  // ============================================================================
  // ENVIRONMENT URLs
  // ============================================================================

  /// Development URLs (local development)
  static const String _devAndroidEmulatorUrl = 'http://10.0.2.2:8000';
  static const String _devLocalhostUrl = 'http://127.0.0.1:8000';

  /// Staging URLs (pre-production testing)
  static const String _stagingUrl = 'https://api-staging.dukanx.com';

  /// Production URLs (live environment)
  static const String _productionUrl = 'https://api.dukanx.com';

  // ============================================================================
  // ENVIRONMENT DETECTION
  // ============================================================================

  /// Current environment - read from dart-define or inferred from build mode
  static Environment get currentEnvironment {
    // Check for explicit environment override via --dart-define
    const envString = String.fromEnvironment('DUKANX_ENV', defaultValue: '');

    if (envString.isNotEmpty) {
      switch (envString.toLowerCase()) {
        case 'dev':
        case 'development':
          return Environment.dev;
        case 'staging':
        case 'stage':
          return Environment.staging;
        case 'prod':
        case 'production':
          return Environment.production;
      }
    }

    // Default: Debug mode uses DEV, Release mode uses PRODUCTION
    return kDebugMode ? Environment.dev : Environment.production;
  }

  /// Check if running in production
  static bool get isProduction => currentEnvironment == Environment.production;

  /// Check if running in development
  static bool get isDevelopment => currentEnvironment == Environment.dev;

  // ============================================================================
  // BASE URL RESOLUTION
  // ============================================================================

  /// Get the appropriate base URL for current environment and platform
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.production:
        return _productionUrl;

      case Environment.staging:
        return _stagingUrl;

      case Environment.dev:
        return _getDevUrl();
    }
  }

  /// Get development URL based on platform
  static String _getDevUrl() {
    if (kIsWeb) {
      return _devLocalhostUrl;
    }

    if (Platform.isAndroid) {
      // 10.0.2.2 is the special alias to host loopback on Android Emulator
      // For real devices, override with DUKANX_API_URL dart-define
      const customUrl = String.fromEnvironment(
        'DUKANX_API_URL',
        defaultValue: '',
      );
      if (customUrl.isNotEmpty) return customUrl;
      return _devAndroidEmulatorUrl;
    }

    // iOS Simulator, Windows, Linux, Mac use localhost
    return _devLocalhostUrl;
  }

  /// Environment name for logging/debugging
  static String get environmentName => currentEnvironment.name.toUpperCase();
}
