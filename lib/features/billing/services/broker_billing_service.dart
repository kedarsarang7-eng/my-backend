import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/error_handler.dart';

import '../../accounting/services/accounting_service.dart';

class BrokerBillingService {
  final AppDatabase _db;
  final ErrorHandler _errorHandler;
  final AccountingService _accountingService;

  BrokerBillingService(this._db, this._errorHandler, this._accountingService);

  // ==========================================
  // FARMER MANAGEMENT
  // ==========================================

  Future<RepositoryResult<String>> createFarmer(
      String userId, String name, String phone, String village) async {
    return await _errorHandler.runSafe<String>(() async {
      final id = const Uuid().v4();
      await _db.into(_db.farmers).insert(FarmersCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            phone: Value(phone),
            village: Value(village),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      return id;
    }, 'createFarmer');
  }

  Stream<List<FarmerEntity>> watchFarmers(String userId) {
    return (_db.select(_db.farmers)
          ..where((t) => t.userId.equals(userId) & t.isActive.equals(true)))
        .watch();
  }

  // ==========================================
  // COMMISSION LOGIC
  // ==========================================

  /// Records a sale where the broker acts as an intermediary.
  ///
  /// [billId]: The ID of the generic sales bill (Buyer Side).
  /// [farmerId]: The supplier who provided the goods.
  /// [saleAmount]: Total sale value collected from Buyer.
  /// [commissionRate]: Percentage of commission (e.g. 5.0 for 5%).
  Future<void> recordBrokerSale({
    required String userId,
    required String billId,
    required String farmerId,
    required double saleAmount,
    required double commissionRate,
    double laborCharges = 0,
    double otherExpenses = 0,
  }) async {
    await _errorHandler.runSafe<void>(() async {
      final commissionAmount = (saleAmount * commissionRate) / 100;
      final netPayable =
          saleAmount - commissionAmount - laborCharges - otherExpenses;

      final ledgerId = const Uuid().v4();

      // 1. Create Ledger Entry
      await _db
          .into(_db.commissionLedger)
          .insert(CommissionLedgerCompanion.insert(
            id: ledgerId,
            userId: userId,
            billId: billId,
            farmerId: farmerId,
            date: DateTime.now(),
            saleAmount: saleAmount,
            commissionRate: Value(commissionRate),
            commissionAmount: commissionAmount,
            laborCharges: Value(laborCharges),
            otherExpenses: Value(otherExpenses),
            netPayableToFarmer: netPayable,
          ));

      // 2. Update Farmer Balance
      // Fetch current farmer stats
      final farmer = await (_db.select(_db.farmers)
            ..where((t) => t.id.equals(farmerId)))
          .getSingle();

      final newSales = farmer.totalSales + saleAmount;
      final newComm = farmer.totalCommissionDeducted + commissionAmount;
      final newExp =
          farmer.totalExpensesDeducted + laborCharges + otherExpenses;
      final newBalance = farmer.currentBalance + netPayable;

      await (_db.update(_db.farmers)..where((t) => t.id.equals(farmerId)))
          .write(FarmersCompanion(
        totalSales: Value(newSales),
        totalCommissionDeducted: Value(newComm),
        totalExpensesDeducted: Value(newExp),
        currentBalance: Value(newBalance),
        updatedAt: Value(DateTime.now()),
      ));
    }, 'recordBrokerSale');
  }

  // ==========================================
  // PAYOUT LOGIC
  // ==========================================

  /// Pay the farmer
  Future<void> payoutFarmer(
      String farmerId, double amount, String description) async {
    await _errorHandler.runSafe<void>(() async {
      final farmer = await (_db.select(_db.farmers)
            ..where((t) => t.id.equals(farmerId)))
          .getSingle();

      final newPaid = farmer.totalPaid + amount;
      final newBalance = farmer.currentBalance - amount;

      await (_db.update(_db.farmers)..where((t) => t.id.equals(farmerId)))
          .write(FarmersCompanion(
        totalPaid: Value(newPaid),
        currentBalance: Value(newBalance),
        updatedAt: Value(DateTime.now()),
      ));

      // Log in Expenses/BankTransactions as a distinct Payout entry
      await _accountingService.createPaymentEntry(
        userId: farmer.userId,
        paymentId: const Uuid().v4(),
        vendorId: farmerId,
        vendorName: farmer.name,
        amount: amount,
        paymentMode: 'CASH', // Default to Cash for now
        paymentDate: DateTime.now(),
      );
    }, 'payoutFarmer');
  }
}
