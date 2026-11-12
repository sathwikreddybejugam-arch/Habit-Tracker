# Habit Tracker

A simple Flutter habit tracker app. Add habits, mark them done each day,
track streaks, and view a 7-day mini calendar plus a stats screen. Firebase
Authentication protects access to the tracker using email and password.

## What's included

- Email/password sign up, sign in, password reset, and sign out
- An authentication gate that shows the tracker only for a signed-in user
- Habits remain in memory, as before; they are not synced or persisted

## Firebase setup

Firebase project credentials are not included in this repository. Each app
configuration is project-specific, so create or select your own Firebase
project before running the app.

1. Install the Firebase CLI and sign in:
   firebase login
2. Install FlutterFire CLI:
   dart pub global activate flutterfire_cli
3. From the project root, generate the Firebase app configuration:
   flutterfire configure
   Select your Firebase project and the platforms you intend to run (Android,
   iOS, Web, etc.). This replaces the safe placeholder at
   lib/firebase_options.dart with the generated DefaultFirebaseOptions.
   The generated file contains public app identifiers, not server credentials.
4. In the Firebase Console, open Authentication → Sign-in method and enable
   Email/Password.
5. Fetch packages and run the app:
   flutter pub get
   flutter run

The current repository has Dart source only, without generated android/,
ios/, or web/ platform folders. If needed, create them first with
flutter create ., then run flutterfire configure again.

Do not add service account keys, private keys, or other server credentials to
the Flutter client. Firebase client configuration is not a security boundary;
use Firebase Security Rules for any future user data stored in Firebase.

## Project structure

- lib/main.dart
- lib/firebase_options.dart
- lib/models/habit.dart
- lib/services/auth_service.dart
- lib/screens/auth_screen.dart
- lib/widgets/

## Run

    flutter pub get
    flutter run
