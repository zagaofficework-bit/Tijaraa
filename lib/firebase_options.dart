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
    apiKey: 'AIzaSyBzhzpDxcyoEpmIp_2OSr9ovZWeNfCcwsE',
    appId: '1:761011301966:web:811d7b5d318460f8735d1f',
    messagingSenderId: '761011301966',
    projectId: 'zagatijaraa',
    authDomain: 'zagatijaraa.firebaseapp.com',
    databaseURL: 'https://zagatijaraa-default-rtdb.firebaseio.com',
    storageBucket: 'zagatijaraa.firebasestorage.app',
    measurementId: 'G-350S1NW25G',
  );

  /// 🔹 WEB configuration

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDjYoRAxS5bn43xJ-ttcLLntvLVtqIKMhY',
    appId: '1:761011301966:android:8689398d31bfa044735d1f',
    messagingSenderId: '761011301966',
    projectId: 'zagatijaraa',
    databaseURL: 'https://zagatijaraa-default-rtdb.firebaseio.com',
    storageBucket: 'zagatijaraa.firebasestorage.app',
  );

  /// 🔹 ANDROID configuration

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBfqNXrTNiA4E1MkpTUr1063KZNJ-WS3-g',
    appId: '1:761011301966:ios:deb2acde02b371ab735d1f',
    messagingSenderId: '761011301966',
    projectId: 'zagatijaraa',
    databaseURL: 'https://zagatijaraa-default-rtdb.firebaseio.com',
    storageBucket: 'zagatijaraa.firebasestorage.app',
    iosClientId: '761011301966-t8886ujor9mmjvg08hjf96htari8293l.apps.googleusercontent.com',
    iosBundleId: 'com.tijaraa.app',
  );

  /// 🔹 iOS configuration

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBfqNXrTNiA4E1MkpTUr1063KZNJ-WS3-g',
    appId: '1:761011301966:ios:d0470fdf6e8d049c735d1f',
    messagingSenderId: '761011301966',
    projectId: 'zagatijaraa',
    databaseURL: 'https://zagatijaraa-default-rtdb.firebaseio.com',
    storageBucket: 'zagatijaraa.firebasestorage.app',
    iosClientId: '761011301966-r43vl7dmg9j7pon3u3mu9jocsfpiefc4.apps.googleusercontent.com',
    iosBundleId: 'com.tijaraa.tijaraa',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBzhzpDxcyoEpmIp_2OSr9ovZWeNfCcwsE',
    appId: '1:761011301966:web:4b98ec6180a61022735d1f',
    messagingSenderId: '761011301966',
    projectId: 'zagatijaraa',
    authDomain: 'zagatijaraa.firebaseapp.com',
    databaseURL: 'https://zagatijaraa-default-rtdb.firebaseio.com',
    storageBucket: 'zagatijaraa.firebasestorage.app',
    measurementId: 'G-J4ET5MSP7Y',
  );

}