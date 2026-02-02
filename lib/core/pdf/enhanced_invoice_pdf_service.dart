// Enhanced Invoice PDF Service - Production-grade PDF Generation
// Supports multi-page, business-type themes, multi-language, and all edge cases
//
// Created: 2024-12-26
// Author: DukanX Team

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'invoice_pdf_theme.dart';
import 'invoice_pdf_widgets.dart';
import 'invoice_models.dart';
import 'invoice_column_model.dart';
import '../../models/bill.dart';
import '../../services/invoice_pdf_service.dart' show InvoiceLanguage;

/// Main Enhanced Invoice PDF Service
class EnhancedInvoicePdfService {
  static final EnhancedInvoicePdfService _instance =
      EnhancedInvoicePdfService._internal();
  factory EnhancedInvoicePdfService() => _instance;
  EnhancedInvoicePdfService._internal();

  /// Generate professional multi-page invoice PDF
  Future<Uint8List> generateInvoicePdf({
    required EnhancedInvoiceConfig config,
    required EnhancedInvoiceCustomer customer,
    required List<EnhancedInvoiceItem> items,
    required String invoiceNumber,
    required DateTime invoiceDate,
    DateTime? dueDate,
    double? additionalDiscount,
    String? notes,
    InvoiceStatus? status,
    PaymentMode? paymentMode,
  }) async {
    // Load fonts
    final regularFont = await _loadFont('assets/fonts/NotoSans-Regular.ttf');
    final boldFont = await _loadFont('assets/fonts/NotoSans-Bold.ttf');

    pw.Font baseFont = pw.Font.helvetica();
    pw.Font baseBoldFont = pw.Font.helveticaBold();

    if (regularFont != null) baseFont = regularFont;
    if (boldFont != null) baseBoldFont = boldFont;

    // Get theme based on business type
    final theme = InvoicePdfTheme.fromBusinessType(config.businessType);

    // Get labels for language
    final labels = _getLabels(config.language);

    // Create widgets helper
    final widgets = InvoicePdfWidgets(
      theme: theme,
      labels: labels,
      language: config.language,
    );

    // Calculate totals
    double subtotal = items.fold(0, (sum, item) => sum + item.subtotal);
    double totalItemDiscount = items.fold(
      0,
      (sum, item) => sum + item.discount,
    );
    double totalDiscount = totalItemDiscount + (additionalDiscount ?? 0);
    double totalCgst = items.fold(0, (sum, item) => sum + (item.cgst ?? 0));
    double totalSgst = items.fold(0, (sum, item) => sum + (item.sgst ?? 0));
    double totalIgst = items.fold(0, (sum, item) => sum + (item.igst ?? 0));
    double totalTax = totalCgst + totalSgst + totalIgst;
    double taxableAmount = subtotal - totalDiscount;
    double grandTotalBeforeRound = taxableAmount + totalTax;

    // Calculate round-off
    double roundOff =
        grandTotalBeforeRound.roundToDouble() - grandTotalBeforeRound;
    double grandTotal = grandTotalBeforeRound + roundOff;

    // Determine status
    final invoiceStatus = status ?? InvoiceStatus.unpaid;
    final invoicePaymentMode = paymentMode ?? PaymentMode.cash;

    // Convert items to row data
    final List<ItemRowData> itemRows = items
        .map(
          (item) => ItemRowData(
            name: item.name,
            quantity: _formatQuantity(item.quantity),
            unit: item.unit,
            rate: item.unitPrice,
            taxPercent: item.taxPercent,
            discount: item.discount,
            amount: item.total,
          ),
        )
        .toList();

    // Create PDF document
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: baseFont, bold: baseBoldFont),
    );

    // Use MultiPage for automatic page handling
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        maxPages: 100, // Support up to 100 pages for very large invoices
        header: (pw.Context context) {
          // Only show header on first page
          if (context.pageNumber == 1) {
            return pw.SizedBox.shrink();
          }
          // Mini header for continuation pages
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  config.shopName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                pw.Text(
                  'Invoice #$invoiceNumber (Continued)',
                  style: pw.TextStyle(fontSize: 10, color: theme.textGray),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  labels['computerGenerated']!,
                  style: pw.TextStyle(fontSize: 8, color: theme.textGray),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: theme.textGray),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // ===== HEADER SECTION =====
            widgets.buildHeader(
              shopName: config.shopName,
              ownerName: config.ownerName,
              address: config.address,
              mobile: config.mobile,
              email: config.email,
              gstin: config.gstin,
              fssaiNumber: config.fssaiNumber,
              tagline: config.tagline,
              logoImage: config.logoImage,
              avatarImage: config.avatarImage,
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: theme.primaryColor, thickness: 2),
            pw.SizedBox(height: 16),

            // ===== INVOICE INFO + CUSTOMER ROW =====
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: Customer Details
                pw.Expanded(
                  flex: 3,
                  child: widgets.buildCustomerSection(
                    name: customer.name,
                    mobile: customer.mobile,
                    address: customer.address,
                    gstin: customer.gstin,
                  ),
                ),
                pw.SizedBox(width: 16),
                // Right: Invoice Info + Optional QR
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    children: [
                      widgets.buildInvoiceInfoBox(
                        invoiceNumber: invoiceNumber,
                        invoiceDate: invoiceDate,
                        dueDate: dueDate,
                        status: invoiceStatus,
                        paymentMode: invoicePaymentMode,
                        isGstBill: config.isGstBill,
                      ),
                      // QR Code for UPI (if upiId provided)
                      if (config.upiId != null &&
                          config.upiId!.isNotEmpty &&
                          grandTotal > 0) ...[
                        pw.SizedBox(height: 10),
                        widgets.buildQrCode(
                          upiId: config.upiId!,
                          shopName: config.shopName,
                          amount: grandTotal,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // ===== ITEMS TABLE =====
            if (config.version >= 2)
              widgets.buildDynamicItemsTable(
                items: items,
                columns: InvoiceSchemaResolver.getColumns(
                  config.businessType,
                  config.showTax,
                ),
              )
            else
              widgets.buildItemsTable(items: itemRows, showTax: config.showTax),
            pw.SizedBox(height: 16),

            // ===== TOTALS SECTION =====
            widgets.buildTotalsSection(
              subtotal: subtotal,
              discount: totalDiscount,
              cgst: config.showTax ? totalCgst : null,
              sgst: config.showTax ? totalSgst : null,
              igst: config.showTax ? totalIgst : null,
              taxAmount: totalTax,
              roundOff: roundOff.abs() > 0.001 ? roundOff : null,
              grandTotal: grandTotal,
              showTax: config.showTax,
            ),
            pw.SizedBox(height: 14),

            // ===== AMOUNT IN WORDS =====
            widgets.buildAmountInWords(grandTotal),
            pw.SizedBox(height: 16),

            // ===== NOTES / TERMS =====
            if (notes != null || config.termsAndConditions != null)
              widgets.buildNotesSection(
                notes: notes,
                terms: config.termsAndConditions,
              ),

            pw.Spacer(),

            // ===== SIGNATURE SECTION =====
            widgets.buildSignatureSection(
              signatureImage: config.signatureImage,
              stampImage: config.stampImage,
            ),
            pw.SizedBox(height: 12),

            // ===== FOOTER =====
            widgets.buildFooter(returnPolicy: config.returnPolicy),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generate invoice from Bill model (convenience method)
  Future<Uint8List> generateFromBill({
    required Bill bill,
    required EnhancedInvoiceConfig config,
    String? notes,
  }) async {
    // Convert bill items
    final items = bill.items
        .map((item) => EnhancedInvoiceItem.fromBillItem(item))
        .toList();

    // Create customer
    final customer = EnhancedInvoiceCustomer.fromBill(bill);

    // Determine status
    InvoiceStatus status;
    if (bill.status == 'Paid') {
      status = InvoiceStatus.paid;
    } else if (bill.status == 'Partial') {
      status = InvoiceStatus.partial;
    } else {
      status = InvoiceStatus.unpaid;
    }

    // Determine payment mode
    PaymentMode paymentMode;
    switch (bill.paymentType.toLowerCase()) {
      case 'online':
      case 'upi':
        paymentMode = PaymentMode.upi;
        break;
      case 'card':
        paymentMode = PaymentMode.card;
        break;
      case 'credit':
        paymentMode = PaymentMode.credit;
        break;
      case 'mixed':
        paymentMode = PaymentMode.mixed;
        break;
      default:
        paymentMode = PaymentMode.cash;
    }

    return generateInvoicePdf(
      config: config,
      customer: customer,
      items: items,
      invoiceNumber: bill.invoiceNumber.isEmpty
          ? 'INV-${DateTime.now().millisecondsSinceEpoch}'
          : bill.invoiceNumber,
      invoiceDate: bill.date,
      additionalDiscount: bill.discountApplied,
      notes: notes,
      status: status,
      paymentMode: paymentMode,
    );
  }

  // ===== EXPORT METHODS =====

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

  /// Save invoice to downloads/documents
  Future<String?> saveInvoice(Uint8List pdfBytes, String invoiceNumber) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final invoicesDir = Directory('${directory.path}/Invoices');
      if (!await invoicesDir.exists()) {
        await invoicesDir.create(recursive: true);
      }
      final path = '${invoicesDir.path}/Invoice_$invoiceNumber.pdf';
      final file = File(path);
      await file.writeAsBytes(pdfBytes);
      return path;
    } catch (e) {
      return null;
    }
  }

  /// Preview invoice (returns PDF for display)
  Future<Uint8List> previewInvoice({
    required EnhancedInvoiceConfig config,
    required EnhancedInvoiceCustomer customer,
    required List<EnhancedInvoiceItem> items,
    required String invoiceNumber,
    required DateTime invoiceDate,
  }) async {
    return generateInvoicePdf(
      config: config,
      customer: customer,
      items: items,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
    );
  }

  // ===== HELPER METHODS =====

  String _formatQuantity(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }

  Future<pw.Font?> _loadFont(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.Font.ttf(data);
    } catch (e) {
      return null;
    }
  }

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
    'slNo': '#',
    'description': 'Description',
    'qty': 'Qty',
    'unit': 'Unit',
    'rate': 'Rate',
    'tax': 'Tax',
    'discount': 'Discount',
    'amount': 'Amount',
    'subtotal': 'Subtotal',
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
    'slNo': 'क्र.',
    'description': 'विवरण',
    'qty': 'मात्रा',
    'unit': 'इकाई',
    'rate': 'दर',
    'tax': 'कर',
    'discount': 'छूट',
    'amount': 'राशि',
    'subtotal': 'उप-योग',
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
    'slNo': 'अनु.',
    'description': 'वर्णन',
    'qty': 'प्रमाण',
    'unit': 'एकक',
    'rate': 'दर',
    'tax': 'कर',
    'discount': 'सवलत',
    'amount': 'रक्कम',
    'subtotal': 'उप-एकूण',
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
    'slNo': 'ક્ર.',
    'description': 'વિગત',
    'qty': 'જથ્થો',
    'unit': 'એકમ',
    'rate': 'ભાવ',
    'tax': 'કર',
    'discount': 'છૂટ',
    'amount': 'રકમ',
    'subtotal': 'પેટા કુલ',
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
    'discount': 'தள்ளுபடி',
    'amount': 'தொகை',
    'subtotal': 'துணை மொத்தம்',
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
    'slNo': 'క్ర.',
    'description': 'వివరణ',
    'qty': 'పరిమాణం',
    'unit': 'యూనిట్',
    'rate': 'రేటు',
    'tax': 'పన్ను',
    'discount': 'తగ్గింపు',
    'amount': 'మొత్తం',
    'subtotal': 'ఉప మొత్తం',
    'taxAmount': 'పన్ను మొత్తం',
    'grandTotal': 'మొత్తం',
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
    'slNo': 'ক্র.',
    'description': 'বিবরণ',
    'qty': 'পরিমাণ',
    'unit': 'একক',
    'rate': 'দর',
    'tax': 'কর',
    'discount': 'ছাড়',
    'amount': 'টাকা',
    'subtotal': 'উপমোট',
    'taxAmount': 'কর পরিমাণ',
    'grandTotal': 'সর্বমোট',
    'amountInWords': 'কথায় পরিমাণ',
    'notes': 'মন্তব্য',
    'termsConditions': 'শর্তাবলী',
    'authorizedSignature': 'অনুমোদিত স্বাক্ষর',
    'thankYou': 'আপনার ব্যবসার জন্য ধন্যবাদ!',
    'computerGenerated': 'এটি কম্পিউটার তৈরি চালান',
  };
}
