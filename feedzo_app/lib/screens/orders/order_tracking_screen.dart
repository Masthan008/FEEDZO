import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../services/loyalty_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_transitions.dart';
import '../../widgets/order_timeline.dart';
import 'order_chat_screen.dart';
import 'rate_order_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  OrderStatus? _lastStatus;
  bool _pointsCredited = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Order>(
      stream: FirestoreService.watchOrder(widget.orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Order Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text('Order not found',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('This order may have been removed',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }
        final order = snapshot.data!;

        // Credit loyalty points when order is delivered
        if (order.status == OrderStatus.delivered &&
            _lastStatus != OrderStatus.delivered &&
            !_pointsCredited) {
          _pointsCredited = true;
          LoyaltyService.creditPointsOnOrderDelivery(
            customerId: order.customerId,
            orderId: order.id,
            orderAmount: order.totalAmount,
          );
        }
        _lastStatus = order.status;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('Order ${order.id}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text('Home'),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status Header Card ──
                  _buildStatusCard(order),
                  const SizedBox(height: 16),

                  // ── OTP Verification Card ──
                  if (order.otpCode != null &&
                      (order.status == OrderStatus.outForDelivery ||
                          order.status == OrderStatus.picked))
                    _buildOtpCard(order),

                  // ── Live Map (when driver is en route) ──
                  if (order.status == OrderStatus.picked ||
                      order.status == OrderStatus.outForDelivery) ...[
                    _buildSectionTitle('Live Tracking'),
                    const SizedBox(height: 10),
                    _LiveMap(order: order),
                    const SizedBox(height: 16),
                  ],

                  // ── Info banner for placed/preparing orders ──
                  if (order.status == OrderStatus.placed ||
                      order.status == OrderStatus.preparing)
                    _buildInfoBanner(order),

                  // ── Order Status Timeline ──
                  OrderTimeline(
                    status: order.status.toString().split('.').last,
                    placedAt: order.placedAt,
                    confirmedAt: order.confirmedAt,
                    preparingAt: order.preparingAt,
                    pickedUpAt: order.pickedUpAt,
                    deliveredAt: order.deliveredAt,
                  ),
                  const SizedBox(height: 16),

                  // ── Restaurant Details ──
                  _buildRestaurantCard(order),
                  const SizedBox(height: 16),

                  // ── Delivery Address ──
                  _buildDeliveryCard(order),
                  const SizedBox(height: 16),

                  // ── Driver Info ──
                  if (order.driverId != null &&
                      order.status != OrderStatus.delivered &&
                      order.status != OrderStatus.cancelled)
                    _buildDriverCard(context, order),

                  // ── Order Summary & Payment ──
                  _buildOrderSummary(order),
                  const SizedBox(height: 16),

                  // ── Payment Details ──
                  _buildPaymentCard(order),
                  const SizedBox(height: 16),

                  // ── Action Buttons ──
                  if (order.status == OrderStatus.placed) ...[
                    AppButton(
                      label: 'Cancel Order',
                      onPressed: () => _cancelOrder(context, order.id),
                      color: AppColors.error,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Chat with driver button ──
                  if (order.driverId != null &&
                      order.status != OrderStatus.delivered &&
                      order.status != OrderStatus.cancelled) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            AppTransitions.slideUp(OrderChatScreen(
                                orderId: order.id,
                                currentUserId: order.customerId,
                                currentUserRole: 'customer',
                                otherUserName: 'Delivery Partner',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('Chat with Driver'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: AppShape.medium),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Delivered Success Banner ──
                  if (order.status == OrderStatus.delivered) ...[
                    _buildSuccessBanner(),
                    const SizedBox(height: 12),
                    
                    // ── Rate Order Button ──
                    if (order.isRated != true)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(
                              context,
                              AppTransitions.fadeSlide(RateOrderScreen(
                                  orderId: order.id,
                                  restaurantId: order.restaurantId,
                                  restaurantName: order.restaurantName,
                                  driverId: order.driverId,
                                  driverName: order.driverName,
                                  items: order.items.map((ci) => OrderItemRating(
                                    dishId: ci.item.id,
                                    dishName: ci.item.name,
                                    quantity: ci.quantity,
                                  )).toList(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.star_rounded),
                          label: const Text(
                            'Rate Your Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB800),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppShape.medium,
                            ),
                            elevation: 0,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: AppShape.large,
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Thanks for rating!',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],

                  // ── Need Help ──
                  _buildHelpCard(order),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Section Title ──
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  // ── Status Card ──
  Widget _buildStatusCard(Order order) {
    final isDelivered = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;
    final isWaiting = order.status == OrderStatus.placed ||
        order.status == OrderStatus.preparing;

    Color bgColor;
    Color accentColor;
    IconData statusIcon;

    if (isCancelled) {
      bgColor = AppColors.error;
      accentColor = AppColors.error;
      statusIcon = Icons.cancel_rounded;
    } else if (isDelivered) {
      bgColor = const Color(0xFF059669);
      accentColor = AppColors.success;
      statusIcon = Icons.check_circle_rounded;
    } else if (isWaiting) {
      bgColor = const Color(0xFF2563EB); // Blue for waiting
      accentColor = const Color(0xFF3B82F6);
      statusIcon = order.status == OrderStatus.placed
          ? Icons.receipt_long_rounded
          : Icons.restaurant_rounded;
    } else {
      // picked / outForDelivery
      bgColor = const Color(0xFF7C3AED); // Purple for in transit
      accentColor = const Color(0xFF8B5CF6);
      statusIcon = Icons.delivery_dining_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppShape.xl,
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusSubtitle(order),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: AppShape.small,
            ),
            child: Row(
              children: [
                Text(
                  'Order ID: ${order.id}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  order.restaurantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusSubtitle(Order order) {
    switch (order.status) {
      case OrderStatus.placed:
        return 'Waiting for restaurant to accept';
      case OrderStatus.preparing:
        return 'Restaurant is preparing your food';
      case OrderStatus.ready:
        return 'Food is ready for pickup';
      case OrderStatus.picked:
      case OrderStatus.outForDelivery:
        return 'Driver is on the way to you';
      case OrderStatus.delivered:
        return 'Enjoy your meal! 🎉';
      case OrderStatus.cancelled:
        return order.cancellationReason ?? 'Order was cancelled';
    }
  }

  // ── OTP Card ──
  Widget _buildOtpCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.1),
            AppColors.warning.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: AppShape.large,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pin_rounded,
                color: AppColors.warning, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery OTP',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.otpCode!,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.shield_rounded,
              color: AppColors.warning, size: 20),
        ],
      ),
    );
  }

  // ── Info Banner ──
  Widget _buildInfoBanner(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // light blue
        borderRadius: AppShape.large,
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              order.status == OrderStatus.placed
                  ? 'Waiting for the restaurant to confirm your order. Live tracking and chat will be available once a driver is assigned.'
                  : 'Restaurant is preparing your food. A driver will be assigned shortly.',
              style: const TextStyle(
                color: Color(0xFF1E40AF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Restaurant Card ──
  Widget _buildRestaurantCard(Order order) {
    return _buildCard(
      title: 'Restaurant',
      icon: Icons.restaurant_rounded,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppShape.small,
            child: Image.network(
              order.restaurantImage,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppShape.small,
                ),
                child: const Icon(Icons.restaurant,
                    color: AppColors.textHint),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.restaurantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.items.length} item${order.items.length > 1 ? 's' : ''} • ₹${order.totalAmount.toInt()}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Delivery Address Card ──
  Widget _buildDeliveryCard(Order order) {
    return _buildCard(
      title: 'Delivery Address',
      icon: Icons.location_on_outlined,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (order.deliveryInstructions != null &&
                    order.deliveryInstructions!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Note: ${order.deliveryInstructions}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Driver Card ──
  Widget _buildDriverCard(BuildContext context, Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShape.large,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.delivery_dining_rounded,
                  size: 18, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'Delivery Partner',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                child: Text(
                  (order.driverName ?? 'D')[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.driverName ?? 'Driver',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (order.driverPhone != null)
                      Text(
                        order.driverPhone!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (order.driverPhone != null)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.phone_rounded,
                        color: AppColors.accent, size: 20),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // Could add url_launcher call here
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Payment Card ──
  Widget _buildPaymentCard(Order order) {
    return _buildCard(
      title: 'Payment',
      icon: Icons.payment_rounded,
      child: Column(
        children: [
          _paymentRow('Subtotal',
              '₹${order.subtotal.toStringAsFixed(0)}'),
          if (order.deliveryFee > 0)
            _paymentRow('Delivery Fee',
                '₹${order.deliveryFee.toStringAsFixed(0)}'),
          if (order.deliveryFee == 0)
            _paymentRow('Delivery Fee', 'FREE', isHighlight: true),
          if (order.taxAmount > 0)
            _paymentRow(
                'Taxes', '₹${order.taxAmount.toStringAsFixed(0)}'),
          if (order.discount > 0)
            _paymentRow('Discount',
                '-₹${order.discount.toStringAsFixed(0)}',
                isHighlight: true),
          if (order.tipAmount > 0)
            _paymentRow(
                'Tip', '₹${order.tipAmount.toStringAsFixed(0)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Paid',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                '₹${order.totalAmount.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: order.paymentType == 'cod'
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.accent.withValues(alpha: 0.1),
              borderRadius: AppShape.small,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  order.paymentType == 'cod'
                      ? Icons.money_rounded
                      : Icons.account_balance_wallet_rounded,
                  size: 14,
                  color: order.paymentType == 'cod'
                      ? AppColors.warning
                      : AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  order.paymentType == 'cod'
                      ? 'Cash on Delivery'
                      : 'Paid Online',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: order.paymentType == 'cod'
                        ? AppColors.warning
                        : AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
                color: isHighlight
                    ? const Color(0xFF059669)
                    : AppColors.textPrimary,
              )),
        ],
      ),
    );
  }

  // ── Help Card ──
  Widget _buildHelpCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShape.large,
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.headset_mic_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Contact support for any issues with your order',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textHint),
        ],
      ),
    );
  }

  // ── Shared Card Builder ──
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ── Cancel Order ──
  Future<void> _cancelOrder(BuildContext context, String orderId) async {
    HapticFeedback.heavyImpact();

    final reasons = [
      'Changed my mind',
      'Found a better price',
      'Order placed by mistake',
      'Delivery time too long',
      'Restaurant too far',
      'Other',
    ];

    String? selectedReason;
    final customCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cancel_rounded, color: AppColors.error, size: 24),
              SizedBox(width: 10),
              Text('Cancel Order'),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please let us know why you want to cancel:',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ...reasons.map(
                  (r) => RadioListTile<String>(
                    title: Text(r, style: const TextStyle(fontSize: 14)),
                    value: r,
                    groupValue: selectedReason,
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) =>
                        setDialogState(() => selectedReason = v),
                  ),
                ),
                if (selectedReason == 'Other') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tell us more...',
                      hintStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: AppShape.small,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Order'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text('Cancel Order'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedReason != null) {
      final reason = selectedReason == 'Other'
          ? (customCtrl.text.trim().isNotEmpty
              ? customCtrl.text.trim()
              : 'Other')
          : selectedReason!;
      await FirestoreService.cancelOrder(orderId, reason: reason);
    }
  }

  // ── Success Banner ──
  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppShape.xl,
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 40),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Delivered!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enjoy your meal! 🎉',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline ──
  Widget _buildTimeline(Order order) {
    if (order.status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.05),
          borderRadius: AppShape.large,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded,
                color: AppColors.error, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Cancelled',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.error,
                    ),
                  ),
                  if (order.cancellationReason != null)
                    Text(
                      order.cancellationReason!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final steps = [
      {
        'status': OrderStatus.placed,
        'label': 'Order Placed',
        'sub': 'We received your order',
        'icon': Icons.receipt_long_rounded,
      },
      {
        'status': OrderStatus.preparing,
        'label': 'Preparing',
        'sub': 'Restaurant is cooking',
        'icon': Icons.restaurant_rounded,
      },
      {
        'status': OrderStatus.picked,
        'label': 'Picked Up',
        'sub': 'On the way to you',
        'icon': Icons.delivery_dining_rounded,
      },
      {
        'status': OrderStatus.delivered,
        'label': 'Delivered',
        'sub': 'Enjoy your meal!',
        'icon': Icons.check_circle_rounded,
      },
    ];

    final currentIdx =
        steps.indexWhere((s) => s['status'] == order.status);

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
            'Order Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) {
            final idx = e.key;
            final step = e.value;
            final isDone = idx <= currentIdx;
            final isCurrent = idx == currentIdx;
            final isLast = idx == steps.length - 1;

            // Use blue for the completed/current step dots instead of green
            final dotColor = isDone
                ? const Color(0xFF2563EB)
                : AppColors.surfaceVariant;
            final lineColor = isDone && idx < currentIdx
                ? const Color(0xFF2563EB)
                : AppColors.divider;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: AppConstants.animSlow,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        color:
                            isDone ? Colors.white : AppColors.textHint,
                        size: 18,
                      ),
                    ),
                    if (!isLast)
                      AnimatedContainer(
                        duration: AppConstants.animSlow,
                        width: 2.5,
                        height: 36,
                        decoration: BoxDecoration(
                          color: lineColor,
                          borderRadius: AppShape.round,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 8, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['label'] as String,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isDone
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          step['sub'] as String,
                          style: TextStyle(
                            color: isDone
                                ? AppColors.textSecondary
                                : AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: AppShape.round,
                    ),
                    child: const Text(
                      'Now',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Order Summary ──
  Widget _buildOrderSummary(Order order) {
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
          const Row(
            children: [
              Icon(Icons.shopping_bag_outlined,
                  size: 18, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.map(
            (ci) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${ci.quantity}x',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ci.item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '₹${ci.total.toInt()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live Map with Real-time Driver Location ───────────────────────────────────
class _LiveMap extends StatelessWidget {
  final Order order;
  const _LiveMap({required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.driverId == null || order.driverId!.isEmpty) {
      return const SizedBox(height: 20);
    }
    return StreamBuilder<Map<String, double>?>(
      stream: FirestoreService.watchDriverLocation(order.driverId!),
      builder: (context, snapshot) {
        final hasLocation = snapshot.hasData && snapshot.data != null;

        return Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppShape.large,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.delivery_dining_rounded,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delivery_dining_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Driver En Route',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasLocation
                                    ? 'Location updating in real-time'
                                    : 'Waiting for driver location...',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Live indicator
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: hasLocation
                                ? const Color(0xFF4ADE80)
                                : Colors.white38,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasLocation ? 'LIVE TRACKING' : 'CONNECTING...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

