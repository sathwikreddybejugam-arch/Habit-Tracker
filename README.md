# Habit Tracker

A Flutter app for building consistent routines. Create habits, set a daily or weekly goal, record completions, and review progress over time. Sign-in uses Firebase Authentication; habit records remain on the device.

## Features

### Accounts

- Create an account or sign in with email and password.
- Request a password reset email and sign out.
- Keep each signed-in account's locally saved habits separate on a device.

### Habit management

- Create, edit, archive, restore, or delete habits. Deleted habits can be restored for five seconds.
- Add an optional note and select one of six categories.
- Choose daily tracking or a weekly goal of one to seven completions.
- Validate habit names and prevent duplicate names.

### Tracking and insights

- Mark a habit complete for today or change its completion on a past date.
- See the recent seven-day completion strip, current streak, and longest streak.
- Review completion history by date and filter habits by category.
- Search by name, sort alphabetically or by current streak, and view a daily progress bar.
- Review recent completion rates: 30 days for daily habits and four calendar weeks for weekly habits.

### Data and accessibility

- Save habits and completion history locally between launches.
- Copy a versioned JSON backup and merge it into the current account without replacing existing habits.
- Switch between light and dark themes; the theme choice is saved on the device.
- Use screen-reader labels for completion history and layouts that adapt to narrow and wide screens.

## Screenshots

Screenshots are not included yet. To add them, capture the app after Firebase is configured, save PNG files under `docs/screenshots/`, and replace the placeholders below with the matching Markdown image links.

- **Habit dashboard:** capture the category filters, progress bar, and habit cards.
- **History:** capture the date picker with completed and incomplete habits.
- **Stats:** capture the summary and recent completion rates.
- **Sign-in:** capture the sign-in or account creation screen.

For example, after adding the image file, use `![Habit dashboard](docs/screenshots/habit-dashboard.png)`.

## Tech stack

- **Flutter / Dart** for the cross-platform app. The Dart SDK constraint is `>=3.2.0 <4.0.0`.
- **Material 3** widgets for the interface.
- **Firebase Core and Firebase Authentication** for email/password account access.
- **shared_preferences** for local habit and theme storage.
- **flutter_test** and **flutter_lints** for the existing test and lint setup.

## Architecture and project structure

```text
lib/
├── main.dart                       # App startup, Firebase gate, and habit dashboard
├── firebase_options.dart            # Safe placeholder; generate for your Firebase project
├── models/
│   └── habit.dart                   # Habit data, serialization, streaks, and weekly goals
├── screens/
│   └── auth_screen.dart             # Sign in, sign up, and password reset
├── services/
│   ├── auth_service.dart            # Firebase Authentication calls
│   ├── habit_storage.dart           # Per-account local persistence
│   └── habit_backup.dart            # JSON backup validation and merge
└── widgets/
    ├── add_habit_dialog.dart
    ├── habit_card.dart
    ├── history_view.dart
    └── stats_view.dart

test/
├── models/habit_test.dart
├── services/habit_storage_test.dart
└── widgets/habit_category_filter_test.dart
```

The repository contains Dart source only; generated `android/`, `ios/`, and `web/` platform folders are not checked in. The app keeps its screens and state in Flutter widgets, with habit rules in the model and storage/auth/backup work in separate services.

## Set up and run

### Requirements

- Flutter with a Dart SDK that satisfies the constraint in `pubspec.yaml`.
- A Firebase project with **Authentication → Email/Password** enabled.
- Firebase CLI and FlutterFire CLI for generating this app's Firebase configuration.

### First-time setup

1. Install Flutter and confirm the toolchain with `flutter doctor`.
2. From the repository root, generate platform folders for the devices you intend to run. For the default mobile and web targets, use:

   ```bash
   flutter create --platforms=android,ios,web .
   ```

3. Create or select a Firebase project, enable the Email/Password sign-in provider, then install and run the FlutterFire CLI:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Select the platforms you generated. FlutterFire replaces the safe placeholder in `lib/firebase_options.dart` with the public app identifiers for your Firebase project. Do not put service-account keys or other server credentials in the Flutter app.

4. Fetch packages and start the app:

   ```bash
   flutter pub get
   flutter run
   ```

Choose a connected device or emulator. To run on Chrome after generating the web platform, use `flutter run -d chrome`.

## Tests and checks

Run the existing test suite and static analysis from the repository root:

```bash
flutter test
flutter analyze
```

**Status for this update:** tests and analysis were not run. Flutter and Dart are not installed in the authoring workspace. The repository contains model tests for streaks and categories, storage tests for save/load and older records, and widget tests for category filtering. Backup, authentication, history editing, and other newer interactions do not yet have dedicated test coverage.

## Data and limitations

- Habit records are serialized as JSON and stored locally with `shared_preferences`, under a key scoped to the signed-in Firebase user ID. They are not uploaded to Firebase or synchronized across devices.
- If the app finds records saved under the earlier shared local key, it assigns them to the first signed-in account that loads them, then removes that shared key.
- Clearing app data or uninstalling the app can remove local records. Use **Copy backup JSON** and keep the copied text somewhere safe; **Import backup JSON** merges records and reports duplicate IDs or names rather than replacing existing habits.
- The saved theme preference is device-wide. It is not synced across devices or accounts.
- Firebase configuration is a placeholder until `flutterfire configure` is run for your project. The generated platform folders are also a local setup step.
- Screenshots are not available in this repository. Scheduled notifications, cloud habit sync, and cross-device backups are not implemented.

## Development history

The feature branch contains **31 meaningful development commits** after the initial repository commit. Merge and branch-sync commits are excluded from this count.

| Commits | Work completed |
| --- | --- |
| 1–5 | Corrected current streak behavior, added streak tests, normalized and validated habit data, and improved name validation and duplicate handling. |
| 6–9 | Added habit editing, connected edit controls to the dashboard, and added deletion with undo. |
| 10–15 | Added selectable categories, Firebase email/password authentication, local persistence, deletion feedback fixes, sign-in gating, and account-scoped local storage. |
| 16–18 | Added category filtering (with widget coverage), name search, and sorting by name or current streak. |
| 19–23 | Added weekly completion goals, date-based history, recent-period rates, JSON backup/merge, and editing past completion dates. |
| 24–29 | Added dashboard progress, habit archiving, saved dark theme, optional notes, screen-reader labels, and responsive layouts. |
| 30–31 | Hardened calendar and streak date handling across daylight changes and protected saved data when local storage cannot be read. |

## Possible next steps

Ideas for future work, not features in this release: reminders, cloud synchronization, and automated widget-level coverage.
