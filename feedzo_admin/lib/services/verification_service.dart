import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/verification_model.dart';

class VerificationService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _verifications = _db.collection('customerVerifications');

  static Stream<List<VerificationModel>> watchAllVerifications() {
    return _verifications.orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => VerificationModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<VerificationModel>> watchPendingVerifications() {
    return _verifications
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => VerificationModel.fromFirestore(doc)).toList();
    });
  }

  static Future<String> addVerification(VerificationModel verification) async {
    final docRef = await _verifications.add(verification.toMap());
    return docRef.id;
  }

  static Future<void> approveVerification(String id, String reviewedBy) async {
    await _verifications.doc(id).update({
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewedBy,
    });
  }

  static Future<void> rejectVerification(String id, String reason, String reviewedBy) async {
    await _verifications.doc(id).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewedBy,
    });
  }

  static Future<void> deleteVerification(String id) async {
    await _verifications.doc(id).delete();
  }
}
