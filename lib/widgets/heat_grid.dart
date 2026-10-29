import 'package:flutter/material.dart';

import '../utils/date_helpers.dart';

/// Calendar-style grid of the last [weeks] weeks (7 columns). Today is the last cell.
class HeatGrid extends StatelessWidget {
  const HeatGrid({
    super.key,
    required this.completedDays,
    required this.color,
    this.weeks = 5,
  });

  final Set<String> completedDays;
  final Color color;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now().dayOnly;
    final total = weeks * 7;

    Widget cell(int index) {
      final day = today.addDays(index - (total - 1));
      final done = completedDays.contains(day.dateKey);
      final isToday = index == total - 1;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: done ? color : scheme.onSurface.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: scheme.primary, width: 2)
                    : null,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var w = 0; w < weeks; w++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [for (var d = 0; d < 7; d++) cell(w * 7 + d)],
            ),
          ),
      ],
    );
  }
}
