import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/theme/futuristic_colors.dart';

/// Premium Revenue Analytics Chart with gradient bars and glassmorphism.
/// Shows real sales trend data with enhanced visual effects.
class RevenueAnalyticsChart extends StatefulWidget {
  final Map<String, double> data; // e.g., {"Mon": 5000, "Tue": 7000}

  const RevenueAnalyticsChart({super.key, required this.data});

  @override
  State<RevenueAnalyticsChart> createState() => _RevenueAnalyticsChartState();
}

class _RevenueAnalyticsChartState extends State<RevenueAnalyticsChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // Empty state with premium styling
    if (widget.data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _buildCardDecoration(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 64,
                color: FuturisticColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                "No Data",
                style: TextStyle(
                  color: FuturisticColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Create invoices to see revenue trends",
                style: TextStyle(
                  color: FuturisticColors.textSecondary.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final keys = widget.data.keys.toList();
    final values = widget.data.values.toList();
    final maxY = values.reduce((curr, next) => curr > next ? curr : next);
    final totalRevenue = values.fold(0.0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Revenue Analytics",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Last ${widget.data.length} Days",
                    style: const TextStyle(
                      color: FuturisticColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              // Total revenue badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      FuturisticColors.primary.withOpacity(0.2),
                      FuturisticColors.accent1.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: FuturisticColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      "₹${_formatNumber(totalRevenue)}",
                      style: const TextStyle(
                        color: FuturisticColors.accent1,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Total",
                      style: TextStyle(
                        color: FuturisticColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Chart
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.25,
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (response?.spot != null &&
                          event is! PointerUpEvent &&
                          event is! PointerExitEvent) {
                        touchedIndex = response!.spot!.touchedBarGroupIndex;
                      } else {
                        touchedIndex = -1;
                      }
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => FuturisticColors.surfaceElevated,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${_formatNumber(rod.toY)}',
                        const TextStyle(
                          color: FuturisticColors.accent1,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < keys.length) {
                          final isTouched = value.toInt() == touchedIndex;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              keys[value.toInt()],
                              style: TextStyle(
                                color: isTouched
                                    ? FuturisticColors.accent1
                                    : FuturisticColors.textSecondary,
                                fontSize: 11,
                                fontWeight: isTouched
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '₹${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(
                              color: FuturisticColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.05),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  widget.data.length,
                  (index) {
                    final isTouched = index == touchedIndex;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: isTouched ? values[index] * 1.02 : values[index],
                          gradient: LinearGradient(
                            colors: isTouched
                                ? [
                                    FuturisticColors.accent1,
                                    FuturisticColors.primary,
                                  ]
                                : [
                                    FuturisticColors.primary,
                                    FuturisticColors.accent1.withOpacity(0.7),
                                  ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: isTouched ? 20 : 16,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY * 1.25,
                            color: Colors.white.withOpacity(0.03),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          FuturisticColors.surface,
          FuturisticColors.surface.withOpacity(0.85),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: FuturisticColors.premiumBlue.withOpacity(0.2),
      ),
      boxShadow: [
        // Premium blue glow
        BoxShadow(
          color: FuturisticColors.premiumBlue.withOpacity(0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: FuturisticColors.primary.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
