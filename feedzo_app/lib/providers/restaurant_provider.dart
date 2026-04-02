import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/restaurant_model.dart';
import '../services/firestore_service.dart';

class RestaurantProvider extends ChangeNotifier {
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  bool _vegOnly = false;
  double _minRating = 0;
  StreamSubscription? _sub;

  List<Restaurant> get restaurants => _filtered;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get vegOnly => _vegOnly;
  double get minRating => _minRating;

  RestaurantProvider() {
    loadRestaurants();
  }

  void loadRestaurants() {
    // Cancel any existing subscription to avoid duplicates
    _sub?.cancel();
    _isLoading = true;
    _error = null;

    _sub = FirestoreService.watchOpenRestaurants().listen(
      (data) {
        _restaurants = data;
        _isLoading = false;
        _error = null;
        debugPrint('[RestaurantProvider] Loaded ${data.length} restaurants');
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[RestaurantProvider] Stream error: $e');
        _isLoading = false;
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  List<Restaurant> get _filtered {
    return _restaurants.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.cuisine.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesVeg = !_vegOnly || r.isVeg;
      final matchesRating = r.rating >= _minRating;
      return matchesSearch && matchesVeg && matchesRating;
    }).toList();
  }

  List<Restaurant> get trending =>
      _restaurants.where((r) => r.tags.contains('Trending')).toList();

  List<Restaurant> get aiRecommended =>
      _restaurants.where((r) => r.tags.contains('AI Pick')).toList();

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setVegOnly(bool value) {
    _vegOnly = value;
    notifyListeners();
  }

  void setMinRating(double value) {
    _minRating = value;
    notifyListeners();
  }

  void resetFilters() {
    _vegOnly = false;
    _minRating = 0;
    _searchQuery = '';
    notifyListeners();
  }

  Restaurant? getById(String id) {
    try {
      return _restaurants.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
