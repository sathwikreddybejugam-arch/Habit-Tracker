class Habit {
  static const List<String> categories = [
    'Health',
    'Fitness',
    'Study',
    'Productivity',
    'Personal Growth',
    'Other',
  ];

  final String id;
  final String name;
  final String frequency; // 'daily' or 'weekly'
  final String category;
  final int weeklyTarget;
  List<DateTime> completedDates;

  Habit({
    required String id,
    required String name,
    required String frequency,
    this.category = 'Other',
    int? weeklyTarget,
    List<DateTime>? completedDates,
  })  : id = id.trim(),
        name = name.trim(),
        frequency = frequency.trim().toLowerCase(),
        category = category.trim(),
        weeklyTarget = weeklyTarget ?? 1,
        completedDates = _normalizeDates(completedDates ?? []) {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Habit ID cannot be empty.');
    }
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Habit name cannot be empty.');
    }
    if (this.frequency != 'daily' && this.frequency != 'weekly') {
      throw ArgumentError.value(
        frequency,
        'frequency',
        'Frequency must be either daily or weekly.',
      );
    }
    if (!categories.contains(this.category)) {
      throw ArgumentError.value(
        category,
        'category',
        'Category must be one of: ${categories.join(', ')}.',
      );
    }
    if (this.weeklyTarget < 1 || this.weeklyTarget > 7) {
      throw ArgumentError.value(
        this.weeklyTarget,
        'weeklyTarget',
        'Weekly target must be between 1 and 7.',
      );
    }
  }

  static List<DateTime> _normalizeDates(List<DateTime> dates) {
    final uniqueDays = <String, DateTime>{};
    for (final date in dates) {
      final normalized = DateTime(date.year, date.month, date.day);
      final key = '${normalized.year}-${normalized.month}-${normalized.day}';
      uniqueDays[key] = normalized;
    }
    return uniqueDays.values.toList()
      ..sort((a, b) => a.compareTo(b));
  }

  bool isDoneOn(DateTime date) {
    return completedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool get isDoneToday => isDoneOn(DateTime.now());

  int completionsThisWeek([DateTime? date]) {
    final start = _weekStart(date ?? DateTime.now());
    final end = start.add(const Duration(days: 7));
    return completedDates
        .where((completion) => !completion.isBefore(start) && completion.isBefore(end))
        .length;
  }

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
    if (frequency == 'weekly') {
      var week = _weekStart(DateTime.now());
      if (_completionsInWeek(week) < weeklyTarget) {
        week = week.subtract(const Duration(days: 7));
      }
      var weeks = 0;
      while (_completionsInWeek(week) >= weeklyTarget) {
        weeks++;
        week = week.subtract(const Duration(days: 7));
      }
      return weeks;
    }

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
    if (frequency == 'weekly') {
      final completionsByWeek = <DateTime, int>{};
      for (final completion in completedDates) {
        final week = _weekStart(completion);
        completionsByWeek.update(week, (count) => count + 1, ifAbsent: () => 1);
      }
      final weeks = completionsByWeek.keys.toList()
        ..sort((a, b) => a.compareTo(b));
      var longest = 0;
      var current = 0;
      DateTime? previous;
      for (final week in weeks) {
        if (completionsByWeek[week]! < weeklyTarget) {
          current = 0;
        } else {
          current = previous != null &&
                  week.difference(previous).inDays == 7 &&
                  completionsByWeek[previous]! >= weeklyTarget
              ? current + 1
              : 1;
          if (current > longest) longest = current;
        }
        previous = week;
      }
      return longest;
    }

    final sorted = List<DateTime>.from(completedDates)
      ..sort((a, b) => a.compareTo(b));
    int longest = 1;
    int current = 1;
    for (int i = 1; i < sorted.length; i++) {
      final previous = sorted[i - 1];
      final next = sorted[i];
      final previousUtc = DateTime.utc(
        previous.year, previous.month, previous.day);
      final nextUtc = DateTime.utc(next.year, next.month, next.day);
      final diff = nextUtc.difference(previousUtc).inDays;
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
    return (completedDates.length / totalDaysTracked)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double completionRateForRecentPeriod([DateTime? date]) {
    final today = date ?? DateTime.now();
    if (frequency == 'weekly') {
      final currentWeek = _weekStart(today);
      var successfulWeeks = 0;
      for (var offset = 0; offset < 4; offset++) {
        final week = currentWeek.subtract(Duration(days: 7 * offset));
        if (_completionsInWeek(week) >= weeklyTarget) successfulWeeks++;
      }
      return successfulWeeks / 4;
    }

    final end = DateTime(today.year, today.month, today.day)
        .add(const Duration(days: 1));
    final start = end.subtract(const Duration(days: 30));
    final completions = completedDates
        .where((completion) =>
            !completion.isBefore(start) && completion.isBefore(end))
        .length;
    return completions / 30;
  }

  int _completionsInWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return completedDates
        .where((completion) =>
            !completion.isBefore(weekStart) && completion.isBefore(weekEnd))
        .length;
  }

  static DateTime _weekStart(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'frequency': frequency,
        'category': category,
        'weeklyTarget': weeklyTarget,
        'completedDates':
            completedDates.map((date) => date.toIso8601String()).toList(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final rawDates = json['completedDates'] as List<dynamic>? ?? const [];
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      frequency: json['frequency'] as String,
      category: json['category'] as String? ?? 'Other',
      weeklyTarget: json['weeklyTarget'] as int? ?? 1,
      completedDates: rawDates
          .map((date) => DateTime.parse(date as String))
          .toList(),
    );
  }
}
