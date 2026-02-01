import 'package:flutter/material.dart';
import '../../core/repository/bills_repository.dart';
import '../../core/di/service_locator.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/futuristic_colors.dart';

class DashboardMetricsRow extends StatelessWidget {
  const DashboardMetricsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Bill>>(
      stream: sl<BillsRepository>()
          .watchAll(userId: sl<SessionManager>().ownerId ?? ''),
      builder: (context, snapshot) {
        double totalRevenue = 0;
        double paidThisMonth = 0;
        double outstanding = 0;
        double overdue = 0;

        if (snapshot.hasData) {
          final now = DateTime.now();
          final bills = snapshot.data!;

          totalRevenue = bills
              .where((b) => b.status == 'Paid')
              .fold(0, (sum, b) => sum + b.grandTotal);
          paidThisMonth = bills
              .where((b) =>
                  b.status == 'Paid' &&
                  b.date.month == now.month &&
                  b.date.year == now.year)
              .fold(0, (sum, b) => sum + b.grandTotal);
          outstanding = bills
              .where((b) => b.status != 'Paid')
              .fold(0, (sum, b) => sum + (b.grandTotal - b.paidAmount));
          overdue = bills
              .where((b) =>
                  b.status != 'Paid' && now.difference(b.date).inDays > 30)
              .fold(0, (sum, b) => sum + (b.grandTotal - b.paidAmount));
        }

        return Row(
          children: [
            Expanded(
                child: _MetricCard(
              title: "Total Revenue",
              value: "₹${totalRevenue.toStringAsFixed(0)}",
              color: FuturisticColors.primary,
              icon: Icons.account_balance_wallet,
            )),
            const SizedBox(width: 16),
            Expanded(
                child: _MetricCard(
              title: "Outstanding",
              value: "₹${outstanding.toStringAsFixed(0)}",
              color: FuturisticColors.accent1,
              icon: Icons.pending_actions,
            )),
            const SizedBox(width: 16),
            Expanded(
                child: _MetricCard(
              title: "Paid This Month",
              value: "₹${paidThisMonth.toStringAsFixed(0)}",
              color: FuturisticColors.success,
              icon: Icons.check_circle_outline,
            )),
            const SizedBox(width: 16),
            Expanded(
                child: _MetricCard(
              title: "Overdue",
              value: "₹${overdue.toStringAsFixed(0)}",
              color: FuturisticColors.error,
              icon: Icons.warning_amber,
            )),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricCard(
      {required this.title,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FuturisticColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: FuturisticColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              Icon(icon, color: color.withOpacity(0.7), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
