import 'package:flutter/material.dart';
import '../core/di/service_locator.dart';
import '../core/repository/customers_repository.dart';
import '../core/repository/bills_repository.dart';
import '../core/session/session_manager.dart';

class OwnerSummaryCards extends StatelessWidget {
  const OwnerSummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = sl<SessionManager>().ownerId;
    if (userId == null) return const SizedBox.shrink();

    final customersRepo = sl<CustomersRepository>();
    final billsRepo = sl<BillsRepository>();

    return StreamBuilder(
      stream: customersRepo.watchAll(userId: userId),
      builder: (context, customerSnap) {
        final customers = customerSnap.data ?? [];

        final totalCustomers = customers.length;
        final totalDues =
            customers.fold<double>(0, (sum, c) => sum + c.totalDues);

        return StreamBuilder(
          stream: billsRepo.watchAll(userId: userId),
          builder: (context, billsSnap) {
            final bills = billsSnap.data ?? [];

            // Calculate Week Sales
            final now = DateTime.now();
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final weekSales = bills
                .where((b) => b.date
                    .isAfter(startOfWeek.subtract(const Duration(seconds: 1))))
                .fold<double>(0, (sum, b) => sum + b.grandTotal);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _card('Customers', totalCustomers.toString()),
                _card('Total Dues', '₹${totalDues.toStringAsFixed(0)}'),
                _card('Week Sales', '₹${weekSales.toStringAsFixed(0)}'),
              ],
            );
          },
        );
      },
    );
  }

  Widget _card(String title, String value) => Card(
        child: SizedBox(
          width: 120,
          height: 80,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold))
            ]),
          ),
        ),
      );
}
