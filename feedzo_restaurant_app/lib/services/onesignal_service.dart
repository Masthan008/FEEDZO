import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

/// Callback for notification navigation
typedef NotificationNavigationCallback = void Function(String type, Map<String, dynamic>? data);

class OneSignalService {
  static const _appId = '90f7c5c6-b51f-466a-acdb-a4829b419363';
  static NotificationNavigationCallback? _navigationCallback;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> init({NotificationNavigationCallback? onNavigate}) async {
    _navigationCallback = onNavigate;

    OneSignal.initialize(_appId);
    await OneSignal.Notifications.requestPermission(true);

    // Handle notification clicks (user taps notification)
    OneSignal.Notifications.addClickListener((event) {
      _handleNotificationClick(event);
    });

    // Handle foreground notifications (app is open)
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      _handleForegroundNotification(event);
    });

    // Enable in-app alerts for foreground
    OneSignal.InAppMessages.paused(false);

    debugPrint('[OneSignal] Initialized successfully');
  }

  /// Handle notification click - navigate to appropriate screen
  static void _handleNotificationClick(OSNotificationClickEvent event) {
    final data = event.notification.additionalData;
    final type = data?['type'] as String? ?? 'general';

    debugPrint('[OneSignal] Notification clicked: $type');

    if (_navigationCallback != null) {
      _navigationCallback!(type, data);
    }
  }

  /// Handle foreground notification - play sound and show in-app alert
  static void _handleForegroundNotification(OSNotificationWillDisplayEvent event) {
    final notification = event.notification;
    final data = notification.additionalData;
    final type = data?['type'] as String? ?? 'general';

    debugPrint('[OneSignal] Foreground notification received: $type');

    // Play appropriate sound based on notification type
    _playNotificationSound(type);

    // Show the notification
    event.preventDefault();
    notification.display();
  }

  /// Play notification sound based on type
  static Future<void> _playNotificationSound(String type) async {
    try {
      String soundFile;
      switch (type) {
        case 'new_order':
          soundFile = 'sounds/new_order.mp3';
          break;
        case 'order_cancelled':
          soundFile = 'sounds/cancel.mp3';
          break;
        case 'order_status':
          soundFile = 'sounds/status_update.mp3';
          break;
        case 'payment':
          soundFile = 'sounds/payment.mp3';
          break;
        default:
          soundFile = 'sounds/notification.mp3';
      }

      await _audioPlayer.stop();
      await _audioPlayer.setSource(AssetSource(soundFile));
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('[OneSignal] Error playing sound: $e');
    }
  }

  /// Send a test notification (for debugging)
  static Future<void> sendTestNotification() async {
    // This would require server-side API call
    debugPrint('[OneSignal] Test notification request sent');
  }

  /// Set external user ID for targeted notifications
  static void loginUser(String firebaseUid) {
    OneSignal.login(firebaseUid);
    debugPrint('[OneSignal] User logged in: $firebaseUid');
  }

  static void logoutUser() {
    OneSignal.logout();
    debugPrint('[OneSignal] User logged out');
  }

  /// Set user role for segmented notifications
  static void setRole(String role) {
    OneSignal.User.addTagWithKey('role', role);
  }

  /// Set restaurant ID for targeted notifications
  static void setRestaurantId(String restaurantId) {
    OneSignal.User.addTagWithKey('restaurant_id', restaurantId);
  }

  /// Get OneSignal player ID for debugging
  static Future<String?> getPlayerId() async {
    return await OneSignal.User.getOnesignalId();
  }

  /// Check notification permission status
  static Future<bool> hasPermission() async {
    return await OneSignal.Notifications.permission;
  }
}
