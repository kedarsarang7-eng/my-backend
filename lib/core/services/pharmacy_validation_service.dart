// ============================================================================
// PHARMACY VALIDATION SERVICE
// ============================================================================
// Centralized validation service for pharmacy/wholesale compliance.
// Validates bill items for expiry, batch numbers, and mandatory fields.
//
// Author: DukanX Engineering
// Version: 1.0.0
// ============================================================================

import '../../models/bill.dart';
import '../billing/business_type_config.dart';
import '../error/pharmacy_compliance_exception.dart';

/// Service to validate pharmacy compliance rules for bill items
///
/// Usage:
/// ```dart
/// final validator = PharmacyValidationService();
/// validator.validateBillItems(items, businessType);
/// ```
class PharmacyValidationService {
  /// Singleton instance
  static final PharmacyValidationService _instance =
      PharmacyValidationService._internal();

  factory PharmacyValidationService() => _instance;

  PharmacyValidationService._internal();

  /// Validates all items in a bill for pharmacy compliance
  ///
  /// Throws [PharmacyComplianceException] if any item fails validation.
  ///
  /// Rules:
  /// - ALL business types: Block sale of expired items (if expiryDate is set)
  /// - Pharmacy/Wholesale: Require batch number and expiry date
  void validateBillItems(List<BillItem> items, BusinessType businessType,
      {String? prescriptionId}) {
    for (final item in items) {
      validateBillItem(item, businessType, prescriptionId: prescriptionId);
    }
  }

  /// Validates a single bill item for pharmacy compliance
  ///
  /// Throws [PharmacyComplianceException] if validation fails.
  void validateBillItem(BillItem item, BusinessType businessType,
      {String? prescriptionId}) {
    final now = DateTime.now();

    // Rule 0: Scheduled Drugs require Prescription (ALL Business Types)
    if (_isScheduledDrug(item.drugSchedule)) {
      if (prescriptionId == null || prescriptionId.isEmpty) {
        // Exception class might need update or use generic exception for now
        throw PharmacyComplianceException(
          code: 'MISSING_PRESCRIPTION',
          message:
              'Prescription required for Schedule ${item.drugSchedule} drug: ${item.productName}',
          details: {
            'productName': item.productName,
            'issueType': 'missing_prescription',
          },
        );
      }
    }

    // Rule 1: Block expired products for ALL business types
    // (Only if expiryDate is set - don't penalize items without expiry)
    if (item.expiryDate != null && item.expiryDate!.isBefore(now)) {
      throw PharmacyComplianceException.expiredProduct(
        productName: item.productName,
        expiryDate: item.expiryDate,
      );
    }

    // Rule 2: For Pharmacy/Wholesale, enforce mandatory fields
    if (_requiresPharmacyValidation(businessType)) {
      // Batch number required
      if (item.batchNo == null || item.batchNo!.trim().isEmpty) {
        throw PharmacyComplianceException.missingBatchNumber(
          productName: item.productName,
        );
      }

      // Expiry date required
      if (item.expiryDate == null) {
        throw PharmacyComplianceException.missingExpiryDate(
          productName: item.productName,
        );
      }
    }
  }

  /// Checks if business type requires pharmacy validation
  /// Driven by Configuration (Batch Number presence)
  bool _requiresPharmacyValidation(BusinessType type) {
    final config = BusinessTypeRegistry.getConfig(type);
    return config.hasField(ItemField.batchNo) &&
        config.hasField(ItemField.expiryDate);
  }

  bool _isScheduledDrug(String? schedule) {
    if (schedule == null) return false;
    final s = schedule.toUpperCase().trim();
    return s == 'H' || s == 'H1' || s == 'X';
  }

  /// Checks if an item is expired
  ///
  /// Returns false if expiryDate is null (unknown expiry)
  bool isExpired(DateTime? expiryDate) {
    if (expiryDate == null) return false;
    return expiryDate.isBefore(DateTime.now());
  }

  /// Checks if an item is near expiry (within specified days)
  ///
  /// Returns false if expiryDate is null (unknown expiry)
  bool isNearExpiry(DateTime? expiryDate, {int daysThreshold = 30}) {
    if (expiryDate == null) return false;
    final warningDate = DateTime.now().add(Duration(days: daysThreshold));
    return expiryDate.isBefore(warningDate) && !isExpired(expiryDate);
  }

  /// Get expiry status for display
  ///
  /// Returns one of: 'expired', 'near_expiry', 'ok', 'unknown'
  String getExpiryStatus(DateTime? expiryDate, {int daysThreshold = 30}) {
    if (expiryDate == null) return 'unknown';
    if (isExpired(expiryDate)) return 'expired';
    if (isNearExpiry(expiryDate, daysThreshold: daysThreshold)) {
      return 'near_expiry';
    }
    return 'ok';
  }

  /// Validate items and return list of issues (non-throwing)
  ///
  /// Useful for UI warnings before final validation
  List<PharmacyComplianceIssue> checkItemsForIssues(
    List<BillItem> items,
    BusinessType businessType, {
    String? prescriptionId,
  }) {
    final issues = <PharmacyComplianceIssue>[];
    final now = DateTime.now();
    final warningDate = now.add(const Duration(days: 30));

    for (final item in items) {
      // Check Schedule H/H1/X compliance
      if (_isScheduledDrug(item.drugSchedule)) {
        if (prescriptionId == null || prescriptionId.isEmpty) {
          issues.add(PharmacyComplianceIssue(
            productName: item.productName,
            issueType: IssueType.missingPrescription,
            severity: IssueSeverity.blocking,
            message:
                'Schedule ${item.drugSchedule} drug requires a prescription',
          ));
        }
      }

      // Check expired
      if (item.expiryDate != null && item.expiryDate!.isBefore(now)) {
        issues.add(PharmacyComplianceIssue(
          productName: item.productName,
          issueType: IssueType.expired,
          severity: IssueSeverity.blocking,
          message: 'Product has expired on ${_formatDate(item.expiryDate!)}',
        ));
      }
      // Check near expiry
      else if (item.expiryDate != null &&
          item.expiryDate!.isBefore(warningDate)) {
        issues.add(PharmacyComplianceIssue(
          productName: item.productName,
          issueType: IssueType.nearExpiry,
          severity: IssueSeverity.warning,
          message: 'Product expires on ${_formatDate(item.expiryDate!)}',
        ));
      }

      // Check mandatory fields for pharmacy
      if (_requiresPharmacyValidation(businessType)) {
        if (item.batchNo == null || item.batchNo!.trim().isEmpty) {
          issues.add(PharmacyComplianceIssue(
            productName: item.productName,
            issueType: IssueType.missingBatch,
            severity: IssueSeverity.blocking,
            message: 'Batch number is required',
          ));
        }
        if (item.expiryDate == null) {
          issues.add(PharmacyComplianceIssue(
            productName: item.productName,
            issueType: IssueType.missingExpiry,
            severity: IssueSeverity.blocking,
            message: 'Expiry date is required',
          ));
        }
      }
    }

    return issues;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

/// Types of pharmacy compliance issues
enum IssueType {
  expired,
  nearExpiry,
  missingBatch,
  missingExpiry,
  missingPrescription,
}

/// Severity of compliance issues
enum IssueSeverity {
  /// Issue blocks the sale
  blocking,

  /// Issue is a warning but sale can proceed
  warning,
}

/// Represents a pharmacy compliance issue for UI display
class PharmacyComplianceIssue {
  final String productName;
  final IssueType issueType;
  final IssueSeverity severity;
  final String message;

  const PharmacyComplianceIssue({
    required this.productName,
    required this.issueType,
    required this.severity,
    required this.message,
  });

  bool get isBlocking => severity == IssueSeverity.blocking;
}
