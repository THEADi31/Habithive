import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../routes.dart';
import '../widgets/habit_tile.dart';
import '../widgets/progress_ring.dart';
import '../widgets/quote_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _message(int done, int total) {
    if (total == 0) return 'Add your first habit to begin.';
    if (done == total) return 'All done. Great work!';
    if (done == 0) return 'Start with one small win.';
    return 'Keep going, you are close.';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final theme = Theme.of(context);
    final today = DateTime.now();
    final habits = provider.habits;
    final total = habits.length;
    final done = provider.doneToday;
    final ratio = total == 0 ? 0.0 : done / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Text(
          _greeting(),
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(DateFormat('EEEE, d MMMM').format(today),
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ProgressRing(
                  value: ratio,
                  label: '${(ratio * 100).round()}%',
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        total == 0 ? 'No habits yet' : '$done of $total done',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(_message(done, total)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const QuoteCard(),
        const SizedBox(height: 16),
        Text("Today's habits", style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (habits.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.hive_outlined, size: 40),
                  const SizedBox(height: 8),
                  const Text('Nothing here yet.'),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () =>
                        context.read<HabitProvider>().addSamples(),
                    child: const Text('Add starter habits'),
                  ),
                ],
              ),
            ),
          )
        else
          for (final h in habits)
            HabitTile(
              habit: h,
              done: h.isDone(today),
              onToggle: () {
                HapticFeedback.lightImpact(); // native feature
                context.read<HabitProvider>().toggle(h.id, DateTime.now());
              },
              onTap: () =>
                  Navigator.pushNamed(context, Routes.detail, arguments: h.id),
            ),
      ],
    );
  }
}
