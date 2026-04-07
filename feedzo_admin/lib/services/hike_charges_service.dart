import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models.dart';

class HikeChargesService {
  static final _db = FirebaseFirestore.instance;
  static const String _globalConfigId = 'global';

  // ── Global Config ───────────────────────────────────────────────────────────

  static CollectionReference get _hikeCharges => _db.collection('hikeCharges');
  static CollectionReference get _restaurantOverrides => _db.collection('restaurantHikeOverrides');

  /// Get global hike charges configuration stream
  static Stream<HikeChargesConfig?> watchGlobalConfig() {
    return _hikeCharges.doc(_globalConfigId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return HikeChargesConfig.fromMap(snap.id, snap.data() as Map<String, dynamic>);
    });
  }

  /// Get global config once (for calculations)
  static Future<HikeChargesConfig?> getGlobalConfig() async {
    final snap = await _hikeCharges.doc(_globalConfigId).get();
    if (!snap.exists || snap.data() == null) return null;
    return HikeChargesConfig.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }

  /// Create or update global hike charges config
  static Future<void> saveGlobalConfig(HikeChargesConfig config) async {
    await _hikeCharges.doc(_globalConfigId).set({
      ...config.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Initialize default global config if not exists
  static Future<void> initializeDefaultConfig() async {
    final snap = await _hikeCharges.doc(_globalConfigId).get();
    if (!snap.exists) {
      final defaultConfig = HikeChargesConfig(
        id: _globalConfigId,
        packagingCharges: 10,
        deliveryCharges: 20,
        deliveryChargePerKm: 5,
        hikeMultiplier: 10,
        commissionPlus: 2,
        minimumOrderValue: 100,
        smallOrderFee: 15,
        surgeEnabled: false,
        updatedAt: DateTime.now(),
      );
      await _hikeCharges.doc(_globalConfigId).set(defaultConfig.toMap());
    }
  }

  // ── Restaurant Overrides ────────────────────────────────────────────────────

  /// Get restaurant-specific hike override stream
  static Stream<RestaurantHikeOverride?> watchRestaurantOverride(String restaurantId) {
    return _restaurantOverrides.doc(restaurantId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return RestaurantHikeOverride.fromMap(snap.id, snap.data() as Map<String, dynamic>);
    });
  }

  /// Get restaurant override once
  static Future<RestaurantHikeOverride?> getRestaurantOverride(String restaurantId) async {
    final snap = await _restaurantOverrides.doc(restaurantId).get();
    if (!snap.exists || snap.data() == null) return null;
    return RestaurantHikeOverride.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }

  /// Save restaurant override
  static Future<void> saveRestaurantOverride(RestaurantHikeOverride override) async {
    await _restaurantOverrides.doc(override.restaurantId).set({
      ...override.toMap(),
      'restaurantId': override.restaurantId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Delete restaurant override (revert to global)
  static Future<void> deleteRestaurantOverride(String restaurantId) async {
    await _restaurantOverrides.doc(restaurantId).delete();
  }

  /// Get all restaurant overrides
  static Stream<List<RestaurantHikeOverride>> watchAllOverrides() {
    return _restaurantOverrides.snapshots().map((snap) {
      return snap.docs.map((doc) =>
        RestaurantHikeOverride.fromMap(doc.id, doc.data() as Map<String, dynamic>)
      ).toList();
    });
  }

  // ── Calculation Helpers ──────────────────────────────────────────────────────

  /// Calculate effective charges for a restaurant (considering overrides)
  static Future<Map<String, double>> calculateEffectiveCharges({
    required String restaurantId,
    required double orderValue,
    required double distanceKm,
    bool isPeakHours = false,
  }) async {
    final globalConfig = await getGlobalConfig();
    final override = await getRestaurantOverride(restaurantId);

    if (globalConfig == null) {
      return {
        'packaging': 0,
        'delivery': 0,
        'hike': 0,
        'totalHike': 0,
        'commission': 0,
      };
    }

    // Use override values if available and not using global settings
    final packaging = (override != null && !override.useGlobalSettings && override.customPackagingCharges != null)
        ? override.customPackagingCharges!
        : globalConfig.packagingCharges;

    final delivery = (override != null && !override.useGlobalSettings && override.customDeliveryCharges != null)
        ? override.customDeliveryCharges!
        : globalConfig.deliveryCharges;

    final perKm = globalConfig.deliveryChargePerKm;

    // Calculate hike multiplier
    var hikeMultiplier = globalConfig.hikeMultiplier;
    if (override != null && !override.useGlobalSettings && override.customHikeMultiplier != null) {
      hikeMultiplier = override.customHikeMultiplier!;
    }

    // Base hike calculation
    double totalHike = packaging + delivery + (perKm * distanceKm);

    // Add small order fee
    if (orderValue < globalConfig.minimumOrderValue && globalConfig.minimumOrderValue > 0) {
      totalHike += globalConfig.smallOrderFee;
    }

    // Apply surge
    if (globalConfig.surgeEnabled && isPeakHours && hikeMultiplier > 0) {
      totalHike *= (1 + hikeMultiplier / 100);
    }

    return {
      'packaging': packaging,
      'delivery': delivery + (perKm * distanceKm),
      'hike': hikeMultiplier,
      'totalHike': totalHike,
      'commission': globalConfig.calculateCommission(orderValue, 0.10), // 10% base assumed
    };
  }
}
