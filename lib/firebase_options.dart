// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBe8AlovPXXjJpOonsLzkgwnTastjb5TwQ',
    appId: '1:746318252750:web:09ac6d4429f37366e51e9f',
    messagingSenderId: '746318252750',
    projectId: 'tijaraademo',
    authDomain: 'tijaraademo.firebaseapp.com',
    storageBucket: 'tijaraademo.firebasestorage.app',
    measurementId: 'G-5EH55LGC4Q',
  );

  /// 🔹 WEB configuration

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD9Y_YV2giFOLKdvigSodHqgpL4nNd_Zu0',
    appId: '1:746318252750:android:b0b5af531473e77ce51e9f',
    messagingSenderId: '746318252750',
    projectId: 'tijaraademo',
    storageBucket: 'tijaraademo.firebasestorage.app',
  );

  /// 🔹 ANDROID configuration

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAD8gD3TwGQXJnw45U_rermH8cuWQ25pmI',
    appId: '1:746318252750:ios:5a43da6278453952e51e9f',
    messagingSenderId: '746318252750',
    projectId: 'tijaraademo',
    storageBucket: 'tijaraademo.firebasestorage.app',
    iosClientId: '746318252750-f7sschoaqh3dt840rpb826d1t6obhbqd.apps.googleusercontent.com',
    iosBundleId: 'com.tijaraa.app',
  );

  /// 🔹 iOS configuration

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAD8gD3TwGQXJnw45U_rermH8cuWQ25pmI',
    appId: '1:746318252750:ios:61b1a076efefcb78e51e9f',
    messagingSenderId: '746318252750',
    projectId: 'tijaraademo',
    storageBucket: 'tijaraademo.firebasestorage.app',
    iosClientId: '746318252750-ici01sothopadgchjvfcinu86n2gcvat.apps.googleusercontent.com',
    iosBundleId: 'com.tijaraa.tijaraa',
  );

  /// 🔹 macOS configuration

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBe8AlovPXXjJpOonsLzkgwnTastjb5TwQ',
    appId: '1:746318252750:web:14c450b64b11aa38e51e9f',
    messagingSenderId: '746318252750',
    projectId: 'tijaraademo',
    authDomain: 'tijaraademo.firebaseapp.com',
    storageBucket: 'tijaraademo.firebasestorage.app',
    measurementId: 'G-L4M6LYX8P0',
  );

}