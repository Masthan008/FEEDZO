import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../data/models/restaurant_model.dart';

class RestaurantCard extends StatefulWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  final bool isTrending;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.isTrending = false,
  });

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: AppConstants.animFast,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleCtrl.forward();
  void _onTapUp(TapUpDetails _) => _scaleCtrl.reverse();
  void _onTapCancel() => _scaleCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final imageHeight =
        widget.isTrending ? AppConstants.trendingImageHeight : AppConstants.restaurantImageHeight;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingLg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppShape.large,
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image Section ──
              Stack(
                children: [
                  Hero(
                    tag: 'restaurant_image_${r.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppShape.radiusLarge)),
                      child: r.firstImage.isEmpty
                          ? _ImagePlaceholder(height: imageHeight)
                          : CachedNetworkImage(
                              imageUrl: r.firstImage,
                              height: imageHeight,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _ImagePlaceholder(height: imageHeight),
                              errorWidget: (_, __, ___) => _ImageError(height: imageHeight),
                            ),
                    ),
                  ),
                  // Closed overlay
                  if (!r.isOpen)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppShape.radiusLarge)),
                        child: Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Text(
                              'CLOSED',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Top-Left Offer Badge
                  Positioned(
                    top: 12,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        r.tags.isNotEmpty ? r.tags.first.toUpperCase() : '20% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom-Left Rating Badge (overlaid on image)
                  Positioned(
                    bottom: 8,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: r.rating >= 4.0 ? Colors.green.shade600 : Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${r.rating}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // ── Info Section ──
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.bolt, color: Colors.green.shade600, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          '${r.deliveryTime - 5}-${r.deliveryTime + 5} mins',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (r.deliveryFee == 0) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FREE DELIVERY',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tag Widget ────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    final isAI = label == 'AI Pick';
    final isTrending = label == 'Trending';
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: isAI
            ? const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientAccent])
            : null,
        color: isAI
            ? null
            : isTrending
                ? AppColors.warning
                : Colors.black87,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAI) ...[
            const Icon(Icons.auto_awesome, color: Colors.white, size: 10),
            const SizedBox(width: 3),
          ],
          if (isTrending) ...[
            const Icon(Icons.trending_up_rounded,
                color: Colors.white, size: 10),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image Placeholder ─────────────────────────────────────────────────────────
class _ImagePlaceholder extends StatelessWidget {
  final double height;
  const _ImagePlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppShape.radiusLarge)),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  final double height;
  const _ImageError({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppShape.radiusLarge)),
      ),
      child: const Center(
        child: Icon(Icons.restaurant, size: 48, color: AppColors.textHint),
      ),
    );
  }
}
