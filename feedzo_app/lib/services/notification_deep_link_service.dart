import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'deep_link_service.dart';

class NotificationDeepLinkService {
  static Future<void> handleNotificationTap(RemoteMessage message, BuildContext context) async {
    final data = message.data;

    if (data.containsKey('orderId')) {
      final orderId = data['orderId'];
      Navigator.pushNamed(context, '/order-tracking', arguments: orderId);
    } else if (data.containsKey('restaurantId')) {
      final restaurantId = data['restaurantId'];
      Navigator.pushNamed(context, '/restaurant', arguments: restaurantId);
    } else if (data.containsKey('screen')) {
      final screen = data['screen'];
      Navigator.pushNamed(context, screen);
    }
  }

  static Future<void> initialize(BuildContext context) async {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationTap(message, context);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      handleNotificationTap(initialMessage, context);
    }
  }
}
