import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _restaurants => _db.collection('restaurants');
  CollectionReference get _transactions => _db.collection('transactions');

  /// Stream all restaurants
  Stream<QuerySnapshot> streamAllRestaurants() => _restaurants.snapshots();

  /// Update commission rate for a restaurant
  Future<void> setCommission(String restaurantId, double rate) =>
      _restaurants.doc(restaurantId).update({'commission_percent': rate});

  /// Release payout to restaurant
  Future<void> releasePayout(String restaurantId, double amount) async {
    final batch = _db.batch();
    batch.update(_restaurants.doc(restaurantId), {
      'wallet_balance': FieldValue.increment(-amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_transactions.doc(), {
      'restaurantId': restaurantId,
      'amount': amount,
      'type': 'payout',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Credit commission to restaurant wallet after order delivered
  Future<void> creditWallet(String restaurantId, double amount, String orderId) async {
    final batch = _db.batch();
    batch.update(_restaurants.doc(restaurantId), {
      'wallet_balance': FieldValue.increment(amount),
    });
    batch.set(_transactions.doc(), {
      'restaurantId': restaurantId,
      'orderId': orderId,
      'amount': amount,
      'type': 'commission',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Stream transactions for a restaurant
  Stream<QuerySnapshot> streamTransactions(String restaurantId) =>
      _transactions.where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true).snapshots();
}
