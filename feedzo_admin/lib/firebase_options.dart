// Firebase project: feedzo-4840a
// Register this app in Firebase Console → Add app → Web
// Then replace the placeholder values below, or run:
//   flutterfire configure --project=feedzo-4840a

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
        return web;
    }
  }

  // ── Web (Admin Panel) ─────────────────────────────────────────────────────

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCNga7fQZOi2-znXxVAZk7_27HPPMUrJcg',
    appId: '1:138473944117:web:60dc96f8825311a560ed7c',
    messagingSenderId: '138473944117',
    projectId: 'feedzo-4840a',
    authDomain: 'feedzo-4840a.firebaseapp.com',
    storageBucket: 'feedzo-4840a.firebasestorage.app',
    measurementId: 'G-JL21W6MXS8',
  );

  // Get these from: Firebase Console → Project Settings → Your apps → Web app

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuuzFxTXP_vYFAdgMPM-_GU8IAQrcXxqI',
    appId: '1:138473944117:android:9a7064f07b798eca60ed7c',
    messagingSenderId: '138473944117',
    projectId: 'feedzo-4840a',
    storageBucket: 'feedzo-4840a.firebasestorage.app',
  );

  // ── Android ───────────────────────────────────────────────────────────────

  // ── iOS ───────────────────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '138473944117',
    projectId: 'feedzo-4840a',
    storageBucket: 'feedzo-4840a.firebasestorage.app',
    iosBundleId: 'com.feedzo.admin',
  );
}