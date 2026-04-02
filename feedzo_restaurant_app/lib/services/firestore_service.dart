import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference get orders => _db.collection('orders');
  static CollectionReference get restaurants => _db.collection('restaurants');
  static CollectionReference get users => _db.collection('users');
  static CollectionReference get transactions => _db.collection('transactions');

  // ── Restaurant profile ────────────────────────────────────────────────────
  static Future<void> createRestaurant({
    required String uid,
    required String ownerName,
    required String restaurantName,
    required String phone,
    required String email,
  }) async {
    await users.doc(uid).set({
      'id': uid, 'name': ownerName, 'phone': phone,
      'role': 'restaurant', 'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await restaurants.doc(uid).set({
      'id': uid, 'ownerId': uid, 'name': restaurantName,
      'email': email, 'phone': phone,
      'commission': 10, 'wallet': 0.0,
      'isApproved': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<DocumentSnapshot> watchRestaurant(String restaurantId) =>
      restaurants.doc(restaurantId).snapshots();

  static Stream<DocumentSnapshot> watchUserStatus(String uid) =>
      users.doc(uid).snapshots();

  // ── Orders ────────────────────────────────────────────────────────────────
  /// Real-time stream of incoming orders for this restaurant
  static Stream<QuerySnapshot> watchRestaurantOrders(String restaurantId) =>
      orders
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .snapshots();

  /// Accept / update order status
  static Future<void> updateOrderStatus(String orderId, String status) =>
      orders.doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ── Transactions ──────────────────────────────────────────────────────────
  static Stream<QuerySnapshot> watchTransactions(String restaurantId) =>
      transactions
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .snapshots();
}
