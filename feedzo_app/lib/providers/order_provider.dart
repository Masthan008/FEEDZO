import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import '../data/models/order_model.dart';
import '../services/firestore_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isPlacing = false;
  bool _isLoading = true;
  StreamSubscription? _ordersSub;
  String? _currentCustomerId;

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
    // Prevent duplicate subscriptions for the same customer
    if (_currentCustomerId == customerId && _ordersSub != null) return;

    _ordersSub?.cancel();
    _currentCustomerId = customerId;
    _isLoading = true;
    debugPrint('[OrderProvider] Initializing with customerId: $customerId');

    _ordersSub = FirestoreService.watchCustomerOrders(customerId).listen(
      (data) {
        debugPrint('[OrderProvider] Received ${data.length} orders');
        _orders = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[OrderProvider] Stream error: $error');
        _isLoading = false;
        _orders = [];
        notifyListeners();
      },
    );
  }

  /// Generates a 4-digit OTP for delivery verification.
  String _generateOtp() {
    final rng = Random();
    return (1000 + rng.nextInt(9000)).toString();
  }

  Future<String> placeOrder(Order order) async {
    _isPlacing = true;
    notifyListeners();
    try {
      // Auto-generate delivery OTP
      final otpCode = _generateOtp();
      final orderWithOtp = order.copyWith(otpCode: otpCode);
      final orderId = await FirestoreService.placeOrder(orderWithOtp);
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
    _ordersSub?.cancel();
    _ordersSub = FirestoreService.watchRestaurantOrders(restaurantId).listen(
      (data) {
        _orders = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[OrderProvider] Restaurant stream error: $error');
        _isLoading = false;
        _orders = [];
        notifyListeners();
      },
    );
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await FirestoreService.updateOrderStatus(orderId, status);
  }

  Future<void> acceptOrder(String orderId) => updateStatus(orderId, OrderStatus.preparing);
  Future<void> rejectOrder(String orderId) => updateStatus(orderId, OrderStatus.cancelled);
  Future<void> markReady(String orderId) => updateStatus(orderId, OrderStatus.ready);

  @override
  void dispose() {
    _ordersSub?.cancel();
    super.dispose();
  }
}
