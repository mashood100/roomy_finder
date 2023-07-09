// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgwyPg0suv0b55nk41MY_9cl_EKh7z7Nk',
    appId: '1:274087124726:android:dffb4ddfcf53202b9d96d7',
    messagingSenderId: '274087124726',
    projectId: 'roomy-finder',
    storageBucket: 'roomy-finder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAkuPvfEYneAgd0JUJUYCvznQTO7bexyEo',
    appId: '1:274087124726:ios:832269b067e7d6ab9d96d7',
    messagingSenderId: '274087124726',
    projectId: 'roomy-finder',
    storageBucket: 'roomy-finder.appspot.com',
    androidClientId: '274087124726-aj9nq0de07rvf0a6egmt499opk7m84gl.apps.googleusercontent.com',
    iosClientId: '274087124726-ik0g181v0na0b1j7190bp1bocv1309fg.apps.googleusercontent.com',
    iosBundleId: 'com.gsccapitalgroup.roomyFinder',
  );
}
