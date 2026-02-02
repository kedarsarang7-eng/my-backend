import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/navigation/navigation_controller.dart';
import '../../core/navigation/app_screens.dart';
import '../feature_error_boundary.dart';

// Import Screens Logic (Barrel imports prefered if available, else direct)

import '../../features/dashboard/presentation/screens/desktop_dashboard_content.dart';
import '../../features/billing/presentation/screens/bill_creation_screen_v2.dart';
import '../../features/revenue/screens/sales_register_screen.dart';
import '../../features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import '../../features/inventory/presentation/screens/categories_screen.dart';
import '../../features/customers/presentation/screens/customers_list_screen.dart';
import '../../features/party_ledger/screens/party_ledger_list_screen.dart';
import '../../features/payment/presentation/screens/payments_history_screen.dart';
import '../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../screens/billing_reports_screen.dart';
import '../../features/gst/screens/gst_reports_screen.dart';
import '../../features/settings/presentation/screens/main_settings_screen.dart';
import '../../features/doctor/presentation/screens/patient_list_screen.dart';
import '../../features/doctor/presentation/screens/prescriptions_list_screen.dart';
import '../../features/doctor/presentation/screens/appointment_screen.dart';
import '../../features/doctor/presentation/screens/add_patient_screen.dart';

// BuyFlow Screens
import '../../features/buy_flow/screens/buy_flow_dashboard.dart';
import '../../features/buy_flow/screens/buy_orders_screen.dart';
import '../../features/buy_flow/screens/stock_entry_screen.dart';
import '../../features/buy_flow/screens/stock_reversal_screen.dart';
import '../../features/buy_flow/screens/procurement_log_screen.dart';
import '../../features/buy_flow/screens/supplier_bills_screen.dart';

// Revenue Screens
import '../../features/revenue/screens/revenue_overview_screen.dart';
import '../../features/revenue/screens/receipt_entry_screen.dart';
import '../../features/revenue/screens/proforma_screen.dart';
import '../../features/revenue/screens/booking_order_screen.dart';
import '../../features/revenue/screens/dispatch_note_screen.dart';
import '../../features/revenue/screens/return_inwards_screen.dart';

// Utility Screens
import '../../features/alerts/presentation/screens/alerts_screen.dart';
import '../../features/insights/presentation/screens/insights_screen.dart';
import '../../features/backup/screens/backup_screen.dart';
import '../../features/daybook/presentation/screens/day_book_screen.dart';
import '../../features/credit_notes/presentation/screens/credit_note_screen.dart';
import '../../features/analytics/analytics_dashboard_screen.dart';
import '../../features/catalogue/presentation/screens/catalogue_screen.dart';

/// The main content area that switches screens based on NavigationController state.
/// Uses [IndexedStack] or [FadeTransition] to switch content without rebuilding the shell.
class DesktopContentHost extends ConsumerStatefulWidget {
  const DesktopContentHost({super.key});

  @override
  ConsumerState<DesktopContentHost> createState() => _DesktopContentHostState();
}

class _DesktopContentHostState extends ConsumerState<DesktopContentHost> {
  // Map of Screen Enum -> Widget Builder
  // We use builders to lazy load if needed, or instantiate direct if const
  late final Map<AppScreen, Widget Function()> _screenBuilders;

  // Cache constructed screens to preserve state
  final Map<AppScreen, Widget> _screenCache = {};

  @override
  void initState() {
    super.initState();
    _initScreenBuilders();
  }

  void _initScreenBuilders() {
    _screenBuilders = {
      // DASHBOARD
      AppScreen.executiveDashboard: () => const DesktopDashboardContent(),

      // BILLING
      AppScreen.newSale: () => const BillCreationScreenV2(),
      AppScreen.salesRegister: () => const SalesRegisterScreen(),

      // INVENTORY
      AppScreen.stockSummary: () => const InventoryDashboardScreen(),
      AppScreen.itemStock: () => const InventoryDashboardScreen(),
      AppScreen.categories: () => const CategoriesScreen(),

      // CUSTOMERS & LEDGER
      AppScreen.customers: () => const CustomersListScreen(),
      AppScreen.partyLedger: () => const PartyLedgerListScreen(),
      AppScreen.outstanding: () => const PartyLedgerListScreen(),

      // FINANCIAL
      AppScreen.paymentHistory: () => const PaymentsHistoryScreen(),
      AppScreen.expenses: () => const ExpensesScreen(),
      AppScreen.accountingReports: () =>
          const BillingReportsScreen(), // Placeholder
      AppScreen.transactionReports: () => const BillingReportsScreen(),

      // TAX
      AppScreen.gstr1: () => const GstReportsScreen(),
      AppScreen.taxLiability: () => const GstReportsScreen(),

      // CLINIC
      AppScreen.clinicDashboard: () =>
          const DesktopDashboardContent(), // Clinic specific needed
      AppScreen.patientsList: () => const PatientListScreen(),
      AppScreen.addPatient: () => const AddPatientScreen(),
      AppScreen.prescriptions: () => const SafePrescriptionListScreen(),
      AppScreen.appointments: () => const AppointmentScreen(),

      // SETTINGS
      AppScreen.settings: () => const SettingsScreen(),
      AppScreen.deviceSettings: () => const SettingsScreen(),

      // --- NEWLY WIRED SCREENS ---

      // REVENUE DESK
      AppScreen.revenueOverview: () => const RevenueOverviewScreen(),
      AppScreen.receiptEntry: () => const ReceiptEntryScreen(),
      AppScreen.proformaBids: () => const ProformaScreen(),
      AppScreen.bookingOrders: () => const BookingOrderScreen(),
      AppScreen.dispatchNotes: () => const DispatchNoteScreen(),
      AppScreen.returnInwards: () => const ReturnInwardsScreen(),

      // BUY FLOW
      AppScreen.buyflowDashboard: () => const BuyFlowDashboard(),
      AppScreen.purchaseOrders: () => const BuyOrdersScreen(),
      AppScreen.stockEntry: () => const StockEntryScreen(),
      AppScreen.stockReversal: () => const StockReversalScreen(),
      AppScreen.procurementLog: () => const ProcurementLogScreen(),
      AppScreen.supplierBills: () => const SupplierBillsScreen(),
      AppScreen.purchaseRegister: () =>
          const BuyOrdersScreen(), // Reuse for now
      // UTILITIES & ANALYTICS
      AppScreen.alerts: () => const AlertsScreen(),
      AppScreen.insights: () => const InsightsScreen(),
      AppScreen.daybook: () => const DayBookScreen(),
      AppScreen.creditNotes: () => const CreditNotesListScreen(),
      AppScreen.backup: () => const BackupScreen(),
      AppScreen.analyticsHub: () => const AnalyticsDashboardScreen(),
      AppScreen.catalogue: () => const CatalogueScreen(),

      // FALLBACK
      AppScreen.unknown: () =>
          const Center(child: Text("Feature under development")),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Listen to navigation state
    final navigationState = ref.watch(navigationControllerProvider);
    final currentScreen = navigationState.currentScreen;

    return FocusTraversalGroup(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(currentScreen),
          child: _buildScreen(currentScreen),
        ),
      ),
    );
  }

  Widget _buildScreen(AppScreen screen) {
    // Return cached if exists
    if (_screenCache.containsKey(screen)) {
      return _screenCache[screen]!;
    }

    // Build and cache
    Widget widget;
    if (_screenBuilders.containsKey(screen)) {
      widget = _screenBuilders[screen]!();
    } else {
      // Default fallback for mapped enums that don't have a builder yet
      widget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "Screen: ${screen.name}",
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              "This screen has not been connected to the new navigation system yet.",
            ),
          ],
        ),
      );
    }

    // Wrap with error boundary for crash isolation
    final wrappedWidget = FeatureErrorBoundary(
      screen: screen,
      onRetry: () {
        // Clear cache to force rebuild on retry
        _screenCache.remove(screen);
        setState(() {});
      },
      child: widget,
    );

    _screenCache[screen] = wrappedWidget;
    return wrappedWidget;
  }
}
