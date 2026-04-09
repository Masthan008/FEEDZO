import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tracking_model.dart';

class TrackingService {
  static final _db = FirebaseFirestore.instance;

  static Stream<TrackingModel?> watchOrderTracking(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .collection('tracking')
        .doc('current')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return TrackingModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  static Future<TrackingModel?> getOrderTracking(String orderId) async {
    final doc = await _db
        .collection('orders')
        .doc(orderId)
        .collection('tracking')
        .doc('current')
        .get();
    if (!doc.exists) return null;
    return TrackingModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  static Future<void> updateDriverLocation({
    required String orderId,
    required String driverId,
    required GeoPoint location,
    double? distanceToRestaurant,
    double? distanceToCustomer,
    int? estimatedTimeMinutes,
    String? status,
  }) async {
    await _db
        .collection('orders')
        .doc(orderId)
        .collection('tracking')
        .doc('current')
        .set({
      'orderId': orderId,
      'driverId': driverId,
      'driverLocation': location,
      'distanceToRestaurant': distanceToRestaurant,
      'distanceToCustomer': distanceToCustomer,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'status': status ?? 'assigned',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    GeoPoint? restaurantLocation,
    GeoPoint? customerLocation,
  }) async {
    await _db
        .collection('orders')
        .doc(orderId)
        .collection('tracking')
        .doc('current')
        .update({
      'status': status,
      if (restaurantLocation != null) 'restaurantLocation': restaurantLocation,
      if (customerLocation != null) 'customerLocation': customerLocation,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
