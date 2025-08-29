
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.

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
    apiKey: 'AIzaSyCRvkXvtRhVw7Dce--eW2DezDXBL0AMv90',
    appId: '1:208428042594:web:37fbf9e478f7621c05c43b',
    messagingSenderId: '208428042594',
    projectId: 'stayeasy-pg',
    authDomain: 'stayeasy-pg.firebaseapp.com',
    storageBucket: 'stayeasy-pg.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBBqXUQcLkY4lcusLs47tN0qCn2hEprEuU',
    appId: '1:208428042594:android:da6fd32584be66f505c43b',
    messagingSenderId: '208428042594',
    projectId: 'stayeasy-pg',
    storageBucket: 'stayeasy-pg.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDy08zmsQskwzqIZWep8lOnbQPW1oZwrqU',
    appId: '1:208428042594:ios:02140f4dabc43d4505c43b',
    messagingSenderId: '208428042594',
    projectId: 'stayeasy-pg',
    storageBucket: 'stayeasy-pg.firebasestorage.app',
    iosBundleId: 'com.stayeasy.internshipPgMsProject',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDy08zmsQskwzqIZWep8lOnbQPW1oZwrqU',
    appId: '1:208428042594:ios:02140f4dabc43d4505c43b',
    messagingSenderId: '208428042594',
    projectId: 'stayeasy-pg',
    storageBucket: 'stayeasy-pg.firebasestorage.app',
    iosBundleId: 'com.stayeasy.internshipPgMsProject',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCRvkXvtRhVw7Dce--eW2DezDXBL0AMv90',
    appId: '1:208428042594:web:b1d326b1be97949d05c43b',
    messagingSenderId: '208428042594',
    projectId: 'stayeasy-pg',
    authDomain: 'stayeasy-pg.firebaseapp.com',
    storageBucket: 'stayeasy-pg.firebasestorage.app',
  );
}
