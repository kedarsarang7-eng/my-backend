import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/futuristic_colors.dart';

/// Premium Tax Summary Panel with glassmorphism effects.
/// Calculates and displays tax data from real monthly bills.
class TaxSummaryPanel extends StatelessWidget {
  final List<BillEntity> monthlyBills;

  const TaxSummaryPanel({super.key, required this.monthlyBills});

  @override
  Widget build(BuildContext context) {
    // Calculate tax metrics from real data
    double totalTax = 0;
    double taxableValue = 0;
    double nonTaxableValue = 0;

    for (var bill in monthlyBills) {
      if (bill.taxAmount > 0) {
        totalTax += bill.taxAmount;
        taxableValue += bill.subtotal;
      } else {
        nonTaxableValue += bill.subtotal;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
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
            color: FuturisticColors.success.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tax Summary",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: FuturisticColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: FuturisticColors.success.withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  "This Month",
                  style: TextStyle(
                    color: FuturisticColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Total Output Tax - Large primary metric
          _buildPrimaryMetric(
            label: "Total Output Tax",
            value: totalTax,
            color: FuturisticColors.success,
          ),

          const SizedBox(height: 24),

          // Divider with subtle styling
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Secondary metrics
          _buildSecondaryMetric(
            label: "Taxable Sales",
            value: taxableValue,
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 16),
          _buildSecondaryMetric(
            label: "Non-Taxable Sales",
            value: nonTaxableValue,
            icon: Icons.receipt_outlined,
          ),

          const Spacer(),

          // Info footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FuturisticColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: FuturisticColors.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: FuturisticColors.primary.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${monthlyBills.length} invoices this month",
                    style: TextStyle(
                      color: FuturisticColors.textSecondary.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryMetric({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FuturisticColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "₹${_formatNumber(value)}",
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(color: color.withOpacity(0.3), blurRadius: 10),
                ],
              ),
            ),
            if (value > 0)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 6),
                child: Icon(
                  Icons.trending_up,
                  color: color.withOpacity(0.7),
                  size: 20,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryMetric({
    required String label,
    required double value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: FuturisticColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: FuturisticColors.primary.withOpacity(0.8),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: FuturisticColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          "₹${_formatNumber(value)}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)}L';
    } else if (value >= 1000) {
      return value
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
    return value.toStringAsFixed(2);
  }
}
