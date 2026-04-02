import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static final _db = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSubscription;

  /// Start listening to location updates and sync to Firestore
  Future<void> startLocationTracking(String driverId) async {
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
            _updateDriverLocation(driverId, position);
          },
        );
  }

  /// Stop listening to location updates
  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Update Firestore with current location
  Future<void> _updateDriverLocation(String driverId, Position position) async {
    try {
      await _db.collection('drivers').doc(driverId).update({
        'location': {'lat': position.latitude, 'lng': position.longitude},
        'lastUpdated': FieldValue.serverTimestamp(),
      });
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
