// Generated from google-services.json for project: feedzo-4840a
// App: com.feedzo.customer

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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuuzFxTXP_vYFAdgMPM-_GU8IAQrcXxqI',
    appId: '1:138473944117:android:8cd9f53b34d756c660ed7c',
    messagingSenderId: '138473944117',
    projectId: 'feedzo-4840a',
    storageBucket: 'feedzo-4840a.firebasestorage.app',
  );

  // ── Android (from google-services.json) ──────────────────────────────────

  // ── iOS — fill in after adding iOS app in Firebase Console ───────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '138473944117',
    projectId: 'feedzo-4840a',
    storageBucket: 'feedzo-4840a.firebasestorage.app',
    iosBundleId: 'com.feedzo.customer',
  );

  // ── Web — fill in after adding Web app in Firebase Console ───────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: 'REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: '138473944117',
    projectId: 'feedzo-4840a',
    storageBucket: 'feedzo-4840a.firebasestorage.app',
    authDomain: 'feedzo-4840a.firebaseapp.com',
  );
}