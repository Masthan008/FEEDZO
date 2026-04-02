import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/order_model.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  const OrderStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case OrderStatus.placed:
        return AppColors.statusPending;
      case OrderStatus.preparing:
        return AppColors.statusPreparing;
      case OrderStatus.ready:
        return AppColors.statusReady;
      case OrderStatus.picked:
      case OrderStatus.outForDelivery:
        return AppColors.statusPicked;
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  Color get _bgColor {
    switch (status) {
      case OrderStatus.placed:
        return AppColors.statusPendingBg;
      case OrderStatus.preparing:
        return AppColors.statusPreparingBg;
      case OrderStatus.ready:
        return AppColors.statusReadyBg;
      case OrderStatus.picked:
      case OrderStatus.outForDelivery:
        return AppColors.statusPickedBg;
      case OrderStatus.delivered:
        return AppColors.statusDeliveredBg;
      case OrderStatus.cancelled:
        return AppColors.statusCancelledBg;
    }
  }

  IconData get _icon {
    switch (status) {
      case OrderStatus.placed:
        return Icons.schedule_rounded;
      case OrderStatus.preparing:
        return Icons.restaurant_rounded;
      case OrderStatus.ready:
        return Icons.takeout_dining_rounded;
      case OrderStatus.picked:
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining_rounded;
      case OrderStatus.delivered:
        return Icons.check_circle_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String get _label {
    switch (status) {
      case OrderStatus.placed:
        return 'New';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.picked:
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: AppShape.round,
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 13, color: _color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
