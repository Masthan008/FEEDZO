import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/split_payment_model.dart';

class SplitPaymentService {
  static final _db = FirebaseFirestore.instance;

  static Future<String> createSplitPayment({
    required String orderId,
    required double totalAmount,
    required List<SplitPaymentPart> splits,
  }) async {
    final docRef = await _db.collection('splitPayments').add({
      'orderId': orderId,
      'totalAmount': totalAmount,
      'splits': splits.map((s) => s.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Stream<SplitPaymentModel?> watchSplitPayment(String orderId) {
    return _db
        .collection('splitPayments')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return SplitPaymentModel.fromFirestore(snap.docs.first);
    });
  }

  static Future<void> updateSplitPaymentStatus(
    String splitPaymentId,
    String userId,
    String status,
  ) async {
    final doc = await _db.collection('splitPayments').doc(splitPaymentId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final splits = (data['splits'] as List).cast<Map<String, dynamic>>();

    final updatedSplits = splits.map((split) {
      if (split['userId'] == userId) {
        split['status'] = status;
        if (status == 'paid') {
          split['paidAt'] = FieldValue.serverTimestamp();
        }
      }
      return split;
    }).toList();

    await doc.reference.update({
      'splits': updatedSplits,
    });
  }

  static Future<bool> isFullyPaid(String splitPaymentId) async {
    final doc = await _db.collection('splitPayments').doc(splitPaymentId).get();
    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>;
    final splits = (data['splits'] as List).cast<Map<String, dynamic>>();

    return splits.every((split) => split['status'] == 'paid');
  }
}
