import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_detail_model.dart';

class CustomerService {
  static final _db = FirebaseFirestore.instance;

  /// Get customer details with all related data
  static Future<CustomerDetail?> getCustomerDetail(String customerId) async {
    try {
      // Get user document
      final userSnap = await _db.collection('users').doc(customerId).get();
      if (!userSnap.exists) return null;

      final userData = userSnap.data() as Map<String, dynamic>;

      // Get customer's orders
      final ordersQuery = await _db
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final orders = ordersQuery.docs
          .map((d) => CustomerOrderSummary.fromMap(d.id, d.data()))
          .toList();

      // Calculate statistics
      final stats = _calculateStats(orders);

      return CustomerDetail.fromMap(customerId, userData, orders, stats);
    } catch (e) {
      print('Error fetching customer detail: $e');
      return null;
    }
  }

  /// Watch customer details in real-time
  static Stream<CustomerDetail?> watchCustomerDetail(String customerId) {
    return _db.collection('users').doc(customerId).snapshots().asyncMap((userSnap) async {
      if (!userSnap.exists) return null;

      final userData = userSnap.data() as Map<String, dynamic>;

      // Get latest orders
      final ordersQuery = await _db
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final orders = ordersQuery.docs
          .map((d) => CustomerOrderSummary.fromMap(d.id, d.data()))
          .toList();

      final stats = _calculateStats(orders);

      return CustomerDetail.fromMap(customerId, userData, orders, stats);
    });
  }

  /// Get customer's order history
  static Stream<List<CustomerOrderSummary>> watchCustomerOrders(String customerId) {
    return _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CustomerOrderSummary.fromMap(d.id, d.data()))
            .toList());
  }

  /// Get active/live order for customer
  static Stream<CustomerOrderSummary?> watchActiveOrder(String customerId) {
    return _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .where('status', whereIn: ['placed', 'preparing', 'picked'])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return CustomerOrderSummary.fromMap(snap.docs.first.id, snap.docs.first.data());
    });
  }

  /// Calculate customer statistics
  static Map<String, dynamic> _calculateStats(List<CustomerOrderSummary> orders) {
    if (orders.isEmpty) {
      return {
        'totalOrders': 0,
        'totalSpent': 0.0,
        'averageOrderValue': 0.0,
        'lastOrderAt': null,
        'favoriteRestaurant': null,
      };
    }

    final completedOrders = orders.where((o) => o.status == 'delivered').toList();
    final totalSpent = completedOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    
    // Find favorite restaurant
    final restaurantCounts = <String, int>{};
    for (final order in completedOrders) {
      restaurantCounts[order.restaurantName] = (restaurantCounts[order.restaurantName] ?? 0) + 1;
    }
    final favoriteRestaurant = restaurantCounts.entries.isNotEmpty
        ? restaurantCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null;

    return {
      'totalOrders': completedOrders.length,
      'totalSpent': totalSpent,
      'averageOrderValue': completedOrders.isNotEmpty ? totalSpent / completedOrders.length : 0.0,
      'lastOrderAt': orders.first.orderedAt,
      'favoriteRestaurant': favoriteRestaurant,
    };
  }

  /// Block/unblock customer
  static Future<void> updateCustomerStatus(String customerId, String status) async {
    await _db.collection('users').doc(customerId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get customer's saved addresses
  static Future<List<Map<String, dynamic>>> getCustomerAddresses(String customerId) async {
    final snap = await _db.collection('users').doc(customerId).get();
    if (!snap.exists) return [];
    
    final data = snap.data() as Map<String, dynamic>;
    final addresses = data['savedAddresses'] as List<dynamic>? ?? [];
    
    return addresses.map((a) {
      if (a is String) {
        return {'address': a, 'type': 'home', 'isDefault': false};
      }
      return a as Map<String, dynamic>;
    }).toList();
  }
}
