import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/auth_service.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/habit_card.dart';
import '../widgets/stats_view.dart';

class HabitHomePage extends StatefulWidget {
  const HabitHomePage({
    super.key,
    required this.authService,
    required this.user,
  });

  final AuthService authService;
  final User user;

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
      final normalizedName = habit.name.trim().toLowerCase();
      final alreadyExists = habits.any(
        (existing) => existing.name.trim().toLowerCase() == normalizedName,
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

  void _updateHabit(Habit original, Habit updated) {
    final normalizedName = updated.name.trim().toLowerCase();
    final duplicateExists = habits.any((habit) =>
        habit.id != original.id &&
        habit.name.trim().toLowerCase() == normalizedName);

    if (duplicateExists) {
      _showMessage('Another habit already uses this name.');
      return;
    }

    final index = habits.indexWhere((habit) => habit.id == original.id);
    if (index == -1) {
      _showMessage('This habit could not be found.');
      return;
    }

    setState(() => habits[index] = updated);
    _showMessage('Habit updated successfully.');
  }

  void _deleteHabit(Habit habit) {
    final index = habits.indexOf(habit);
    if (index == -1) return;

    setState(() => habits.removeAt(index));
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${habit.name} deleted.'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              if (!mounted || habits.any((item) => item.id == habit.id)) {
                return;
              }
              setState(() {
                final restoreIndex = index.clamp(0, habits.length);
                habits.insert(restoreIndex, habit);
              });
            },
          ),
        ),
      );
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

  void _showEditHabitDialog(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AddHabitDialog(
        initialHabit: habit,
        onAdd: (updated) => _updateHabit(habit, updated),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await widget.authService.signOut();
    } catch (_) {
      _showMessage('Unable to sign out. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Account options',
            onSelected: (value) {
              if (value == 'sign_out') _signOut();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(widget.user.email ?? 'Signed in'),
              ),
              const PopupMenuItem(
                value: 'sign_out',
                child: Text('Sign out'),
              ),
            ],
          ),
        ],
      ),
      body: _selectedTab == 0
          ? (habits.isEmpty
              ? const Center(child: Text('No habits yet. Tap + to add one.'))
              : ListView(
                  children: habits
                      .map((habit) => HabitCard(
                            habit: habit,
                            onToggleToday: () => _toggleToday(habit),
                            onDelete: () => _deleteHabit(habit),
                            onEdit: () => _showEditHabitDialog(habit),
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
