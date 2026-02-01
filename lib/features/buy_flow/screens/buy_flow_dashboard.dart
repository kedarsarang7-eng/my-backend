import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/app_state_providers.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/repository/reports_repository.dart';
import '../../../../models/daily_stats.dart';
import '../../../widgets/desktop/desktop_content_container.dart';
import 'stock_entry_screen.dart';
import 'vendor_payouts_screen.dart';
import 'stock_reversal_screen.dart';
import 'buy_orders_screen.dart';

class BuyFlowDashboard extends ConsumerStatefulWidget {
  const BuyFlowDashboard({super.key});

  @override
  ConsumerState<BuyFlowDashboard> createState() => _BuyFlowDashboardState();
}

class _BuyFlowDashboardState extends ConsumerState<BuyFlowDashboard> {
  final _session = sl<SessionManager>();
  final _reportsRepository = sl<ReportsRepository>();

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeStateProvider);
    final isDark = theme.isDark;
    final ownerId = _session.ownerId ?? '';

    return DesktopContentContainer(
      title: "BuyFlow Dashboard",
      child: StreamBuilder<VendorStats>(
        stream: _reportsRepository.watchVendorStats(ownerId),
        initialData: VendorStats.empty(),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? VendorStats.empty();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        "Total Purchased",
                        "₹${stats.totalInvoiceValue.toStringAsFixed(0)}",
                        Icons.inventory_2_rounded,
                        Colors.blue,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        "Pending Payments",
                        "₹${stats.unpaidAmount.toStringAsFixed(0)}",
                        Icons.pending_actions_rounded,
                        Colors.orange,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        "Active Orders",
                        "${stats.activeOrders}",
                        Icons.local_shipping_rounded,
                        Colors.purple,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        "Recent Returns",
                        "₹0", // Placeholder
                        Icons.keyboard_return_rounded,
                        Colors.redAccent,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 2. Quick Actions
                Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, constraints) {
                  return GridView.count(
                    crossAxisCount: constraints.maxWidth > 900 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildActionCard(
                        context,
                        "Stock Entry",
                        "Add new inventory",
                        Icons.add_box_rounded,
                        Colors.green,
                        isDark,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const StockEntryScreen())),
                      ),
                      _buildActionCard(
                        context,
                        "Pay Vendor",
                        "Clear dues",
                        Icons.payment_rounded,
                        Colors.blue,
                        isDark,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const VendorPayoutsScreen())),
                      ),
                      _buildActionCard(
                        context,
                        "Create Order",
                        "Request stock",
                        Icons.shopping_cart_checkout_rounded,
                        Colors.purple,
                        isDark,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BuyOrdersScreen())),
                      ),
                      _buildActionCard(
                        context,
                        "Stock Reversal",
                        "Return items",
                        Icons.assignment_return_rounded,
                        Colors.orange,
                        isDark,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const StockReversalScreen())),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 32),

                // 3. Recent Activity (Placeholder for now)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Activity",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text("View All"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActivityItem("Stock Added",
                    "Invoice #8822 from Raj Traders", "Just now", isDark),
                _buildActivityItem("Payment Made", "₹5,000 to Apex Supplies",
                    "2 hours ago", isDark),
                _buildActivityItem("Order Sent", "Order #PO-001 to Raj Traders",
                    "5 hours ago", isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color, bool isDark,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [color.withOpacity(0.15), color.withOpacity(0.05)]
                : [color.withOpacity(0.1), color.withOpacity(0.01)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String subtitle, String time, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.history,
              size: 20, color: isDark ? Colors.white54 : Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
