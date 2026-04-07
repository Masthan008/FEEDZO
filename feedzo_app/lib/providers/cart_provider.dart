import 'package:flutter/material.dart';
import '../data/models/restaurant_model.dart';
import '../data/models/order_model.dart';
import '../services/hike_charges_service.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _restaurantId;
  String? _restaurantName;
  String? _restaurantImage;
  double _deliveryFee = 0;

  // ── Hike Charges ──
  double _packagingCharge = 0;
  double _deliveryCharge = 0;
  double _smallOrderFee = 0;
  double _surgeCharge = 0;
  bool _isSurgeActive = false;
  double _hikeMultiplier = 0;
  bool _hikeChargesLoaded = false;

  // ── New checkout fields ──
  String? _deliveryInstructions;
  double _tipAmount = 0;
  String? _couponCode;
  double _discount = 0;
  DateTime? _scheduledFor;

  List<CartItem> get items => _items;
  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;
  String? get restaurantImage => _restaurantImage;
  double get deliveryFee => _deliveryFee;
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  // New getters
  String? get deliveryInstructions => _deliveryInstructions;
  double get tipAmount => _tipAmount;
  String? get couponCode => _couponCode;
  double get discount => _discount;
  DateTime? get scheduledFor => _scheduledFor;

  // Hike charges getters
  double get packagingCharge => _packagingCharge;
  double get deliveryCharge => _deliveryCharge;
  double get smallOrderFee => _smallOrderFee;
  double get surgeCharge => _surgeCharge;
  bool get isSurgeActive => _isSurgeActive;
  double get hikeMultiplier => _hikeMultiplier;
  bool get hikeChargesLoaded => _hikeChargesLoaded;
  double get totalHikeCharges => _packagingCharge + _deliveryCharge + _smallOrderFee + _surgeCharge;

  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.total);
  double get taxAmount => (subtotal + totalHikeCharges) * 0.05; // 5% GST on items + hike
  double get total => subtotal + totalHikeCharges + taxAmount + _tipAmount - _discount;

  bool get isEmpty => _items.isEmpty;

  int quantityOf(String itemId) {
    final idx = _items.indexWhere((i) => i.item.id == itemId);
    return idx >= 0 ? _items[idx].quantity : 0;
  }

  /// Returns true if adding requires a restaurant switch (so caller can show a dialog).
  bool wouldSwitchRestaurant(String restaurantId) {
    return _restaurantId != null && _restaurantId != restaurantId && _items.isNotEmpty;
  }

  /// Adds an item. If [forceSwitch] is true, clears the cart first.
  void addItem(
    MenuItem item,
    String restaurantId,
    String restaurantName,
    String restaurantImage,
    double deliveryFee, {
    bool forceSwitch = false,
    List<SelectedAddon> selectedAddons = const [],
    String? selectedVariant,
    double? variantPriceAdjustment,
  }) {
    if (_restaurantId != null && _restaurantId != restaurantId) {
      if (!forceSwitch) return; // Caller should show dialog first
      _items.clear();
      _couponCode = null;
      _discount = 0;
      _deliveryInstructions = null;
      _tipAmount = 0;
    }
    _restaurantId = restaurantId;
    _restaurantName = restaurantName;
    _restaurantImage = restaurantImage;
    _deliveryFee = deliveryFee;

    // Check if same item with same addons/variant exists
    final idx = _items.indexWhere((i) =>
        i.item.id == item.id &&
        i.selectedVariant == selectedVariant &&
        _addonsMatch(i.selectedAddons, selectedAddons));
    if (idx >= 0) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(
        item: item,
        selectedAddons: selectedAddons,
        selectedVariant: selectedVariant,
        variantPriceAdjustment: variantPriceAdjustment,
      ));
    }
    notifyListeners();
  }

  bool _addonsMatch(List<SelectedAddon> a, List<SelectedAddon> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name) return false;
    }
    return true;
  }

  void removeItem(String itemId) {
    final idx = _items.indexWhere((i) => i.item.id == itemId);
    if (idx >= 0) {
      if (_items[idx].quantity > 1) {
        _items[idx].quantity--;
      } else {
        _items.removeAt(idx);
      }
    }
    if (_items.isEmpty) _restaurantId = null;
    notifyListeners();
  }

  // ── Calculate Hike Charges ──
  Future<void> calculateHikeCharges({double distanceKm = 3.0}) async {
    if (_restaurantId == null || _items.isEmpty) return;
    
    try {
      final charges = await HikeChargesService.calculateCharges(
        restaurantId: _restaurantId!,
        orderValue: subtotal,
        distanceKm: distanceKm,
      );
      
      _packagingCharge = charges['packagingCharge'] as double;
      _deliveryCharge = charges['deliveryCharge'] as double;
      _smallOrderFee = charges['smallOrderFee'] as double;
      _surgeCharge = charges['surgeCharge'] as double;
      _isSurgeActive = charges['isSurge'] as bool;
      _hikeMultiplier = charges['hikeMultiplier'] as double;
      _hikeChargesLoaded = true;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error calculating hike charges: $e');
      // Use default values
      _packagingCharge = 10;
      _deliveryCharge = 20 + (5 * distanceKm);
      _smallOrderFee = 0;
      _surgeCharge = 0;
      _isSurgeActive = false;
      _hikeMultiplier = 0;
      _hikeChargesLoaded = true;
      notifyListeners();
    }
  }

  // ── Delivery Instructions ──
  void setDeliveryInstructions(String? instructions) {
    _deliveryInstructions = instructions;
    notifyListeners();
  }

  // ── Tip ──
  void setTip(double amount) {
    _tipAmount = amount.clamp(0, 999);
    notifyListeners();
  }

  // ── Coupon ──
  void applyCoupon(String code, double discountAmount) {
    _couponCode = code;
    _discount = discountAmount;
    notifyListeners();
  }

  void removeCoupon() {
    _couponCode = null;
    _discount = 0;
    notifyListeners();
  }

  // ── Schedule ──
  void setSchedule(DateTime? dateTime) {
    _scheduledFor = dateTime;
    notifyListeners();
  }

  // ── Reorder from past order ──
  void reorderFromPast(Order pastOrder) {
    _items.clear();
    _restaurantId = pastOrder.restaurantId;
    _restaurantName = pastOrder.restaurantName;
    _restaurantImage = pastOrder.restaurantImage;
    _deliveryFee = pastOrder.deliveryFee;
    for (final cartItem in pastOrder.items) {
      _items.add(CartItem(
        item: cartItem.item,
        quantity: cartItem.quantity,
        selectedAddons: cartItem.selectedAddons,
        selectedVariant: cartItem.selectedVariant,
        variantPriceAdjustment: cartItem.variantPriceAdjustment,
      ));
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _restaurantId = null;
    _restaurantName = null;
    _restaurantImage = null;
    _deliveryInstructions = null;
    _tipAmount = 0;
    _couponCode = null;
    _discount = 0;
    _scheduledFor = null;
    _packagingCharge = 0;
    _deliveryCharge = 0;
    _smallOrderFee = 0;
    _surgeCharge = 0;
    _isSurgeActive = false;
    _hikeMultiplier = 0;
    _hikeChargesLoaded = false;
    notifyListeners();
  }
}
