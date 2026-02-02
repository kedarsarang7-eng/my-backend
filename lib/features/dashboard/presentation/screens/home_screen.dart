import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../widgets/modern_ui_components.dart';
import '../../../../core/theme/futuristic_colors.dart';
import '../../../../screens/widgets/sync_status_indicator.dart';

// Strategy Imports
import '../../logic/dashboard_strategies.dart';

import '../../../../models/business_type.dart';
import '../../../../providers/app_state_providers.dart';

class HomeScreenModern extends ConsumerStatefulWidget {
  const HomeScreenModern({super.key});

  @override
  ConsumerState<HomeScreenModern> createState() => _HomeScreenModernState();
}

class _HomeScreenModernState extends ConsumerState<HomeScreenModern>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Get Current Business Type from Riverpod Provider
    // Get Current Business Type from Riverpod Provider
    final businessType = ref.watch(businessTypeProvider).type;
    final strategy = DashboardStrategyFactory.getStrategy(businessType);
    final quickActions = strategy.quickActions;

    return Scaffold(
      backgroundColor: FuturisticColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Modern AppBar with gradient
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: FuturisticColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  businessType.displayName, // Use displayName from Extension
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        FuturisticColors.primary,
                        FuturisticColors.primaryDark,
                      ],
                    ),
                  ),
                ),
                centerTitle: true,
                collapseMode: CollapseMode.parallax,
              ),
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(child: SyncStatusIndicator()),
                ),
              ],
            ),
            // Content
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamic Menu Grid
                      GridView.count(
                        crossAxisCount: isMobile ? 2 : 3,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.85,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: quickActions.map((action) {
                          return AnimatedMenuCard(
                            icon: action.icon,
                            title: action.label,
                            onTap: () {
                              if (action.route.isNotEmpty) {
                                Navigator.pushNamed(context, action.route);
                              }
                            },
                            backgroundColor:
                                (action.color ?? FuturisticColors.primary)
                                    .withOpacity(0.1),
                            iconColor: action.color ?? FuturisticColors.primary,
                            showBadge: false, // Can add later
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Quick Tips Section
                      Text(
                        'Quick Tips',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ModernCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTipItem(
                              context,
                              Icons.lightbulb_outline,
                              'Optimize Your Business',
                              'Use ${businessType.displayName} features to track everything efficiently.',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildTipItem(
                              context,
                              strategy.addItemIcon,
                              'Quick Actions',
                              'Use the "${strategy.addItemLabel}" shortcut for faster entry.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: FuturisticColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Icon(icon, color: FuturisticColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: FuturisticColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
