import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/futuristic_colors.dart';
import '../../../../widgets/desktop/neon_card.dart';
import '../../../dashboard/data/dashboard_analytics_repository.dart';
import '../../../../core/session/session_manager.dart';

class UpcomingPaymentsPanel extends StatefulWidget {
  const UpcomingPaymentsPanel({super.key});

  @override
  State<UpcomingPaymentsPanel> createState() => _UpcomingPaymentsPanelState();
}

class _UpcomingPaymentsPanelState extends State<UpcomingPaymentsPanel> {
  bool _isLoading = true;
  List<BillEntity> _payments = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final userId = sl<SessionManager>().userId;
      if (userId == null) return;

      final data = await sl<DashboardAnalyticsRepository>().getUpcomingPayments(
        userId: userId,
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _payments = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      height: 350, // Match expense chart
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Payments',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: FuturisticColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Collect these soon',
                    style: TextStyle(
                        color: FuturisticColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              // Icon or Action
              const Icon(Icons.calendar_today,
                  color: FuturisticColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_payments.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: FuturisticColors.success.withOpacity(0.5),
                        size: 48),
                    const SizedBox(height: 16),
                    const Text('All caught up!',
                        style:
                            TextStyle(color: FuturisticColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final bill = _payments[index];
                  // Calculate due date (assuming 7 days credit if not in DB)
                  final dueDate = bill.billDate.add(const Duration(days: 7));
                  final daysOverdue = DateTime.now().difference(dueDate).inDays;
                  final isOverdue = daysOverdue > 0;

                  final customerName = bill.customerName;
                  final hasCustomer =
                      customerName != null && customerName.isNotEmpty;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FuturisticColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOverdue
                            ? FuturisticColors.error.withOpacity(0.3)
                            : FuturisticColors.divider,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Date Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: FuturisticColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: [
                              Text(DateFormat('MMM').format(dueDate),
                                  style: const TextStyle(
                                      color: FuturisticColors.textSecondary,
                                      fontSize: 10)),
                              Text(DateFormat('d').format(dueDate),
                                  style: const TextStyle(
                                      color: FuturisticColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasCustomer ? customerName : 'Walk-in',
                                style: const TextStyle(
                                    color: FuturisticColors.textPrimary,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isOverdue
                                    ? 'Overdue by $daysOverdue days'
                                    : 'Due in ${daysOverdue.abs()} days',
                                style: TextStyle(
                                  color: isOverdue
                                      ? FuturisticColors.error
                                      : FuturisticColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          NumberFormat.currency(symbol: '₹')
                              .format(bill.grandTotal - bill.paidAmount),
                          style: const TextStyle(
                              color: FuturisticColors.textPrimary,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
