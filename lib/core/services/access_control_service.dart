// ============================================================================
// ACCESS CONTROL SERVICE
// ============================================================================
// Unified permission checking service with caching and audit logging.
// ============================================================================

import 'package:flutter/foundation.dart';

import '../repository/audit_repository.dart';
import '../../services/role_management_service.dart';
import '../security/services/fraud_detection_service.dart';

/// Access Control Service - Unified permission and role management.
///
/// Features:
/// - Permission checking with role-based access
/// - Role abuse detection and logging
/// - Business-specific access control
/// - Audit trail for permission denials
class AccessControlService {
  final AuditRepository _auditRepository;
  final FraudDetectionService? _fraudService;

  /// Cache of user roles by userId
  final Map<String, UserRole> _roleCache = {};

  AccessControlService({
    required AuditRepository auditRepository,
    FraudDetectionService? fraudService,
  })  : _auditRepository = auditRepository,
        _fraudService = fraudService;

  /// Check if user has a specific permission
  bool hasPermission(String userId, Permission permission) {
    final role = _roleCache[userId];
    if (role == null) {
      debugPrint('AccessControlService: No role cached for user $userId');
      return false;
    }
    return RolePermissions.hasPermission(role, permission);
  }

  /// Check permission and log denial if not authorized
  Future<bool> checkPermission({
    required String userId,
    required String businessId,
    required Permission permission,
    String? context,
  }) async {
    final role = _roleCache[userId] ?? UserRole.viewer;
    final hasAccess = RolePermissions.hasPermission(role, permission);

    if (!hasAccess) {
      // Log the denied attempt
      await _logPermissionDenial(
        userId: userId,
        businessId: businessId,
        permission: permission,
        role: role,
        context: context,
      );

      // Check for potential role abuse
      await _fraudService?.checkRoleAbuseAttempt(
        businessId: businessId,
        userId: userId,
        attemptedAction: permission.name,
        userRole: role.name,
      );
    }

    return hasAccess;
  }

  /// Set user role (from auth/login)
  void setUserRole(String userId, UserRole role) {
    _roleCache[userId] = role;
    debugPrint('AccessControlService: Set role for $userId to ${role.name}');
  }

  /// Get user role
  UserRole? getUserRole(String userId) => _roleCache[userId];

  /// Check if user is owner
  bool isOwner(String userId) {
    return _roleCache[userId] == UserRole.owner;
  }

  /// Check if user is accountant (CA Safe Mode)
  bool isAccountant(String userId) {
    return _roleCache[userId] == UserRole.accountant ||
        _roleCache[userId] == UserRole.viewer;
  }

  /// Check if user can modify data (not read-only)
  bool canModify(String userId) {
    final role = _roleCache[userId];
    // Viewer and Accountant roles are read-only
    return role != UserRole.viewer;
  }

  /// Check multiple permissions (any)
  bool hasAnyPermission(String userId, List<Permission> permissions) {
    return permissions.any((p) => hasPermission(userId, p));
  }

  /// Check multiple permissions (all)
  bool hasAllPermissions(String userId, List<Permission> permissions) {
    return permissions.every((p) => hasPermission(userId, p));
  }

  /// Get all permissions for a user
  Set<Permission> getUserPermissions(String userId) {
    final role = _roleCache[userId];
    if (role == null) return {};
    return RolePermissions.getPermissions(role);
  }

  /// Clear cache for user (on logout)
  void clearUserCache(String userId) {
    _roleCache.remove(userId);
  }

  /// Clear all cache
  void clearAllCache() {
    _roleCache.clear();
  }

  Future<void> _logPermissionDenial({
    required String userId,
    required String businessId,
    required Permission permission,
    required UserRole role,
    String? context,
  }) async {
    try {
      await _auditRepository.logAction(
        userId: userId,
        targetTableName: 'permission_denial',
        recordId: businessId,
        action: 'DENIED',
        newValueJson: '''{
          "permission": "${permission.name}",
          "role": "${role.name}",
          "context": ${context != null ? '"$context"' : 'null'}
        }''',
      );
    } catch (e) {
      debugPrint('AccessControlService: Failed to log denial: $e');
    }
  }
}

/// Extension for easy permission checking
extension AccessControlX on AccessControlService {
  /// Require permission or throw
  void requirePermission(String userId, Permission permission) {
    if (!hasPermission(userId, permission)) {
      throw PermissionDeniedException(permission);
    }
  }
}

/// Exception for permission denied
class PermissionDeniedException implements Exception {
  final Permission permission;

  PermissionDeniedException(this.permission);

  @override
  String toString() => 'PermissionDeniedException: ${permission.name} required';
}
