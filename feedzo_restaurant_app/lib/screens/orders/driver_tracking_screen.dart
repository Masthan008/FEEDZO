import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';

class DriverTrackingScreen extends StatefulWidget {
  final OrderModel order;
  const DriverTrackingScreen({super.key, required this.order});

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final driverId = widget.order.driverId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Driver'),
      ),
      body: driverId == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delivery_dining, size: 64, color: AppColors.textMuted),
                  SizedBox(height: 16),
                  Text('No driver assigned yet',
                      style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
                ],
              ),
            )
          : StreamBuilder<Map<String, double>?>(
              stream: FirestoreService.watchDriverLocation(driverId),
              builder: (context, snapshot) {
                LatLng driverPos = LatLng(12.9716, 77.5946); // Default

                if (snapshot.hasData && snapshot.data != null) {
                  final lat = snapshot.data!['lat'];
                  final lng = snapshot.data!['lng'];
                  if (lat != null && lng != null && lat != 0 && lng != 0) {
                    driverPos = LatLng(lat, lng);
                  }
                }

                return Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: driverPos,
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.feedzo.restaurant',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: driverPos,
                              width: 80,
                              height: 80,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.delivery_dining,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Recenter button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: FloatingActionButton.small(
                        onPressed: () {
                          _mapController.move(driverPos, 15.0);
                        },
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.my_location, color: AppColors.primary),
                      ),
                    ),
                    // Driver info card
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.1),
                                child: const Icon(Icons.person,
                                    color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.order.driverName ??
                                          'Assigned Driver',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      widget.order.driverPhone ??
                                          'Contacting...',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: snapshot.hasData && snapshot.data != null
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  snapshot.hasData && snapshot.data != null
                                      ? '● Live'
                                      : '○ Offline',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: snapshot.hasData && snapshot.data != null
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
