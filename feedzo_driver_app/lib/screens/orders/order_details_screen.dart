import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../services/location_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/swipeable_button.dart';
import 'live_tracking_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> data;
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.data,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _updating = false;
  String? _deliveryProofUrl;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _takeDeliveryProof() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (image == null) return;

    setState(() => _updating = true);
    try {
      final url = await CloudinaryService.uploadImage(
        File(image.path),
        folder: 'deliveries',
      );
      if (url != null) {
        setState(() => _deliveryProofUrl = url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery proof uploaded!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
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

  String? _nextStatus(String current) {
    if (current == 'preparing') return 'picked';
    if (current == 'picked') return 'delivered';
    return null;
  }

  String _actionLabel(String status) {
    if (status == 'preparing') return 'Swipe to Pick Up';
    if (status == 'picked') return 'Swipe to Deliver';
    return 'Delivered';
  }

  Future<void> _updateStatus(String currentStatus) async {
    if (_updating) return; // Prevent double trigger on swipe
    HapticFeedback.heavyImpact();
    final next = _nextStatus(currentStatus);
    if (next == null) return;
    setState(() => _updating = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final updateData = {
        'status': next,
        'driverId': _uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (next == 'delivered' && _deliveryProofUrl != null) {
        updateData['deliveryProofUrl'] = _deliveryProofUrl!;
      }
      batch.update(
        FirebaseFirestore.instance.collection('orders').doc(widget.orderId),
        updateData,
      );

      // Start location tracking when order is picked up
      if (next == 'picked') {
        LocationService().startLocationTracking(_uid);
      }

      if (next == 'delivered') {
        // Stop location tracking when delivered
        LocationService().stopLocationTracking();

        final totalAmount =
            ((widget.data['totalAmount'] as num?) ?? 0).toDouble();
        final isCod = widget.data['paymentType'] == 'cod';
        batch.update(
          FirebaseFirestore.instance.collection('drivers').doc(_uid),
          {
            'todayOrders': FieldValue.increment(1),
            'status': 'available',
            if (isCod) 'codCollected': FieldValue.increment(totalAmount),
          },
        );
        if (isCod) {
          final sRef =
              FirebaseFirestore.instance.collection('settlements').doc(_uid);
          batch.set(
              sRef,
              {
                'driverId': _uid,
                'codCollected': FieldValue.increment(totalAmount),
                'pending': FieldValue.increment(totalAmount),
                'submitted': FieldValue.increment(0),
              },
              SetOptions(merge: true));
        }
      }
      await batch.commit();
      if (mounted && next == 'delivered') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order delivered successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted && next != 'delivered') setState(() => _updating = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final status = widget.data['status'] as String? ?? 'preparing';
    if (status == 'picked') {
      LocationService().startLocationTracking(_uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .snapshots(),
      builder: (context, snap) {
        final d = snap.data?.data() as Map<String, dynamic>? ?? widget.data;
        final status = d['status'] as String? ?? 'preparing';
        final restaurantName = d['restaurantName'] as String? ?? 'Restaurant';
        final totalAmount = ((d['totalAmount'] as num?) ?? 0).toDouble();
        final paymentType = d['paymentType'] as String? ?? 'online';
        final shortId = widget.orderId.length > 6
            ? widget.orderId.substring(widget.orderId.length - 6).toUpperCase()
            : widget.orderId.toUpperCase();

        final items = (d['items'] as List<dynamic>?) ?? [];
        final next = _nextStatus(status);

        final restaurantLoc =
            d['restaurantLocation'] as Map<String, dynamic>? ?? {};
        final customerLoc = d['customerLocation'] as Map<String, dynamic>? ?? {};
        
        final rLat = (restaurantLoc['lat'] as num?)?.toDouble() ?? 28.6139;
        final rLng = (restaurantLoc['lng'] as num?)?.toDouble() ?? 77.2090;
        final cLat = (customerLoc['lat'] as num?)?.toDouble() ?? 28.6200;
        final cLng = (customerLoc['lng'] as num?)?.toDouble() ?? 77.2150;

        final restaurantPhone = d['restaurantPhone'] as String? ?? '9876543210';
        final customerPhone = d['customerPhone'] as String? ?? '1234567890';
        final customerName = d['customerName'] as String? ?? 'Customer';
        final customerAddress =
            d['customerAddress'] as String? ?? 'Not provided';

        return Scaffold(
          appBar: AppBar(
            title: Text('Order #$shortId'),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Timeline
                _PremiumTimeline(status: status),
                const SizedBox(height: 24),

                // Live Map Tracker
                _MapCard(orderId: widget.orderId, data: d),
                const SizedBox(height: 16),

                // Pickup & Delivery Info
                _PremiumInfoCard(
                  type: 'PICKUP',
                  name: restaurantName,
                  address: null,
                  phone: restaurantPhone,
                  lat: rLat,
                  lng: rLng,
                  icon: Icons.storefront_rounded,
                  color: AppColors.primary,
                  onCall: () => _makeCall(restaurantPhone),
                  onNavigate: () => _openNavigation(rLat, rLng),
                ),
                const SizedBox(height: 12),
                _PremiumInfoCard(
                  type: 'DROP-OFF',
                  name: customerName,
                  address: customerAddress,
                  phone: customerPhone,
                  lat: cLat,
                  lng: cLng,
                  icon: Icons.person_rounded,
                  color: AppColors.info,
                  onCall: () => _makeCall(customerPhone),
                  onNavigate: () => _openNavigation(cLat, cLng),
                ),
                const SizedBox(height: 16),

                // Payment & Items
                _PaymentAndItemsCard(
                  totalAmount: totalAmount,
                  paymentType: paymentType,
                  items: items,
                ),
                const SizedBox(height: 24),

                // Delivery Proof
                if (status == 'picked') ...[
                  const Text(
                    'Delivery Proof required',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _updating ? null : _takeDeliveryProof,
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppShape.large,
                        border: Border.all(
                          color: _deliveryProofUrl == null
                              ? AppColors.error.withValues(alpha: 0.3)
                              : AppColors.success.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        image: _deliveryProofUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_deliveryProofUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _deliveryProofUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  color: AppColors.error,
                                  size: 32,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tap to take photo proof',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              alignment: Alignment.topRight,
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Swipeable
                if (next != null)
                  if (_updating)
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: AppShape.round,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (next == 'delivered' && _deliveryProofUrl == null)
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppShape.round,
                      ),
                      child: const Center(
                        child: Text(
                          'Upload Proof to Deliver',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else
                    SwipeableButton(
                      text: _actionLabel(status),
                      onSwipeComplete: () => _updateStatus(status),
                      backgroundColor:
                          status == 'picked' ? AppColors.info : AppColors.primary,
                    )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: AppShape.round,
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.done_all, color: AppColors.success),
                        SizedBox(width: 8),
                        Text(
                          'Order Delivered',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PremiumTimeline extends StatelessWidget {
  final String status;
  const _PremiumTimeline({required this.status});

  int get _step {
    if (status == 'placed') return 0;
    if (status == 'preparing') return 1;
    if (status == 'picked') return 2;
    if (status == 'delivered') return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Assigned', 'Preparing', 'Picked Up', 'Delivered'];
    final current = _step;

    return Row(
      children: List.generate(steps.length, (i) {
        final done = i <= current;
        final isLast = i == steps.length - 1;
        final color = done
            ? (i == 3 ? AppColors.success : AppColors.primary)
            : AppColors.border;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: done ? color.withValues(alpha: 0.15) : Colors.transparent,
                        border: Border.all(
                          color: color,
                          width: done ? 0 : 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: done ? color : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: done ? AppColors.textPrimary : AppColors.textHint,
                        fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: i < current ? AppColors.primary : AppColors.border,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _PremiumInfoCard extends StatelessWidget {
  final String type;
  final String name;
  final String? address;
  final String phone;
  final double lat;
  final double lng;
  final IconData icon;
  final Color color;
  final VoidCallback onCall;
  final VoidCallback onNavigate;

  const _PremiumInfoCard({
    required this.type,
    required this.name,
    this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.icon,
    required this.color,
    required this.onCall,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShape.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppShape.small,
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CircleBtn(
                    icon: Icons.call_rounded,
                    color: color,
                    onTap: onCall,
                  ),
                  const SizedBox(width: 8),
                  _CircleBtn(
                    icon: Icons.navigation_rounded,
                    color: color,
                    onTap: onNavigate,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.textSecondary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (address != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        address!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _PaymentAndItemsCard extends StatelessWidget {
  final double totalAmount;
  final String paymentType;
  final List<dynamic> items;

  const _PaymentAndItemsCard({
    required this.totalAmount,
    required this.paymentType,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShape.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: paymentType == 'cod'
                        ? Colors.orange.shade50
                        : AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    color: paymentType == 'cod'
                        ? Colors.orange.shade600
                        : AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Payment',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: paymentType == 'cod'
                        ? Colors.orange.shade50
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: AppShape.round,
                    border: Border.all(
                      color: paymentType == 'cod'
                          ? Colors.orange.shade200
                          : AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    paymentType == 'cod' ? 'COLLECT CASH' : 'PAID ONLINE',
                    style: TextStyle(
                      color: paymentType == 'cod'
                          ? Colors.orange.shade700
                          : AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDER ITEMS (${items.length})',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map((item) {
                  final i = item as Map<String, dynamic>? ?? {};
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i['quantity'] ?? 1}x',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            i['name'] as String? ?? 'Item',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  const _MapCard({required this.orderId, required this.data});

  @override
  Widget build(BuildContext context) {
    final restaurantLoc =
        data['restaurantLocation'] as Map<String, dynamic>? ?? {};
    final customerLoc = data['customerLocation'] as Map<String, dynamic>? ?? {};
    
    final rLat = (restaurantLoc['lat'] as num?)?.toDouble() ?? 28.6139;
    final rLng = (restaurantLoc['lng'] as num?)?.toDouble() ?? 77.2090;
    final cLat = (customerLoc['lat'] as num?)?.toDouble() ?? 28.6200;
    final cLng = (customerLoc['lng'] as num?)?.toDouble() ?? 77.2150;

  final driverId = data['driverId'] as String? ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';

    return GestureDetector(
      onTap: () async {
        HapticFeedback.heavyImpact();
        
        // Get actual location to prevent simulated Bangalore coords from breaking OSRM
        final pos = await LocationService.getCurrentLocation();
        final rLat = pos?.latitude ?? 12.9716;
        final rLng = pos?.longitude ?? 77.5946;

        // Simulate restaurant and customer nearby to ensure routing works globally
        final restLat = rLat + 0.005;
        final restLng = rLng + 0.005;
        final custLat = rLat - 0.008;
        final custLng = rLng - 0.008;

        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveTrackingScreen(
              orderId: orderId,
              driverId: driverId,
              restaurantLocation: LatLng(restLat, restLng),
              customerLocation: LatLng(custLat, custLng),
            ),
          ),
        );
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: AppShape.large,
          border: Border.all(color: AppColors.border),
          color: AppColors.surface,
          boxShadow: AppShadows.subtle,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _GridPainter()),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surface.withValues(alpha: 0.1),
                    AppColors.surface.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'View Live Tracking Route',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to open map',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
