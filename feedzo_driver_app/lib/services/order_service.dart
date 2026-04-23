import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _driverId => _auth.currentUser?.uid;

  /// Stream orders assigned to this driver
  Stream<QuerySnapshot> streamMyOrders() {
    if (_driverId == null) return const Stream.empty();
    return _db.collection('orders')
        .where('driverId', isEqualTo: _driverId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream available orders (unassigned orders that drivers can accept)
  Stream<QuerySnapshot> streamAvailableOrders() {
    return _db.collection('orders')
        .where('status', whereIn: ['placed', 'preparing', 'ready'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream active order (preparing / out_for_delivery)
  Stream<QuerySnapshot> streamActiveOrder() {
    if (_driverId == null) return const Stream.empty();
    return _db.collection('orders')
        .where('driverId', isEqualTo: _driverId)
        .where('status', whereIn: ['preparing', 'out_for_delivery'])
        .snapshots();
  }

  /// Update order status
  Future<void> updateStatus(String orderId, String status) =>
      _db.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
