// ============================================================================
// STOCK SECURITY SERVICE
// ============================================================================
// Security layer for stock operations with PIN and audit integration.
// ============================================================================

import 'package:flutter/foundation.dart';

import '../repository/audit_repository.dart';
import '../security/services/owner_pin_service.dart';

/// Stock Adjustment Reason - Required for all manual stock changes.
enum StockAdjustmentReason {
  /// Stock arrived from supplier
  purchaseReceived,

  /// Stock sold to customer
  saleMade,

  /// Customer returned item
  customerReturn,

  /// Item returned to supplier
  supplierReturn,

  /// Damaged/expired items
  damageOrExpiry,

  /// Stolen or missing items
  theft,

  /// Physical count correction
  physicalCountCorrection,

  /// Opening balance for new item
  openingBalance,

  /// Transfer between locations
  transfer,

  /// Sample/demo given
  sampleGiven,

  /// Other (requires notes)
  other,
}

extension StockAdjustmentReasonX on StockAdjustmentReason {
  String get displayName {
    switch (this) {
      case StockAdjustmentReason.purchaseReceived:
        return 'Purchase Received';
      case StockAdjustmentReason.saleMade:
        return 'Sale Made';
      case StockAdjustmentReason.customerReturn:
        return 'Customer Return';
      case StockAdjustmentReason.supplierReturn:
        return 'Supplier Return';
      case StockAdjustmentReason.damageOrExpiry:
        return 'Damage/Expiry';
      case StockAdjustmentReason.theft:
        return 'Theft/Missing';
      case StockAdjustmentReason.physicalCountCorrection:
        return 'Physical Count';
      case StockAdjustmentReason.openingBalance:
        return 'Opening Balance';
      case StockAdjustmentReason.transfer:
        return 'Transfer';
      case StockAdjustmentReason.sampleGiven:
        return 'Sample Given';
      case StockAdjustmentReason.other:
        return 'Other';
    }
  }

  /// Whether this reason requires additional notes
  bool get requiresNotes {
    switch (this) {
      case StockAdjustmentReason.other:
      case StockAdjustmentReason.theft:
      case StockAdjustmentReason.physicalCountCorrection:
        return true;
      default:
        return false;
    }
  }

  /// Whether this reason requires PIN verification
  bool get requiresPin {
    switch (this) {
      case StockAdjustmentReason.theft:
      case StockAdjustmentReason.physicalCountCorrection:
      case StockAdjustmentReason.other:
      case StockAdjustmentReason.damageOrExpiry:
        return true;
      default:
        return false;
    }
  }
}

/// Stock Adjustment Request
class StockAdjustmentRequest {
  final String productId;
  final String productName;
  final double oldQuantity;
  final double newQuantity;
  final StockAdjustmentReason reason;
  final String? referenceId; // billId, purchaseId, etc.
  final String? notes;
  final String adjustedBy;
  final DateTime timestamp;

  StockAdjustmentRequest({
    required this.productId,
    required this.productName,
    required this.oldQuantity,
    required this.newQuantity,
    required this.reason,
    this.referenceId,
    this.notes,
    required this.adjustedBy,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  double get quantityChange => newQuantity - oldQuantity;
  bool get isIncrease => quantityChange > 0;
  bool get isDecrease => quantityChange < 0;

  Map<String, dynamic> toAuditJson() => {
        'productId': productId,
        'productName': productName,
        'oldQuantity': oldQuantity,
        'newQuantity': newQuantity,
        'quantityChange': quantityChange,
        'reason': reason.name,
        'referenceId': referenceId,
        'notes': notes,
        'adjustedBy': adjustedBy,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Stock Security Service - PIN and audit integration for stock operations.
class StockSecurityService {
  final OwnerPinService _pinService;
  final AuditRepository _auditRepository;

  StockSecurityService({
    required OwnerPinService pinService,
    required AuditRepository auditRepository,
  })  : _pinService = pinService,
        _auditRepository = auditRepository;

  /// Validate stock adjustment request
  Future<StockAdjustmentValidation> validateAdjustment({
    required String businessId,
    required StockAdjustmentRequest request,
    String? pin,
  }) async {
    // Check if reason requires notes
    if (request.reason.requiresNotes &&
        (request.notes == null || request.notes!.trim().isEmpty)) {
      return StockAdjustmentValidation.denied(
        'Reason "${request.reason.displayName}" requires notes',
      );
    }

    // Check if reason requires PIN
    if (request.reason.requiresPin) {
      if (pin == null || pin.isEmpty) {
        return StockAdjustmentValidation.pinRequired(
          'PIN required for ${request.reason.displayName}',
        );
      }

      // Verify PIN
      try {
        final isValid = await _pinService.verifyPin(
          businessId: businessId,
          pin: pin,
        );
        if (!isValid) {
          return StockAdjustmentValidation.denied('Invalid PIN');
        }
      } catch (e) {
        return StockAdjustmentValidation.denied('$e');
      }
    }

    return StockAdjustmentValidation.allowed();
  }

  /// Log stock adjustment with full context
  Future<void> logStockAdjustment({
    required String businessId,
    required StockAdjustmentRequest request,
    bool pinVerified = false,
  }) async {
    // Audit log
    await _auditRepository.logAction(
      userId: request.adjustedBy,
      targetTableName: 'stock_movements',
      recordId: request.productId,
      action: request.isIncrease ? 'INCREASE' : 'DECREASE',
      oldValueJson: '{"quantity": ${request.oldQuantity}}',
      newValueJson: '${request.toAuditJson()}',
    );

    // Check for suspicious patterns - large quantity changes
    final changePercent = request.oldQuantity > 0
        ? (request.quantityChange.abs() / request.oldQuantity) * 100
        : 100;

    if (changePercent > 50) {
      // Log as potential fraud alert via audit
      await _auditRepository.logAction(
        userId: request.adjustedBy,
        targetTableName: 'fraud_alerts',
        recordId: request.productId,
        action: 'STOCK_MISMATCH_ALERT',
        newValueJson: '''{
          "severity": "${changePercent > 90 ? 'CRITICAL' : 'HIGH'}",
          "description": "Large stock adjustment (${changePercent.toStringAsFixed(0)}%): ${request.productName}",
          "oldQuantity": ${request.oldQuantity},
          "newQuantity": ${request.newQuantity},
          "reason": "${request.reason.name}"
        }''',
      );
    }

    debugPrint(
        'StockSecurityService: Logged adjustment for ${request.productId}: '
        '${request.oldQuantity} -> ${request.newQuantity} (${request.reason.displayName})');
  }
}

/// Stock adjustment validation result
class StockAdjustmentValidation {
  final bool isAllowed;
  final bool requiresPin;
  final String? error;

  StockAdjustmentValidation._({
    required this.isAllowed,
    this.requiresPin = false,
    this.error,
  });

  factory StockAdjustmentValidation.allowed() {
    return StockAdjustmentValidation._(isAllowed: true);
  }

  factory StockAdjustmentValidation.denied(String error) {
    return StockAdjustmentValidation._(isAllowed: false, error: error);
  }

  factory StockAdjustmentValidation.pinRequired(String message) {
    return StockAdjustmentValidation._(
      isAllowed: false,
      requiresPin: true,
      error: message,
    );
  }
}
