import 'package:cloud_firestore/cloud_firestore.dart';

/// Hike charges configuration for customer checkout
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
  final DateTime? peakHoursStart;
  final DateTime? peakHoursEnd;
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
    this.peakHoursStart,
    this.peakHoursEnd,
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
      peakHoursStart: (map['peakHoursStart'] as Timestamp?)?.toDate(),
      peakHoursEnd: (map['peakHoursEnd'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Calculate delivery fee based on distance
  double calculateDeliveryFee(double distanceKm) {
    return deliveryCharges + (deliveryChargePerKm * distanceKm);
  }

  /// Calculate packaging charge
  double getPackagingCharge() {
    return packagingCharges;
  }

  /// Calculate small order fee if applicable
  double calculateSmallOrderFee(double orderValue) {
    if (minimumOrderValue > 0 && orderValue < minimumOrderValue) {
      return smallOrderFee;
    }
    return 0;
  }

  /// Calculate if surge pricing applies
  bool isSurgeActive() {
    if (!surgeEnabled) return false;
    if (peakHoursStart == null || peakHoursEnd == null) return false;
    
    final now = DateTime.now();
    final currentTime = DateTime(2000, 1, 1, now.hour, now.minute);
    final start = DateTime(2000, 1, 1, peakHoursStart!.hour, peakHoursStart!.minute);
    final end = DateTime(2000, 1, 1, peakHoursEnd!.hour, peakHoursEnd!.minute);
    
    return currentTime.isAfter(start) && currentTime.isBefore(end);
  }

  /// Calculate surge multiplier amount
  double calculateSurgeAmount(double baseAmount) {
    if (!isSurgeActive() || hikeMultiplier <= 0) return 0;
    return baseAmount * (hikeMultiplier / 100);
  }

  /// Calculate total hike charges for an order
  Map<String, double> calculateCharges({
    required double orderValue,
    required double distanceKm,
  }) {
    final packaging = getPackagingCharge();
    final delivery = calculateDeliveryFee(distanceKm);
    final smallOrder = calculateSmallOrderFee(orderValue);
    final baseCharges = packaging + delivery + smallOrder;
    final surge = calculateSurgeAmount(baseCharges);
    
    return {
      'packaging': packaging,
      'delivery': delivery,
      'smallOrderFee': smallOrder,
      'surge': surge,
      'totalHike': baseCharges + surge,
    };
  }
}

/// Restaurant-specific hike override (for customer display)
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

/// Combined effective charges for display at checkout
class CheckoutCharges {
  final double itemTotal;
  final double packagingCharge;
  final double deliveryCharge;
  final double smallOrderFee;
  final double surgeCharge;
  final double taxAmount;
  final double tipAmount;
  final double discount;
  final double grandTotal;
  final bool surgeActive;
  final double hikeMultiplier;

  CheckoutCharges({
    required this.itemTotal,
    required this.packagingCharge,
    required this.deliveryCharge,
    required this.smallOrderFee,
    required this.surgeCharge,
    required this.taxAmount,
    this.tipAmount = 0,
    this.discount = 0,
    required this.grandTotal,
    this.surgeActive = false,
    this.hikeMultiplier = 0,
  });

  double get subtotal => itemTotal + packagingCharge + deliveryCharge + smallOrderFee;
  double get totalHike => packagingCharge + deliveryCharge + smallOrderFee + surgeCharge;
}
