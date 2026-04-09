import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/zone_model.dart';

class ZoneService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _zones = _db.collection('zones');

  /// Get all zones
  static Stream<List<ZoneModel>> watchAllZones() {
    return _zones.orderBy('name').snapshots().map((snap) {
      return snap.docs.map((doc) => ZoneModel.fromFirestore(doc)).toList();
    });
  }

  /// Get active zones only
  static Stream<List<ZoneModel>> watchActiveZones() {
    return _zones
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => ZoneModel.fromFirestore(doc)).toList();
    });
  }

  /// Get zone by ID
  static Future<ZoneModel?> getZoneById(String id) async {
    final doc = await _zones.doc(id).get();
    if (!doc.exists) return null;
    return ZoneModel.fromFirestore(doc);
  }

  /// Add new zone
  static Future<String> addZone(ZoneModel zone) async {
    final docRef = await _zones.add(zone.toMap());
    return docRef.id;
  }

  /// Update zone
  static Future<void> updateZone(ZoneModel zone) async {
    await _zones.doc(zone.id).update(zone.toUpdateMap());
  }

  /// Delete zone
  static Future<void> deleteZone(String id) async {
    await _zones.doc(id).delete();
  }

  /// Toggle zone active status
  static Future<void> toggleZoneStatus(String id, bool isActive) async {
    await _zones.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Calculate delivery charge for a zone based on distance
  static Future<double> calculateDeliveryCharge(
    String zoneId,
    double distanceKm,
  ) async {
    final zone = await getZoneById(zoneId);
    if (zone == null) return 20.0; // Default charge
    return zone.baseDeliveryCharge + (zone.perKmCharge * distanceKm);
  }
}
