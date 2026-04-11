import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Available orders: status is 'placed' or 'ready', no driver assigned yet
  Stream<QuerySnapshot> _availableStream() => FirebaseFirestore.instance
      .collection('orders')
      .where('status', whereIn: ['placed', 'preparing', 'ready'])
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
          _AvailableOrderList(uid: _uid),
          _OrderList(stream: _activeStream(), label: 'Active'),
          _OrderList(stream: _completedStream(), label: 'Completed'),
        ],
      ),
    );
  }
}

// ── Available Orders tab with Accept button ─────────────────────────
class _AvailableOrderList extends StatelessWidget {
  final String uid;
  const _AvailableOrderList({required this.uid});

  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection('orders')
      .where('status', whereIn: ['placed', 'preparing', 'ready'])
      .snapshots();

  Future<void> _acceptOrder(BuildContext context, String orderId) async {
    try {
      // Get driver info
      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(uid)
          .get();
      final driverData = driverDoc.data() as Map<String, dynamic>? ?? {};
      final driverName = driverData['name'] as String? ?? 'Driver';
      final driverPhone = driverData['phone'] as String? ?? '';

      final batch = FirebaseFirestore.instance.batch();

      // Update order with driver info
      batch.update(
        FirebaseFirestore.instance.collection('orders').doc(orderId),
        {
          'driverId': uid,
          'driverName': driverName,
          'driverPhone': driverPhone,
          'status': 'preparing',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Update driver status to busy
      batch.update(
        FirebaseFirestore.instance.collection('drivers').doc(uid),
        {
          'status': 'busy',
          'currentOrderId': orderId,
        },
      );

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted! 🚀'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder(BuildContext context, String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'rejectedBy': FieldValue.arrayUnion([uid]),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          debugPrint('[OrdersScreen] Stream error: ${snap.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error loading orders: ${snap.error}'),
              ],
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        debugPrint('[OrdersScreen] Received ${snap.data!.docs.length} orders from Firestore');
        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text("No data available"));
        }
        // Filter only unassigned orders (no driverId)
        var docs = snap.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final rejectedBy = List<String>.from(data['rejectedBy'] as List<dynamic>? ?? []);
          return data['driverId'] == null && !rejectedBy.contains(uid);
        }).toList();

        debugPrint('[OrdersScreen] Filtered to ${docs.length} unassigned orders');

        // Sort by createdAt descending
        docs.sort((a, b) {
          final ad = a.data() as Map<String, dynamic>;
          final bd = b.data() as Map<String, dynamic>;
          final ac = ad['createdAt'] as Timestamp?;
          final bc = bd['createdAt'] as Timestamp?;
          if (ac == null || bc == null) return 0;
          return bc.compareTo(ac);
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
                const Text(
                  'No available orders',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'New orders will appear here',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
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
            return _AvailableOrderCard(
              orderId: doc.id,
              data: d,
              onAccept: () => _acceptOrder(context, doc.id),
              onReject: () => _rejectOrder(context, doc.id),
            );
          },
        );
      },
    );
  }
}

class _AvailableOrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const _AvailableOrderCard({
    required this.orderId,
    required this.data,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final restaurantName = data['restaurantName'] as String? ?? 'Restaurant';
    final totalAmount = ((data['totalAmount'] as num?) ?? 0).toDouble();
    final paymentType = data['paymentType'] as String? ?? 'online';
    final customerName = data['customerName'] as String? ?? 'Customer';
    final address = data['address'] as String? ?? 'No address';
    final shortId = orderId.length > 6
        ? orderId.substring(orderId.length - 6).toUpperCase()
        : orderId.toUpperCase();
        
    final createdAt = data['createdAt'] as Timestamp?;
    String timeStr = '';
    if (createdAt != null) {
      final t = createdAt.toDate();
      final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
      final amPm = t.hour >= 12 ? 'PM' : 'AM';
      final m = t.minute.toString().padLeft(2, '0');
      timeStr = 'Ordered at: $h:$m $amPm';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShape.large,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                    Icons.restaurant_rounded,
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
                        restaurantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#$shortId',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
                    color: paymentType == 'cod'
                        ? Colors.orange.shade50
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: AppShape.round,
                  ),
                  child: Text(
                    paymentType == 'cod' ? 'COD' : 'PAID',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: paymentType == 'cod'
                          ? Colors.orange.shade700
                          : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.border),
            ),
            // Customer & delivery info
            Row(
              children: [
                const Icon(Icons.person_rounded, size: 14, color: AppColors.textHint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textHint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      timeStr,
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            // Amount + Accept button
            Row(
              children: [
                Text(
                  '₹${totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onReject();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: AppShape.round),
                      ),
                      child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        onAccept();
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: AppShape.round),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active/Completed Orders tab ─────────────────────────────────────
class _OrderList extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String label;
  const _OrderList({required this.stream, required this.label});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          debugPrint('[OrderList] Stream error for $label: ${snap.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error loading $label orders: ${snap.error}'),
              ],
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        debugPrint('[OrderList] Received ${snap.data!.docs.length} $label orders from Firestore');
        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text("No data available"));
        }
        var docs = snap.data!.docs;

        // Sort locally to bypass Firestore index requirements
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

    final createdAt = data['createdAt'] as Timestamp?;
    String timeStr = '';
    if (createdAt != null) {
      final t = createdAt.toDate();
      final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
      final amPm = t.hour >= 12 ? 'PM' : 'AM';
      final m = t.minute.toString().padLeft(2, '0');
      timeStr = 'Ordered at: $h:$m $amPm';
    }

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
              if (timeStr.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        timeStr,
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
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
