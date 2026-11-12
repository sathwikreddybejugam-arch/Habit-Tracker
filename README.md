# Habit Tracker

A Flutter app for creating habits, tracking daily progress, and keeping a streak.

## Features

- Create and edit daily or weekly habits.
- Organize habits into Health, Fitness, Study, Productivity, Personal Growth, and Other.
- Mark a habit done today and view its recent seven-day history.
- View current and longest streaks and a summary statistics screen.
- Delete habits with an undo action.
- Save habits and completion history locally between app launches.

Habits are stored on the current device with `shared_preferences`. They are not
cloud-synced or separated by user account.

## Run locally

This repository contains Dart source and tests, but no generated Android, iOS,
or web platform folders. From the project root:

```bash
flutter create .
flutter pub get
flutter run
```

Run the available tests with:

```bash
flutter test
```

## Firebase status

Firebase dependencies, a small authentication service, and a safe placeholder
configuration are present as groundwork. The app does not yet initialize
Firebase or show a sign-in flow. No Firebase project configuration is needed
to use the current habit tracker features. Do not commit service-account keys
or other private credentials.

## Project structure

```text
lib/
├── main.dart
├── firebase_options.dart       # Safe placeholder; not used by the app yet
├── models/habit.dart
├── services/
│   ├── auth_service.dart       # Firebase authentication wrapper
│   └── habit_storage.dart      # Local habit persistence
└── widgets/
    ├── add_habit_dialog.dart
    ├── habit_card.dart
    └── stats_view.dart
```
