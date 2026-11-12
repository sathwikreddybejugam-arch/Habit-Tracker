import 'package:flutter/material.dart';

import '../models/habit.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({
    super.key,
    required this.habits,
    required this.onToggleCompletion,
  });

  final List<Habit> habits;
  final void Function(Habit, DateTime) onToggleCompletion;

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final completed = widget.habits
        .where((habit) => habit.isDoneOn(_selectedDate))
        .toList();
    final incomplete = widget.habits
        .where((habit) => !habit.isDoneOn(_selectedDate))
        .toList();
    final dateLabel = MaterialLocalizations.of(context)
        .formatMediumDate(_selectedDate);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CalendarDatePicker(
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          onDateChanged: (date) => setState(() => _selectedDate = date),
        ),
        const Divider(),
        Text('Completed on $dateLabel',
            style: Theme.of(context).textTheme.titleMedium),
        if (completed.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No habits were marked complete on this date.'),
          )
        else
          ...completed.map((habit) => ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.teal),
                title: Text(habit.name),
                subtitle: Text(habit.category),
                trailing: IconButton(
                  tooltip: 'Undo completion for ${habit.name}',
                  onPressed: () =>
                      widget.onToggleCompletion(habit, _selectedDate),
                  icon: const Icon(Icons.undo),
                ),
              )),
        if (incomplete.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Not completed',
              style: Theme.of(context).textTheme.titleMedium),
          ...incomplete.map((habit) => ListTile(
                leading: const Icon(Icons.circle_outlined),
                title: Text(habit.name),
                subtitle: Text(habit.category),
                trailing: IconButton(
                  tooltip: 'Mark ${habit.name} complete',
                  onPressed: () =>
                      widget.onToggleCompletion(habit, _selectedDate),
                  icon: const Icon(Icons.check),
                ),
              )),
        ],
      ],
    );
  }
}
