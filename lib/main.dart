import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/habit.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'widgets/add_habit_dialog.dart';
import 'widgets/habit_card.dart';
import 'widgets/stats_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    firebaseError = error;
  }

  runApp(HabitTrackerApp(firebaseError: firebaseError));
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key, this.firebaseError});

  final Object? firebaseError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: firebaseError == null
          ? const AuthGate()
          : FirebaseSetupScreen(error: firebaseError!),
    );
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Firebase setup required',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create or select a Firebase project, then follow the setup steps in README.md and run flutterfire configure.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  static final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Unable to check sign-in status.')),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return AuthScreen(authService: _authService);
        }

        return HabitHomePage(
          key: ValueKey(user.uid),
          user: user,
          authService: _authService,
        );
      },
    );
  }
}

class HabitHomePage extends StatefulWidget {
  const HabitHomePage({
    super.key,
    required this.user,
    required this.authService,
  });

  final User user;
  final AuthService authService;

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
          content: Text('" ${habit.name} " deleted.'),
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
    } on FirebaseAuthException {
      _showMessage('Unable to sign out. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          IconButton(
            tooltip: 'Sign out ${widget.user.email ?? ''}',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
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
