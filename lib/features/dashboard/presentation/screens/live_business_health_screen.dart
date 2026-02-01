import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/repository/bills_repository.dart';
// import '../../../../core/session/session_manager.dart';
import '../../../../core/repository/products_repository.dart';
import '../../../../core/repository/bank_repository.dart';
import '../../../../providers/app_state_providers.dart';
import '../../../../widgets/glass_morphism.dart';
import '../../../../widgets/desktop/desktop_content_container.dart';

/// Live Business Health Screen
///
/// Real-time dashboard showing:
/// - Business health score
/// - Cash position
/// - Receivables vs Payables (Payables requires purchase module)
/// - Stock alerts
/// - Today's metrics
class LiveBusinessHealthScreen extends ConsumerStatefulWidget {
  const LiveBusinessHealthScreen({super.key});

  @override
  ConsumerState<LiveBusinessHealthScreen> createState() =>
      _LiveBusinessHealthScreenState();
}

class _LiveBusinessHealthScreenState
    extends ConsumerState<LiveBusinessHealthScreen> {
  bool _loading = true;

  // Health metrics
  int _healthScore = 0;
  String _healthStatus = 'Calculating...';
  Color _healthColor = Colors.grey;

  // Cash metrics
  double _cashBalance = 0;
  double _bankBalance = 0;
  double _totalLiquidity = 0;

  // Receivables
  double _totalReceivables = 0;
  double _overdueAmount = 0;
  int _overdueCount = 0;

  // Stock metrics
  int _lowStockCount = 0;
  double _stockValue = 0;

  // Today's metrics
  double _todaySales = 0;
  double _todayCollections = 0;
  int _todayInvoices = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final userId = ref.read(authStateProvider).userId ?? '';
    if (userId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Load bills for receivables and today's metrics
      final billsRepo = sl<BillsRepository>();
      final billsResult = await billsRepo.getAll(userId: userId);
      final bills = billsResult.data ?? [];

      // Today's bills
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final todayBills =
          bills.where((b) => b.date.isAfter(startOfDay)).toList();

      _todaySales = todayBills.fold(0.0, (sum, b) => sum + b.grandTotal);
      _todayCollections = todayBills.fold(0.0, (sum, b) => sum + b.paidAmount);
      _todayInvoices = todayBills.length;

      // Calculate receivables (unpaid amounts)
      _totalReceivables = 0;
      _overdueAmount = 0;
      _overdueCount = 0;

      for (final bill in bills) {
        final outstanding = bill.grandTotal - bill.paidAmount;
        if (outstanding > 0) {
          _totalReceivables += outstanding;
          // Consider overdue if > 30 days old
          if (bill.date.isBefore(today.subtract(const Duration(days: 30)))) {
            _overdueAmount += outstanding;
            _overdueCount++;
          }
        }
      }

      // Load products for stock metrics
      final productsRepo = sl<ProductsRepository>();
      final productsResult = await productsRepo.getAll(userId: userId);
      final products = productsResult.data ?? [];

      _lowStockCount = products.where((p) => p.isLowStock).length;
      _stockValue =
          products.fold(0.0, (sum, p) => sum + (p.stockQuantity * p.costPrice));

      // Load bank balances
      try {
        final bankRepo = sl<BankRepository>();
        final accountsResult = await bankRepo.getAccounts(userId: userId);
        final accounts = accountsResult.data ?? [];

        for (final account in accounts) {
          if (account.accountName.toLowerCase().contains('cash')) {
            _cashBalance += account.currentBalance;
          } else {
            _bankBalance += account.currentBalance;
          }
        }
        _totalLiquidity = _cashBalance + _bankBalance;
      } catch (e) {
        // Bank repo might not have data
      }

      // Calculate health score
      _calculateHealthScore();

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _calculateHealthScore() {
    int score = 100;

    // Deduct for overdue receivables (max -30)
    if (_totalReceivables > 0) {
      final overduePercent = _overdueAmount / _totalReceivables;
      score -= (overduePercent * 30).toInt();
    }

    // Deduct for low stock (max -20)
    score -= (_lowStockCount * 2).clamp(0, 20);

    // Deduct for low liquidity (max -20)
    if (_totalLiquidity < 10000) {
      score -= 20;
    } else if (_totalLiquidity < 50000) {
      score -= 10;
    }

    // Bonus for good collections today (max +10)
    if (_todaySales > 0 && _todayCollections / _todaySales > 0.8) {
      score += 10;
    }

    _healthScore = score.clamp(0, 100);

    if (_healthScore >= 80) {
      _healthStatus = 'Excellent';
      _healthColor = const Color(0xFF10B981);
    } else if (_healthScore >= 60) {
      _healthStatus = 'Good';
      _healthColor = const Color(0xFF06B6D4);
    } else if (_healthScore >= 40) {
      _healthStatus = 'Attention Needed';
      _healthColor = const Color(0xFFF59E0B);
    } else {
      _healthStatus = 'Critical';
      _healthColor = const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopContentContainer(
      title: 'Live Business Health',
      subtitle: 'Last updated: ${DateFormat('hh:mm a').format(DateTime.now())}',
      actions: [
        DesktopIconButton(
          icon: Icons.refresh,
          tooltip: 'Refresh',
          onPressed: _loadData,
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Health Score Card
                _buildHealthScoreCard(
                    Theme.of(context).brightness == Brightness.dark),
                const SizedBox(height: 24),

                // QuickMetrics Row
                _buildQuickMetrics(
                    Theme.of(context).brightness == Brightness.dark),
                const SizedBox(height: 24),

                // Detailed Cards
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      child: Column(
                        children: [
                          _buildCashPositionCard(
                              Theme.of(context).brightness == Brightness.dark),
                          const SizedBox(height: 16),
                          _buildReceivablesCard(
                              Theme.of(context).brightness == Brightness.dark),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right Column
                    Expanded(
                      child: Column(
                        children: [
                          _buildStockAlertsCard(
                              Theme.of(context).brightness == Brightness.dark),
                          const SizedBox(height: 16),
                          _buildTodayMetricsCard(
                              Theme.of(context).brightness == Brightness.dark),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildHealthScoreCard(bool isDark) {
    return GlassMorphism(
      blur: 10,
      opacity: 0.1,
      borderRadius: 20, // Fixed: double
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Health Score Circle
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _healthScore / 100,
                      strokeWidth: 12,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_healthColor),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_healthScore',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _healthColor,
                        ),
                      ),
                      Text(
                        'SCORE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Status Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _healthColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _healthStatus,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _healthColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHealthIndicator(
                      'Receivables', _overdueCount == 0, isDark),
                  _buildHealthIndicator(
                      'Stock Levels', _lowStockCount == 0, isDark),
                  _buildHealthIndicator(
                      'Cash Position', _totalLiquidity > 10000, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String label, bool isGood, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning,
            size: 16,
            color: isGood ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetrics(bool isDark) {
    return Row(
      children: [
        Expanded(
            child: _buildMetricTile(
                'Today\'s Sales',
                '₹${_formatAmount(_todaySales)}',
                Icons.trending_up,
                const Color(0xFF10B981),
                isDark)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildMetricTile(
                'Collections',
                '₹${_formatAmount(_todayCollections)}',
                Icons.payments,
                const Color(0xFF06B6D4),
                isDark)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildMetricTile(
                'Receivables',
                '₹${_formatAmount(_totalReceivables)}',
                Icons.account_balance_wallet,
                const Color(0xFFF59E0B),
                isDark)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildMetricTile(
                'Liquidity',
                '₹${_formatAmount(_totalLiquidity)}',
                Icons.savings,
                const Color(0xFF8B5CF6),
                isDark)),
      ],
    );
  }

  Widget _buildMetricTile(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashPositionCard(bool isDark) {
    return _buildCard(
      isDark,
      'Cash Position',
      Icons.account_balance,
      const Color(0xFF10B981),
      Column(
        children: [
          _buildDetailRow(
              'Cash in Hand', '₹${_formatAmount(_cashBalance)}', isDark),
          _buildDetailRow(
              'Bank Balance', '₹${_formatAmount(_bankBalance)}', isDark),
          const Divider(height: 24),
          _buildDetailRow(
              'Total Liquidity', '₹${_formatAmount(_totalLiquidity)}', isDark,
              isBold: true),
        ],
      ),
    );
  }

  Widget _buildReceivablesCard(bool isDark) {
    return _buildCard(
      isDark,
      'Receivables',
      Icons.receipt_long,
      const Color(0xFFF59E0B),
      Column(
        children: [
          _buildDetailRow('Total Outstanding',
              '₹${_formatAmount(_totalReceivables)}', isDark),
          _buildDetailRow(
              'Overdue (>30 days)', '₹${_formatAmount(_overdueAmount)}', isDark,
              valueColor: const Color(0xFFEF4444)),
          _buildDetailRow('Overdue Invoices', '$_overdueCount', isDark),
        ],
      ),
    );
  }

  Widget _buildStockAlertsCard(bool isDark) {
    return _buildCard(
      isDark,
      'Stock Alerts',
      Icons.inventory_2,
      const Color(0xFFEF4444),
      Column(
        children: [
          _buildDetailRow('Low Stock Items', '$_lowStockCount', isDark,
              valueColor: _lowStockCount > 0 ? const Color(0xFFF59E0B) : null),
          _buildDetailRow(
              'Stock Value', '₹${_formatAmount(_stockValue)}', isDark),
        ],
      ),
    );
  }

  Widget _buildTodayMetricsCard(bool isDark) {
    return _buildCard(
      isDark,
      'Today\'s Activity',
      Icons.today,
      const Color(0xFF06B6D4),
      Column(
        children: [
          _buildDetailRow('Invoices Created', '$_todayInvoices', isDark),
          _buildDetailRow(
              'Total Sales', '₹${_formatAmount(_todaySales)}', isDark),
          _buildDetailRow(
              'Collected', '₹${_formatAmount(_todayCollections)}', isDark),
          _buildDetailRow(
            'Collection Rate',
            _todaySales > 0
                ? '${((_todayCollections / _todaySales) * 100).toStringAsFixed(0)}%'
                : 'N/A',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      bool isDark, String title, IconData icon, Color color, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
        ),
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
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    }
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
