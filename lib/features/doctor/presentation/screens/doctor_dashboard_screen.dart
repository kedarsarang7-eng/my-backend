import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_prescription_screen.dart';
import '../../data/repositories/doctor_dashboard_repository.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/futuristic_colors.dart';
import '../../../../widgets/desktop/desktop_content_container.dart';

import '../widgets/patient_overview_card.dart';
import '../widgets/daily_patient_view.dart';
import '../widgets/smart_insights_card.dart';
import '../widgets/weekly_analytics_chart.dart';
import '../widgets/monthly_analytics_chart.dart';
import '../widgets/alerts_panel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'visit_screen.dart';
import 'doctor_revenue_screen.dart';
import '../../data/repositories/patient_repository.dart';
import '../../models/patient_model.dart';
import 'package:uuid/uuid.dart';
import '../../../../screens/widgets/sync_status_indicator.dart'; // IMPORT ADDED

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() =>
      _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  final DoctorDashboardRepository _repository = sl<DoctorDashboardRepository>();
  String get _doctorId => sl<SessionManager>().ownerId ?? 'SYSTEM';
  String? _doctorName;

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
  }

  Future<void> _loadDoctorName() async {
    final session = sl<SessionManager>();
    final name = session.currentSession.displayName;
    if (name != null && mounted) {
      setState(() => _doctorName = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopContentContainer(
      title: 'Doctor Dashboard',
      subtitle:
          'Welcome back${_doctorName != null ? ', Dr. $_doctorName' : ''}',
      actions: [
        DesktopIconButton(
          icon: Icons.flash_on,
          tooltip: 'Emergency Visit',
          onPressed: _startEmergencyVisit,
        ),
        const SizedBox(width: 8),
        const SyncStatusIndicator(),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlerts(),
            const SizedBox(height: 24),
            _buildPatientOverview(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildDailyPatientView()),
                const SizedBox(width: 24),
                Expanded(flex: 1, child: _buildSmartInsights()),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildWeeklyAnalytics()),
                const SizedBox(width: 24),
                Expanded(child: _buildMonthlyAnalytics()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startEmergencyVisit() async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FuturisticColors.surface,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              'Emergency / Walk-in',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quickly create a visit. Enter name or leave blank for "Walk-In".',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Patient Name (Optional)',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.redAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text(
              'Start Visit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (!mounted) return;

    // Create Patient
    final patientName = result.isEmpty
        ? 'Walk-In ${DateTime.now().hour}:${DateTime.now().minute}'
        : result;
    final newId = const Uuid().v4();
    final now = DateTime.now();

    final patient = PatientModel(
      id: newId,
      name: patientName,
      phone: null, // Skip phone for emergency
      age: null,
      gender: 'Unknown',
      bloodGroup: null,
      address: 'Emergency Walk-in',
      chronicConditions: null,
      allergies: null,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await sl<PatientRepository>().createPatient(patient);

      if (!mounted) return;

      // Navigate to Visit Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VisitScreen(patientId: newId)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start emergency visit: $e')),
        );
      }
    }
  }

  Widget _buildPatientOverview() {
    return FutureBuilder<Map<String, int>>(
      future: _repository.getPatientStats(_doctorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return PatientOverviewCard(data: snapshot.data!);
      },
    );
  }

  Widget _buildDailyPatientView() {
    return StreamBuilder(
      stream: _repository.watchDailyAppointments(_doctorId, DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return DailyPatientView(
          appointments: snapshot.data!,
          onPatientTap: _showPatientDetails,
        );
      },
    );
  }

  void _showPatientDetails(String patientId) async {
    final patient = await _repository.getPatientDetails(patientId);
    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FuturisticColors.surface,
        title: Text(
          'Patient Details',
          style: GoogleFonts.inter(color: FuturisticColors.textPrimary),
        ),
        content: patient == null
            ? Text(
                'Patient not found',
                style: GoogleFonts.inter(color: FuturisticColors.textSecondary),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: ${patient.name}',
                    style: GoogleFonts.inter(
                      color: FuturisticColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phone: ${patient.phone ?? "--"}',
                    style: GoogleFonts.inter(
                      color: FuturisticColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Age: ${patient.age ?? "--"}',
                    style: GoogleFonts.inter(
                      color: FuturisticColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Gender: ${patient.gender ?? "--"}',
                    style: GoogleFonts.inter(
                      color: FuturisticColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Allergies: ${patient.allergies ?? "None"}',
                    style: GoogleFonts.inter(color: FuturisticColors.error),
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to Prescription
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddPrescriptionScreen(preSelectedPatientId: patient?.id),
                ),
              );
            },
            child: Text(
              'Prescribe',
              style: GoogleFonts.inter(color: FuturisticColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: FuturisticColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartInsights() {
    return FutureBuilder<Map<String, String>>(
      future: _repository.getSmartInsights(_doctorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return SmartInsightsCard(insights: snapshot.data!);
      },
    );
  }

  Widget _buildWeeklyAnalytics() {
    return FutureBuilder<Map<String, int>>(
      future: _repository.getWeeklyAnalytics(_doctorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return WeeklyAnalyticsChart(weeklyData: snapshot.data!);
      },
    );
  }

  Widget _buildMonthlyAnalytics() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DoctorRevenueScreen()),
        );
      },
      child: FutureBuilder<Map<String, int>>(
        future: _repository.getMonthlyAnalytics(_doctorId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          return MonthlyAnalyticsChart(monthlyData: snapshot.data!);
        },
      ),
    );
  }

  Widget _buildAlerts() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _repository.getDashboardAlerts(_doctorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return AlertsPanel(alerts: snapshot.data!);
      },
    );
  }
}
