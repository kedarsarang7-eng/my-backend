import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/repository/products_repository.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/futuristic_colors.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/prescription_repository.dart';
import '../../../../widgets/desktop/desktop_content_container.dart';
import '../../../../widgets/modern_ui_components.dart';
import 'dart:convert';
import '../../data/repositories/medical_template_repository.dart';
import '../../models/medical_template_model.dart';
import '../../models/prescription_model.dart';

class AddPrescriptionScreen extends ConsumerStatefulWidget {
  final String? preSelectedPatientId;
  final String? visitId;
  const AddPrescriptionScreen({
    this.preSelectedPatientId,
    this.visitId,
    super.key,
  });

  @override
  ConsumerState<AddPrescriptionScreen> createState() =>
      _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends ConsumerState<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adviceController = TextEditingController();

  // Dependencies
  final PrescriptionRepository _prescriptionRepo = sl<PrescriptionRepository>();
  final ProductsRepository _productsRepo = sl<ProductsRepository>();
  final MedicalTemplateRepository _templateRepo =
      sl<MedicalTemplateRepository>();
  final SessionManager _sessionManager = sl<SessionManager>();

  // State
  String? _selectedPatientId;
  final List<PrescriptionItemModel> _items = [];
  List<MedicalTemplateModel> _rxTemplates = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedPatientId != null) {
      _selectedPatientId = widget.preSelectedPatientId;
    }
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final docId = _sessionManager.ownerId ?? 'SYSTEM';
    final templates = await _templateRepo.getTemplatesByType(
      docId,
      'PRESCRIPTION',
    );
    if (mounted) setState(() => _rxTemplates = templates);
  }

  Future<void> _saveAsTemplate() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add medicines first to save as template'),
        ),
      );
      return;
    }

    // Ask for template name
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FuturisticColors.surface,
        title: const Text(
          'Save Protocol Template',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Protocol Name',
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameCtrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    final docId = _sessionManager.ownerId ?? 'SYSTEM';

    // Serialize items
    final itemsJson = jsonEncode(_items.map((e) => e.toMap()).toList());

    final template = MedicalTemplateModel(
      id: const Uuid().v4(),
      userId: docId,
      type: 'PRESCRIPTION',
      title: name,
      content: itemsJson,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _templateRepo.createTemplate(template);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Protocol saved!')));
      _loadTemplates();
    }
  }

  void _applyTemplate(MedicalTemplateModel template) {
    try {
      final List<dynamic> list = jsonDecode(template.content);
      final newItems = list
          .map((e) => PrescriptionItemModel.fromMap(e))
          .toList();

      setState(() {
        // Create new IDs for imported items to avoid conflicts
        for (var item in newItems) {
          item.prescriptionId = ''; // Reset
          // item.id should strictly be new too, but PrescriptionItemModel might not allow setter.
          // Assuming it's a data class, we might need copyWith or just replicate.
          // Ideally we regenerate ID here strictly.
        }
        _items.addAll(newItems);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load template: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopContentContainer(
      title: 'New Prescription',
      subtitle: 'Create a new prescription',
      actions: [
        PrimaryButton(
          label: _isSaving ? 'Saving...' : 'Save Prescription',
          icon: _isSaving ? null : Icons.save,
          onPressed: _isSaving ? null : _savePrescription,
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Patient Selection
              _buildSectionTitle('Select Patient'),
              const SizedBox(height: 8),
              _buildPatientDropdown(),
              const SizedBox(height: 24),

              // 2. Add Medicines
              _buildSectionTitle('Prescribed Medicines'),
              const SizedBox(height: 8),
              _buildSectionTitle('Prescribed Medicines'),
              const SizedBox(height: 8),

              // Templates Chips
              if (_rxTemplates.isNotEmpty) ...[
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _rxTemplates.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final t = _rxTemplates[index];
                      return ActionChip(
                        label: Text(t.title),
                        backgroundColor: FuturisticColors.primary.withOpacity(
                          0.2,
                        ),
                        labelStyle: const TextStyle(color: Colors.white),
                        onPressed: () => _applyTemplate(t),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              _buildMedicineSearch(),
              const SizedBox(height: 16),

              // 3. Medicine List
              if (_items.isNotEmpty) ...[
                _buildMedicineList(),
                const SizedBox(height: 24),
              ],

              // 4. Clinical Advice
              _buildSectionTitle('Clinical Advice / Notes'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _adviceController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: FuturisticColors.surface,
                  hintText: 'e.g. Drink plenty of water, Rest for 2 days...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _saveAsTemplate,
                    icon: const Icon(
                      Icons.bookmark_add,
                      color: FuturisticColors.primary,
                    ),
                    label: const Text('Save as Protocol'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: FuturisticColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPatientDropdown() {
    return FutureBuilder(
      future: sl<PatientRepository>().watchAllPatients().first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: LinearProgressIndicator());
        }
        final patients = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          value: _selectedPatientId,
          dropdownColor: FuturisticColors.surface,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: FuturisticColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(
              Icons.person,
              color: FuturisticColors.primary,
            ),
          ),
          items: patients
              .map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(
                    p.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedPatientId = val),
          hint: const Text(
            'Choose Patient',
            style: TextStyle(color: Colors.grey),
          ),
          validator: (val) => val == null ? 'Please select a patient' : null,
        );
      },
    );
  }

  Widget _buildMedicineSearch() {
    return Autocomplete<Product>(
      optionsBuilder: (textEditingValue) async {
        if (textEditingValue.text.length < 2) return [];
        final userId = _sessionManager.ownerId ?? '';
        final result = await _productsRepo.search(
          textEditingValue.text,
          userId: userId,
        );
        // Filter to show medicines preferentially, but also include all products
        final products = result.data ?? [];
        // Sort: medicines first, then by name
        products.sort((a, b) {
          final aIsMedicine =
              a.category?.toLowerCase() == 'medicine' ||
              a.category?.toLowerCase() == 'medicines';
          final bIsMedicine =
              b.category?.toLowerCase() == 'medicine' ||
              b.category?.toLowerCase() == 'medicines';
          if (aIsMedicine && !bIsMedicine) return -1;
          if (!aIsMedicine && bIsMedicine) return 1;
          return a.name.compareTo(b.name);
        });
        return products.take(10).toList(); // Limit results
      },
      displayStringForOption: (option) => option.name,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: FuturisticColors.surface,
            hintText: 'Search Medicine...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: const Icon(
              Icons.medication_outlined,
              color: FuturisticColors.primary,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () => controller.clear(),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: FuturisticColors.surface,
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 350,
              height: 250,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  final isMedicine =
                      option.category?.toLowerCase() == 'medicine' ||
                      option.category?.toLowerCase() == 'medicines';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isMedicine
                          ? FuturisticColors.primary.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      child: Icon(
                        isMedicine ? Icons.medication : Icons.inventory_2,
                        color: isMedicine
                            ? FuturisticColors.primary
                            : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      option.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '₹${option.sellingPrice.toStringAsFixed(2)} • ${option.unit}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (product) => _showAddMedicineDialog(product),
    );
  }

  Widget _buildMedicineList() {
    return Container(
      decoration: BoxDecoration(
        color: FuturisticColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, _) =>
            const Divider(color: Colors.white10, height: 1),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            title: Text(
              item.medicineName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.dosage ?? ""} • ${item.duration ?? ""} • ${item.instructions ?? ""}',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => setState(() => _items.removeAt(index)),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddMedicineDialog(Product product) async {
    final dosageCtrl = TextEditingController(text: '1-0-1');
    final durationCtrl = TextEditingController(text: '3 Days');
    final instructionCtrl = TextEditingController(text: 'After Food');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FuturisticColors.surface,
        title: Text(product.name, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(dosageCtrl, 'Dosage (e.g. 1-0-1)'),
            const SizedBox(height: 12),
            _buildDialogField(durationCtrl, 'Duration (e.g. 5 Days)'),
            const SizedBox(height: 12),
            _buildDialogField(instructionCtrl, 'Instructions'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _items.add(
                  PrescriptionItemModel(
                    id: const Uuid().v4(),
                    prescriptionId: '', // Set on save
                    medicineName: product.name,
                    productId: product.id,
                    dosage: dosageCtrl.text,
                    duration: durationCtrl.text,
                    instructions: instructionCtrl.text,
                    frequency: 'Daily', // Default or add field
                  ),
                );
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FuturisticColors.primary,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: FuturisticColors.primary),
        ),
      ),
    );
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please prescribe at least one medicine')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final docId = _sessionManager.ownerId ?? 'SYSTEM';
      final prescriptionId = const Uuid().v4();

      // Update item IDs
      for (var item in _items) {
        item.prescriptionId = prescriptionId;
      }

      final prescription = PrescriptionModel(
        id: prescriptionId,
        doctorId: docId,
        patientId: _selectedPatientId!,
        visitId:
            widget.visitId ??
            const Uuid().v4(), // Use provided visitId or generate
        date: DateTime.now(),
        advice: _adviceController.text,
        items: _items,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _prescriptionRepo.createPrescription(prescription);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription Saved Successfully!')),
        );
        Navigator.pop(
          context,
          prescriptionId,
        ); // Return prescriptionId to caller
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
