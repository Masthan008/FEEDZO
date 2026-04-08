import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../orders/order_details_screen.dart';
import '../../services/driver_notification_service.dart';
import '../../services/settlement_service.dart';
import '../../models/driver_notification_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isOnline = true;
  final DriverNotificationService _notificationService = DriverNotificationService();
  final SettlementService _settlementService = SettlementService();

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _fetchDriverStatus();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (_uid.isNotEmpty) {
      await _notificationService.initializeFCM(_uid);
    }
  }

  Future<void> _fetchDriverStatus() async {
    if (_uid.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(_uid)
        .get();
    if (doc.exists && mounted) {
      final status = doc.data()?['status'] as String? ?? 'offline';
      setState(() {
        _isOnline = status == 'available' || status == 'online';
      });
    }
  }

  Future<void> _startLocationUpdates() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen((pos) {
        if (_uid.isEmpty) return;
        FirebaseFirestore.instance.collection('drivers').doc(_uid).update({
          'location': {'lat': pos.latitude, 'lng': pos.longitude},
          'locationUpdatedAt': FieldValue.serverTimestamp(),
        }).catchError((_) {});
      });
    } catch (_) {}
  }

  Future<void> _toggleOnline(bool val) async {
    HapticFeedback.mediumImpact();
    setState(() => _isOnline = val);
    if (_uid.isEmpty) return;
    await FirebaseFirestore.instance.collection('drivers').doc(_uid).update({
      'status': val ? 'available' : 'offline',
      'isOnline': val,
      'lastActive': FieldValue.serverTimestamp(),
      // Clear active orders when going offline
      if (!val) 'activeOrderIds': [],
      if (!val) 'currentOrderId': null,
    });
  }

  Future<void> _openNavigation(double lat, double lng) async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving",
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Stream<List<DocumentSnapshot>> _getActiveOrdersStream(List<String> activeOrderIds) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where(FieldPath.documentId, whereIn: activeOrderIds)
        .snapshots()
        .map((querySnap) => querySnap.docs);
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .doc(_uid)
          .snapshots(),
      builder: (context, driverSnap) {
        final driverData =
            driverSnap.data?.data() as Map<String, dynamic>? ?? {};
        final name = driverData['name'] as String? ?? 'Driver';
        final todayOrders = (driverData['todayOrders'] as num?)?.toInt() ?? 0;
        final codCollected =
            ((driverData['codCollected'] as num?) ?? 0).toDouble();
        final activeOrderIds = List<String>.from(driverData['activeOrderIds'] ?? []);
        final maxConcurrentOrders = (driverData['maxConcurrentOrders'] as num?)?.toInt() ?? 3;
        final allowMultiOrder = driverData['allowMultiOrderAssignment'] as bool? ?? true;

        // Fetch settlement data for COD tracking
        return StreamBuilder<DocumentSnapshot>(
          stream: _settlementService.streamMySettlement(),
          builder: (context, settlementSnap) {
            final settlementData = settlementSnap.data?.data() as Map<String, dynamic>? ?? {};
            final totalCodCollected = (settlementData['codCollected'] as num?)?.toDouble() ?? 0.0;
            final totalSubmitted = (settlementData['submitted'] as num?)?.toDouble() ?? 0.0;
            final pendingCod = (settlementData['pending'] as num?)?.toDouble() ?? 0.0;

            // Fetch active orders using activeOrderIds
            return StreamBuilder<List<DocumentSnapshot>>(
              stream: _getActiveOrdersStream(activeOrderIds),
              builder: (context, ordersSnap) {
                final activeDocs = ordersSnap.data?.where((doc) => doc.exists).toList() ?? [];

            return Scaffold(
              backgroundColor: AppColors.background,
              body: CustomScrollView(
                slivers: [
                  // ── Gradient Header ──
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 20,
                        right: 20,
                        bottom: 24,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gradientStart,
                            AppColors.gradientEnd,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: AppShape.medium,
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : 'D',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, ${name.split(' ').first} 👋',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _isOnline
                                                ? const Color(0xFF4ADE80)
                                                : Colors.red.shade300,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _isOnline
                                                    ? const Color(0xFF4ADE80)
                                                        .withValues(alpha: 0.6)
                                                    : Colors.red.withValues(
                                                        alpha: 0.6),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isOnline ? 'Online' : 'Offline',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Status toggle
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: AppShape.round,
                                ),
                                child: Switch(
                                  value: _isOnline,
                                  onChanged: _toggleOnline,
                                  activeColor: Colors.white,
                                  activeTrackColor:
                                      Colors.white.withValues(alpha: 0.3),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _QuickStat(
                                icon: Icons.check_circle_rounded,
                                label: "Today's Deliveries",
                                value: '$todayOrders',
                              ),
                              const SizedBox(width: 12),
                              _QuickStat(
                                icon: Icons.money_rounded,
                                label: 'COD Collected',
                                value: '₹${totalCodCollected.toStringAsFixed(0)}',
                              ),
                              const SizedBox(width: 12),
                              _QuickStat(
                                icon: Icons.pending_actions_rounded,
                                label: 'Active',
                                value: '${activeDocs.length}/$maxConcurrentOrders',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // COD Summary Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: AppShape.medium,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${pendingCod.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Pending COD',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${totalSubmitted.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Submitted',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Active Orders ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Active Orders',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (activeDocs.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: activeDocs.length >= maxConcurrentOrders
                                        ? Colors.red.withValues(alpha: 0.2)
                                        : AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: AppShape.round,
                                  ),
                                  child: Text(
                                    '${activeDocs.length}/$maxConcurrentOrders',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: activeDocs.length >= maxConcurrentOrders
                                          ? Colors.red
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (activeDocs.isNotEmpty)
                            ...activeDocs.map((doc) {
                              final d =
                                  doc.data() as Map<String, dynamic>;
                              return _ActiveOrderCard(
                                orderId: doc.id,
                                data: d,
                                onCall: (phone) => _makeCall(phone),
                                onNavigate: (lat, lng) =>
                                    _openNavigation(lat, lng),
                              );
                            })
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppShape.large,
                                border: Border.all(color: AppColors.border),
                                boxShadow: AppShadows.subtle,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delivery_dining_outlined,
                                      size: 40,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No active deliveries',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'New orders will appear here',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Available Orders (Pool) ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          const Text(
                            'Available Orders',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Accept orders to start delivering',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('orders')
                                .where('status', whereIn: ['placed', 'preparing', 'ready'])
                                .snapshots(),
                            builder: (context, availSnap) {
                              final allDocs = availSnap.data?.docs ?? [];
                              final availDocs = allDocs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return data['driverId'] == null;
                              }).toList();

                              if (availDocs.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: AppShape.large,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        size: 32,
                                        color: AppColors.textHint,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'No orders available',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                children: availDocs.map((doc) {
                                  final d = doc.data() as Map<String, dynamic>;
                                  return _AvailableOrderTile(
                                    orderId: doc.id,
                                    data: d,
                                    driverUid: _uid,
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
              },
            );
          },
        );
      },
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label, value;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: AppShape.medium,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final Function(String) onCall;
  final Function(double, double) onNavigate;

  const _ActiveOrderCard({
    required this.orderId,
    required this.data,
    required this.onCall,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final restaurantName = data['restaurantName'] as String? ?? 'Restaurant';
    final totalAmount = ((data['totalAmount'] as num?) ?? 0).toDouble();
    final status = data['status'] as String? ?? 'preparing';
    final paymentType = data['paymentType'] as String? ?? 'online';

    final restaurantLoc =
        data['restaurantLocation'] as Map<String, dynamic>? ?? {};
    final customerLoc =
        data['customerLocation'] as Map<String, dynamic>? ?? {};
        
    final rLat = (restaurantLoc['lat'] as num?)?.toDouble() ?? 28.6139;
    final rLng = (restaurantLoc['lng'] as num?)?.toDouble() ?? 77.2090;
    final cLat = (customerLoc['lat'] as num?)?.toDouble() ?? 28.6200;
    final cLng = (customerLoc['lng'] as num?)?.toDouble() ?? 77.2150;
    final restaurantPhone = data['restaurantPhone'] as String? ?? '9876543210';
    final customerPhone = data['customerPhone'] as String? ?? '1234567890';
    final isPicked = status == 'picked';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShape.large,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: AppShadows.primaryGlow(0.06),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppShape.radiusLarge),
              topRight: Radius.circular(AppShape.radiusLarge),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    OrderDetailsScreen(orderId: orderId, data: data),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppShape.small,
                        ),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          restaurantName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isPicked
                              ? AppColors.statusPickedBg
                              : AppColors.statusPreparingBg,
                          borderRadius: AppShape.round,
                          border: Border.all(
                            color: isPicked
                                ? AppColors.statusPicked.withValues(alpha: 0.3)
                                : AppColors.statusPreparing
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          status == 'picked' ? 'Picked Up' : 'Preparing',
                          style: TextStyle(
                            color: isPicked
                                ? AppColors.statusPicked
                                : AppColors.statusPreparing,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.border),
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: paymentType == 'cod'
                              ? Colors.orange.shade50
                              : Colors.green.shade50,
                          borderRadius: AppShape.small,
                        ),
                        child: Text(
                          paymentType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: paymentType == 'cod'
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Tap to view',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppShape.radiusLarge),
                bottomRight: Radius.circular(AppShape.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onCall(isPicked ? customerPhone : restaurantPhone);
                    },
                    icon: Icon(
                      Icons.call_rounded,
                      size: 16,
                      color: isPicked ? AppColors.info : AppColors.primary,
                    ),
                    label: Text(
                      'Call ${isPicked ? 'Customer' : 'Restaurant'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPicked ? AppColors.info : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: AppColors.border,
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final targetLat = isPicked ? cLat : rLat;
                      final targetLng = isPicked ? cLng : rLng;
                      onNavigate(targetLat, targetLng);
                    },
                    icon: Icon(
                      Icons.navigation_rounded,
                      size: 16,
                      color: isPicked ? AppColors.info : AppColors.primary,
                    ),
                    label: Text(
                      'Navigate to ${isPicked ? 'Customer' : 'Pickup'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPicked ? AppColors.info : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableOrderTile extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final String driverUid;

  const _AvailableOrderTile({
    required this.orderId,
    required this.data,
    required this.driverUid,
  });

  @override
  State<_AvailableOrderTile> createState() => _AvailableOrderTileState();
}

class _AvailableOrderTileState extends State<_AvailableOrderTile> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(widget.driverUid)
          .get();
      final dd = driverDoc.data() as Map<String, dynamic>? ?? {};
      
      // Check multi-order capacity
      final activeOrderIds = List<String>.from(dd['activeOrderIds'] ?? []);
      final maxConcurrentOrders = (dd['maxConcurrentOrders'] as num?)?.toInt() ?? 3;
      final allowMultiOrder = dd['allowMultiOrderAssignment'] as bool? ?? true;
      
      if (activeOrderIds.length >= maxConcurrentOrders) {
        throw Exception('You are at maximum capacity ($maxConcurrentOrders orders). Complete some orders first.');
      }
      
      if (!allowMultiOrder && activeOrderIds.isNotEmpty) {
        throw Exception('Multi-order assignment is disabled. Complete your current order first.');
      }

      final batch = FirebaseFirestore.instance.batch();
      
      // Update order
      batch.update(
        FirebaseFirestore.instance.collection('orders').doc(widget.orderId),
        {
          'driverId': widget.driverUid,
          'driverName': dd['name'] ?? 'Driver',
          'driverPhone': dd['phone'] ?? '',
          'status': 'preparing',
          'assignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      // Update driver with new active order
      final newActiveOrderIds = [...activeOrderIds, widget.orderId];
      String newStatus;
      if (newActiveOrderIds.length >= maxConcurrentOrders) {
        newStatus = 'multiOrder';
      } else if (newActiveOrderIds.length > 1) {
        newStatus = 'multiOrder';
      } else {
        newStatus = 'busy';
      }
      
      batch.update(
        FirebaseFirestore.instance.collection('drivers').doc(widget.driverUid),
        {
          'status': newStatus,
          'currentOrderId': newActiveOrderIds.first,
          'activeOrderIds': newActiveOrderIds,
          'lastOrderAcceptedAt': FieldValue.serverTimestamp(),
        },
      );
      
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order accepted! Active orders: ${newActiveOrderIds.length}/$maxConcurrentOrders 🚀'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _accepting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantName = widget.data['restaurantName'] as String? ?? 'Restaurant';
    final totalAmount = ((widget.data['totalAmount'] as num?) ?? 0).toDouble();
    final paymentType = widget.data['paymentType'] as String? ?? 'online';
    final shortId = widget.orderId.length > 6
        ? widget.orderId.substring(widget.orderId.length - 6).toUpperCase()
        : widget.orderId.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShape.large,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppShape.medium,
            ),
            child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurantName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '#$shortId · ₹${totalAmount.toStringAsFixed(0)} · ${paymentType.toUpperCase()}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: _accepting ? null : _accept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: AppShape.round),
              ),
              child: _accepting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
