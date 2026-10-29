import 'package:flutter/material.dart';

import '../utils/date_helpers.dart';

/// Icons and colours a habit can use (stored as indexes, so saved data stays small).
const List<IconData> habitIcons = [
  Icons.fitness_center,
  Icons.menu_book,
  Icons.water_drop,
  Icons.self_improvement,
  Icons.bedtime,
  Icons.code,
  Icons.directions_run,
  Icons.restaurant,
  Icons.savings,
  Icons.brush,
  Icons.music_note,
  Icons.edit_note,
];

const List<Color> habitColors = [
  Color(0xFF6C4CF1),
  Color(0xFF00A896),
  Color(0xFFEF476F),
  Color(0xFFF59E0B),
  Color(0xFF3B82F6),
  Color(0xFF22C55E),
];

/// One habit, its reminder settings, and the days it was completed.
class Habit {
  Habit({
    required this.id,
    required this.name,
    this.description = '',
    this.iconIndex = 0,
    this.colorIndex = 0,
    this.reminderTime,
    this.reminderEnabled = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    Set<String>? completedDays,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now(),
        completedDays = completedDays ?? <String>{};

  final String id;
  final String name;
  final String description;
  final int iconIndex;
  final int colorIndex;

  /// Time formatted as "HH:mm" (e.g. "08:30")
  final String? reminderTime;
  final bool reminderEnabled;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Dates (yyyy-MM-dd) on which the habit was done.
  final Set<String> completedDays;

  IconData get icon => habitIcons[iconIndex % habitIcons.length];
  Color get color => habitColors[colorIndex % habitColors.length];

  bool isDone(DateTime day) => completedDays.contains(day.dateKey);

  /// Consecutive days ending today (or yesterday if today is not done yet).
  int get currentStreak {
    var day = DateTime.now().dayOnly;
    if (!completedDays.contains(day.dateKey)) day = day.addDays(-1);
    var count = 0;
    while (completedDays.contains(day.dateKey)) {
      count++;
      day = day.addDays(-1);
    }
    return count;
  }

  /// Longest run of consecutive days ever.
  int get bestStreak {
    if (completedDays.isEmpty) return 0;
    final days = completedDays.map(DateTime.parse).toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i] == days[i - 1].addDays(1)) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }

  /// Fraction (0..1) of the last [days] days that were completed.
  double completionRate(int days) {
    final today = DateTime.now().dayOnly;
    var count = 0;
    for (var i = 0; i < days; i++) {
      if (completedDays.contains(today.addDays(-i).dateKey)) count++;
    }
    return count / days;
  }

  Habit copyWith({
    String? name,
    String? description,
    int? iconIndex,
    int? colorIndex,
    String? reminderTime,
    bool? reminderEnabled,
    DateTime? updatedAt,
    Set<String>? completedDays,
    bool clearReminderTime = false,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconIndex: iconIndex ?? this.iconIndex,
      colorIndex: colorIndex ?? this.colorIndex,
      reminderTime: clearReminderTime ? null : (reminderTime ?? this.reminderTime),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completedDays: completedDays ?? this.completedDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': iconIndex,
        'color': colorIndex,
        'reminderTime': reminderTime,
        'reminderEnabled': reminderEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'days': completedDays.toList(),
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: j['name'] as String,
        description: (j['description'] ?? '') as String,
        iconIndex: (j['icon'] ?? 0) as int,
        colorIndex: (j['color'] ?? 0) as int,
        reminderTime: j['reminderTime'] as String?,
        reminderEnabled: (j['reminderEnabled'] ?? false) as bool,
        createdAt: DateTime.tryParse((j['createdAt'] ?? '') as String),
        updatedAt: DateTime.tryParse((j['updatedAt'] ?? '') as String),
        completedDays:
            ((j['days'] ?? <dynamic>[]) as List).map((e) => e as String).toSet(),
      );
}
