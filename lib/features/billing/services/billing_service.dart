import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../inventory/services/inventory_service.dart';
import '../../../core/error/error_handler.dart'; // Import ErrorHandler

class BillingService {
  final AppDatabase _db;
  final InventoryService _inventoryService;

  BillingService(this._db, this._inventoryService);

  /// Create a Bill with strict validation and atomic stock deduction
  Future<Result<String>> createBill({
    required BillEntity bill,
    required List<BillItemEntity> items,
  }) async {
    // Defensive Wrapper
    return runSafe(() async {
      return _db.transaction(() async {
        // 1. Validate Business Rules
        final validation = await _validateBillRules(bill, items);
        if (!validation.isSuccess) {
          throw validation.error!; // Will be caught by runSafe
        }

        // 2. Insert Bill Header
        await _db.insertBill(BillsCompanion(
          id: Value(bill.id),
          userId: Value(bill.userId),
          customerId: Value(bill.customerId),
          customerName: Value(bill.customerName),
          billDate: Value(bill.billDate),
          invoiceNumber: Value(bill.invoiceNumber),
          status: Value(bill.status),
          // ... Map other fields
          grandTotal: Value(bill.grandTotal),
          itemsJson: Value(bill.itemsJson),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          businessType: Value(bill.businessType),
        ));

        // 3. Insert Bill Items
        for (final item in items) {
          await _db.into(_db.billItems).insert(BillItemsCompanion(
                id: Value(item.id),
                billId: Value(bill.id),
                productId: Value(item.productId),
                productName: Value(item.productName),
                quantity: Value(item.quantity),
                unitPrice: Value(item.unitPrice),
                totalAmount: Value(item.totalAmount),
                // Business Specifics
                batchId: Value(item.batchId),
                imei: Value(item.imei),
                createdAt: Value(DateTime.now()),
              ));

          // 4. Deduct Stock (Atomic)
          if (item.productId != null) {
            await _inventoryService.deductStockInTransaction(
              userId: bill.userId,
              productId: item.productId!,
              quantity: item.quantity,
              referenceId: bill.id,
              invoiceNumber: bill.invoiceNumber,
              date: bill.billDate,
              batchId: item.batchId,
            );
          }
        }

        return bill.id;
      });
    }, errorMessage: 'Failed to create bill', context: null);
  }

  Future<Result<void>> _validateBillRules(
      BillEntity bill, List<BillItemEntity> items) async {
    final businessType = bill.businessType;

    // PHARMACY: Strict Expiry Check
    if (businessType == 'pharmacy' || businessType == 'medical_store') {
      for (final item in items) {
        if (item.batchId != null) {
          final batch = await (_db.select(_db.productBatches)
                ..where((t) => t.id.equals(item.batchId!)))
              .getSingleOrNull();

          if (batch != null && batch.expiryDate != null) {
            if (batch.expiryDate!.isBefore(DateTime.now())) {
              return Result.failure(AppError(
                message:
                    'Cannot sell expired item: ${item.productName} (Expiry: ${batch.expiryDate})',
                category: ErrorCategory.validation,
                severity: ErrorSeverity.medium,
              ));
            }
          }
        }
      }
    }

    // ELECTRONICS: IMEI Check
    if (businessType == 'electronics' || businessType == 'mobile_shop') {
      for (final item in items) {
        if (item.imei != null && item.imei!.isNotEmpty) {
          // Strict 1:1 validation could go here
        }
      }
    }

    // Check Credit Limit (if Credit Bill)
    if (bill.paymentMode == 'CREDIT' && bill.customerId != null) {
      final customer = await _db.getCustomerById(bill.customerId!);
      if (customer != null && customer.creditLimit > 0) {
        if (customer.totalDues + bill.grandTotal > customer.creditLimit) {
          return Result.failure(AppError(
            message:
                'Credit Limit Exceeded for ${customer.name}. Limit: ${customer.creditLimit}',
            category: ErrorCategory.validation,
            severity: ErrorSeverity.medium,
          ));
        }
      }
    }

    return Result.success(null);
  }
}
