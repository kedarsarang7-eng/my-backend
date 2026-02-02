// ============================================================================
// SESSION MANAGER TEST
// ============================================================================
// Comprehensive tests for SessionManager and UserSession model
//
// Author: DukanX Engineering
// Version: 1.0.0
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:dukanx/core/session/session_manager.dart';

void main() {
  group('UserRole Tests', () {
    test('should have correct enum values', () {
      expect(UserRole.values.length, 3);
      expect(UserRole.values.contains(UserRole.owner), true);
      expect(UserRole.values.contains(UserRole.customer), true);
      expect(UserRole.values.contains(UserRole.unknown), true);
    });
  });

  group('UserSession Model Tests', () {
    test('should create UserSession with required fields', () {
      final session = UserSession(odId: 'user-123', role: UserRole.owner);

      expect(session.odId, 'user-123');
      expect(session.role, UserRole.owner);
      expect(session.email, null);
      expect(session.displayName, null);
      expect(session.photoUrl, null);
      expect(session.ownerId, null);
      expect(session.lastLoginAt, null);
      expect(session.metadata, null);
    });

    test('should create UserSession with all optional fields', () {
      final now = DateTime.now();
      final metadata = {'key': 'value', 'count': 42};

      final session = UserSession(
        odId: 'user-456',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        role: UserRole.customer,
        ownerId: 'owner-789',
        lastLoginAt: now,
        metadata: metadata,
      );

      expect(session.odId, 'user-456');
      expect(session.email, 'test@example.com');
      expect(session.displayName, 'Test User');
      expect(session.photoUrl, 'https://example.com/photo.jpg');
      expect(session.role, UserRole.customer);
      expect(session.ownerId, 'owner-789');
      expect(session.lastLoginAt, now);
      expect(session.metadata, metadata);
    });

    test('isOwner should return true only for owner role', () {
      final ownerSession = UserSession(odId: 'owner-123', role: UserRole.owner);

      final customerSession = UserSession(
        odId: 'customer-123',
        role: UserRole.customer,
      );

      final unknownSession = UserSession(
        odId: 'unknown-123',
        role: UserRole.unknown,
      );

      expect(ownerSession.isOwner, true);
      expect(customerSession.isOwner, false);
      expect(unknownSession.isOwner, false);
    });

    test('isCustomer should return true only for customer role', () {
      final ownerSession = UserSession(odId: 'owner-123', role: UserRole.owner);

      final customerSession = UserSession(
        odId: 'customer-123',
        role: UserRole.customer,
      );

      final unknownSession = UserSession(
        odId: 'unknown-123',
        role: UserRole.unknown,
      );

      expect(ownerSession.isCustomer, false);
      expect(customerSession.isCustomer, true);
      expect(unknownSession.isCustomer, false);
    });

    test('isAuthenticated should return true when odId is not empty', () {
      final authenticatedSession = UserSession(
        odId: 'user-123',
        role: UserRole.owner,
      );

      final emptyIdSession = UserSession(odId: '', role: UserRole.unknown);

      expect(authenticatedSession.isAuthenticated, true);
      expect(emptyIdSession.isAuthenticated, false);
    });

    test('empty session should have correct defaults', () {
      final emptySession = UserSession.empty;

      expect(emptySession.odId, '');
      expect(emptySession.role, UserRole.unknown);
      expect(emptySession.isAuthenticated, false);
      expect(emptySession.isOwner, false);
      expect(emptySession.isCustomer, false);
    });

    test('copyWith should create copy with updated fields', () {
      final original = UserSession(
        odId: 'user-123',
        email: 'original@example.com',
        displayName: 'Original Name',
        role: UserRole.owner,
        ownerId: 'owner-123',
      );

      final updated = original.copyWith(
        email: 'updated@example.com',
        displayName: 'Updated Name',
        role: UserRole.customer,
      );

      // Changed fields
      expect(updated.email, 'updated@example.com');
      expect(updated.displayName, 'Updated Name');
      expect(updated.role, UserRole.customer);

      // Unchanged fields
      expect(updated.odId, 'user-123');
      expect(updated.ownerId, 'owner-123');
    });

    test('copyWith with no changes should return equivalent session', () {
      final now = DateTime.now();
      final original = UserSession(
        odId: 'user-123',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        role: UserRole.owner,
        ownerId: 'owner-123',
        lastLoginAt: now,
        metadata: {'key': 'value'},
      );

      final copy = original.copyWith();

      expect(copy.odId, original.odId);
      expect(copy.email, original.email);
      expect(copy.displayName, original.displayName);
      expect(copy.photoUrl, original.photoUrl);
      expect(copy.role, original.role);
      expect(copy.ownerId, original.ownerId);
      expect(copy.lastLoginAt, original.lastLoginAt);
      expect(copy.metadata, original.metadata);
    });

    test('copyWith should handle partial updates', () {
      final original = UserSession(
        odId: 'user-123',
        email: 'old@example.com',
        displayName: 'Old Name',
        role: UserRole.unknown,
      );

      // Update only email
      final updated1 = original.copyWith(email: 'new@example.com');
      expect(updated1.email, 'new@example.com');
      expect(updated1.displayName, 'Old Name');

      // Update only displayName
      final updated2 = original.copyWith(displayName: 'New Name');
      expect(updated2.email, 'old@example.com');
      expect(updated2.displayName, 'New Name');
    });

    test('copyWith should handle metadata updates', () {
      final original = UserSession(
        odId: 'user-123',
        role: UserRole.owner,
        metadata: {'existing': 'data'},
      );

      final updated = original.copyWith(
        metadata: {'new': 'metadata', 'count': 100},
      );

      expect(updated.metadata, {'new': 'metadata', 'count': 100});
    });
  });

  group('UserSession Edge Cases', () {
    test('session with special characters in odId', () {
      final session = UserSession(odId: 'user@123!#\$%', role: UserRole.owner);

      expect(session.isAuthenticated, true);
      expect(session.odId, 'user@123!#\$%');
    });

    test('session with very long email', () {
      final longEmail =
          'very.long.email.address.that.is.really.really.long@subdomain.domain.example.com';
      final session = UserSession(
        odId: 'user-123',
        email: longEmail,
        role: UserRole.customer,
      );

      expect(session.email, longEmail);
    });

    test('session with unicode display name', () {
      final session = UserSession(
        odId: 'user-123',
        displayName: '日本語テスト 🎉',
        role: UserRole.owner,
      );

      expect(session.displayName, '日本語テスト 🎉');
    });

    test('session with empty string fields', () {
      final session = UserSession(
        odId: 'user-123',
        email: '',
        displayName: '',
        photoUrl: '',
        role: UserRole.owner,
        ownerId: '',
      );

      expect(session.email, '');
      expect(session.displayName, '');
      expect(session.photoUrl, '');
      expect(session.ownerId, '');
      expect(session.isAuthenticated, true); // odId is not empty
    });

    test('session with complex metadata', () {
      final complexMetadata = {
        'string': 'value',
        'number': 42,
        'double': 3.14,
        'boolean': true,
        'list': [1, 2, 3],
        'nested': {'key': 'value', 'count': 10},
        'nullValue': null,
      };

      final session = UserSession(
        odId: 'user-123',
        role: UserRole.owner,
        metadata: complexMetadata,
      );

      expect(session.metadata, complexMetadata);
      expect(session.metadata!['string'], 'value');
      expect(session.metadata!['number'], 42);
      expect(session.metadata!['nested']['key'], 'value');
    });
  });

  group('Role-based Logic Tests', () {
    test('owner should have isOwner true and isCustomer false', () {
      final session = UserSession(odId: 'owner-1', role: UserRole.owner);

      expect(session.isOwner, true);
      expect(session.isCustomer, false);
    });

    test('customer should have isCustomer true and isOwner false', () {
      final session = UserSession(odId: 'cust-1', role: UserRole.customer);

      expect(session.isOwner, false);
      expect(session.isCustomer, true);
    });

    test('unknown role should have both isOwner and isCustomer false', () {
      final session = UserSession(odId: 'unknown-1', role: UserRole.unknown);

      expect(session.isOwner, false);
      expect(session.isCustomer, false);
    });

    test('customer with linked owner should have ownerId set', () {
      final session = UserSession(
        odId: 'customer-123',
        role: UserRole.customer,
        ownerId: 'owner-456',
      );

      expect(session.role, UserRole.customer);
      expect(session.odId, 'customer-123');
      expect(session.ownerId, 'owner-456');
    });

    test('owner ownerId should typically be same as odId', () {
      final session = UserSession(
        odId: 'owner-123',
        role: UserRole.owner,
        ownerId: 'owner-123',
      );

      expect(session.odId, session.ownerId);
    });
  });
}
