import 'dart:convert';
import 'dart:math' show atan2, pi;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String orderId;
  final String driverId;
  final LatLng restaurantLocation;
  final LatLng customerLocation;

  const LiveTrackingScreen({
    super.key,
    required this.orderId,
    required this.driverId,
    required this.restaurantLocation,
    required this.customerLocation,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(0, 0);
  double _rotation = 0.0;
  String? _driverImageUrl;
  String? _driverName;

  List<LatLng> _routePoints = [];
  String _eta = "Calculating...";
  String _distance = "Calculating...";
  bool _isAnimating = false;

  Future<void> _openNavigation(double lat, double lng) async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving",
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    _listenToDriverLocation();
  }

  void _listenToDriverLocation() {
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(widget.driverId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data()?['location'] != null) {
            final data = snapshot.data()!;
            final loc = data['location'];
            final nextLocation = LatLng(loc['lat'], loc['lng']);

            setState(() {
              _driverImageUrl = data['imageUrl'];
              _driverName = data['name'];
            });

            if (_currentPosition.latitude == 0) {
              setState(() {
                _currentPosition = nextLocation;
              });
            } else {
              _animateMarker(_currentPosition, nextLocation);
            }

            _getRouteAndETA(nextLocation);
          }
        });
  }

  void _animateMarker(LatLng start, LatLng end) async {
    if (_isAnimating) return;
    _isAnimating = true;

    // Calculate rotation
    double bearing = atan2(
      end.longitude - start.longitude,
      end.latitude - start.latitude,
    );

    setState(() {
      _rotation = bearing;
    });

    const int steps = 25;
    for (int i = 1; i <= steps; i++) {
      if (!mounted) return;

      double lat =
          start.latitude + (end.latitude - start.latitude) * (i / steps);
      double lng =
          start.longitude + (end.longitude - start.longitude) * (i / steps);

      setState(() {
        _currentPosition = LatLng(lat, lng);
      });

      await Future.delayed(const Duration(milliseconds: 40));
    }

    // Ensure final position is exact
    setState(() {
      _currentPosition = end;
    });

    _isAnimating = false;
  }

  Future<void> _getRouteAndETA(LatLng driverPos) async {
    try {
      final url =
          "https://router.project-osrm.org/route/v1/driving/"
          "${driverPos.longitude},${driverPos.latitude};"
          "${widget.customerLocation.longitude},${widget.customerLocation.latitude}"
          "?overview=full&geometries=geojson";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final List coords = geometry['coordinates'];

          final List<LatLng> points = coords
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();

          final double durationSeconds = route['duration'].toDouble();
          final double distanceMeters = route['distance'].toDouble();

          setState(() {
            _routePoints = points;
            _eta = "${(durationSeconds / 60).round()} mins";
            _distance = "${(distanceMeters / 1000).toStringAsFixed(1)} km";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Delivery Tracking'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.restaurantLocation,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.feedzo.driver',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.restaurantLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                  Marker(
                    point: widget.customerLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.home, color: Colors.red, size: 30),
                  ),
                  if (_currentPosition.latitude != 0)
                    Marker(
                      point: _currentPosition,
                      width: 60,
                      height: 60,
                      child: Transform.rotate(
                        angle: _rotation,
                        child: _driverImageUrl != null
                            ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    _driverImageUrl!,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.delivery_dining,
                                color: AppTheme.primaryColor,
                                size: 40,
                              ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Navigation & Recenter Buttons
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: () => _openNavigation(
                    widget.customerLocation.latitude,
                    widget.customerLocation.longitude,
                  ),
                  backgroundColor: Colors.blue,
                  child: const Icon(
                    Icons.navigation_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  onPressed: () {
                    if (_currentPosition.latitude != 0) {
                      _mapController.move(_currentPosition, 15);
                    }
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.my_location,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _driverImageUrl != null
                            ? CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(_driverImageUrl!),
                              )
                            : const Icon(
                                Icons.delivery_dining,
                                color: AppTheme.primaryColor,
                                size: 30,
                              ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _driverName ?? 'On the way to delivery',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Order ID: #${widget.orderId.toUpperCase().substring(widget.orderId.length - 6)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Live',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated Time',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _eta,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Distance',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _distance,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
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
