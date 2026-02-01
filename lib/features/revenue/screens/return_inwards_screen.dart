import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/app_state_providers.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/repository/bills_repository.dart';
import '../../../widgets/glass_morphism.dart';
import '../models/revenue_models.dart';
import '../services/revenue_service.dart';
import '../../../widgets/desktop/desktop_content_container.dart';

class ReturnInwardsScreen extends ConsumerWidget {
  const ReturnInwardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeStateProvider);
    final isDark = theme.isDark;
    final ownerId = sl<SessionManager>().ownerId ?? '';

    return DesktopContentContainer(
      title: 'Return Inwards',
      actions: [
        DesktopActionButton(
          icon: Icons.add,
          label: 'New Return',
          onPressed: () => _showAddReturnSheet(context, ownerId, isDark),
        ),
      ],
      child: StreamBuilder<List<ReturnInward>>(
        stream: RevenueService().streamReturns(ownerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final returns = snapshot.data ?? [];

          if (returns.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_return,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Returns Recorded',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Process returns when customers bring back goods',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showAddReturnSheet(context, ownerId, isDark),
                    icon: const Icon(Icons.add),
                    label: const Text('Process Return'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: returns.length,
            itemBuilder: (context, index) {
              final ret = returns[index];
              return _ReturnCard(returnData: ret, isDark: isDark);
            },
          );
        },
      ),
    );
  }

  void _showAddReturnSheet(BuildContext context, String ownerId, bool isDark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddReturnScreen(ownerId: ownerId),
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final ReturnInward returnData;
  final bool isDark;

  const _ReturnCard({required this.returnData, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_return,
                        color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        returnData.creditNoteNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        returnData.customerName,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PROCESSED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Bill Reference
          Row(
            children: [
              const Icon(Icons.receipt, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Against Bill: ${returnData.billNumber}',
                style:
                    TextStyle(color: isDark ? Colors.white54 : Colors.black45),
              ),
              const Spacer(),
              Text(
                dateFormat.format(returnData.date),
                style:
                    TextStyle(color: isDark ? Colors.white38 : Colors.black38),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items
          ...returnData.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '↩ ${item.itemName} × ${item.quantity.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45),
                    ),
                    Text(
                      currencyFormat.format(item.amount),
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45),
                    ),
                  ],
                ),
              )),
          const Divider(height: 24),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Credit Note Amount',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                currencyFormat.format(returnData.totalReturnAmount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          // Reason
          if (returnData.reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: ${returnData.reason}',
                        style:
                            const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Add Return Screen
class _AddReturnScreen extends ConsumerStatefulWidget {
  final String ownerId;

  const _AddReturnScreen({required this.ownerId});

  @override
  ConsumerState<_AddReturnScreen> createState() => _AddReturnScreenState();
}

class _AddReturnScreenState extends ConsumerState<_AddReturnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _revenueService = RevenueService();
  final _reasonController = TextEditingController();

  String? _selectedBillId;
  Bill? _selectedBill;
  final List<ReturnItem> _returnItems = [];
  bool _isSaving = false;

  double get _totalReturnAmount =>
      _returnItems.fold(0, (total, item) => total + item.amount);

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeStateProvider);
    final isDark = theme.isDark;

    return DesktopContentContainer(
      title: 'Process Return',
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            if (isDesktop) {
              return Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _buildSelectBillCard(isDark),
                              const SizedBox(height: 16),
                              if (_selectedBill != null)
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: _buildReturnItemsCard(isDark),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _buildSummaryCard(isDark),
                              const SizedBox(height: 16),
                              _buildReasonCard(isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                  const SizedBox(height: 16),
                ],
              );
            }

            // Mobile Layout
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildSelectBillCard(isDark),
                  const SizedBox(height: 16),
                  if (_selectedBill != null) _buildReturnItemsCard(isDark),
                  const SizedBox(height: 16),
                  _buildReasonCard(isDark),
                  const SizedBox(height: 16),
                  _buildSummaryCard(isDark),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectBillCard(bool isDark) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Original Bill',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _selectBill(isDark),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedBillId != null
                      ? Colors.green
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: _selectedBill != null
                  ? Row(
                      children: [
                        const Icon(Icons.receipt_long, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedBill!.invoiceNumber,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                _selectedBill!.customerName,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${_selectedBill!.grandTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Text(
                          'Tap to select a bill',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnItemsCard(bool isDark) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items to Return',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ..._selectedBill!.items.map((item) {
            final isSelected = _returnItems.any((r) => r.itemId == item.vegId);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                item.itemName,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                'Qty: ${item.qty} × ₹${item.unitPrice}',
                style:
                    TextStyle(color: isDark ? Colors.white54 : Colors.black45),
              ),
              secondary: Text(
                '₹${item.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black),
              ),
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _returnItems.add(ReturnItem(
                      itemId: item.vegId,
                      itemName: item.itemName,
                      quantity: item.qty,
                      rate: item.unitPrice,
                      amount: item.totalAmount,
                    ));
                  } else {
                    _returnItems.removeWhere((r) => r.itemId == item.vegId);
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReasonCard(bool isDark) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Return Reason',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reasonController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'E.g., Damaged goods, wrong item, quality issue',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (val) =>
                val?.isEmpty == true ? 'Please specify reason' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    if (_returnItems.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items to Return',
                style:
                    TextStyle(color: isDark ? Colors.white54 : Colors.black45),
              ),
              Text(
                '${_returnItems.length}',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Credit Note Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '₹${_totalReturnAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Stock will be automatically updated',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _returnItems.isNotEmpty && !_isSaving ? _saveReturn : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check),
                  const SizedBox(width: 8),
                  const Text('Process Return', style: TextStyle(fontSize: 18)),
                ],
              ),
      ),
    );
  }

  Future<void> _selectBill(bool isDark) async {
    final result = await sl<BillsRepository>().getAll(userId: widget.ownerId);
    final bills = result.data ?? [];

    if (!mounted) return;

    final selected = await showModalBottomSheet<Bill>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Bill for Return',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: bills.isEmpty
                  ? const Center(child: Text('No bills found'))
                  : ListView.builder(
                      itemCount: bills.length,
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                const Icon(Icons.receipt, color: Colors.blue),
                          ),
                          title: Text(
                            bill.invoiceNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(bill.customerName),
                          trailing: Text(
                            '₹${bill.grandTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                          onTap: () {
                            Navigator.pop(ctx, bill);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );

    setState(() {
      if (selected != null) {
        _selectedBillId = selected.id;
        _selectedBill = selected;
        _returnItems.clear();
      }
    });
  }

  Future<void> _saveReturn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final returnData = ReturnInward(
        id: '',
        ownerId: widget.ownerId,
        customerId: _selectedBill!.customerId,
        customerName: _selectedBill!.customerName,
        billId: _selectedBillId!,
        billNumber: _selectedBill!.invoiceNumber,
        items: _returnItems,
        totalReturnAmount: _totalReturnAmount,
        reason: _reasonController.text,
        creditNoteNumber: '',
        status: ReturnStatus.processed,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _revenueService.addReturnInward(widget.ownerId, returnData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Return processed! Credit note generated.'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
