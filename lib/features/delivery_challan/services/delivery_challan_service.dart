import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/session/session_manager.dart';
import '../../../core/repository/bills_repository.dart';
import '../../../core/repository/products_repository.dart';
import '../../../core/services/invoice_number_service.dart';
import '../models/delivery_challan_model.dart';
import '../data/repositories/delivery_challan_repository.dart';

class DeliveryChallanService {
  final DeliveryChallanRepository _repository;
  final BillsRepository _billsRepository;
  final ProductsRepository _productsRepository;
  final InvoiceNumberService _invoiceNumberService;
  final SessionManager _sessionManager;

  DeliveryChallanService(
    this._repository,
    this._billsRepository,
    this._productsRepository,
    this._invoiceNumberService,
    this._sessionManager,
  );

  /// Create a new Delivery Challan
  Future<DeliveryChallan?> createChallan({
    required String? customerId,
    required String? customerName,
    required List<DeliveryChallanItem> items,
    required DateTime challanDate,
    DateTime? dueDate,
    String? transportMode,
    String? vehicleNumber,
    String? eWayBillNumber,
    String? shippingAddress,
  }) async {
    try {
      final userId = _sessionManager.ownerId;
      if (userId == null) throw Exception('User not logged in');

      // 1. Generate Challan Number (using same sequence or a separate DC sequence)
      // For now, we'll prefix DC- to the invoice sequence or use a timestamp if no specific sequence
      final challanNumber = 'DC-${DateTime.now().millisecondsSinceEpoch}';

      // 2. Calculate totals
      double subtotal = 0;
      double taxAmount = 0;
      double grandTotal = 0;

      for (var item in items) {
        subtotal += item.totalAmount - item.taxAmount;
        taxAmount += item.taxAmount;
        grandTotal += item.totalAmount;
      }

      // 3. Create Challan Object
      final challan = DeliveryChallan(
        id: const Uuid().v4(),
        userId: userId,
        challanNumber: challanNumber,
        customerId: customerId,
        customerName: customerName,
        challanDate: challanDate,
        dueDate: dueDate,
        subtotal: subtotal,
        taxAmount: taxAmount,
        grandTotal: grandTotal,
        status: DeliveryChallanStatus.sent, // Assume sent immediately
        transportMode: transportMode,
        vehicleNumber: vehicleNumber,
        eWayBillNumber: eWayBillNumber,
        shippingAddress: shippingAddress,
        items: items,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 4. Save to Repository
      await _repository.createChallan(challan);

      // 5. Reserve Stock (Optional: Mark as "Out on Challan" logic would go here)
      // For now, we adjust stock normally as it's leaving the warehouse?
      // GST Rule: Delivery Challan moves goods, so stock physically leaves.
      // We will decrement stock with a specific reason.
      for (var item in items) {
        await _productsRepository.adjustStock(
          productId: item.productId,
          quantity: -item.quantity, // Deduct stock
          userId: userId,
          // Extra metadata could be passed if adjustStock supported it,
          // but for now the reason is implicit or we add a log.
        );
      }

      return challan;
    } catch (e) {
      debugPrint('DeliveryChallanService: Error creating challan: $e');
      return null;
    }
  }

  /// Convert Delivery Challan to Tax Invoice
  Future<Bill?> convertToInvoice(DeliveryChallan challan) async {
    try {
      if (challan.status == DeliveryChallanStatus.converted) {
        throw Exception('Challan already converted');
      }

      final userId = challan.userId;

      // 1. REVERSE Stock Deduction from DC (to avoid double counting)
      // Since createBill will deduct stock again, we technically "return" the DC stock
      // and then "sell" it via the invoice. This maintains correct audit trails.
      for (var item in challan.items) {
        await _productsRepository.adjustStock(
          productId: item.productId,
          quantity: item.quantity, // Add back stock
          userId: userId,
          // Reason: 'Conversion Reversal for Invoice Generation'
        );
      }

      // 2. Generate Invoice Number
      final invoiceNumber = await _invoiceNumberService.getNextInvoiceNumber(
        userId: userId,
      );

      // Re-map properly
      final billItemsProper = challan.items.map((dcItem) {
        return BillItem(
          productId: dcItem.productId,
          productName: dcItem.productName,
          qty: dcItem.quantity,
          price: dcItem.unitPrice,
          unit: dcItem.unit,
          gstRate: dcItem.taxRate,
          hsn: dcItem.hsnCode ?? '',
          discount: 0,
        );
      }).toList();

      // 4. Create Bill Object
      final bill = Bill(
        id: const Uuid().v4(),
        ownerId: userId,
        invoiceNumber: invoiceNumber,
        customerId: challan.customerId ?? '',
        customerName: challan.customerName ?? 'Walk-in',
        date: DateTime.now(),
        // dueDate: challan.dueDate, // Missing in Bill
        subtotal: challan.subtotal,
        totalTax: challan.taxAmount,
        grandTotal: challan.grandTotal,
        status: 'Unpaid', // String status
        paymentType: 'CREDIT',
        items: billItemsProper,
        deliveryChallanId: challan.id, // Link back
        updatedAt: DateTime.now(),
      );

      // 4. Save Bill
      final result = await _billsRepository.createBill(bill);

      if (!result.isSuccess) {
        throw Exception(result.errorMessage ?? 'Failed to create bill');
      }

      // 5. Update Challan Status
      final updatedChallan = challan.copyWith(
        status: DeliveryChallanStatus.converted,
        convertedBillId: bill.id,
        updatedAt: DateTime.now(),
      );
      await _repository.updateChallan(updatedChallan);

      return bill;
    } catch (e) {
      debugPrint('DeliveryChallanService: Error converting to invoice: $e');
      return null;
    }
  }
}
