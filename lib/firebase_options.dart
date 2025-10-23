import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Placeholder Firebase configuration.
///
/// Replace the values with those from your Firebase project before running the
/// app. The structure mirrors the one produced by `flutterfire configure` so
/// you can easily swap it out once you have real credentials.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'YOUR_WEB_API_KEY',
        appId: 'YOUR_WEB_APP_ID',
        messagingSenderId: 'YOUR_WEB_MESSAGING_SENDER_ID',
        projectId: 'YOUR_WEB_PROJECT_ID',
        authDomain: 'YOUR_WEB_AUTH_DOMAIN',
        storageBucket: 'YOUR_WEB_STORAGE_BUCKET',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'YOUR_ANDROID_API_KEY',
          appId: 'YOUR_ANDROID_APP_ID',
          messagingSenderId: 'YOUR_ANDROID_MESSAGING_SENDER_ID',
          projectId: 'YOUR_ANDROID_PROJECT_ID',
          storageBucket: 'YOUR_ANDROID_STORAGE_BUCKET',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'YOUR_IOS_API_KEY',
          appId: 'YOUR_IOS_APP_ID',
          messagingSenderId: 'YOUR_IOS_MESSAGING_SENDER_ID',
          projectId: 'YOUR_IOS_PROJECT_ID',
          storageBucket: 'YOUR_IOS_STORAGE_BUCKET',
          iosClientId: 'YOUR_IOS_CLIENT_ID',
          iosBundleId: 'YOUR_IOS_BUNDLE_ID',
        );
      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: 'YOUR_MACOS_API_KEY',
          appId: 'YOUR_MACOS_APP_ID',
          messagingSenderId: 'YOUR_MACOS_MESSAGING_SENDER_ID',
          projectId: 'YOUR_MACOS_PROJECT_ID',
          storageBucket: 'YOUR_MACOS_STORAGE_BUCKET',
          iosClientId: 'YOUR_MACOS_CLIENT_ID',
          iosBundleId: 'YOUR_MACOS_BUNDLE_ID',
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Please configure Firebase for the platform you are targeting.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }
}
