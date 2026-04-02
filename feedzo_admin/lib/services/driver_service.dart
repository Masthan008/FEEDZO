import 'package:cloud_firestore/cloud_firestore.dart';

class DriverService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _drivers => _db.collection('drivers');
  CollectionReference get _settlements => _db.collection('settlements');

  /// Stream all drivers
  Stream<QuerySnapshot> streamAllDrivers() => _drivers.snapshots();

  /// Stream available drivers only
  Stream<QuerySnapshot> streamAvailableDrivers() =>
      _drivers.where('status', isEqualTo: 'available').snapshots();

  /// Update driver status
  Future<void> updateStatus(String driverId, String status) =>
      _drivers.doc(driverId).update({'status': status});

  /// Stream settlement for a driver
  Stream<DocumentSnapshot> streamSettlement(String driverId) =>
      _settlements.doc(driverId).snapshots();

  /// Mark cash received from driver
  Future<void> markCashReceived(String driverId, double amount) async {
    final ref = _settlements.doc(driverId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        final current = (snap.data() as Map)['submitted'] as double? ?? 0;
        final pending = (snap.data() as Map)['pending'] as double? ?? 0;
        tx.update(ref, {
          'submitted': current + amount,
          'pending': (pending - amount).clamp(0, double.infinity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(ref, {
          'driverId': driverId,
          'codCollected': amount,
          'submitted': amount,
          'pending': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Get all settlements (admin overview)
  Stream<QuerySnapshot> streamAllSettlements() => _settlements.snapshots();
}
