// ============================================================================
// SECURITY NOTIFICATION SERVICE
// ============================================================================
// Integrates security alerts with the app's notification system.
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../security/services/fraud_detection_service.dart';
import '../repository/fraud_alert_repository.dart';

/// Security Notification Service - Bridges fraud alerts to notifications.
///
/// Features:
/// - Listens to FraudDetectionService alerts
/// - Persists alerts to repository
/// - Provides stream for UI consumption
class SecurityNotificationService {
  final FraudDetectionService _fraudService;
  final FraudAlertRepository _alertRepository;

  StreamSubscription<FraudAlert>? _subscription;

  /// Stream controller for UI notifications
  final StreamController<SecurityNotification> _notificationController =
      StreamController<SecurityNotification>.broadcast();

  SecurityNotificationService({
    required FraudDetectionService fraudService,
    required FraudAlertRepository alertRepository,
  })  : _fraudService = fraudService,
        _alertRepository = alertRepository;

  /// Stream of security notifications for UI
  Stream<SecurityNotification> get notifications =>
      _notificationController.stream;

  /// Start listening for fraud alerts
  void startListening() {
    _subscription?.cancel();
    _subscription = _fraudService.fraudAlerts.listen(_handleAlert);
    debugPrint(
        'SecurityNotificationService: Started listening for fraud alerts');
  }

  /// Stop listening for fraud alerts
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('SecurityNotificationService: Stopped listening');
  }

  Future<void> _handleAlert(FraudAlert alert) async {
    try {
      // Persist alert
      await _alertRepository.saveAlert(alert);

      // Create UI notification
      final notification = SecurityNotification(
        id: alert.id,
        title: _getAlertTitle(alert),
        message: alert.description,
        severity: alert.severity,
        type: alert.type,
        createdAt: alert.createdAt,
        referenceId: alert.referenceId,
      );

      // Emit to stream for UI
      _notificationController.add(notification);

      debugPrint('SecurityNotificationService: Created notification for '
          '${alert.type.name} (${alert.severity.name})');
    } catch (e) {
      debugPrint('SecurityNotificationService: Failed to handle alert: $e');
    }
  }

  String _getAlertTitle(FraudAlert alert) {
    switch (alert.type) {
      case FraudAlertType.highDiscount:
        return '⚠️ High Discount Alert';
      case FraudAlertType.repeatedBillEdits:
        return '🔄 Unusual Bill Edits';
      case FraudAlertType.lateNightBilling:
        return '🌙 Late Night Billing';
      case FraudAlertType.cashVariance:
        return '💰 Cash Mismatch';
      case FraudAlertType.stockMismatch:
        return '📦 Stock Discrepancy';
      case FraudAlertType.roleAbuseAttempt:
        return '🚨 Unauthorized Access Attempt';
      case FraudAlertType.pinBruteForce:
        return '🔐 PIN Security Alert';
      case FraudAlertType.paidBillDeletion:
        return '❌ Paid Bill Deletion';
      case FraudAlertType.suspiciousRefunds:
        return '↩️ Suspicious Refund Pattern';
      case FraudAlertType.largeTransaction:
        return '💵 Large Transaction';
      case FraudAlertType.billEditWindowExpired:
        return '⏰ Bill Edit Window Expired';
    }
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _notificationController.close();
  }
}

/// Security Notification model for UI consumption
class SecurityNotification {
  final String id;
  final String title;
  final String message;
  final FraudSeverity severity;
  final FraudAlertType type;
  final DateTime createdAt;
  final String? referenceId;

  const SecurityNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.type,
    required this.createdAt,
    this.referenceId,
  });

  /// Check if notification is high priority
  bool get isHighPriority =>
      severity == FraudSeverity.critical || severity == FraudSeverity.high;
}
