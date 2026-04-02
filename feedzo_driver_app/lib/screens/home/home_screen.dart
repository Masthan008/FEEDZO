import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../orders/order_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _fetchDriverStatus();
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

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('driverId', isEqualTo: _uid)
              .where('status', whereIn: ['preparing', 'picked'])
              .snapshots(),
          builder: (context, ordersSnap) {
            final activeDocs = ordersSnap.data?.docs ?? [];

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
                                value: '₹${codCollected.toStringAsFixed(0)}',
                              ),
                              const SizedBox(width: 12),
                              _QuickStat(
                                icon: Icons.pending_actions_rounded,
                                label: 'Active',
                                value: '${activeDocs.length}',
                              ),
                            ],
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
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: AppShape.round,
                                  ),
                                  child: Text(
                                    '${activeDocs.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
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
                ],
              ),
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
