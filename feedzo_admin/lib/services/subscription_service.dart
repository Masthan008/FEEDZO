import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _subscriptions = _db.collection('subscriptions');
  static final CollectionReference _restaurantSubscriptions = _db.collection('restaurantSubscriptions');

  static Stream<List<SubscriptionModel>> watchAllSubscriptions() {
    return _subscriptions.orderBy('price').snapshots().map((snap) {
      return snap.docs.map((doc) => SubscriptionModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<SubscriptionModel>> watchActiveSubscriptions() {
    return _subscriptions
        .where('isActive', isEqualTo: true)
        .orderBy('price')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => SubscriptionModel.fromFirestore(doc)).toList();
    });
  }

  static Future<SubscriptionModel?> getSubscriptionById(String id) async {
    final doc = await _subscriptions.doc(id).get();
    if (!doc.exists) return null;
    return SubscriptionModel.fromFirestore(doc);
  }

  static Future<String> addSubscription(SubscriptionModel subscription) async {
    final docRef = await _subscriptions.add(subscription.toMap());
    return docRef.id;
  }

  static Future<void> updateSubscription(SubscriptionModel subscription) async {
    await _subscriptions.doc(subscription.id).update(subscription.toUpdateMap());
  }

  static Future<void> deleteSubscription(String id) async {
    await _subscriptions.doc(id).delete();
  }

  static Future<void> toggleSubscriptionStatus(String id, bool isActive) async {
    await _subscriptions.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<RestaurantSubscription>> watchRestaurantSubscriptions(String restaurantId) {
    return _restaurantSubscriptions
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => RestaurantSubscription.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<RestaurantSubscription>> watchAllRestaurantSubscriptions() {
    return _restaurantSubscriptions
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => RestaurantSubscription.fromFirestore(doc)).toList();
    });
  }

  static Future<String> assignSubscriptionToRestaurant(
    String restaurantId,
    String subscriptionId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final docRef = await _restaurantSubscriptions.add({
      'restaurantId': restaurantId,
      'subscriptionId': subscriptionId,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<void> cancelRestaurantSubscription(String id) async {
    await _restaurantSubscriptions.doc(id).update({
      'isActive': false,
    });
  }
}
