import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingModel {
  final String orderId;
  final String driverId;
  final GeoPoint driverLocation;
  final GeoPoint? restaurantLocation;
  final GeoPoint? customerLocation;
  final String status; // 'assigned', 'at_restaurant', 'picked_up', 'on_delivery', 'delivered'
  final double? distanceToRestaurant;
  final double? distanceToCustomer;
  final int? estimatedTimeMinutes;
  final DateTime updatedAt;

  TrackingModel({
    required this.orderId,
    required this.driverId,
    required this.driverLocation,
    this.restaurantLocation,
    this.customerLocation,
    required this.status,
    this.distanceToRestaurant,
    this.distanceToCustomer,
    this.estimatedTimeMinutes,
    required this.updatedAt,
  });

  factory TrackingModel.fromMap(Map<String, dynamic> data) {
    return TrackingModel(
      orderId: data['orderId'] ?? '',
      driverId: data['driverId'] ?? '',
      driverLocation: data['driverLocation'] ?? GeoPoint(0, 0),
      restaurantLocation: data['restaurantLocation'],
      customerLocation: data['customerLocation'],
      status: data['status'] ?? 'assigned',
      distanceToRestaurant: data['distanceToRestaurant']?.toDouble(),
      distanceToCustomer: data['distanceToCustomer']?.toDouble(),
      estimatedTimeMinutes: data['estimatedTimeMinutes']?.toInt(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'driverId': driverId,
      'driverLocation': driverLocation,
      'restaurantLocation': restaurantLocation,
      'customerLocation': customerLocation,
      'status': status,
      'distanceToRestaurant': distanceToRestaurant,
      'distanceToCustomer': distanceToCustomer,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
