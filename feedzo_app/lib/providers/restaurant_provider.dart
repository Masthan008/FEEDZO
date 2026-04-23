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

  // Advanced filters
  List<String> _selectedCuisines = [];
  List<String> _selectedDietary = [];
  List<String> _selectedOffers = [];
  double _priceMin = 0;
  double _priceMax = 2000;
  double _deliveryMin = 0;
  double _deliveryMax = 20;
  bool _showOpenOnly = false;

  List<Restaurant> get restaurants => _filtered;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get vegOnly => _vegOnly;
  bool get freeDeliveryOnly => _freeDeliveryOnly;
  bool get fastDeliveryOnly => _fastDeliveryOnly;
  double get minRating => _minRating;
  String get sortBy => _sortBy;
  List<String> get selectedCuisines => _selectedCuisines;
  List<String> get selectedDietary => _selectedDietary;
  List<String> get selectedOffers => _selectedOffers;
  double get priceMin => _priceMin;
  double get priceMax => _priceMax;
  double get deliveryMin => _deliveryMin;
  double get deliveryMax => _deliveryMax;
  bool get showOpenOnly => _showOpenOnly;

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
      
      // Advanced filters
      final matchesCuisine = _selectedCuisines.isEmpty ||
          _selectedCuisines.contains(r.cuisine);
      final matchesDietary = _selectedDietary.isEmpty ||
          _selectedDietary.every((diet) => r.dietaryOptions.contains(diet));
      final matchesOffers = _selectedOffers.isEmpty ||
          _selectedOffers.any((offer) => r.offers.contains(offer));
      final matchesPriceRange = r.averagePrice >= _priceMin && r.averagePrice <= _priceMax;
      final matchesDeliveryRange = r.deliveryTime >= _deliveryMin && r.deliveryTime <= _deliveryMax;
      final matchesOpenNow = !_showOpenOnly || r.isOpen;

      return matchesSearch && matchesVeg && matchesRating && matchesFreeDelivery &&
          matchesFastDelivery && matchesCuisine && matchesDietary && matchesOffers &&
          matchesPriceRange && matchesDeliveryRange && matchesOpenNow;
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
    _selectedCuisines.clear();
    _selectedDietary.clear();
    _selectedOffers.clear();
    _priceMin = 0;
    _priceMax = 2000;
    _deliveryMin = 0;
    _deliveryMax = 20;
    _showOpenOnly = false;
    notifyListeners();
  }

  void setAdvancedFilters(Map<String, dynamic> filters) {
    if (filters.containsKey('cuisines')) {
      _selectedCuisines = List<String>.from(filters['cuisines']);
    }
    if (filters.containsKey('dietary')) {
      _selectedDietary = List<String>.from(filters['dietary']);
    }
    if (filters.containsKey('offers')) {
      _selectedOffers = List<String>.from(filters['offers']);
    }
    if (filters.containsKey('priceMin')) {
      _priceMin = filters['priceMin'];
    }
    if (filters.containsKey('priceMax')) {
      _priceMax = filters['priceMax'];
    }
    if (filters.containsKey('deliveryMin')) {
      _deliveryMin = filters['deliveryMin'];
    }
    if (filters.containsKey('deliveryMax')) {
      _deliveryMax = filters['deliveryMax'];
    }
    if (filters.containsKey('minRating')) {
      _minRating = filters['minRating'];
    }
    if (filters.containsKey('openNow')) {
      _showOpenOnly = filters['openNow'];
    }
    if (filters.containsKey('vegOnly')) {
      _vegOnly = filters['vegOnly'];
    }
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
