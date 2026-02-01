// ============================================================================
// PERMISSION GUARD WIDGET
// ============================================================================
// Widget wrapper for permission-based UI control.
// Hides or disables UI elements based on user permissions.
// ============================================================================

import 'package:flutter/material.dart';

import '../../services/role_management_service.dart';

/// Permission Guard - UI-level permission enforcement.
///
/// Wraps child widgets and controls visibility/enablement based on
/// the current user's role and permissions.
///
/// Usage:
/// ```dart
/// PermissionGuard(
///   permission: Permission.deleteBill,
///   child: IconButton(
///     icon: Icon(Icons.delete),
///     onPressed: _deleteBill,
///   ),
/// )
/// ```
class PermissionGuard extends StatelessWidget {
  /// The permission required to show/enable the child
  final Permission permission;

  /// The child widget to conditionally show
  final Widget child;

  /// Widget to show when permission is denied (optional)
  /// If null, child is hidden entirely
  final Widget? deniedChild;

  /// Current user's role (required for checking permissions)
  final UserRole userRole;

  /// Whether to disable instead of hide when permission denied
  /// Default: false (hides the widget)
  final bool disableWhenDenied;

  /// Callback when unauthorized action is attempted
  final VoidCallback? onUnauthorizedAttempt;

  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    required this.userRole,
    this.deniedChild,
    this.disableWhenDenied = false,
    this.onUnauthorizedAttempt,
  });

  /// Quick check if current role has permission
  bool get hasPermission => RolePermissions.hasPermission(userRole, permission);

  @override
  Widget build(BuildContext context) {
    if (hasPermission) {
      return child;
    }

    // Permission denied
    if (disableWhenDenied) {
      return _buildDisabledChild(context);
    }

    if (deniedChild != null) {
      return deniedChild!;
    }

    // Hide completely
    return const SizedBox.shrink();
  }

  Widget _buildDisabledChild(BuildContext context) {
    // Wrap in IgnorePointer and reduce opacity
    return GestureDetector(
      onTap: onUnauthorizedAttempt ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('You don\'t have permission for: ${permission.name}'),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.4,
          child: child,
        ),
      ),
    );
  }
}

/// Permission Gate - Alternative widget for larger sections
///
/// Shows an access denied message for entire sections.
class PermissionGate extends StatelessWidget {
  /// The permission required to access this section
  final Permission permission;

  /// The protected content
  final Widget child;

  /// Current user's role
  final UserRole userRole;

  /// Custom message when access denied
  final String? deniedMessage;

  /// Custom icon when access denied
  final IconData? deniedIcon;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    required this.userRole,
    this.deniedMessage,
    this.deniedIcon,
  });

  bool get hasPermission => RolePermissions.hasPermission(userRole, permission);

  @override
  Widget build(BuildContext context) {
    if (hasPermission) {
      return child;
    }

    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              deniedIcon ?? Icons.lock_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              deniedMessage ?? 'Access Restricted',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have permission to access this section.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-Permission Guard - Requires any/all of multiple permissions
class MultiPermissionGuard extends StatelessWidget {
  /// List of permissions to check
  final List<Permission> permissions;

  /// Require ALL permissions (true) or ANY permission (false)
  final bool requireAll;

  /// The child widget
  final Widget child;

  /// Current user's role
  final UserRole userRole;

  /// Widget when denied
  final Widget? deniedChild;

  const MultiPermissionGuard({
    super.key,
    required this.permissions,
    this.requireAll = false,
    required this.child,
    required this.userRole,
    this.deniedChild,
  });

  bool get hasPermission {
    if (requireAll) {
      return permissions
          .every((p) => RolePermissions.hasPermission(userRole, p));
    } else {
      return permissions.any((p) => RolePermissions.hasPermission(userRole, p));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hasPermission) {
      return child;
    }

    return deniedChild ?? const SizedBox.shrink();
  }
}

/// Role Guard - Requires specific role(s)
class RoleGuard extends StatelessWidget {
  /// Allowed roles
  final List<UserRole> allowedRoles;

  /// The child widget
  final Widget child;

  /// Current user's role
  final UserRole userRole;

  /// Widget when role not allowed
  final Widget? deniedChild;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    required this.userRole,
    this.deniedChild,
  });

  bool get hasAccess => allowedRoles.contains(userRole);

  @override
  Widget build(BuildContext context) {
    if (hasAccess) {
      return child;
    }

    return deniedChild ?? const SizedBox.shrink();
  }
}

/// Owner Only Guard - Quick shorthand for owner-only features
class OwnerOnlyGuard extends StatelessWidget {
  final Widget child;
  final UserRole userRole;
  final Widget? deniedChild;

  const OwnerOnlyGuard({
    super.key,
    required this.child,
    required this.userRole,
    this.deniedChild,
  });

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: const [UserRole.owner],
      userRole: userRole,
      deniedChild: deniedChild,
      child: child,
    );
  }
}
