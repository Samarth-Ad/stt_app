// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD33H5WSnOrMiXjU_q5bBqM6Z69CEuBy54',
    appId: '1:1082767745621:web:e8b8b9f6899da08639eadc',
    messagingSenderId: '1082767745621',
    projectId: 'sttapp-9e24e',
    authDomain: 'sttapp-9e24e.firebaseapp.com',
    storageBucket: 'sttapp-9e24e.firebasestorage.app',
    measurementId: 'G-W20P3SV0Z5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBZogQWPRM444y-BCdwBL69SCWGCV9xoWE',
    appId: '1:1082767745621:android:35ea493bfce8c79b39eadc',
    messagingSenderId: '1082767745621',
    projectId: 'sttapp-9e24e',
    storageBucket: 'sttapp-9e24e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC1xiNAY4HRVdlBjy25uAczH1NqlodxFU8',
    appId: '1:1082767745621:ios:6bfeafe17933d65e39eadc',
    messagingSenderId: '1082767745621',
    projectId: 'sttapp-9e24e',
    storageBucket: 'sttapp-9e24e.firebasestorage.app',
    iosBundleId: 'com.example.sttApp',
  );
}
