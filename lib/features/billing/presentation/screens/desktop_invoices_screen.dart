import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/repository/bills_repository.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/futuristic_colors.dart';

import '../../../../screens/bill_detail.dart';
import '../../../../widgets/desktop/enterprise_table.dart';
import '../../../billing/presentation/screens/bill_creation_screen_v2.dart';
import '../../../invoice/screens/invoice_preview_screen.dart';

class DesktopInvoicesScreen extends ConsumerStatefulWidget {
  const DesktopInvoicesScreen({super.key});

  @override
  ConsumerState<DesktopInvoicesScreen> createState() =>
      _DesktopInvoicesScreenState();
}

class _DesktopInvoicesScreenState extends ConsumerState<DesktopInvoicesScreen> {
  final String _userId = sl<SessionManager>().ownerId ?? '';
  final _billsRepo = sl<BillsRepository>();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header & Actions
            _buildHeader(),
            const SizedBox(height: 24),
            // Data Table
            Expanded(
              child: StreamBuilder<List<Bill>>(
                stream: _billsRepo.watchAll(userId: _userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var bills = snapshot.data ?? [];

                  // Local Filtering
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    bills = bills.where((b) {
                      final invoice = b.invoiceNumber.toLowerCase();
                      final customer = (b.customerName).toLowerCase();
                      final amount = b.grandTotal.toString();
                      return invoice.contains(q) ||
                          customer.contains(q) ||
                          amount.contains(q);
                    }).toList();
                  }

                  // Default Sort: Handled by Table usually, but good to prepopulate
                  // bills.sort((a, b) => b.date.compareTo(a.date));

                  return EnterpriseTable<Bill>(
                    data: bills,
                    columns: _buildColumns(),
                    onRowTap: (bill) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BillDetailScreen(bill: bill),
                        ),
                      );
                    },
                    actionsBuilder: (bill) => [
                      IconButton(
                        icon: const Icon(
                          Icons.visibility_outlined,
                          size: 20,
                          color: FuturisticColors.accent1,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BillDetailScreen(bill: bill),
                            ),
                          );
                        },
                        tooltip: 'View',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.print_outlined,
                          size: 20,
                          color: FuturisticColors.textSecondary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  InvoicePreviewScreen(bill: bill),
                            ),
                          );
                        },
                        tooltip: 'Print',
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

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Invoices",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Manage and track all sales records",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Search
        Container(
          width: 300,
          height: 44,
          decoration: BoxDecoration(
            color: FuturisticColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Search invoices...',
              hintStyle: TextStyle(color: FuturisticColors.textSecondary),
              prefixIcon: Icon(
                Icons.search,
                color: FuturisticColors.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Create Button
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BillCreationScreenV2()),
            ),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: FuturisticColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: FuturisticColors.primary.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Create Bill",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<EnterpriseTableColumn<Bill>> _buildColumns() {
    return [
      EnterpriseTableColumn(
        title: "Date",
        valueBuilder: (bill) => bill.date, // For sorting
        widgetBuilder: (bill) => Text(
          DateFormat('dd MMM yyyy').format(bill.date),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      EnterpriseTableColumn(
        title: "Invoice #",
        valueBuilder: (bill) => bill.invoiceNumber,
        widgetBuilder: (bill) => Text(
          bill.invoiceNumber,
          style: const TextStyle(
            color: FuturisticColors.accent1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      EnterpriseTableColumn(
        title: "Customer",
        valueBuilder: (bill) => bill.customerName,
        widgetBuilder: (bill) {
          final name = bill.customerName;
          return Text(
            name.isEmpty ? "Walk-in" : name,
            style: const TextStyle(color: Colors.white70),
          );
        },
      ),
      if (sl<SessionManager>().activeBusinessType == BusinessType.restaurant)
        EnterpriseTableColumn(
          title: "Table #",
          valueBuilder: (bill) => bill.tableNumber ?? '-',
          widgetBuilder: (bill) => Text(
            bill.tableNumber ?? '-',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      EnterpriseTableColumn(
        title: "Amount",
        valueBuilder: (bill) => bill.grandTotal,
        isNumeric: true,
        widgetBuilder: (bill) => Text(
          "₹ ${bill.grandTotal.toStringAsFixed(2)}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      EnterpriseTableColumn(
        title: "Status",
        valueBuilder: (bill) => bill.status,
        widgetBuilder: (bill) => _buildStatusBadge(bill.status),
      ),
      EnterpriseTableColumn(
        title: "Mode",
        valueBuilder: (bill) => bill.paymentType,
        widgetBuilder: (bill) => Text(
          bill.paymentType,
          style: const TextStyle(color: Colors.white60),
        ),
      ),
    ];
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = FuturisticColors.success;
        break;
      case 'pending':
      case 'unpaid':
        color = FuturisticColors.warning;
        break;
      case 'cancelled':
        color = FuturisticColors.error;
        break;
      default:
        color = FuturisticColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
