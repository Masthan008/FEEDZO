import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import 'order_chat_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Order>(
      stream: FirestoreService.watchOrder(orderId),
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
          return const Scaffold(body: Center(child: Text('Order not found')));
        }
        final order = snapshot.data!;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Order Tracking'),
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text(
                  'Home',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(order),
                  const SizedBox(height: 20),
                // ── OTP Verification Card ──
                if (order.otpCode != null &&
                    (order.status == OrderStatus.outForDelivery ||
                     order.status == OrderStatus.picked))
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.warning.withValues(alpha: 0.1),
                          AppColors.warning.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: AppShape.large,
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
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
                  ),
                if (order.status == OrderStatus.picked ||
                    order.status == OrderStatus.outForDelivery) ...[
                  const Text(
                    'Live Tracking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _LiveMap(order: order),
                  const SizedBox(height: 20),
                ],
                _buildTimeline(order),
                const SizedBox(height: 20),
                _buildOrderSummary(order),
                if (order.status == OrderStatus.placed) ...[
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Cancel Order',
                    onPressed: () => _cancelOrder(context, order.id),
                    color: AppColors.error,
                    width: double.infinity,
                  ),
                ],
                // Chat with driver button
                if (order.driverId != null &&
                    order.status != OrderStatus.delivered &&
                    order.status != OrderStatus.cancelled) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderChatScreen(
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
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppShape.medium),
                      ),
                    ),
                  ),
                ],
                if (order.status == OrderStatus.delivered) ...[
                  const SizedBox(height: 20),
                  _buildSuccessBanner(),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

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
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success,
            AppColors.success.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppShape.xl,
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 40),
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

  Widget _buildStatusCard(Order order) {
    final isDelivered = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCancelled
              ? [AppColors.error, AppColors.error.withValues(alpha: 0.7)]
              : isDelivered
                  ? [
                      AppColors.success,
                      AppColors.success.withValues(alpha: 0.7)
                    ]
                  : [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppShape.xl,
        boxShadow: isCancelled
            ? []
            : [
                BoxShadow(
                  color: (isDelivered ? AppColors.success : AppColors.primary)
                      .withValues(alpha: 0.3),
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
                child: Icon(
                  isCancelled
                      ? Icons.cancel_rounded
                      : isDelivered
                          ? Icons.check_circle_rounded
                          : Icons.delivery_dining_rounded,
                  color: Colors.white,
                  size: 28,
                ),
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
                      isCancelled
                          ? 'Order was cancelled'
                          : isDelivered
                              ? 'Enjoy your meal!'
                              : 'Estimated: 30-40 min',
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: AppShape.small,
            ),
            child: Row(
              children: [
                Text(
                  'Order #${order.id.isNotEmpty ? order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0) : 'N/A'}',
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

  Widget _buildTimeline(Order order) {
    if (order.status == OrderStatus.cancelled) return const SizedBox.shrink();

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
                        color: isDone
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        boxShadow: isCurrent
                            ? AppShadows.primaryGlow(0.3)
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
                          color: isDone && idx < currentIdx
                              ? AppColors.primary
                              : AppColors.divider,
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
                      color: AppColors.primarySurface,
                      borderRadius: AppShape.round,
                    ),
                    child: const Text(
                      'Now',
                      style: TextStyle(
                        color: AppColors.primary,
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
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
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
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${ci.quantity}x',
                      style: const TextStyle(
                        color: AppColors.primary,
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '₹${order.totalAmount.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
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
        // Default to Bangalore coordinates
        final lat = snapshot.data?['lat'] ?? AppConstants.defaultLat;
        final lng = snapshot.data?['lng'] ?? AppConstants.defaultLng;
        final driverPos = LatLng(lat, lng);

        return Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: AppShape.large,
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: AppShape.large,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: driverPos,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.feedzo.customer',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: driverPos,
                      width: 48,
                      height: 48,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.primaryGlow(0.4),
                        ),
                        child: const Icon(
                          Icons.delivery_dining_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
