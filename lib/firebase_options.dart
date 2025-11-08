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

  /// 🔹 WEB configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "YOUR_WEB_API_KEY",
    authDomain: "tijaraa-a350b.firebaseapp.com",
    projectId: "tijaraa-a350b",
    storageBucket: "tijaraa-a350b.appspot.com",
    messagingSenderId: "283187015377",
    appId: "1:283187015377:web:cb00012428cd8ae298dff0",
  );

  /// 🔹 ANDROID configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBfyx2tCFmmgIEJvEV6cEaLAwIuvtMuaco',
    appId: '1:283187015377:android:cb00012428cd8ae298dff0',
    messagingSenderId: '283187015377',
    projectId: 'tijaraa-a350b',
    storageBucket: 'tijaraa-a350b.firebasestorage.app',
  );

  /// 🔹 iOS configuration
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:283187015377:ios:4996f3694dd7652498dff0',
    messagingSenderId: '283187015377',
    projectId: 'tijaraa-a350b',
    storageBucket: 'tijaraa-a350b.firebasestorage.app',
    iosBundleId: 'com.tijaraa.app',
  );

  /// 🔹 macOS configuration
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: '283187015377',
    projectId: 'tijaraa-a350b',
    storageBucket: 'tijaraa-a350b.firebasestorage.app',
    iosBundleId: 'com.tijaraa.app',
  );

  /// 🔹 Windows configuration
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: '283187015377',
    projectId: 'tijaraa-a350b',
    storageBucket: 'tijaraa-a350b.firebasestorage.app',
  );
}
