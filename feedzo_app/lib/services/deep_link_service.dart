import 'package:flutter/material.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class DeepLinkService {
  static Future<String> createOrderDeepLink(String orderId) async {
    final dynamicLinkParams = DynamicLinkParameters(
      link: Uri.parse('https://feedzo.app/order/$orderId'),
      uriPrefix: 'https://feedzo.page.link',
      androidParameters: const AndroidParameters(
        packageName: 'com.example.feedzo_app',
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.example.feedzo_app',
        minimumVersion: '1',
      ),
    );

    final dynamicLink = await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
    return dynamicLink.shortUrl.toString();
  }

  static Future<String> createRestaurantDeepLink(String restaurantId) async {
    final dynamicLinkParams = DynamicLinkParameters(
      link: Uri.parse('https://feedzo.app/restaurant/$restaurantId'),
      uriPrefix: 'https://feedzo.page.link',
      androidParameters: const AndroidParameters(
        packageName: 'com.example.feedzo_app',
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.example.feedzo_app',
        minimumVersion: '1',
      ),
    );

    final dynamicLink = await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
    return dynamicLink.shortUrl.toString();
  }

  static Future<String> createReferralDeepLink(String referralCode) async {
    final dynamicLinkParams = DynamicLinkParameters(
      link: Uri.parse('https://feedzo.app/referral/$referralCode'),
      uriPrefix: 'https://feedzo.page.link',
      androidParameters: const AndroidParameters(
        packageName: 'com.example.feedzo_app',
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.example.feedzo_app',
        minimumVersion: '1',
      ),
    );

    final dynamicLink = await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
    return dynamicLink.shortUrl.toString();
  }

  static Future<void> handleDynamicLinks(BuildContext context) async {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      final Uri deepLink = dynamicLinkData.link;
      _navigateToScreen(context, deepLink);
    });
  }

  static Future<void> handleInitialLink(BuildContext context) async {
    final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
    if (data != null) {
      final Uri deepLink = data.link;
      _navigateToScreen(context, deepLink);
    }
  }

  static void _navigateToScreen(BuildContext context, Uri deepLink) {
    final path = deepLink.path;

    if (path.startsWith('/order/')) {
      final orderId = path.split('/').last;
      Navigator.pushNamed(context, '/order-tracking', arguments: orderId);
    } else if (path.startsWith('/restaurant/')) {
      final restaurantId = path.split('/').last;
      Navigator.pushNamed(context, '/restaurant', arguments: restaurantId);
    } else if (path.startsWith('/referral/')) {
      final referralCode = path.split('/').last;
      Navigator.pushNamed(context, '/referral', arguments: referralCode);
    }
  }
}
