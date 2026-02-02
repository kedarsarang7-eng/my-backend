import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/navigation/navigation_controller.dart';
import '../../core/theme/futuristic_colors.dart';
import 'enterprise_sidebar.dart';
import 'content_host.dart';
import 'premium_content_wrapper.dart';
// Reuse existing top bar from original shell or extract it.
// For now, I'll reimplement/extract the structure to ensure clean decoupling.
import 'enterprise_desktop_shell.dart';

/// The Root Shell for the Desktop Application.
/// This widget is CONST (ideally) and never rebuilds its structure.
/// Updates are handled by leaf widgets listening to [NavigationController].
class DesktopRootShell extends ConsumerWidget {
  const DesktopRootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to navigation state ONLY for the sidebar selection ID
    // We use select to only rebuild if the screen ID changes, though
    // the sidebar itself handles internal state well too.
    final currentScreen = ref.watch(
      navigationControllerProvider.select((s) => s.currentScreen),
    );
    final controller = ref.read(navigationControllerProvider.notifier);

    return Scaffold(
      backgroundColor: FuturisticColors.background,
      body: Row(
        children: [
          // 1. SIDEBAR (Static placement, updates via props)
          // RepaintBoundary prevents rebuild propagation from content area
          RepaintBoundary(
            child: EnterpriseDesktopSidebar(
              selectedItemId: currentScreen.id,
              onItemSelected: (itemId, _) {
                controller.navigateById(itemId);
              },
            ),
          ),

          // 2. MAIN AREA
          Expanded(
            child: Column(
              children: [
                // TOP BAR (Extracted or Reused)
                // We reuse the internal private class via a public wrapper or just copy it if private.
                // Since _EnterpriseTopBar is private in the original file, we temporarily assume
                // we might need to modify the original file to export it or duplicate it.
                // For this task, I will modify enterprise_desktop_shell.dart to export 'EnterpriseTopBar'.
                const EnterpriseTopBar(),

                // CONTENT HOST (The only thing that switches)
                const Expanded(
                  child: PremiumContentWrapper(
                    showStarField: true,
                    showGradientOverlay: true,
                    child: DesktopContentHost(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
