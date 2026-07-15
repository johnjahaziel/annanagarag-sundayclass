import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with this app's Firebase project
/// (`annanagarag-church`).
///
/// This file was hand-written from the values already checked into
/// `android/app/src/debug/google-services.json`, because the FlutterFire CLI
/// (`flutterfire configure`) is not available in this environment. Only
/// Android is configured. To add iOS/macOS/web/Windows support, install the
/// FlutterFire CLI and run `flutterfire configure` from the project root —
/// it will regenerate this file with every platform filled in.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'run `flutterfire configure` to add web support.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'run `flutterfire configure` to add iOS support.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
          'run `flutterfire configure` to add macOS support.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows - '
          'run `flutterfire configure` to add Windows support.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'run `flutterfire configure` to add Linux support.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCeSqV1RV8XzBmnul3QH9zKd45wfYppA6k',
    appId: '1:939423099620:android:10a220aa57ed4827c4daf1',
    messagingSenderId: '939423099620',
    projectId: 'annanagarag-church',
    storageBucket: 'annanagarag-church.firebasestorage.app',
  );
}
