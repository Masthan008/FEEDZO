import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettlementService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _driverId => _auth.currentUser?.uid;

  /// Stream this driver's settlement document
  Stream<DocumentSnapshot> streamMySettlement() {
    if (_driverId == null) return const Stream.empty();
    return _db.collection('settlements').doc(_driverId).snapshots();
  }

  /// Record COD collected for an order
  Future<void> recordCodCollected(String orderId, double amount) async {
    if (_driverId == null) return;
    final ref = _db.collection('settlements').doc(_driverId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        final collected = (snap.data() as Map)['codCollected'] as double? ?? 0;
        final pending = (snap.data() as Map)['pending'] as double? ?? 0;
        tx.update(ref, {
          'codCollected': collected + amount,
          'pending': pending + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(ref, {
          'driverId': _driverId,
          'codCollected': amount,
          'submitted': 0.0,
          'pending': amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Submit cash to admin
  Future<void> submitCash(double amount) async {
    if (_driverId == null) return;
    final ref = _db.collection('settlements').doc(_driverId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final submitted = (snap.data() as Map)['submitted'] as double? ?? 0;
      final pending = (snap.data() as Map)['pending'] as double? ?? 0;
      tx.update(ref, {
        'submitted': submitted + amount,
        'pending': (pending - amount).clamp(0, double.infinity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
