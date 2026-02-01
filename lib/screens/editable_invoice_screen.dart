import 'package:flutter/material.dart';
import '../models/invoice_editable.dart';
import 'package:uuid/uuid.dart';

/// Comprehensive Editable Invoice Screen
/// - Owner details at top (with colors)
/// - Customer details
/// - Editable items table
/// - Editable charges section
/// - Auto-calculation
/// - Signature & stamp upload
/// - PDF export

class EditableInvoiceScreen extends StatefulWidget {
  final EditableInvoice? initialInvoice;
  final String ownerName;
  final String shopName;
  final String ownerPhone;
  final String ownerAddress;

  const EditableInvoiceScreen({
    super.key,
    this.initialInvoice,
    required this.ownerName,
    required this.shopName,
    required this.ownerPhone,
    required this.ownerAddress,
  });

  @override
  State<EditableInvoiceScreen> createState() => _EditableInvoiceScreenState();
}

class _EditableInvoiceScreenState extends State<EditableInvoiceScreen> {
  late EditableInvoice _invoice;
  late TextEditingController _customerNameCtrl;
  late TextEditingController _customerVillageCtrl;
  late TextEditingController _notesCtrl;

  final List<TextEditingController> _itemNameCtrls = [];
  final List<TextEditingController> _itemManQtyCtrls = [];
  final List<TextEditingController> _itemKiloCtrls = [];
  final List<TextEditingController> _itemRatePerKiloCtrls = [];
  final List<TextEditingController> _itemManRateCtrls = [];

  late TextEditingController _okshanCtrl;
  late TextEditingController _nagarpalikaCtrl;
  late TextEditingController _commissionCtrl;
  late TextEditingController _hamaliCtrl;
  late TextEditingController _vetChithiCtrl;
  late TextEditingController _gadiKhadaCtrl;

  @override
  void initState() {
    super.initState();
    _initializeInvoice();
    _initializeControllers();
  }

  void _initializeInvoice() {
    _invoice = widget.initialInvoice ??
        EditableInvoice.empty(
          ownerName: widget.ownerName,
          shopName: widget.shopName,
          ownerPhone: widget.ownerPhone,
          ownerAddress: widget.ownerAddress,
        );
  }

  void _initializeControllers() {
    _customerNameCtrl = TextEditingController(text: _invoice.customerName);
    _customerVillageCtrl =
        TextEditingController(text: _invoice.customerVillage);
    _notesCtrl = TextEditingController(text: _invoice.notes);

    // Items
    for (final item in _invoice.items) {
      _itemNameCtrls.add(TextEditingController(text: item.itemName));
      _itemManQtyCtrls
          .add(TextEditingController(text: item.manQuantity?.toString() ?? ''));
      _itemKiloCtrls
          .add(TextEditingController(text: item.kiloWeight.toStringAsFixed(2)));
      _itemRatePerKiloCtrls.add(
          TextEditingController(text: item.ratePerKilo.toStringAsFixed(2)));
      _itemManRateCtrls
          .add(TextEditingController(text: item.manRate?.toString() ?? ''));
    }

    // Charges
    _okshanCtrl = TextEditingController(
        text: _invoice.charges.okshanKharcha.toStringAsFixed(2));
    _nagarpalikaCtrl = TextEditingController(
        text: _invoice.charges.nagarpalika.toStringAsFixed(2));
    _commissionCtrl = TextEditingController(
        text: _invoice.charges.commission.toStringAsFixed(2));
    _hamaliCtrl =
        TextEditingController(text: _invoice.charges.hamali.toStringAsFixed(2));
    _vetChithiCtrl = TextEditingController(
        text: _invoice.charges.vetChithi.toStringAsFixed(2));
    _gadiKhadaCtrl = TextEditingController(
        text: _invoice.charges.gadiKhada.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerVillageCtrl.dispose();
    _notesCtrl.dispose();
    for (var ctrl in _itemNameCtrls) {
      ctrl.dispose();
    }
    for (var ctrl in _itemManQtyCtrls) {
      ctrl.dispose();
    }
    for (var ctrl in _itemKiloCtrls) {
      ctrl.dispose();
    }
    for (var ctrl in _itemRatePerKiloCtrls) {
      ctrl.dispose();
    }
    for (var ctrl in _itemManRateCtrls) {
      ctrl.dispose();
    }
    _okshanCtrl.dispose();
    _nagarpalikaCtrl.dispose();
    _commissionCtrl.dispose();
    _hamaliCtrl.dispose();
    _vetChithiCtrl.dispose();
    _gadiKhadaCtrl.dispose();
    super.dispose();
  }

  void _updateInvoiceFromControllers() {
    _invoice.customerName = _customerNameCtrl.text;
    _invoice.customerVillage = _customerVillageCtrl.text;
    _invoice.notes = _notesCtrl.text;

    _invoice.charges.okshanKharcha = double.tryParse(_okshanCtrl.text) ?? 0;
    _invoice.charges.nagarpalika = double.tryParse(_nagarpalikaCtrl.text) ?? 0;
    _invoice.charges.commission = double.tryParse(_commissionCtrl.text) ?? 0;
    _invoice.charges.hamali = double.tryParse(_hamaliCtrl.text) ?? 0;
    _invoice.charges.vetChithi = double.tryParse(_vetChithiCtrl.text) ?? 0;
    _invoice.charges.gadiKhada = double.tryParse(_gadiKhadaCtrl.text) ?? 0;

    _invoice.items.clear();
    for (int i = 0; i < _itemNameCtrls.length; i++) {
      final kiloWeight = double.tryParse(_itemKiloCtrls[i].text) ?? 0;
      final ratePerKilo = double.tryParse(_itemRatePerKiloCtrls[i].text) ?? 0;
      final manQty = double.tryParse(_itemManQtyCtrls[i].text);
      final manRate = double.tryParse(_itemManRateCtrls[i].text);

      double total = kiloWeight * ratePerKilo;
      if (manQty != null && manRate != null) {
        total += manQty * manRate;
      }

      _invoice.items.add(
        EditableInvoiceItem(
          id: const Uuid().v4(),
          itemName: _itemNameCtrls[i].text,
          manQuantity: manQty,
          kiloWeight: kiloWeight,
          ratePerKilo: ratePerKilo,
          manRate: manRate,
          totalAmount: total,
        ),
      );
    }
  }

  void _addItemRow() {
    setState(() {
      _itemNameCtrls.add(TextEditingController());
      _itemManQtyCtrls.add(TextEditingController());
      _itemKiloCtrls.add(TextEditingController());
      _itemRatePerKiloCtrls.add(TextEditingController());
      _itemManRateCtrls.add(TextEditingController());
    });
  }

  void _removeItemRow(int index) {
    if (_itemNameCtrls.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one item required')),
      );
      return;
    }

    setState(() {
      _itemNameCtrls[index].dispose();
      _itemManQtyCtrls[index].dispose();
      _itemKiloCtrls[index].dispose();
      _itemRatePerKiloCtrls[index].dispose();
      _itemManRateCtrls[index].dispose();

      _itemNameCtrls.removeAt(index);
      _itemManQtyCtrls.removeAt(index);
      _itemKiloCtrls.removeAt(index);
      _itemRatePerKiloCtrls.removeAt(index);
      _itemManRateCtrls.removeAt(index);
    });
  }

  double _calculateItemTotal(int index) {
    final kilo = double.tryParse(_itemKiloCtrls[index].text) ?? 0;
    final rate = double.tryParse(_itemRatePerKiloCtrls[index].text) ?? 0;
    final manQty = double.tryParse(_itemManQtyCtrls[index].text);
    final manRate = double.tryParse(_itemManRateCtrls[index].text);

    double total = kilo * rate;
    if (manQty != null && manRate != null) {
      total += manQty * manRate;
    }
    return total;
  }

  double _getItemsGrandTotal() {
    double total = 0;
    for (int i = 0; i < _itemNameCtrls.length; i++) {
      total += _calculateItemTotal(i);
    }
    return total;
  }

  double _getChargesTotal() {
    return (double.tryParse(_okshanCtrl.text) ?? 0) +
        (double.tryParse(_nagarpalikaCtrl.text) ?? 0) +
        (double.tryParse(_commissionCtrl.text) ?? 0) +
        (double.tryParse(_hamaliCtrl.text) ?? 0) +
        (double.tryParse(_vetChithiCtrl.text) ?? 0) +
        (double.tryParse(_gadiKhadaCtrl.text) ?? 0);
  }

  double _getFinalTotal() {
    return _getItemsGrandTotal() + _getChargesTotal();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: () {
              _updateInvoiceFromControllers();
              Navigator.pop(context, _invoice);
            },
            tooltip: 'Save Invoice',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Owner Details Header
            _buildOwnerDetailsCard(),
            const SizedBox(height: 16),

            // Customer Details
            _buildCustomerDetailsCard(),
            const SizedBox(height: 16),

            // Items Table
            _buildItemsTableCard(),
            const SizedBox(height: 16),

            // Charges Section
            _buildChargesCard(),
            const SizedBox(height: 16),

            // Totals
            _buildTotalsCard(),
            const SizedBox(height: 16),

            // Notes
            _buildNotesCard(),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _updateInvoiceFromControllers();
                      Navigator.pop(context, _invoice);
                    },
                    child: const Text('Save & Exit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerDetailsCard() {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[700]!, Colors.green[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _invoice.shopName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _invoice.ownerName,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            Text(
              'मो: ${_invoice.ownerPhone}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              _invoice.ownerAddress,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'खरेदीदार तपशील',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customerNameCtrl,
              decoration: const InputDecoration(
                labelText: 'ग्राहक नाव',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customerVillageCtrl,
              decoration: const InputDecoration(
                labelText: 'गाव / शहर',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'तारीख',
                      border: const OutlineInputBorder(),
                      hintText: _invoice.formattedDate,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'बिल क्रमांक',
                      border: const OutlineInputBorder(),
                      hintText: _invoice.invoiceNumber,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTableCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'मालाचा तपशील',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addItemRow,
                  icon: const Icon(Icons.add),
                  label: const Text('मालाची पंक्ति'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('मालाचा विवरण')),
                  DataColumn(label: Text('मन')),
                  DataColumn(label: Text('किलो')),
                  DataColumn(label: Text('भाव')),
                  DataColumn(label: Text('रुपये')),
                  DataColumn(label: Text('एकूण')),
                  DataColumn(label: Text('क्रिया')),
                ],
                rows: List.generate(_itemNameCtrls.length, (index) {
                  return DataRow(cells: [
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _itemNameCtrls[index],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _itemManQtyCtrls[index],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _itemKiloCtrls[index],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _itemRatePerKiloCtrls[index],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _itemManRateCtrls[index],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '₹${_calculateItemTotal(index).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeItemRow(index),
                        iconSize: 18,
                      ),
                    ),
                  ]);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'खर्च',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildChargeRow('ऑक्शन / अड्डा खर्च', _okshanCtrl),
            _buildChargeRow('नगरपालिका', _nagarpalikaCtrl),
            _buildChargeRow('कमिशन', _commissionCtrl),
            _buildChargeRow('हमाली', _hamaliCtrl),
            _buildChargeRow('व. चिठ्ठी', _vetChithiCtrl),
            _buildChargeRow('गाडी भाडा', _gadiKhadaCtrl),
          ],
        ),
      ),
    );
  }

  Widget _buildChargeRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                prefix: Text('₹'),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
    final itemsTotal = _getItemsGrandTotal();
    final chargesTotal = _getChargesTotal();
    final finalTotal = _getFinalTotal();

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('मालाची एकूण', itemsTotal),
            const Divider(),
            _buildTotalRow('खर्च एकूण', chargesTotal),
            const Divider(thickness: 2),
            _buildTotalRow(
              'अंतिम एकूण',
              finalTotal,
              isBold: true,
              isLarge: true,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount,
      {bool isBold = false, bool isLarge = false, Color color = Colors.black}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isLarge ? 16 : 14,
            color: color,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isLarge ? 16 : 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'अतिरिक्त नोट्स',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'कोणतेही अतिरिक्त नोट्स टाइप करा...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
