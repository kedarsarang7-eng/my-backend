import 'package:flutter/material.dart';

// Dashboard & Control
import '../../features/dashboard/presentation/screens/dashboard_selection_screen.dart';
import '../../features/dashboard/presentation/screens/live_business_health_screen.dart';
import '../../features/dashboard/presentation/screens/daily_snapshot_screen.dart';
import '../../features/alerts/presentation/screens/alerts_notifications_screen.dart';

// Doctor/Clinic
import '../../features/doctor/presentation/screens/doctor_dashboard_screen.dart';
import '../../features/doctor/presentation/screens/appointment_screen.dart';
import '../../features/doctor/presentation/screens/patient_list_screen.dart';
import '../../features/doctor/presentation/screens/add_patient_screen.dart';
import '../../features/doctor/presentation/screens/prescriptions_list_screen.dart';
import '../../features/doctor/presentation/screens/medicine_master_screen.dart';
import '../../features/doctor/presentation/screens/lab_reports_screen.dart';

// Billing
import '../../features/billing/presentation/screens/bill_creation_screen_v2.dart';

// Revenue
import '../../features/revenue/screens/revenue_overview_screen.dart';
import '../../features/revenue/screens/receipt_entry_screen.dart';
import '../../features/revenue/screens/return_inwards_screen.dart';
import '../../features/revenue/screens/proforma_screen.dart';
import '../../features/revenue/screens/booking_order_screen.dart';
import '../../features/revenue/screens/dispatch_note_screen.dart';
import '../../features/revenue/screens/sales_register_screen.dart';

// BuyFlow
import '../../features/buy_flow/screens/buy_flow_dashboard.dart';
import '../../features/buy_flow/screens/buy_orders_screen.dart';
import '../../features/buy_flow/screens/stock_entry_screen.dart';
import '../../features/buy_flow/screens/stock_reversal_screen.dart';
import '../../features/buy_flow/screens/vendor_payouts_screen.dart';
import '../../features/buy_flow/screens/procurement_log_screen.dart';
import '../../features/buy_flow/screens/supplier_bills_screen.dart';

// Inventory
import '../../features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import '../../features/inventory/presentation/screens/stock_summary_screen.dart';
import '../../features/inventory/presentation/screens/low_stock_alerts_screen.dart';
import '../../features/inventory/presentation/screens/stock_valuation_screen.dart';
import '../../features/inventory/presentation/screens/batch_tracking_screen.dart';
import '../../features/inventory/presentation/screens/damage_logs_screen.dart';

// Petrol Pump
import '../../features/petrol_pump/presentation/screens/petrol_pump_management_screen.dart';
import '../../features/petrol_pump/presentation/screens/shift_history_screen.dart';
import '../../features/petrol_pump/presentation/screens/tank_list_screen.dart';
import '../../features/petrol_pump/presentation/screens/dispenser_list_screen.dart';

// Restaurant
import '../../features/restaurant/presentation/screens/table_management_screen.dart';
import '../../features/restaurant/presentation/screens/kitchen_display_screen.dart';
import '../../features/restaurant/presentation/screens/food_menu_management_screen.dart';

// Customers & Ledger
import '../../features/customers/presentation/screens/customers_list_screen.dart';
import '../../features/party_ledger/screens/party_ledger_list_screen.dart';

// Reports & GST
import '../../features/reports/presentation/screens/reports_hub_screen.dart';
import '../../features/reports/presentation/screens/all_transactions_screen.dart';
import '../../features/reports/presentation/screens/pnl_screen.dart';
import '../../features/reports/presentation/screens/cashflow_screen.dart';
import '../../features/reports/presentation/screens/balance_screen.dart';
import '../../features/gst/screens/gst_reports_screen.dart';
import '../../features/reports/presentation/screens/trial_balance_screen.dart';
import '../../features/reports/presentation/screens/purchase_report_screen.dart';
import '../../features/reports/presentation/screens/bill_wise_profit_screen.dart';
import '../../features/reports/presentation/screens/print_menu_screen.dart';
import '../../features/reports/presentation/screens/product_performance_screen.dart'; // Added
import '../../features/backup/screens/backup_screen.dart';
import '../../features/settings/presentation/screens/error_logs_screen.dart'; // Added
import '../../features/settings/presentation/screens/device_settings_screen.dart'; // Added

// ============================================================
// HIDDEN FEATURE SCREENS (Made visible per audit)
// ============================================================

// Doctor/Clinic - Hidden screens
import '../../features/doctor/presentation/screens/doctor_revenue_screen.dart';

// Petrol Pump - Hidden report screens
import '../../features/petrol_pump/presentation/screens/fuel_rates_screen.dart';
import '../../features/petrol_pump/presentation/screens/reports/fuel_profit_report_screen.dart';
import '../../features/petrol_pump/presentation/screens/reports/nozzle_sales_report_screen.dart';
import '../../features/petrol_pump/presentation/screens/reports/shift_report_screen.dart';
import '../../features/petrol_pump/presentation/screens/reports/tank_stock_report_screen.dart';

// Restaurant - Hidden screens
import '../../features/restaurant/presentation/screens/restaurant_daily_summary_screen.dart';

// Service Business - Hidden screens
import '../../features/service/presentation/screens/service_job_list_screen.dart';
import '../../features/service/presentation/screens/exchange_list_screen.dart';

// QR Scanner (for scan_qr sidebar item)
import '../../features/shop_linking/presentation/screens/qr_scanner_screen.dart';

// ============================================================
// PHASE 2 - ADDITIONAL HIDDEN SCREENS DISCOVERED
// ============================================================

// Accounting Module - Hidden from sidebar
import '../../features/accounting/screens/accounting_reports_screen.dart';

// Bank Module - Hidden from sidebar
import '../../features/bank/presentation/screens/bank_screen.dart';

// Credit Notes - Hidden from sidebar
import '../../features/credit_notes/presentation/screens/credit_note_screen.dart';

// DayBook - Hidden from sidebar (exists in main.dart routes but not sidebar)
import '../../features/daybook/presentation/screens/day_book_screen.dart';

// Catalogue - Hidden from sidebar
import '../../features/catalogue/presentation/screens/catalogue_screen.dart';

// Insights - Hidden from sidebar
import '../../features/insights/presentation/screens/insights_screen.dart';

// Expenses - Hidden from sidebar
import '../../features/expenses/presentation/screens/expenses_screen.dart';

/// Navigation route handler for enterprise sidebar
/// Maps item IDs to actual screen widgets/routes
class SidebarNavigationHandler {
  /// Get the screen widget for a given sidebar item ID
  static Widget getScreenForItem(String itemId, BuildContext context) {
    switch (itemId) {
      // ========== Dashboard & Control ==========
      case 'executive_dashboard':
        return const DashboardSelectionScreen();
      case 'clinic_dashboard':
        return const DoctorDashboardScreen();
      case 'live_health':
        return const LiveBusinessHealthScreen();
      case 'alerts':
        return const AlertsNotificationsScreen();
      case 'daily_snapshot':
        return const DailySnapshotScreen();

      // ========== Clinic Specific ==========
      case 'daily_appointments':
      case 'appointments':
        return const AppointmentScreen();
      case 'patients_list':
        return const PatientListScreen();
      case 'add_patient':
        return const AddPatientScreen();
      case 'prescriptions':
        return const SafePrescriptionListScreen();
      case 'medicine_master':
        return const MedicineMasterScreen();
      case 'lab_reports':
        return const LabReportsScreen();
      case 'patient_history':
        // Show picker dialog or navigate to first patient
        return const PatientListScreen(); // Default to patient list for selection

      // ========== Revenue Desk ==========
      case 'revenue_overview':
        return const RevenueOverviewScreen();
      case 'new_sale':
        return const BillCreationScreenV2();
      case 'receipt_entry':
        return const ReceiptEntryScreen();
      case 'return_inwards':
        return const ReturnInwardsScreen();
      case 'proforma_bids':
        return const ProformaScreen();
      case 'booking_orders':
        return const BookingOrderScreen();
      case 'dispatch_notes':
        return const DispatchNoteScreen();
      case 'sales_register':
        return const SalesRegisterScreen();

      // ========== BuyFlow ==========
      case 'buyflow_dashboard':
        return const BuyFlowDashboard();
      case 'purchase_orders':
        return const BuyOrdersScreen();
      case 'stock_entry':
        return const StockEntryScreen();
      case 'stock_reversal':
        return const StockReversalScreen();
      case 'vendor_payouts':
        return const VendorPayoutsScreen();
      case 'procurement_log':
        return const ProcurementLogScreen();
      case 'supplier_bills':
        return const SupplierBillsScreen();
      case 'purchase_register':
        return const ProcurementLogScreen(); // Reuse procurement log

      // ========== Inventory & Stock ==========
      case 'stock_summary':
        return const StockSummaryScreen();
      case 'item_stock':
        return const InventoryDashboardScreen();
      case 'batch_tracking':
        return const BatchTrackingScreen();
      case 'low_stock':
        return const LowStockAlertsScreen();
      case 'stock_valuation':
        return const StockValuationScreen();
      case 'damage_logs':
        return const DamageLogsScreen();

      // ========== Parties & Ledger ==========
      case 'customers':
        return const CustomersListScreen();
      case 'suppliers':
        // Reuse Party Ledger strictly for suppliers
        return const PartyLedgerListScreen(initialFilter: 'supplier');
      case 'party_ledger':
        return const PartyLedgerListScreen();
      case 'ledger_history':
        return const AllTransactionsScreen();
      case 'ledger_abstract':
        return const TrialBalanceScreen();
      case 'outstanding':
        return const PartyLedgerListScreen(initialFilter: 'receivable');

      // ========== Business Intelligence ==========
      case 'analytics_hub':
        return const ReportsHubScreen();
      case 'turnover_analysis':
        return const AllTransactionsScreen(); // Placeholder mapping
      case 'product_performance':
        return const ProductPerformanceScreen();
      case 'daily_activity':
        return const AllTransactionsScreen();
      case 'procurement_insights':
        return const PurchaseReportScreen();
      case 'margin_analysis':
        return const BillWiseProfitScreen();

      // ========== Financial Reports ==========
      case 'invoice_margin':
        return const PnlScreen();
      case 'income_statement':
        return const PnlScreen();
      case 'funds_flow':
        return const CashflowScreen();
      case 'financial_position':
        return const BalanceScreen();
      case 'cash_bank':
        return const CashflowScreen();

      // ========== Tax & Compliance ==========
      case 'gstr1':
        return const GstReportsScreen(initialIndex: 0); // GSTR-1
      case 'b2b_b2c':
        return const GstReportsScreen(initialIndex: 0); // B2B/B2C
      case 'hsn_reports':
        return const GstReportsScreen(initialIndex: 1); // HSN
      case 'tax_liability':
        return const GstReportsScreen(initialIndex: 2); // Liability
      case 'filing_status':
        return const GstReportsScreen(initialIndex: 3); // Status

      // ========== Operations & Logs ==========
      case 'transaction_reports':
        return const AllTransactionsScreen();
      case 'activity_logs':
        return const AllTransactionsScreen();
      case 'audit_trail':
        return const AllTransactionsScreen();
      case 'error_logs':
        return const ErrorLogsScreen();

      // ========== Utilities & System ==========
      case 'print_settings':
        return const PrintMenuScreen();
      case 'doc_templates':
        return const PrintMenuScreen();
      case 'backup':
        return const BackupScreen();
      case 'sync_status':
        return const BackupScreen(); // Reuse Backup for sync status
      case 'device_settings':
        return const DeviceSettingsScreen();

      // ========== Petrol Pump ==========
      case 'petrol_dashboard':
        return const PetrolPumpManagementScreen();
      case 'shift_management':
        return const ShiftHistoryScreen();
      case 'tank_management':
        return const TankListScreen();
      case 'dispenser_management':
        return const DispenserListScreen();

      // ========== Restaurant ==========
      case 'restaurant_tables':
        return const TableManagementScreen(vendorId: 'SYSTEM');
      case 'kitchen_display':
        return const KitchenDisplayScreen(vendorId: 'SYSTEM');
      case 'menu_management':
        return const FoodMenuManagementScreen(vendorId: 'SYSTEM');
      case 'daily_summary':
        return const RestaurantDailySummaryScreen(vendorId: 'SYSTEM');

      // ============================================================
      // HIDDEN FEATURES MADE VISIBLE (per audit)
      // ============================================================

      // ========== Doctor/Clinic Hidden ==========
      case 'doctor_revenue':
        return const DoctorRevenueScreen();
      case 'scan_qr':
        return const QrScannerScreen();

      // ========== Petrol Pump Reports (Hidden) ==========
      case 'fuel_rates':
        return const FuelRatesScreen();
      case 'fuel_profit_report':
        return const FuelProfitReportScreen();
      case 'nozzle_sales_report':
        return const NozzleSalesReportScreen();
      case 'shift_report':
        return const ShiftReportScreen();
      case 'tank_stock_report':
        return const TankStockReportScreen();

      // ========== Service Business (Hidden) ==========
      case 'service_jobs':
        return const ServiceJobListScreen();
      case 'exchanges':
        return const ExchangeListScreen();

      // ============================================================
      // PHASE 2 - ADDITIONAL HIDDEN SCREENS
      // ============================================================

      // Accounting & Financial
      case 'accounting_reports':
        return const AccountingReportsScreen();
      case 'bank_accounts':
        return const BankScreen();
      case 'credit_notes':
        return const CreditNotesListScreen();

      // Daily Operations
      case 'daybook':
        return const DayBookScreen();
      case 'catalogue':
        return const CatalogueScreen();
      case 'insights':
        return const InsightsScreen();
      case 'expenses':
        return const ExpensesScreen();

      default:
        return _buildPlaceholderScreen('Unknown Screen', Icons.help_outline);
    }
  }

  /// Get the route name for a given sidebar item ID
  static String getRouteForItem(String itemId) {
    return '/app/$itemId';
  }

  /// Build a placeholder screen for features not yet implemented
  static Widget _buildPlaceholderScreen(String title, IconData icon) {
    return _PlaceholderScreen(title: title, icon: icon);
  }
}

/// Placeholder screen widget - shown only for unknown routes
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 36,
                color: const Color(0xFF06B6D4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Feature Not Found',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'This screen could not be located. Please select from the sidebar.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
