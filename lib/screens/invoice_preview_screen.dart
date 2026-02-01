import 'package:flutter/material.dart';
import '../core/theme/futuristic_colors.dart';
import '../models/invoice_editable.dart';

/// Professional Invoice Preview & Export Screen
/// - Beautiful, colorful invoice layout
/// - Matches handwritten screenshot style
/// - PDF export ready
/// - Print-friendly format
/// - Signature & stamp display

class InvoicePreviewScreen extends StatefulWidget {
  final EditableInvoice invoice;
  final VoidCallback? onEdit;
  final VoidCallback? onExportPDF;
  final VoidCallback? onPrint;

  const InvoicePreviewScreen({
    super.key,
    required this.invoice,
    this.onEdit,
    this.onExportPDF,
    this.onPrint,
  });

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  bool _showOptions = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => setState(() => _showOptions = !_showOptions),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Action buttons
            if (_showOptions) _buildActionBar(),

            // Invoice content
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              child: _buildInvoiceContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      color: Colors.blue[50],
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.edit, 'Edit', widget.onEdit),
          _buildActionButton(Icons.picture_as_pdf, 'PDF', widget.onExportPDF),
          _buildActionButton(Icons.print, 'Print', widget.onPrint),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInvoiceContent() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with colorful border
          _buildHeader(),
          const SizedBox(height: 24),

          // Invoice number and date
          _buildInvoiceInfo(),
          const SizedBox(height: 20),

          // Customer details
          _buildCustomerDetails(),
          const SizedBox(height: 20),

          // Items table
          _buildItemsTable(),
          const SizedBox(height: 20),

          // Charges table
          _buildChargesTable(),
          const SizedBox(height: 20),

          // Totals
          _buildTotalsSection(),
          const SizedBox(height: 20),

          // Signature & Stamp
          _buildSignatureSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: FuturisticColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: FuturisticColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.invoice.shopName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'स्वामी: ${widget.invoice.ownerName}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'सब्जी व फूड चे कमिशन एजन्ट',
            style: TextStyle(color: Colors.amber[100], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          Text(
            '📞 ${widget.invoice.ownerPhone}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            '📍 ${widget.invoice.ownerAddress}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (widget.invoice.gstNumber != null &&
              widget.invoice.gstNumber!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'GST: ${widget.invoice.gstNumber}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInvoiceInfo() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Customer name appears before invoice number as requested
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ग्राहकाचे नाव',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.invoice.customerName,
                  style: const TextStyle(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 8),
              const Text('बिल क्रमांक',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.invoice.invoiceNumber,
                  style: const TextStyle(fontSize: 16, color: Colors.blue)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('तारीख',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.invoice.formattedDate,
                  style: const TextStyle(fontSize: 16, color: Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetails() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange[300]!, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.orange[50],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'खरेदीदारचे तपशील',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'नाव: ${widget.invoice.customerName}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'गाव: ${widget.invoice.customerVillage}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'वेळ: ${widget.invoice.formattedTime}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    if (widget.invoice.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('No items in this invoice'),
      );
    }

    return Column(
      children: [
        // Table header
        Container(
          decoration: BoxDecoration(
            color: Colors.blue[600],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildHeaderText('मालाचा विवरण'),
              ),
              Expanded(
                flex: 1,
                child: _buildHeaderText('मन'),
              ),
              Expanded(
                flex: 2,
                child: _buildHeaderText('किलो'),
              ),
              Expanded(
                flex: 2,
                child: _buildHeaderText('भाव'),
              ),
              Expanded(
                flex: 2,
                child: _buildHeaderText('एकूण'),
              ),
            ],
          ),
        ),

        // Table rows
        ...List.generate(widget.invoice.items.length, (index) {
          final item = widget.invoice.items[index];
          final isAlternate = index % 2 == 0;

          return Container(
            color: isAlternate ? Colors.blue[50] : Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.itemName,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    item.manQuantity?.toStringAsFixed(2) ?? '-',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    item.kiloWeight.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${item.ratePerKilo.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${item.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }),

        // Table footer
        Container(
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'मालाची एकूण: ₹${widget.invoice.getItemsTotal().toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildChargesTable() {
    if (widget.invoice.charges.getTotalCharges() == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.purple[50],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'खर्च',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.invoice.charges.okshanKharcha > 0)
            _buildChargeRow(
                'ऑक्शन / अड्डा खर्च', widget.invoice.charges.okshanKharcha),
          if (widget.invoice.charges.nagarpalika > 0)
            _buildChargeRow('नगरपालिका', widget.invoice.charges.nagarpalika),
          if (widget.invoice.charges.commission > 0)
            _buildChargeRow('कमिशन', widget.invoice.charges.commission),
          if (widget.invoice.charges.hamali > 0)
            _buildChargeRow('हमाली', widget.invoice.charges.hamali),
          if (widget.invoice.charges.vetChithi > 0)
            _buildChargeRow('व. चिठ्ठी', widget.invoice.charges.vetChithi),
          if (widget.invoice.charges.gadiKhada > 0)
            _buildChargeRow('गाडी भाडा', widget.invoice.charges.gadiKhada),
        ],
      ),
    );
  }

  Widget _buildChargeRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    final itemsTotal = widget.invoice.getItemsTotal();
    final chargesTotal = widget.invoice.charges.getTotalCharges();
    final finalTotal = widget.invoice.getFinalTotal();

    return Container(
      decoration: BoxDecoration(
        gradient: FuturisticColors.primaryGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTotalRow('मालाची एकूण', itemsTotal),
          const Divider(color: Colors.white30),
          _buildTotalRow('खर्च एकूण', chargesTotal),
          Container(
            height: 2,
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          _buildTotalRow(
            'अंतिम एकूण',
            finalTotal,
            isBold: true,
            isLarge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount,
      {bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isLarge ? 16 : 13,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isLarge ? 18 : 13,
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (widget.invoice.ownerSignatureUrl != null &&
            widget.invoice.ownerSignatureUrl!.isNotEmpty)
          Column(
            children: [
              Container(
                width: 100,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.invoice.ownerSignatureUrl!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('स्वाक्षर', style: TextStyle(fontSize: 11)),
            ],
          ),
        if (widget.invoice.stampUrl != null &&
            widget.invoice.stampUrl!.isNotEmpty)
          Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.invoice.stampUrl!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('दुकानदारचे छाप', style: TextStyle(fontSize: 11)),
            ],
          ),
      ],
    );
  }
}
