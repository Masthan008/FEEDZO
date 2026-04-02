import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Place a new order
  Future<DocumentReference> placeOrder({
    required String restaurantId,
    required String restaurantName,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String paymentType, // 'cod' or 'online'
  }) async {
    return _db.collection('orders').add({
      'customerId': _uid,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'items': items,
      'totalAmount': totalAmount,
      'paymentType': paymentType,
      'status': 'placed',
      'driverId': null,
      'driverName': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream this customer's orders (real-time tracking)
  Stream<QuerySnapshot> streamMyOrders() {
    if (_uid == null) return const Stream.empty();
    return _db.collection('orders')
        .where('customerId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream a single order for live tracking
  Stream<DocumentSnapshot> streamOrder(String orderId) =>
      _db.collection('orders').doc(orderId).snapshots();
}
