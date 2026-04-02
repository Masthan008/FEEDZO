import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _restaurantId => _auth.currentUser?.uid;

  /// Stream incoming orders for this restaurant (real-time)
  Stream<QuerySnapshot> streamIncomingOrders() {
    if (_restaurantId == null) return const Stream.empty();
    return _db.collection('orders')
        .where('restaurantId', isEqualTo: _restaurantId)
        .where('status', whereIn: ['placed', 'preparing'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream all orders for this restaurant
  Stream<QuerySnapshot> streamAllOrders() {
    if (_restaurantId == null) return const Stream.empty();
    return _db.collection('orders')
        .where('restaurantId', isEqualTo: _restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Accept / update order status
  Future<void> updateStatus(String orderId, String status) =>
      _db.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
