import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import '../services/analytics_service.dart';
import '../services/habit_repository.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../utils/date_helpers.dart';

/// App state for habits (Provider + ChangeNotifier), backed by HabitRepository and SyncService.
class HabitProvider extends ChangeNotifier {
  HabitProvider(this._repository);

  final HabitRepository _repository;
  List<Habit> _habits = [];

  List<Habit> get habits => List.unmodifiable(_habits);

  Habit? byId(String id) {
    for (final h in _habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  int get doneToday {
    final today = DateTime.now();
    return _habits.where((h) => h.isDone(today)).length;
  }

  int get totalCheckIns =>
      _habits.fold<int>(0, (sum, h) => sum + h.completedDays.length);

  int get bestStreakOverall =>
      _habits.fold<int>(0, (m, h) => h.bestStreak > m ? h.bestStreak : m);

  /// Number of habits completed on each of the last [n] days (oldest first).
  List<int> completionsLastDays(int n) {
    final today = DateTime.now().dayOnly;
    return [
      for (var i = n - 1; i >= 0; i--)
        _habits.where((h) => h.isDone(today.addDays(-i))).length,
    ];
  }

  Future<void> load() async {
    _habits = await _repository.getAllHabits();
    for (final h in _habits) {
      if (h.reminderEnabled) {
        NotificationService.instance.syncHabitReminder(h);
      }
    }
    notifyListeners();
  }

  /// Syncs local SQLite database with Firestore and reloads habits.
  Future<void> syncWithCloud() async {
    await SyncService.instance.syncOnLogin(_repository);
    await load();
  }

  String _newId([int salt = 0]) =>
      '${DateTime.now().microsecondsSinceEpoch}_$salt';

  Future<void> addHabit({
    required String name,
    String description = '',
    int iconIndex = 0,
    int colorIndex = 0,
    String? reminderTime,
    bool reminderEnabled = false,
  }) async {
    final habit = Habit(
      id: _newId(),
      name: name,
      description: description,
      iconIndex: iconIndex,
      colorIndex: colorIndex,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
    );
    _habits.add(habit);
    notifyListeners();

    await _repository.createHabit(habit);
    NotificationService.instance.syncHabitReminder(habit);
    SyncService.instance.pushHabit(habit);

    AnalyticsService.logHabitCreated(habitId: habit.id);
    if (reminderEnabled) {
      AnalyticsService.logReminderEnabled(habitId: habit.id);
    }
  }

  Future<void> addSamples() async {
    const samples = [
      ['Drink water', 'Eight glasses through the day', 2, 4],
      ['Read 20 pages', 'Any book counts', 1, 0],
      ['Practise coding', 'One small problem', 5, 1],
    ];
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      final habit = Habit(
        id: _newId(i),
        name: s[0] as String,
        description: s[1] as String,
        iconIndex: s[2] as int,
        colorIndex: s[3] as int,
      );
      _habits.add(habit);
      await _repository.createHabit(habit);
      SyncService.instance.pushHabit(habit);
      AnalyticsService.logHabitCreated(habitId: habit.id);
    }
    notifyListeners();
  }

  Future<void> updateHabit(Habit updated) async {
    final i = _habits.indexWhere((h) => h.id == updated.id);
    if (i < 0) return;
    final previous = _habits[i];
    _habits[i] = updated;
    notifyListeners();

    await _repository.updateHabit(updated);
    NotificationService.instance.syncHabitReminder(updated);
    SyncService.instance.pushHabit(updated);

    if (!previous.reminderEnabled && updated.reminderEnabled) {
      AnalyticsService.logReminderEnabled(habitId: updated.id);
    } else if (previous.reminderEnabled && !updated.reminderEnabled) {
      AnalyticsService.logReminderDisabled(habitId: updated.id);
    }
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    notifyListeners();

    await _repository.deleteHabit(id);
    NotificationService.instance.cancelReminder(id);
    SyncService.instance.deleteHabit(id);
    AnalyticsService.logHabitDeleted(habitId: id);
  }

  Future<void> toggle(String id, DateTime day) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i < 0) return;
    final habit = _habits[i];
    final key = day.dateKey;
    final days = Set<String>.from(habit.completedDays);
    final wasDone = days.contains(key);
    final isDone = !wasDone;

    if (wasDone) {
      days.remove(key);
    } else {
      days.add(key);
    }
    final updatedHabit = habit.copyWith(completedDays: days);
    _habits[i] = updatedHabit;
    notifyListeners();

    await _repository.markCompleteForDate(
      habitId: id,
      date: day,
      completed: isDone,
    );
    SyncService.instance.pushCompletion(
      habitId: id,
      dateKey: key,
      completed: isDone,
    );

    if (isDone) {
      AnalyticsService.logHabitCompleted(
        habitId: id,
        streakLength: updatedHabit.currentStreak,
      );
    }
  }

  Future<void> clearAll() async {
    final ids = _habits.map((h) => h.id).toList();
    _habits = [];
    await NotificationService.instance.cancelAllReminders();
    await _repository.clearAll();
    for (final id in ids) {
      SyncService.instance.deleteHabit(id);
    }
    AnalyticsService.log('data_cleared');
    notifyListeners();
  }
}
