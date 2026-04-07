import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hike_charges_model.dart';

class HikeChargesService {
  static final _db = FirebaseFirestore.instance;
  static const String _globalConfigId = 'global';

  static CollectionReference get _hikeCharges => _db.collection('hikeCharges');
  static CollectionReference get _restaurantOverrides => _db.collection('restaurantHikeOverrides');

  /// Get global hike charges configuration
  static Future<HikeChargesConfig?> getGlobalConfig() async {
    final snap = await _hikeCharges.doc(_globalConfigId).get();
    if (!snap.exists || snap.data() == null) return null;
    return HikeChargesConfig.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }

  /// Watch global config changes
  static Stream<HikeChargesConfig?> watchGlobalConfig() {
    return _hikeCharges.doc(_globalConfigId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return HikeChargesConfig.fromMap(snap.id, snap.data() as Map<String, dynamic>);
    });
  }

  /// Get restaurant-specific override
  static Future<RestaurantHikeOverride?> getRestaurantOverride(String restaurantId) async {
    final snap = await _restaurantOverrides.doc(restaurantId).get();
    if (!snap.exists || snap.data() == null) return null;
    return RestaurantHikeOverride.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }

  /// Calculate effective charges for a restaurant
  static Future<Map<String, dynamic>> calculateCharges({
    required String restaurantId,
    required double orderValue,
    required double distanceKm,
  }) async {
    final globalConfig = await getGlobalConfig();
    final override = await getRestaurantOverride(restaurantId);

    // Default values if no config exists
    final defaultConfig = HikeChargesConfig(
      id: 'default',
      packagingCharges: 10,
      deliveryCharges: 20,
      deliveryChargePerKm: 5,
      hikeMultiplier: 0,
      commissionPlus: 0,
      minimumOrderValue: 0,
      smallOrderFee: 0,
      surgeEnabled: false,
      updatedAt: DateTime.now(),
    );

    final config = globalConfig ?? defaultConfig;

    // Apply override if exists and not using global settings
    final hasCustomSettings = override != null && !override.useGlobalSettings;

    final packaging = hasCustomSettings && override.customPackagingCharges != null
        ? override.customPackagingCharges!
        : config.packagingCharges;

    final delivery = hasCustomSettings && override.customDeliveryCharges != null
        ? override.customDeliveryCharges!
        : config.deliveryCharges;

    final perKm = config.deliveryChargePerKm;
    final minOrder = config.minimumOrderValue;
    final smallFee = config.smallOrderFee;
    final multiplier = hasCustomSettings && override.customHikeMultiplier != null
        ? override.customHikeMultiplier!
        : config.hikeMultiplier;

    // Calculate charges
    final packagingCharge = packaging;
    final deliveryCharge = delivery + (perKm * distanceKm);
    double smallOrderCharge = 0;
    if (minOrder > 0 && orderValue < minOrder) {
      smallOrderCharge = smallFee;
    }

    final baseCharges = packagingCharge + deliveryCharge + smallOrderCharge;

    // Check surge
    final now = DateTime.now();
    final isSurge = config.surgeEnabled && 
        (config.peakHoursStart == null || 
         (now.hour >= config.peakHoursStart!.hour && now.hour <= config.peakHoursEnd!.hour));
    
    double surgeCharge = 0;
    if (isSurge && multiplier > 0) {
      surgeCharge = baseCharges * (multiplier / 100);
    }

    return {
      'packagingCharge': packagingCharge,
      'deliveryCharge': deliveryCharge,
      'smallOrderFee': smallOrderCharge,
      'surgeCharge': surgeCharge,
      'totalHike': baseCharges + surgeCharge,
      'isSurge': isSurge && multiplier > 0,
      'hikeMultiplier': isSurge ? multiplier : 0,
    };
  }
}
