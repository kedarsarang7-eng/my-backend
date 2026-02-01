/// IMEI Validation Service
/// Validates IMEI/Serial numbers during billing to prevent duplicates
library;

import 'package:dukanx/core/database/app_database.dart';
import 'package:dukanx/features/service/data/repositories/imei_serial_repository.dart';
import 'package:dukanx/features/service/models/imei_serial.dart';
import 'package:dukanx/models/bill.dart';

/// Result of IMEI validation
class IMEIValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, String>
      imeiToProductMap; // IMEI -> Product ID for valid IMEIs

  IMEIValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.imeiToProductMap = const {},
  });

  factory IMEIValidationResult.success({
    List<String> warnings = const [],
    Map<String, String> imeiToProductMap = const {},
  }) {
    return IMEIValidationResult(
      isValid: true,
      warnings: warnings,
      imeiToProductMap: imeiToProductMap,
    );
  }

  factory IMEIValidationResult.failure(List<String> errors) {
    return IMEIValidationResult(isValid: false, errors: errors);
  }
}

/// Service for validating IMEI/Serial during billing
class IMEIValidationService {
  final AppDatabase _db;
  late final IMEISerialRepository _imeiRepository;

  IMEIValidationService(this._db) {
    _imeiRepository = IMEISerialRepository(_db);
  }

  /// Validate all IMEI/Serial numbers in bill items before sale
  /// Returns validation result with errors if any IMEI is already sold or invalid
  Future<IMEIValidationResult> validateBillItems({
    required String userId,
    required List<BillItem> items,
    required String businessType,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final validImeiMap = <String, String>{};

    // Only validate for electronics-related business types
    final requiresIMEI = _requiresIMEIValidation(businessType);
    if (!requiresIMEI) {
      return IMEIValidationResult.success();
    }

    for (final item in items) {
      final serialNo = item.serialNo;
      if (serialNo == null || serialNo.isEmpty) {
        // For mobileShop, IMEI is required
        if (businessType.toLowerCase().contains('mobile')) {
          errors.add('IMEI/Serial required for: ${item.productName}');
        }
        continue;
      }

      // Check if this IMEI is already in use
      final existingIMEI = await _imeiRepository.getByNumber(userId, serialNo);

      if (existingIMEI != null) {
        // Check status
        switch (existingIMEI.status) {
          case IMEISerialStatus.sold:
            errors.add(
                'IMEI $serialNo already sold on ${_formatDate(existingIMEI.soldDate)}');
            break;
          case IMEISerialStatus.inService:
            errors.add('IMEI $serialNo is currently in service');
            break;
          case IMEISerialStatus.returned:
            warnings.add(
                'IMEI $serialNo was previously returned - verify condition');
            validImeiMap[serialNo] = existingIMEI.id;
            break;
          case IMEISerialStatus.inStock:
            // Valid - available for sale
            validImeiMap[serialNo] = existingIMEI.id;
            break;
          case IMEISerialStatus.damaged:
            errors.add('IMEI $serialNo is marked as damaged');
            break;
        }
      } else {
        // IMEI not in our system - add a warning but allow sale
        // (It may be a new stock item not yet added to IMEISerials)
        warnings.add(
            'IMEI $serialNo not found in inventory - will be auto-registered');
      }
    }

    if (errors.isNotEmpty) {
      return IMEIValidationResult.failure(errors);
    }

    return IMEIValidationResult.success(
      warnings: warnings,
      imeiToProductMap: validImeiMap,
    );
  }

  /// Mark IMEIs as sold after successful bill creation
  /// Should be called within the same transaction as bill creation
  Future<void> markIMEIsAsSold({
    required String userId,
    required String billId,
    required String customerId,
    required List<BillItem> items,
    int defaultWarrantyMonths = 12,
  }) async {
    for (final item in items) {
      final serialNo = item.serialNo;
      if (serialNo == null || serialNo.isEmpty) continue;

      final existingIMEI = await _imeiRepository.getByNumber(userId, serialNo);

      if (existingIMEI != null) {
        // Mark as sold
        await _imeiRepository.markAsSold(
          id: existingIMEI.id,
          billId: billId,
          customerId: customerId,
          soldPrice: item.price,
          warrantyMonths: item.warrantyMonths ?? defaultWarrantyMonths,
        );
      } else {
        // Auto-register new IMEI and mark as sold
        final now = DateTime.now();
        final warrantyMonths = item.warrantyMonths ?? defaultWarrantyMonths;
        final imei = IMEISerial(
          id: '',
          userId: userId,
          productId: item.productId,
          imeiOrSerial: serialNo,
          type: _guessIMEIType(serialNo),
          status: IMEISerialStatus.sold,
          billId: billId,
          customerId: customerId,
          soldPrice: item.price,
          soldDate: now,
          warrantyMonths: warrantyMonths,
          warrantyStartDate: now,
          warrantyEndDate:
              DateTime(now.year, now.month + warrantyMonths, now.day),
          isUnderWarranty: warrantyMonths > 0,
          productName: item.productName,
          createdAt: now,
          updatedAt: now,
        );
        await _imeiRepository.createIMEISerial(imei);
      }
    }
  }

  /// Check if a business type requires IMEI validation
  bool _requiresIMEIValidation(String businessType) {
    final normalizedType = businessType.toLowerCase();
    return normalizedType.contains('mobile') ||
        normalizedType.contains('computer') ||
        normalizedType.contains('electronics') ||
        normalizedType.contains('phone') ||
        normalizedType.contains('laptop');
  }

  /// Guess IMEI type from format
  IMEISerialType _guessIMEIType(String serial) {
    // IMEI is typically 15 digits
    if (serial.length == 15 && int.tryParse(serial) != null) {
      return IMEISerialType.imei;
    }
    return IMEISerialType.serial;
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return '${date.day}/${date.month}/${date.year}';
  }
}
