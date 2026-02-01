import 'package:flutter/material.dart';
import '../core/di/service_locator.dart';
import '../core/repository/bills_repository.dart';
import '../core/session/session_manager.dart';
import '../core/theme/futuristic_colors.dart';

class TotalPaidScreen extends StatefulWidget {
  const TotalPaidScreen({super.key});

  @override
  State<TotalPaidScreen> createState() => _TotalPaidScreenState();
}

class _TotalPaidScreenState extends State<TotalPaidScreen> {
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final ownerId = sl<SessionManager>().ownerId;

    if (ownerId == null) {
      return const Scaffold(body: Center(child: Text("Please login first")));
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 8,
        shadowColor: Colors.black26,
        backgroundColor: Colors.white,
        title: Text(
          'Total Paid',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: FuturisticColors.primary,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by invoice or customer name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Bill>>(
                stream: sl<BillsRepository>().watchAll(userId: ownerId),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var bills = snap.data ?? [];

                  // Filter only paid bills
                  bills = bills
                      .where((b) => b.status.toLowerCase() == 'paid')
                      .toList();

                  // Apply search
                  final q = _searchCtrl.text.trim().toLowerCase();
                  if (q.isNotEmpty) {
                    bills = bills.where((b) {
                      if (b.invoiceNumber.toLowerCase().contains(q)) {
                        return true;
                      }
                      if (b.customerName.toLowerCase().contains(q)) return true;
                      return false;
                    }).toList();
                  }

                  if (bills.isEmpty) {
                    return const Center(child: Text('No paid bills yet'));
                  }

                  // Calculate total paid
                  double totalPaid = 0;
                  for (final b in bills) {
                    totalPaid += b.paidAmount;
                  }

                  return Column(
                    children: [
                      // Summary card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: FuturisticColors.paidBackground,
                          border: Border.all(
                              color: FuturisticColors.paid.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Paid Amount',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${totalPaid.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: FuturisticColors.paid,
                                      ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.check_circle,
                              color: FuturisticColors.paid,
                              size: 48,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: bills.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final b = bills[idx];
                            // No need to fetch customer N+1, use b.customerName
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Invoice ${b.invoiceNumber.isEmpty ? b.id.substring(0, 8) : b.invoiceNumber}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          Text(
                                            b.customerName.isEmpty
                                                ? 'Unknown Customer'
                                                : b.customerName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const Icon(
                                        Icons.check_circle,
                                        color: FuturisticColors.paid,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        b.date.toIso8601String().split('T')[0],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      Text(
                                        '₹${b.paidAmount.toStringAsFixed(2)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
