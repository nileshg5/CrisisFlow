// File generated manually — FlutterFire CLI was not available.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCXRHNWGj0a8WNPy5fMeWz6PjZr9uUpj_U',
    appId: '1:298751238576:web:13cd36fbe3363a9d52b675',
    messagingSenderId: '298751238576',
    projectId: 'crisisflow-6a6aa',
    authDomain: 'crisisflow-6a6aa.firebaseapp.com',
    storageBucket: 'crisisflow-6a6aa.firebasestorage.app',
    measurementId: 'G-3HZWF61JJB',
  );
}
