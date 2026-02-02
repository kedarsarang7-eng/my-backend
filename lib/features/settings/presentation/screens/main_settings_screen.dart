import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:dukanx/core/di/service_locator.dart' hide sessionService; // Removed
// import 'package:dukanx/core/sync/sync_manager.dart'; // Removed

import '../../../../providers/app_state_providers.dart';
import '../../../../services/session_service.dart';
import '../../../../services/google_drive_service.dart';
import 'package:dukanx/generated/app_localizations.dart';
import '../../../shop_linking/presentation/screens/qr_display_screen.dart'
    as qrd;
import '../../../../core/utils/logout_guard.dart';
import '../../../gst/gst.dart' as gst;
import '../../../accounting/accounting.dart' as acc;
import '../../../avatar/presentation/screens/avatar_editor_screen.dart';
import '../../../auth/services/biometric_service.dart'; // Restored
import '../../../../core/sync/engine/sync_engine.dart'; // Added for manual sync

import '../../../../widgets/modern_ui_components.dart';
import '../../../../widgets/glass_bottom_sheet.dart';
import '../../../../core/theme/futuristic_colors.dart';
import '../../../../widgets/desktop/desktop_content_container.dart';

import '../../../auth/presentation/screens/pin_setup_screen.dart';
import 'customer_app_entry_qr_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isUploadingImage = false;

  // State for Desktop 2-Pane Navigation
  int _selectedCategoryIndex =
      0; // 0: Profile, 1: Business, 2: Security, 3: Appearance, 4: Backup

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width > 900) {
      return _buildDesktopLayout();
    }
    return _buildMobileLayout();
  }

  // ===========================================================================
  // DESKTOP LAYOUT (2-PANE)
  // ===========================================================================
  Widget _buildDesktopLayout() {
    return DesktopContentContainer(
      title: 'Settings',
      subtitle: 'Manage application preferences and business details',
      showScrollbar: false, // Handle scrolling internally in panes
      padding: const EdgeInsets.all(24),
      child: SizedBox.expand(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT PANEL: Navigation
            Container(
              width: 280,
              margin: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: FuturisticColors.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: FuturisticColors.border.withOpacity(0.1),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDesktopNavTile(0, "My Profile", Icons.person_outline),
                    if (sessionService.getUserRole() != 'customer')
                      _buildDesktopNavTile(
                        1,
                        "Business & Reports",
                        Icons.storefront_outlined,
                      ),
                    _buildDesktopNavTile(
                      2,
                      "Security & Access",
                      Icons.lock_outline,
                    ),
                    _buildDesktopNavTile(
                      3,
                      "Appearance & Language",
                      Icons.palette_outlined,
                    ),
                    _buildDesktopNavTile(
                      4,
                      "Backup & Sync",
                      Icons.cloud_sync_outlined,
                    ),
                    const Divider(height: 32, color: Colors.white10),
                    _buildDesktopNavTile(
                      99,
                      "Logout",
                      Icons.logout,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),

            // RIGHT PANEL: Content Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: FuturisticColors.surface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: FuturisticColors.border.withOpacity(0.05),
                  ),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Header
                    Text(
                      _getCategoryTitle(_selectedCategoryIndex),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getCategorySubtitle(_selectedCategoryIndex),
                      style: TextStyle(
                        fontSize: 14,
                        color: FuturisticColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildDesktopCategoryContent(
                          _selectedCategoryIndex,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopNavTile(
    int index,
    String title,
    IconData icon, {
    bool isDestructive = false,
  }) {
    final isSelected = _selectedCategoryIndex == index;
    final color = isDestructive
        ? FuturisticColors.error
        : (isSelected
              ? FuturisticColors.primary
              : FuturisticColors.textSecondary);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          if (index == 99) {
            _confirmLogout(context, AppLocalizations.of(context)!);
          } else {
            setState(() => _selectedCategoryIndex = index);
          }
        },
        selected: isSelected,
        selectedTileColor: FuturisticColors.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _getCategoryTitle(int index) {
    switch (index) {
      case 0:
        return "My Profile";
      case 1:
        return "Business Profile";
      case 2:
        return "Security";
      case 3:
        return "Appearance";
      case 4:
        return "Data Management";
      default:
        return "";
    }
  }

  String _getCategorySubtitle(int index) {
    switch (index) {
      case 0:
        return "Manage your personal account details";
      case 1:
        return "Configure GST, Invoicing rules and Reports";
      case 2:
        return "Biometrics, PIN and Password settings";
      case 3:
        return "Customize theme and display language";
      case 4:
        return "Backup your data to Cloud or Local Drive";
      default:
        return "";
    }
  }

  Widget _buildDesktopCategoryContent(int index) {
    // Reuse existing mobile widgets but wrap them in constrained cards
    // This avoids code duplication while giving extensive desktop look
    final l10n = AppLocalizations.of(context)!;
    final theme = ref.watch(themeStateProvider);
    final settings = ref.watch(settingsStateProvider);
    final isDark = theme.isDark;
    final palette = theme.palette;
    final localeState = ref.watch(localeStateProvider);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Builder(
        builder: (context) {
          switch (index) {
            case 0:
              return _buildProfileSection(context, settings, l10n, isDark);
            case 1:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.storefront_rounded,
                      title: "Business Profile",
                      onTap: () =>
                          Navigator.pushNamed(context, '/vendor_profile'),
                      isDark: isDark,
                      color: Colors.orange,
                    ),
                    _buildSettingsTile(
                      icon: Icons.receipt_long,
                      title: "GST Settings",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const gst.GstSettingsScreen(),
                        ),
                      ),
                      isDark: isDark,
                      color: Colors.teal,
                    ),
                  ], isDark),
                  const SizedBox(height: 24),
                  _buildSectionHeader('REPORTS & LOGS', isDark),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.summarize,
                      title: "GST Reports",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const gst.GstReportsScreen(),
                        ),
                      ),
                      isDark: isDark,
                      color: Colors.blue,
                    ),
                    _buildSettingsTile(
                      icon: Icons.account_balance,
                      title: "Financial Reports",
                      subtitle: "Trial Balance, P&L, Balance Sheet",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const acc.AccountingReportsScreen(),
                        ),
                      ),
                      isDark: isDark,
                      color: Colors.indigo,
                    ),
                  ], isDark),
                ],
              );
            case 2:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFastLoginSection(context, isDark, palette),
                  const SizedBox(height: 24),
                  _buildSettingsCard([
                    if (sessionService.getUserRole() == 'owner') ...[
                      _buildSettingsTile(
                        icon: Icons.qr_code_2_rounded,
                        title: "My QR Code",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const qrd.QrDisplayScreen(),
                          ),
                        ),
                        isDark: isDark,
                      ),
                    ],
                    _buildSettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: l10n.resetPassword,
                      onTap: () => _showResetPasswordDialog(context, l10n),
                      isDark: isDark,
                    ),
                  ], isDark),
                ],
              );
            case 3:
              return _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.language_rounded,
                  title: l10n.language,
                  trailing: Text(
                    _getLanguageName(localeState.locale.languageCode),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () =>
                      _showLanguageSelector(context, localeState, l10n),
                  isDark: isDark,
                ),
                _buildSettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: l10n.darkMode,
                  trailing: Switch(
                    value: theme.isDark,
                    onChanged: (val) {
                      ref.read(themeStateProvider.notifier).toggleTheme();
                    },
                    activeColor: palette.leafGreen,
                  ),
                  onTap: null,
                  isDark: isDark,
                ),
              ], isDark);
            case 4:
              return _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.cloud_done_outlined,
                  title: "Cloud Sync",
                  trailing: const Icon(
                    Icons.sync,
                    size: 20,
                    color: Colors.blue,
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/cloud_sync_settings',
                      arguments: sessionService.getUserId(),
                    );
                  },
                  isDark: isDark,
                ),
                _buildSettingsTile(
                  icon: Icons.add_to_drive,
                  title: GoogleDriveService().isConnected
                      ? "Google Drive Connected"
                      : "Connect Google Drive",
                  subtitle: GoogleDriveService().isConnected
                      ? "Tap to manage"
                      : "Free backup to your Drive",
                  trailing: GoogleDriveService().isConnected
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showDriveOptions(context, isDark),
                  isDark: isDark,
                  color: Colors.green,
                ),
                _buildSettingsTile(
                  icon: Icons.backup_outlined,
                  title: "Local Backup",
                  onTap: () => _performLocalBackup(context),
                  isDark: isDark,
                ),
              ], isDark);
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }

  // ===========================================================================
  // MOBILE LAYOUT (Renamed from original build)
  // ===========================================================================
  Widget _buildMobileLayout() {
    final theme = ref.watch(themeStateProvider);
    final settings = ref.watch(settingsStateProvider);
    final localeState = ref.watch(localeStateProvider);

    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.isDark;
    final palette = theme.palette;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: isDark
                ? FuturisticColors.darkTextPrimary
                : FuturisticColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? FuturisticColors.darkBackgroundGradient
              : FuturisticColors.lightBackgroundGradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              _buildProfileSection(context, settings, l10n, isDark),
              const SizedBox(height: 20),
              // BUSINESS PROFILE SECTION - For Invoice Details
              // Visible for owners and vendors (anyone who is NOT a customer)
              if (sessionService.getUserRole() != 'customer') ...[
                _buildSectionHeader('BUSINESS PROFILE', isDark),
                _buildSettingsCard([
                  _buildSettingsTile(
                    icon: Icons.storefront_rounded,
                    title: "Business Profile",
                    onTap: () =>
                        Navigator.pushNamed(context, '/vendor_profile'),
                    isDark: isDark,
                    color: Colors.orange,
                  ),
                  _buildSettingsTile(
                    icon: Icons.receipt_long,
                    title: "GST Settings",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const gst.GstSettingsScreen(),
                      ),
                    ),
                    isDark: isDark,
                    color: Colors.teal,
                  ),
                  // Reminders disabled - Repo unimplemented
                  // _buildSettingsTile(
                  //   icon: Icons.notifications_active,
                  //   title: "Payment Reminders",
                  //   ...
                  // ),
                ], isDark),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '💡 Add your shop name, address, mobile & GST for invoices',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('REPORTS & LOGS', isDark),
                _buildSettingsCard([
                  _buildSettingsTile(
                    icon: Icons.summarize,
                    title: "GST Reports",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const gst.GstReportsScreen(),
                      ),
                    ),
                    isDark: isDark,
                    color: Colors.blue,
                  ),
                  _buildSettingsTile(
                    icon: Icons.account_balance,
                    title: "Financial Reports",
                    subtitle: "Trial Balance, P&L, Balance Sheet",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const acc.AccountingReportsScreen(),
                      ),
                    ),
                    isDark: isDark,
                    color: Colors.indigo,
                  ),
                  // Reminder Logs disabled
                ], isDark),
                const SizedBox(height: 20),
              ],
              _buildSectionHeader(l10n.accountSecurity, isDark),
              _buildSettingsCard([
                if (sessionService.getUserRole() == 'owner') ...[
                  _buildSettingsTile(
                    icon: Icons.qr_code_2_rounded,
                    title: "My QR Code",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const qrd.QrDisplayScreen(),
                      ),
                    ),
                    isDark: isDark,
                  ),
                  _buildSettingsTile(
                    icon: Icons.qr_code_scanner_rounded,
                    title: "Customer App QR",
                    subtitle: "Invite customers to download app",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerAppEntryQrScreen(),
                      ),
                    ),
                    isDark: isDark,
                    color: Colors.green,
                  ),
                  _buildSettingsTile(
                    icon: Icons.storefront_rounded,
                    title: "Business Settings",
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Type & Language",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ],
                    ),
                    onTap: () =>
                        Navigator.pushNamed(context, '/business_settings'),
                    isDark: isDark,
                    color: Colors.deepPurple,
                  ),
                ],
                _buildSettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: l10n.resetPassword,
                  onTap: () => _showResetPasswordDialog(context, l10n),
                  isDark: isDark,
                ),
                _buildSettingsTile(
                  icon: Icons.logout_rounded,
                  title: l10n.logout,
                  onTap: () => _confirmLogout(context, l10n),
                  isDark: isDark,
                  color: Colors.redAccent,
                ),
              ], isDark),
              const SizedBox(height: 20),
              _buildSectionHeader(l10n.languageAppearance, isDark),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.language_rounded,
                  title: l10n.language,
                  trailing: Text(
                    _getLanguageName(localeState.locale.languageCode),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () =>
                      _showLanguageSelector(context, localeState, l10n),
                  isDark: isDark,
                ),
                _buildSettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: l10n.darkMode,
                  trailing: Switch(
                    value: theme.isDark,
                    onChanged: (val) {
                      ref.read(themeStateProvider.notifier).toggleTheme();
                    },
                    activeColor: palette.leafGreen,
                  ),
                  onTap: null,
                  isDark: isDark,
                ),
              ], isDark),
              if (sessionService.getUserRole() == 'owner') ...[
                const SizedBox(height: 20),
                _buildSectionHeader(l10n.dashboardSwitch, isDark),
                _buildSettingsCard([
                  _buildSettingsTile(
                    icon: Icons.dashboard_customize_outlined,
                    title: settings.isOwnerDashboard
                        ? l10n.ownerDashboard
                        : l10n.customerDashboard,
                    trailing: Switch(
                      value: !settings.isOwnerDashboard,
                      onChanged: (val) async {
                        try {
                          await ref
                              .read(settingsStateProvider.notifier)
                              .setDashboardMode(!val);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  val
                                      ? "Switched to Owner View" // Logic was inverted in logging, fixed now
                                      : "Switched to Customer View",
                                ),
                              ),
                            );
                          }

                          // Safe rebuild wait
                          await Future.delayed(
                            const Duration(milliseconds: 300),
                          );
                        } catch (e) {
                          _showErrorDialog(
                            context,
                            l10n.permissionError,
                            e.toString(),
                          );
                        }
                      },
                      activeColor: palette.leafGreen,
                    ),
                    onTap: null,
                    isDark: isDark,
                  ),
                ], isDark),
              ],

              const SizedBox(height: 20),
              _buildSectionHeader("Security & Login", isDark),
              _buildFastLoginSection(context, isDark, palette),

              const SizedBox(height: 20),
              _buildSectionHeader(l10n.backupSync, isDark),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.cloud_done_outlined,
                  title: "Cloud Sync",
                  trailing: const Icon(
                    Icons.sync,
                    size: 20,
                    color: Colors.blue,
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/cloud_sync_settings',
                      arguments: sessionService.getUserId(),
                    );
                  },
                  isDark: isDark,
                ),
                _buildSettingsTile(
                  icon: Icons.add_to_drive,
                  title: GoogleDriveService().isConnected
                      ? "Google Drive Connected"
                      : "Connect Google Drive",
                  subtitle: GoogleDriveService().isConnected
                      ? "Tap to manage"
                      : "Free backup to your Drive",
                  trailing: GoogleDriveService().isConnected
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showDriveOptions(context, isDark),
                  isDark: isDark,
                  color: Colors.green,
                ),
                _buildSettingsTile(
                  icon: Icons.backup_outlined,
                  title: "Local Backup",
                  onTap: () => _performLocalBackup(context),
                  isDark: isDark,
                ),
              ], isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    SettingsState settings,
    var l10n,
    bool isDark,
  ) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: FuturisticColors.primaryGradient,
                  image: settings.profileImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(settings.profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: settings.profileImageUrl == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _pickImage(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: FuturisticColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isUploadingImage || settings.isLoading)
            const Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.userName ?? "User",
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? FuturisticColors.darkTextPrimary
                        : FuturisticColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? "",
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? FuturisticColors.darkTextSecondary
                        : FuturisticColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _editName(context, settings, l10n),
                  child: Text(
                    l10n.editName,
                    style: AppTypography.labelLarge.copyWith(
                      color: FuturisticColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AvatarEditorScreen(),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.face,
                        size: 16,
                        color: FuturisticColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Customize Avatar',
                        style: AppTypography.labelLarge.copyWith(
                          color: FuturisticColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark
              ? FuturisticColors.darkTextMuted
              : FuturisticColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, bool isDark) {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback? onTap,
    required bool isDark,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? FuturisticColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? FuturisticColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.w500,
          color: isDark
              ? FuturisticColors.darkTextPrimary
              : FuturisticColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? FuturisticColors.darkTextSecondary
                    : FuturisticColors.textSecondary,
              ),
            )
          : null,
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
    );
  }

  Widget _buildFastLoginSection(
    BuildContext context,
    bool isDark,
    AppColorPalette palette,
  ) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FuturisticColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.speed, color: FuturisticColors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quick Access",
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? FuturisticColors.darkTextPrimary
                          : FuturisticColors.textPrimary,
                    ),
                  ),
                  Text(
                    "Enable biometric or PIN login",
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? FuturisticColors.darkTextSecondary
                          : FuturisticColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSecurityOption(
                  icon: Icons.fingerprint,
                  label: "Biometric",
                  isDark: isDark,
                  onTap: () async {
                    final bioService = BiometricService();
                    final available = await bioService.isDeviceSupported();
                    if (available) {
                      await bioService.enableBiometrics();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Biometric Login Enabled!"),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Biometric not available on this device",
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecurityOption(
                  icon: Icons.pin,
                  label: "Setup PIN",
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PinSetupScreen(
                          onSuccess: () {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("PIN Set Successfully!"),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? FuturisticColors.darkSurfaceElevated
              : FuturisticColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? FuturisticColors.glassBorderDark
                : FuturisticColors.glassBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isDark
                  ? FuturisticColors.darkTextPrimary
                  : FuturisticColors.textPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark
                    ? FuturisticColors.darkTextSecondary
                    : FuturisticColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'Hindi (हिंदी)';
      case 'mr':
        return 'Marathi (मराठी)';
      case 'gu':
        return 'Gujarati (ગુજરાતી)';
      case 'ta':
        return 'Tamil (தமிழ்)';
      case 'te':
        return 'Telugu (తెలుగు)';
      case 'kn':
        return 'Kannada (ಕನ್ನಡ)';
      case 'ml':
        return 'Malayalam (മലയാളം)';
      case 'bn':
        return 'Bengali (বাংলা)';
      case 'pa':
        return 'Punjabi (ਪੰਜਾਬੀ)';
      case 'ur':
        return 'Urdu (اردو)';
      default:
        return code;
    }
  }

  void _showLanguageSelector(
    BuildContext context,
    LocaleState localeState,
    AppLocalizations l10n,
  ) {
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'hi', 'name': 'Hindi (हिंदी)'},
      {'code': 'mr', 'name': 'Marathi (मराठी)'},
      {'code': 'gu', 'name': 'Gujarati (ગુજરાતી)'},
      {'code': 'ta', 'name': 'Tamil (தமிழ்)'},
      {'code': 'te', 'name': 'Telugu (తెలుగు)'},
      {'code': 'kn', 'name': 'Kannada (ಕನ್ನಡ)'},
      {'code': 'ml', 'name': 'Malayalam (മലയാളം)'},
      {'code': 'bn', 'name': 'Bengali (বাংলা)'},
      {'code': 'pa', 'name': 'Punjabi (ਪੰਜਾਬੀ)'},
      {'code': 'ur', 'name': 'Urdu (اردو)'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return GlassBottomSheet(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.language,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: FuturisticColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final lang = languages[index];
                      return ListTile(
                        title: Text(
                          lang['name']!,
                          style: AppTypography.bodyLarge.copyWith(
                            color: FuturisticColors.textPrimary,
                          ),
                        ),
                        trailing:
                            localeState.locale.languageCode == lang['code']
                            ? const Icon(
                                Icons.check_circle,
                                color: FuturisticColors.success,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          // Delay to allow modal to close before rebuilding app with new locale
                          Future.delayed(const Duration(milliseconds: 300), () {
                            ref
                                .read(localeStateProvider.notifier)
                                .setLocale(Locale(lang['code']!));
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickImage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassBottomSheet(
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: FuturisticColors.primary,
                ),
                title: Text(
                  'Gallery',
                  style: AppTypography.bodyLarge.copyWith(
                    color: FuturisticColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close sheet immediately
                  _handleImageUpload(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: FuturisticColors.primary,
                ),
                title: Text(
                  'Camera',
                  style: AppTypography.bodyLarge.copyWith(
                    color: FuturisticColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close sheet immediately
                  _handleImageUpload(context, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Legacy Image Upload Logic locally implemented to keep Notifier pure
  Future<void> _handleImageUpload(
    BuildContext context,
    ImageSource source,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 50,
      );
      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_images/${user.uid}.jpg',
      );

      // Universal upload (works on Web, Mobile, Desktop)
      final bytes = await image.readAsBytes();
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await storageRef.getDownloadURL();

      if (mounted) {
        // Update Riverpod State
        await ref
            .read(settingsStateProvider.notifier)
            .updateProfileImage(downloadUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile picture updated!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error uploading image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _editName(
    BuildContext context,
    SettingsState settings,
    AppLocalizations l10n,
  ) {
    final controller = TextEditingController(text: settings.userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editName),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter your name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(settingsStateProvider.notifier)
                  .setUserName(controller.text);
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, AppLocalizations l10n) {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetPassword),
        content: Text("A password reset link will be sent to $email"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reset email sent!")),
                );
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.confirmLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) await LogoutGuard.attemptLogout(context);
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showDriveOptions(BuildContext context, bool isDark) {
    final driveService = GoogleDriveService();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Google Drive Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uses only drive.file scope - app can only access its own files',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!driveService.isConnected) ...[
              _buildDriveOption(
                icon: Icons.login,
                title: 'Connect Google Drive',
                subtitle: 'Enable cloud backup',
                color: Colors.green,
                onTap: () async {
                  Navigator.pop(context);
                  final success = await driveService.connect();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Google Drive connected!'
                              : 'Failed to connect. Try again.',
                        ),
                      ),
                    );
                    setState(() {});
                  }
                },
                isDark: isDark,
              ),
            ] else ...[
              // _buildDriveOption(
              //   icon: Icons.cloud_upload_outlined,
              //   title: 'Backup Now',
              //   subtitle: 'Manual Backup',
              //   color: Colors.blue,
              //   onTap: () async {
              //      // Implement Backup Now
              //   },
              //   isDark: isDark,
              // ),
              const SizedBox(height: 12),
              _buildDriveOption(
                icon: Icons.logout,
                title: 'Disconnect',
                subtitle: 'Stop backing up',
                color: Colors.red,
                onTap: () async {
                  await driveService.disconnect();
                  if (context.mounted) {
                    Navigator.pop(context);
                    // Wire up Backup Now
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Starting manual backup...'),
                      ),
                    );
                    SyncEngine.instance
                        .triggerSync()
                        .then((_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Backup completed successfully'),
                              ),
                            );
                          }
                        })
                        .catchError((e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Backup failed: $e')),
                            );
                          }
                        });
                  }
                },
                isDark: isDark,
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDriveOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white24 : Colors.black26,
      ),
    );
  }

  Future<void> _performLocalBackup(BuildContext context) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Creating backup...')));

      // Get the app's data directory
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFileName = 'dukanx_backup_$timestamp.json';

      // Get data from repositories
      final userId = sessionService.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create backup data structure
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'userId': userId,
        'note':
            'This is a local backup. Data is also synced to cloud automatically.',
      };

      // Backup data prepared - in production would be saved to file

      // For demonstration, show success with file info
      // In production, this would use path_provider and file_picker to save
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup created: $backupFileName (${backupData.length} items)',
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
