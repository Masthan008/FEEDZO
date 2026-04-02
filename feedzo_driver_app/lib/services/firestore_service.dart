import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference get orders => _db.collection('orders');
  static CollectionReference get drivers => _db.collection('drivers');
  static CollectionReference get settlements => _db.collection('settlements');
  static CollectionReference get users => _db.collection('users');

  // ── Driver profile ────────────────────────────────────────────────────────
  static Future<void> createDriver({
    required String uid,
    required String name,
    required String phone,
    required String vehicle,
  }) async {
    await users.doc(uid).set({
      'id': uid, 'name': name, 'phone': phone,
      'role': 'driver', 'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await drivers.doc(uid).set({
      'id': uid, 'userId': uid, 'name': name, 'phone': phone,
      'vehicle': vehicle, 'status': 'available',
      'isApproved': false, 'todayOrders': 0,
      'codCollected': 0.0, 'submitted': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<DocumentSnapshot> watchDriverProfile(String driverId) =>
      drivers.doc(driverId).snapshots();

  static Stream<DocumentSnapshot> watchUserStatus(String uid) =>
      users.doc(uid).snapshots();

  // ── Orders ────────────────────────────────────────────────────────────────
  /// Real-time stream of orders assigned to this driver
  static Stream<QuerySnapshot> watchDriverOrders(String driverId) =>
      orders
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .snapshots();

  /// Update order status (picked, delivered)
  static Future<void> updateOrderStatus(String orderId, String status) =>
      orders.doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ── Settlement ────────────────────────────────────────────────────────────
  static Stream<DocumentSnapshot> watchSettlement(String driverId) =>
      settlements.doc(driverId).snapshots();

  static Future<void> recordCodCollected(String driverId, double amount) =>
      _db.runTransaction((tx) async {
        final ref = settlements.doc(driverId);
        final snap = await tx.get(ref);
        if (snap.exists) {
          final d = snap.data() as Map;
          tx.update(ref, {
            'codCollected': (d['codCollected'] ?? 0) + amount,
            'pending': (d['pending'] ?? 0) + amount,
          });
        } else {
          tx.set(ref, {
            'driverId': driverId, 'codCollected': amount,
            'submitted': 0.0, 'pending': amount,
          });
        }
      });

  static Future<void> submitCash(String driverId, double amount) =>
      _db.runTransaction((tx) async {
        final ref = settlements.doc(driverId);
        final snap = await tx.get(ref);
        if (!snap.exists) return;
        final d = snap.data() as Map;
        final pending = ((d['pending'] ?? 0) as num).toDouble();
        tx.update(ref, {
          'submitted': (d['submitted'] ?? 0) + amount,
          'pending': (pending - amount).clamp(0, double.infinity),
        });
      });

  /// On delivery: increment todayOrders, add COD if applicable
  static Future<void> onDeliveryComplete({
    required String driverId,
    required bool isCod,
    required double amount,
  }) async {
    final batch = _db.batch();
    batch.update(drivers.doc(driverId), {
      'todayOrders': FieldValue.increment(1),
      if (isCod) 'codCollected': FieldValue.increment(amount),
    });
    if (isCod) {
      final sRef = settlements.doc(driverId);
      batch.set(sRef, {
        'driverId': driverId,
        'codCollected': FieldValue.increment(amount),
        'pending': FieldValue.increment(amount),
        'submitted': FieldValue.increment(0),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
