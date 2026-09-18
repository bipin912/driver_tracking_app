// 🔑 MANUAL FIREBASE OPTIONS
// Find your values in Firebase Console → Project Settings → Your apps → SDK setup

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      default:
        throw UnsupportedError('Platform not supported.');
    }
  }

  // 🔑 ANDROID: Copy values from android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbOENlL1POknVI_h_6QRTmhk06sJuQxwU', // ← Replace with YOUR key
    appId: '1:27497017193:android:b629682e88d5f3ad72d7f8',  // ← Replace with YOUR appId
    messagingSenderId: '27497017193',              // ← Replace with YOUR sender ID
    projectId: 'driver-tracking-app-32e76',       // ← Your Firebase Project ID
    // Optional: storageBucket: 'driver-tracking-app-32e76.appspot.com',
  );


}