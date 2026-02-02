// ============================================================================
// KITCHEN DISPLAY SCREEN (VENDOR) - PREMIUM FUTURISTIC UI
// ============================================================================
// All existing functionality preserved:
// - Sound toggle
// - Refresh orders
// - Accept order → Start cooking
// - Mark ready → Customer notification
// - Mark served
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../widgets/modern_ui_components.dart';
import '../../../../widgets/glass_morphism.dart';
import '../../../../core/theme/futuristic_colors.dart';
import '../../data/models/food_order_model.dart';
import '../../data/repositories/food_order_repository.dart';

class KitchenDisplayScreen extends StatefulWidget {
  final String vendorId;

  const KitchenDisplayScreen({super.key, required this.vendorId});

  @override
  State<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends State<KitchenDisplayScreen> {
  final FoodOrderRepository _orderRepo = FoodOrderRepository();
  bool _soundEnabled = true; // Sound notification toggle state

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? FuturisticColors.darkBackground
          : FuturisticColors.background,
      appBar: _buildPremiumAppBar(context, isDark),
      body: StreamBuilder<List<FoodOrder>>(
        stream: _orderRepo.watchPendingOrders(widget.vendorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  FuturisticColors.primary,
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return _buildEmptyState(isDark);
          }

          // Group orders by status
          final pendingOrders = orders
              .where((o) => o.orderStatus == FoodOrderStatus.pending)
              .toList();
          final cookingOrders = orders
              .where(
                (o) =>
                    o.orderStatus == FoodOrderStatus.accepted ||
                    o.orderStatus == FoodOrderStatus.cooking,
              )
              .toList();
          final readyOrders = orders
              .where((o) => o.orderStatus == FoodOrderStatus.ready)
              .toList();

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // NEW Column
                Expanded(
                  child: _buildOrderColumn(
                    context,
                    'NEW',
                    FuturisticColors.accent1,
                    AppGradients.accentGradient,
                    pendingOrders,
                    isDark,
                    showAcceptButton: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // COOKING Column
                Expanded(
                  child: _buildOrderColumn(
                    context,
                    'COOKING',
                    FuturisticColors.accent2,
                    AppGradients.secondaryGradient,
                    cookingOrders,
                    isDark,
                    showReadyButton: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // READY Column
                Expanded(
                  child: _buildOrderColumn(
                    context,
                    'READY',
                    FuturisticColors.success,
                    AppGradients.primaryGradient,
                    readyOrders,
                    isDark,
                    showServeButton: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    FuturisticColors.darkSurface,
                    FuturisticColors.darkBackground,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: [
                    FuturisticColors.surface,
                    FuturisticColors.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppGradients.primaryGradient,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              boxShadow: AppShadows.glowShadow(FuturisticColors.primary),
            ),
            child: const Icon(
              Icons.soup_kitchen,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Kitchen Display',
            style: AppTypography.headlineMedium.copyWith(
              color: isDark
                  ? FuturisticColors.darkTextPrimary
                  : FuturisticColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        // Sound toggle - PRESERVED FUNCTIONALITY
        _buildAppBarAction(
          icon: _soundEnabled ? Icons.volume_up : Icons.volume_off,
          isActive: _soundEnabled,
          onPressed: () {
            setState(() => _soundEnabled = !_soundEnabled);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_soundEnabled ? 'Sound ON' : 'Sound OFF'),
                duration: const Duration(seconds: 1),
                backgroundColor: FuturisticColors.primary,
              ),
            );
          },
          isDark: isDark,
        ),
        const SizedBox(width: AppSpacing.sm),
        // Refresh - PRESERVED FUNCTIONALITY
        _buildAppBarAction(
          icon: Icons.refresh,
          onPressed: () => setState(() {}),
          isDark: isDark,
        ),
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? FuturisticColors.primary.withOpacity(0.15)
              : (isDark
                    ? FuturisticColors.darkSurfaceVariant
                    : FuturisticColors.surfaceVariant),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isActive
                ? FuturisticColors.primary.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: isActive
              ? FuturisticColors.primary
              : (isDark
                    ? FuturisticColors.darkTextSecondary
                    : FuturisticColors.textSecondary),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        borderRadius: AppBorderRadius.xxl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glowShadow(FuturisticColors.primary),
              ),
              child: const Icon(
                Icons.soup_kitchen_outlined,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No pending orders',
              style: AppTypography.headlineMedium.copyWith(
                color: isDark
                    ? FuturisticColors.darkTextPrimary
                    : FuturisticColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'New orders will appear here automatically',
              style: AppTypography.bodyMedium.copyWith(
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

  Widget _buildOrderColumn(
    BuildContext context,
    String title,
    Color accentColor,
    Gradient headerGradient,
    List<FoodOrder> orders,
    bool isDark, {
    bool showAcceptButton = false,
    bool showReadyButton = false,
    bool showServeButton = false,
  }) {
    return GlassContainer(
      borderRadius: AppBorderRadius.xl,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: headerGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppBorderRadius.xl),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
                  ),
                  child: Text(
                    '${orders.length}',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text(
                      'No orders',
                      style: AppTypography.bodyMedium.copyWith(
                        color: accentColor.withOpacity(0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: orders.length,
                    itemBuilder: (context, index) => _buildOrderCard(
                      orders[index],
                      accentColor,
                      isDark,
                      showAcceptButton: showAcceptButton,
                      showReadyButton: showReadyButton,
                      showServeButton: showServeButton,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    FoodOrder order,
    Color accentColor,
    bool isDark, {
    bool showAcceptButton = false,
    bool showReadyButton = false,
    bool showServeButton = false,
  }) {
    final waitTime = DateTime.now().difference(order.orderTime).inMinutes;
    final isUrgent = waitTime > 15;

    return ModernCard(
      backgroundColor: isDark
          ? FuturisticColors.darkSurface
          : FuturisticColors.surface,
      borderGradient: isUrgent ? AppGradients.accentGradient : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with table number and time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor, accentColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      boxShadow: AppShadows.glowShadow(accentColor),
                    ),
                    child: Text(
                      order.tableNumber ?? 'Takeaway',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (order.orderType == OrderType.takeaway)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Icon(
                        Icons.takeout_dining,
                        size: 16,
                        color: isDark
                            ? FuturisticColors.darkTextSecondary
                            : FuturisticColors.textSecondary,
                      ),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? FuturisticColors.error.withOpacity(0.15)
                      : (isDark
                            ? FuturisticColors.darkSurfaceVariant
                            : FuturisticColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  border: isUrgent
                      ? Border.all(
                          color: FuturisticColors.error.withOpacity(0.5),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: isUrgent
                          ? FuturisticColors.error
                          : FuturisticColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$waitTime min',
                      style: AppTypography.labelSmall.copyWith(
                        color: isUrgent
                            ? FuturisticColors.error
                            : FuturisticColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(
            color: isDark
                ? FuturisticColors.darkDivider
                : FuturisticColors.divider,
            height: 1,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Order items
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: accentColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Center(
                      child: Text(
                        '${item.quantity}',
                        style: AppTypography.labelSmall.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.itemName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? FuturisticColors.darkTextPrimary
                            : FuturisticColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Special instructions
          if (order.specialInstructions?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: FuturisticColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                border: Border.all(
                  color: FuturisticColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes, size: 14, color: FuturisticColors.warning),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      order.specialInstructions!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? FuturisticColors.darkTextPrimary
                            : FuturisticColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Action buttons - PRESERVED FUNCTIONALITY
          if (showAcceptButton)
            _buildActionButton(
              label: 'ACCEPT',
              icon: Icons.check,
              gradient: AppGradients.primaryGradient,
              onPressed: () => _acceptOrder(order.id),
            ),
          if (showReadyButton)
            _buildActionButton(
              label: 'READY',
              icon: Icons.done_all,
              gradient: AppGradients.secondaryGradient,
              onPressed: () => _markReady(order.id),
            ),
          if (showServeButton)
            _buildActionButton(
              label: 'SERVED',
              icon: Icons.room_service,
              gradient: AppGradients.primaryGradient,
              onPressed: () => _markServed(order.id),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return GlassButton(
      label: label,
      icon: icon,
      gradient: gradient,
      onPressed: onPressed,
      borderRadius: AppBorderRadius.md,
    );
  }

  // ============================================================================
  // PRESERVED FUNCTIONALITY - NO CHANGES TO BUSINESS LOGIC
  // ============================================================================

  Future<void> _acceptOrder(String orderId) async {
    await _orderRepo.acceptOrder(orderId);
    await _orderRepo.startCooking(orderId);
    // Play feedback sound
    if (_soundEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🔔 Order accepted - Cooking started!'),
          duration: const Duration(seconds: 2),
          backgroundColor: FuturisticColors.success,
        ),
      );
    }
  }

  Future<void> _markReady(String orderId) async {
    await _orderRepo.markReady(orderId);
    // Customer notification feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Order ready - Customer notified!'),
          duration: const Duration(seconds: 2),
          backgroundColor: FuturisticColors.success,
        ),
      );
    }
  }

  Future<void> _markServed(String orderId) async {
    await _orderRepo.markServed(orderId);
  }
}
