import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/futuristic_colors.dart';
import '../../data/repositories/lab_report_repository.dart';
import '../../models/lab_report_model.dart';
import '../../models/patient_model.dart';
import '../../../../widgets/desktop/desktop_content_container.dart';
import '../../../../widgets/glass_morphism.dart';

/// Lab Reports Screen - View and manage lab reports for a patient
///
/// Features:
/// - List all lab reports for a patient
/// - Filter by status (Pending, Uploaded, Ready)
/// - Upload report files (placeholder for file picking)
class LabReportsScreen extends ConsumerStatefulWidget {
  final PatientModel? patient;

  const LabReportsScreen({super.key, this.patient});

  @override
  ConsumerState<LabReportsScreen> createState() => _LabReportsScreenState();
}

class _LabReportsScreenState extends ConsumerState<LabReportsScreen>
    with SingleTickerProviderStateMixin {
  final _labReportRepo = sl<LabReportRepository>();
  late TabController _tabController;

  List<LabReportModel> _allReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      if (widget.patient != null) {
        // Load reports for specific patient
        _allReports =
            await _labReportRepo.getReportsForPatient(widget.patient!.id);
      } else {
        // Load pending reports for doctor
        final doctorId = sl<SessionManager>().ownerId ?? '';
        _allReports = await _labReportRepo.getPendingReports(doctorId);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<LabReportModel> _filterByStatus(LabReportStatus status) {
    return _allReports.where((r) => r.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopContentContainer(
      title: widget.patient != null
          ? 'Lab Reports - ${widget.patient!.name}'
          : 'Lab Reports',
      subtitle: 'Manage patient lab reports',
      child: Column(
        children: [
          // Custom Tab Bar
          Container(
            color: FuturisticColors.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: FuturisticColors.primary,
              labelColor: FuturisticColors.primary,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Uploaded'),
                Tab(text: 'Ready'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReportList(
                          _filterByStatus(LabReportStatus.pending)),
                      _buildReportList(
                          _filterByStatus(LabReportStatus.uploaded)),
                      _buildReportList(_filterByStatus(LabReportStatus.ready)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList(List<LabReportModel> reports) {
    if (reports.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) => _buildReportCard(reports[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined,
              size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No reports in this category',
            style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(LabReportModel report) {
    final dateFormat = DateFormat('dd MMM yyyy');

    Color statusColor;
    IconData statusIcon;

    switch (report.status) {
      case LabReportStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
        break;
      case LabReportStatus.collected:
        statusColor = Colors.yellow.shade700;
        statusIcon = Icons.science;
        break;
      case LabReportStatus.processing:
        statusColor = Colors.purple;
        statusIcon = Icons.autorenew;
        break;
      case LabReportStatus.uploaded:
        statusColor = Colors.blue;
        statusIcon = Icons.cloud_upload;
        break;
      case LabReportStatus.ready:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: FuturisticColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.science, color: statusColor),
        ),
        title: Text(
          report.testName,
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Ordered: ${dateFormat.format(report.orderedAt)}',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  report.status.name.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        trailing: _buildActionButton(report),
      ),
    );
  }

  Widget _buildActionButton(LabReportModel report) {
    switch (report.status) {
      case LabReportStatus.pending:
      case LabReportStatus.collected:
      case LabReportStatus.processing:
        return ElevatedButton.icon(
          onPressed: () => _uploadReport(report),
          icon: const Icon(Icons.upload, size: 16),
          label: const Text('Upload'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      case LabReportStatus.uploaded:
      case LabReportStatus.ready:
        return ElevatedButton.icon(
          onPressed: () => _viewReport(report),
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('View'),
          style: ElevatedButton.styleFrom(
            backgroundColor: FuturisticColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
    }
  }

  Future<void> _uploadReport(LabReportModel report) async {
    // Simulated File Picker
    final pickedFile = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select a File'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'report_scan.pdf'),
            child: const Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red),
                SizedBox(width: 10),
                Text('report_scan.pdf'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'lab_results.jpg'),
            child: const Row(
              children: [
                Icon(Icons.image, color: Colors.blue),
                SizedBox(width: 10),
                Text('lab_results.jpg'),
              ],
            ),
          ),
        ],
      ),
    );

    if (pickedFile != null) {
      // Simulate upload delay
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading...')),
        );
      }

      await Future.delayed(const Duration(seconds: 1));
      await _labReportRepo.updateStatus(report.id, LabReportStatus.uploaded);
      _loadReports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded $pickedFile successfully!')),
        );
      }
    }
  }

  void _viewReport(LabReportModel report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(report.testName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold))),
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.file_present, size: 64, color: Colors.grey),
                        Text('Report Preview',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                )
              ],
            )),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
