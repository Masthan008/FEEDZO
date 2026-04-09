import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payout_request_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PayoutService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _payoutRequests = _db.collection('restaurantPayoutRequests');

  static Stream<List<PayoutRequestModel>> watchPayouts(String restaurantId) {
    return _payoutRequests
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PayoutRequestModel.fromFirestore(doc))
            .toList());
  }

  static Future<List<PayoutRequestModel>> getPayouts(String restaurantId) async {
    final snapshot = await _payoutRequests
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('requestedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => PayoutRequestModel.fromFirestore(doc))
        .toList();
  }

  static Future<String> requestPayout({
    required String restaurantId,
    required String restaurantName,
    required double amount,
    required String bankAccount,
    required String ifscCode,
    required String accountHolderName,
  }) async {
    final docRef = await _payoutRequests.add({
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'amount': amount,
      'status': 'pending',
      'bankAccount': bankAccount,
      'ifscCode': ifscCode,
      'accountHolderName': accountHolderName,
      'requestedAt': FieldValue.serverTimestamp(),
      'approvedAt': null,
      'completedAt': null,
      'approvedBy': null,
      'rejectionReason': null,
      'transactionId': null,
    });
    return docRef.id;
  }

  static Future<double> getAvailableBalance(String restaurantId) async {
    // Get total earnings minus already requested payouts
    final transactions = await _db
        .collection('transactions')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    final totalEarnings = transactions.docs.fold<double>(
      0,
      (sum, doc) => sum + (doc.data()['amount'] as num).toDouble(),
    );

    final pendingPayouts = await _payoutRequests
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', whereIn: ['pending', 'approved'])
        .get();

    final requestedAmount = pendingPayouts.docs.fold<double>(
      0,
      (sum, doc) => sum + (doc.data()['amount'] as num).toDouble(),
    );

    return totalEarnings - requestedAmount;
  }
}
