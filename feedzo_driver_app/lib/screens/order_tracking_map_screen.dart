import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/tracking_model.dart';
import '../../services/tracking_service.dart';
import '../../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class DriverOrderTrackingMapScreen extends StatefulWidget {
  final String orderId;
  const DriverOrderTrackingMapScreen({super.key, required this.orderId});

  @override
  State<DriverOrderTrackingMapScreen> createState() => _DriverOrderTrackingMapScreenState();
}

class _DriverOrderTrackingMapScreenState extends State<DriverOrderTrackingMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  TrackingModel? _trackingData;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  Future<void> _initLocationTracking() async {
    final authProvider = context.read<AuthProvider>();
    final driverId = authProvider.driverId;
    if (driverId != null) {
      LocationService().startLocationTracking(driverId, orderId: widget.orderId);
    }
  }

  @override
  void dispose() {
    LocationService().stopLocationTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.navigation),
            onPressed: _navigateToDestination,
          ),
        ],
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

                _updateMarkersAndRoutes(_trackingData!);

                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _trackingData!.driverLocation.latitude,
                      _trackingData!.driverLocation.longitude,
                    ),
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                );
              },
            ),
          ),
          _buildTrackingControls(),
        ],
      ),
    );
  }

  Widget _buildTrackingControls() {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Update Status',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus('at_restaurant'),
                  icon: const Icon(Icons.restaurant),
                  label: const Text('At Restaurant'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus('picked_up'),
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('Picked Up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _updateStatus('on_delivery'),
            icon: const Icon(Icons.directions_bike),
            label: const Text('On Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  void _updateMarkersAndRoutes(TrackingModel tracking) {
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
          infoWindow: const InfoWindow(title: 'You'),
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
            infoWindow: const InfoWindow(title: 'Customer'),
          ),
        );
      }

      // Create route polyline
      if (tracking.restaurantLocation != null && tracking.customerLocation != null) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 3,
            points: [
              LatLng(
                tracking.driverLocation.latitude,
                tracking.driverLocation.longitude,
              ),
              if (tracking.status == 'at_restaurant')
                LatLng(
                  tracking.restaurantLocation!.latitude,
                  tracking.restaurantLocation!.longitude,
                ),
              if (tracking.status == 'picked_up' || tracking.status == 'on_delivery')
                LatLng(
                  tracking.customerLocation!.latitude,
                  tracking.customerLocation!.longitude,
                ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _updateStatus(String status) async {
    final authProvider = context.read<AuthProvider>();
    final driverId = authProvider.driverId;
    if (driverId == null) return;

    await TrackingService.updateOrderStatus(
      orderId: widget.orderId,
      status: status,
    );
  }

  Future<void> _navigateToDestination() async {
    if (_trackingData?.customerLocation == null) return;

    final url = 'https://www.google.com/maps/dir/?api=1&destination=${_trackingData!.customerLocation!.latitude},${_trackingData!.customerLocation!.longitude}';
    // Launch URL (needs url_launcher package)
  }
}
