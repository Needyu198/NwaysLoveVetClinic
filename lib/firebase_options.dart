import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase web options are not configured for this app.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return apple;
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCAokUamj6DVxc41JS1GoC6RphI5HBJ3eM',
    appId: '1:664771128258:android:3d219a049c5a7438b8445b',
    messagingSenderId: '664771128258',
    projectId: 'nwayslovevetclinic',
    storageBucket: 'nwayslovevetclinic.firebasestorage.app',
  );

  static const FirebaseOptions apple = FirebaseOptions(
    apiKey: 'AIzaSyBZ9abrO-hBBqTu6FjVsDI8p5IfWZiEBUY',
    appId: '1:664771128258:ios:2af0ef617d9c68efb8445b',
    messagingSenderId: '664771128258',
    projectId: 'nwayslovevetclinic',
    storageBucket: 'nwayslovevetclinic.firebasestorage.app',
    iosBundleId: 'com.example.seniorProject',
  );
}
