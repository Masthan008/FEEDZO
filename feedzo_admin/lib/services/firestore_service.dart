import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

class AdminFirestoreService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference get users => _db.collection('users');
  static CollectionReference get orders => _db.collection('orders');
  static CollectionReference get restaurants => _db.collection('restaurants');
  static CollectionReference get drivers => _db.collection('drivers');
  static CollectionReference get settlements => _db.collection('settlements');
  static CollectionReference get transactions => _db.collection('transactions');
  static CollectionReference get alerts => _db.collection('alerts');
  static CollectionReference get activities => _db.collection('activities');

  // ── Real-time streams ─────────────────────────────────────────────────────
  static Stream<QuerySnapshot> watchAllOrders() =>
      orders.orderBy('createdAt', descending: true).snapshots();

  static Stream<QuerySnapshot> watchPendingUsers() =>
      users.where('status', isEqualTo: 'pending').snapshots();

  static Stream<QuerySnapshot> watchAllUsers() => users.snapshots();

  static Stream<QuerySnapshot> watchAllRestaurants() =>
      restaurants.snapshots();

  static Stream<QuerySnapshot> watchAllDrivers() => drivers.snapshots();

  static Stream<QuerySnapshot> watchAllSettlements() =>
      settlements.snapshots();

  static Stream<QuerySnapshot> watchAllAlerts() =>
      alerts.orderBy('createdAt', descending: true).snapshots();

  static Stream<QuerySnapshot> watchActivityFeed() =>
      activities.orderBy('createdAt', descending: true).snapshots();

  // ── Approval system ───────────────────────────────────────────────────────
  static Future<void> approveUser(String uid) =>
      users.doc(uid).update({'status': 'approved'});

  static Future<void> rejectUser(String uid) =>
      users.doc(uid).update({'status': 'rejected'});

  static Future<void> approveRestaurant(String restaurantId) async {
    await restaurants.doc(restaurantId).update({'isApproved': true});
    await users.doc(restaurantId).update({'status': 'approved'});
  }

  static Future<void> rejectRestaurant(String restaurantId) async {
    await restaurants.doc(restaurantId).update({'isApproved': false});
    await users.doc(restaurantId).update({'status': 'rejected'});
  }

  static Future<void> approveDriver(String driverId) async {
    await drivers.doc(driverId).update({'isApproved': true});
    await users.doc(driverId).update({'status': 'approved'});
  }

  // ── Driver assignment ─────────────────────────────────────────────────────
  static Future<void> assignDriver(String orderId, String driverId) =>
      orders.doc(orderId).update({
        'driverId': driverId,
        'status': 'preparing',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static Future<void> updateOrderStatus(String orderId, String status) =>
      orders.doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ── Commission & payout ───────────────────────────────────────────────────
  static Future<void> setRestaurantCommission(
      String restaurantId, double commission) =>
      restaurants.doc(restaurantId).update({'commission': commission});

  static Future<void> releasePayout(
      String restaurantId, double amount) async {
    final batch = _db.batch();
    batch.update(restaurants.doc(restaurantId),
        {'wallet': FieldValue.increment(-amount)});
    batch.set(transactions.doc(), {
      'restaurantId': restaurantId,
      'amount': amount,
      'type': 'payout',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // ── COD settlement ────────────────────────────────────────────────────────
  static Future<void> markCashReceived(
    String driverId, 
    double amount,
    String driverName,
    String adminId,
  ) async {
    // Run transaction to update settlement
    await _db.runTransaction((tx) async {
      final ref = settlements.doc(driverId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final d = snap.data() as Map;
      final pending = ((d['pending'] ?? 0) as num).toDouble();
      final submitted = ((d['submitted'] ?? 0) as num).toDouble();
      
      tx.update(ref, {
        'submitted': submitted + amount,
        'pending': (pending - amount).clamp(0, double.infinity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    
    // Create submission record for audit trail
    await _db.collection('driverSubmissions').add({
      'driverId': driverId,
      'driverName': driverName,
      'amount': amount,
      'status': 'verified',
      'submittedAt': FieldValue.serverTimestamp(),
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedBy': adminId,
      'notes': 'Marked as received by admin',
    });
    
    // Add to activity feed
    await _db.collection('activities').add({
      'type': 'cash_submission',
      'title': 'Cash Received from Driver',
      'description': '₹${amount.toStringAsFixed(0)} received from $driverName',
      'amount': amount,
      'driverId': driverId,
      'driverName': driverName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
