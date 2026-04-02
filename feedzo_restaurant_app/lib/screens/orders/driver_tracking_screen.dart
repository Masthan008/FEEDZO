import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';
import '../../models/order_model.dart';

class DriverTrackingScreen extends StatelessWidget {
  final OrderModel order;
  const DriverTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Default to a center if driver location is missing (e.g. for testing)
    final driverPos = LatLng(
      order.driverLat ?? 12.9716, // Bangalore default
      order.driverLng ?? 77.5946,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Driver'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: driverPos,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.feedzo.restaurant',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: driverPos,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.delivery_dining,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            order.driverName ?? 'Assigned Driver',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            order.driverPhone ?? 'Contacting...',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
