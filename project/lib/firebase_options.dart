// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// opsi firebase buat masing masing platform, dipakai pas Firebase.initializeApp()
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
    apiKey: 'AIzaSyCDp0EO2qpyaWmE-mWk5d7gqlrUP-uFMls',
    appId: '1:179578543175:web:5b0327922d62c4c469a562',
    messagingSenderId: '179578543175',
    projectId: 'sensor-suhu-sht20',
    authDomain: 'sensor-suhu-sht20.firebaseapp.com',
    databaseURL: 'https://sensor-suhu-sht20-default-rtdb.firebaseio.com',
    storageBucket: 'sensor-suhu-sht20.firebasestorage.app',
    measurementId: 'G-KK03BFXP01',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCm0aquQzkKDW5XFuOdatxYrkeHGrGKymY',
    appId: '1:179578543175:android:87e2285c12928f0669a562',
    messagingSenderId: '179578543175',
    projectId: 'sensor-suhu-sht20',
    databaseURL: 'https://sensor-suhu-sht20-default-rtdb.firebaseio.com',
    storageBucket: 'sensor-suhu-sht20.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCGPg-jEHxAdAHyOnRVRVGeWkK1-bkJoXo',
    appId: '1:483974364391:ios:1f8eb0a5903e284f1ff642',
    messagingSenderId: '483974364391',
    projectId: 'humtemp-monito',
    storageBucket: 'humtemp-monito.firebasestorage.app',
    iosBundleId: 'com.example.myapp',
  );
}
