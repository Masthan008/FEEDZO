import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cash_limit_model.dart';

class CashLimitService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _limits = _db.collection('driverCashLimits');

  static Stream<List<CashLimitModel>> watchAllLimits() {
    return _limits.orderBy('driverName').snapshots().map((snap) {
      return snap.docs.map((doc) => CashLimitModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<CashLimitModel?> watchDriverLimit(String driverId) {
    return _limits.where('driverId', isEqualTo: driverId).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return CashLimitModel.fromFirestore(snap.docs.first);
    });
  }

  static Future<CashLimitModel?> getDriverLimit(String driverId) async {
    final snapshot = await _limits.where('driverId', isEqualTo: driverId).get();
    if (snapshot.docs.isEmpty) return null;
    return CashLimitModel.fromFirestore(snapshot.docs.first);
  }

  static Future<String> setLimit(CashLimitModel limit) async {
    final existing = await _limits.where('driverId', isEqualTo: limit.driverId).get();
    if (existing.docs.isEmpty) {
      final docRef = await _limits.add(limit.toMap());
      return docRef.id;
    } else {
      await _limits.doc(existing.docs.first.id).update(limit.toUpdateMap());
      return existing.docs.first.id;
    }
  }

  static Future<void> updateLimit(CashLimitModel limit) async {
    await _limits.doc(limit.id).update(limit.toUpdateMap());
  }

  static Future<void> updateCurrentCash(String driverId, double currentCash) async {
    final snapshot = await _limits.where('driverId', isEqualTo: driverId).get();
    if (snapshot.docs.isEmpty) return;
    await _limits.doc(snapshot.docs.first.id).update({
      'currentCash': currentCash,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteLimit(String id) async {
    await _limits.doc(id).delete();
  }
}
