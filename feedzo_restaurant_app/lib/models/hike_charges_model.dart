import 'package:cloud_firestore/cloud_firestore.dart';

/// Hike charges configuration for restaurant view
class HikeChargesConfig {
  final String id;
  final double packagingCharges;
  final double deliveryCharges;
  final double deliveryChargePerKm;
  final double hikeMultiplier;
  final double commissionPlus;
  final double minimumOrderValue;
  final double smallOrderFee;
  final bool surgeEnabled;
  final DateTime updatedAt;

  HikeChargesConfig({
    required this.id,
    required this.packagingCharges,
    required this.deliveryCharges,
    required this.deliveryChargePerKm,
    required this.hikeMultiplier,
    required this.commissionPlus,
    required this.minimumOrderValue,
    required this.smallOrderFee,
    required this.surgeEnabled,
    required this.updatedAt,
  });

  factory HikeChargesConfig.fromMap(String id, Map<String, dynamic> map) {
    return HikeChargesConfig(
      id: id,
      packagingCharges: ((map['packagingCharges'] ?? 0) as num).toDouble(),
      deliveryCharges: ((map['deliveryCharges'] ?? 0) as num).toDouble(),
      deliveryChargePerKm: ((map['deliveryChargePerKm'] ?? 0) as num).toDouble(),
      hikeMultiplier: ((map['hikeMultiplier'] ?? 0) as num).toDouble(),
      commissionPlus: ((map['commissionPlus'] ?? 0) as num).toDouble(),
      minimumOrderValue: ((map['minimumOrderValue'] ?? 0) as num).toDouble(),
      smallOrderFee: ((map['smallOrderFee'] ?? 0) as num).toDouble(),
      surgeEnabled: map['surgeEnabled'] as bool? ?? false,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  double get totalCommissionRate => 10 + commissionPlus; // Base 10% + commission plus

  /// Calculate delivery charge for a given distance
  double calculateDeliveryCharge(double distanceKm) {
    return deliveryCharges + (deliveryChargePerKm * distanceKm);
  }

  /// Calculate total charges for an order
  double calculateTotalCharges({
    required double orderValue,
    required double distanceKm,
    bool isPeakHours = false,
  }) {
    double total = packagingCharges + calculateDeliveryCharge(distanceKm);

    // Add small order fee if applicable
    if (orderValue < minimumOrderValue && minimumOrderValue > 0) {
      total += smallOrderFee;
    }

    // Apply surge multiplier
    if (surgeEnabled && isPeakHours && hikeMultiplier > 0) {
      total *= (1 + hikeMultiplier / 100);
    }

    return total;
  }

  /// Calculate commission on order value
  double calculateCommission(double orderValue) {
    return orderValue * (totalCommissionRate / 100);
  }
}

/// Restaurant-specific hike override
class RestaurantHikeOverride {
  final String restaurantId;
  final double? customPackagingCharges;
  final double? customDeliveryCharges;
  final double? customHikeMultiplier;
  final double? customCommissionPlus;
  final bool useGlobalSettings;
  final DateTime updatedAt;

  RestaurantHikeOverride({
    required this.restaurantId,
    this.customPackagingCharges,
    this.customDeliveryCharges,
    this.customHikeMultiplier,
    this.customCommissionPlus,
    required this.useGlobalSettings,
    required this.updatedAt,
  });

  factory RestaurantHikeOverride.fromMap(String id, Map<String, dynamic> map) {
    return RestaurantHikeOverride(
      restaurantId: id,
      customPackagingCharges: map['customPackagingCharges'] != null
          ? ((map['customPackagingCharges'] as num).toDouble())
          : null,
      customDeliveryCharges: map['customDeliveryCharges'] != null
          ? ((map['customDeliveryCharges'] as num).toDouble())
          : null,
      customHikeMultiplier: map['customHikeMultiplier'] != null
          ? ((map['customHikeMultiplier'] as num).toDouble())
          : null,
      customCommissionPlus: map['customCommissionPlus'] != null
          ? ((map['customCommissionPlus'] as num).toDouble())
          : null,
      useGlobalSettings: map['useGlobalSettings'] as bool? ?? true,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Effective hike charges for a specific restaurant (combining global + override)
class EffectiveHikeCharges {
  final String restaurantId;
  final double packagingCharges;
  final double deliveryCharges;
  final double deliveryChargePerKm;
  final double hikeMultiplier;
  final double commissionPlus;
  final double minimumOrderValue;
  final double smallOrderFee;
  final bool surgeEnabled;
  final bool hasCustomSettings;

  EffectiveHikeCharges({
    required this.restaurantId,
    required this.packagingCharges,
    required this.deliveryCharges,
    required this.deliveryChargePerKm,
    required this.hikeMultiplier,
    required this.commissionPlus,
    required this.minimumOrderValue,
    required this.smallOrderFee,
    required this.surgeEnabled,
    required this.hasCustomSettings,
  });

  double get totalCommissionRate => 10 + commissionPlus;

  double get baseDeliveryCharge => deliveryCharges;

  double calculateDeliveryCharge(double distanceKm) {
    return deliveryCharges + (deliveryChargePerKm * distanceKm);
  }

  double calculateTotalCharges({
    required double orderValue,
    required double distanceKm,
    bool isPeakHours = false,
  }) {
    double total = packagingCharges + calculateDeliveryCharge(distanceKm);

    if (orderValue < minimumOrderValue && minimumOrderValue > 0) {
      total += smallOrderFee;
    }

    if (surgeEnabled && isPeakHours && hikeMultiplier > 0) {
      total *= (1 + hikeMultiplier / 100);
    }

    return total;
  }

  double calculateCommission(double orderValue) {
    return orderValue * (totalCommissionRate / 100);
  }
}
