import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Shimmer loading effect for skeleton placeholders.
/// Wraps children with a shimmering gradient animation.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value + 1, 0),
          colors: [
            AppColors.surfaceVariant,
            AppColors.surfaceVariant.withValues(alpha: 0.3),
            AppColors.surfaceVariant,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.srcATop,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// A single skeleton bone — a rounded rectangle placeholder.
class SkeletonBone extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBone({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton placeholder for a restaurant card.
class RestaurantCardSkeleton extends StatelessWidget {
  const RestaurantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppShape.large,
        ),
        child: Row(
          children: [
            const SkeletonBone(width: 90, height: 90, borderRadius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBone(width: 140, height: 18),
                  const SizedBox(height: 8),
                  const SkeletonBone(width: 100, height: 13),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SkeletonBone(width: 50, height: 13),
                      const SizedBox(width: 12),
                      const SkeletonBone(width: 70, height: 13),
                      const SizedBox(width: 12),
                      const SkeletonBone(width: 40, height: 13),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton list — shows N skeleton cards as loading placeholders.
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => const RestaurantCardSkeleton(),
    );
  }
}

/// Skeleton for order card placeholders.
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppShape.large,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBone(width: 120, height: 16),
                SkeletonBone(width: 60, height: 22, borderRadius: 12),
              ],
            ),
            SizedBox(height: 12),
            SkeletonBone(width: 200, height: 13),
            SizedBox(height: 8),
            SkeletonBone(width: 150, height: 13),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBone(width: 80, height: 14),
                SkeletonBone(width: 100, height: 36, borderRadius: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
