import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/repository/reports_repository.dart';
import '../../../../core/repository/expenses_repository.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/futuristic_colors.dart';
import '../../../../models/daily_stats.dart';
import '../../../../widgets/desktop/dashboard_stat_card.dart';
import '../../../../widgets/desktop/revenue_analytics_chart.dart';
import '../../../../widgets/desktop/expense_breakdown_chart.dart';
import '../../../../widgets/desktop/recent_transactions_table.dart';
import '../../../../widgets/desktop/tax_summary_panel.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/navigation/navigation_controller.dart';
import '../../../../core/navigation/app_screens.dart';
import '../../../../widgets/desktop/desktop_content_container.dart';

class DesktopDashboardContent extends ConsumerStatefulWidget {
  const DesktopDashboardContent({super.key});

  @override
  ConsumerState<DesktopDashboardContent> createState() =>
      _DesktopDashboardContentState();
}

class _DesktopDashboardContentState
    extends ConsumerState<DesktopDashboardContent> {
  final String _userId = sl<SessionManager>().ownerId ?? '';
  late Stream<DailyStats> _statsStream;
  late Future<List<Map<String, dynamic>>> _salesTrendFuture;
  late Stream<List<ExpenseModel>> _expensesStream;
  late Stream<List<BillEntity>> _recentBillsStream;

  @override
  void initState() {
    super.initState();
    _statsStream = sl<ReportsRepository>().watchDailyStats(_userId);
    _salesTrendFuture = _fetchSalesTrend();
    _expensesStream = sl<ExpensesRepository>().watchAll(
      userId: _userId,
      fromDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    ); // Current Month Expenses
    _recentBillsStream = sl<AppDatabase>().watchAllBills(_userId);
  }

  Future<List<Map<String, dynamic>>> _fetchSalesTrend() async {
    final result =
        await sl<ReportsRepository>().getSalesTrend(userId: _userId, days: 7);
    return result.data ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return DesktopContentContainer(
      title: 'Executive Dashboard',
      subtitle: 'Real-time business insights and analytics',
      actions: [
        DesktopIconButton(
          icon: Icons.refresh,
          tooltip: 'Refresh Data',
          onPressed: () {
            setState(() {
              _salesTrendFuture = _fetchSalesTrend();
            });
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KPI Grid (3x2)
          StreamBuilder<DailyStats>(
            stream: _statsStream,
            builder: (context, snapshot) {
              final stats = snapshot.data ?? DailyStats.empty();
              return Column(
                children: [
                  // Row 1: Revenue, Paid (Month), Expense (Today)
                  Row(
                    children: [
                      Expanded(
                        child: DashboardStatCard(
                          title: "Total Revenue (Today)",
                          value: "₹${stats.todaySales.toStringAsFixed(0)}",
                          icon: Icons.attach_money,
                          color: FuturisticColors.primary,
                          trend: "Today",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardStatCard(
                          title: "Paid Used (This Month)",
                          value: "₹${stats.paidThisMonth.toStringAsFixed(0)}",
                          icon: Icons.check_circle_outline,
                          color: FuturisticColors.success,
                          isPositive: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardStatCard(
                          title: "Expense (Today)",
                          value: "₹${stats.todaySpend.toStringAsFixed(0)}",
                          icon: Icons.outbox,
                          color: FuturisticColors.error,
                          isPositive: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Row 2: Outstanding, Overdue, Low Stock
                  Row(
                    children: [
                      Expanded(
                        child: DashboardStatCard(
                          title: "Total Outstanding",
                          value: "₹${stats.totalPending.toStringAsFixed(0)}",
                          icon: Icons.pending_actions,
                          color: FuturisticColors.warning,
                          isPositive: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardStatCard(
                          title: "Overdue Amount",
                          value: "₹${stats.overdueAmount.toStringAsFixed(0)}",
                          icon: Icons.access_time_filled,
                          color: const Color(0xFFEF4444), // Red
                          isPositive: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardStatCard(
                          title: "Low Stock Items",
                          value: "${stats.lowStockCount}",
                          icon: Icons.inventory_2_outlined,
                          color: FuturisticColors.accent2,
                          isPositive: stats.lowStockCount == 0,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // 2. Charts Row (Revenue + Expense)
          SizedBox(
            height: 350,
            child: Row(
              children: [
                // Revenue Analytics
                Expanded(
                  flex: 3,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _salesTrendFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: FuturisticColors.primary));
                      }
                      final List<Map<String, dynamic>> trendData =
                          snapshot.data ?? [];
                      final Map<String, double> chartData = {};
                      for (var item in trendData) {
                        final dateStr = item['date'] as String;
                        chartData[dateStr] = (item['value'] as num).toDouble();
                      }

                      return RevenueAnalyticsChart(data: chartData);
                    },
                  ),
                ),
                const SizedBox(width: 24),

                // Expense Breakdown
                Expanded(
                  flex: 2,
                  child: StreamBuilder<List<ExpenseModel>>(
                    stream: _expensesStream,
                    builder: (context, snapshot) {
                      final expenses = snapshot.data ?? [];
                      final Map<String, double> categoryData = {};
                      for (var e in expenses) {
                        categoryData[e.category] =
                            (categoryData[e.category] ?? 0) + e.amount;
                      }
                      // Pass empty map if no expenses to handle "No Expenses" UI in widget
                      return ExpenseBreakdownChart(data: categoryData);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Bottom Section: Recent Transactions + Tax Summary
          SizedBox(
            height: 400,
            child: StreamBuilder<List<BillEntity>>(
              stream: _recentBillsStream,
              builder: (context, snapshot) {
                final bills = snapshot.data ?? [];

                // 1. Prepare Recent Transactions
                // Sort by date desc
                final sortedBills = List<BillEntity>.from(bills);
                sortedBills.sort((a, b) => b.billDate.compareTo(a.billDate));
                final recentBills = sortedBills.take(8).toList();

                final transactionData = recentBills.map((b) {
                  return {
                    'id': b.invoiceNumber,
                    'customer': b.customerName ?? 'Unknown',
                    'amount': "₹${b.grandTotal.toStringAsFixed(2)}",
                    'status': b.status,
                  };
                }).toList();

                // 2. Prepare Tax Data (Current Month)
                final now = DateTime.now();
                final monthlyBills = bills.where((b) {
                  return b.billDate.year == now.year &&
                      b.billDate.month == now.month;
                }).toList();

                return Row(
                  children: [
                    // Recent Transactions Table
                    Expanded(
                      flex: 6, // 60%
                      child: RecentTransactionsTable(
                        transactions: transactionData,
                        onViewAll: () {
                          // Navigate to Invoices Tab (Index 2)
                          // Navigate to Invoices Tab
                          ref
                              .read(navigationControllerProvider.notifier)
                              .navigateTo(AppScreen.salesRegister);
                        },
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Tax Summary Panel
                    Expanded(
                      flex: 4, // 40%
                      child: TaxSummaryPanel(monthlyBills: monthlyBills),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
