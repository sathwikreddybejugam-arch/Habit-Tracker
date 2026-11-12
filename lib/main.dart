import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key, this.firebaseError});

  final Object? firebaseError;

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _themeMode = preferences.getBool('darkTheme') == true
        ? ThemeMode.dark
        : ThemeMode.light);
  }

  Future<void> _toggleTheme() async {
    final nextMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setState(() => _themeMode = nextMode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('darkTheme', nextMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
          useMaterial3: true),
      themeMode: _themeMode,
      home: widget.firebaseError == null
          ? AuthGate(
              isDarkMode: _themeMode == ThemeMode.dark,
              onToggleTheme: _toggleTheme,
            )
          : FirebaseSetupScreen(error: widget.firebaseError!),
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
  const AuthGate({super.key, required this.isDarkMode, required this.onToggleTheme});

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

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
          isDarkMode: isDarkMode,
          onToggleTheme: onToggleTheme,
        );
      },
    );
  }
}

void _noThemeChange() {}

class HabitHomePage extends StatefulWidget {
  const HabitHomePage({
    super.key,
    this.user,
    this.authService,
    this.isDarkMode = false,
    this.onToggleTheme = _noThemeChange,
  });

  final User? user;
  final AuthService? authService;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<HabitHomePage> createState() => _HabitHomePageState();
}

class _HabitHomePageState extends State<HabitHomePage> {
  final List<Habit> habits = [];
  final HabitBackup _backup = HabitBackup();
  final TextEditingController _searchController = TextEditingController();
  late final HabitStorage _storage =
      HabitStorage(accountId: widget.user?.uid);
  Future<void> _saveQueue = Future<void>.value();
  int _selectedTab = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortMode = 'name';
  bool _showArchived = false;
  bool _isLoading = true;
  bool _loadError = false;

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
    setState(() {
      _isLoading = true;
      _loadError = false;
    });
    try {
      final savedHabits = await _storage.loadHabits();
      if (!mounted) return;
      setState(() {
        habits
          ..clear()
          ..addAll(savedHabits);
        _isLoading = false;
        _loadError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = true;
      });
    }
  }

  void _saveHabits() {
    if (_isLoading || _loadError) return;
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

  void _toggleArchive(Habit habit) {
    setState(() => habit.isArchived = !habit.isArchived);
    _saveHabits();
    _showMessage(habit.isArchived ? 'Habit archived.' : 'Habit restored.');
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
    final authService = widget.authService;
    if (authService == null) return;
    try {
      await authService.signOut();
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
          IconButton(
            tooltip: isDarkMode ? 'Use light theme' : 'Use dark theme',
            onPressed: onToggleTheme,
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
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
    final activeHabits = habits
        .where((habit) => habit.isArchived == _showArchived)
        .toList();
    if (activeHabits.isEmpty) {
      if (_showArchived) {
        return const Center(child: Text('No archived habits.'));
      }
      return const Center(child: Text('No habits yet. Tap + to add one.'));
    }

    final completedToday = activeHabits.where((habit) => habit.isDoneToday).length;
    final categoryHabits = _selectedCategory == 'All'
        ? activeHabits
        : activeHabits
            .where((habit) => habit.category == _selectedCategory)
            .toList();
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Today's progress · $completedToday of ${habits.length}"),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: completedToday / habits.length),
            ],
          ),
        ),
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
                            onToggleToday: habit.isArchived
                                ? null
                                : () => _toggleToday(habit),
                            onDelete: () => _deleteHabit(habit),
                            onEdit: () => _showEditHabitDialog(habit),
                            onArchive: () => _toggleArchive(habit),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildStorageError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text('Saved habits could not be loaded',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'Your saved data has been left untouched. Try loading it again before making changes.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadHabits,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          IconButton(
            tooltip: _showArchived ? 'Show active habits' : 'Show archived habits',
            onPressed: () => setState(() => _showArchived = !_showArchived),
            icon: Icon(_showArchived ? Icons.checklist : Icons.archive_outlined),
          ),
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
          if (widget.user != null)
            IconButton(
              tooltip: 'Sign out ${widget.user?.email ?? ''}',
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError
                  ? _buildStorageError()
              : _selectedTab == 0
                  ? _buildHabitsTab()
                  : _selectedTab == 1
                      ? StatsView(habits: habits)
                      : HistoryView(
                          habits: habits,
                          onToggleCompletion: _toggleCompletionOnDate,
                        ),
        ),
      ),
      floatingActionButton: !_isLoading && _selectedTab == 0 && !_showArchived
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
