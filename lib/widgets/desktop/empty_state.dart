import 'package:flutter/material.dart';
import '../../core/theme/futuristic_colors.dart';
import '../../widgets/desktop/enterprise_button.dart';

/// Premium Empty State Widget
///
/// A futuristic empty state component with:
/// - Icon with neon glow effect
/// - Glass card background
/// - Primary CTA button
/// - Optional secondary action
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryButtonPressed;
  final Color? accentColor;
  final double maxWidth;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonLabel,
    this.onButtonPressed,
    this.secondaryButtonLabel,
    this.onSecondaryButtonPressed,
    this.accentColor,
    this.maxWidth = 400,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? FuturisticColors.premiumBlue;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: FuturisticColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with glow
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: color,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: FuturisticColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              if (buttonLabel != null && onButtonPressed != null) ...[
                const SizedBox(height: 28),
                EnterpriseButton.primary(
                  label: buttonLabel!,
                  onPressed: onButtonPressed!,
                  icon: Icons.add_rounded,
                ),
              ],

              // Secondary Button
              if (secondaryButtonLabel != null &&
                  onSecondaryButtonPressed != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onSecondaryButtonPressed,
                  child: Text(
                    secondaryButtonLabel!,
                    style: TextStyle(
                      color: FuturisticColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact Empty State for tables/lists
class CompactEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;

  const CompactEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? FuturisticColors.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: accentColor.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: FuturisticColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onAction,
                icon: Icon(Icons.add,
                    size: 18, color: FuturisticColors.premiumBlue),
                label: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: FuturisticColors.premiumBlue,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
