import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/tracking_model.dart';
import '../../services/tracking_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class OrderTrackingMapScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingMapScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingMapScreen> createState() => _OrderTrackingMapScreenState();
}

class _OrderTrackingMapScreenState extends State<OrderTrackingMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  TrackingModel? _trackingData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<TrackingModel?>(
              stream: TrackingService.watchOrderTracking(widget.orderId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                _trackingData = snapshot.data;

                if (_trackingData == null) {
                  return const Center(
                    child: Text('Tracking not available'),
                  );
                }

                _updateMarkers(_trackingData!);

                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _trackingData!.driverLocation.latitude,
                      _trackingData!.driverLocation.longitude,
                    ),
                    zoom: 14,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                );
              },
            ),
          ),
          _buildTrackingInfo(),
        ],
      ),
    );
  }

  Widget _buildTrackingInfo() {
    if (_trackingData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(_trackingData!.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(_trackingData!.status),
                  color: _getStatusColor(_trackingData!.status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusText(_trackingData!.status),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_trackingData!.estimatedTimeMinutes != null)
                      Text(
                        'ETA: ${_trackingData!.estimatedTimeMinutes} min',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_trackingData!.distanceToRestaurant != null)
            _buildInfoRow(
              'Distance to Restaurant',
              '${_trackingData!.distanceToRestaurant!.toStringAsFixed(1)} km',
              Icons.restaurant,
            ),
          if (_trackingData!.distanceToCustomer != null)
            _buildInfoRow(
              'Distance to You',
              '${_trackingData!.distanceToCustomer!.toStringAsFixed(1)} km',
              Icons.location_on,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _updateMarkers(TrackingModel tracking) {
    setState(() {
      _markers = {};

      // Driver marker
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            tracking.driverLocation.latitude,
            tracking.driverLocation.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Driver'),
        ),
      );

      // Restaurant marker
      if (tracking.restaurantLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('restaurant'),
            position: LatLng(
              tracking.restaurantLocation!.latitude,
              tracking.restaurantLocation!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: const InfoWindow(title: 'Restaurant'),
          ),
        );
      }

      // Customer marker
      if (tracking.customerLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('customer'),
            position: LatLng(
              tracking.customerLocation!.latitude,
              tracking.customerLocation!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
      case 'at_restaurant':
        return Colors.orange;
      case 'picked_up':
        return Colors.purple;
      case 'on_delivery':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'assigned':
        return Icons.motorcycle;
      case 'at_restaurant':
        return Icons.restaurant;
      case 'picked_up':
        return Icons.shopping_bag;
      case 'on_delivery':
        return Icons.directions_bike;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'assigned':
        return 'Driver assigned';
      case 'at_restaurant':
        return 'At restaurant';
      case 'picked_up':
        return 'Order picked up';
      case 'on_delivery':
        return 'On the way';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }
}
