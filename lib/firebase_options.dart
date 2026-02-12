// This file is a manual stand-in for flutterfire configure.
// Replace the web values with your Firebase web app config.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDCOZ8m92UbOxYLWmmkbEwT1BgzJqayifw',
    appId: '1:559169832467:web:7c384b192ea4013825e1e6',
    messagingSenderId: '559169832467',
    projectId: 'present-sir-30e45',
    authDomain: 'present-sir-30e45.firebaseapp.com',
    storageBucket: 'present-sir-30e45.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDriboaCgurT6QmR_osWxaJZwGEj65LGcQ',
    appId: '1:559169832467:android:7141f1edb778534a25e1e6',
    messagingSenderId: '559169832467',
    projectId: 'present-sir-30e45',
    storageBucket: 'present-sir-30e45.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDiNWXJvDnVIN4GIpDFo8xEDU2zvioYXLQ',
    appId: '1:559169832467:ios:cbb987f800b310e025e1e6',
    messagingSenderId: '559169832467',
    projectId: 'present-sir-30e45',
    storageBucket: 'present-sir-30e45.firebasestorage.app',
    iosBundleId: 'com.galacticgeeks.presentsir',
  );
}
