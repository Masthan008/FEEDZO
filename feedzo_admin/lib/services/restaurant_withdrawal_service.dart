import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_withdrawal_model.dart';

class RestaurantWithdrawalService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _withdrawals = _db.collection('restaurantWithdrawals');
  static final CollectionReference _withdrawalMethods = _db.collection('withdrawalMethods');

  static Stream<List<RestaurantWithdrawalModel>> watchAllWithdrawals() {
    return _withdrawals.orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => RestaurantWithdrawalModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<RestaurantWithdrawalModel>> watchWithdrawalsByStatus(String status) {
    return _withdrawals
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => RestaurantWithdrawalModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<RestaurantWithdrawalModel>> watchRestaurantWithdrawals(String restaurantId) {
    return _withdrawals
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => RestaurantWithdrawalModel.fromFirestore(doc)).toList();
    });
  }

  static Future<RestaurantWithdrawalModel?> getWithdrawalById(String id) async {
    final doc = await _withdrawals.doc(id).get();
    if (!doc.exists) return null;
    return RestaurantWithdrawalModel.fromFirestore(doc);
  }

  static Future<String> createWithdrawal(RestaurantWithdrawalModel withdrawal) async {
    final docRef = await _withdrawals.add(withdrawal.toMap());
    return docRef.id;
  }

  static Future<void> approveWithdrawal(String id, String processedBy) async {
    await _withdrawals.doc(id).update({
      'status': 'completed',
      'processedAt': FieldValue.serverTimestamp(),
      'processedBy': processedBy,
    });
  }

  static Future<void> rejectWithdrawal(String id, String reason, String processedBy) async {
    await _withdrawals.doc(id).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'processedAt': FieldValue.serverTimestamp(),
      'processedBy': processedBy,
    });
  }

  static Future<void> processWithdrawal(String id, String processedBy) async {
    await _withdrawals.doc(id).update({
      'status': 'processing',
      'processedAt': FieldValue.serverTimestamp(),
      'processedBy': processedBy,
    });
  }

  static Stream<List<WithdrawalMethodConfig>> watchWithdrawalMethods() {
    return _withdrawalMethods.snapshots().map((snap) {
      return snap.docs.map((doc) => WithdrawalMethodConfig.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  static Future<void> addWithdrawalMethod(WithdrawalMethodConfig method) async {
    await _withdrawalMethods.add(method.toMap());
  }

  static Future<void> updateWithdrawalMethod(String id, WithdrawalMethodConfig method) async {
    await _withdrawals.doc(id).update(method.toMap());
  }

  static Future<void> deleteWithdrawalMethod(String id) async {
    await _withdrawals.doc(id).delete();
  }
}
