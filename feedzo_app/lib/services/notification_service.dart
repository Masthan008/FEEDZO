import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../core/theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  final _fcm = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> init() async {
    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // ── Foreground message handler — show in-app banner ──
      FirebaseMessaging.onMessage.listen((message) {
        _showInAppNotification(message);
      });

      // ── Message opened handler — deep link ──
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleMessageTap(message);
      });

      await _saveToken();
      _fcm.onTokenRefresh.listen((_) => _saveToken());
    } catch (_) {
      /* FCM not available on this device */
    }
  }

  /// Show a Material banner for foreground notifications
  void _showInAppNotification(RemoteMessage message) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final context = navigator.overlay?.context;
    if (context == null) return;

    final title = message.notification?.title ?? 'Feedzo';
    final body = message.notification?.body ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (body.isNotEmpty)
              Text(
                body,
                style: const TextStyle(fontSize: 13),
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppShape.medium),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _handleMessageTap(message),
        ),
      ),
    );
  }

  /// Handle message tap — navigate based on data payload
  void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final type = data['type'];
    final orderId = data['orderId'];

    if (type == 'order_update' && orderId != null) {
      navigator.pushNamed('/order/$orderId');
    }
  }

  Future<void> _saveToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final token = await _fcm.getToken();
    if (token != null) {
      await _db.collection('users').doc(uid).update({'fcmToken': token});
    }
  }
}
