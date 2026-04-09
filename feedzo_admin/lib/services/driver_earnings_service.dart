import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_earnings_model.dart';

class DriverEarningsService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _earnings = _db.collection('driverEarnings');

  static Stream<List<DriverEarningsModel>> watchAllEarnings() {
    return _earnings.orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => DriverEarningsModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<DriverEarningsModel>> watchDriverEarnings(String driverId) {
    return _earnings
        .where('driverId', isEqualTo: driverId)
        .orderBy('periodStart', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => DriverEarningsModel.fromFirestore(doc)).toList();
    });
  }

  static Future<String> addEarnings(DriverEarningsModel earnings) async {
    final docRef = await _earnings.add(earnings.toMap());
    return docRef.id;
  }

  static Future<void> deleteEarnings(String id) async {
    await _earnings.doc(id).delete();
  }
}
