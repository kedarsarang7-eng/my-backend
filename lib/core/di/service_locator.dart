// ============================================================================
// SERVICE LOCATOR - DEPENDENCY INJECTION
// ============================================================================
// Central dependency injection using GetIt
// ALL services, repositories, and managers are registered here
// NO direct instantiation allowed in UI
//
// ARCHITECTURE ENFORCEMENT:
// - UI MUST use repositories only (never direct Firestore)
// - All data flows through Drift → SyncManager → Firestore
// - SessionManager is the ONLY auth state source
//
// Author: DukanX Engineering
// Version: 3.0.0 (Production Hardened)
// ============================================================================

import '../../features/dashboard/data/dashboard_analytics_repository.dart';

import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

import '../database/app_database.dart';
import '../sync/sync_manager.dart';

import '../sync/background_sync_service.dart';
import '../sync/engine/sync_engine.dart'; // Added
import '../sync/data/drift_sync_repository.dart'; // Added
import '../sync/abstractions/sync_repository.dart'; // Added
import '../error/error_handler.dart';
import '../monitoring/monitoring_service.dart';
import '../services/notification_controller.dart';
import '../../services/audit_service.dart';
import '../services/device_id_service.dart';
import '../../services/daybook_service.dart';

// Event System & Daily Snapshot
import '../services/event_dispatcher.dart';
// import '../services/daily_snapshot_service.dart';
import '../services/notification_listener_service.dart';
import '../repository/vendor_notification_repository.dart';

// Repositories (Single Source of Truth)
import '../repository/bills_repository.dart';
import '../repository/audit_repository.dart';
import '../repository/customers_repository.dart';
import '../services/customer_enforcement_service.dart';

import '../repository/products_repository.dart';
import '../repository/revenue_repository.dart';
import '../repository/purchase_repository.dart';
import '../repository/reports_repository.dart';
import '../repository/bank_repository.dart';
import '../repository/expenses_repository.dart';
import '../repository/udhar_repository.dart';
import '../repository/shop_repository.dart';
import '../repository/onboarding_repository.dart';
import '../repository/vendors_repository.dart';
import '../repository/user_repository.dart';
import '../repository/connection_repository.dart';
import '../repository/customer_profile_repository.dart';
import '../repository/shop_link_repository.dart';

import '../repository/patients_repository.dart';
import '../repository/visits_repository.dart';
import '../repository/clinical_prescription_repository.dart';

// Delivery Challan
import '../../features/delivery_challan/data/repositories/delivery_challan_repository.dart';
import '../../features/delivery_challan/services/delivery_challan_service.dart';

// Reports & Tally
import '../../features/reports/services/tally_xml_service.dart';

// Petrol Pump Services
import '../../features/petrol_pump/services/services.dart';

// Session (Unified)
import '../session/session_manager.dart';

import '../../features/accounting/accounting.dart' as acc;
import '../../features/inventory/data/product_batch_repository.dart';
import '../../features/inventory/services/pharmacy_migration_service.dart';
import '../../features/inventory/services/batch_allocation_service.dart';
import '../../features/inventory/services/inventory_service.dart';

import '../../services/data_integrity_service.dart';

import '../../features/ai_assistant/services/recommendation_service.dart';
import '../../features/ai_assistant/services/customer_recommendation_service.dart';
import '../../features/ai_assistant/services/morning_briefing_service.dart';
import '../../features/ai_assistant/services/voice_intent_service.dart';
import '../../features/pre_order/data/repositories/customer_item_request_repository.dart';
import '../../features/pre_order/data/repositories/vendor_item_snapshot_repository.dart';
import '../../features/pre_order/data/repositories/stock_transaction_repository.dart';
import '../../features/pre_order/services/pre_order_service.dart';
import '../../features/customers/services/customer_link_service.dart';
import '../../features/reports/services/gstr1_service.dart';
import '../../features/party_ledger/services/party_ledger_service.dart';

// Invoice Safety
import '../services/invoice_number_service.dart';

// e-Invoice Module
import '../../features/e_invoice/data/repositories/e_invoice_repository.dart';
import '../../features/e_invoice/data/services/e_invoice_service.dart';
import '../../features/e_invoice/data/services/e_way_bill_service.dart';

// Marketing Module
import '../../features/marketing/data/repositories/marketing_repository.dart';
import '../../features/marketing/data/services/whatsapp_service.dart';

// Payment
import '../../features/payment/services/upi_payment_service.dart';
import '../../features/doctor/data/repositories/appointment_repository.dart';
import '../../features/doctor/data/repositories/prescription_repository.dart';
import '../../features/doctor/services/patient_service.dart';
import '../../features/doctor/services/clinic_billing_service.dart';
import '../../features/payment/data/repositories/payment_repository.dart';

import '../../features/payment/services/payment_orchestrator.dart'; // Payment Orchestrator
import '../../features/doctor/data/repositories/doctor_dashboard_repository.dart';
import '../../features/doctor/data/repositories/patient_repository.dart';
import '../../features/doctor/data/repositories/doctor_repository.dart';

// Staff Management Module
import '../../features/staff/data/repositories/staff_repository.dart';
import '../../features/staff/services/staff_service.dart'; // Added StaffService
import '../../features/staff/data/services/payroll_service.dart';

// ML Services
import '../../features/ml/ml_services/ocr_service.dart';
import '../../features/ml/ml_services/ocr_router.dart';
import '../../features/ml/ml_services/language_service.dart';
import '../../features/ml/ml_services/translation_service.dart';
import '../../features/billing/services/barcode_scanner_service.dart';
import '../../features/billing/services/broker_billing_service.dart'; // Mandi

// Credit Network

// Restaurant / Hotel Module
import '../../features/restaurant/restaurant.dart';

import '../../features/doctor/data/repositories/medical_template_repository.dart';
import '../../features/doctor/data/repositories/lab_report_repository.dart';

// GST Module
import '../../features/gst/repositories/gst_repository.dart';

// Legacy Services (Deprecated)
import '../../services/local_storage_service.dart';
import '../../services/connection_service.dart';

// Licensing System
import '../../services/license_service.dart';
import '../../services/device_fingerprint_service.dart';

/// Global service locator instance
final GetIt sl = GetIt.instance;

/// Track initialization state
bool _isInitialized = false;

/// Initialize all dependencies
/// MUST be called in main.dart BEFORE runApp()
Future<void> initializeDependencies() async {
  if (_isInitialized) {
    monitoring.warning('ServiceLocator', 'Already initialized, skipping');
    return;
  }

  monitoring.info('ServiceLocator', 'Initializing dependencies...');

  // ============================================
  // EXTERNAL SERVICES (Firebase)
  // ============================================
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // ============================================
  // CORE INFRASTRUCTURE
  // ============================================

  // Monitoring Service (already a singleton via global)
  sl.registerLazySingleton<MonitoringService>(() => monitoring);

  // Database (Singleton - shared across app)
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase.instance);

  // Error Handler (Singleton)
  sl.registerLazySingleton<ErrorHandler>(() => ErrorHandler.instance);

  // Dashboard Analytics Repository
  sl.registerLazySingleton<DashboardAnalyticsRepository>(
      () => DashboardAnalyticsRepository(
            database: sl<AppDatabase>(),
            errorHandler: sl<ErrorHandler>(),
          ));

  // Customer Enforcement Service (Credit Limit & Blocking)
  sl.registerLazySingleton<CustomerEnforcementService>(
      () => CustomerEnforcementService(sl<CustomersRepository>()));
  sl.registerLazySingleton<CustomerLinkService>(() => CustomerLinkService(
        database: sl<AppDatabase>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  // Local Storage Service (Deprecated - for backward compatibility)
  sl.registerLazySingleton<LocalStorageService>(() => LocalStorageService());

  // Connection Service
  sl.registerLazySingleton<ConnectionService>(() => ConnectionService());

  // Device ID Service (Singleton)
  sl.registerLazySingleton<DeviceIdService>(() => DeviceIdService.instance);

  // ============================================
  // LICENSING SYSTEM (Enterprise)
  // ============================================

  // Device Fingerprint Service - Cross-platform device identification
  sl.registerLazySingleton<DeviceFingerprintService>(
      () => DeviceFingerprintService());

  // License Service - License validation, activation, and caching
  sl.registerLazySingleton<LicenseService>(
      () => LicenseService(sl<AppDatabase>()));

  // Audit System
  sl.registerLazySingleton<AuditRepository>(() => AuditRepository(
        database: sl<AppDatabase>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<AuditService>(() => AuditService(
        sl<AuditRepository>(),
        sl<DeviceIdService>(),
      ));

  // Udhar Repository
  sl.registerLazySingleton<UdharRepository>(() => UdharRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  // Session Manager (THE ONLY AUTH STATE SOURCE)
  // Replaces old SessionService completely
  sl.registerLazySingleton<SessionManager>(() => SessionManager(
        auth: sl<FirebaseAuth>(),
        firestore: sl<FirebaseFirestore>(),
      ));

  // Sync Queue Local Operations
  sl.registerLazySingleton<SyncQueueLocalOperations>(() => sl<AppDatabase>());

  // Sync Manager (Singleton)
  sl.registerLazySingleton<SyncManager>(() => SyncManager.instance);

  // Background Sync Service (Singleton)
  sl.registerLazySingleton<BackgroundSyncService>(
      () => BackgroundSyncService.instance);

  // Unified Notification Controller
  sl.registerLazySingleton<NotificationController>(
      () => NotificationController());

  // Event Dispatcher
  sl.registerLazySingleton<EventDispatcher>(() => EventDispatcher.instance);

  // Notification Listener Service
  sl.registerLazySingleton<NotificationListenerService>(
      () => NotificationListenerService(
            dispatcher: sl<EventDispatcher>(),
            notificationRepo: sl<VendorNotificationRepository>(),
            customersRepo: sl<CustomersRepository>(),
          ));

  // Vendor Notification Repository
  sl.registerLazySingleton<VendorNotificationRepository>(
      () => VendorNotificationRepository(db: sl<AppDatabase>()));

  // ============================================
  // REPOSITORIES (Single Source of Truth for UI)
  // ============================================

  sl.registerLazySingleton<BillsRepository>(() => BillsRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
        accountingService: sl<acc.AccountingService>(),
        inventoryService: sl<InventoryService>(),
        customerRecommendationService: sl<CustomerRecommendationService>(),
        auditService: sl<AuditService>(),
        productBatchRepository: sl<ProductBatchRepository>(),
        batchAllocationService: sl<BatchAllocationService>(),
        gstRepository: sl<GstRepository>(),
        brokerBillingService: sl<BrokerBillingService>(), // Mandi
      ));

  // Mandi: Broker Billing Service
  sl.registerLazySingleton<BrokerBillingService>(() => BrokerBillingService(
        sl<AppDatabase>(),
        sl<ErrorHandler>(),
        sl<acc.AccountingService>(),
      ));

  sl.registerLazySingleton<CustomersRepository>(() => CustomersRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<ProductsRepository>(() => ProductsRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<RevenueRepository>(() => RevenueRepository(
        db: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<ProductBatchRepository>(() => ProductBatchRepository(
        sl<AppDatabase>(),
      ));

  sl.registerLazySingleton<PurchaseRepository>(() => PurchaseRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
        inventoryService: sl<InventoryService>(),
        productBatchRepository: sl<ProductBatchRepository>(),
      ));

  sl.registerLazySingleton<BankRepository>(() => BankRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<ReportsRepository>(() => ReportsRepository(
        database: sl<AppDatabase>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<ExpensesRepository>(() => ExpensesRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<ShopRepository>(() => ShopRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  // OnboardingRepository - Firestore-first onboarding persistence
  sl.registerLazySingleton<OnboardingRepository>(() => OnboardingRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<VendorsRepository>(() => VendorsRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<ConnectionRepository>(() => ConnectionRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  // Customer-Shop QR Linking Repositories
  sl.registerLazySingleton<CustomerProfileRepository>(
      () => CustomerProfileRepository(
            database: sl<AppDatabase>(),
            syncManager: sl<SyncManager>(),
            errorHandler: sl<ErrorHandler>(),
          ));

  sl.registerLazySingleton<ShopLinkRepository>(() => ShopLinkRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<PatientsRepository>(() => PatientsRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<VisitsRepository>(() => VisitsRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<ClinicalPrescriptionRepository>(
      () => ClinicalPrescriptionRepository(
            database: sl<AppDatabase>(),
            syncManager: sl<SyncManager>(),
            errorHandler: sl<ErrorHandler>(),
          ));

  // DOCTOR / CLINIC MODULE SERVICES
  sl.registerLazySingleton<PatientRepository>(() => PatientRepository(
        db: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
      ));

  sl.registerLazySingleton<DoctorRepository>(() => DoctorRepository(
        db: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
      ));

  sl.registerLazySingleton<AppointmentRepository>(() => AppointmentRepository(
        db: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
      ));

  sl.registerLazySingleton<PrescriptionRepository>(() => PrescriptionRepository(
        db: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
      ));

  sl.registerLazySingleton<DoctorDashboardRepository>(
      () => DoctorDashboardRepository(
            sl<AppDatabase>(),
          ));

  sl.registerLazySingleton<MedicalTemplateRepository>(
      () => MedicalTemplateRepository(
            db: sl<AppDatabase>(),
            syncManager: sl<SyncManager>(),
          ));

  sl.registerLazySingleton<LabReportRepository>(() => LabReportRepository(
        db: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
      ));

  sl.registerLazySingleton<ClinicBillingService>(() => ClinicBillingService(
        db: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        inventoryService: sl<InventoryService>(),
      ));

  // ============================================
  // NEW COMPETITIVE FEATURE REPOSITORIES
  // ============================================

  // Staff Management Repository
  sl.registerLazySingleton<StaffRepository>(
      () => StaffRepository(sl<AppDatabase>()));

  // Staff Payroll Service
  sl.registerLazySingleton<PayrollService>(
      () => PayrollService(sl<StaffRepository>()));

  // NEW Staff Service (Replaces/Enhances StaffRepository)
  sl.registerLazySingleton<StaffService>(() => StaffService(
        db: sl<AppDatabase>(),
        auditRepo: sl<AuditRepository>(),
        sessionManager: sl<SessionManager>(),
      ));

  // Marketing/CRM Repository
  sl.registerLazySingleton<MarketingRepository>(
      () => MarketingRepository(sl<AppDatabase>()));

  // WhatsApp Service
  sl.registerLazySingleton<WhatsAppService>(() => WhatsAppService());

  // e-Invoice Repository
  sl.registerLazySingleton<EInvoiceRepository>(
      () => EInvoiceRepository(sl<AppDatabase>()));

  // e-Invoice Service
  sl.registerLazySingleton<EInvoiceService>(() => EInvoiceService(
        sl<EInvoiceRepository>(),
        auditService: sl<AuditService>(),
      ));

  // e-Way Bill Service
  sl.registerLazySingleton<EWayBillService>(
      () => EWayBillService(sl<EInvoiceRepository>()));

  sl.registerLazySingleton<CustomerItemRequestRepository>(
      () => CustomerItemRequestRepository(
            db: sl<AppDatabase>(),
            syncManager: sl<SyncManager>(),
          ));

  sl.registerLazySingleton<VendorItemSnapshotRepository>(
      () => VendorItemSnapshotRepository(
            firestore: sl<FirebaseFirestore>(),
            localStorage: sl<LocalStorageService>(),
          ));

  sl.registerLazySingleton<StockTransactionRepository>(
      () => StockTransactionRepository(
            firestore: sl<FirebaseFirestore>(),
            syncManager: sl<SyncManager>(),
          ));

  sl.registerLazySingleton<PreOrderService>(() => PreOrderService(
        requestRepository: sl<CustomerItemRequestRepository>(),
        billsRepository: sl<BillsRepository>(),
        productsRepository: sl<ProductsRepository>(),
        stockTxnRepo: sl<StockTransactionRepository>(),
        snapshotRepo: sl<VendorItemSnapshotRepository>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<UserRepository>(() => UserRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
      ));

  sl.registerLazySingleton<acc.AccountingRepository>(
      () => acc.AccountingRepository(db: sl<AppDatabase>()));

  // Accounting Services
  // Internal service for journaling - separate from policy
  sl.registerLazySingleton<acc.JournalEntryService>(
      () => acc.JournalEntryService(repo: sl<acc.AccountingRepository>()));

  // Public service with locking policy
  sl.registerLazySingleton<acc.AccountingService>(() => acc.AccountingService(
        sl<acc.JournalEntryService>(),
        sl<acc.LockingService>(),
      ));

  sl.registerLazySingleton<acc.FinancialReportsService>(
      () => acc.FinancialReportsService(repo: sl<acc.AccountingRepository>()));

  sl.registerLazySingleton<DayBookService>(() => DayBookService(
        sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
      ));

  sl.registerLazySingleton<acc.LockingService>(
      () => acc.LockingService(sl<AppDatabase>()));
  sl.registerLazySingleton<PartyLedgerService>(() => PartyLedgerService(
        accountingRepo: sl<acc.AccountingRepository>(),
        reportsService: sl<acc.FinancialReportsService>(),
        db: sl<AppDatabase>(),
      ));

  // Inventory
  sl.registerLazySingleton<InventoryService>(() => InventoryService(
        sl<AppDatabase>(),
        sl<acc.LockingService>(),
        sl<acc.AccountingService>(),
        sl<SyncManager>(),
        sl<ProductBatchRepository>(),
      ));

  sl.registerLazySingleton<BatchAllocationService>(() => BatchAllocationService(
        productBatchRepository: sl<ProductBatchRepository>(),
      ));

  sl.registerLazySingleton<PharmacyMigrationService>(
      () => PharmacyMigrationService(
            sl<ProductsRepository>(),
            sl<ProductBatchRepository>(),
          ));

  // Data Integrity & Crash Recovery
  sl.registerLazySingleton<DataIntegrityService>(() => DataIntegrityService(
        database: sl<AppDatabase>(),
      ));

  // Invoice Number Safety Service
  sl.registerLazySingleton<InvoiceNumberService>(
      () => InvoiceNumberService(sl<AppDatabase>()));

  // ============================================
  // PETROL PUMP SERVICES
  // ============================================

  sl.registerLazySingleton<FuelService>(() => FuelService());
  sl.registerLazySingleton<DispenserService>(() => DispenserService());
  sl.registerLazySingleton<ShiftService>(() => ShiftService());
  sl.registerLazySingleton<TankService>(() => TankService());
  sl.registerLazySingleton<PetrolPumpBillingService>(
      () => PetrolPumpBillingService());
  sl.registerLazySingleton<CalibrationReminderService>(
      () => CalibrationReminderService(sl<AppDatabase>()));

  // ============================================
  // AI / RECOMMENDATION SERVICES
  // ============================================

  sl.registerLazySingleton<CustomerRecommendationService>(
      () => CustomerRecommendationService(
            sl<AppDatabase>(),
            sl<CustomersRepository>(),
          ));

  // ============================================
  // ML KIT SERVICES
  // ============================================
  sl.registerLazySingleton<MLKitOcrService>(() {
    final service = MLKitOcrService();
    // Disposal is handled by the service itself if needed, or we can use lazy singleton lifecycle
    // For services that need explicit disposal on app exit, we might need a disposal logic in main
    return service;
  });

  sl.registerLazySingleton<LanguageDetectionService>(() {
    final service = LanguageDetectionService();
    return service;
  });

  // OcrRouter
  sl.registerLazySingleton<OcrRouter>(() => OcrRouter());

  sl.registerLazySingleton<TranslationService>(() {
    final service = TranslationService();
    return service;
  });

  sl.registerLazySingleton<BarcodeScannerService>(
      () => BarcodeScannerService());

  // AI Assistant
  sl.registerLazySingleton<RecommendationService>(() => RecommendationService(
        sl<ProductsRepository>(),
        sl<BillsRepository>(),
      ));
  sl.registerLazySingleton<MorningBriefingService>(
      () => MorningBriefingService(sl<ReportsRepository>()));
  sl.registerLazySingleton<VoiceIntentService>(() => VoiceIntentService());
  sl.registerLazySingleton<GSTR1Service>(
      () => GSTR1Service(sl<BillsRepository>(), sl<CustomersRepository>()));

  // NOTE: Marketing, Staff modules already registered in "NEW COMPETITIVE FEATURE REPOSITORIES" section above

  // ============================================
  // RESTAURANT / HOTEL MODULE
  // ============================================
  sl.registerLazySingleton<FoodMenuRepository>(() => FoodMenuRepository());
  sl.registerLazySingleton<FoodOrderRepository>(() => FoodOrderRepository());
  sl.registerLazySingleton<RestaurantTableRepository>(
      () => RestaurantTableRepository());
  sl.registerLazySingleton<RestaurantBillRepository>(
      () => RestaurantBillRepository());
  sl.registerLazySingleton<QrCodeService>(() => QrCodeService());
  sl.registerLazySingleton<RestaurantSyncService>(() => RestaurantSyncService(
        menuRepo: sl<FoodMenuRepository>(),
        orderRepo: sl<FoodOrderRepository>(),
        tableRepo: sl<RestaurantTableRepository>(),
        billRepo: sl<RestaurantBillRepository>(),
        syncManager: sl<SyncManager>(),
      ));
  sl.registerLazySingleton<RestaurantNotificationService>(
      () => RestaurantNotificationService());
  sl.registerLazySingleton<RestaurantPdfBillService>(
      () => RestaurantPdfBillService());

  // ============================================
  // PAYMENT SERVICES
  // ============================================
  sl.registerLazySingleton<UpiPaymentService>(
      () => UpiPaymentService(sl<AppDatabase>()));

  sl.registerLazySingleton<PaymentRepository>(() => PaymentRepository(
        database: sl<AppDatabase>(),
        syncManager: sl<SyncManager>(),
        errorHandler: sl<ErrorHandler>(),
        auditService: sl<AuditService>(),
      ));

  // Delivery Challan Module
  sl.registerLazySingleton<DeliveryChallanRepository>(
      () => DeliveryChallanRepository(sl<AppDatabase>()));

  sl.registerLazySingleton<DeliveryChallanService>(() => DeliveryChallanService(
        sl<DeliveryChallanRepository>(),
        sl<BillsRepository>(),
        sl<ProductsRepository>(),
        sl<InvoiceNumberService>(),
        sl<SessionManager>(),
      ));

  // Reports
  sl.registerLazySingleton<TallyXmlService>(() => TallyXmlService(
        sl<BillsRepository>(),
        sl<PaymentRepository>(),
        sl<CustomersRepository>(),
        sl<GstRepository>(),
        sl<PurchaseRepository>(),
        sl<VendorsRepository>(),
        sl<ShopRepository>(),
      ));

  // GST Module
  sl.registerLazySingleton<GstRepository>(
      () => GstRepository(db: sl<AppDatabase>()));

  // Payment Orchestrator
  sl.registerLazySingleton<PaymentOrchestrator>(() => PaymentOrchestrator());

  // Initialize Restaurant Services
  await sl<RestaurantNotificationService>().initialize();

  // Initialize Event Listeners
  sl<NotificationListenerService>().initialize();

  // ============================================
  // INITIALIZE SYNC ENGINE (Isolated)
  // ============================================
  try {
    // Register Sync Repository and Engine if not already registered (lazy singletons)
    if (!sl.isRegistered<SyncRepository>()) {
      sl.registerLazySingleton<SyncRepository>(
          () => DriftSyncRepository(sl<AppDatabase>()));
    }
    if (!sl.isRegistered<SyncEngine>()) {
      sl.registerLazySingleton<SyncEngine>(() => SyncEngine.instance);
    }

    // Initialize Engine
    final engine = sl<SyncEngine>();
    engine.initialize(
      repository: sl<SyncRepository>(),
      // process: sl<TaskProcessor>() // optional if we registered it
    );
    monitoring.info('ServiceLocator', 'SyncEngine (Isolated) initialized');

    // Initialize Local Storage Service (Deprecated)
    await sl<LocalStorageService>().init();
    monitoring.info('ServiceLocator', 'LocalStorageService initialized');

    // LEGACY SyncManager - WRITE-ONLY MODE
    // initialized to allow legacy enqueue() calls to write to Drift
    // but DISABLED processing to prevent double-execution.
    if (kIsWeb) {
      // On web, defer sync manager init slightly to let IndexedDB stabilize
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          await sl<SyncManager>().initialize(
            localOperations: sl<SyncQueueLocalOperations>(),
            config: const SyncManagerConfig(
              maxConcurrency: 1,
              batchSize: 5,
              autoStart: false,
              enabled: false, // DISABLE PROCESSING
            ),
          );
          monitoring.info(
              'ServiceLocator', 'SyncManager initialized (Write-Only)');
        } catch (e) {
          monitoring.warning('ServiceLocator',
              'SyncManager init skipped on web: ${e.toString()}');
        }
      });
    } else {
      await sl<SyncManager>().initialize(
        localOperations: sl<SyncQueueLocalOperations>(),
        config: const SyncManagerConfig(
          maxConcurrency: 1,
          batchSize: 10,
          autoStart: false,
          enabled: false, // DISABLE PROCESSING
        ),
      );
      monitoring.info('ServiceLocator', 'SyncManager initialized (Write-Only)');
    }
  } catch (e, stack) {
    monitoring.warning('ServiceLocator', 'SyncEngine init failed: $e');
    debugPrint('SyncEngine init stack: $stack');
  }

  _isInitialized = true;
  monitoring.info('ServiceLocator', 'All dependencies initialized');
}

/// Reset all dependencies (for testing)
Future<void> resetDependencies() async {
  await sl.reset();
  _isInitialized = false;
}

/// Check if dependencies are initialized
bool get isDependenciesInitialized => _isInitialized;

// ============================================================================
// CONVENIENCE GETTERS (Type-safe access)
// ============================================================================

/// Get the session manager (ONLY auth state source)
SessionManager get sessionManager => sl<SessionManager>();

/// Get the database
AppDatabase get database => sl<AppDatabase>();

/// Get the sync manager
SyncManager get syncManagerInstance => sl<SyncManager>();

/// Get the error handler
ErrorHandler get errorHandlerInstance => sl<ErrorHandler>();

// Repositories
BillsRepository get billsRepository => sl<BillsRepository>();
PatientsRepository get patientsRepository => sl<PatientsRepository>();
VisitsRepository get visitsRepository => sl<VisitsRepository>();
CustomersRepository get customersRepository => sl<CustomersRepository>();
ProductsRepository get productsRepository => sl<ProductsRepository>();
RevenueRepository get revenueRepository => sl<RevenueRepository>();
PurchaseRepository get purchaseRepository => sl<PurchaseRepository>();
BankRepository get bankRepository => sl<BankRepository>();
ReportsRepository get reportsRepository => sl<ReportsRepository>();
ExpensesRepository get expensesRepository => sl<ExpensesRepository>();
UdharRepository get udharRepository => sl<UdharRepository>();
ShopRepository get shopRepository => sl<ShopRepository>();
VendorsRepository get vendorsRepository => sl<VendorsRepository>();
UserRepository get userRepository => sl<UserRepository>();
CustomerItemRequestRepository get customerItemRequestRepository =>
    sl<CustomerItemRequestRepository>();

PatientRepository get patientRepository => sl<PatientRepository>();
DoctorRepository get doctorRepository => sl<DoctorRepository>();
AppointmentRepository get appointmentRepository => sl<AppointmentRepository>();
PrescriptionRepository get prescriptionRepository =>
    sl<PrescriptionRepository>();

PatientService get patientService => sl<PatientService>();

// Petrol Pump Services
FuelService get fuelService => sl<FuelService>();
DispenserService get dispenserService => sl<DispenserService>();
ShiftService get shiftService => sl<ShiftService>();
TankService get tankService => sl<TankService>();
PetrolPumpBillingService get petrolPumpBillingService =>
    sl<PetrolPumpBillingService>();

// Restaurant Module
FoodMenuRepository get foodMenuRepository => sl<FoodMenuRepository>();
FoodOrderRepository get foodOrderRepository => sl<FoodOrderRepository>();
RestaurantTableRepository get restaurantTableRepository =>
    sl<RestaurantTableRepository>();
RestaurantBillRepository get restaurantBillRepository =>
    sl<RestaurantBillRepository>();
QrCodeService get qrCodeService => sl<QrCodeService>();
RestaurantSyncService get restaurantSyncService => sl<RestaurantSyncService>();
RestaurantNotificationService get restaurantNotificationService =>
    sl<RestaurantNotificationService>();
RestaurantPdfBillService get restaurantPdfBillService =>
    sl<RestaurantPdfBillService>();

// Payment Repository

// ============================================================================
// DEPRECATED: Old session service compatibility
// Use SessionManager instead
// ============================================================================

/// @Deprecated('Use sessionManager instead')
/// This getter provides backward compatibility during migration
/// It returns the SessionManager which has compatible API
SessionManager get sessionService => sessionManager;

/// @Deprecated('Use repositories instead')
LocalStorageService get localStorageService => sl<LocalStorageService>();
