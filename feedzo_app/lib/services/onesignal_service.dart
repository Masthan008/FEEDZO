import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../main.dart';
import '../screens/orders/order_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// OneSignal push notification service with deep linking.
class OneSignalService {
  static const _appId = '90f7c5c6-b51f-466a-acdb-a4829b419363';

  /// Call once in main() after Firebase.initializeApp()
  static Future<void> init() async {
    OneSignal.initialize(_appId);
    await OneSignal.Notifications.requestPermission(true);

    // ── Notification click handler with deep linking ──
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data == null) return;

      final type = data['type'] as String?;
      final orderId = data['orderId'] as String?;
      final navigator = navigatorKey.currentState;

      if (navigator == null) return;

      switch (type) {
        case 'order_update':
          if (orderId != null) {
            navigator.push(
              MaterialPageRoute(
                builder: (_) => OrderTrackingScreen(orderId: orderId),
              ),
            );
          }
          break;
        case 'promotion':
          // Navigate to home or promo screen
          navigator.popUntil((route) => route.isFirst);
          break;
        default:
          break;
      }
    });

    // ── Foreground notification handler ──
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // Show the notification in the notification center
      event.preventDefault();
      event.notification.display();
    });
  }

  static void loginUser(String firebaseUid) {
    if (!kIsWeb) OneSignal.login(firebaseUid);
  }

  /// Call on logout
  static void logoutUser() {
    if (!kIsWeb) OneSignal.logout();
  }

  /// Add a tag for role-based targeting (e.g. role=customer)
  static void setRole(String role) {
    if (!kIsWeb) OneSignal.User.addTagWithKey('role', role);
  }

  /// Set external user ID for targeted push
  static void setExternalUserId(String userId) {
    if (!kIsWeb) OneSignal.login(userId);
  }
}
