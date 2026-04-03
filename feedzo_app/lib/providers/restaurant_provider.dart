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
  bool _freeDeliveryOnly = false;
  bool _fastDeliveryOnly = false;
  double _minRating = 0;
  String _sortBy = 'default'; // 'default', 'rating', 'deliveryTime', 'deliveryFee'
  StreamSubscription? _sub;

  List<Restaurant> get restaurants => _filtered;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get vegOnly => _vegOnly;
  bool get freeDeliveryOnly => _freeDeliveryOnly;
  bool get fastDeliveryOnly => _fastDeliveryOnly;
  double get minRating => _minRating;
  String get sortBy => _sortBy;

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
    var result = _restaurants.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.cuisine.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesVeg = !_vegOnly || r.isVeg;
      final matchesRating = r.rating >= _minRating;
      final matchesFreeDelivery = !_freeDeliveryOnly || r.deliveryFee == 0;
      final matchesFastDelivery = !_fastDeliveryOnly || r.deliveryTime <= 30;
      return matchesSearch && matchesVeg && matchesRating && matchesFreeDelivery && matchesFastDelivery;
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'deliveryTime':
        result.sort((a, b) => a.deliveryTime.compareTo(b.deliveryTime));
        break;
      case 'deliveryFee':
        result.sort((a, b) => a.deliveryFee.compareTo(b.deliveryFee));
        break;
    }

    return result;
  }

  List<Restaurant> get trending =>
      _restaurants.where((r) => r.tags.contains('Trending')).toList();

  List<Restaurant> get recommended =>
      _restaurants.where((r) => r.isRecommended).toList();

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

  void setFreeDeliveryOnly(bool value) {
    _freeDeliveryOnly = value;
    notifyListeners();
  }

  void setFastDeliveryOnly(bool value) {
    _fastDeliveryOnly = value;
    notifyListeners();
  }

  void setMinRating(double value) {
    _minRating = value;
    notifyListeners();
  }

  void setSortBy(String value) {
    _sortBy = value;
    notifyListeners();
  }

  void resetFilters() {
    _vegOnly = false;
    _freeDeliveryOnly = false;
    _fastDeliveryOnly = false;
    _minRating = 0;
    _searchQuery = '';
    _sortBy = 'default';
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
