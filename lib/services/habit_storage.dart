import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

class HabitStorage {
  static const _storageKey = 'habits';

  Future<List<Habit>> loadHabits() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedHabits = preferences.getString(_storageKey);
    if (encodedHabits == null) return [];

    final decoded = jsonDecode(encodedHabits) as List<dynamic>;
    return decoded
        .map((item) => Habit.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedHabits = jsonEncode(habits.map((habit) => habit.toJson()).toList());
    await preferences.setString(_storageKey, encodedHabits);
  }
}
