import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/futuristic_colors.dart';
import '../../providers/app_state_providers.dart';
import '../../core/isolation/business_capability.dart';
import '../../core/isolation/feature_resolver.dart';
import '../../core/session/session_manager.dart';

/// Sidebar mode enum for expand/collapse/mini states
enum SidebarMode { expanded, collapsed, mini }

/// Sidebar menu item model
class SidebarMenuItem {
  final String id;
  final IconData icon;
  final String label;
  final String? route;
  final VoidCallback? onTap;
  final bool badge;
  final int? badgeCount;
  final BusinessCapability? capability; // Capability required for this item
  final String? permission; // Permission string (future RBAC)

  const SidebarMenuItem({
    required this.id,
    required this.icon,
    required this.label,
    this.route,
    this.onTap,
    this.badge = false,
    this.badgeCount,
    this.capability,
    this.permission,
  });
}

/// Sidebar section model
class SidebarSection {
  final int index;
  final IconData icon;
  final String title;
  final Color? accentColor;
  final List<SidebarMenuItem> items;
  final String? shortcutHint;

  const SidebarSection({
    required this.index,
    required this.icon,
    required this.title,
    this.accentColor,
    required this.items,
    this.shortcutHint,
  });
}

/// Provider that returns the list of sidebar sections filtered by:
/// 1. Business Type (Clinic, Retail, etc.)
/// 2. User Permissions (via Session)
/// 3. Feature Flags (Capabilities)
///
/// This is memoized by Riverpod, so it ONLY re-runs if [businessTypeProvider]
/// or [authStateProvider] changes, NOT on every hover/frame.
final sidebarSectionsProvider = Provider<List<SidebarSection>>((ref) {
  final businessTypeState = ref.watch(businessTypeProvider);
  final authState = ref.watch(authStateProvider);
  final session = authState.session;

  // 1. Get Base Sections
  final allSections = _getSectionsForBusiness(businessTypeState.type);

  // 2. Filter by Capabilities & Permissions
  final typeStr = businessTypeState.type.name;

  return allSections
      .map((section) {
        final filteredItems = section.items.where((item) {
          // Check Capability
          if (item.capability != null) {
            if (!FeatureResolver.canAccess(typeStr, item.capability!)) {
              return false;
            }
          }
          // Check Permission (RBAC)
          if (item.permission != null) {
            if (session == null) return false;
            if (item.permission == 'owner' && !session.isOwner) return false;
          }
          return true;
        }).toList();

        return SidebarSection(
          index: section.index,
          icon: section.icon,
          title: section.title,
          accentColor: section.accentColor,
          shortcutHint: section.shortcutHint,
          items: filteredItems,
        );
      })
      .where((section) => section.items.isNotEmpty)
      .toList();
});

// --- INTERNAL HELPER FUNCTIONS (Extracted from UI) ---

List<SidebarSection> _getSectionsForBusiness(BusinessType type) {
  switch (type) {
    case BusinessType.clinic:
      return _getClinicSections();
    case BusinessType.pharmacy:
      return _getPharmacySections();
    case BusinessType.restaurant:
      return _getRestaurantSections();
    case BusinessType.petrolPump:
      return _getPetrolPumpSections();
    case BusinessType.electronics:
    case BusinessType.mobileShop:
    case BusinessType.computerShop:
      return _getRetailSections();
    case BusinessType.service:
      return _getServiceSections();
    default:
      return _getRetailSections();
  }
}

List<SidebarSection> _getClinicSections() {
  return [
    SidebarSection(
      index: 0,
      icon: Icons.space_dashboard_rounded,
      title: 'Clinic Dashboard',
      accentColor: FuturisticColors.accent1,
      shortcutHint: 'Ctrl+1',
      items: [
        SidebarMenuItem(
            id: 'clinic_dashboard',
            icon: Icons.dashboard_customize_outlined,
            label: 'Overview'),
        SidebarMenuItem(
            id: 'daily_appointments',
            icon: Icons.calendar_today_outlined,
            label: 'Today\'s Schedule',
            badge: true),
      ],
    ),
    SidebarSection(
      index: 1,
      icon: Icons.personal_injury_outlined,
      title: 'Patient Management',
      accentColor: FuturisticColors.primary,
      shortcutHint: 'Ctrl+2',
      items: [
        SidebarMenuItem(
            id: 'patients_list',
            icon: Icons.people_outline,
            label: 'All Patients'),
        SidebarMenuItem(
            id: 'add_patient',
            icon: Icons.person_add_outlined,
            label: 'Register Patient'),
        SidebarMenuItem(
            id: 'patient_history',
            icon: Icons.history_edu_outlined,
            label: 'Patient History'),
        SidebarMenuItem(
            id: 'scan_qr',
            icon: Icons.qr_code_scanner_outlined,
            label: 'Scan Patient QR',
            capability: BusinessCapability.usePatientRegistry),
      ],
    ),
    SidebarSection(
      index: 2,
      icon: Icons.medical_services_outlined,
      title: 'Clinical Desk',
      accentColor: FuturisticColors.error,
      shortcutHint: 'Ctrl+3',
      items: [
        SidebarMenuItem(
            id: 'appointments',
            icon: Icons.event_note_outlined,
            label: 'Appointments'),
        SidebarMenuItem(
            id: 'prescriptions',
            icon: Icons.description_outlined,
            label: 'Prescriptions',
            capability: BusinessCapability.usePrescription),
        SidebarMenuItem(
            id: 'medicine_master',
            icon: Icons.medication_outlined,
            label: 'Medicine Master',
            capability: BusinessCapability.usePrescription),
        SidebarMenuItem(
            id: 'lab_reports',
            icon: Icons.science_outlined,
            label: 'Lab Reports'),
        SidebarMenuItem(
            id: 'doctor_revenue',
            icon: Icons.monetization_on_outlined,
            label: 'Revenue Analytics'),
      ],
    ),
    SidebarSection(
      index: 3,
      icon: Icons.point_of_sale_rounded,
      title: 'Billing & Revenue',
      accentColor: FuturisticColors.success,
      shortcutHint: 'Ctrl+4',
      items: [
        SidebarMenuItem(
            id: 'new_sale',
            icon: Icons.receipt_long_outlined,
            label: 'Create Bill'),
        SidebarMenuItem(
            id: 'revenue_overview',
            icon: Icons.analytics_outlined,
            label: 'Revenue Overview'),
      ],
    ),
    // Utilities
    SidebarSection(
      index: 4,
      icon: Icons.settings_applications_rounded,
      title: 'System',
      accentColor: FuturisticColors.textSecondary,
      items: [
        SidebarMenuItem(
            id: 'sync_status',
            icon: Icons.cloud_sync_outlined,
            label: 'Sync Status'),
        SidebarMenuItem(
            id: 'device_settings',
            icon: Icons.devices_outlined,
            label: 'Settings'),
      ],
    ),
  ];
}

List<SidebarSection> _getServiceSections() {
  return [
    SidebarSection(
      index: 0,
      icon: Icons.space_dashboard_rounded,
      title: 'Service Dashboard',
      accentColor: FuturisticColors.accent1,
      shortcutHint: 'Ctrl+1',
      items: [
        SidebarMenuItem(
            id: 'executive_dashboard',
            icon: Icons.dashboard_customize_outlined,
            label: 'Overview'),
        SidebarMenuItem(
            id: 'daily_activity',
            icon: Icons.calendar_today_outlined,
            label: 'Daily Activity',
            badge: true),
        SidebarMenuItem(
            id: 'daily_snapshot',
            icon: Icons.today_outlined,
            label: 'Daily Snapshot'),
      ],
    ),
    SidebarSection(
      index: 1,
      icon: Icons.point_of_sale_rounded,
      title: 'Billing Desk',
      accentColor: FuturisticColors.success,
      shortcutHint: 'Ctrl+2',
      items: [
        SidebarMenuItem(
            id: 'new_sale',
            icon: Icons.receipt_long_outlined,
            label: 'Create Invoice'),
        SidebarMenuItem(
            id: 'revenue_overview',
            icon: Icons.analytics_outlined,
            label: 'Revenue Overview'),
        SidebarMenuItem(
            id: 'receipt_entry',
            icon: Icons.payment_outlined,
            label: 'Receipt Entry'),
        SidebarMenuItem(
            id: 'sales_register',
            icon: Icons.menu_book_outlined,
            label: 'Invoice History'),
        SidebarMenuItem(
            id: 'proforma_bids',
            icon: Icons.description_outlined,
            label: 'Quotes / Estimates'),
      ],
    ),
    SidebarSection(
      index: 2,
      icon: Icons.build_rounded,
      title: 'Service & Repairs',
      accentColor: FuturisticColors.warning,
      shortcutHint: 'Ctrl+3',
      items: [
        SidebarMenuItem(
            id: 'service_jobs',
            icon: Icons.build_circle_outlined,
            label: 'Service Jobs'),
        SidebarMenuItem(
            id: 'exchanges',
            icon: Icons.swap_horiz_outlined,
            label: 'Device Exchanges'),
      ],
    ),
    ..._getCommonSections(startingIndex: 3),
  ];
}

List<SidebarSection> _getRetailSections() {
  return [
    SidebarSection(
      index: 0,
      icon: Icons.space_dashboard_rounded,
      title: 'Dashboard & Control',
      accentColor: FuturisticColors.accent1,
      shortcutHint: 'Ctrl+1',
      items: [
        SidebarMenuItem(
            id: 'executive_dashboard',
            icon: Icons.dashboard_customize_outlined,
            label: 'Executive Dashboard'),
        SidebarMenuItem(
            id: 'live_health',
            icon: Icons.monitor_heart_outlined,
            label: 'Live Business Health'),
        SidebarMenuItem(
            id: 'alerts',
            icon: Icons.notifications_active_outlined,
            label: 'Alerts & Notifications',
            badge: true),
        SidebarMenuItem(
            id: 'daily_snapshot',
            icon: Icons.today_outlined,
            label: 'Daily Snapshot'),
      ],
    ),
    SidebarSection(
      index: 1,
      icon: Icons.point_of_sale_rounded,
      title: 'Revenue Desk',
      accentColor: FuturisticColors.success,
      shortcutHint: 'Ctrl+2',
      items: [
        SidebarMenuItem(
            id: 'revenue_overview',
            icon: Icons.analytics_outlined,
            label: 'Revenue Overview'),
        SidebarMenuItem(
            id: 'new_sale',
            icon: Icons.add_shopping_cart_outlined,
            label: 'Invoice / Bill Creation'),
        SidebarMenuItem(
            id: 'receipt_entry',
            icon: Icons.receipt_long_outlined,
            label: 'Receipt Entry'),
        SidebarMenuItem(
            id: 'return_inwards',
            icon: Icons.assignment_return_outlined,
            label: 'Return Inwards'),
        SidebarMenuItem(
            id: 'proforma_bids',
            icon: Icons.description_outlined,
            label: 'Proforma & Bids'),
        SidebarMenuItem(
            id: 'booking_orders',
            icon: Icons.bookmark_add_outlined,
            label: 'Booking Orders'),
        SidebarMenuItem(
            id: 'dispatch_notes',
            icon: Icons.local_shipping_outlined,
            label: 'Dispatch Notes'),
        SidebarMenuItem(
            id: 'sales_register',
            icon: Icons.menu_book_outlined,
            label: 'Sales Register'),
      ],
    ),
    SidebarSection(
      index: 2,
      icon: Icons.shopping_bag_rounded,
      title: 'BuyFlow',
      accentColor: FuturisticColors.warning,
      shortcutHint: 'Ctrl+3',
      items: [
        SidebarMenuItem(
            id: 'buyflow_dashboard',
            icon: Icons.dashboard_outlined,
            label: 'BuyFlow Dashboard'),
        SidebarMenuItem(
            id: 'purchase_orders',
            icon: Icons.shopping_cart_checkout_outlined,
            label: 'Purchase Orders'),
        SidebarMenuItem(
            id: 'stock_entry',
            icon: Icons.add_box_outlined,
            label: 'Stock Entry'),
        SidebarMenuItem(
            id: 'stock_reversal',
            icon: Icons.replay_outlined,
            label: 'Stock Reversal'),
        SidebarMenuItem(
            id: 'procurement_log',
            icon: Icons.history_outlined,
            label: 'Procurement Log'),
        SidebarMenuItem(
            id: 'supplier_bills',
            icon: Icons.request_quote_outlined,
            label: 'Supplier Bills'),
        SidebarMenuItem(
            id: 'purchase_register',
            icon: Icons.menu_book_outlined,
            label: 'Purchase Register'),
      ],
    ),
    SidebarSection(
      index: 3,
      icon: Icons.inventory_2_rounded,
      title: 'Inventory & Stock',
      accentColor: FuturisticColors.primary,
      shortcutHint: 'Ctrl+4',
      items: [
        SidebarMenuItem(
            id: 'stock_summary',
            icon: Icons.summarize_outlined,
            label: 'Stock Summary'),
        SidebarMenuItem(
            id: 'item_stock',
            icon: Icons.category_outlined,
            label: 'Item-wise Stock'),
        SidebarMenuItem(
            id: 'batch_tracking',
            icon: Icons.layers_outlined,
            label: 'Batch / Variant Tracking',
            capability: BusinessCapability.useBatchExpiry),
        SidebarMenuItem(
            id: 'low_stock',
            icon: Icons.warning_amber_outlined,
            label: 'Low Stock Alerts',
            badge: true),
        SidebarMenuItem(
            id: 'stock_valuation',
            icon: Icons.price_check_outlined,
            label: 'Stock Valuation'),
        SidebarMenuItem(
            id: 'damage_logs',
            icon: Icons.delete_sweep_outlined,
            label: 'Damage / Adjustment'),
      ],
    ),
    SidebarSection(
      index: 4,
      icon: Icons.people_alt_rounded,
      title: 'Parties & Ledger',
      accentColor: FuturisticColors.accent2,
      shortcutHint: 'Ctrl+5',
      items: [
        SidebarMenuItem(
            id: 'customers', icon: Icons.person_outline, label: 'Customers'),
        SidebarMenuItem(
            id: 'suppliers',
            icon: Icons.storefront_outlined,
            label: 'Suppliers'),
        SidebarMenuItem(
            id: 'party_ledger',
            icon: Icons.account_balance_wallet_outlined,
            label: 'Party Ledger'),
        SidebarMenuItem(
            id: 'ledger_history',
            icon: Icons.history_edu_outlined,
            label: 'Master Ledger History'),
        SidebarMenuItem(
            id: 'ledger_abstract',
            icon: Icons.list_alt_outlined,
            label: 'Ledger Abstract'),
        SidebarMenuItem(
            id: 'outstanding',
            icon: Icons.pending_actions_outlined,
            label: 'Outstanding Reports'),
      ],
    ),
    SidebarSection(
      index: 5,
      icon: Icons.insights_rounded,
      title: 'Business Intelligence',
      accentColor: const Color(0xFF00D4FF),
      shortcutHint: 'Ctrl+6',
      items: [
        SidebarMenuItem(
            id: 'analytics_hub',
            icon: Icons.hub_outlined,
            label: 'Analytics Hub'),
        SidebarMenuItem(
            id: 'turnover_analysis',
            icon: Icons.trending_up_outlined,
            label: 'Turnover Analysis'),
        SidebarMenuItem(
            id: 'product_performance',
            icon: Icons.auto_graph_outlined,
            label: 'Product Performance'),
        SidebarMenuItem(
            id: 'daily_activity',
            icon: Icons.calendar_today_outlined,
            label: 'Daily Activity Register'),
        SidebarMenuItem(
            id: 'procurement_insights',
            icon: Icons.insights_outlined,
            label: 'Procurement Insights'),
        SidebarMenuItem(
            id: 'margin_analysis',
            icon: Icons.pie_chart_outline,
            label: 'Margin Analysis'),
        SidebarMenuItem(
            id: 'insights',
            icon: Icons.auto_awesome_outlined,
            label: 'AI Insights'),
        SidebarMenuItem(
            id: 'catalogue',
            icon: Icons.collections_bookmark_outlined,
            label: 'Share Catalogue'),
      ],
    ),
    SidebarSection(
      index: 6,
      icon: Icons.account_balance_rounded,
      title: 'Financial Reports',
      accentColor: FuturisticColors.success,
      shortcutHint: 'Ctrl+7',
      items: [
        SidebarMenuItem(
            id: 'invoice_margin',
            icon: Icons.money_outlined,
            label: 'Invoice Margin View'),
        SidebarMenuItem(
            id: 'income_statement',
            icon: Icons.assessment_outlined,
            label: 'Income Statement (P&L)'),
        SidebarMenuItem(
            id: 'funds_flow',
            icon: Icons.swap_horiz_outlined,
            label: 'Funds Flow Analysis'),
        SidebarMenuItem(
            id: 'financial_position',
            icon: Icons.account_balance_outlined,
            label: 'Financial Position'),
        SidebarMenuItem(
            id: 'cash_bank',
            icon: Icons.savings_outlined,
            label: 'Cash / Bank Summary'),
        SidebarMenuItem(
            id: 'accounting_reports',
            icon: Icons.calculate_outlined,
            label: 'Trial Balance / P&L'),
        SidebarMenuItem(
            id: 'bank_accounts',
            icon: Icons.account_balance_outlined,
            label: 'Bank Accounts'),
        SidebarMenuItem(
            id: 'daybook', icon: Icons.book_outlined, label: 'Day Book'),
        SidebarMenuItem(
            id: 'credit_notes',
            icon: Icons.note_outlined,
            label: 'Credit Notes'),
        SidebarMenuItem(
            id: 'expenses', icon: Icons.money_off_outlined, label: 'Expenses'),
      ],
    ),
    SidebarSection(
      index: 7,
      icon: Icons.policy_rounded,
      title: 'Tax & Compliance',
      accentColor: FuturisticColors.error,
      shortcutHint: 'Ctrl+8',
      items: [
        SidebarMenuItem(
            id: 'gstr1', icon: Icons.receipt_outlined, label: 'GSTR-1 Reports'),
        SidebarMenuItem(
            id: 'b2b_b2c',
            icon: Icons.compare_arrows_outlined,
            label: 'B2B / B2C Summary'),
        SidebarMenuItem(
            id: 'hsn_reports',
            icon: Icons.qr_code_outlined,
            label: 'HSN Reports'),
        SidebarMenuItem(
            id: 'tax_liability',
            icon: Icons.percent_outlined,
            label: 'Tax Liability'),
        SidebarMenuItem(
            id: 'filing_status',
            icon: Icons.fact_check_outlined,
            label: 'Filing Readiness'),
      ],
    ),
    SidebarSection(
      index: 8,
      icon: Icons.engineering_rounded,
      title: 'Operations & Logs',
      accentColor: FuturisticColors.textSecondary,
      shortcutHint: 'Ctrl+9',
      items: [
        SidebarMenuItem(
            id: 'transaction_reports',
            icon: Icons.receipt_long_outlined,
            label: 'Transaction Reports'),
        SidebarMenuItem(
            id: 'activity_logs',
            icon: Icons.history_outlined,
            label: 'Master Activity Logs'),
        SidebarMenuItem(
            id: 'audit_trail',
            icon: Icons.verified_user_outlined,
            label: 'Audit Trail'),
        SidebarMenuItem(
            id: 'error_logs',
            icon: Icons.error_outline,
            label: 'Error & Sync Logs'),
      ],
    ),
    SidebarSection(
      index: 9,
      icon: Icons.settings_applications_rounded,
      title: 'Utilities & System',
      accentColor: FuturisticColors.textSecondary,
      shortcutHint: 'Ctrl+0',
      items: [
        SidebarMenuItem(
            id: 'print_settings',
            icon: Icons.print_outlined,
            label: 'Print Settings'),
        SidebarMenuItem(
            id: 'doc_templates',
            icon: Icons.article_outlined,
            label: 'Document Templates'),
        SidebarMenuItem(
            id: 'backup',
            icon: Icons.backup_outlined,
            label: 'Backup & Restore'),
        SidebarMenuItem(
            id: 'sync_status',
            icon: Icons.cloud_sync_outlined,
            label: 'Sync Status'),
        SidebarMenuItem(
            id: 'device_settings',
            icon: Icons.devices_outlined,
            label: 'Device Settings'),
      ],
    ),
  ];
}

List<SidebarSection> _getRestaurantSections() {
  return [
    SidebarSection(
      index: 0,
      icon: Icons.restaurant_menu_rounded,
      title: 'Restaurant Operations',
      accentColor: FuturisticColors.accent1,
      shortcutHint: 'Ctrl+1',
      items: [
        SidebarMenuItem(
            id: 'executive_dashboard',
            icon: Icons.dashboard_outlined,
            label: 'Dashboard'),
        SidebarMenuItem(
            id: 'restaurant_tables',
            icon: Icons.table_restaurant_outlined,
            label: 'Table Management',
            capability: BusinessCapability.useTableManagement),
        SidebarMenuItem(
            id: 'kitchen_display',
            icon: Icons.soup_kitchen_outlined,
            label: 'Kitchen / KOT View'),
        SidebarMenuItem(
            id: 'menu_management',
            icon: Icons.restaurant_menu_outlined,
            label: 'Menu Management'),
        SidebarMenuItem(
            id: 'daily_summary',
            icon: Icons.summarize_outlined,
            label: 'Daily Summary'),
      ],
    ),
    SidebarSection(
      index: 1,
      icon: Icons.point_of_sale_rounded,
      title: 'Billing & Cashier',
      accentColor: FuturisticColors.success,
      shortcutHint: 'Ctrl+2',
      items: [
        SidebarMenuItem(
            id: 'new_sale',
            icon: Icons.receipt_long_outlined,
            label: 'Quick Bill / Invoice'),
        SidebarMenuItem(
            id: 'revenue_overview',
            icon: Icons.analytics_outlined,
            label: 'Live Sales'),
        SidebarMenuItem(
            id: 'sales_register',
            icon: Icons.menu_book_outlined,
            label: 'Sales History'),
      ],
    ),
    SidebarSection(
      index: 2,
      icon: Icons.inventory_2_rounded,
      title: 'Inventory & Stock',
      accentColor: FuturisticColors.primary,
      shortcutHint: 'Ctrl+3',
      items: [
        SidebarMenuItem(
            id: 'stock_summary',
            icon: Icons.summarize_outlined,
            label: 'Stock Summary'),
        SidebarMenuItem(
            id: 'item_stock',
            icon: Icons.category_outlined,
            label: 'Ingredients Stock'),
        SidebarMenuItem(
            id: 'low_stock',
            icon: Icons.warning_amber_outlined,
            label: 'Low Stock Alerts',
            badge: true),
      ],
    ),
    ..._getCommonSections(startingIndex: 3),
  ];
}

List<SidebarSection> _getPetrolPumpSections() {
  return [
    SidebarSection(
      index: 0,
      icon: Icons.local_gas_station_rounded,
      title: 'Fuel Station Ops',
      accentColor: FuturisticColors.accent1,
      shortcutHint: 'Ctrl+1',
      items: [
        SidebarMenuItem(
            id: 'petrol_dashboard',
            icon: Icons.dashboard_outlined,
            label: 'Station Dashboard'),
        SidebarMenuItem(
            id: 'shift_management',
            icon: Icons.schedule_outlined,
            label: 'Shift Management'),
        SidebarMenuItem(
            id: 'dispenser_management',
            icon: Icons.ev_station_outlined,
            label: 'Dispensers / Nozzles'),
        SidebarMenuItem(
            id: 'tank_management',
            icon: Icons.water_drop_outlined,
            label: 'Tank Levels'),
      ],
    ),
    SidebarSection(
      index: 1,
      icon: Icons.point_of_sale_rounded,
      title: 'Billing & Sales',
      accentColor: FuturisticColors.success,
      shortcutHint: 'Ctrl+2',
      items: [
        SidebarMenuItem(
            id: 'new_sale',
            icon: Icons.receipt_long_outlined,
            label: 'Create Invoice'),
        SidebarMenuItem(
            id: 'revenue_overview',
            icon: Icons.analytics_outlined,
            label: 'Revenue Overview'),
        SidebarMenuItem(
            id: 'sales_register',
            icon: Icons.menu_book_outlined,
            label: 'Sales Register'),
      ],
    ),
    SidebarSection(
      index: 2,
      icon: Icons.assessment_rounded,
      title: 'Reports & Analytics',
      accentColor: FuturisticColors.primary,
      shortcutHint: 'Ctrl+3',
      items: [
        SidebarMenuItem(
            id: 'fuel_rates',
            icon: Icons.price_change_outlined,
            label: 'Fuel Rates Config'),
        SidebarMenuItem(
            id: 'fuel_profit_report',
            icon: Icons.trending_up_outlined,
            label: 'Profit Analysis'),
        SidebarMenuItem(
            id: 'nozzle_sales_report',
            icon: Icons.local_gas_station_outlined,
            label: 'Nozzle Sales'),
        SidebarMenuItem(
            id: 'shift_report',
            icon: Icons.schedule_outlined,
            label: 'Shift Reports'),
        SidebarMenuItem(
            id: 'tank_stock_report',
            icon: Icons.water_drop_outlined,
            label: 'Tank Stock'),
      ],
    ),
    ..._getCommonSections(startingIndex: 3),
  ];
}

List<SidebarSection> _getPharmacySections() {
  return [
    SidebarSection(
      index: 0,
      icon: Icons.local_pharmacy_rounded,
      title: 'Pharmacy Control',
      accentColor: FuturisticColors.accent1,
      shortcutHint: 'Ctrl+1',
      items: [
        SidebarMenuItem(
            id: 'executive_dashboard',
            icon: Icons.dashboard_customize_outlined,
            label: 'Dashboard'),
        SidebarMenuItem(
            id: 'live_health',
            icon: Icons.monitor_heart_outlined,
            label: 'Live Health'),
        SidebarMenuItem(
            id: 'daily_snapshot',
            icon: Icons.today_outlined,
            label: 'Daily Snapshot'),
      ],
    ),
    SidebarSection(
      index: 1,
      icon: Icons.medication_rounded,
      title: 'Dispensing & Sales',
      accentColor: FuturisticColors.success,
      shortcutHint: 'Ctrl+2',
      items: [
        SidebarMenuItem(
            id: 'new_sale',
            icon: Icons.point_of_sale_outlined,
            label: 'New Sale (POS)'),
        SidebarMenuItem(
            id: 'prescriptions',
            icon: Icons.description_outlined,
            label: 'Prescriptions',
            capability: BusinessCapability.usePrescription),
        SidebarMenuItem(
            id: 'revenue_overview',
            icon: Icons.analytics_outlined,
            label: 'Revenue Overview'),
        SidebarMenuItem(
            id: 'sales_register',
            icon: Icons.menu_book_outlined,
            label: 'Sales Register'),
      ],
    ),
    SidebarSection(
      index: 2,
      icon: Icons.inventory_2_rounded,
      title: 'Inventory & Expiry',
      accentColor: FuturisticColors.warning,
      shortcutHint: 'Ctrl+3',
      items: [
        SidebarMenuItem(
            id: 'item_stock',
            icon: Icons.category_outlined,
            label: 'Medicine Stock'),
        SidebarMenuItem(
            id: 'batch_tracking',
            icon: Icons.layers_outlined,
            label: 'Batch / Expiry View'),
        SidebarMenuItem(
            id: 'low_stock',
            icon: Icons.warning_amber_outlined,
            label: 'Low Stock / Expiry',
            badge: true),
        SidebarMenuItem(
            id: 'stock_valuation',
            icon: Icons.price_check_outlined,
            label: 'Stock Valuation'),
      ],
    ),
    SidebarSection(
        index: 3,
        icon: Icons.shopping_bag_rounded,
        title: 'Procurement',
        accentColor: FuturisticColors.primary,
        shortcutHint: 'Ctrl+4',
        items: [
          SidebarMenuItem(
              id: 'purchase_orders',
              icon: Icons.shopping_cart_checkout_outlined,
              label: 'Purchase Orders'),
          SidebarMenuItem(
              id: 'stock_entry',
              icon: Icons.add_box_outlined,
              label: 'Stock Entry'),
          SidebarMenuItem(
              id: 'supplier_bills',
              icon: Icons.request_quote_outlined,
              label: 'Supplier Bills'),
        ]),
    ..._getCommonSections(startingIndex: 4),
  ];
}

List<SidebarSection> _getCommonSections({required int startingIndex}) {
  int idx = startingIndex;
  return [
    SidebarSection(
      index: idx++,
      icon: Icons.people_alt_rounded,
      title: 'Parties & Ledger',
      accentColor: FuturisticColors.accent2,
      items: [
        SidebarMenuItem(
            id: 'customers', icon: Icons.person_outline, label: 'Customers'),
        SidebarMenuItem(
            id: 'suppliers',
            icon: Icons.storefront_outlined,
            label: 'Suppliers'),
        SidebarMenuItem(
            id: 'party_ledger',
            icon: Icons.account_balance_wallet_outlined,
            label: 'Party Ledger'),
        SidebarMenuItem(
            id: 'outstanding',
            icon: Icons.pending_actions_outlined,
            label: 'Outstanding'),
      ],
    ),
    SidebarSection(
      index: idx++,
      icon: Icons.insights_rounded,
      title: 'Reports & Analytics',
      accentColor: const Color(0xFF00D4FF),
      items: [
        SidebarMenuItem(
            id: 'analytics_hub',
            icon: Icons.hub_outlined,
            label: 'Analytics Hub'),
        SidebarMenuItem(
            id: 'product_performance',
            icon: Icons.auto_graph_outlined,
            label: 'Product Performance'),
        SidebarMenuItem(
            id: 'invoice_margin',
            icon: Icons.money_outlined,
            label: 'Profit & Loss'),
        SidebarMenuItem(
            id: 'gstr1', icon: Icons.receipt_outlined, label: 'GST Reports'),
      ],
    ),
    SidebarSection(
      index: idx++,
      icon: Icons.settings_applications_rounded,
      title: 'System',
      accentColor: FuturisticColors.textSecondary,
      items: [
        SidebarMenuItem(
            id: 'print_settings',
            icon: Icons.print_outlined,
            label: 'Printing'),
        SidebarMenuItem(
            id: 'backup', icon: Icons.backup_outlined, label: 'Backup'),
        SidebarMenuItem(
            id: 'error_logs', icon: Icons.error_outline, label: 'System Logs'),
        SidebarMenuItem(
            id: 'device_settings',
            icon: Icons.devices_outlined,
            label: 'Settings'),
      ],
    ),
  ];
}
