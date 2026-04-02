import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  StreamSubscription? _subscription;
  bool _isLoading = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  List<OrderModel> get activeOrders => _orders
      .where(
        (o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled,
      )
      .toList();

  List<OrderModel> get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.placed).toList();

  int get totalOrders => _orders.length;
  double get totalRevenue => _orders
      .where((o) => o.status == OrderStatus.delivered)
      .fold(0, (s, o) => s + o.totalAmount);

  Map<String, int> get topItems {
    final Map<String, int> counts = {};
    for (var order in _orders) {
      if (order.status == OrderStatus.delivered) {
        for (var item in order.items) {
          counts[item.name] = (counts[item.name] ?? 0) + item.qty;
        }
      }
    }
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/new_order.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void init(String restaurantId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .listen((snap) {
          final newOrders = snap.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
          newOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Check for new orders to play sound
          if (_orders.isNotEmpty && newOrders.length > _orders.length) {
            final newest = newOrders.first;
            if (newest.status == OrderStatus.placed) {
              _playSound();
            }
          }

          _orders = newOrders;
          _isLoading = false;
          notifyListeners();
        });
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': status.name},
      );
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  Future<void> acceptOrder(String orderId, int prepTime) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
            'status': OrderStatus.preparing.name,
            'prepTime': prepTime,
            'acceptedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error accepting order: $e');
    }
  }

  double get averagePrepTime {
    final preparingOrders = _orders.where((o) => o.prepTime != null).toList();
    if (preparingOrders.isEmpty) return 0;
    final totalTime = preparingOrders.fold(0, (sum, o) => sum + o.prepTime!);
    return totalTime / preparingOrders.length;
  }

  List<double> get weeklyPerformance {
    final List<double> performance = List.filled(7, 0.0);
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (var order in _orders) {
      if (order.status == OrderStatus.delivered) {
        final orderDate = order.createdAt;
        if (orderDate.isAfter(startOfWeek)) {
          final dayIndex = orderDate.weekday - 1;
          if (dayIndex >= 0 && dayIndex < 7) {
            performance[dayIndex] += order.totalAmount;
          }
        }
      }
    }
    return performance;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
