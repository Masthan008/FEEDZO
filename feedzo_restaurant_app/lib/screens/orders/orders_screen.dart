import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/prep_timer.dart';
import 'order_detail_screen.dart';
import 'driver_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<OrderModel> _filtered(List<OrderModel> orders, int tab) {
    switch (tab) {
      case 1:
        return orders.where((o) => o.status == OrderStatus.placed).toList();
      case 2:
        return orders
            .where(
              (o) =>
                  o.status == OrderStatus.preparing ||
                  o.status == OrderStatus.ready ||
                  o.status == OrderStatus.picked ||
                  o.status == OrderStatus.outForDelivery,
            )
            .toList();
      case 3:
        return orders
            .where(
              (o) =>
                  o.status == OrderStatus.delivered ||
                  o.status == OrderStatus.cancelled,
            )
            .toList();
      default:
        return orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;
    final pendingCount =
        orders.where((o) => o.status == OrderStatus.placed).length;
    final activeCount = orders
        .where(
          (o) =>
              o.status == OrderStatus.preparing ||
              o.status == OrderStatus.ready ||
              o.status == OrderStatus.picked ||
              o.status == OrderStatus.outForDelivery,
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            const Tab(text: 'All'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: AppShape.round,
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Active'),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        borderRadius: AppShape.round,
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Done'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(4, (tab) {
          final list = _filtered(orders, tab);
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_outlined,
                      size: 40,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No orders here',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Orders matching this filter will appear here',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _OrderCard(order: list[i]),
          );
        }),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  void _showAcceptDialog(
    BuildContext context,
    OrderProvider provider,
    String orderId,
  ) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppShape.round,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Accept Order',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select estimated preparation time',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [10, 20, 30, 45]
                  .map(
                    (time) => GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        provider.acceptOrder(orderId, time);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 72,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientEnd,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: AppShape.large,
                          boxShadow: AppShadows.primaryGlow(0.2),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$time',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                            const Text(
                              'mins',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OrderProvider>();
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppShape.large,
          border: Border.all(
            color: order.status == OrderStatus.placed
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
          ),
          boxShadow: order.status == OrderStatus.placed
              ? AppShadows.primaryGlow(0.08)
              : AppShadows.subtle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 12),

              // Prep timer widget
              if (order.status == OrderStatus.preparing &&
                  order.prepTime != null) ...[
                PrepTimer(
                  totalMinutes: order.prepTime!,
                  remainingMinutes: order.remainingPrepTime ?? order.prepTime!,
                  onExtend: () {
                    // Extend prep time by 5 minutes
                    context.read<OrderProvider>().extendPrepTime(
                      order.id,
                      additionalMinutes: 5,
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Customer info
              Text(
                order.customerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.address,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.items.map((i) => '${i.name} x${i.qty}').join(', '),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Driver info
              if (order.driverId != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.06),
                    borderRadius: AppShape.medium,
                    border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delivery_dining_rounded,
                          size: 16,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${order.driverName ?? "Assigned"} · ${order.driverPhone ?? "N/A"}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.info.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriverTrackingScreen(order: order),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: AppShape.round,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_rounded, size: 14, color: AppColors.info),
                              SizedBox(width: 4),
                              Text(
                                'Track',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Price row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    DateFormat('hh:mm a').format(order.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Action buttons
              if (order.status == OrderStatus.placed) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          provider.updateStatus(
                              order.id, OrderStatus.cancelled);
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppShape.medium,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showAcceptDialog(context, provider, order.id),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppShape.medium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (order.status == OrderStatus.preparing) ...[
                const SizedBox(height: 14),
                if (order.driverId == null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: AppShape.medium,
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_empty_rounded, size: 16, color: AppColors.warning),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Waiting for driver assignment',
                            style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        provider.updateStatus(order.id, OrderStatus.ready);
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 18),
                      label: const Text('Mark as Ready'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        backgroundColor: AppColors.info,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppShape.medium,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
