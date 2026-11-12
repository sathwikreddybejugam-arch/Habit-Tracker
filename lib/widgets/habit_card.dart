import 'package:flutter/material.dart';
import '../models/habit.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggleToday;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggleToday,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final last7Days =
        List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(habit.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Text(
                    '🔥 ${habit.currentStreak}${habit.frequency == 'weekly' ? 'w' : ''}'),
                IconButton(
                  tooltip: 'Edit habit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Delete habit',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(habit.category),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Text(habit.frequency == 'weekly'
                ? '${habit.category} · ${habit.completionsThisWeek()} / ${habit.weeklyTarget} this week'
                : '${habit.category} · Daily'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: last7Days.map((date) {
                final done = habit.isDoneOn(date);
                return Column(
                  children: [
                    Text(_weekdayLabel(date.weekday),
                        style: const TextStyle(fontSize: 10)),
                    const SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: done ? Colors.green : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onToggleToday,
                style: ElevatedButton.styleFrom(
                  backgroundColor: habit.isDoneToday ? Colors.green : null,
                ),
                child: Text(
                    habit.isDoneToday ? 'Done Today ✓' : 'Mark Done Today'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[weekday - 1];
  }
}
