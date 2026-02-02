// ============================================================================
// DUKANX - MAIN ENTRY POINT
// ============================================================================
// Production-ready bootstrap with proper dependency injection
//
// ARCHITECTURE:
// UI → Riverpod State → Repository → Drift DB → SyncManager → Firestore
//
// Author: DukanX Engineering
// Version: 3.0.0 (Production Hardened)
// ============================================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:workmanager/workmanager.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';
import 'package:dukanx/generated/app_localizations.dart';

// Core DI & Session
import 'core/di/service_locator.dart';
import 'core/auth/auth_intent_service.dart';

import 'core/monitoring/monitoring_service.dart';
import 'core/sync/background_sync_service.dart';
import 'core/sync/sync_manager.dart';

import 'core/database/app_database.dart';
import 'core/app_bootstrap.dart';
import 'core/sync/sync_conflict_listener.dart'; // Added
import 'core/lifecycle/app_lifecycle_observer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/data_integrity_service.dart';

// Screens
import 'screens/dukanx_splash_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_selection_screen.dart';
import 'widgets/error_boundary.dart';
import 'features/auth/presentation/screens/vendor_auth_screen.dart';
import 'features/auth/presentation/screens/customer_auth_screen.dart';
import 'screens/vendor_qr_code_screen.dart';
import 'screens/customer_link_shop_screen.dart';
import 'screens/professional_startup_screen.dart';
import 'features/dashboard/presentation/screens/home_screen.dart'; // Contains HomeScreenModern
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_controller.dart';
import 'features/auth/presentation/screens/auth_wrapper.dart';
import 'features/customers/presentation/screens/customer_home_screen.dart';
import 'features/customers/presentation/screens/my_linked_shops_screen.dart';
import 'screens/real_sync_screen.dart'; // IMPORT ADDED

// import 'screens/billing_screen.dart'; // Deleted

import 'screens/billing_flow.dart';
import 'screens/pending_screen.dart';
import 'screens/customer_bills.dart';
import 'screens/bill_search_screen.dart';
import 'screens/advanced_billing_screen.dart';
import 'screens/advanced_bill_creation_screen.dart';
import 'screens/blacklist_management_screen.dart';
import 'screens/billing_reports_screen.dart';
import 'features/customers/presentation/screens/add_customer_screen.dart';
import 'features/customers/presentation/screens/customers_list_screen.dart';
import 'screens/total_bills_screen.dart';
import 'screens/total_paid_screen.dart';
import 'screens/pending_dues_screen.dart';
import 'screens/customer_report_screen.dart';

import 'features/settings/presentation/screens/main_settings_screen.dart';
import 'screens/admin_migrations_screen.dart';
import 'screens/owner_link_screen.dart';
import 'screens/customer_link_accept_screen.dart';
import 'screens/cloud_sync_settings_screen.dart';
import 'screens/shop_selection_screen.dart';
import 'screens/developer_health_screen.dart';
import 'screens/editable_invoice_screen.dart';
import 'screens/invoice_preview_screen.dart';
import 'screens/business_type_selection_screen.dart';
import 'features/inventory/presentation/screens/barcode_scanner_screen.dart';
import 'screens/app_management_screen.dart';

// Models (Canonical)
import 'core/repository/customers_repository.dart' show Customer;
import 'models/bill.dart' show Bill;
import 'models/invoice_editable.dart';
import 'models/business_type.dart'; // Core Enum

// State Providers (Riverpod-based)
import 'providers/app_state_providers.dart';

// Onboarding & Features
import 'features/onboarding/vendor_onboarding_screen.dart';
import 'features/settings/business_settings_screen.dart';
import 'features/profile/screens/vendor_profile_screen.dart';
import 'features/billing/presentation/screens/bill_scan_screen.dart';
import 'features/insights/presentation/screens/insights_screen.dart';
import 'features/settings/presentation/screens/template_designer_screen.dart';
import 'features/alerts/presentation/screens/alerts_screen.dart';
import 'features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import 'features/analytics/analytics_dashboard_screen.dart';
import 'features/backup/screens/backup_screen.dart';
import 'features/gst/screens/gst_reports_screen.dart';
import 'features/daybook/presentation/screens/day_book_screen.dart';
import 'features/customers/presentation/screens/customer_notifications_screen.dart';
import 'features/catalogue/presentation/screens/catalogue_screen.dart';
import 'screens/payment_history_screen.dart';

// Service/Repair Module
import 'features/service/service.dart';

// Clinic Module
import 'features/doctor/presentation/screens/appointment_screen.dart';
import 'features/doctor/presentation/screens/add_prescription_screen.dart';
import 'features/doctor/presentation/screens/patient_list_screen.dart';

// Petrol Pump Module
import 'features/petrol_pump/presentation/screens/dispenser_list_screen.dart';
import 'features/petrol_pump/presentation/screens/fuel_rates_screen.dart';

// Party Ledger Module
import 'features/party_ledger/party_ledger.dart';

// Guards
import 'core/auth/role_guard.dart';

// AuthGate - Single Entry Point
import 'core/auth/auth_gate.dart';

// Keyboard Architecture - Tally-Style Shortcuts
import 'core/keyboard/global_keyboard_handler.dart';
import 'widgets/desktop/keyboard_help_overlay.dart';

// Business Type Guard
import 'features/core/auth/business_type_guard.dart'; // Protection Layer

// Global Keys for Navigation stability
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> globalScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Global state flags
bool firebaseReady = true;
String? firebaseInitError;

// ============================================================================
// WORKMANAGER CALLBACK (Must be top-level)
// ============================================================================
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      developer.log('Background task started: $taskName', name: 'WorkManager');

      // Initialize Firebase for background
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Perform sync
      if (taskName == BackgroundSyncService.syncTaskName) {
        // Get pending count and sync
        final database = AppDatabase.instance;
        final pending = await database.getPendingSyncEntries();

        if (pending.isNotEmpty) {
          // Initialize sync manager and perform sync
          final syncManager = SyncManager.instance;
          await syncManager.initialize(localOperations: database);
          await syncManager.forceSyncAll();
        }

        developer.log(
          'Background sync completed: ${pending.length} items',
          name: 'WorkManager',
        );
      }

      return true;
    } catch (e, stack) {
      developer.log(
        'Background task failed: $e',
        name: 'WorkManager',
        stackTrace: stack,
      );
      return false;
    }
  });
}

// ============================================================================
// MAIN ENTRY POINT
// ============================================================================
void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 1. Load environment config
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        developer.log("Environment config load failed: $e", name: 'main');
      }

      // 1.5. Initialize Google Sign-In (v7.x requirement)
      try {
        await GoogleSignIn.instance.initialize();
      } catch (e) {
        developer.log("Google Sign-In initialization failed: $e", name: 'main');
      }

      // 2. Configure Flutter error handling (Crash Prevention)
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        monitoring.fatal(
          'FlutterError',
          details.exceptionAsString(),
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      // 2.1 Global UI Error Fallback (Prevents Gray/Red Screen of Death)
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return MainErrorFallback(details: details);
      };

      // 3. CRITICAL: Initialize dependency injection FIRST
      await initializeDependencies();
      developer.log('✓ Dependencies initialized', name: 'main');

      // 4. Initialize Firebase
      await _bootstrapFirebase();
      developer.log('✓ Firebase initialized', name: 'main');

      // 5. Initialize WorkManager for background sync
      await _initializeWorkManager();
      developer.log('✓ WorkManager initialized', name: 'main');

      // 6. Initialize AuthIntentService for login intent persistence
      await authIntent.initialize();
      developer.log('✓ AuthIntentService initialized', name: 'main');

      // 7. Register global app lifecycle observer for sync on resume
      AppLifecycleObserver.instance.register();
      developer.log('✓ AppLifecycleObserver registered', name: 'main');

      // 8. Start application
      runApp(const riverpod.ProviderScope(child: DukanXApp()));
    },
    (error, stack) {
      developer.log(
        'Uncaught zone error: $error',
        name: 'main',
        stackTrace: stack,
      );
      monitoring.fatal(
        'ZoneError',
        error.toString(),
        error: error,
        stackTrace: stack,
      );
    },
  );
}

// ============================================================================
// FIREBASE BOOTSTRAP
// ============================================================================
Future<void> _bootstrapFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      developer.log('Firebase already initialized', name: 'main');
      return;
    }

    // Step 1: Initialize Firebase Core
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 20));

    developer.log('Firebase Core initialized', name: 'main');

    // Step 2: Initialize App Check
    await _initializeAppCheck();

    // Step 3: Configure Firestore
    await _configureFirestoreSettings();

    // Step 4: Warmup connection
    await _warmupFirestore();

    firebaseReady = true;
    firebaseInitError = null;
    developer.log('Firebase bootstrap complete', name: 'main');
  } catch (e, stack) {
    developer.log(
      'Firebase initialization failed: $e',
      name: 'main',
      stackTrace: stack,
    );
    firebaseReady = false;
    firebaseInitError = e.toString();
    // App can continue in offline mode
  }
}

Future<void> _initializeAppCheck() async {
  try {
    const isDebug = bool.fromEnvironment('dart.vm.product') == false;

    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider(
        '6LcYWjYsAAAAAGbbveVV_QrGv03ePVEMm9yYNFKB',
      ),
      androidProvider: isDebug
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: isDebug ? AppleProvider.debug : AppleProvider.appAttest,
    );

    await FirebaseAppCheck.instance
        .getToken(true)
        .timeout(const Duration(seconds: 10))
        .catchError((_) => null);

    developer.log('App Check initialized', name: 'main');
  } catch (e) {
    developer.log('App Check warning: $e', name: 'main');
  }
}

Future<void> _configureFirestoreSettings() async {
  try {
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } else {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  } catch (e) {
    developer.log('Firestore settings failed: $e', name: 'main');
  }
}

Future<void> _warmupFirestore() async {
  // On web, warmup in background without blocking startup
  if (kIsWeb) {
    _warmupFirestoreWeb();
    return;
  }

  // Native: blocking warmup with retries
  for (int i = 0; i < 3; i++) {
    try {
      await FirebaseFirestore.instance.enableNetwork().timeout(
        const Duration(seconds: 5),
      );
      developer.log('Firestore network enabled', name: 'main');
      break;
    } catch (e) {
      if (i < 2) {
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
  }
}

/// Web-specific warmup that runs in background
void _warmupFirestoreWeb() {
  // Run warmup async without blocking
  Future.microtask(() async {
    // Multiple warmup attempts over 10 seconds
    for (int i = 0; i < 5; i++) {
      try {
        await FirebaseFirestore.instance.enableNetwork().timeout(
          const Duration(seconds: 3),
        );
        developer.log(
          'Web: Firestore warmup success on attempt ${i + 1}',
          name: 'main',
        );
        return; // Success
      } catch (e) {
        developer.log(
          'Web: Firestore warmup attempt ${i + 1} failed: $e',
          name: 'main',
        );
        await Future.delayed(Duration(seconds: 2));
      }
    }
    developer.log(
      'Web: Firestore warmup completed (may still be connecting)',
      name: 'main',
    );
  });
}

// ============================================================================
// WORKMANAGER INITIALIZATION
// ============================================================================
Future<void> _initializeWorkManager() async {
  if (kIsWeb) return; // WorkManager not supported on web

  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Register periodic sync task (every 15 minutes)
    await Workmanager().registerPeriodicTask(
      BackgroundSyncService.syncTaskId,
      BackgroundSyncService.syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    developer.log('WorkManager registered for background sync', name: 'main');
  } catch (e) {
    developer.log('WorkManager init failed: $e', name: 'main');
  }
}

// ============================================================================
// POST-LOGIN ENTERPRISE INIT
// ============================================================================
Future<void> initEnterpriseServicesForUser(String userId) async {
  if (AppBootstrap.instance.isInitialized) {
    developer.log('Enterprise services already initialized', name: 'main');
    return;
  }

  try {
    await AppBootstrap.instance.initialize(
      userId: userId,
      enableBackgroundSync: !kIsWeb,
    );
    developer.log('Enterprise services initialized for user', name: 'main');

    // ================================================================
    // AUDIT FIX: Automatic weekly integrity verification
    // Ensures 100/100 audit compliance by detecting data drift
    // ================================================================
    _runWeeklyIntegrityCheck(userId);
  } catch (e, stack) {
    developer.log(
      'Enterprise init failed: $e',
      name: 'main',
      stackTrace: stack,
    );
  }
}

/// Background integrity check that runs weekly
/// Fire-and-forget to not block user experience
void _runWeeklyIntegrityCheck(String userId) {
  Future.microtask(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt('lastIntegrityCheck') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const weekInMs = 7 * 24 * 60 * 60 * 1000; // 7 days

      if (now - lastCheck > weekInMs) {
        developer.log('Running weekly integrity check...', name: 'integrity');

        // Create integrity service directly with database
        final integrityService = DataIntegrityService(
          database: AppDatabase.instance,
        );

        // Stock integrity check with auto-fix
        final stockResult = await integrityService
            .verifyAndAutoFixStockIntegrity(
              userId,
              minorThreshold: 1.0,
              alertThreshold: 5.0,
            );
        developer.log(
          'Stock integrity: ${stockResult.checkedCount} products, '
          '${stockResult.minorFixCount} corrections',
          name: 'integrity',
        );

        // Customer ledger integrity check
        final ledgerResult = await integrityService.reconcileCustomerBalance(
          userId,
        );
        developer.log(
          'Ledger integrity: ${ledgerResult.checkedCount} customers, '
          '${ledgerResult.correctionCount} corrected',
          name: 'integrity',
        );

        await prefs.setInt('lastIntegrityCheck', now);
        developer.log('Weekly integrity check complete', name: 'integrity');
      }
    } catch (e) {
      developer.log(
        'Integrity check failed (non-blocking): $e',
        name: 'integrity',
      );
    }
  });
}

// ============================================================================
// MAIN APPLICATION WIDGET
// ============================================================================
class DukanXApp extends riverpod.ConsumerWidget {
  const DukanXApp({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    // Watch theme and locale from Riverpod providers
    final themeState = ref.watch(themeStateProvider);
    final localeState = ref.watch(localeStateProvider);

    return ErrorBoundary(
      child: MaterialApp(
        navigatorKey: globalNavigatorKey,
        scaffoldMessengerKey: globalScaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'DukanX',
        locale: localeState.locale,
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
          Locale('mr'),
          Locale('gu'),
          Locale('ta'),
          Locale('te'),
          Locale('kn'),
          Locale('ml'),
          Locale('bn'),
          Locale('pa'),
          Locale('ur'),
        ],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        themeMode: themeState.isDark ? ThemeMode.dark : ThemeMode.light,
        theme: themeState.lightTheme,
        darkTheme: themeState.darkTheme,
        initialRoute: '/',
        routes: _buildRoutes(),
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => const ProfessionalStartupScreen(),
          );
        },
        // We wrap the entire app in the builder to ensure:
        // 1. Directionality is available for Stack/Overlays
        // 2. Theme/MediaQuery are available for GlobalKeyboardHandler/HelpOverlay
        // 3. ScaffoldMessenger is available for GlobalKeyboardHandler
        builder: (context, child) {
          return GlobalKeyboardHandler(
            onHelpRequested: () {
              // F1 Help overlay is managed via keyboardStateProvider
            },
            onQuitRequested: () {
              // Handle app quit request
            },
            child: SyncConflictListener(
              navigatorKey: globalNavigatorKey,
              child: Stack(
                children: [
                  // The main app content (Navigator)
                  child!,
                  // Global Overlays (always on top)
                  const KeyboardHelpOverlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      // Entry Point
      '/': (context) => const DukanXSplashScreen(),
      '/auth_gate': (context) => const AuthGate(),
      '/auth_wrapper': (context) => const AuthWrapper(),

      // Dashboard Selection
      '/dashboard_selection': (context) => const DashboardSelectionScreen(),

      // Authentication
      '/vendor_auth': (context) => const VendorAuthScreen(),
      '/customer_auth': (context) => const CustomerAuthScreen(),

      // Linking
      '/vendor_qr_code': (context) =>
          VendorRoleGuard(child: const VendorQRCodeScreen()),
      '/customer_link_shop': (context) => const CustomerLinkShopScreen(),

      // Core
      '/startup': (context) => const ProfessionalStartupScreen(),
      '/home': (context) => VendorRoleGuard(child: const HomeScreenModern()),
      '/home_modern': (context) =>
          VendorRoleGuard(child: const HomeScreenModern()),
      '/owner_dashboard': (context) =>
          VendorRoleGuard(child: const DashboardController()),

      // Legacy redirects
      '/signup': (context) => const VendorAuthScreen(),
      '/login': (context) => const DashboardSelectionScreen(),
      '/forgot_password': (context) => const ForgotPasswordScreen(),
      '/owner_login': (context) => const VendorAuthScreen(),
      '/customer_login': (context) => const CustomerAuthScreen(),

      '/shop_selection': (context) => const ShopSelectionScreen(),
      '/business_type_selection': (context) =>
          const BusinessTypeSelectionScreen(),

      // Vendor Onboarding
      '/vendor_onboarding': (context) => const VendorOnboardingScreen(),
      '/business_settings': (context) =>
          VendorRoleGuard(child: const BusinessSettingsScreen()),
      '/vendor_profile': (context) =>
          VendorRoleGuard(child: const VendorProfileScreen()),

      // Billing (Owner Protected)
      // '/billing': (context) => VendorRoleGuard(child: const BillingScreen()),
      '/pending': (context) => VendorRoleGuard(child: const PendingScreen()),

      '/billing_flow': (context) => VendorRoleGuard(child: const BillingFlow()),
      '/customer_bills': (context) =>
          VendorRoleGuard(child: const CustomerBillsScreen()),
      '/bill_search': (context) =>
          VendorRoleGuard(child: const BillSearchScreen()),
      '/advanced_billing': (context) =>
          VendorRoleGuard(child: const AdvancedBillingScreen()),
      '/blacklist': (context) =>
          VendorRoleGuard(child: const BlacklistManagementScreen()),
      '/reports': (context) =>
          VendorRoleGuard(child: const BillingReportsScreen()),
      '/add_customer': (context) =>
          VendorRoleGuard(child: const AddCustomerScreen()),
      '/total_bills': (context) =>
          VendorRoleGuard(child: const TotalBillsScreen()),
      '/total_paid': (context) =>
          VendorRoleGuard(child: const TotalPaidScreen()),
      '/pending_dues': (context) =>
          VendorRoleGuard(child: const PendingDuesScreen()),
      '/customers_list': (context) =>
          VendorRoleGuard(child: const CustomersListScreen()),

      // Settings & Admin
      '/settings': (context) => VendorRoleGuard(child: const SettingsScreen()),
      '/admin/recompute_dues': (context) =>
          VendorRoleGuard(child: const AdminMigrationsScreen()),
      '/dev_health': (context) =>
          VendorRoleGuard(child: const DeveloperHealthScreen()),

      // Cloud & Linking
      '/owner_link': (context) =>
          VendorRoleGuard(child: const OwnerLinkScreen()),
      '/customer_link_accept': (context) => const CustomerLinkAcceptScreen(),
      '/customer_portal': (context) {
        // Customer portal requires customerId - get from args or auth
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args is String) {
          return CustomerRoleGuard(child: CustomerHomeScreen(customerId: args));
        }
        // Fallback: redirect to auth
        return const CustomerAuthScreen();
      },

      // Customer-Shop Linking
      '/my-linked-shops': (context) =>
          CustomerRoleGuard(child: const MyLinkedShopsScreen()),

      // Features
      '/bill_scan': (context) => VendorRoleGuard(child: const BillScanScreen()),
      '/barcode_scanner': (context) =>
          VendorRoleGuard(child: const BarcodeScannerScreen()),
      '/insights': (context) => VendorRoleGuard(child: const InsightsScreen()),
      '/bill_template': (context) =>
          VendorRoleGuard(child: const BillTemplateDesignerScreen()),
      '/alerts': (context) => VendorRoleGuard(child: const AlertsScreen()),
      '/app_management': (context) =>
          VendorRoleGuard(child: const AppManagementScreen()),
      '/inventory': (context) =>
          VendorRoleGuard(child: const InventoryDashboardScreen()),
      '/analytics': (context) =>
          VendorRoleGuard(child: const AnalyticsDashboardScreen()),
      '/backup': (context) => VendorRoleGuard(child: const BackupScreen()),
      '/gst-reports': (context) =>
          VendorRoleGuard(child: const GstReportsScreen()),
      '/daybook': (context) => VendorRoleGuard(child: const DayBookScreen()),
      '/party_ledger': (context) =>
          VendorRoleGuard(child: const PartyLedgerListScreen()),
      '/notifications': (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args is String) {
          return VendorRoleGuard(
            child: CustomerNotificationsScreen(customerId: args),
          );
        }
        return const VendorRoleGuard(child: SizedBox.shrink());
      },
      '/payment-history': (context) =>
          VendorRoleGuard(child: const PaymentHistoryScreen()),

      // Sync Status
      '/sync-status': (context) =>
          VendorRoleGuard(child: const RealSyncScreen()),

      // Service/Repair Module (Mobile/Computer Shop)
      '/service_jobs': (context) =>
          VendorRoleGuard(child: const ServiceJobListScreen()),
      '/exchanges': (context) =>
          VendorRoleGuard(child: const ExchangeListScreen()),

      // Catalogue
      '/catalogue': (context) =>
          VendorRoleGuard(child: const CatalogueScreen()),

      // ======================================================================
      // CUSTOM BUSINESS MODULES
      // ======================================================================

      // ======================================================================
      // CUSTOM BUSINESS MODULES (Protected Routes)
      // ======================================================================

      // Clinic
      '/clinic/appointment': (context) => VendorRoleGuard(
        child: BusinessGuard(
          allowedTypes: const [BusinessType.clinic],
          denialMessage: 'Only Clinics can access Appointments',
          child: const AppointmentScreen(),
        ),
      ),
      '/clinic/prescription': (context) => VendorRoleGuard(
        child: BusinessGuard(
          allowedTypes: const [BusinessType.clinic],
          denialMessage: 'Only Clinics can access Prescriptions',
          child: const AddPrescriptionScreen(),
        ),
      ),
      '/clinic/queue': (context) => VendorRoleGuard(
        child: BusinessGuard(
          allowedTypes: const [BusinessType.clinic],
          denialMessage: 'Only Clinics can access Patient Queue',
          child: const PatientListScreen(),
        ),
      ),

      // Service / Repair (Mobile, Computer, General Service)
      '/job/create': (context) => VendorRoleGuard(
        child: BusinessGuard(
          allowedTypes: const [
            BusinessType.mobileShop,
            BusinessType.computerShop,
            BusinessType.service,
            BusinessType.electronics,
          ],
          denialMessage: 'This feature is for Service/Repair businesses only',
          child: const CreateServiceJobScreen(),
        ),
      ),
      '/job/status': (context) => VendorRoleGuard(
        child: BusinessGuard(
          allowedTypes: const [
            BusinessType.mobileShop,
            BusinessType.computerShop,
            BusinessType.service,
            BusinessType.electronics,
          ],
          child: const ServiceJobListScreen(),
        ),
      ),
      '/job/deliver': (context) => VendorRoleGuard(
        child: BusinessGuard(
          allowedTypes: const [
            BusinessType.mobileShop,
            BusinessType.computerShop,
            BusinessType.service,
            BusinessType.electronics,
          ],
          child: const ServiceJobListScreen(),
        ),
      ), // Reuse list for now
      // Petrol Pump
      '/pump/reading': (context) => VendorRoleGuard(
        child: BusinessGuard(
          allowedTypes: const [BusinessType.petrolPump],
          denialMessage: 'Only Petrol Pumps can access Meter Readings',
          child: const DispenserListScreen(),
        ),
      ),
      '/pump/density': (context) => VendorRoleGuard(
        child: BusinessGuard(
          allowedTypes: const [BusinessType.petrolPump],
          child: const FuelRatesScreen(),
        ),
      ),

      // Parameterized routes
      '/customer_app': (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args is Customer) {
          return CustomerRoleGuard(
            child: CustomerHomeScreen(customerId: args.id),
          );
        }
        return const CustomerAuthScreen();
      },
      '/customer_report': (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
        if (args != null && args.containsKey('customerId')) {
          return VendorRoleGuard(
            child: CustomerReportScreen(
              customerId: args['customerId']!,
              customerName: args['customerName'],
            ),
          );
        }
        return VendorRoleGuard(child: const SizedBox.shrink());
      },
      '/advanced_bill_creation': (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args is Bill) {
          return VendorRoleGuard(
            child: AdvancedBillCreationScreen(editingBill: args),
          );
        }
        return VendorRoleGuard(child: AdvancedBillCreationScreen());
      },
      '/cloud_sync_settings': (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args is String) {
          return VendorRoleGuard(child: CloudSyncSettingsScreen(ownerId: args));
        }
        return VendorRoleGuard(child: const SettingsScreen());
      },
      '/editable_invoice': (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
        return VendorRoleGuard(
          child: EditableInvoiceScreen(
            ownerName: args?['ownerName'] ?? '',
            shopName: args?['shopName'] ?? '',
            ownerPhone: args?['ownerPhone'] ?? '',
            ownerAddress: args?['ownerAddress'] ?? '',
          ),
        );
      },
      '/invoice_preview': (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args is EditableInvoice) {
          return VendorRoleGuard(child: InvoicePreviewScreen(invoice: args));
        }
        return VendorRoleGuard(child: const SizedBox.shrink());
      },
    };
  }
}
