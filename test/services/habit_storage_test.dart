import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/services/habit_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and restores habit details and completion dates', () async {
    final date = DateTime(2026, 11, 12);
    final habit = Habit(
      id: 'reading',
      name: 'Read',
      frequency: 'daily',
      category: 'Study',
      completedDates: [date],
    );
    final storage = HabitStorage();

    await storage.saveHabits([habit]);
    final restored = await storage.loadHabits();

    expect(restored, hasLength(1));
    expect(restored.single.id, habit.id);
    expect(restored.single.name, habit.name);
    expect(restored.single.frequency, habit.frequency);
    expect(restored.single.category, habit.category);
    expect(restored.single.completedDates, [date]);
  });

  test('loads an empty list when no habits have been saved', () async {
    expect(await HabitStorage().loadHabits(), isEmpty);
  });

  test('loads older saved habits without a category as Other', () async {
    SharedPreferences.setMockInitialValues({
      'habits': jsonEncode([
        {'id': 'old', 'name': 'Read', 'frequency': 'daily'},
      ]),
    });

    final restored = await HabitStorage().loadHabits();

    expect(restored.single.category, 'Other');
  });
}
