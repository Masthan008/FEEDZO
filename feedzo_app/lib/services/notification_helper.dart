import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// In-app notification service for the customer app.
/// Reads from the `notifications` Firestore collection and provides
/// streams for real-time notification updates.
class NotificationHelper {
  static final _db = FirebaseFirestore.instance;

  /// Stream all notifications for a specific user, newest first.
  static Stream<List<AppNotification>> watchNotifications(String userId) =>
      _db
          .collection('notifications')
          .where('targetUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) =>
                  AppNotification.fromMap(doc.data(), doc.id))
              .toList());

  /// Mark a notification as read.
  static Future<void> markRead(String notificationId) =>
      _db.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });

  /// Mark all notifications for a user as read.
  static Future<void> markAllRead(String userId) async {
    final batch = _db.batch();
    final snap = await _db
        .collection('notifications')
        .where('targetUserId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Get unread count for badge display.
  static Stream<int> watchUnreadCount(String userId) => _db
      .collection('notifications')
      .where('targetUserId', isEqualTo: userId)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snap) => snap.size);
}

/// Notification model for the customer app.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      read: map['read'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  IconData get icon {
    final type = data['type'] as String?;
    switch (type) {
      case 'order_update':
      case 'new_order':
        return Icons.receipt_long_rounded;
      case 'out_for_delivery':
        return Icons.delivery_dining_rounded;
      case 'driver_assigned':
        return Icons.person_pin_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      case 'order_delivered':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get iconColor {
    final type = data['type'] as String?;
    switch (type) {
      case 'order_update':
        return const Color(0xFF2563EB);
      case 'out_for_delivery':
        return const Color(0xFFF59E0B);
      case 'order_delivered':
        return const Color(0xFF16A34A);
      case 'promotion':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
