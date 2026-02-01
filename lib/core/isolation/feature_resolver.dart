import 'package:dukanx/core/isolation/business_capability.dart';

/// Feature Resolver Engine
///
/// The central authority for Feature Isolation.
/// All UI, Logic, and DB layers MUST query this engine before
/// accessing restricted features.
class FeatureResolver {
  /// Check if a Business Type has access to a specific Capability
  ///
  /// Usage:
  /// if (FeatureResolver.canAccess(businessType, BusinessCapability.useIMEI)) {
  ///   showIMEIField();
  /// }
  static bool canAccess(String businessType, BusinessCapability capability) {
    // Normalize string to match registry keys
    final typeKey = _normalizeType(businessType);

    final capabilities = businessCapabilityRegistry[typeKey];
    if (capabilities == null) {
      // Default to strict deny if type unknown
      return false;
    }

    return capabilities.contains(capability);
  }

  /// Enforce access - Throws SecurityException if access is denied
  ///
  /// Use this in Repository/Backend layers to prevent data leakage
  static void enforceAccess(
      String businessType, BusinessCapability capability) {
    if (!canAccess(businessType, capability)) {
      throw SecurityException(
          'Access Denied: Business Type [$businessType] cannot use feature [${capability.name}]');
    }
  }

  /// Helper to match BusinessType enum to string keys
  static String _normalizeType(String type) {
    // Handle enum toString() likely cases or raw strings
    if (type.contains('.')) {
      return type.split('.').last;
    }
    return type;
  }

  /// Get all allowed capabilities for a business type
  static Set<BusinessCapability> getCapabilities(String businessType) {
    return businessCapabilityRegistry[_normalizeType(businessType)] ?? {};
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
