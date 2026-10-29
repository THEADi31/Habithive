import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../utils/date_helpers.dart';
import '../widgets/stat_card.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final habits = provider.habits;

    if (habits.isEmpty) {
      return const Center(child: Text('Add habits to see your stats.'));
    }

    final week = provider.completionsLastDays(7);
    final maxCount = week.fold<int>(1, (m, c) => c > m ? c : m);
    final today = DateTime.now().dayOnly;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
                child: StatCard(
                    icon: Icons.list_alt,
                    value: '${habits.length}',
                    label: 'Habits')),
            Expanded(
                child: StatCard(
                    icon: Icons.task_alt,
                    value: '${provider.totalCheckIns}',
                    label: 'Check-ins')),
            Expanded(
                child: StatCard(
                    icon: Icons.emoji_events,
                    value: '${provider.bestStreakOverall}',
                    label: 'Best streak')),
          ],
        ),
        const SizedBox(height: 16),
        Text('This week', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < week.length; i++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${week[i]}', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            height: week[i] == 0 ? 4 : 80 * week[i] / maxCount,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('E')
                                .format(today.addDays(i - 6))
                                .substring(0, 1),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Last 30 days', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final h in habits)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(h.name),
                    Text('${(h.completionRate(30) * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: h.completionRate(30),
                  minHeight: 10,
                  color: h.color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
