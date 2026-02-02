import 'package:flutter/material.dart';
import '../../core/theme/futuristic_colors.dart';
import 'enterprise_table.dart';

/// Premium Recent Transactions Table with glassmorphism styling.
/// Displays real transaction data with enhanced status badges and visual effects.
class RecentTransactionsTable extends StatelessWidget {
  final List<dynamic> transactions;
  final VoidCallback onViewAll;

  const RecentTransactionsTable({
    super.key,
    required this.transactions,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.cardColor, theme.cardColor.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FuturisticColors.premiumBlue.withOpacity(0.2),
        ),
        boxShadow: [
          // Premium blue glow
          BoxShadow(
            color: FuturisticColors.premiumBlue.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with View All button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FuturisticColors.accent1.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: FuturisticColors.accent1,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Recent Transactions",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // View All button with hover effect
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: FuturisticColors.accent1.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "View All",
                          style: TextStyle(
                            color: FuturisticColors.accent1,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: FuturisticColors.accent1,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Table content
          Expanded(
            child: EnterpriseTable(
              columns: [
                EnterpriseTableColumn(
                  title: "Invoice #",
                  valueBuilder: (item) => (item as Map)['id'],
                  widgetBuilder: (item) {
                    final id = (item as Map)['id'];
                    return Text(
                      id,
                      style: TextStyle(
                        color: FuturisticColors.accent1,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                EnterpriseTableColumn(
                  title: "Customer",
                  valueBuilder: (item) => (item as Map)['customer'],
                  widgetBuilder: (item) {
                    final customer = (item as Map)['customer'];
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: FuturisticColors.primary.withOpacity(
                            0.2,
                          ),
                          child: Text(
                            customer.isNotEmpty
                                ? customer[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: FuturisticColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            customer,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                EnterpriseTableColumn(
                  title: "Amount",
                  valueBuilder: (item) => (item as Map)['amount'],
                  isNumeric: true,
                  widgetBuilder: (item) {
                    final amount = (item as Map)['amount'];
                    return Text(
                      amount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                EnterpriseTableColumn(
                  title: "Status",
                  valueBuilder: (item) => (item as Map)['status'],
                  widgetBuilder: (item) => _buildStatusBadge(item),
                ),
              ],
              // DATA INTEGRITY: Only show REAL transactions - NO mock data
              data: transactions,
              rowsPerPage: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(dynamic item) {
    final status = (item as Map)['status'];
    Color color;
    IconData icon;

    switch (status) {
      case 'Paid':
        color = FuturisticColors.success;
        icon = Icons.check_circle;
        break;
      case 'Pending':
        color = FuturisticColors.warning;
        icon = Icons.schedule;
        break;
      case 'Unpaid':
        color = FuturisticColors.error;
        icon = Icons.error_outline;
        break;
      default:
        color = FuturisticColors.textSecondary;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
