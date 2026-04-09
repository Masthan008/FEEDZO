import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineService {
  static bool _isOnline = true;

  static Future<void> initialize() async {
    // Enable offline persistence
    await FirebaseFirestore.instance.enablePersistence(
      const PersistenceSettings(synchronizeWrites: true),
    );

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  static bool get isOnline => _isOnline;

  static Future<void> syncPendingOperations() async {
    if (!_isOnline) return;

    // Sync pending orders
    await _syncPendingOrders();

    // Sync pending reviews
    await _syncPendingReviews();

    // Sync pending profile updates
    await _syncPendingProfileUpdates();
  }

  static Future<void> _syncPendingOrders() async {
    final pendingOrders = await FirebaseFirestore.instance
        .collection('pending_orders')
        .where('synced', isEqualTo: false)
        .get();

    for (var doc in pendingOrders.docs) {
      final data = doc.data();
      await FirebaseFirestore.instance
          .collection('orders')
          .add(data);
      await doc.reference.update({'synced': true});
    }
  }

  static Future<void> _syncPendingReviews() async {
    final pendingReviews = await FirebaseFirestore.instance
        .collection('pending_reviews')
        .where('synced', isEqualTo: false)
        .get();

    for (var doc in pendingReviews.docs) {
      final data = doc.data();
      await FirebaseFirestore.instance
          .collection('reviews')
          .add(data);
      await doc.reference.update({'synced': true});
    }
  }

  static Future<void> _syncPendingProfileUpdates() async {
    final pendingUpdates = await FirebaseFirestore.instance
        .collection('pending_profile_updates')
        .where('synced', isEqualTo: false)
        .get();

    for (var doc in pendingUpdates.docs) {
      final data = doc.data();
      final userId = data['userId'];
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(data['updates']);
      await doc.reference.update({'synced': true});
    }
  }

  static Future<void> saveOrderForSync(Map<String, dynamic> orderData) async {
    await FirebaseFirestore.instance.collection('pending_orders').add({
      ...orderData,
      'synced': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveReviewForSync(Map<String, dynamic> reviewData) async {
    await FirebaseFirestore.instance.collection('pending_reviews').add({
      ...reviewData,
      'synced': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveProfileUpdateForSync(String userId, Map<String, dynamic> updates) async {
    await FirebaseFirestore.instance.collection('pending_profile_updates').add({
      'userId': userId,
      'updates': updates,
      'synced': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
