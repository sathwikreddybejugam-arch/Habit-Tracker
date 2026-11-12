import 'dart:convert';

import '../models/habit.dart';

class HabitBackup {
  static const _format = 'habit_tracker_backup';
  static const _version = 1;

  String encode(List<Habit> habits) => jsonEncode({
        'format': _format,
        'version': _version,
        'habits': habits.map((habit) => habit.toJson()).toList(),
      });

  List<Habit> decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != _format ||
        decoded['version'] != _version ||
        decoded['habits'] is! List<dynamic>) {
      throw const FormatException('This is not a supported Habit Tracker backup.');
    }

    try {
      final habits = (decoded['habits'] as List<dynamic>)
          .map((item) => Habit.fromJson(item as Map<String, dynamic>))
          .toList();
      final ids = habits.map((habit) => habit.id).toSet();
      final names = habits
          .map((habit) => habit.name.trim().toLowerCase())
          .toSet();
      if (ids.length != habits.length || names.length != habits.length) {
        throw const FormatException('The backup contains duplicate habits.');
      }
      return habits;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('The backup contains invalid habit data.');
    }
  }

  List<Habit> merge(List<Habit> existing, List<Habit> incoming) {
    final ids = existing.map((habit) => habit.id).toSet();
    final names = existing
        .map((habit) => habit.name.trim().toLowerCase())
        .toSet();
    for (final habit in incoming) {
      if (ids.contains(habit.id) ||
          names.contains(habit.name.trim().toLowerCase())) {
        throw const FormatException(
            'A habit with the same ID or name already exists.');
      }
    }
    return [...existing, ...incoming];
  }
}
