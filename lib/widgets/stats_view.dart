import 'package:flutter/material.dart';
import '../models/habit.dart';

class StatsView extends StatelessWidget {
  final List<Habit> habits;

  const StatsView({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const Center(child: Text('Add habits to see stats.'));
    }

    final completedToday = habits.where((habit) => habit.isDoneToday).length;
    final bestCurrentStreak = habits
        .map((habit) => habit.currentStreak)
        .fold<int>(0, (best, streak) => streak > best ? streak : best);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryMetric(label: 'Habits', value: '${habits.length}'),
                _SummaryMetric(
                    label: 'Done today', value: '$completedToday'),
                _SummaryMetric(
                    label: 'Best streak', value: '$bestCurrentStreak'),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Completion rate · recent 30 days / 4 weeks'),
        ),
        ...habits.map((habit) {
          final rate = habit.completionRateForRecentPeriod() * 100;
          final unit = habit.frequency == 'weekly' ? 'weeks' : 'days';
          return Card(
            child: ListTile(
              title: Text(habit.name),
              subtitle: Text(
                  'Current: ${habit.currentStreak} $unit · Longest: ${habit.longestStreak} $unit'),
              trailing: Text('${rate.toStringAsFixed(0)}%'),
            ),
          );
        }),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label),
      ],
    );
  }
}
