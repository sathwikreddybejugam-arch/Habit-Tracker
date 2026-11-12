import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

class HabitStorage {
  HabitStorage({this.accountId});

  final String? accountId;

  String get _storageKey =>
      accountId == null ? 'habits' : 'habits_${accountId!}';

  Future<List<Habit>> loadHabits() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedHabits = preferences.getString(_storageKey);
    if (encodedHabits == null) {
      // Assign pre-auth local data to the first signed-in account that loads
      // it, then remove the shared legacy key so another account cannot see it.
      if (accountId == null) return [];
      final legacyHabits = preferences.getString('habits');
      if (legacyHabits == null) return [];
      await preferences.setString(_storageKey, legacyHabits);
      await preferences.remove('habits');
      return _decodeHabits(legacyHabits);
    }

    return _decodeHabits(encodedHabits);
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedHabits = jsonEncode(habits.map((habit) => habit.toJson()).toList());
    await preferences.setString(_storageKey, encodedHabits);
  }

  List<Habit> _decodeHabits(String encoded) {
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .map((item) => Habit.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
