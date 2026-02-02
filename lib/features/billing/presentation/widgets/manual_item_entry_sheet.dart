// ============================================================================
// MANUAL ITEM ENTRY SHEET - BUSINESS AWARE & DYNAMIC
// ============================================================================
// Allows manual item entry with strict business-type validation
//
// Author: DukanX Engineering
// Version: 2.0.0
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/futuristic_colors.dart';
import '../../../../models/bill.dart';
import '../../../../models/business_type.dart';
import '../../../../widgets/glass_bottom_sheet.dart';

/// Manual Item Entry Sheet
///
/// Provides a form for entering items manually with dynamic fields
/// based on the selected Business Type.
class ManualItemEntrySheet extends StatefulWidget {
  final Function(BillItem) onItemAdded;
  final BusinessType businessType;
  final String? defaultUnit;
  final double? defaultGstRate;

  const ManualItemEntrySheet({
    super.key,
    required this.onItemAdded,
    required this.businessType,
    this.defaultUnit,
    this.defaultGstRate,
  });

  @override
  State<ManualItemEntrySheet> createState() => _ManualItemEntrySheetState();
}

class _ManualItemEntrySheetState extends State<ManualItemEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _rateController = TextEditingController();
  final _gstController = TextEditingController();
  final _hsnController = TextEditingController();
  final _discountController = TextEditingController(text: '0');

  // Business Specific Controllers
  final _batchController = TextEditingController(); // Pharmacy
  final _expiryController = TextEditingController(); // Pharmacy
  DateTime? _selectedExpiryDate;

  final _serialController = TextEditingController(); // Electronics
  final _warrantyController = TextEditingController(); // Electronics

  final _sizeController = TextEditingController(); // Clothing/Hardware
  final _colorController = TextEditingController(); // Clothing

  String _selectedUnit = 'pcs';
  bool _isLoading = false;

  final List<String> _units = [
    'pcs',
    'kg',
    'g',
    'l',
    'ml',
    'box',
    'pack',
    'dozen',
    'meter',
    'sq.ft',
    'hour',
    'service',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.defaultUnit != null && _units.contains(widget.defaultUnit)) {
      _selectedUnit = widget.defaultUnit!;
    }
    if (widget.defaultGstRate != null) {
      _gstController.text = widget.defaultGstRate!.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _rateController.dispose();
    _gstController.dispose();
    _hsnController.dispose();
    _discountController.dispose();
    _batchController.dispose();
    _expiryController.dispose();
    _serialController.dispose();
    _warrantyController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: now, // Cannot sell expired items manually
      lastDate: now.add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
        _expiryController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final qty = double.tryParse(_qtyController.text) ?? 1;
      final rate = double.tryParse(_rateController.text) ?? 0;
      final gstRate = double.tryParse(_gstController.text) ?? 0;
      final discount = double.tryParse(_discountController.text) ?? 0;
      final hsn = _hsnController.text.trim();

      // Calculate GST amounts
      final taxableAmount = (qty * rate) - discount;
      final gstAmount = taxableAmount * (gstRate / 100);
      final cgst = gstAmount / 2;
      final sgst = gstAmount / 2;

      // Basic Item
      BillItem item = BillItem(
        productId: '', // Empty ID indicates manual entry
        productName: name,
        qty: qty,
        price: rate,
        unit: _selectedUnit,
        hsn: hsn,
        gstRate: gstRate,
        discount: discount,
        cgst: cgst,
        sgst: sgst,
      );

      // Inject Business Specific Data
      if (widget.businessType == BusinessType.pharmacy) {
        item = item.copyWith(
          batchNo: _batchController.text.trim(),
          expiryDate: _selectedExpiryDate,
        );
      } else if (widget.businessType == BusinessType.electronics ||
          widget.businessType == BusinessType.mobileShop ||
          widget.businessType == BusinessType.computerShop) {
        int? warranty;
        if (_warrantyController.text.isNotEmpty) {
          warranty = int.tryParse(_warrantyController.text);
        }
        item = item.copyWith(
          serialNo: _serialController.text.trim(),
          warrantyMonths: warranty,
        );
      } else if (widget.businessType == BusinessType.clothing) {
        item = item.copyWith(
          size: _sizeController.text.trim(),
          color: _colorController.text.trim(),
        );
      } else if (widget.businessType == BusinessType.hardware) {
        item = item.copyWith(size: _sizeController.text.trim());
      }

      widget.onItemAdded(item);
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassBottomSheet(
      title: 'Manual Item Entry',
      subtitle: widget.businessType.displayName,
      icon: Icons.edit_note,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Product/Service Name
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _buildInputDecoration(
                  'Item Name',
                  Icons.shopping_bag_outlined,
                  isDark,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // === DYNAMIC BUSINESS FIELDS START ===
              if (widget.businessType == BusinessType.pharmacy) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _batchController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: _buildInputDecoration(
                          'Batch No',
                          Icons.qr_code_2,
                          isDark,
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickExpiryDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _expiryController,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: _buildInputDecoration(
                              'Expiry Date',
                              Icons.calendar_today,
                              isDark,
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (widget.businessType == BusinessType.electronics ||
                  widget.businessType == BusinessType.mobileShop ||
                  widget.businessType == BusinessType.computerShop) ...[
                TextFormField(
                  controller: _serialController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: _buildInputDecoration(
                    'Serial No / IMEI',
                    Icons.tag,
                    isDark,
                    hint: 'Scan or enter serial number',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _warrantyController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: _buildInputDecoration(
                    'Warranty (Months)',
                    Icons.verified_user_outlined,
                    isDark,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (widget.businessType == BusinessType.clothing) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sizeController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: _buildInputDecoration(
                          'Size',
                          Icons.straighten,
                          isDark,
                          hint: 'S, M, L, XL...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _colorController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: _buildInputDecoration(
                          'Color',
                          Icons.palette_outlined,
                          isDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (widget.businessType == BusinessType.hardware) ...[
                TextFormField(
                  controller: _sizeController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: _buildInputDecoration(
                    'Size / Dimensions',
                    Icons.straighten,
                    isDark,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // === DYNAMIC BUSINESS FIELDS END ===

              // Quantity & Unit Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: _buildInputDecoration(
                        'Quantity',
                        Icons.numbers,
                        isDark,
                      ),
                      validator: (v) {
                        final qty = double.tryParse(v ?? '');
                        if (qty == null || qty <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      dropdownColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: _buildInputDecoration('Unit', null, isDark),
                      items: _units
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedUnit = v ?? 'pcs'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rate
              TextFormField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _buildInputDecoration(
                  'Rate (₹)',
                  Icons.currency_rupee,
                  isDark,
                ),
                validator: (v) {
                  final rate = double.tryParse(v ?? '');
                  if (rate == null || rate < 0) return 'Invalid rate';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // GST % & Discount Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _gstController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: _buildInputDecoration(
                        'GST %',
                        Icons.receipt_long_outlined,
                        isDark,
                        hint: 'Optional',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: _buildInputDecoration(
                        'Discount (₹)',
                        Icons.local_offer_outlined,
                        isDark,
                        hint: 'Optional',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // HSN Code (Optional)
              TextFormField(
                controller: _hsnController,
                keyboardType: TextInputType.text,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _buildInputDecoration(
                  'HSN Code',
                  Icons.qr_code,
                  isDark,
                  hint: 'Optional',
                ),
              ),
              const SizedBox(height: 24),

              // Live Preview
              _buildLivePreview(isDark),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: FuturisticColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: FuturisticColors.primary.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline),
                              SizedBox(width: 8),
                              Text(
                                'Add to Bill',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    IconData? icon,
    bool isDark, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: FuturisticColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildLivePreview(bool isDark) {
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final gstRate = double.tryParse(_gstController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;

    final subtotal = qty * rate;
    final afterDiscount = subtotal - discount;
    final gstAmount = afterDiscount * (gstRate / 100);
    final total = afterDiscount + gstAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? FuturisticColors.primary.withOpacity(0.1)
            : FuturisticColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FuturisticColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                '₹${subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          if (discount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount',
                  style: TextStyle(
                    color: FuturisticColors.success,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '-₹${discount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: FuturisticColors.success,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          if (gstRate > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GST ($gstRate%)',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '+₹${gstAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item Total',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: FuturisticColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
