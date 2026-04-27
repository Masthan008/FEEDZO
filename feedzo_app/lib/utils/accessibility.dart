import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Accessibility helpers for screen readers and semantic labels
/// 
/// Usage:
/// ```dart
/// Semantics(
///   label: SemanticLabels.restaurantCard(name: 'Pizza Hut'),
///   child: RestaurantCard(...),
/// )
/// ```
class SemanticLabels {
  // Navigation
  static String get home => 'Home tab';
  static String get search => 'Search tab';
  static String get orders => 'Orders tab';
  static String get profile => 'Profile tab';
  static String get cart => 'Cart';

  // Restaurant
  static String restaurantCard({required String name, double? rating, String? cuisine}) {
    var label = 'Restaurant: $name';
    if (rating != null) label += ', Rating: $rating stars';
    if (cuisine != null) label += ', Cuisine: $cuisine';
    return label;
  }

  static String menuItem({required String name, required double price, String? description}) {
    var label = 'Menu item: $name, Price: ₹$price';
    if (description != null) label += ', $description';
    return label;
  }

  // Orders
  static String orderCard({required String status, required double amount}) {
    return 'Order status: $status, Total: ₹$amount';
  }

  static String orderTimelineStep({required String step, required bool isComplete}) {
    return '$step: ${isComplete ? "Completed" : "Pending"}';
  }

  // Actions
  static String get addToCart => 'Add to cart';
  static String get removeFromCart => 'Remove from cart';
  static String get placeOrder => 'Place order';
  static String get backButton => 'Go back';
  static String get closeButton => 'Close';
  static String get searchField => 'Search field';
  static String get clearSearch => 'Clear search';
}

/// Haptic feedback utilities
/// Provides tactile feedback for interactions
class Haptics {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void selection() => HapticFeedback.selectionClick();
  static void success() => HapticFeedback.mediumImpact();
  static void error() => HapticFeedback.heavyImpact();
}

/// Accessible button wrapper
/// Ensures minimum touch target size (48x48) and proper semantics
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;
  final EdgeInsets? padding;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: padding ?? const EdgeInsets.all(12),
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Accessible icon button
/// Combines IconButton with proper semantics and haptic feedback
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final Color? color;
  final double size;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton(
        icon: Icon(icon, size: size),
        color: color,
        onPressed: () {
          Haptics.light();
          onPressed();
        },
        tooltip: semanticLabel,
      ),
    );
  }
}

/// Repaint boundary wrapper for performance optimization
/// Reduces unnecessary repaints in static content
class OptimizedRepaint extends StatelessWidget {
  final Widget child;

  const OptimizedRepaint({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}
