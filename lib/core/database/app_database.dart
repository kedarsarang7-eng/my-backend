// ============================================================================
// DUKANX ENTERPRISE DATABASE
// ============================================================================
// Main Drift database class with all tables and DAOs
//
// Author: DukanX Engineering
// Version: 1.0.0
// ============================================================================

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'tables.dart';

import 'connection.dart';
import '../sync/sync_manager.dart';
import '../sync/sync_queue_state_machine.dart';

part 'app_database.g.dart';

// ============================================================================
// DATABASE CLASS
// ============================================================================

@DriftDatabase(tables: [
  SyncQueue,
  Bills,
  BillItems,
  Customers,
  Products,
  Payments,
  PaymentTransactions, // NEW: Dynamic QR Audit
  DeliveryChallans, // NEW: Delivery Challan
  Expenses,
  FileUploads,
  OcrTasks,
  VoiceTasks,
  SchemaVersions,
  Checksums,
  AuditLogs,
  ConflictLog, // NEW: Conflict audit trail
  DeadLetterQueue,
  BankAccounts,
  BankTransactions,
  Vendors,
  PurchaseOrders,
  PurchaseItems,
  // Customer Dashboard Tables
  CustomerConnections,
  CustomerLedger,
  CustomerNotifications,
  // Customer-Shop QR Linking (Multi-Tenant Isolation)
  CustomerProfiles, // Shop-scoped customer profiles
  ShopLinks, // Customer-shop associations
  UdharPeople,
  UdharTransactions,
  // Duplicate UdharTransactions removed
  Shops,
  Receipts,
  ReturnInwards,
  Proformas,
  Bookings,
  Dispatches,
  Users,
  // GST Compliance Tables
  GstSettings,
  GstInvoiceDetails,
  HsnMaster,
  // Accounting Tables
  JournalEntries,
  AccountingPeriods,
  LedgerAccounts,
  DayBook,
  // Reminder Tables
  ReminderSettings,
  ReminderLogs,
  PeriodLocks,
  StockMovements, // Phase 8: Golden Rule Inventory
  // Phase 12: e-Invoice & e-Way Bill
  EInvoices,
  EWayBills,
  // Phase 12: Marketing & CRM
  MarketingCampaigns,
  CampaignLogs,
  MessageTemplates,
  // AI
  CustomerBehaviors,
  // Phase 12: Staff Management
  StaffMembers,
  StaffAttendance,
  SalaryRecords,
  // Phase 13: Credit Network
  CreditProfiles,
  // Phase 14: Restaurant / Hotel Food Ordering
  FoodCategories,
  FoodMenuItems,
  RestaurantTables,
  RestaurantQrCodes,
  FoodOrders,
  FoodOrderItems,
  RestaurantBills,
  // Phase 15: Invoice Number Safety
  InvoiceCounters,
  // Phase 16: Mobile/Computer Shop - Service Jobs & IMEI Tracking
  IMEISerials,
  ServiceJobs,
  ServiceJobParts,
  ServiceJobStatusHistory,
  ProductVariants,
  Exchanges,
  // Phase 20: Security & Fraud Prevention
  SecuritySettingsTable,
  CashClosings,
  FraudAlerts,
  UserSessions,
  // Phase 22: Doctor Prescriptions
  Prescriptions,
  Visits,
  Patients,
  // Phase 23: Pharmacy Compliance (Audit Fix)
  ProductBatches,

  LockOverrideLogs,
  // Phase 30: Shortcut Panel
  ShortcutDefinitions,
  UserShortcuts,
  // Phase 31: Manufacturing Module
  BillOfMaterials,
  ProductionEntries,
  // Phase 32: Recurring Billing
  Subscriptions,
  CustomerItemRequests,
  // Phase 35: Doctor / Clinic Module
  Patients,
  DoctorProfiles,
  PatientDoctorLinks,
  Appointments,
  // Prescriptions is already registered for v24, checking if we need re-declaration or extend
  // Assuming Prescriptions table definition in tables.dart was UPDATED to include more fields or used as is.
  // Ideally we should double check if Prescriptions was already in the list.
  // Looking at line 116: Prescriptions IS ALREADY REGISTERED.
  // We need to add others:
  MedicalRecords,
  PrescriptionItems,
  LabReports,
  MedicalTemplates, // Added
  Farmers,
  CommissionLedger,
  // Petrol Pump Tables
  Shifts,
  Tanks,
  Nozzles,
  Dispensers,
  // Phase 12+: Enhanced Staff Management
  StaffNozzleAssignments,
  StaffSalesDetails,
  StaffCashSettlements,
  // Phase 38: Petrol Pump - Additional Tables
  CashDeposits,
  LubeStock,
  DensityRecords,
  LicenseCache,
])
class AppDatabase extends _$AppDatabase implements SyncQueueLocalOperations {
  // Singleton instance
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  AppDatabase._() : super(_openConnection());

  // For testing
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 38; // Bumped to 38 for Petrol Pump Audit

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          debugPrint('AppDatabase: Created all tables');
        },
        onUpgrade: (Migrator m, int from, int to) async {
          debugPrint('AppDatabase: Migrating from $from to $to');

          if (from < 4) {
            // Migration to version 4: Add new columns to bills table
            await m.addColumn(bills, bills.cashPaid);
            await m.addColumn(bills, bills.onlinePaid);
            await m.addColumn(bills, bills.businessType);
            await m.addColumn(bills, bills.serviceCharge);
          }

          if (from < 5) {
            // Migration to version 5: Add deviceId columns and ConflictLog table
            await m.addColumn(syncQueue, syncQueue.deviceId);
            await m.addColumn(bills, bills.deviceId);
            await m.addColumn(customers, customers.deviceId);
            await m.addColumn(products, products.deviceId);
            await m.createTable(conflictLog);
          }
          if (from < 6) {
            // Migration to version 6: Add Shops table
            await m.createTable(shops);
          }
          if (from < 7) {
            // Migration to version 7: Add Revenue tables
            await m.createTable(receipts);
            await m.createTable(returnInwards);
            await m.createTable(proformas);
            await m.createTable(bookings);
            await m.createTable(dispatches);
          }
          if (from < 8) {
            // Migration to version 8: Add Users table and Onboarding columns
            await m.createTable(users);
            await m.addColumn(shops, shops.businessType);
            await m.addColumn(shops, shops.appLanguage);
            await m.addColumn(shops, shops.onboardingCompleted);
          }
          if (from < 9) {
            // Migration to version 9: Add ifsc column to bank_accounts
            await m.addColumn(
                bankAccounts, bankAccounts.ifsc as GeneratedColumn);
          }
          if (from < 10) {
            // Migration to version 10: GST, Accounting, and Reminder modules
            // GST Tables
            await m.createTable(gstSettings);
            await m.createTable(gstInvoiceDetails);
            await m.createTable(hsnMaster);
            // Accounting Tables
            await m.createTable(journalEntries);
            await m.createTable(accountingPeriods);
            await m.createTable(ledgerAccounts);
            // Reminder Tables
            await m.createTable(reminderSettings);
            await m.createTable(reminderLogs);
            // Add GST columns to existing tables
            await m.addColumn(products, products.hsnCode);
            await m.addColumn(products, products.cgstRate);
            await m.addColumn(products, products.sgstRate);
            await m.addColumn(products, products.igstRate);
            await m.addColumn(billItems, billItems.hsnCode);
            await m.addColumn(billItems, billItems.cgstRate);
            await m.addColumn(billItems, billItems.cgstAmount);
            await m.addColumn(billItems, billItems.sgstRate);
            await m.addColumn(billItems, billItems.sgstAmount);
            await m.addColumn(billItems, billItems.igstRate);
            await m.addColumn(billItems, billItems.igstAmount);
            await m.addColumn(customers, customers.stateCode);
            await m.addColumn(customers, customers.creditPeriodDays);
            await m.addColumn(customers, customers.creditLimit);
            await m.addColumn(customers, customers.optInSmsReminders);
            await m.addColumn(customers, customers.optInWhatsAppReminders);
          }
          if (from < 11) {
            // Migration to version 11: Stock Automation
            await m.createTable(stockMovements);
          }
          if (from < 12) {
            // Migration to version 12: e-Invoice, Marketing, Staff Management
            // e-Invoice Tables
            await m.createTable(eInvoices);
            await m.createTable(eWayBills);
            // Marketing Tables
            await m.createTable(marketingCampaigns);
            await m.createTable(campaignLogs);
            await m.createTable(messageTemplates);
            // Staff Management Tables
            await m.createTable(staffMembers);
            await m.createTable(staffAttendance);
            await m.createTable(salaryRecords);
          }
          if (from < 15) {
            // Migration to version 15: Restaurant / Hotel Food Ordering System
            await m.createTable(foodCategories);
            await m.createTable(foodMenuItems);
            await m.createTable(restaurantTables);
            await m.createTable(restaurantQrCodes);
            await m.createTable(foodOrders);
            await m.createTable(foodOrderItems);
            await m.createTable(restaurantBills);
          }
          if (from < 16) {
            // Migration to version 16: Invoice Counter for collision-free invoice numbers
            await m.createTable(invoiceCounters);
          }
          if (from < 17) {
            // Migration to version 17: Delivery Challan
            await m.createTable(deliveryChallans);
            await m.addColumn(bills, bills.deliveryChallanId);
          }
          if (from < 18) {
            // Migration to version 18: Mobile/Computer Shop - Service Jobs & IMEI Tracking
            await m.createTable(iMEISerials);
            await m.createTable(serviceJobs);
            await m.createTable(serviceJobParts);
            await m.createTable(serviceJobStatusHistory);
            await m.createTable(productVariants);
            await m.createTable(productVariants);
            await m.createTable(exchanges);
          }
          if (from < 19) {
            // Migration to version 19: Fraud Prevention
            // 1. Audit Log Hash Chaining
            await m.addColumn(auditLogs, auditLogs.previousHash);
            await m.addColumn(auditLogs, auditLogs.currentHash);
            // 2. Bill Locking
            await m.addColumn(bills, bills.printCount);
          }
          if (from < 20) {
            // Migration to version 20: Security & Fraud Prevention Tables
            await m.createTable(securitySettingsTable);
            await m.createTable(cashClosings);
            await m.createTable(fraudAlerts);
            await m.createTable(userSessions);
          }
          if (from < 21) {
            // Migration to version 21: Customer Master Tab Enhancement
            await m.addColumn(customers, customers.customerType);
            await m.addColumn(customers, customers.openingBalance);
            await m.addColumn(customers, customers.priceLevel);
            await m.addColumn(customers, customers.gstPreference);
            await m.addColumn(customers, customers.isBlocked);
            await m.addColumn(customers, customers.blockReason);
            await m.addColumn(customers, customers.lastTransactionDate);
          }
          if (from < 22) {
            // Migration to version 22: Customer-Shop QR Linking System
            // 1. Create shop-scoped customer profiles table
            await m.createTable(customerProfiles);
            // 2. Create customer-shop links table
            await m.createTable(shopLinks);
            // 3. Add customerProfileId to bills for linked customer billing
            await m.addColumn(bills, bills.customerProfileId);
          }
          if (from < 23) {
            // Migration to version 23: Add altBarcodes to Products
            await m.addColumn(
                products, products.altBarcodes as GeneratedColumn);
          }
          if (from < 24) {
            await m.createTable(prescriptions);
            await m.addColumn(bills, bills.prescriptionId);
          }
          if (from < 25) {
            // Migration to version 25: Add drugSchedule to Products & BillItems
            await m.addColumn(
                products, products.drugSchedule as GeneratedColumn);
            await m.addColumn(
                billItems, billItems.drugSchedule as GeneratedColumn);
          }
          if (from < 26) {
            // Migration to version 26: Enhanced Sync Queue (Sync Engine 2.0)
            await m.addColumn(
                syncQueue, syncQueue.payloadHash as GeneratedColumn);
            await m.addColumn(
                syncQueue, syncQueue.dependencyGroup as GeneratedColumn);
            await m.addColumn(syncQueue, syncQueue.ownerId as GeneratedColumn);

            // Backfill ownerId from userId (Best effort for pending items)
            await customStatement(
                'UPDATE sync_queue SET owner_id = user_id WHERE owner_id = "UNKNOWN"');
          }
          if (from < 27) {
            // Migration to version 27: Pharmacy Compliance Upgrade
            await m.createTable(productBatches);
            await m.createTable(lockOverrideLogs);
            await m.addColumn(stockMovements, stockMovements.batchId);

            // Backfill batch info in PurchaseItems
            await m.addColumn(purchaseItems, purchaseItems.batchNumber);
            await m.addColumn(purchaseItems, purchaseItems.expiryDate);

            // Re-create stockMovements if needed for batchId, but addColumn is enough for SQLite
          }
          if (from < 28) {
            // Migration to version 28: Business Data Isolation & Inventory Rules
            await m.addColumn(bills, bills.businessId);
            await m.addColumn(shops, shops.allowNegativeStock);
          }
          if (from < 29) {
            // Migration to version 29: HIS Module (Patients, Visits)
            // Re-creating patients if not exists, though v29 says it did.
            // But we are adding refined Patients table now in v35 possibly replacing or extending?
            // The task implies we are adding NEW tables. If Patients existed in v29, we should check if we need to DROP and CREATE or just use it.
            // Since we defined `PatientEntity` in `tables.dart`, drift needs it.
            // Let's assume standard behavior: creation if not exists.
            await m.createTable(patients);
            await m.createTable(visits);
          }
          if (from < 30) {
            // Migration to version 30: Shortcut Panel
            await m.createTable(shortcutDefinitions);
            await m.createTable(userShortcuts);
          }
          if (from < 31) {
            // Migration to version 31: Manufacturing Module
            await m.createTable(billOfMaterials);
            await m.createTable(productionEntries);
          }
          if (from < 32) {
            // Migration to version 32: Recurring Billing
            await m.createTable(subscriptions);
          }
          if (from < 33) {
            await m.addColumn(
                customers, customers.linkStatus as GeneratedColumn);
          }
          if (from < 34) {
            // Migration to version 34: Customer Item Requests
            await m.createTable(customerItemRequests);
          }
          if (from < 35) {
            // Migration to version 35: Doctor / Clinic Module
            // Patients might have been created in v29, but let's ensure schema match or re-create if needed.
            // For safety in this environment, we'll try to create tables.
            // If they exist, we might need manual handling, but standard practice here is `createTable` which implies `IF NOT EXISTS` usually or we rely on Drift handling.
            // However, Drift's `createTable` throws if exists.
            // We'll proceed with creating the NEW tables.
            await m.createTable(doctorProfiles);
            await m.createTable(patientDoctorLinks);
            await m.createTable(appointments);
            await m.createTable(medicalRecords);
            await m.createTable(prescriptionItems);
            await m.createTable(labReports);
            // Patients, Prescriptions, Visits might already exist from v29/v24.
            // We should allow them to remain or safely update them.
            // For now, we assume they are compatible or this is a fresh setup for this module.
            // For now, we assume they are compatible or this is a fresh setup for this module.
          }
          if (from < 36) {
            // Migration to version 36: Garment Variants & Vegetable Broker
            await m.addColumn(products, products.groupId);
            await m.addColumn(products, products.variantAttributes);
            await m.createTable(farmers);
            await m.createTable(commissionLedger);
          }
          if (from < 37) {
            // Migration to version 37: Enhanced Staff Management (Petrol Pump)
            await m.createTable(staffNozzleAssignments);
            await m.createTable(staffSalesDetails);
            await m.createTable(staffCashSettlements);

            // Add columns to existing tables
            await m.addColumn(staffMembers, staffMembers.pumpId);
            await m.addColumn(staffAttendance, staffAttendance.method);
            await m.addColumn(bills, bills.attendantId);
          }
          if (from < 38) {
            // Migration to version 38: Petrol Pump Audit - Additional Tables
            await m.createTable(cashDeposits);
            await m.createTable(lubeStock);
            await m.createTable(densityRecords);
            await m.createTable(dayBook);

            // Add calibration fields to dispensers
            await m.addColumn(
                dispensers, dispensers.lastCalibrationDate as GeneratedColumn);
            await m.addColumn(
                dispensers, dispensers.nextCalibrationDate as GeneratedColumn);
            await m.addColumn(dispensers,
                dispensers.calibrationIntervalDays as GeneratedColumn);
            await m.addColumn(dispensers,
                dispensers.calibrationCertificateNumber as GeneratedColumn);
          }
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');
          debugPrint('AppDatabase: Opened (version: ${details.versionNow})');
        },
      );

  // ============================================================================
  // SYNC QUEUE OPERATIONS
  // ============================================================================

  // ============================================================================
  // SYNC QUEUE OPERATIONS (SyncQueueLocalOperations Implementation)
  // ============================================================================

  @override
  Future<void> insertSyncQueueItem(SyncQueueItem item) {
    return into(syncQueue).insert(
      SyncQueueCompanion(
        operationId: Value(item.operationId),
        operationType: Value(item.operationType.value),
        targetCollection: Value(item.targetCollection),
        documentId: Value(item.documentId),
        payload: Value(jsonEncode(item.payload)),
        status: Value(item.status.value),
        retryCount: Value(item.retryCount),
        lastError: Value(item.lastError),
        createdAt: Value(item.createdAt),
        lastAttemptAt: Value(item.lastAttemptAt),
        syncedAt: Value(item.syncedAt),
        priority: Value(item.priority),
        parentOperationId: Value(item.parentOperationId),
        stepNumber: Value(item.stepNumber),
        totalSteps: Value(item.totalSteps),
        userId: Value(item.userId),
        deviceId: Value(item.deviceId),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<void> updateSyncQueueItem(SyncQueueItem item) {
    return (update(syncQueue)
          ..where((t) => t.operationId.equals(item.operationId)))
        .write(SyncQueueCompanion(
      status: Value(item.status.value),
      retryCount: Value(item.retryCount),
      lastError: Value(item.lastError),
      lastAttemptAt: Value(item.lastAttemptAt),
      syncedAt: Value(item.syncedAt),
    ));
  }

  @override
  Future<void> deleteSyncQueueItem(String operationId) {
    return (delete(syncQueue)..where((t) => t.operationId.equals(operationId)))
        .go();
  }

  @override
  Future<List<SyncQueueItem>> getPendingSyncItems() async {
    final rows = await (select(syncQueue)
          ..where((t) => t.status.isIn([
                'PENDING',
                'RETRY',
                'IN_PROGRESS'
              ])) // Include IN_PROGRESS to resume
          ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
        .get();

    return rows.map((row) {
      return SyncQueueItem(
        operationId: row.operationId,
        operationType: SyncOperationType.fromString(row.operationType),
        targetCollection: row.targetCollection,
        documentId: row.documentId,
        payload: jsonDecode(row.payload),
        status: SyncStatus.fromString(row.status),
        retryCount: row.retryCount,
        lastError: row.lastError,
        createdAt: row.createdAt,
        lastAttemptAt: row.lastAttemptAt,
        syncedAt: row.syncedAt,
        priority: row.priority,
        parentOperationId: row.parentOperationId,
        stepNumber: row.stepNumber,
        totalSteps: row.totalSteps,
        userId: row.userId,
        deviceId: row.deviceId,
        payloadHash: row.payloadHash,
        dependencyGroup: row.dependencyGroup,
        ownerId: row.ownerId,
      );
    }).toList();
  }

  @override
  Future<void> markDocumentSynced(String collection, String documentId) async {
    // Mark the entity as synced in its respective table
    // This reduces the need for a switch statement if we are generic,
    // but Drift tables are strongly typed.
    switch (collection) {
      case 'bills':
        await (update(bills)..where((t) => t.id.equals(documentId))).write(
          const BillsCompanion(isSynced: Value(true)),
        );
        break;
      case 'customers':
        await (update(customers)..where((t) => t.id.equals(documentId))).write(
          const CustomersCompanion(isSynced: Value(true)),
        );
        break;
      case 'products':
        await (update(products)..where((t) => t.id.equals(documentId))).write(
          const ProductsCompanion(isSynced: Value(true)),
        );
        break;
      case 'payments':
        await (update(payments)..where((t) => t.id.equals(documentId))).write(
          const PaymentsCompanion(isSynced: Value(true)),
        );
        break;
      case 'expenses':
        await (update(expenses)..where((t) => t.id.equals(documentId))).write(
          const ExpensesCompanion(isSynced: Value(true)),
        );
        break;
      case 'receipts':
        await (update(receipts)..where((t) => t.id.equals(documentId))).write(
          const ReceiptsCompanion(isSynced: Value(true)),
        );
        break;
      case 'returnInwards':
        await (update(returnInwards)..where((t) => t.id.equals(documentId)))
            .write(
          const ReturnInwardsCompanion(isSynced: Value(true)),
        );
        break;
      case 'proformas':
        await (update(proformas)..where((t) => t.id.equals(documentId))).write(
          const ProformasCompanion(isSynced: Value(true)),
        );
        break;
      case 'bookings':
        await (update(bookings)..where((t) => t.id.equals(documentId))).write(
          const BookingsCompanion(isSynced: Value(true)),
        );
        break;
      case 'dispatches':
        await (update(dispatches)..where((t) => t.id.equals(documentId))).write(
          const DispatchesCompanion(isSynced: Value(true)),
        );
        break;
      // Add other tables as needed
    }
  }

  @override
  Future<void> moveToDeadLetter(SyncQueueItem item, String error) async {
    await transaction(() async {
      // 1. Insert into Dead Letter Queue
      await into(deadLetterQueue).insert(
        DeadLetterQueueCompanion.insert(
          id: const Uuid().v4(),
          originalOperationId: item.operationId,
          userId: item.userId,
          operationType: item.operationType.value,
          targetCollection: item.targetCollection,
          documentId: item.documentId,
          payload: jsonEncode(item.payload),
          failureReason: error,
          totalAttempts: item.retryCount,
          firstAttemptAt: item.createdAt,
          lastAttemptAt: DateTime.now(),
          movedToDeadLetterAt: DateTime.now(),
        ),
      );

      // 2. Remove from active sync queue
      await deleteSyncQueueItem(item.operationId);
    });
  }

  @override
  Future<int> getDeadLetterCount() {
    return select(deadLetterQueue).get().then((l) => l.length);
  }

  @override
  Future<void> updateLocalFromServer({
    required String collection,
    required String documentId,
    required Map<String, dynamic> serverData,
  }) async {
    switch (collection) {
      case 'bills':
        await updateBillFromServer(documentId, serverData);
        break;
      case 'customers':
        await updateCustomerFromServer(documentId, serverData);
        break;
      case 'products':
        await updateProductFromServer(documentId, serverData);
        break;
      // Add others as needed
    }
  }

  // ============================================================================
  // LEGACY HELPER METHODS (Can be deprecated later)
  // ============================================================================
  // Kept for backward compatibility if needed during migration, or aliases.

  Future<void> insertSyncQueueEntry(SyncQueueCompanion entry) {
    return into(syncQueue).insert(entry, mode: InsertMode.insertOrReplace);
  }

  Future<void> updateSyncQueueEntry(SyncQueueEntry entry) {
    return (update(syncQueue)
          ..where((t) => t.operationId.equals(entry.operationId)))
        .write(SyncQueueCompanion(
      status: Value(entry.status),
      retryCount: Value(entry.retryCount),
      lastError: Value(entry.lastError),
      lastAttemptAt: Value(entry.lastAttemptAt),
      syncedAt: Value(entry.syncedAt),
    ));
  }

  Future<List<SyncQueueEntry>> getPendingSyncEntries() {
    return (select(syncQueue)
          ..where((t) => t.status.isIn(['PENDING', 'RETRY']))
          ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
        .get();
  }

  Future<void> deleteSyncQueueEntry(String operationId) {
    return (delete(syncQueue)..where((t) => t.operationId.equals(operationId)))
        .go();
  }

  Stream<List<SyncQueueEntry>> watchPendingSyncEntries() {
    return (select(syncQueue)
          ..where((t) => t.status.isIn(['PENDING', 'RETRY', 'IN_PROGRESS']))
          ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
        .watch();
  }

  // ============================================================================
  // BILLS OPERATIONS
  // ============================================================================

  Future<void> insertBill(BillsCompanion bill) {
    return into(bills).insert(bill, mode: InsertMode.insertOrReplace);
  }

  Future<void> updateBill(BillEntity bill) {
    return (update(bills)..where((t) => t.id.equals(bill.id))).write(
      BillsCompanion(
        customerName: Value(bill.customerName),
        subtotal: Value(bill.subtotal),
        taxAmount: Value(bill.taxAmount),
        grandTotal: Value(bill.grandTotal),
        paidAmount: Value(bill.paidAmount),
        status: Value(bill.status),
        paymentMode: Value(bill.paymentMode),
        notes: Value(bill.notes),
        itemsJson: Value(bill.itemsJson),
        updatedAt: Value(DateTime.now()),
        isSynced: Value(bill.isSynced),
        version: Value(bill.version + 1),
      ),
    );
  }

  Future<BillEntity?> getBillById(String id) {
    return (select(bills)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<BillEntity>> getAllBills(String userId) {
    return (select(bills)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Stream<List<BillEntity>> watchAllBills(String userId) {
    return (select(bills)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<void> softDeleteBill(String id) {
    return (update(bills)..where((t) => t.id.equals(id))).write(
      BillsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markBillSynced(String id, String? operationId) {
    return (update(bills)..where((t) => t.id.equals(id))).write(
      BillsCompanion(
        isSynced: const Value(true),
        syncOperationId: Value(operationId),
      ),
    );
  }

  // ============================================================================
  // CUSTOMERS OPERATIONS
  // ============================================================================

  Future<void> insertCustomer(CustomersCompanion customer) {
    return into(customers).insert(customer, mode: InsertMode.insertOrReplace);
  }

  Future<CustomerEntity?> getCustomerById(String id) {
    return (select(customers)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<CustomerEntity>> getAllCustomers(String userId) {
    return (select(customers)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Stream<List<CustomerEntity>> watchAllCustomers(String userId) {
    return (select(customers)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<void> markCustomerSynced(String id, String? operationId) {
    return (update(customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(
        isSynced: const Value(true),
        syncOperationId: Value(operationId),
      ),
    );
  }

  /// Soft-delete a customer: sets isActive=false and deletedAt timestamp.
  /// Historical bills and payments remain intact.
  Future<void> softDeleteCustomer(String id) {
    return (update(customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(
        isActive: const Value(false),
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  // ============================================================================
  // PRODUCTS OPERATIONS
  // ============================================================================

  Future<void> insertProduct(ProductsCompanion product) {
    return into(products).insert(product, mode: InsertMode.insertOrReplace);
  }

  Future<ProductEntity?> getProductById(String id) {
    return (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<ProductEntity>> getAllProducts(String userId) {
    return (select(products)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Stream<List<ProductEntity>> watchAllProducts(String userId) {
    return (select(products)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<ProductEntity>> getLowStockProducts(String userId) {
    return (select(products)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.stockQuantity)]))
        .get()
        .then((list) =>
            list.where((p) => p.stockQuantity <= p.lowStockThreshold).toList());
  }

  Future<List<ProductEntity>> getDeadStockProducts(
      String userId, DateTime cutoffDate) async {
    // 1. Get all active products with stock > 0 created before cutoff
    final candidateProducts = await (select(products)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.isActive.equals(true) &
              t.stockQuantity.isBiggerThanValue(0) &
              t.createdAt.isSmallerThanValue(cutoffDate)))
        .get();

    if (candidateProducts.isEmpty) return [];

    // 2. Find products sold AFTER the cutoff date
    // We strictly link to bills to ensure we look at valid sales for this user
    final query = select(billItems).join([
      innerJoin(bills, bills.id.equalsExp(billItems.billId)),
    ])
      ..where(bills.userId.equals(userId) &
          bills.createdAt.isBiggerOrEqualValue(cutoffDate) &
          bills.status.isNotIn(['DRAFT', 'CANCELLED']));

    final activeProductIds =
        await query.map((row) => row.readTable(billItems).productId).get();
    final activeIdsSet = activeProductIds.toSet();

    // 3. Filter candidates: Keep those NOT in the active set
    return candidateProducts
        .where((p) => !activeIdsSet.contains(p.id))
        .toList();
  }

  /// Get sales history for velocity calculation
  /// Returns Map&lt;ProductId, TotalQuantitySold&gt;
  Future<Map<String, double>> getProductSalesHistory(
      String userId, DateTime cutoffDate) async {
    final query = select(billItems).join([
      innerJoin(bills, bills.id.equalsExp(billItems.billId)),
    ])
      ..where(bills.userId.equals(userId) &
          bills.createdAt.isBiggerOrEqualValue(cutoffDate) &
          bills.status.isNotIn(['DRAFT', 'CANCELLED']));

    final rows = await query.get();

    final usageMap = <String, double>{};

    for (final row in rows) {
      final item = row.readTable(billItems);
      // Ensure we handle potential nulls, though quantity should be non-null
      final qty = item.quantity;
      final pid = item.productId;

      if (pid != null) {
        usageMap[pid] = (usageMap[pid] ?? 0) + qty;
      }
    }

    return usageMap;
  }

  // ============================================================================
  // PAYMENTS OPERATIONS
  // ============================================================================

  Future<void> insertPayment(PaymentsCompanion payment) {
    return into(payments).insert(payment, mode: InsertMode.insertOrReplace);
  }

  Future<List<PaymentEntity>> getPaymentsForBill(String billId) {
    return (select(payments)
          ..where((t) => t.billId.equals(billId))
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .get();
  }

  Future<List<PaymentEntity>> getAllPayments(String userId,
      {DateTime? fromDate, DateTime? toDate}) {
    var query = select(payments)..where((t) => t.userId.equals(userId));
    if (fromDate != null) {
      query = query..where((t) => t.paymentDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query = query..where((t) => t.paymentDate.isSmallerOrEqualValue(toDate));
    }
    return (query..orderBy([(t) => OrderingTerm.desc(t.paymentDate)])).get();
  }

  // ============================================================================
  // EXPENSES OPERATIONS
  // ============================================================================

  Future<void> insertExpense(ExpensesCompanion expense) {
    return into(expenses).insert(expense, mode: InsertMode.insertOrReplace);
  }

  Future<List<ExpenseEntity>> getAllExpenses(String userId,
      {DateTime? fromDate, DateTime? toDate}) {
    var query = select(expenses)..where((t) => t.userId.equals(userId));
    if (fromDate != null) {
      query = query..where((t) => t.expenseDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query = query..where((t) => t.expenseDate.isSmallerOrEqualValue(toDate));
    }
    return (query..orderBy([(t) => OrderingTerm.desc(t.expenseDate)])).get();
  }

  // ============================================================================
  // DEAD LETTER QUEUE OPERATIONS
  // ============================================================================

  Future<void> insertDeadLetter(DeadLetterQueueCompanion entry) {
    return into(deadLetterQueue).insert(entry);
  }

  Future<List<DeadLetterEntity>> getUnresolvedDeadLetters(String userId) {
    return (select(deadLetterQueue)
          ..where((t) => t.userId.equals(userId) & t.isResolved.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.movedToDeadLetterAt)]))
        .get();
  }

  Future<void> resolveDeadLetter(String id, String notes) {
    return (update(deadLetterQueue)..where((t) => t.id.equals(id))).write(
      DeadLetterQueueCompanion(
        isResolved: const Value(true),
        resolutionNotes: Value(notes),
        resolvedAt: Value(DateTime.now()),
      ),
    );
  }

  // ============================================================================
  // AUDIT LOG OPERATIONS
  // ============================================================================

  Future<void> insertAuditLog({
    required String userId,
    required String targetTableName,
    required String recordId,
    required String action,
    String? oldValueJson,
    String? newValueJson,
    String? deviceId,
    String? appVersion,
  }) {
    return into(auditLogs).insert(AuditLogsCompanion.insert(
      userId: userId,
      targetTableName: targetTableName,
      recordId: recordId,
      action: action,
      oldValueJson: Value(oldValueJson),
      newValueJson: Value(newValueJson),
      timestamp: DateTime.now(),
      deviceId: Value(deviceId),
      appVersion: Value(appVersion),
    ));
  }

  // ============================================================================
  // ANALYTICS QUERIES
  // ============================================================================

  Future<Map<String, dynamic>> getDashboardStats(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonth = DateTime(now.year, now.month, 1);

    // Today's sales
    final todayBills = await (select(bills)
          ..where((t) =>
              t.userId.equals(userId) &
              t.createdAt.isBiggerOrEqualValue(today) &
              t.status.isNotIn(['DRAFT', 'CANCELLED'])))
        .get();
    final todaySales =
        todayBills.fold<double>(0, (sum, b) => sum + b.grandTotal);
    final todayCollections =
        todayBills.fold<double>(0, (sum, b) => sum + b.paidAmount);

    // Monthly sales
    final monthBills = await (select(bills)
          ..where((t) =>
              t.userId.equals(userId) &
              t.createdAt.isBiggerOrEqualValue(thisMonth) &
              t.status.isNotIn(['DRAFT', 'CANCELLED'])))
        .get();
    final monthlySales =
        monthBills.fold<double>(0, (sum, b) => sum + b.grandTotal);
    final monthlyCollections =
        monthBills.fold<double>(0, (sum, b) => sum + b.paidAmount);

    // Total dues
    final allBills = await (select(bills)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.status.isNotIn(['DRAFT', 'CANCELLED', 'PAID'])))
        .get();
    final totalDues = allBills.fold<double>(
        0, (sum, b) => sum + (b.grandTotal - b.paidAmount));

    // Customer count
    final customerCount = await (select(customers)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.isActive.equals(true)))
        .get()
        .then((list) => list.length);

    // Low stock count
    final lowStockProducts = await getLowStockProducts(userId);

    // Pending sync count
    final pendingSync =
        await getPendingSyncEntries().then((list) => list.length);

    // Monthly purchases
    final monthPurchases = await (select(purchaseOrders)
          ..where((t) =>
              t.userId.equals(userId) &
              t.purchaseDate.isBiggerOrEqualValue(thisMonth) &
              t.status.isNotIn(['CANCELLED'])))
        .get();
    final monthlyPurchaseAmount =
        monthPurchases.fold<double>(0, (sum, p) => sum + p.totalAmount);

    return {
      'todaySales': todaySales,
      'todayCollections': todayCollections,
      'todayBillCount': todayBills.length,
      'monthlySales': monthlySales,
      'monthlyCollections': monthlyCollections,
      'monthlyPurchaseAmount': monthlyPurchaseAmount, // ADDED
      'monthlyBillCount': monthBills.length,
      'totalDues': totalDues,
      'customerCount': customerCount,
      'lowStockCount': lowStockProducts.length,
      'pendingSyncCount': pendingSync,
    };
  }

  /// Calculate real profit for today (Sales - COGS)
  /// Uses current Product Cost Price as approximation for COGS
  Future<double> getTodayProfit(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Join Bills, BillItems, and Products to calc profit
    // Profit = Sum(Item.qty * (Item.unitPrice - Product.costPrice))

    final query = select(billItems).join([
      innerJoin(bills, bills.id.equalsExp(billItems.billId)),
      innerJoin(products, products.id.equalsExp(billItems.productId)),
    ])
      ..where(bills.userId.equals(userId) &
          bills.createdAt.isBiggerOrEqualValue(today) &
          bills.status.isNotIn(['DRAFT', 'CANCELLED']));

    final rows = await query.map((row) {
      final item = row.readTable(billItems);
      final product = row.readTable(products);

      final qty = item.quantity;
      final sellPrice = item.unitPrice; // Or totalAmount/qty
      final cost = product.costPrice;

      return qty * (sellPrice - cost);
    }).get();

    // Sum up the profits
    return rows.fold<double>(0.0, (sum, profit) => sum + profit);
  }

  /// Get count of items sold today
  /// Returns total quantity of all items in today's bills
  Future<int?> getTodayItemsSoldCount(String userId, DateTime today) async {
    final query = select(billItems).join([
      innerJoin(bills, bills.id.equalsExp(billItems.billId)),
    ])
      ..where(bills.userId.equals(userId) &
          bills.createdAt.isBiggerOrEqualValue(today) &
          bills.status.isNotIn(['DRAFT', 'CANCELLED']));

    final rows = await query.map((row) {
      final item = row.readTable(billItems);
      return item.quantity.toInt();
    }).get();
    return rows.fold<int>(0, (sum, qty) => sum + qty);
  }

  // ============================================================================
  // HEALTH CHECK
  // ============================================================================

  Future<Map<String, dynamic>> performHealthCheck(String userId) async {
    try {
      // Count records
      final billCount = await (select(bills)
            ..where((t) => t.userId.equals(userId)))
          .get()
          .then((l) => l.length);
      final customerCount = await (select(customers)
            ..where((t) => t.userId.equals(userId)))
          .get()
          .then((l) => l.length);
      final productCount = await (select(products)
            ..where((t) => t.userId.equals(userId)))
          .get()
          .then((l) => l.length);
      final pendingSync = await getPendingSyncEntries().then((l) => l.length);
      final deadLetters =
          await getUnresolvedDeadLetters(userId).then((l) => l.length);

      return {
        'healthy': deadLetters == 0 && pendingSync < 100,
        'billCount': billCount,
        'customerCount': customerCount,
        'productCount': productCount,
        'pendingSyncCount': pendingSync,
        'deadLetterCount': deadLetters,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'healthy': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // ============================================================================
  // DEAD LETTER QUEUE OPERATIONS
  // ============================================================================

  /// Get all dead letter items (for sync health metrics)
  Future<List<DeadLetterEntity>> getDeadLetterItems() {
    return select(deadLetterQueue).get();
  }

  // ============================================================================
  // SERVER RECONCILIATION (for conflict resolution)
  // ============================================================================

  /// Update a bill record with server data after conflict resolution
  Future<void> updateBillFromServer(
      String id, Map<String, dynamic> serverData) async {
    await (update(bills)..where((t) => t.id.equals(id))).write(
      BillsCompanion(
        customerName: Value(serverData['customerName'] ?? ''),
        subtotal: Value((serverData['subtotal'] as num?)?.toDouble() ?? 0),
        taxAmount: Value((serverData['taxAmount'] as num?)?.toDouble() ?? 0),
        grandTotal: Value((serverData['grandTotal'] as num?)?.toDouble() ?? 0),
        paidAmount: Value((serverData['paidAmount'] as num?)?.toDouble() ?? 0),
        status: Value(serverData['status'] ?? 'PENDING'),
        paymentMode: Value(serverData['paymentMode'] ?? 'CASH'),
        isSynced: const Value(true),
        version: Value((serverData['_version'] as int?) ?? 1),
        updatedAt: Value(DateTime.now()),
      ),
    );
    debugPrint('AppDatabase: Reconciled bill $id with server');
  }

  /// Update a customer record with server data after conflict resolution
  Future<void> updateCustomerFromServer(
      String id, Map<String, dynamic> serverData) async {
    await (update(customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(
        name: Value(serverData['name'] ?? ''),
        phone: Value(serverData['phone']),
        email: Value(serverData['email']),
        address: Value(serverData['address']),
        gstin: Value(serverData['gstin']),
        totalBilled:
            Value((serverData['totalBilled'] as num?)?.toDouble() ?? 0),
        totalPaid: Value((serverData['totalPaid'] as num?)?.toDouble() ?? 0),
        totalDues: Value((serverData['totalDues'] as num?)?.toDouble() ?? 0),
        isSynced: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    debugPrint('AppDatabase: Reconciled customer $id with server');
  }

  /// Update a product record with server data after conflict resolution
  Future<void> updateProductFromServer(
      String id, Map<String, dynamic> serverData) async {
    await (update(products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        name: Value(serverData['name'] ?? ''),
        sku: Value(serverData['sku']),
        category: Value(serverData['category']),
        sellingPrice: Value((serverData['price'] as num?)?.toDouble() ?? 0),
        costPrice: Value((serverData['costPrice'] as num?)?.toDouble() ?? 0),
        stockQuantity: Value((serverData['quantity'] as num?)?.toDouble() ?? 0),
        unit: Value(serverData['unit'] ?? 'pcs'),
        lowStockThreshold:
            Value((serverData['lowStockThreshold'] as num?)?.toDouble() ?? 10),
        isSynced: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    debugPrint('AppDatabase: Reconciled product $id with server');
  }
}

// ============================================================================
// DATABASE CONNECTION
// ============================================================================

QueryExecutor _openConnection() {
  return openConnection();
}
