import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hike_charges_model.dart';

class HikeChargesService {
  static final _db = FirebaseFirestore.instance;
  static const String _globalConfigId = 'global';

  static CollectionReference get _hikeCharges => _db.collection('hikeCharges');
  static CollectionReference get _restaurantOverrides => _db.collection('restaurantHikeOverrides');

  /// Watch global hike charges configuration
  static Stream<HikeChargesConfig?> watchGlobalConfig() {
    return _hikeCharges.doc(_globalConfigId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return HikeChargesConfig.fromMap(snap.id, snap.data() as Map<String, dynamic>);
    });
  }

  /// Get global config once
  static Future<HikeChargesConfig?> getGlobalConfig() async {
    final snap = await _hikeCharges.doc(_globalConfigId).get();
    if (!snap.exists || snap.data() == null) return null;
    return HikeChargesConfig.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }

  /// Watch restaurant-specific override
  static Stream<RestaurantHikeOverride?> watchRestaurantOverride(String restaurantId) {
    return _restaurantOverrides.doc(restaurantId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return RestaurantHikeOverride.fromMap(snap.id, snap.data() as Map<String, dynamic>);
    });
  }

  /// Save restaurant hike charge override
  static Future<void> saveRestaurantOverride({
    required String restaurantId,
    required bool useGlobalSettings,
    double? customPackagingCharges,
    double? customDeliveryCharges,
    double? customHikeMultiplier,
    double? customCommissionPlus,
  }) async {
    await _restaurantOverrides.doc(restaurantId).set({
      'restaurantId': restaurantId,
      'useGlobalSettings': useGlobalSettings,
      'customPackagingCharges': customPackagingCharges,
      'customDeliveryCharges': customDeliveryCharges,
      'customHikeMultiplier': customHikeMultiplier,
      'customCommissionPlus': customCommissionPlus,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Delete restaurant override (revert to global settings)
  static Future<void> deleteRestaurantOverride(String restaurantId) async {
    await _restaurantOverrides.doc(restaurantId).delete();
  }

  /// Get effective hike charges for a restaurant
  static Stream<EffectiveHikeCharges> watchEffectiveCharges(String restaurantId) {
    return _hikeCharges.doc(_globalConfigId).snapshots().asyncMap((globalSnap) async {
      HikeChargesConfig? globalConfig;
      if (globalSnap.exists && globalSnap.data() != null) {
        globalConfig = HikeChargesConfig.fromMap(
          globalSnap.id,
          globalSnap.data() as Map<String, dynamic>,
        );
      }

      // Default values if no config exists
      globalConfig ??= HikeChargesConfig(
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

      // Check for override
      final overrideSnap = await _restaurantOverrides.doc(restaurantId).get();
      RestaurantHikeOverride? override;
      if (overrideSnap.exists && overrideSnap.data() != null) {
        override = RestaurantHikeOverride.fromMap(
          overrideSnap.id,
          overrideSnap.data() as Map<String, dynamic>,
        );
      }

      // Build effective charges
      final hasCustomSettings = override != null && !override.useGlobalSettings;

      return EffectiveHikeCharges(
        restaurantId: restaurantId,
        packagingCharges: hasCustomSettings && override.customPackagingCharges != null
            ? override.customPackagingCharges!
            : globalConfig.packagingCharges,
        deliveryCharges: hasCustomSettings && override.customDeliveryCharges != null
            ? override.customDeliveryCharges!
            : globalConfig.deliveryCharges,
        deliveryChargePerKm: globalConfig.deliveryChargePerKm,
        hikeMultiplier: hasCustomSettings && override.customHikeMultiplier != null
            ? override.customHikeMultiplier!
            : globalConfig.hikeMultiplier,
        commissionPlus: hasCustomSettings && override.customCommissionPlus != null
            ? override.customCommissionPlus!
            : globalConfig.commissionPlus,
        minimumOrderValue: globalConfig.minimumOrderValue,
        smallOrderFee: globalConfig.smallOrderFee,
        surgeEnabled: globalConfig.surgeEnabled,
        hasCustomSettings: hasCustomSettings,
      );
    });
  }
}
