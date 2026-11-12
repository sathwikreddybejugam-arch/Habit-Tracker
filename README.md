# Habit Tracker

A Flutter habit tracker for creating daily or weekly habits, recording completions, and reviewing streaks. Habits can be categorized and are saved locally between launches.

## Current features

- Create, edit, and delete habits, with a five-second undo action.
- Set a daily or weekly frequency and choose a category.
- Mark today's completion and view a rolling seven-day history.
- Review current and longest streaks and a completion percentage.
- Save habits and completion dates on the device with `shared_preferences`.

## Project structure

```text
lib/
  main.dart
  models/habit.dart
  services/habit_storage.dart
  widgets/
    add_habit_dialog.dart
    habit_card.dart
    stats_view.dart
test/
  models/habit_test.dart
  services/habit_storage_test.dart
```

## Setup

This repository currently contains Dart source files and does not include generated platform folders. With Flutter 3.16 or later installed, generate the platform folders if needed, then fetch packages and run:

```bash
flutter create .
flutter pub get
flutter run
```

## Tests

Run the Flutter test suite with:

```bash
flutter test
```

Test status: not run in this workspace.

## Storage

Habit records and completion dates are stored locally on the device using `shared_preferences`. Data is not synced between devices or backed up to a server. Clearing app data or uninstalling the app may remove saved habits.

## Development history

The development branch currently contains 11 meaningful development commits. The completed work covers streak calculation, validation, editing, deletion undo, categories, and local persistence. The remaining roadmap will be recorded here after implementation.
