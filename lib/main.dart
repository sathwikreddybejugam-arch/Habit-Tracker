import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'models/habit.dart';
import 'screens/auth_screen.dart';
import 'services/habit_backup.dart';
import 'services/auth_service.dart';
import 'services/habit_storage.dart';
import 'widgets/add_habit_dialog.dart';
import 'widgets/habit_card.dart';
import 'widgets/history_view.dart';
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
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
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
      body: SafeArea(
        child: Center(
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
                    'Configure Firebase for this app, then follow the setup steps in README.md.',
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
        if (user == null) return AuthScreen(authService: _authService);
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
  final HabitBackup _backup = HabitBackup();
  final TextEditingController _searchController = TextEditingController();
  late final HabitStorage _storage =
      HabitStorage(accountId: widget.user.uid);
  Future<void> _saveQueue = Future<void>.value();
  int _selectedTab = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortMode = 'name';
  bool _isLoading = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final savedHabits = await _storage.loadHabits();
      if (!mounted) return;
      setState(() {
        habits
          ..clear()
          ..addAll(savedHabits);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Saved habits could not be loaded.');
    }
  }

  void _saveHabits() {
    final snapshot = List<Habit>.from(habits);
    _saveQueue = _saveQueue
        .then((_) => _storage.saveHabits(snapshot))
        .catchError((_) => _showMessage('Habit changes could not be saved.'));
    unawaited(_saveQueue);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _addHabit(Habit habit) {
    final normalizedName = habit.name.trim().toLowerCase();
    final alreadyExists = habits.any(
      (existing) => existing.name.trim().toLowerCase() == normalizedName,
    );
    if (alreadyExists) {
      _showMessage('A habit with this name already exists.');
      return;
    }

    setState(() => habits.add(habit));
    _saveHabits();
    _showMessage('Habit added successfully.');
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
    _saveHabits();
    _showMessage('Habit updated successfully.');
  }

  void _deleteHabit(Habit habit) {
    final index = habits.indexOf(habit);
    if (index == -1) return;

    setState(() => habits.removeAt(index));
    _saveHabits();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text("'${habit.name}' deleted."),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              if (!mounted || habits.any((item) => item.id == habit.id)) {
                return;
              }
              setState(() {
                final restoreIndex = index.clamp(0, habits.length).toInt();
                habits.insert(restoreIndex, habit);
              });
              _saveHabits();
            },
          ),
        ),
      );
  }

  void _toggleToday(Habit habit) {
    setState(() => habit.toggleToday());
    _saveHabits();
  }

  void _toggleCompletionOnDate(Habit habit, DateTime date) {
    setState(() => habit.toggleDate(date));
    _saveHabits();
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

  Future<void> _copyBackup() async {
    await Clipboard.setData(ClipboardData(text: _backup.encode(habits)));
    _showMessage('Backup JSON copied to the clipboard.');
  }

  Future<void> _importBackup() async {
    final controller = TextEditingController();
    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Backup JSON',
              hintText: 'Paste a Habit Tracker backup',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Merge backup'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || source == null || source.trim().isEmpty) return;

    try {
      final incoming = _backup.decode(source);
      final merged = _backup.merge(habits, incoming);
      setState(() {
        habits
          ..clear()
          ..addAll(merged);
      });
      _saveHabits();
      _showMessage('Imported ${incoming.length} habits. Existing habits were kept.');
    } on FormatException catch (error) {
      _showMessage(error.message);
    }
  }

  Widget _buildHabitsTab() {
    if (habits.isEmpty) {
      return const Center(child: Text('No habits yet. Tap + to add one.'));
    }

    final categoryHabits = _selectedCategory == 'All'
        ? habits
        : habits.where((habit) => habit.category == _selectedCategory).toList();
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final visibleHabits = (normalizedQuery.isEmpty
        ? List<Habit>.from(categoryHabits)
        : categoryHabits
            .where((habit) => habit.name.toLowerCase().contains(normalizedQuery))
            .toList())
      ..sort((a, b) => _sortMode == 'streak'
          ? b.currentStreak.compareTo(a.currentStreak)
          : a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search habits',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              'All',
              ...Habit.categories,
            ].map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = category),
                ),
              );
            }).toList(),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButton<String>(
              value: _sortMode,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) setState(() => _sortMode = value);
              },
              items: const [
                DropdownMenuItem(value: 'name', child: Text('Name A–Z')),
                DropdownMenuItem(value: 'streak', child: Text('Longest current streak')),
              ],
            ),
          ),
        ),
        Expanded(
          child: visibleHabits.isEmpty
              ? Center(
                  child: Text(normalizedQuery.isNotEmpty
                      ? 'No habits match “$_searchQuery”.'
                      : 'No habits in $_selectedCategory yet.'),
                )
              : ListView(
                  children: visibleHabits
                      .map((habit) => HabitCard(
                            habit: habit,
                            onToggleToday: () => _toggleToday(habit),
                            onDelete: () => _deleteHabit(habit),
                            onEdit: () => _showEditHabitDialog(habit),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Backup and restore',
            onSelected: (action) {
              if (action == 'export') {
                _copyBackup();
              } else {
                _importBackup();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'export', child: Text('Copy backup JSON')),
              PopupMenuItem(value: 'import', child: Text('Import backup JSON')),
            ],
          ),
          IconButton(
            tooltip: 'Sign out ${widget.user.email ?? ''}',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedTab == 0
              ? _buildHabitsTab()
              : _selectedTab == 1
                  ? StatsView(habits: habits)
                  : HistoryView(
                      habits: habits,
                      onToggleCompletion: _toggleCompletionOnDate,
                    ),
      floatingActionButton: !_isLoading && _selectedTab == 0
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
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'History'),
        ],
      ),
    );
  }
}
