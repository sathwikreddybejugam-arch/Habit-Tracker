# Habit Tracker

A simple Flutter habit tracker app. Add habits, mark them done each day,
track streaks, and view a 7-day mini calendar plus a stats screen.

## What's included

```
habit_tracker/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/
│   │   └── habit.dart         # Habit model + streak logic
│   └── widgets/
│       ├── add_habit_dialog.dart
│       ├── habit_card.dart
│       └── stats_view.dart
├── pubspec.yaml
├── .gitignore
└── README.md
```

Note: this only contains the Dart source (`lib/`) and `pubspec.yaml`.
The `android/`, `ios/`, `web/` platform folders are **not** included —
you'll generate them in step 1 below.

## 1. Set up the project locally

Unzip this folder, then open a terminal inside it and run:

```bash
flutter create .
```

This generates the missing platform folders (android, ios, web, etc.)
without touching your existing `lib/` and `pubspec.yaml`.

Then fetch dependencies:

```bash
flutter pub get
```

## 2. Run it

```bash
flutter run
```

Pick a connected device, emulator, or Chrome when prompted.

## 3. Push to GitHub

```bash
git init
git add .
git commit -m "Initial habit tracker app"
```

Create a new empty repo on [github.com](https://github.com) (no README,
so it doesn't conflict), then:

```bash
git remote add origin https://github.com/YOUR_USERNAME/habit_tracker.git
git branch -M main
git push -u origin main
```

## Next steps / ideas

- Persist habits with `shared_preferences` or `sqflite` so data survives restarts
- Add habit colors/icons
- Weekly view instead of just 7-day
- Notifications/reminders
