// Firebase project: feedzo-4840a
// Register this app: Firebase Console → Add app → Android → com.feedzo.driver
// Then download google-services.json → place in feedzo_driver_app/android/app/
// Or run: flutterfire configure --project=feedzo-4840a

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: 'REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: '138473944117',
    projectId: 'feedzo-4840a',
    storageBucket: 'feedzo-4840a.firebasestorage.app',
    authDomain: 'feedzo-4840a.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuuzFxTXP_vYFAdgMPM-_GU8IAQrcXxqI',
    appId: '1:138473944117:android:4a3722659d97e43260ed7c',
    messagingSenderId: '138473944117',
    projectId: 'feedzo-4840a',
    storageBucket: 'feedzo-4840a.firebasestorage.app',
  );

  // Replace after registering com.feedzo.driver in Firebase Console

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '138473944117',
    projectId: 'feedzo-4840a',
    storageBucket: 'feedzo-4840a.firebasestorage.app',
    iosBundleId: 'com.feedzo.driver',
  );
}