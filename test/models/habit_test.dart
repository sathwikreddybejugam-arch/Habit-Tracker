import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/habit.dart';

void main() {
  group('Habit streak calculations', () {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final yesterday = normalizedToday.subtract(const Duration(days: 1));
    final twoDaysAgo = normalizedToday.subtract(const Duration(days: 2));

    Habit makeHabit(List<DateTime> completedDates) {
      return Habit(
        id: 'test-habit',
        name: 'Read',
        frequency: 'daily',
        completedDates: completedDates,
      );
    }

    test('current streak is zero when there are no completions', () {
      expect(makeHabit([]).currentStreak, 0);
    });

    test('current streak includes a completion from today', () {
      expect(makeHabit([normalizedToday]).currentStreak, 1);
    });

    test('current streak remains active when last completed yesterday', () {
      expect(makeHabit([yesterday]).currentStreak, 1);
    });

    test('current streak counts consecutive completions through today', () {
      expect(
        makeHabit([yesterday, normalizedToday]).currentStreak,
        2,
      );
    });

    test('longest streak counts consecutive dates regardless of input order', () {
      expect(
        makeHabit([twoDaysAgo, normalizedToday, yesterday]).longestStreak,
        3,
      );
    });

    test('longest streak resets after a gap', () {
      final fourDaysAgo = normalizedToday.subtract(const Duration(days: 4));
      expect(
        makeHabit([fourDaysAgo, twoDaysAgo, normalizedToday]).longestStreak,
        1,
      );
    });

    test('longest streak is zero when there are no completions', () {
      expect(makeHabit([]).longestStreak, 0);
    });
  });
}
