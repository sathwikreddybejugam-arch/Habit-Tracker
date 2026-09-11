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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: habits.map((habit) {
        const totalDays = 30; // stats window
        final rate = (habit.completionRate(totalDays) * 100).clamp(0, 100);
        return Card(
          child: ListTile(
            title: Text(habit.name),
            subtitle: Text(
                'Current streak: ${habit.currentStreak} · Longest: ${habit.longestStreak}'),
            trailing: Text('${rate.toStringAsFixed(0)}%'),
          ),
        );
      }).toList(),
    );
  }
}
