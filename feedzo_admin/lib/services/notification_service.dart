import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here
}

class NotificationService {
  final _fcm = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> init() async {
    // Request permission (iOS / web)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      // In a real app, show an in-app notification here
    });
  }

  /// Save FCM token to Firestore for a user
  Future<void> saveToken(String userId) async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _db.collection('users').doc(userId).update({'fcmToken': token});
    }
  }

  /// Send notification by writing to a Firestore trigger collection.
  /// A Cloud Function would pick this up and call FCM send API.
  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    await _db.collection('notifications').add({
      'targetUserId': targetUserId,
      'title': title,
      'body': body,
      'data': data ?? {},
      'sent': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Convenience triggers ──────────────────────────────────────────────────

  Future<void> notifyRestaurantNewOrder(String restaurantUserId, String orderId) =>
      sendNotification(
        targetUserId: restaurantUserId,
        title: 'New Order Received',
        body: 'Order #$orderId has been placed. Please confirm.',
        data: {'orderId': orderId, 'type': 'new_order'},
      );

  Future<void> notifyDriverAssigned(String driverUserId, String orderId) =>
      sendNotification(
        targetUserId: driverUserId,
        title: 'New Delivery Assigned',
        body: 'You have been assigned order #$orderId.',
        data: {'orderId': orderId, 'type': 'driver_assigned'},
      );

  Future<void> notifyCustomerOutForDelivery(String customerUserId, String orderId) =>
      sendNotification(
        targetUserId: customerUserId,
        title: 'Order On The Way',
        body: 'Your order #$orderId is out for delivery!',
        data: {'orderId': orderId, 'type': 'out_for_delivery'},
      );
}
