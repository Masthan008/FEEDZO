import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _availableStream() => FirebaseFirestore.instance
      .collection('orders')
      .where('status', whereIn: ['preparing', 'ready'])
      .snapshots();

  Stream<QuerySnapshot> _activeStream() => FirebaseFirestore.instance
      .collection('orders')
      .where('driverId', isEqualTo: _uid)
      .where('status', whereIn: ['preparing', 'ready', 'picked', 'outForDelivery'])
      .snapshots();

  Stream<QuerySnapshot> _completedStream() => FirebaseFirestore.instance
      .collection('orders')
      .where('driverId', isEqualTo: _uid)
      .where('status', isEqualTo: 'delivered')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Available'), Tab(text: 'Active'), Tab(text: 'Completed')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OrderList(stream: _availableStream(), label: 'Available', filterDriverId: true),
          _OrderList(stream: _activeStream(), label: 'Active'),
          _OrderList(stream: _completedStream(), label: 'Completed'),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String label;
  final bool filterDriverId;
  const _OrderList({required this.stream, required this.label, this.filterDriverId = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snap.data?.docs ?? [];
        
        if (filterDriverId) {
           docs = docs.where((doc) {
             final data = doc.data() as Map<String, dynamic>;
             return data['driverId'] == null;
           }).toList();
        }
        
        // Sorting locally to bypass Firestore index requirements
        docs.sort((a, b) {
           final ad = a.data() as Map<String, dynamic>;
           final bd = b.data() as Map<String, dynamic>;
           final ac = ad['createdAt'] as Timestamp?;
           final bc = bd['createdAt'] as Timestamp?;
           if (ac == null || bc == null) return 0;
           return bc.compareTo(ac); // descending
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inbox_rounded,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${label.toLowerCase()} orders',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;
            return _OrderCard(orderId: doc.id, data: d);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  const _OrderCard({required this.orderId, required this.data});

  @override
  Widget build(BuildContext context) {
    final restaurantName = data['restaurantName'] as String? ?? 'Restaurant';
    final totalAmount = ((data['totalAmount'] as num?) ?? 0).toDouble();
    final status = data['status'] as String? ?? 'preparing';
    final paymentType = data['paymentType'] as String? ?? 'online';
    final shortId = orderId.length > 6
        ? orderId.substring(orderId.length - 6).toUpperCase()
        : orderId.toUpperCase();

    Color statusColor;
    Color statusBgColor;
    switch (status) {
      case 'preparing':
        statusColor = AppColors.info;
        statusBgColor = AppColors.info.withValues(alpha: 0.1);
        break;
      case 'picked':
        statusColor = const Color(0xFF8B5CF6);
        statusBgColor = const Color(0xFF8B5CF6).withValues(alpha: 0.1);
        break;
      case 'delivered':
        statusColor = AppColors.success;
        statusBgColor = AppColors.statusDeliveredBg;
        break;
      default:
        statusColor = AppColors.warning;
        statusBgColor = AppColors.warning.withValues(alpha: 0.1);
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: orderId, data: data),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppShape.large,
          border: Border.all(
            color: status == 'preparing' || status == 'picked'
                ? statusColor.withValues(alpha: 0.3)
                : AppColors.border,
            width: status == 'preparing' || status == 'picked' ? 1.5 : 1.0,
          ),
          boxShadow: status == 'preparing' || status == 'picked'
              ? [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : AppShadows.subtle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppShape.medium,
                    ),
                    child: const Icon(
                      Icons.delivery_dining_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#$shortId',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          restaurantName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: AppShape.round,
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: AppColors.border),
              ),
              Row(
                children: [
                  Text(
                    '₹${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: paymentType == 'cod'
                          ? Colors.orange.shade50
                          : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: AppShape.small,
                    ),
                    child: Text(
                      paymentType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: paymentType == 'cod'
                            ? Colors.orange.shade700
                            : AppColors.success,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'View Details',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
