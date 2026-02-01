// Professional Invoice PDF Generator for Indian Businesses
// Vyapar-level quality, multi-language support, signature integration
//
// Created: 2024-12-25
// Author: DukanX Team

// import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';

/// Supported Indian languages for invoice generation
enum InvoiceLanguage {
  english,
  hindi,
  marathi,
  gujarati,
  tamil,
  telugu,
  kannada,
  bengali,
  punjabi,
  malayalam,
  urdu,
  odia,
  assamese,
}

/// Invoice configuration containing shop and styling details
class InvoiceConfig {
  final String shopName;
  final String ownerName;
  final String address;
  final String mobile;
  final String? gstin;
  final String? email;
  final Uint8List? logoImage;
  final Uint8List? avatarImage;
  final Uint8List? signatureImage;
  final InvoiceLanguage language;
  final bool showTax;
  final bool isGstBill;

  InvoiceConfig({
    required this.shopName,
    required this.ownerName,
    required this.address,
    required this.mobile,
    this.gstin,
    this.email,
    this.logoImage,
    this.avatarImage,
    this.signatureImage,
    this.language = InvoiceLanguage.english,
    this.showTax = false,
    this.isGstBill = false,
  });
}

/// Customer details for the invoice
class InvoiceCustomer {
  final String name;
  final String mobile;
  final String? address;
  final String? gstin;

  InvoiceCustomer({
    required this.name,
    required this.mobile,
    this.address,
    this.gstin,
  });
}

/// Individual line item in the invoice
class InvoiceItem {
  final String name;
  final String? description;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double? discountPercent;
  final double? taxPercent;

  InvoiceItem({
    required this.name,
    this.description,
    required this.quantity,
    this.unit = 'pcs',
    required this.unitPrice,
    this.discountPercent,
    this.taxPercent,
  });

  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * (discountPercent ?? 0) / 100;
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * (taxPercent ?? 0) / 100;
  double get total => taxableAmount + taxAmount;
}

/// Main Invoice PDF Service
class InvoicePdfService {
  static final InvoicePdfService _instance = InvoicePdfService._internal();
  factory InvoicePdfService() => _instance;
  InvoicePdfService._internal();

  // Professional blue theme colors
  static const PdfColor primaryBlue = PdfColor.fromInt(0xFF1E3A8A);
  static const PdfColor lightBlue = PdfColor.fromInt(0xFFDBEAFE);
  static const PdfColor darkBlue = PdfColor.fromInt(0xFF1E40AF);
  static const PdfColor textDark = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor textGray = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor borderGray = PdfColor.fromInt(0xFFE5E7EB);

  // Currency formatter
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Generate professional invoice PDF
  Future<Uint8List> generateInvoicePdf({
    required InvoiceConfig config,
    required InvoiceCustomer customer,
    required List<InvoiceItem> items,
    required String invoiceNumber,
    required DateTime invoiceDate,
    DateTime? dueDate,
    double? discount,
    String? notes,
    String? termsAndConditions,
  }) async {
    // Load fonts
    final regularFont = await _loadFont('assets/fonts/NotoSans-Regular.ttf');
    final boldFont = await _loadFont('assets/fonts/NotoSans-Bold.ttf');

    // Use default fonts if custom fonts not available
    pw.Font baseFont = pw.Font.helvetica();
    pw.Font baseBoldFont = pw.Font.helveticaBold();

    if (regularFont != null) baseFont = regularFont;
    if (boldFont != null) baseBoldFont = boldFont;

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: baseFont,
        bold: baseBoldFont,
      ),
    );

    // Calculate totals
    double subtotal = items.fold(0, (sum, item) => sum + item.subtotal);
    double totalDiscount =
        items.fold(0, (sum, item) => sum + item.discountAmount);
    if (discount != null) totalDiscount += discount;
    double taxableAmount = subtotal - totalDiscount;
    double totalTax = items.fold(0, (sum, item) => sum + item.taxAmount);
    double grandTotal = taxableAmount + totalTax;

    // Get translated labels
    final labels = _getLabels(config.language);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ===== HEADER SECTION =====
              _buildHeader(config, labels),
              pw.SizedBox(height: 8),
              pw.Divider(color: primaryBlue, thickness: 2),
              pw.SizedBox(height: 20),

              // ===== INVOICE INFO + CUSTOMER =====
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left: Customer Details
                  pw.Expanded(
                    flex: 3,
                    child: _buildCustomerSection(customer, labels),
                  ),
                  // Right: Invoice Details
                  pw.Expanded(
                    flex: 2,
                    child: _buildInvoiceInfo(invoiceNumber, invoiceDate,
                        dueDate, labels, config.isGstBill),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // ===== ITEMS TABLE =====
              _buildItemsTable(items, labels, config.showTax),
              pw.SizedBox(height: 16),

              // ===== TOTALS SECTION =====
              _buildTotalsSection(
                subtotal: subtotal,
                discount: totalDiscount,
                taxableAmount: taxableAmount,
                totalTax: totalTax,
                grandTotal: grandTotal,
                labels: labels,
                showTax: config.showTax,
              ),
              pw.SizedBox(height: 16),

              // ===== AMOUNT IN WORDS =====
              _buildAmountInWords(grandTotal, labels),
              pw.SizedBox(height: 24),

              // ===== NOTES / TERMS =====
              if (notes != null || termsAndConditions != null)
                _buildNotesSection(notes, termsAndConditions, labels),

              pw.Spacer(),

              // ===== SIGNATURE SECTION =====
              _buildSignatureSection(config.signatureImage, labels),
              pw.SizedBox(height: 16),

              // ===== FOOTER =====
              _buildFooter(labels),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Build header with shop details
  pw.Widget _buildHeader(InvoiceConfig config, Map<String, String> labels) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Shop Logo (if available)
        if (config.logoImage != null)
          pw.Container(
            height: 60,
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Image(pw.MemoryImage(config.logoImage!),
                fit: pw.BoxFit.contain),
          ),

        // Avatar (if available) - Professional circular look next to shop name
        if (config.avatarImage != null)
          pw.Container(
            height: 40,
            width: 40,
            margin: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: primaryBlue, width: 1),
            ),
            child: pw.ClipOval(
              child: pw.Image(pw.MemoryImage(config.avatarImage!),
                  fit: pw.BoxFit.cover),
            ),
          ),

        // Shop Name
        pw.Text(
          config.shopName.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: primaryBlue,
            letterSpacing: 1.5,
          ),
        ),
        pw.SizedBox(height: 6),

        // Owner Name
        pw.Text(
          '${labels['proprietor']}: ${config.ownerName}',
          style: pw.TextStyle(
            fontSize: 11,
            color: textGray,
          ),
        ),
        pw.SizedBox(height: 4),

        // Address
        pw.Text(
          config.address,
          style: pw.TextStyle(fontSize: 10, color: textDark),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),

        // Contact Details
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              '${labels['mobile']}: ${config.mobile}',
              style: pw.TextStyle(fontSize: 10, color: textDark),
            ),
            if (config.email != null) ...[
              pw.Text('  |  ', style: pw.TextStyle(color: textGray)),
              pw.Text(
                '${labels['email']}: ${config.email}',
                style: pw.TextStyle(fontSize: 10, color: textDark),
              ),
            ],
          ],
        ),

        // GSTIN
        if (config.gstin != null && config.gstin!.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: pw.BoxDecoration(
              color: lightBlue,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'GSTIN: ${config.gstin}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build invoice info section (right side)
  pw.Widget _buildInvoiceInfo(
    String invoiceNumber,
    DateTime invoiceDate,
    DateTime? dueDate,
    Map<String, String> labels,
    bool isGstBill,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: lightBlue,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: primaryBlue, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Invoice Title
          pw.Text(
            isGstBill ? labels['taxInvoice']! : labels['invoice']!,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          pw.SizedBox(height: 12),

          // Invoice Number
          _buildInfoRow(labels['invoiceNo']!, invoiceNumber),
          pw.SizedBox(height: 6),

          // Invoice Date
          _buildInfoRow(labels['date']!, dateFormat.format(invoiceDate)),

          // Due Date (if applicable)
          if (dueDate != null) ...[
            pw.SizedBox(height: 6),
            _buildInfoRow(labels['dueDate']!, dateFormat.format(dueDate)),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(fontSize: 10, color: textGray),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: textDark,
          ),
        ),
      ],
    );
  }

  /// Build customer details section (left side)
  pw.Widget _buildCustomerSection(
      InvoiceCustomer customer, Map<String, String> labels) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderGray),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            labels['billedTo']!,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            customer.name,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: textDark,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${labels['mobile']}: ${customer.mobile}',
            style: pw.TextStyle(fontSize: 10, color: textDark),
          ),
          if (customer.address != null && customer.address!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              customer.address!,
              style: pw.TextStyle(fontSize: 10, color: textGray),
            ),
          ],
          if (customer.gstin != null && customer.gstin!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'GSTIN: ${customer.gstin}',
              style: pw.TextStyle(fontSize: 10, color: textDark),
            ),
          ],
        ],
      ),
    );
  }

  /// Build items table with professional styling
  pw.Widget _buildItemsTable(
      List<InvoiceItem> items, Map<String, String> labels, bool showTax) {
    final headers = [
      labels['slNo']!,
      labels['description']!,
      labels['qty']!,
      labels['unit']!,
      labels['rate']!,
      if (showTax) labels['tax']!,
      labels['amount']!,
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5), // Sl No
        1: const pw.FlexColumnWidth(3), // Description
        2: const pw.FlexColumnWidth(0.8), // Qty
        3: const pw.FlexColumnWidth(0.7), // Unit
        4: const pw.FlexColumnWidth(1.2), // Rate
        if (showTax) 5: const pw.FlexColumnWidth(0.8), // Tax
        showTax ? 6 : 5: const pw.FlexColumnWidth(1.2), // Amount
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryBlue),
          children: headers
              .map((h) => pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ))
              .toList(),
        ),

        // Data Rows
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : lightBlue,
            ),
            children: [
              _tableCell('${index + 1}', align: pw.Alignment.center),
              _tableCell(item.name, align: pw.Alignment.centerLeft),
              _tableCell(
                  item.quantity.toStringAsFixed(
                      item.quantity == item.quantity.roundToDouble() ? 0 : 2),
                  align: pw.Alignment.center),
              _tableCell(item.unit, align: pw.Alignment.center),
              _tableCell(_currencyFormat.format(item.unitPrice),
                  align: pw.Alignment.centerRight),
              if (showTax)
                _tableCell('${item.taxPercent?.toStringAsFixed(0) ?? '-'}%',
                    align: pw.Alignment.center),
              _tableCell(_currencyFormat.format(item.total),
                  align: pw.Alignment.centerRight, bold: true),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _tableCell(String text,
      {pw.Alignment align = pw.Alignment.center, bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textDark,
        ),
      ),
    );
  }

  /// Build totals section
  pw.Widget _buildTotalsSection({
    required double subtotal,
    required double discount,
    required double taxableAmount,
    required double totalTax,
    required double grandTotal,
    required Map<String, String> labels,
    required bool showTax,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderGray),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              _totalRow(labels['subtotal']!, subtotal),
              if (discount > 0) ...[
                pw.SizedBox(height: 6),
                _totalRow(labels['discount']!, -discount, isNegative: true),
              ],
              if (showTax && totalTax > 0) ...[
                pw.SizedBox(height: 6),
                _totalRow(labels['taxAmount']!, totalTax),
              ],
              pw.SizedBox(height: 8),
              pw.Divider(color: borderGray),
              pw.SizedBox(height: 8),
              _totalRow(labels['grandTotal']!, grandTotal,
                  isBold: true, isHighlight: true),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _totalRow(String label, double amount,
      {bool isBold = false,
      bool isNegative = false,
      bool isHighlight = false}) {
    return pw.Container(
      padding: isHighlight ? const pw.EdgeInsets.all(8) : pw.EdgeInsets.zero,
      decoration: isHighlight
          ? pw.BoxDecoration(
              color: lightBlue,
              borderRadius: pw.BorderRadius.circular(4),
            )
          : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isHighlight ? 12 : 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHighlight ? primaryBlue : textDark,
            ),
          ),
          pw.Text(
            '${isNegative ? "- " : ""}${_currencyFormat.format(amount.abs())}',
            style: pw.TextStyle(
              fontSize: isHighlight ? 14 : 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isNegative
                  ? PdfColors.red
                  : (isHighlight ? primaryBlue : textDark),
            ),
          ),
        ],
      ),
    );
  }

  /// Build amount in words section
  pw.Widget _buildAmountInWords(double amount, Map<String, String> labels) {
    final words = _convertAmountToWords(amount);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF3F4F6),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '${labels['amountInWords']}: ',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: textGray,
              ),
            ),
            pw.TextSpan(
              text: words,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.normal,
                color: textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build notes and terms section
  pw.Widget _buildNotesSection(
      String? notes, String? terms, Map<String, String> labels) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (notes != null && notes.isNotEmpty) ...[
          pw.Text(
            labels['notes']!,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
          ),
          pw.SizedBox(height: 4),
          pw.Text(notes, style: pw.TextStyle(fontSize: 9, color: textGray)),
          pw.SizedBox(height: 12),
        ],
        if (terms != null && terms.isNotEmpty) ...[
          pw.Text(
            labels['termsConditions']!,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
          ),
          pw.SizedBox(height: 4),
          pw.Text(terms, style: pw.TextStyle(fontSize: 9, color: textGray)),
        ],
      ],
    );
  }

  /// Build signature section
  pw.Widget _buildSignatureSection(
      Uint8List? signatureImage, Map<String, String> labels) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (signatureImage != null)
              pw.Container(
                height: 50,
                width: 120,
                child: pw.Image(pw.MemoryImage(signatureImage),
                    fit: pw.BoxFit.contain),
              )
            else
              pw.Container(
                height: 50,
                width: 120,
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: textDark)),
                ),
              ),
            pw.SizedBox(height: 4),
            pw.Text(
              labels['authorizedSignature']!,
              style: pw.TextStyle(fontSize: 9, color: textGray),
            ),
          ],
        ),
      ],
    );
  }

  /// Build footer
  pw.Widget _buildFooter(Map<String, String> labels) {
    return pw.Column(
      children: [
        pw.Divider(color: borderGray),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            labels['thankYou']!,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            labels['computerGenerated']!,
            style: pw.TextStyle(fontSize: 8, color: textGray),
          ),
        ),
      ],
    );
  }

  /// Convert amount to words (Indian numbering system)
  String _convertAmountToWords(double amount) {
    final rupees = amount.floor();
    final paise = ((amount - rupees) * 100).round();

    String result = 'Rupees ${_numberToWords(rupees)}';
    if (paise > 0) {
      result += ' and ${_numberToWords(paise)} Paise';
    }
    result += ' Only';

    return result;
  }

  String _numberToWords(int number) {
    if (number == 0) return 'Zero';

    final ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen'
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety'
    ];

    if (number < 20) {
      return ones[number];
    }
    if (number < 100) {
      return '${tens[number ~/ 10]}${number % 10 > 0 ? ' ${ones[number % 10]}' : ''}';
    }
    if (number < 1000) {
      return '${ones[number ~/ 100]} Hundred${number % 100 > 0 ? ' ${_numberToWords(number % 100)}' : ''}';
    }
    if (number < 100000) {
      return '${_numberToWords(number ~/ 1000)} Thousand${number % 1000 > 0 ? ' ${_numberToWords(number % 1000)}' : ''}';
    }
    if (number < 10000000) {
      return '${_numberToWords(number ~/ 100000)} Lakh${number % 100000 > 0 ? ' ${_numberToWords(number % 100000)}' : ''}';
    }
    return '${_numberToWords(number ~/ 10000000)} Crore${number % 10000000 > 0 ? ' ${_numberToWords(number % 10000000)}' : ''}';
  }

  /// Load custom font
  Future<pw.Font?> _loadFont(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.Font.ttf(data);
    } catch (e) {
      return null;
    }
  }

  /// Get translated labels for the selected language
  Map<String, String> _getLabels(InvoiceLanguage language) {
    switch (language) {
      case InvoiceLanguage.hindi:
        return _hindiLabels;
      case InvoiceLanguage.marathi:
        return _marathiLabels;
      case InvoiceLanguage.gujarati:
        return _gujaratiLabels;
      case InvoiceLanguage.tamil:
        return _tamilLabels;
      case InvoiceLanguage.telugu:
        return _teluguLabels;
      case InvoiceLanguage.bengali:
        return _bengaliLabels;
      default:
        return _englishLabels;
    }
  }

  // ========== LANGUAGE LABELS ==========

  static const Map<String, String> _englishLabels = {
    'invoice': 'INVOICE',
    'taxInvoice': 'TAX INVOICE',
    'invoiceNo': 'Invoice No',
    'date': 'Date',
    'dueDate': 'Due Date',
    'billedTo': 'Billed To',
    'proprietor': 'Proprietor',
    'mobile': 'Mobile',
    'email': 'Email',
    'slNo': 'Sl No',
    'description': 'Description',
    'qty': 'Qty',
    'unit': 'Unit',
    'rate': 'Rate',
    'tax': 'Tax',
    'amount': 'Amount',
    'subtotal': 'Subtotal',
    'discount': 'Discount',
    'taxAmount': 'Tax Amount',
    'grandTotal': 'Grand Total',
    'amountInWords': 'Amount in Words',
    'notes': 'Notes',
    'termsConditions': 'Terms & Conditions',
    'authorizedSignature': 'Authorized Signature',
    'thankYou': 'Thank You for Your Business!',
    'computerGenerated': 'This is a computer-generated invoice',
  };

  static const Map<String, String> _hindiLabels = {
    'invoice': 'बिल',
    'taxInvoice': 'टैक्स बिल',
    'invoiceNo': 'बिल नंबर',
    'date': 'दिनांक',
    'dueDate': 'देय तिथि',
    'billedTo': 'बिल प्राप्तकर्ता',
    'proprietor': 'मालिक',
    'mobile': 'मोबाइल',
    'email': 'ईमेल',
    'slNo': 'क्र. सं.',
    'description': 'विवरण',
    'qty': 'मात्रा',
    'unit': 'इकाई',
    'rate': 'दर',
    'tax': 'कर',
    'amount': 'राशि',
    'subtotal': 'उप-योग',
    'discount': 'छूट',
    'taxAmount': 'कर राशि',
    'grandTotal': 'कुल योग',
    'amountInWords': 'शब्दों में राशि',
    'notes': 'टिप्पणी',
    'termsConditions': 'नियम और शर्तें',
    'authorizedSignature': 'अधिकृत हस्ताक्षर',
    'thankYou': 'आपके व्यापार के लिए धन्यवाद!',
    'computerGenerated': 'यह कंप्यूटर जनित बिल है',
  };

  static const Map<String, String> _marathiLabels = {
    'invoice': 'बिल',
    'taxInvoice': 'कर बिल',
    'invoiceNo': 'बिल क्रमांक',
    'date': 'दिनांक',
    'dueDate': 'देय तारीख',
    'billedTo': 'बिल प्राप्तकर्ता',
    'proprietor': 'मालक',
    'mobile': 'मोबाईल',
    'email': 'ईमेल',
    'slNo': 'अनु. क्र.',
    'description': 'वर्णन',
    'qty': 'प्रमाण',
    'unit': 'एकक',
    'rate': 'दर',
    'tax': 'कर',
    'amount': 'रक्कम',
    'subtotal': 'उप-एकूण',
    'discount': 'सवलत',
    'taxAmount': 'कर रक्कम',
    'grandTotal': 'एकूण',
    'amountInWords': 'शब्दात रक्कम',
    'notes': 'टीप',
    'termsConditions': 'अटी आणि शर्ती',
    'authorizedSignature': 'अधिकृत स्वाक्षरी',
    'thankYou': 'आपल्या व्यवसायासाठी धन्यवाद!',
    'computerGenerated': 'हे संगणक निर्मित बिल आहे',
  };

  static const Map<String, String> _gujaratiLabels = {
    'invoice': 'ઇન્વોઇસ',
    'taxInvoice': 'ટેક્સ ઇન્વોઇસ',
    'invoiceNo': 'ઇન્વોઇસ નંબર',
    'date': 'તારીખ',
    'dueDate': 'નિયત તારીખ',
    'billedTo': 'બીલ પ્રાપ્તકર્તા',
    'proprietor': 'માલિક',
    'mobile': 'મોબાઇલ',
    'email': 'ઈમેઈલ',
    'slNo': 'ક્ર. નં.',
    'description': 'વિગત',
    'qty': 'જથ્થો',
    'unit': 'એકમ',
    'rate': 'ભાવ',
    'tax': 'કર',
    'amount': 'રકમ',
    'subtotal': 'પેટા કુલ',
    'discount': 'છૂટ',
    'taxAmount': 'કર રકમ',
    'grandTotal': 'કુલ રકમ',
    'amountInWords': 'શબ્દોમાં રકમ',
    'notes': 'નોંધ',
    'termsConditions': 'નિયમો અને શરતો',
    'authorizedSignature': 'અધિકૃત હસ્તાક્ષર',
    'thankYou': 'તમારા વ્યવસાય માટે આભાર!',
    'computerGenerated': 'આ કમ્પ્યુટર જનિત ઇન્વોઇસ છે',
  };

  static const Map<String, String> _tamilLabels = {
    'invoice': 'விலைப்பட்டியல்',
    'taxInvoice': 'வரி விலைப்பட்டியல்',
    'invoiceNo': 'விலைப்பட்டியல் எண்',
    'date': 'தேதி',
    'dueDate': 'நிலுவை தேதி',
    'billedTo': 'பில் பெறுநர்',
    'proprietor': 'உரிமையாளர்',
    'mobile': 'மொபைல்',
    'email': 'மின்னஞ்சல்',
    'slNo': 'வ.எண்',
    'description': 'விவரம்',
    'qty': 'அளவு',
    'unit': 'அலகு',
    'rate': 'விலை',
    'tax': 'வரி',
    'amount': 'தொகை',
    'subtotal': 'துணை மொத்தம்',
    'discount': 'தள்ளுபடி',
    'taxAmount': 'வரி தொகை',
    'grandTotal': 'மொத்த தொகை',
    'amountInWords': 'சொற்களில் தொகை',
    'notes': 'குறிப்புகள்',
    'termsConditions': 'விதிமுறைகள்',
    'authorizedSignature': 'அங்கீகரிக்கப்பட்ட கையொப்பம்',
    'thankYou': 'உங்கள் வணிகத்திற்கு நன்றி!',
    'computerGenerated': 'இது கணினி உருவாக்கிய விலைப்பட்டியல்',
  };

  static const Map<String, String> _teluguLabels = {
    'invoice': 'ఇన్వాయిస్',
    'taxInvoice': 'టాక్స్ ఇన్వాయిస్',
    'invoiceNo': 'ఇన్వాయిస్ నంబర్',
    'date': 'తేదీ',
    'dueDate': 'చెల్లించవలసిన తేదీ',
    'billedTo': 'బిల్ పొందేవారు',
    'proprietor': 'యజమాని',
    'mobile': 'మొబైల్',
    'email': 'ఇమెయిల్',
    'slNo': 'క్ర.సం.',
    'description': 'వివరణ',
    'qty': 'పరిమాణం',
    'unit': 'యూనిట్',
    'rate': 'రేటు',
    'tax': 'పన్ను',
    'amount': 'మొత్తం',
    'subtotal': 'ఉప మొత్తం',
    'discount': 'తగ్గింపు',
    'taxAmount': 'పన్ను మొత్తం',
    'grandTotal': 'మొత్తం మొత్తం',
    'amountInWords': 'మాటలలో మొత్తం',
    'notes': 'గమనికలు',
    'termsConditions': 'నిబంధనలు',
    'authorizedSignature': 'అధీకృత సంతకం',
    'thankYou': 'మీ వ్యాపారానికి ధన్యవాదాలు!',
    'computerGenerated': 'ఇది కంప్యూటర్ రూపొందించిన ఇన్వాయిస్',
  };

  static const Map<String, String> _bengaliLabels = {
    'invoice': 'চালান',
    'taxInvoice': 'ট্যাক্স চালান',
    'invoiceNo': 'চালান নম্বর',
    'date': 'তারিখ',
    'dueDate': 'বকেয়া তারিখ',
    'billedTo': 'বিল প্রাপক',
    'proprietor': 'মালিক',
    'mobile': 'মোবাইল',
    'email': 'ইমেইল',
    'slNo': 'ক্র. নং',
    'description': 'বিবরণ',
    'qty': 'পরিমাণ',
    'unit': 'একক',
    'rate': 'দর',
    'tax': 'কর',
    'amount': 'পরিমাণ',
    'subtotal': 'উপমোট',
    'discount': 'ছাড়',
    'taxAmount': 'কর পরিমাণ',
    'grandTotal': 'সর্বমোট',
    'amountInWords': 'কথায় পরিমাণ',
    'notes': 'মন্তব্য',
    'termsConditions': 'শর্তাবলী',
    'authorizedSignature': 'অনুমোদিত স্বাক্ষর',
    'thankYou': 'আপনার ব্যবসার জন্য ধন্যবাদ!',
    'computerGenerated': 'এটি কম্পিউটার তৈরি চালান',
  };

  // ========== SHARING METHODS ==========

  /// Share invoice via platform share sheet
  Future<void> shareInvoice(
    Uint8List pdfBytes,
    String invoiceNumber, {
    String? paymentLink,
    String? message,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Invoice_$invoiceNumber.pdf');
    await file.writeAsBytes(pdfBytes);

    String shareText = message ?? 'Invoice #$invoiceNumber from DukanX';
    if (paymentLink != null) {
      shareText += "\n\nPAY NOW: $paymentLink";
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      text: shareText,
      subject: 'Invoice #$invoiceNumber',
    );
  }

  /// Print invoice directly
  Future<void> printInvoice(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice',
    );
  }

  /// Save invoice to downloads
  Future<String?> saveInvoice(Uint8List pdfBytes, String invoiceNumber) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/Invoice_$invoiceNumber.pdf';
      final file = File(path);
      await file.writeAsBytes(pdfBytes);
      return path;
    } catch (e) {
      return null;
    }
  }

  /// Generate invoice from Bill model
  Future<Uint8List> generateFromBill({
    required Bill bill,
    required InvoiceConfig config,
    String? notes,
    String? terms,
  }) async {
    // Convert bill items to invoice items
    // BillItem fields: itemName, qty, price, unit, gstRate, discount (amount not percent)
    final items = bill.items
        .map((item) => InvoiceItem(
              name: item.itemName,
              description: null,
              quantity: item.qty,
              unit: item.unit,
              unitPrice: item.price,
              discountPercent: null, // BillItem.discount is amount, not percent
              taxPercent: item.gstRate,
            ))
        .toList();

    // Create customer
    final customer = InvoiceCustomer(
      name: bill.customerName,
      mobile: bill.customerPhone,
      address: bill.customerAddress,
      gstin: bill.customerGst,
    );

    return generateInvoicePdf(
      config: config,
      customer: customer,
      items: items,
      invoiceNumber: bill.invoiceNumber,
      invoiceDate: bill.date,
      discount: bill.discountApplied,
      notes: notes,
      termsAndConditions: terms,
    );
  }
}
