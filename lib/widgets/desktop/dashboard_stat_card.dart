import 'package:flutter/material.dart';
import '../../core/theme/futuristic_colors.dart';

/// Premium Dashboard Stat Card with glassmorphism and neon glow effects.
/// Matches the futuristic enterprise design from reference screenshots.
class DashboardStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool isPositive;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isPositive = true,
  });

  @override
  State<DashboardStatCard> createState() => _DashboardStatCardState();
}

class _DashboardStatCardState extends State<DashboardStatCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Premium glassmorphism background with subtle texture
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              theme.cardColor.withOpacity(0.85),
              theme.cardColor.withOpacity(0.75),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          // Premium blue accent border with glow
          border: Border.all(
            color: _isHovered
                ? FuturisticColors.premiumBlue.withOpacity(0.5)
                : FuturisticColors.premiumBlue.withOpacity(0.2),
            width: 1,
          ),
          // Premium shadow with colored glow
          boxShadow: [
            // Premium blue glow effect
            BoxShadow(
              color: FuturisticColors.premiumBlue.withOpacity(
                _isHovered ? 0.15 : 0.08,
              ),
              blurRadius: _isHovered ? 20 : 12,
              spreadRadius: _isHovered ? 2 : 0,
              offset: const Offset(0, 2),
            ),
            // Card color glow effect
            BoxShadow(
              color: widget.color.withOpacity(_isHovered ? 0.2 : 0.1),
              blurRadius: _isHovered ? 24 : 16,
              spreadRadius: _isHovered ? 2 : 0,
              offset: const Offset(0, 4),
            ),
            // Standard depth shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon with gradient background and glow
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.color.withOpacity(0.2),
                        widget.color.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.color.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 24),
                ),
                // Trend badge (if provided)
                if (widget.trend != null) _buildTrendBadge(),
              ],
            ),
            const SizedBox(height: 16),
            // Value and Title section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large value with subtle text shadow
                Text(
                  widget.value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Title with proper hierarchy
                Text(
                  widget.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.hintColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendBadge() {
    final isPositive = widget.isPositive;
    final badgeColor = isPositive
        ? FuturisticColors.success
        : FuturisticColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [badgeColor.withOpacity(0.2), badgeColor.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: badgeColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            widget.trend!,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
