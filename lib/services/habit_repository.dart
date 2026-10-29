import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/habit.dart';
import '../utils/date_helpers.dart';
import 'database_helper.dart';

/// Repository providing CRUD operations, completion marking, streak calculations,
/// and SharedPreferences-to-SQLite data migration.
class HabitRepository {
  HabitRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;
  static const _legacyStorageKey = 'habits_v1';

  /// Initializes the repository and runs one-time migration from SharedPreferences if needed.
  Future<void> init() async {
    await _dbHelper.database;
    await migrateFromSharedPreferences();
  }

  /// Migrates existing habits from SharedPreferences into SQLite.
  Future<void> migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_legacyStorageKey);
      if (raw == null || raw.isEmpty) return;

      final list = (jsonDecode(raw) as List)
          .map((e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) {
        debugPrint('[HabitRepository] Migrating ${list.length} habits from SharedPreferences...');
        for (final habit in list) {
          await createHabit(habit);
        }
        await prefs.remove(_legacyStorageKey);
        debugPrint('[HabitRepository] Migration completed successfully.');
      }
    } catch (e) {
      debugPrint('[HabitRepository] Migration failed: $e');
    }
  }

  /// Retrieves all habits with their completed dates.
  Future<List<Habit>> getAllHabits() async {
    final db = await _dbHelper.database;
    final habitRows = await db.query('habits', orderBy: 'created_at ASC');

    if (habitRows.isEmpty) return [];

    final completionRows = await db.query(
      'habit_completions',
      where: 'completed = 1',
    );

    // Group completion dates by habit_id
    final completionsByHabit = <String, Set<String>>{};
    for (final row in completionRows) {
      final habitId = row['habit_id'] as String;
      final date = row['date'] as String;
      completionsByHabit.putIfAbsent(habitId, () => <String>{}).add(date);
    }

    return habitRows.map((row) {
      final id = row['id'] as String;
      return Habit(
        id: id,
        name: row['name'] as String,
        description: (row['description'] ?? '') as String,
        iconIndex: (row['icon_index'] ?? 0) as int,
        colorIndex: (row['color_index'] ?? 0) as int,
        reminderTime: row['reminder_time'] as String?,
        reminderEnabled: (row['reminder_enabled'] as int? ?? 0) == 1,
        createdAt: DateTime.tryParse(row['created_at'] as String),
        updatedAt: DateTime.tryParse(row['updated_at'] as String),
        completedDays: completionsByHabit[id] ?? <String>{},
      );
    }).toList();
  }

  /// Retrieves a single habit by [id] with its completions.
  Future<Habit?> getHabitById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final row = rows.first;

    final completionRows = await db.query(
      'habit_completions',
      columns: ['date'],
      where: 'habit_id = ? AND completed = 1',
      whereArgs: [id],
    );

    final completedDays =
        completionRows.map((r) => r['date'] as String).toSet();

    return Habit(
      id: id,
      name: row['name'] as String,
      description: (row['description'] ?? '') as String,
      iconIndex: (row['icon_index'] ?? 0) as int,
      colorIndex: (row['color_index'] ?? 0) as int,
      reminderTime: row['reminder_time'] as String?,
      reminderEnabled: (row['reminder_enabled'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(row['created_at'] as String),
      updatedAt: DateTime.tryParse(row['updated_at'] as String),
      completedDays: completedDays,
    );
  }

  /// Inserts a new habit into the database.
  Future<void> createHabit(Habit habit) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        'habits',
        {
          'id': habit.id,
          'name': habit.name,
          'description': habit.description,
          'icon_index': habit.iconIndex,
          'color_index': habit.colorIndex,
          'reminder_time': habit.reminderTime,
          'reminder_enabled': habit.reminderEnabled ? 1 : 0,
          'created_at': habit.createdAt.toIso8601String(),
          'updated_at': habit.updatedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final date in habit.completedDays) {
        await txn.insert(
          'habit_completions',
          {
            'id': '${habit.id}_$date',
            'habit_id': habit.id,
            'date': date,
            'completed': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Updates an existing habit.
  Future<void> updateHabit(Habit habit) async {
    final db = await _dbHelper.database;
    await db.update(
      'habits',
      {
        'name': habit.name,
        'description': habit.description,
        'icon_index': habit.iconIndex,
        'color_index': habit.colorIndex,
        'reminder_time': habit.reminderTime,
        'reminder_enabled': habit.reminderEnabled ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  /// Deletes a habit (cascades to habit_completions).
  Future<void> deleteHabit(String id) async {
    final db = await _dbHelper.database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  /// Marks a habit complete or incomplete for a specific [date].
  Future<void> markCompleteForDate({
    required String habitId,
    required DateTime date,
    required bool completed,
  }) async {
    final db = await _dbHelper.database;
    final dateKey = date.dateKey;
    final completionId = '${habitId}_$dateKey';

    await db.transaction((txn) async {
      if (completed) {
        await txn.insert(
          'habit_completions',
          {
            'id': completionId,
            'habit_id': habitId,
            'date': dateKey,
            'completed': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        await txn.delete(
          'habit_completions',
          where: 'habit_id = ? AND date = ?',
          whereArgs: [habitId, dateKey],
        );
      }

      await txn.update(
        'habits',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [habitId],
      );
    });
  }

  /// Returns the set of completed dates for a given habit.
  Future<Set<String>> getCompletionHistory(String habitId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'habit_completions',
      columns: ['date'],
      where: 'habit_id = ? AND completed = 1',
      whereArgs: [habitId],
      orderBy: 'date ASC',
    );
    return rows.map((r) => r['date'] as String).toSet();
  }

  /// Calculates the current consecutive streak for a habit.
  Future<int> getCurrentStreak(String habitId) async {
    final completedDays = await getCompletionHistory(habitId);
    var day = DateTime.now().dayOnly;
    if (!completedDays.contains(day.dateKey)) day = day.addDays(-1);
    var count = 0;
    while (completedDays.contains(day.dateKey)) {
      count++;
      day = day.addDays(-1);
    }
    return count;
  }

  /// Calculates the best streak ever achieved for a habit.
  Future<int> getBestStreak(String habitId) async {
    final completedDays = await getCompletionHistory(habitId);
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

  /// Returns the total completions for each of the last [days] days.
  Future<List<int>> getCompletionsLastDays(int days) async {
    final habits = await getAllHabits();
    final today = DateTime.now().dayOnly;
    return [
      for (var i = days - 1; i >= 0; i--)
        habits.where((h) => h.isDone(today.addDays(-i))).length,
    ];
  }

  /// Deletes all habits and their completions.
  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('habits');
  }
}

