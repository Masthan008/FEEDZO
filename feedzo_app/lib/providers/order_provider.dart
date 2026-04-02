import 'package:flutter/material.dart';
import '../data/models/order_model.dart';
import '../services/firestore_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isPlacing = false;
  bool _isLoading = true;

  List<Order> get orders => _orders;
  bool get isPlacing => _isPlacing;
  bool get isLoading => _isLoading;

  List<Order> get activeOrders => _orders
      .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
      .toList();

  List<Order> get pastOrders => _orders
      .where((o) => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled)
      .toList();

  void init(String customerId) {
    FirestoreService.watchCustomerOrders(customerId).listen((data) {
      _orders = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<String> placeOrder(Order order) async {
    _isPlacing = true;
    notifyListeners();
    try {
      final orderId = await FirestoreService.placeOrder(order);
      _isPlacing = false;
      notifyListeners();
      return orderId;
    } catch (e) {
      _isPlacing = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    await FirestoreService.cancelOrder(orderId);
  }

  void initRestaurant(String restaurantId) {
    FirestoreService.watchRestaurantOrders(restaurantId).listen((data) {
      _orders = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await FirestoreService.updateOrderStatus(orderId, status);
  }

  Future<void> acceptOrder(String orderId) => updateStatus(orderId, OrderStatus.preparing);
  Future<void> rejectOrder(String orderId) => updateStatus(orderId, OrderStatus.cancelled);
  Future<void> markReady(String orderId) => updateStatus(orderId, OrderStatus.ready);
}

