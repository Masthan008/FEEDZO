import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tip_model.dart';

class TipService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _tips = _db.collection('tips');

  static Stream<List<TipModel>> watchAllTips() {
    return _tips.orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => TipModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<TipModel>> watchDriverTips(String driverId) {
    return _tips
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => TipModel.fromFirestore(doc)).toList();
    });
  }

  static Future<double> getTotalTipsForDriver(String driverId) async {
    final snapshot = await _tips.where('driverId', isEqualTo: driverId).get();
    double total = 0;
    for (var doc in snapshot.docs) {
      final tip = TipModel.fromFirestore(doc);
      total += tip.amount;
    }
    return total;
  }

  static Future<String> addTip(TipModel tip) async {
    final docRef = await _tips.add(tip.toMap());
    return docRef.id;
  }

  static Future<void> deleteTip(String id) async {
    await _tips.doc(id).delete();
  }
}
