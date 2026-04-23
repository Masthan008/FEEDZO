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

  /// Watch settlement data for a specific driver
  static Stream<Map<String, dynamic>> watchSettlement(String driverId) {
    return FirebaseFirestore.instance.collection('settlements').doc(driverId).snapshots().map((doc) {
      if (!doc.exists) return {};
      return doc.data() as Map<String, dynamic>;
    });
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
  static Future<void> submitCash(String driverId, double amount, String notes) async {
    final db = FirebaseFirestore.instance;
    final ref = db.collection('settlements').doc(driverId);
    
    // Get driver info for the submission record
    final driverDoc = await db.collection('drivers').doc(driverId).get();
    final driverData = driverDoc.data() ?? {};
    final driverName = driverData['name'] ?? 'Unknown Driver';
    final driverPhone = driverData['phone'] ?? '';
    
    await db.runTransaction((tx) async {
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
    
    // Create submission record for admin visibility
    await db.collection('driverSubmissions').add({
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'amount': amount,
      'status': 'pending', // pending, verified, rejected
      'submittedAt': FieldValue.serverTimestamp(),
      'verifiedAt': null,
      'verifiedBy': null,
      'notes': notes,
    });
  }
}
