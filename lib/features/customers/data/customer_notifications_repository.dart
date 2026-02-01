// ============================================================================
// CUSTOMER NOTIFICATIONS REPOSITORY
// ============================================================================
// Manages notifications for customer dashboard
//
// Author: DukanX Engineering
// Version: 1.0.0
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_queue_state_machine.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/di/service_locator.dart';

// ============================================================================
// MODELS
// ============================================================================

enum NotificationType {
  newInvoice,
  paymentReminder,
  paymentReceived,
  dueDateAlert,
  promotional,
  systemAlert,
}

/// Notification for customer view
class CustomerNotification {
  final String id;
  final String customerId;
  final String? vendorId;
  final NotificationType notificationType;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final String? actionType;
  final String? actionId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime? expiresAt;

  CustomerNotification({
    required this.id,
    required this.customerId,
    this.vendorId,
    required this.notificationType,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    this.actionType,
    this.actionId,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.expiresAt,
  });

  factory CustomerNotification.fromEntity(CustomerNotificationEntity e) {
    Map<String, dynamic>? data;
    if (e.dataJson != null) {
      try {
        data = jsonDecode(e.dataJson!) as Map<String, dynamic>;
      } catch (_) {}
    }

    return CustomerNotification(
      id: e.id,
      customerId: e.customerId,
      vendorId: e.vendorId,
      notificationType: _parseNotificationType(e.notificationType),
      title: e.title,
      body: e.body,
      imageUrl: e.imageUrl,
      data: data,
      actionType: e.actionType,
      actionId: e.actionId,
      isRead: e.isRead,
      readAt: e.readAt,
      createdAt: e.createdAt,
      expiresAt: e.expiresAt,
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type.toUpperCase()) {
      case 'NEW_INVOICE':
        return NotificationType.newInvoice;
      case 'PAYMENT_REMINDER':
        return NotificationType.paymentReminder;
      case 'PAYMENT_RECEIVED':
        return NotificationType.paymentReceived;
      case 'DUE_DATE_ALERT':
        return NotificationType.dueDateAlert;
      case 'PROMOTIONAL':
        return NotificationType.promotional;
      case 'SYSTEM_ALERT':
        return NotificationType.systemAlert;
      default:
        return NotificationType.systemAlert;
    }
  }

  String get notificationTypeString {
    switch (notificationType) {
      case NotificationType.newInvoice:
        return 'NEW_INVOICE';
      case NotificationType.paymentReminder:
        return 'PAYMENT_REMINDER';
      case NotificationType.paymentReceived:
        return 'PAYMENT_RECEIVED';
      case NotificationType.dueDateAlert:
        return 'DUE_DATE_ALERT';
      case NotificationType.promotional:
        return 'PROMOTIONAL';
      case NotificationType.systemAlert:
        return 'SYSTEM_ALERT';
    }
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  CustomerNotification copyWith({bool? isRead, DateTime? readAt}) {
    return CustomerNotification(
      id: id,
      customerId: customerId,
      vendorId: vendorId,
      notificationType: notificationType,
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
      actionType: actionType,
      actionId: actionId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }
}

// ============================================================================
// REPOSITORY
// ============================================================================

class CustomerNotificationsRepository {
  final AppDatabase database;
  final SyncManager syncManager;
  final ErrorHandler errorHandler;

  CustomerNotificationsRepository({
    required this.database,
    required this.syncManager,
    required this.errorHandler,
  });

  // ============================================
  // NOTIFICATIONS
  // ============================================

  /// Get all notifications for a customer
  Future<RepositoryResult<List<CustomerNotification>>> getNotifications(
    String customerId, {
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    return errorHandler.runSafe(() async {
      var query = database.select(database.customerNotifications)
        ..where((t) => t.customerId.equals(customerId));

      if (unreadOnly) {
        query = query..where((t) => t.isRead.equals(false));
      }

      query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
      query.limit(limit);

      final entities = await query.get();
      return entities
          .map(CustomerNotification.fromEntity)
          .where((n) => !n.isExpired)
          .toList();
    }, 'getNotifications');
  }

  /// Watch notifications stream
  Stream<List<CustomerNotification>> watchNotifications(
    String customerId, {
    bool unreadOnly = false,
  }) {
    var query = database.select(database.customerNotifications)
      ..where((t) => t.customerId.equals(customerId));

    if (unreadOnly) {
      query = query..where((t) => t.isRead.equals(false));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    query.limit(100);

    return query.watch().map((entities) => entities
        .map(CustomerNotification.fromEntity)
        .where((n) => !n.isExpired)
        .toList());
  }

  /// Get unread count
  Future<RepositoryResult<int>> getUnreadCount(String customerId) async {
    return errorHandler.runSafe(() async {
      final count = await (database.select(database.customerNotifications)
            ..where((t) => t.customerId.equals(customerId))
            ..where((t) => t.isRead.equals(false)))
          .get();

      return count.length;
    }, 'getUnreadCount');
  }

  /// Watch unread count
  Stream<int> watchUnreadCount(String customerId) {
    return (database.select(database.customerNotifications)
          ..where((t) => t.customerId.equals(customerId))
          ..where((t) => t.isRead.equals(false)))
        .watch()
        .map((list) => list.length);
  }

  /// Mark notification as read
  Future<RepositoryResult<bool>> markAsRead(String notificationId) async {
    return errorHandler.runSafe(() async {
      final now = DateTime.now();

      await (database.update(database.customerNotifications)
            ..where((t) => t.id.equals(notificationId)))
          .write(CustomerNotificationsCompanion(
        isRead: const Value(true),
        readAt: Value(now),
      ));

      return true;
    }, 'markAsRead');
  }

  /// Mark all as read
  Future<RepositoryResult<int>> markAllAsRead(String customerId) async {
    return errorHandler.runSafe(() async {
      final now = DateTime.now();

      final updated = await (database.update(database.customerNotifications)
            ..where((t) => t.customerId.equals(customerId))
            ..where((t) => t.isRead.equals(false)))
          .write(CustomerNotificationsCompanion(
        isRead: const Value(true),
        readAt: Value(now),
      ));

      return updated;
    }, 'markAllAsRead');
  }

  /// Create a notification (used by vendor to notify customer)
  Future<RepositoryResult<CustomerNotification>> createNotification({
    required String customerId,
    String? vendorId,
    required NotificationType notificationType,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? actionType,
    String? actionId,
    DateTime? expiresAt,
  }) async {
    return errorHandler.runSafe(() async {
      final now = DateTime.now();
      final id = const Uuid().v4();

      final entity = CustomerNotificationsCompanion.insert(
        id: id,
        customerId: customerId,
        vendorId: Value(vendorId),
        notificationType: _getNotificationTypeString(notificationType),
        title: title,
        body: body,
        imageUrl: Value(imageUrl),
        dataJson: Value(data != null ? jsonEncode(data) : null),
        actionType: Value(actionType),
        actionId: Value(actionId),
        createdAt: now,
        expiresAt: Value(expiresAt),
      );

      await database.into(database.customerNotifications).insert(entity);

      // Queue for sync (to trigger push notification on server)
      await syncManager.enqueue(SyncQueueItem.create(
        userId: vendorId ?? customerId,
        operationType: SyncOperationType.create,
        targetCollection: 'customer_notifications',
        documentId: id,
        payload: {
          'id': id,
          'customerId': customerId,
          'vendorId': vendorId,
          'notificationType': _getNotificationTypeString(notificationType),
          'title': title,
          'body': body,
          'imageUrl': imageUrl,
          'data': data,
          'actionType': actionType,
          'actionId': actionId,
          'isRead': false,
          'createdAt': now.toIso8601String(),
          'expiresAt': expiresAt?.toIso8601String(),
        },
      ));

      final result = await (database.select(database.customerNotifications)
            ..where((t) => t.id.equals(id)))
          .getSingle();

      return CustomerNotification.fromEntity(result);
    }, 'createNotification');
  }

  String _getNotificationTypeString(NotificationType type) {
    switch (type) {
      case NotificationType.newInvoice:
        return 'NEW_INVOICE';
      case NotificationType.paymentReminder:
        return 'PAYMENT_REMINDER';
      case NotificationType.paymentReceived:
        return 'PAYMENT_RECEIVED';
      case NotificationType.dueDateAlert:
        return 'DUE_DATE_ALERT';
      case NotificationType.promotional:
        return 'PROMOTIONAL';
      case NotificationType.systemAlert:
        return 'SYSTEM_ALERT';
    }
  }

  /// Delete old notifications (cleanup)
  Future<RepositoryResult<int>> deleteOldNotifications(
    String customerId, {
    int daysOld = 30,
  }) async {
    return errorHandler.runSafe(() async {
      final cutoff = DateTime.now().subtract(Duration(days: daysOld));

      final deleted = await (database.delete(database.customerNotifications)
            ..where((t) => t.customerId.equals(customerId))
            ..where((t) => t.createdAt.isSmallerThanValue(cutoff))
            ..where((t) => t.isRead.equals(true)))
          .go();

      return deleted;
    }, 'deleteOldNotifications');
  }
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================

/// Provider for CustomerNotificationsRepository
final customerNotificationsRepositoryProvider =
    Provider<CustomerNotificationsRepository>((ref) {
  return CustomerNotificationsRepository(
    database: AppDatabase.instance,
    syncManager: sl<SyncManager>(),
    errorHandler: sl<ErrorHandler>(),
  );
});

/// Provider for notifications list
final customerNotificationsProvider =
    StreamProvider.family<List<CustomerNotification>, String>(
        (ref, customerId) {
  final repo = ref.watch(customerNotificationsRepositoryProvider);
  return repo.watchNotifications(customerId);
});

/// Provider for unread count
final customerUnreadNotificationsCountProvider =
    StreamProvider.family<int, String>((ref, customerId) {
  final repo = ref.watch(customerNotificationsRepositoryProvider);
  return repo.watchUnreadCount(customerId);
});
