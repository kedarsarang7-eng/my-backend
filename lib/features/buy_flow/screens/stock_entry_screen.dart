import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/desktop/desktop_content_container.dart';
import 'package:intl/intl.dart';

import '../../../../providers/app_state_providers.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/repository/products_repository.dart';
import '../models/stock_entry_model.dart';
import '../services/buy_flow_service.dart';
import '../../inventory/widgets/variant_matrix_selection.dart';

class StockEntryScreen extends ConsumerStatefulWidget {
  const StockEntryScreen({super.key});

  @override
  ConsumerState<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends ConsumerState<StockEntryScreen> {
  final _session = sl<SessionManager>();
  final _buyFlowService = BuyFlowService();

  // Form State
  final _vendorCtrl = TextEditingController(); // Search/Add
  String? _selectedVendorId; // Null means new vendor

  final _invoiceCtrl = TextEditingController();
  final _paidAmountCtrl = TextEditingController();
  DateTime _invoiceDate = DateTime.now();

  final List<StockEntryItem> _items = [];
  PaymentStatus _paymentStatus =
      PaymentStatus.unpaid; // Default unpaid (Credit) for business
  bool _isLoading = false;

  // Vyapar-like: Smart Defaults
  double get _totalAmount => _items.fold(0, (acc, item) => acc + item.total);
  double get _paidAmount => double.tryParse(_paidAmountCtrl.text) ?? 0;
  double get _dueAmount => _totalAmount - _paidAmount;

  @override
  void initState() {
    super.initState();
    _paidAmountCtrl.addListener(_updatePaymentStatus);
  }

  void _updatePaymentStatus() {
    if (_paidAmount >= _totalAmount && _totalAmount > 0) {
      if (_paymentStatus != PaymentStatus.paid) {
        setState(() => _paymentStatus = PaymentStatus.paid);
      }
    } else if (_paidAmount > 0) {
      if (_paymentStatus != PaymentStatus.partial) {
        setState(() => _paymentStatus = PaymentStatus.partial);
      }
    } else {
      if (_paymentStatus != PaymentStatus.unpaid) {
        setState(() => _paymentStatus = PaymentStatus.unpaid);
      }
    }
  }

  @override
  void dispose() {
    _vendorCtrl.dispose();
    _invoiceCtrl.dispose();
    _paidAmountCtrl.dispose();
    super.dispose();
  }

  void _showAddItemDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedItemId;

    showDialog(
      context: context,
      builder: (context) {
        final ownerId = _session.ownerId ?? '';
        final theme = ref.watch(themeStateProvider);
        final isDark = theme.isDark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(
            "Add Stock Item",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 500,
            child: StreamBuilder<List<Product>>(
              stream: _buyFlowService.streamItems(ownerId),
              builder: (context, snapshot) {
                final products = snapshot.data ?? [];

                return Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Autocomplete for Item Name
                      Autocomplete<Product>(
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable.empty();
                          }
                          return products.where(
                            (p) => p.name.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          );
                        },
                        displayStringForOption: (option) => option.name,
                        onSelected: (option) {
                          nameCtrl.text = option.name;
                          selectedItemId = option.id;
                          // Auto-fill Purchase Price if available
                          if (option.costPrice > 0) {
                            rateCtrl.text = option.costPrice.toString();
                          }
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              textEditingController.addListener(() {
                                nameCtrl.text = textEditingController.text;
                              });
                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                decoration: _inputDecoration(
                                  "Search Item Name",
                                  isDark,
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? "Required" : null,
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : Colors.white,
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 300,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(
                                        option.name,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Stock: ${option.stockQuantity}',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // MODE SWITCHER: Simple vs Matrix
                      StatefulBuilder(
                        builder: (context, setSheetState) {
                          bool isMatrixMode = false;

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: isMatrixMode,
                                    onChanged: (v) =>
                                        setSheetState(() => isMatrixMode = v!),
                                  ),
                                  Text(
                                    "Add as Variants (Matrix)",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              if (isMatrixMode)
                                VariantMatrixSelection(
                                  sizes: const ['S', 'M', 'L', 'XL'],
                                  colors: const [
                                    'Red',
                                    'Blue',
                                    'Black',
                                    'White',
                                  ],
                                  initialQuantities: const {},
                                  onChanged: (matrix) {
                                    qtyCtrl.text = jsonEncode(matrix);
                                  },
                                  // isDark: isDark, // Assuming widget supports it or adapts
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: qtyCtrl,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        decoration: _inputDecoration(
                                          "Quantity",
                                          isDark,
                                        ),
                                        validator: (v) =>
                                            v!.isEmpty ? "Required" : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: rateCtrl,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        decoration: _inputDecoration(
                                          "Rate (₹)",
                                          isDark,
                                        ),
                                        validator: (v) =>
                                            v!.isEmpty ? "Required" : null,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final rate = double.tryParse(rateCtrl.text) ?? 0.0;
                  final matrixJson = qtyCtrl.text;

                  bool isMatrix = matrixJson.startsWith('{');

                  if (isMatrix) {
                    // Add Multiple Items
                    final matrix = Map<String, double>.from(
                      jsonDecode(matrixJson),
                    );

                    matrix.forEach((key, qty) {
                      final parts = key.split('-');
                      final size = parts[0];
                      final color = parts[1];

                      // Unique Item Name and ID for Variant
                      final varName = "${nameCtrl.text} - $size $color";
                      final varId =
                          "${nameCtrl.text.toLowerCase().replaceAll(' ', '_')}_${size}_$color";

                      final newItem = StockEntryItem(
                        lineId:
                            DateTime.now().microsecondsSinceEpoch.toString() +
                            key,
                        entryId: '',
                        itemId: varId,
                        name: varName,
                        quantity: qty,
                        rate: rate,
                        taxPercent: 0,
                        total: qty * rate,
                      );
                      setState(() => _items.add(newItem));
                    });
                  } else {
                    // Simple Add
                    final qty = double.parse(qtyCtrl.text);

                    final finalItemId =
                        selectedItemId ??
                        nameCtrl.text.toLowerCase().replaceAll(' ', '_');

                    final newItem = StockEntryItem(
                      lineId: DateTime.now().microsecondsSinceEpoch.toString(),
                      entryId: '',
                      itemId: finalItemId,
                      name: nameCtrl.text,
                      quantity: qty,
                      rate: rate,
                      taxPercent: 0,
                      total: qty * rate,
                    );
                    setState(() => _items.add(newItem));
                  }
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "ADD ITEM",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey[300]!,
        ),
      ),
    );
  }

  Future<void> _saveEntry(bool isDark) async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Add at least one item")));
      return;
    }
    if (_vendorCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vendor name required")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final ownerId = _session.ownerId;
      if (ownerId == null) throw Exception("User not logged in");

      final txnId = DateTime.now().millisecondsSinceEpoch.toString();

      // Construct Transaction
      String vendorId = _selectedVendorId ?? '';

      // Auto-create Vendor if new (Vyapar Feature)
      if (vendorId.isEmpty) {
        vendorId = 'v_${DateTime.now().millisecondsSinceEpoch}';
        final newVendor = {
          'vendorId': vendorId,
          'ownerId': ownerId,
          'name': _vendorCtrl.text,
          'phone': '',
          'email': '',
          'address': '',
          'gstin': '',
        };
        await _buyFlowService.saveVendor(newVendor);
      }

      // Construct Stock Entry
      final entry = StockEntry(
        entryId: txnId,
        ownerId: ownerId,
        vendorId: vendorId,
        invoiceNumber: _invoiceCtrl.text.isEmpty ? 'NA' : _invoiceCtrl.text,
        invoiceDate: _invoiceDate,
        totalAmount: _totalAmount,
        paidAmount: _paidAmount,
        dueAmount: _dueAmount,
        paymentStatus: _paymentStatus,
        createdAt: DateTime.now(),
      );

      // Link Items
      final finalItems = _items
          .map(
            (e) => StockEntryItem(
              lineId: e.lineId,
              entryId: txnId,
              itemId: e.itemId,
              name: e.name,
              quantity: e.quantity,
              rate: e.rate,
              total: e.total,
            ),
          )
          .toList();

      // Atomic Save via BuyFlowService
      await _buyFlowService.createStockEntry(entry, finalItems);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Stock Entry Saved!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeStateProvider);
    final isDark = theme.isDark;

    return DesktopContentContainer(
      title: "Stock Entry",
      actions: [
        if (_items.isNotEmpty)
          ElevatedButton(
            onPressed: _isLoading ? null : () => _saveEntry(isDark),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text("SAVE ENTRY"),
          ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Details (40%)
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Vendor Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _vendorCtrl,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: _inputDecoration("Vendor Name", isDark),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _invoiceCtrl,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: _inputDecoration(
                                "Invoice No",
                                isDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _invoiceDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (d != null) setState(() => _invoiceDate = d);
                              },
                              child: Container(
                                height: 60,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd MMM').format(_invoiceDate),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Payment Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Payment Info",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _paidAmountCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: _inputDecoration("Paid Amount (₹)", isDark),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildBalanceChip(
                            "Total",
                            "₹${_totalAmount.toStringAsFixed(0)}",
                            Colors.blue,
                            isDark,
                          ),
                          const SizedBox(width: 12),
                          _buildBalanceChip(
                            "Due",
                            "₹${_dueAmount.toStringAsFixed(0)}",
                            Colors.redAccent,
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Column: Items (60%)
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Stock Items",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddItemDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Add Item"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No items added",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  "${item.quantity} x ₹${item.rate}",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey[600],
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "₹${item.total.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => setState(
                                        () => _items.removeAt(index),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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

  Widget _buildBalanceChip(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
