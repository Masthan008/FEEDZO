import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'app_transitions.dart';

/// Animated stat card with count-up animation
/// Usage: Dashboard stats, earnings displays, order counts
class AnimatedStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final String? prefix;
  final String? suffix;
  final int decimalPlaces;
  final Color? iconColor;
  final Color? valueColor;
  final String? trend;
  final bool? trendUp;
  final VoidCallback? onTap;

  const AnimatedStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
    this.iconColor,
    this.valueColor,
    this.trend,
    this.trendUp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppShape.large,
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: AppShape.medium,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.primary,
                    size: 24,
                  ),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (trendUp == true ? Colors.green : Colors.red)
                          .withValues(alpha: 0.1),
                      borderRadius: AppShape.small,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendUp == true ? Icons.trending_up : Icons.trending_down,
                          color: trendUp == true ? Colors.green : Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trend!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: trendUp == true ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedCounter(
              target: value,
              prefix: prefix,
              suffix: suffix,
              decimalPlaces: decimalPlaces,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
