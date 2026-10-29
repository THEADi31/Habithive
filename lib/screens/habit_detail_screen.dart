import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../routes.dart';
import '../widgets/heat_grid.dart';
import '../widgets/stat_card.dart';

class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete habit?'),
        content: const Text('Its history will be removed too.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final provider = context.read<HabitProvider>();
      Navigator.pop(context);
      provider.deleteHabit(habitId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habit = provider.byId(habitId);

    if (habit == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Habit not found.')),
      );
    }

    final theme = Theme.of(context);
    final today = DateTime.now();
    final doneToday = habit.isDone(today);

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit),
            onPressed: () =>
                Navigator.pushNamed(context, Routes.form, arguments: habit),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: habit.color.withAlpha(45),
                foregroundColor: habit.color,
                child: Icon(habit.icon, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.description.isEmpty
                          ? 'No description'
                          : habit.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (habit.reminderEnabled && habit.reminderTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.alarm,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Daily reminder: ${habit.reminderTime}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: StatCard(
                      icon: Icons.local_fire_department,
                      value: '${habit.currentStreak}',
                      label: 'Current streak')),
              Expanded(
                  child: StatCard(
                      icon: Icons.emoji_events,
                      value: '${habit.bestStreak}',
                      label: 'Best streak')),
              Expanded(
                  child: StatCard(
                      icon: Icons.event_available,
                      value: '${habit.completedDays.length}',
                      label: 'Total days')),
            ],
          ),
          const SizedBox(height: 16),
          Text('Last 5 weeks', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          HeatGrid(completedDays: habit.completedDays, color: habit.color),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            icon: Icon(doneToday ? Icons.undo : Icons.check),
            label: Text(doneToday ? 'Undo today' : 'Mark today as done'),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.read<HabitProvider>().toggle(habit.id, DateTime.now());
            },
          ),
        ],
      ),
    );
  }
}
