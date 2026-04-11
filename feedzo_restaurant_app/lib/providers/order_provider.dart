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
  String? _restaurantId;
  // Track known order IDs to detect new ones
  Set<String> _knownOrderIds = {};

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

  Future<void> _playNewOrderSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setSource(AssetSource('sounds/new_order.mp3'));
      await _audioPlayer.resume();
      debugPrint('[OrderProvider] Playing new order sound');
    } catch (e) {
      debugPrint('[OrderProvider] Error playing sound: $e');
    }
  }

  void init(String restaurantId) {
    _subscription?.cancel();
    _restaurantId = restaurantId;
    _isLoading = true;
    _knownOrderIds.clear();
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .listen(
      (snap) {
        final newOrders = snap.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
        newOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Detect truly new orders (not just status changes)
        if (_knownOrderIds.isNotEmpty) {
          for (final order in newOrders) {
            if (!_knownOrderIds.contains(order.id) &&
                order.status == OrderStatus.placed) {
              _playNewOrderSound();
              break;
            }
          }
        }

        // Update known order IDs
        _knownOrderIds = newOrders.map((o) => o.id).toSet();

        _orders = newOrders;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[OrderProvider] Stream error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final orderRef =
          FirebaseFirestore.instance.collection('orders').doc(orderId);

      batch.update(orderRef, {'status': status.name});

      // When order is delivered, credit the restaurant wallet (no commission)
      if (status == OrderStatus.delivered && _restaurantId != null) {
        final order = _orders.firstWhere(
          (o) => o.id == orderId,
          orElse: () => _orders.first,
        );

        // Credit full amount to restaurant wallet
        final restRef = FirebaseFirestore.instance
            .collection('restaurants')
            .doc(_restaurantId);
        batch.update(restRef, {
          'walletBalance': FieldValue.increment(order.totalAmount),
        });

        // Create transaction record (no commission)
        final txnRef =
            FirebaseFirestore.instance.collection('transactions').doc();
        batch.set(txnRef, {
          'restaurantId': _restaurantId,
          'orderId': orderId,
          'description': 'Order #${orderId.length > 8 ? orderId.substring(orderId.length - 8).toUpperCase() : orderId}',
          'amount': order.totalAmount,
          'date': FieldValue.serverTimestamp(),
          'type': 'earning',
          'status': 'completed',
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('[OrderProvider] Error updating order status: $e');
    }
  }

  Future<void> acceptOrder(String orderId, int prepTime) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);

      final dbData = <String, dynamic>{
        'status': OrderStatus.preparing.name,
        'prepTime': prepTime,
        'acceptedAt': FieldValue.serverTimestamp(),
      };

      // Quick logic: auto assign driver if online/available
      debugPrint('[OrderProvider] Querying for online/available drivers for order $orderId');
      final drivers = await FirebaseFirestore.instance
          .collection('drivers')
          .where('status', whereIn: ['online', 'available'])
          .get();

      debugPrint('[OrderProvider] Found ${drivers.docs.length} drivers with status online/available');

      if (drivers.docs.isNotEmpty) {
        final doc = drivers.docs.first;
        final driverId = doc.id;
        final data = doc.data();

        debugPrint('[OrderProvider] Assigning driver $driverId (${data['name']}) to order $orderId');

        dbData['driverId'] = driverId;
        dbData['driverName'] = data['name'] ?? 'Driver';
        dbData['driverPhone'] = data['phone'] ?? '';

        final driverRef = FirebaseFirestore.instance.collection('drivers').doc(driverId);
        batch.update(driverRef, {
          'status': 'busy',
          'currentOrderId': orderId,
          'activeOrderIds': FieldValue.arrayUnion([orderId]),
        });
      } else {
        debugPrint('[OrderProvider] No online/available drivers found for order $orderId');
      }

      batch.update(orderRef, dbData);
      await batch.commit();

      debugPrint('[OrderProvider] Order $orderId accepted and batch committed');

    } catch (e) {
      debugPrint('[OrderProvider] Error accepting order: $e');
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
