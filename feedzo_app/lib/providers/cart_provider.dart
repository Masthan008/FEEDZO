import 'package:flutter/material.dart';
import '../data/models/restaurant_model.dart';
import '../data/models/order_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _restaurantId;
  String? _restaurantName;
  String? _restaurantImage;
  double _deliveryFee = 0;

  List<CartItem> get items => _items;
  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;
  String? get restaurantImage => _restaurantImage;
  double get deliveryFee => _deliveryFee;
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.total);
  double get total => subtotal + _deliveryFee;

  bool get isEmpty => _items.isEmpty;

  int quantityOf(String itemId) {
    final idx = _items.indexWhere((i) => i.item.id == itemId);
    return idx >= 0 ? _items[idx].quantity : 0;
  }

  void addItem(MenuItem item, String restaurantId, String restaurantName, String restaurantImage, double deliveryFee) {
    if (_restaurantId != null && _restaurantId != restaurantId) {
      _items.clear();
    }
    _restaurantId = restaurantId;
    _restaurantName = restaurantName;
    _restaurantImage = restaurantImage;
    _deliveryFee = deliveryFee;

    final idx = _items.indexWhere((i) => i.item.id == item.id);
    if (idx >= 0) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(item: item));
    }
    notifyListeners();
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

  void clear() {
    _items.clear();
    _restaurantId = null;
    _restaurantName = null;
    _restaurantImage = null;
    notifyListeners();
  }
}

