import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static const _appId = '90f7c5c6-b51f-466a-acdb-a4829b419363';

  static Future<void> init() async {
    OneSignal.initialize(_appId);
    await OneSignal.Notifications.requestPermission(true);
    OneSignal.Notifications.addClickListener((event) {});
  }

  static void loginUser(String firebaseUid) => OneSignal.login(firebaseUid);
  static void logoutUser() => OneSignal.logout();
  static void setRole(String role) => OneSignal.User.addTagWithKey('role', role);
}
