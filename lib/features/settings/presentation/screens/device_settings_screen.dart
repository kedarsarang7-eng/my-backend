import 'package:flutter/material.dart';
import '../../../../widgets/desktop/desktop_content_container.dart';
import '../../../../widgets/modern_ui_components.dart';
import '../../../../core/theme/futuristic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/app_state_providers.dart';

class DeviceSettingsScreen extends ConsumerStatefulWidget {
  const DeviceSettingsScreen({super.key});

  @override
  ConsumerState<DeviceSettingsScreen> createState() =>
      _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends ConsumerState<DeviceSettingsScreen> {
  bool _enableCloudBackup = true;
  bool _darkMode = true;
  double _defaultTaxRate = 18.0;

  @override
  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final theme = ref.watch(themeStateProvider);

    return DesktopContentContainer(
      title: 'Device Settings',
      subtitle: 'Configure device-specific preferences and hardware',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('General Preferences'),
            const SizedBox(height: 16),
            ModernCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Dark Mode',
                    'Use futuristic dark theme',
                    _darkMode,
                    (val) => setState(() => _darkMode = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Data & Backup'),
            const SizedBox(height: 16),
            ModernCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Cloud Backup',
                    'Auto-sync data to cloud',
                    _enableCloudBackup,
                    (val) => setState(() => _enableCloudBackup = val),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Backup Frequency'),
                    subtitle: const Text('Daily at 12:00 AM'),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () => _showBackupFrequencyDialog(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Billing Defaults'),
            const SizedBox(height: 16),
            ModernCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Default Tax Rate (GST)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_defaultTaxRate.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: FuturisticColors.accent1,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _defaultTaxRate,
                      min: 0,
                      max: 28,
                      divisions: 4,
                      activeColor: FuturisticColors.accent1,
                      label: '${_defaultTaxRate.round()}%',
                      onChanged: (val) => setState(() => _defaultTaxRate = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Hardware Integration'),
            const SizedBox(height: 16),
            ModernCard(
              child: ListTile(
                leading: const Icon(
                  Icons.print,
                  color: FuturisticColors.accent2,
                ),
                title: const Text('Printer Configuration'),
                subtitle: const Text('Manage connected thermal printers'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/printer-settings'),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'DukanX Enterprise v3.0.1\nBuild 2026.01.25',
                textAlign: TextAlign.center,
                style: TextStyle(color: FuturisticColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: FuturisticColors.accent1,
    );
  }

  void _showBackupFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Backup Frequency'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Every 6 hours'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Daily at 12:00 AM (Recommended)'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Weekly'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: FuturisticColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }
}
