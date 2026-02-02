import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/bill.dart';
import 'gmail_service.dart';

class EmailRepository {
  static final EmailRepository _instance = EmailRepository._internal();
  factory EmailRepository() => _instance;
  EmailRepository._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final GmailService _gmailService = GmailService();

  /// Send Invoice Email via Backend using Client-Side Access Token
  Future<void> sendInvoiceEmail({
    required Uint8List pdfBytes,
    required Bill bill,
    required String businessName,
  }) async {
    try {
      // 1. Check Authentication
      if (!await _gmailService.isAuthenticated()) {
        throw Exception('Gmail not connected. Please sign in first.');
      }

      // 2. Get Fresh Access Token
      final accessToken = await _gmailService.getAccessToken();

      // 3. Prepare Data
      final pdfBase64 = base64Encode(pdfBytes);
      final senderEmail = _gmailService.userEmail;

      if (bill.customerEmail == null || bill.customerEmail!.isEmpty) {
        throw Exception('Customer email not provided in the bill.');
      }

      // 4. Call Cloud Function
      final callable = _functions.httpsCallable('sendInvoiceEmail');

      final subject = 'Invoice #${bill.invoiceNumber} from $businessName';
      final body =
          '''
Hello ${bill.customerName},

Please find attached the invoice #${bill.invoiceNumber} for your recent purchase at $businessName.

Invoice Details:
Number: ${bill.invoiceNumber}
Date: ${bill.date.toString().split(' ')[0]}
Amount: ₹${bill.grandTotal.toStringAsFixed(2)}

Thank you for your business!

Regards,
$businessName
''';

      final result = await callable.call({
        'recipient':
            bill.customerEmail, // Using customerEmail field from Bill model
        'subject': subject,
        'body': body,
        'pdfBase64': pdfBase64,
        'filename': 'Invoice_${bill.invoiceNumber}.pdf',
        'accessToken': accessToken,
        'senderEmail': senderEmail,
        'businessName': businessName,
      });

      if (result.data['success'] != true) {
        throw Exception('Server failed to send email: ${result.data}');
      }

      debugPrint(
        '[EmailRepository] Email sent successfully. ID: ${result.data['messageId']}',
      );
    } catch (e) {
      debugPrint('[EmailRepository] Failed to send email: $e');
      rethrow;
    }
  }
}
