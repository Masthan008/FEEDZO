import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/models.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label;
    switch (status) {
      case OrderStatus.pending:
        color = AppColors.statusPending; bg = AppColors.statusPendingBg; label = 'Pending';
      case OrderStatus.preparing:
        color = AppColors.statusPreparing; bg = AppColors.statusPreparingBg; label = 'Preparing';
      case OrderStatus.outForDelivery:
        color = AppColors.info; bg = const Color(0xFFDBEAFE); label = 'Out for Delivery';
      case OrderStatus.delivered:
        color = AppColors.statusDelivered; bg = AppColors.statusDeliveredBg; label = 'Delivered';
      case OrderStatus.cancelled:
        color = AppColors.statusCancelled; bg = AppColors.statusCancelledBg; label = 'Cancelled';
    }
    return _Badge(label: label, color: color, bg: bg);
  }
}

class DriverStatusBadge extends StatelessWidget {
  final DriverStatus status;
  const DriverStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label;
    switch (status) {
      case DriverStatus.available:
        color = AppColors.statusDelivered; bg = AppColors.statusDeliveredBg; label = 'Available';
      case DriverStatus.busy:
        color = AppColors.statusPreparing; bg = AppColors.statusPreparingBg; label = 'Busy';
      case DriverStatus.multiOrder:
        color = AppColors.warning; bg = const Color(0xFFFEF3C7); label = 'Multi-Order';
      case DriverStatus.offline:
        color = AppColors.textSecondary; bg = const Color(0xFFF3F4F6); label = 'Offline';
    }
    return _Badge(label: label, color: color, bg: bg);
  }
}

class AlertSeverityBadge extends StatelessWidget {
  final AlertSeverity severity;
  const AlertSeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label;
    switch (severity) {
      case AlertSeverity.high:
        color = AppColors.error; bg = AppColors.statusCancelledBg; label = 'High';
      case AlertSeverity.medium:
        color = AppColors.warning; bg = AppColors.statusPendingBg; label = 'Medium';
      case AlertSeverity.low:
        color = AppColors.info; bg = const Color(0xFFDBEAFE); label = 'Low';
    }
    return _Badge(label: label, color: color, bg: bg);
  }
}

class UserStatusBadge extends StatelessWidget {
  final UserStatus status;
  const UserStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status == UserStatus.active;
    return _Badge(
      label: active ? 'Active' : 'Blocked',
      color: active ? AppColors.statusDelivered : AppColors.statusCancelled,
      bg: active ? AppColors.statusDeliveredBg : AppColors.statusCancelledBg,
    );
  }
}

class RestaurantStatusBadge extends StatelessWidget {
  final RestaurantStatus status;
  const RestaurantStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label;
    switch (status) {
      case RestaurantStatus.active:
        color = AppColors.statusDelivered; bg = AppColors.statusDeliveredBg; label = 'Active';
      case RestaurantStatus.disabled:
        color = AppColors.statusCancelled; bg = AppColors.statusCancelledBg; label = 'Disabled';
      case RestaurantStatus.pendingApproval:
        color = AppColors.statusPending; bg = AppColors.statusPendingBg; label = 'Pending';
    }
    return _Badge(label: label, color: color, bg: bg);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
