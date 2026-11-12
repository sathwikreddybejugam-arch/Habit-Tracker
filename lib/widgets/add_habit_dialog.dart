import 'package:flutter/material.dart';
import '../models/habit.dart';

class AddHabitDialog extends StatefulWidget {
  final void Function(Habit) onAdd;
  final Habit? initialHabit;

  const AddHabitDialog({
    super.key,
    required this.onAdd,
    this.initialHabit,
  });

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _frequency;
  late String _category;
  late int _weeklyTarget;

  bool get _isEditing => widget.initialHabit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialHabit?.name ?? '',
    );
    _frequency = widget.initialHabit?.frequency ?? 'daily';
    _category = widget.initialHabit?.category ?? 'Other';
    _weeklyTarget = widget.initialHabit?.weeklyTarget ?? 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final original = widget.initialHabit;
    widget.onAdd(Habit(
      id: original?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      frequency: _frequency,
      category: _category,
      weeklyTarget: _weeklyTarget,
      completedDates: original == null
          ? []
          : List<DateTime>.from(original.completedDates),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 60,
              decoration: const InputDecoration(
                hintText: 'e.g. Drink water',
                labelText: 'Habit name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) return 'Please enter a habit name.';
                if (name.length < 2) {
                  return 'Habit name must be at least 2 characters.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              ],
              onChanged: (val) =>
                  setState(() => _frequency = val ?? 'daily'),
            ),
            if (_frequency == 'weekly') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _weeklyTarget,
                decoration: const InputDecoration(
                  labelText: 'Weekly goal',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(7, (index) => index + 1)
                    .map((count) => DropdownMenuItem(
                          value: count,
                          child: Text('$count ${count == 1 ? 'day' : 'days'} per week'),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _weeklyTarget = value ?? 1),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: Habit.categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _category = value ?? 'Other'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save changes' : 'Add habit'),
        ),
      ],
    );
  }
}
