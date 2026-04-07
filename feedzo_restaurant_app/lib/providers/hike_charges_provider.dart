import 'dart:async';
import 'package:flutter/material.dart';
import '../models/hike_charges_model.dart';
import '../services/hike_charges_service.dart';

class HikeChargesProvider extends ChangeNotifier {
  HikeChargesConfig? _globalConfig;
  RestaurantHikeOverride? _override;
  EffectiveHikeCharges? _effectiveCharges;
  StreamSubscription? _globalSubscription;
  StreamSubscription? _effectiveSubscription;
  bool _isLoading = true;
  String? _error;

  HikeChargesConfig? get globalConfig => _globalConfig;
  RestaurantHikeOverride? get override => _override;
  EffectiveHikeCharges? get effectiveCharges => _effectiveCharges;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  String? get error => _error;

  /// Initialize and watch hike charges for a restaurant
  void init(String restaurantId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Cancel existing subscriptions
    _globalSubscription?.cancel();
    _effectiveSubscription?.cancel();

    // Watch effective charges (combines global + override)
    _effectiveSubscription = HikeChargesService.watchEffectiveCharges(restaurantId).listen(
      (effective) {
        _effectiveCharges = effective;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load hike charges: $e';
        _isLoading = false;
        notifyListeners();
      },
    );

    // Also watch global config separately for display
    _globalSubscription = HikeChargesService.watchGlobalConfig().listen(
      (config) {
        _globalConfig = config;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error loading global config: $e');
      },
    );
  }

  /// Calculate delivery charge for a distance
  double calculateDeliveryCharge(double distanceKm) {
    return _effectiveCharges?.calculateDeliveryCharge(distanceKm) ?? 
           (_globalConfig?.calculateDeliveryCharge(distanceKm) ?? 20 + (5 * distanceKm));
  }

  /// Calculate total charges for an order
  double calculateTotalCharges({
    required double orderValue,
    required double distanceKm,
    bool isPeakHours = false,
  }) {
    return _effectiveCharges?.calculateTotalCharges(
          orderValue: orderValue,
          distanceKm: distanceKm,
          isPeakHours: isPeakHours,
        ) ??
        _globalConfig?.calculateTotalCharges(
          orderValue: orderValue,
          distanceKm: distanceKm,
          isPeakHours: isPeakHours,
        ) ??
        30; // Default fallback
  }

  /// Calculate commission on order value
  double calculateCommission(double orderValue) {
    return _effectiveCharges?.calculateCommission(orderValue) ??
           (_globalConfig?.calculateCommission(orderValue) ?? orderValue * 0.12);
  }

  /// Get display values for UI
  Map<String, dynamic> getDisplayValues() {
    if (_effectiveCharges != null) {
      return {
        'packagingCharges': _effectiveCharges!.packagingCharges,
        'deliveryCharges': _effectiveCharges!.deliveryCharges,
        'deliveryChargePerKm': _effectiveCharges!.deliveryChargePerKm,
        'hikeMultiplier': _effectiveCharges!.hikeMultiplier,
        'commissionPlus': _effectiveCharges!.commissionPlus,
        'totalCommissionRate': _effectiveCharges!.totalCommissionRate,
        'minimumOrderValue': _effectiveCharges!.minimumOrderValue,
        'smallOrderFee': _effectiveCharges!.smallOrderFee,
        'surgeEnabled': _effectiveCharges!.surgeEnabled,
        'hasCustomSettings': _effectiveCharges!.hasCustomSettings,
      };
    } else if (_globalConfig != null) {
      return {
        'packagingCharges': _globalConfig!.packagingCharges,
        'deliveryCharges': _globalConfig!.deliveryCharges,
        'deliveryChargePerKm': _globalConfig!.deliveryChargePerKm,
        'hikeMultiplier': _globalConfig!.hikeMultiplier,
        'commissionPlus': _globalConfig!.commissionPlus,
        'totalCommissionRate': _globalConfig!.totalCommissionRate,
        'minimumOrderValue': _globalConfig!.minimumOrderValue,
        'smallOrderFee': _globalConfig!.smallOrderFee,
        'surgeEnabled': _globalConfig!.surgeEnabled,
        'hasCustomSettings': false,
      };
    }
    // Default values
    return {
      'packagingCharges': 10.0,
      'deliveryCharges': 20.0,
      'deliveryChargePerKm': 5.0,
      'hikeMultiplier': 10.0,
      'commissionPlus': 2.0,
      'totalCommissionRate': 12.0,
      'minimumOrderValue': 100.0,
      'smallOrderFee': 15.0,
      'surgeEnabled': false,
      'hasCustomSettings': false,
    };
  }

  void dispose() {
    _globalSubscription?.cancel();
    _effectiveSubscription?.cancel();
    super.dispose();
  }
}
