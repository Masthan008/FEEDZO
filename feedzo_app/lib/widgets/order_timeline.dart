import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Visual order timeline stepper showing order progress
/// Steps: Placed → Confirmed → Preparing → Picked Up → Delivered
class OrderTimeline extends StatelessWidget {
  final String status;
  final DateTime? placedAt;
  final DateTime? confirmedAt;
  final DateTime? preparingAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  const OrderTimeline({
    super.key,
    required this.status,
    this.placedAt,
    this.confirmedAt,
    this.preparingAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    final currentIndex = _getCurrentStepIndex();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShape.large,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isActive = index <= currentIndex;
            final isCurrent = index == currentIndex;
            final showConnector = index < steps.length - 1;

            return _TimelineStep(
              icon: step.icon,
              title: step.title,
              subtitle: step.time,
              isActive: isActive,
              isCurrent: isCurrent,
              showConnector: showConnector,
            );
          }),
        ],
      ),
    );
  }

  List<_StepData> _buildSteps() {
    return [
      _StepData(
        icon: Icons.receipt_outlined,
        title: 'Order Placed',
        time: placedAt != null ? _formatTime(placedAt!) : 'Pending',
      ),
      _StepData(
        icon: Icons.check_circle_outline,
        title: 'Confirmed',
        time: confirmedAt != null ? _formatTime(confirmedAt!) : 'Pending',
      ),
      _StepData(
        icon: Icons.restaurant_outlined,
        title: 'Preparing',
        time: preparingAt != null ? _formatTime(preparingAt!) : 'Pending',
      ),
      _StepData(
        icon: Icons.delivery_dining_outlined,
        title: 'Picked Up',
        time: pickedUpAt != null ? _formatTime(pickedUpAt!) : 'Pending',
      ),
      _StepData(
        icon: Icons.home_outlined,
        title: 'Delivered',
        time: deliveredAt != null ? _formatTime(deliveredAt!) : 'Pending',
      ),
    ];
  }

  int _getCurrentStepIndex() {
    switch (status.toLowerCase()) {
      case 'placed':
        return 0;
      case 'confirmed':
        return 1;
      case 'preparing':
      case 'ready':
        return 2;
      case 'picked_up':
      case 'out_for_delivery':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _StepData {
  final IconData icon;
  final String title;
  final String time;

  _StepData({required this.icon, required this.title, required this.time});
}

class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isCurrent;
  final bool showConnector;

  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isCurrent,
    required this.showConnector,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive ? AppColors.primary : AppColors.textHint;
    final bgColor = isCurrent
        ? AppColors.primary.withValues(alpha: 0.1)
        : isActive
            ? AppColors.surfaceVariant
            : AppColors.surfaceVariant.withValues(alpha: 0.5);
    final titleColor = isActive ? AppColors.textPrimary : AppColors.textHint;
    final subtitleColor = isActive ? AppColors.textSecondary : AppColors.textHint;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isActive ? AppColors.primary : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
