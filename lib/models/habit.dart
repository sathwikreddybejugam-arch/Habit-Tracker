class Habit {
  final String id;
  final String name;
  final String frequency; // 'daily' or 'weekly'
  List<DateTime> completedDates;

  Habit({
    required this.id,
    required this.name,
    required this.frequency,
    List<DateTime>? completedDates,
  }) : completedDates = completedDates ?? [];

  bool isDoneOn(DateTime date) {
    return completedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool get isDoneToday => isDoneOn(DateTime.now());

  void toggleToday() {
    final today = DateTime.now();
    if (isDoneToday) {
      completedDates.removeWhere((d) =>
          d.year == today.year &&
          d.month == today.month &&
          d.day == today.day);
    } else {
      completedDates.add(DateTime(today.year, today.month, today.day));
    }
  }

  int get currentStreak {
    // A streak remains active until the end of the day after the last
    // completion, so an unfinished habit today can retain yesterday's run.
    final today = DateTime.now();
    var day = DateTime(today.year, today.month, today.day);

    if (!isDoneOn(day)) {
      day = day.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (isDoneOn(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get longestStreak {
    if (completedDates.isEmpty) return 0;
    final sorted = List<DateTime>.from(completedDates)
      ..sort((a, b) => a.compareTo(b));
    int longest = 1;
    int current = 1;
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        current++;
        longest = longest > current ? longest : current;
      } else if (diff > 1) {
        current = 1;
      }
    }
    return longest;
  }

  double completionRate(int totalDaysTracked) {
    if (totalDaysTracked <= 0) return 0;
    return completedDates.length / totalDaysTracked;
  }
}
