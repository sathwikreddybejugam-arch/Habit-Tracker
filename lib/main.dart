import 'package:flutter/material.dart';
import 'models/habit.dart';
import 'widgets/add_habit_dialog.dart';
import 'widgets/habit_card.dart';
import 'widgets/stats_view.dart';

void main() {
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const HabitHomePage(),
    );
  }
}

class HabitHomePage extends StatefulWidget {
  const HabitHomePage({super.key});

  @override
  State<HabitHomePage> createState() => _HabitHomePageState();
}

class _HabitHomePageState extends State<HabitHomePage> {
  final List<Habit> habits = [];
  int _selectedTab = 0;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _addHabit(Habit habit) {
    try {
      final normalizedName = habit.name.toLowerCase();
      final alreadyExists = habits.any(
        (existing) => existing.name.toLowerCase() == normalizedName,
      );

      if (alreadyExists) {
        _showMessage('A habit with this name already exists.');
        return;
      }

      setState(() => habits.add(habit));
      _showMessage('Habit added successfully.');
    } on ArgumentError catch (error) {
      _showMessage('Unable to add habit: ${error.message}');
    } catch (_) {
      _showMessage('Something went wrong while adding the habit.');
    }
  }

  void _deleteHabit(Habit habit) {
    setState(() => habits.remove(habit));
  }

  void _toggleToday(Habit habit) {
    setState(() => habit.toggleToday());
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (context) => AddHabitDialog(onAdd: _addHabit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Tracker')),
      body: _selectedTab == 0
          ? (habits.isEmpty
              ? const Center(child: Text('No habits yet. Tap + to add one.'))
              : ListView(
                  children: habits
                      .map((habit) => HabitCard(
                            habit: habit,
                            onToggleToday: () => _toggleToday(habit),
                            onDelete: () => _deleteHabit(habit),
                          ))
                      .toList(),
                ))
          : StatsView(habits: habits),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: _showAddHabitDialog,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.checklist), label: 'Habits'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }
}
