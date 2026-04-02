import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider extends ChangeNotifier {
  String _currentAddress = 'Fetching location...';
  double? _latitude;
  double? _longitude;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<Position>? _positionSub;

  String get currentAddress => _currentAddress;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isLoading => _isLoading;
  String? get error => _error;

  LocationProvider() {
    Future.microtask(() => _initLocation());
  }

  Future<void> _initLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (!serviceEnabled) {
        _currentAddress = 'Enable location services';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 5), onTimeout: () => LocationPermission.denied);
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 10), onTimeout: () => LocationPermission.denied);
        if (permission == LocationPermission.denied) {
          _currentAddress = 'Allow location access';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _currentAddress = 'Location permission denied';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get the current position with timeout to prevent hanging
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Location request timed out');
      });
      await _updateFromPosition(position);

      // Listen for position updates
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      ).listen(
        (Position position) => _updateFromPosition(position),
        onError: (e) {
          debugPrint('[LocationProvider] Position stream error: $e');
        },
      );
    } on TimeoutException {
      debugPrint('[LocationProvider] Location timed out, using fallback');
      _currentAddress = 'Location unavailable';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[LocationProvider] Init error: $e');
      _currentAddress = 'Location unavailable';
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _updateFromPosition(Position position) async {
    _latitude = position.latitude;
    _longitude = position.longitude;

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5), onTimeout: () => <Placemark>[]);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (parts.isEmpty && place.administrativeArea != null) {
          parts.add(place.administrativeArea!);
        }
        _currentAddress = parts.isNotEmpty ? parts.join(', ') : 'Unknown area';
      } else {
        _currentAddress = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      debugPrint('[LocationProvider] Geocoding error: $e');
      _currentAddress = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }

    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    _isLoading = true;
    notifyListeners();
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Refresh timed out');
      });
      await _updateFromPosition(position);
    } catch (e) {
      debugPrint('[LocationProvider] Refresh error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
