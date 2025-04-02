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
        return windows;
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
    apiKey: 'AIzaSyBsqeV9qM6ehLA-RdTZHQCarynd9L153Ig',
    appId: '1:715388557527:web:427db1b82fc6efa9173892',
    messagingSenderId: '715388557527',
    projectId: 'sistemaescolar-d50ef',
    authDomain: 'sistemaescolar-d50ef.firebaseapp.com',
    storageBucket: 'sistemaescolar-d50ef.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBStrm_ruX7-yyln6Fhe-dEWfPy10eNA2I',
    appId: '1:715388557527:android:9c29cf748742eaa2173892',
    messagingSenderId: '715388557527',
    projectId: 'sistemaescolar-d50ef',
    storageBucket: 'sistemaescolar-d50ef.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCIEbneqGyAeS2xVGZ7UrQS-dUp9e4LjwI',
    appId: '1:715388557527:ios:0d8145b9ff297cad173892',
    messagingSenderId: '715388557527',
    projectId: 'sistemaescolar-d50ef',
    storageBucket: 'sistemaescolar-d50ef.firebasestorage.app',
    iosBundleId: 'com.example.sistemaEscolar',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBsqeV9qM6ehLA-RdTZHQCarynd9L153Ig',
    appId: '1:715388557527:web:6f837febeb48c55b173892',
    messagingSenderId: '715388557527',
    projectId: 'sistemaescolar-d50ef',
    authDomain: 'sistemaescolar-d50ef.firebaseapp.com',
    storageBucket: 'sistemaescolar-d50ef.firebasestorage.app',
  );
}
