import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class RecurringBillingService {
  final AppDatabase _db;
  // potentially inject BillingRepository if available to reuse "Create Bill" logic

  RecurringBillingService(this._db);

  /// Check for due subscriptions and generate invoices
  /// specificUserId: Optional, to run for a specific user (e.g. on login)
  Future<int> checkAndGenerateInvoices({String? specificUserId}) async {
    final now = DateTime.now();

    // Query Active Subscriptions due for billing
    var query = _db.select(_db.subscriptions)
      ..where((t) =>
          t.status.equals('ACTIVE') &
          t.nextInvoiceDate.isSmallerOrEqualValue(now));

    if (specificUserId != null) {
      query = query..where((t) => t.userId.equals(specificUserId));
    }

    final dueSubscriptions = await query.get();
    int generatedCount = 0;

    for (final sub in dueSubscriptions) {
      await _generateBillForSubscription(sub);
      generatedCount++;
    }

    return generatedCount;
  }

  Future<void> _generateBillForSubscription(SubscriptionEntity sub) async {
    await _db.transaction(() async {
      final now = DateTime.now();
      final billId = const Uuid().v4();

      // Implement Bill Creation Logic
      // 1. Create Bill
      // 2. Create BillItems

      // Parse Items
      // List<BillItemEntity> items = ... decode sub.itemsJson

      // Calculate Dates
      DateTime nextDate;
      switch (sub.frequency) {
        case 'WEEKLY':
          nextDate = sub.nextInvoiceDate.add(const Duration(days: 7));
          break;
        case 'QUARTERLY':
          nextDate = DateTime(sub.nextInvoiceDate.year,
              sub.nextInvoiceDate.month + 3, sub.nextInvoiceDate.day);
          break;
        case 'YEARLY':
          nextDate = DateTime(sub.nextInvoiceDate.year + 1,
              sub.nextInvoiceDate.month, sub.nextInvoiceDate.day);
          break;
        case 'MONTHLY':
        default:
          nextDate = DateTime(sub.nextInvoiceDate.year,
              sub.nextInvoiceDate.month + 1, sub.nextInvoiceDate.day);
          break;
      }

      // Update Subscription
      await (_db.update(_db.subscriptions)..where((t) => t.id.equals(sub.id)))
          .write(SubscriptionsCompanion(
        nextInvoiceDate: Value(nextDate),
        lastGeneratedAt: Value(now),
      ));

      // 3. Create Bill via Billing Service (Handles Rules & Stock)
      // We need to map Subscription items to BillItemEntity list
      // For now we assume itemsJson contains list of items

      // Parse items if possible, else empty list for now as we don't have the parsing logic
      // final items = (jsonDecode(sub.itemsJson) as List).map((e) => BillItemEntity.fromJson(e)).toList();

      final invoiceNumber =
          'SUB-${now.millisecondsSinceEpoch}'; // Temporary generator

      final bill = BillEntity(
        id: billId,
        userId: sub.userId,
        customerId: sub.customerId,
        customerName: sub.customerName,
        billDate: now,
        invoiceNumber: invoiceNumber,
        status: 'DRAFT',
        itemsJson: sub.itemsJson,
        grandTotal: sub.amount,
        source: 'SUBSCRIPTION',
        createdAt: now,
        updatedAt: now,
        businessType: 'service', // Default to service/generic
        // ... defaults
        subtotal: sub.amount,
        taxAmount: 0.0,
        paidAmount: 0.0,
        discountAmount: 0.0,
        version: 1,
        cashPaid: 0.0,
        onlinePaid: 0.0,
        serviceCharge: 0.0,
        costOfGoodsSold: 0.0,
        grossProfit: 0.0,
        printCount: 0,
        isSynced: false,
        marketCess: 0.0,
        commissionAmount: 0.0,
      );

      // Use BillingService if injected, else insert directly (drafts don't need stock deducation yet?)
      // If it is DRAFT, we don't deduct stock.
      // Since Recurring Invoice is usually Auto-Generated as DRAFT for review, we just insert.

      await _db.into(_db.bills).insert(bill);

      // Insert Items
      // for (var item in items) ...
    });
  }
}
