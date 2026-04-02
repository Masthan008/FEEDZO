import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _orders => _db.collection('orders');

  /// Stream all orders (admin view)
  Stream<QuerySnapshot> streamAllOrders() =>
      _orders.orderBy('createdAt', descending: true).snapshots();

  /// Stream orders by status
  Stream<QuerySnapshot> streamOrdersByStatus(String status) =>
      _orders.where('status', isEqualTo: status).snapshots();

  /// Assign driver to order
  Future<void> assignDriver(String orderId, String driverId, String driverName) =>
      _orders.doc(orderId).update({
        'driverId': driverId,
        'driverName': driverName,
        'status': 'preparing',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Update order status
  Future<void> updateStatus(String orderId, String status) =>
      _orders.doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Create a new order
  Future<DocumentReference> createOrder(Map<String, dynamic> data) =>
      _orders.add({
        ...data,
        'status': 'placed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Stream orders for a specific customer
  Stream<QuerySnapshot> streamCustomerOrders(String customerId) =>
      _orders.where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true).snapshots();

  /// Stream orders for a specific driver
  Stream<QuerySnapshot> streamDriverOrders(String driverId) =>
      _orders.where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true).snapshots();

  /// Stream orders for a specific restaurant
  Stream<QuerySnapshot> streamRestaurantOrders(String restaurantId) =>
      _orders.where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true).snapshots();
}
