// Safe placeholder. Run flutterfire configure to replace this file with
// project-specific (non-secret) Firebase app identifiers.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows) {
      throw UnsupportedError(
        'Firebase is not configured. Follow the Firebase setup steps in README.md and run flutterfire configure.',
      );
    }

    throw UnsupportedError(
      'Firebase is not configured for this platform. Follow README.md.',
    );
  }
}
