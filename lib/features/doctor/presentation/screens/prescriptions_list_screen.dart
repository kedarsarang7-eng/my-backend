import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/futuristic_colors.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/repository/products_repository.dart';
import '../../../../models/bill.dart'; // For BillItem
import '../../../../features/billing/presentation/screens/bill_creation_screen_v2.dart';
import '../../data/repositories/prescription_repository.dart';
import '../../data/repositories/patient_repository.dart';
import '../../models/prescription_model.dart';

import '../../../../widgets/desktop/desktop_content_container.dart';
import '../../../../widgets/modern_ui_components.dart';
import 'add_prescription_screen.dart';

class SafePrescriptionListScreen extends ConsumerStatefulWidget {
  const SafePrescriptionListScreen({super.key});

  @override
  ConsumerState<SafePrescriptionListScreen> createState() =>
      _SafePrescriptionListScreenState();
}

class _SafePrescriptionListScreenState
    extends ConsumerState<SafePrescriptionListScreen> {
  final PrescriptionRepository _repo = sl<PrescriptionRepository>();
  final PatientRepository _patientRepo = sl<PatientRepository>();
  final ProductsRepository _productsRepo = sl<ProductsRepository>();
  final SessionManager _sessionManager = sl<SessionManager>();

  @override
  Widget build(BuildContext context) {
    return DesktopContentContainer(
      title: 'Prescriptions',
      subtitle: 'Manage patient prescriptions',
      actions: [
        PrimaryButton(
          label: 'New Prescription',
          icon: Icons.note_add,
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddPrescriptionScreen()));
          },
        ),
      ],
      child: FutureBuilder<List<PrescriptionModel>>(
        future: _fetchAllPrescriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final p = list[index];
              return _buildPrescriptionCard(p);
            },
          );
        },
      ),
    );
  }

  Future<List<PrescriptionModel>> _fetchAllPrescriptions() async {
    final docId = _sessionManager.ownerId ?? 'SYSTEM';
    return await _repo.getRecentPrescriptions(docId);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined,
              size: 64, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No prescriptions found',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionModel p) {
    return FutureBuilder(
      future: _patientRepo.getPatientById(p.patientId),
      builder: (context, snapshot) {
        final patientName = snapshot.data?.name ?? 'Unknown Patient';
        return ModernCard(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FuturisticColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medical_services,
                  color: FuturisticColors.primary),
            ),
            title: Text(patientName,
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(DateFormat('MMM dd, yyyy • HH:mm').format(p.date),
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${p.items.length} Medicines',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.receipt_long, color: Colors.greenAccent),
                  tooltip: 'Create Bill',
                  onPressed: () => _billPrescription(p, snapshot.data),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _billPrescription(PrescriptionModel p, dynamic patient) async {
    // 1. Build Bill Items
    final List<BillItem> billItems = [];

    for (var item in p.items) {
      if (item.productId != null) {
        final productResult = await _productsRepo.getById(item.productId!);
        final product = productResult.data;
        if (product != null) {
          billItems.add(BillItem(
            productId: product.id,
            productName: product
                .name, // Use current name or prescription name? Using product name.
            qty: 1, // Default qty, maybe parse 'Dosage' later?
            price: product.sellingPrice,
            unit: product.unit,
            gstRate: product.taxRate,
            cgst: product.sellingPrice * (product.taxRate / 200),
            sgst: product.sellingPrice * (product.taxRate / 200),
          ));
        }
      }
    }

    if (billItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No billed items found (products may be deleted)')),
        );
      }
      return;
    }

    if (mounted) {
      // 2. Navigate to Bill Creation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BillCreationScreenV2(
            initialItems: billItems,
            // initialCustomer: Map patient to Customer?
            // For now, let user select customer or handle mapping manually.
            // Ideally we'd map patient -> customer here if they exist in customer db.
          ),
        ),
      );
    }
  }
}
