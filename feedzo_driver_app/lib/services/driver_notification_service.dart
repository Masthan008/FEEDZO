import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/driver_notification_model.dart';

/// Service for managing driver notifications and multi-order assignments
class DriverNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Collection references
  CollectionReference get _notificationsCollection => 
      _firestore.collection('driverNotifications');
  CollectionReference get _driversCollection => 
      _firestore.collection('drivers');
  CollectionReference get _ordersCollection => 
      _firestore.collection('orders');

  /// Stream of unread notifications for a driver
  Stream<List<DriverNotification>> getUnreadNotifications(String driverId) {
    return _notificationsCollection
        .where('driverId', isEqualTo: driverId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverNotification.fromJson(
                doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream of all notifications for a driver
  Stream<List<DriverNotification>> getAllNotifications(String driverId) {
    return _notificationsCollection
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverNotification.fromJson(
                doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).update({
      'isRead': true,
      'readAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String driverId) async {
    final batch = _firestore.batch();
    final now = Timestamp.fromDate(DateTime.now());

    final unreadDocs = await _notificationsCollection
        .where('driverId', isEqualTo: driverId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadDocs.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': now,
      });
    }

    await batch.commit();
  }

  /// Record action taken on notification
  Future<void> recordAction({
    required String notificationId,
    required String action,
  }) async {
    await _notificationsCollection.doc(notificationId).update({
      'actionTaken': action,
      'actionTakenAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get count of unread notifications
  Stream<int> getUnreadCount(String driverId) {
    return _notificationsCollection
        .where('driverId', isEqualTo: driverId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Initialize FCM for driver
  Future<void> initializeFCM(String driverId) async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Subscribe to driver-specific topic
    await _messaging.subscribeToTopic('driver_$driverId');
    await _messaging.subscribeToTopic('all_drivers');

    // Get and store FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _driversCollection.doc(driverId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  /// Get driver's active orders with details
  Stream<List<Map<String, dynamic>>> getActiveOrdersWithDetails(String driverId) {
    return _driversCollection.doc(driverId).snapshots().asyncMap((driverDoc) async {
      if (!driverDoc.exists) return [];

      final driverData = driverDoc.data() as Map<String, dynamic>;
      final activeOrderIds = List<String>.from(driverData['activeOrderIds'] ?? []);

      if (activeOrderIds.isEmpty) return [];

      // Fetch order details
      final orders = await Future.wait(
        activeOrderIds.map((orderId) async {
          final orderDoc = await _ordersCollection.doc(orderId).get();
          if (orderDoc.exists) {
            return {
              'id': orderId,
              ...orderDoc.data() as Map<String, dynamic>,
            };
          }
          return null;
        }),
      );

      return orders.where((o) => o != null).cast<Map<String, dynamic>>().toList();
    });
  }

  /// Accept new order assignment
  Future<void> acceptOrderAssignment({
    required String driverId,
    required String orderId,
    required String notificationId,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    // Update notification
    batch.update(_notificationsCollection.doc(notificationId), {
      'isRead': true,
      'readAt': Timestamp.fromDate(now),
      'actionTaken': 'accept',
      'actionTakenAt': Timestamp.fromDate(now),
    });

    // Update driver status to confirm acceptance
    batch.update(_driversCollection.doc(driverId), {
      'lastOrderAcceptedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  /// Dismiss notification without action
  Future<void> dismissNotification(String notificationId) async {
    await _notificationsCollection.doc(notificationId).update({
      'isRead': true,
      'readAt': Timestamp.fromDate(DateTime.now()),
      'actionTaken': 'dismiss',
      'actionTakenAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
