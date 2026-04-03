import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// A reusable empty state widget with icon, title, subtitle, and optional action.
/// Use this when a list/section has no data to display.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  // ── Named constructors for common empty states ──

  /// Empty orders state
  const EmptyState.orders({super.key, this.onAction})
      : icon = Icons.receipt_long_rounded,
        title = 'No orders yet',
        subtitle = 'Your order history will appear here',
        actionLabel = 'Browse Restaurants',
        iconColor = null;

  /// Empty search results
  const EmptyState.search({super.key})
      : icon = Icons.search_off_rounded,
        title = 'No results found',
        subtitle = 'Try different keywords or filters',
        actionLabel = null,
        onAction = null,
        iconColor = null;

  /// Empty favorites
  const EmptyState.favorites({super.key})
      : icon = Icons.favorite_outline_rounded,
        title = 'No favorites yet',
        subtitle = 'Tap the heart icon to save your favorites',
        actionLabel = null,
        onAction = null,
        iconColor = const Color(0xFFEC4899);

  /// Empty cart
  const EmptyState.cart({super.key, this.onAction})
      : icon = Icons.shopping_cart_outlined,
        title = 'Your cart is empty',
        subtitle = 'Add items from a restaurant to get started',
        actionLabel = 'Browse Restaurants',
        iconColor = null;

  /// Empty notifications
  const EmptyState.notifications({super.key})
      : icon = Icons.notifications_off_rounded,
        title = 'No notifications',
        subtitle = 'We\'ll let you know when something happens',
        actionLabel = null,
        onAction = null,
        iconColor = null;

  /// Empty chat
  const EmptyState.chat({super.key})
      : icon = Icons.chat_bubble_outline_rounded,
        title = 'No messages yet',
        subtitle = 'Start a conversation',
        actionLabel = null,
        onAction = null,
        iconColor = null;

  /// Network error
  const EmptyState.error({super.key, this.onAction})
      : icon = Icons.wifi_off_rounded,
        title = 'Something went wrong',
        subtitle = 'Please check your connection and try again',
        actionLabel = 'Retry',
        iconColor = const Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary)
                      .withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 52,
                  color: (iconColor ?? AppColors.primary)
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              ),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (_, value, child) => Opacity(
                  opacity: value,
                  child: child,
                ),
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppShape.medium),
                    elevation: 0,
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
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
