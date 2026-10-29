import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../services/notification_service.dart';

/// Create or edit a habit. Demonstrates Form, validators and pickers.
class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({super.key, this.existing});

  final Habit? existing;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late int _icon;
  late int _color;
  bool _reminderEnabled = false;
  TimeOfDay? _reminderTime;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _nameCtrl = TextEditingController(text: h?.name ?? '');
    _descCtrl = TextEditingController(text: h?.description ?? '');
    _icon = h?.iconIndex ?? 0;
    _color = h?.colorIndex ?? 0;
    _reminderEnabled = h?.reminderEnabled ?? false;

    if (h?.reminderTime != null) {
      final parts = h!.reminderTime!.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          _reminderTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final initial = _reminderTime ?? const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
        _reminderEnabled = true;
      });
    }
  }

  Future<void> _onToggleReminder(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.instance.requestPermissions();
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications are disabled in device settings.'),
          ),
        );
      }
      if (_reminderTime == null) {
        await _pickTime();
      } else {
        setState(() => _reminderEnabled = true);
      }
    } else {
      setState(() => _reminderEnabled = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<HabitProvider>();
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    final reminderStr = _reminderTime != null
        ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
        : null;

    if (_isEditing) {
      provider.updateHabit(widget.existing!.copyWith(
        name: name,
        description: desc,
        iconIndex: _icon,
        colorIndex: _color,
        reminderEnabled: _reminderEnabled,
        reminderTime: reminderStr,
      ));
    } else {
      provider.addHabit(
        name: name,
        description: desc,
        iconIndex: _icon,
        colorIndex: _color,
        reminderEnabled: _reminderEnabled,
        reminderTime: reminderStr,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit habit' : 'New habit')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'Habit name',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter a name';
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Daily reminder', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable daily reminder'),
                    subtitle: Text(
                      _reminderEnabled && _reminderTime != null
                          ? 'Remind daily at ${_reminderTime!.format(context)}'
                          : 'Receive a daily notification',
                    ),
                    secondary: Icon(
                      _reminderEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off_outlined,
                      color: _reminderEnabled ? scheme.primary : null,
                    ),
                    value: _reminderEnabled,
                    onChanged: _onToggleReminder,
                  ),
                  if (_reminderEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Reminder time'),
                      trailing: FilledButton.tonal(
                        onPressed: _pickTime,
                        child: Text(
                          _reminderTime != null
                              ? _reminderTime!.format(context)
                              : 'Set time',
                        ),
                      ),
                      onTap: _pickTime,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Icon', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < habitIcons.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _icon = i),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _icon
                            ? scheme.primary.withAlpha(40)
                            : scheme.onSurface.withAlpha(15),
                        border: Border.all(
                          color: i == _icon ? scheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(habitIcons[i]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Colour', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < habitColors.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _color = i),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: habitColors[i],
                      child: i == _color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              onPressed: _save,
              child: Text(_isEditing ? 'Save changes' : 'Create habit'),
            ),
          ],
        ),
      ),
    );
  }
}
