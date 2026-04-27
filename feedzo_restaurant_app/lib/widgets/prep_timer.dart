import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Animated preparation countdown timer for restaurant orders
/// Shows circular progress with remaining time
class PrepTimer extends StatefulWidget {
  final int totalMinutes;
  final int remainingMinutes;
  final VoidCallback? onComplete;
  final VoidCallback? onExtend;

  const PrepTimer({
    super.key,
    required this.totalMinutes,
    required this.remainingMinutes,
    this.onComplete,
    this.onExtend,
  });

  @override
  State<PrepTimer> createState() => _PrepTimerState();
}

class _PrepTimerState extends State<PrepTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.remainingMinutes / widget.totalMinutes;
    final isUrgent = widget.remainingMinutes <= 5;
    final isOverdue = widget.remainingMinutes <= 0;

    final Color ringColor = isOverdue
        ? AppColors.error
        : isUrgent
            ? AppColors.warning
            : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShape.large,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // Circular Progress Timer
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.remainingMinutes}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: ringColor,
                        ),
                      ),
                      const Text(
                        'min',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 16),
          // Timer Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverdue
                      ? 'Overdue!'
                      : isUrgent
                          ? 'Almost Ready!'
                          : 'Preparing Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ringColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Est. time: ${widget.totalMinutes} min total',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Extend Button
          if (widget.onExtend != null && !isOverdue)
            IconButton(
              onPressed: widget.onExtend,
              icon: const Icon(Icons.add_time, color: AppColors.primary),
              tooltip: 'Add 5 min',
            ),
        ],
      ),
    );
  }
}
