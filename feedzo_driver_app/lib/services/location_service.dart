import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static final _db = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSubscription;
  String? _currentOrderId;
  String? _currentDriverId;

  /// Start listening to location updates and sync to Firestore
  Future<void> startLocationTracking(String driverId, {String? orderId}) async {
    _currentDriverId = driverId;
    _currentOrderId = orderId;

    // 1. Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // 2. Start position stream
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _updateDriverLocation(driverId, position, orderId);
          },
        );
  }

  /// Stop listening to location updates
  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _currentOrderId = null;
    _currentDriverId = null;
  }

  /// Update Firestore with current location
  Future<void> _updateDriverLocation(String driverId, Position position, String? orderId) async {
    try {
      // Update driver document with location
      await _db.collection('drivers').doc(driverId).update({
        'location': {'lat': position.latitude, 'lng': position.longitude},
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Also update order tracking subcollection if orderId is provided
      if (orderId != null) {
        await _db
            .collection('orders')
            .doc(orderId)
            .collection('tracking')
            .doc('current')
            .set({
          'orderId': orderId,
          'driverId': driverId,
          'driverLocation': GeoPoint(position.latitude, position.longitude),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error updating driver location: $e");
    }
  }

  /// Get one-time current location
  static Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }
}
