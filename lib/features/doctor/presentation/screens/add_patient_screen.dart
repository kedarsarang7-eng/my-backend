import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../widgets/desktop/desktop_content_container.dart';
import '../../../../widgets/modern_ui_components.dart';
import '../../../../core/theme/futuristic_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../models/patient_model.dart';
import '../../services/patient_service.dart';
import '../../data/repositories/patient_repository.dart';

class AddPatientScreen extends ConsumerStatefulWidget {
  const AddPatientScreen({super.key});

  @override
  ConsumerState<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends ConsumerState<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _allergiesController = TextEditingController(); // New

  // Chronic Conditions
  final List<String> _commonConditions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Thyroid',
    'Heart Disease',
    'Arthritis',
    'Kidney Disease',
  ];
  final Set<String> _selectedConditions = {};

  String _selectedGender = 'Male';
  String _selectedBloodGroup = 'Unknown';
  bool _isLoading = false;

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newId = const Uuid().v4();
      final now = DateTime.now();

      final patient = PatientModel(
        id: newId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender,
        bloodGroup: _selectedBloodGroup,
        address: _addressController.text.trim(),
        chronicConditions: _selectedConditions.join(','),
        allergies: _allergiesController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      // Save to DB
      await sl<PatientRepository>().createPatient(patient);

      // Auto-generate QR
      await sl<PatientService>().generateQrToken(newId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient registered successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopContentContainer(
      title: 'Register New Patient',
      subtitle: 'Create a new patient record',
      actions: [
        PrimaryButton(
          label: _isLoading ? 'Saving...' : 'Register Patient',
          icon: _isLoading ? null : Icons.save,
          onPressed: _isLoading ? null : _savePatient,
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: FuturisticColors.surface,
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: FuturisticColors.accent1.withOpacity(0.1)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Information',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 24),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'Full Name', icon: Icon(Icons.person)),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                        labelText: 'Phone Number', icon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Age & Gender Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          decoration: const InputDecoration(
                              labelText: 'Age', icon: Icon(Icons.cake)),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                              labelText: 'Gender', icon: Icon(Icons.male)),
                          items: ['Male', 'Female', 'Other']
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedGender = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Blood Group
                  DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    decoration: const InputDecoration(
                        labelText: 'Blood Group', icon: Icon(Icons.bloodtype)),
                    items: [
                      'Unknown',
                      'A+',
                      'A-',
                      'B+',
                      'B-',
                      'O+',
                      'O-',
                      'AB+',
                      'AB-'
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBloodGroup = v!),
                  ),
                  const SizedBox(height: 16),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                        labelText: 'Address', icon: Icon(Icons.home)),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Medical History Section
                  const Text('Medical History',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Chronic Conditions Chips
                  const Text('Chronic Conditions:',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonConditions.map((condition) {
                      final isSelected =
                          _selectedConditions.contains(condition);
                      return FilterChip(
                        label: Text(condition),
                        selected: isSelected,
                        selectedColor:
                            FuturisticColors.primary.withOpacity(0.2),
                        checkmarkColor: FuturisticColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? FuturisticColors.primary
                              : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedConditions.add(condition);
                            } else {
                              _selectedConditions.remove(condition);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Allergies
                  TextFormField(
                    controller: _allergiesController,
                    decoration: const InputDecoration(
                        labelText: 'Allergies (Optional)',
                        icon: Icon(Icons.warning_amber)),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  // Removed bottom button as it is in the header actions now
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
