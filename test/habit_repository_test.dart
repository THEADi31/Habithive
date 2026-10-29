import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:habit_hive/models/habit.dart';
import 'package:habit_hive/services/database_helper.dart';
import 'package:habit_hive/services/habit_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  test('HabitRepository creates, retrieves, and completes habits', () async {
    final repo = HabitRepository(DatabaseHelper.instance);
    await repo.init();
    await repo.clearAll();

    final habit = Habit(
      id: 'test_habit_1',
      name: 'Morning Jog',
      description: 'Run 5km',
      reminderTime: '07:00',
      reminderEnabled: true,
    );

    await repo.createHabit(habit);

    final retrieved = await repo.getHabitById('test_habit_1');
    expect(retrieved, isNotNull);
    expect(retrieved!.name, 'Morning Jog');
    expect(retrieved.reminderTime, '07:00');
    expect(retrieved.reminderEnabled, true);

    // Mark completed today
    final today = DateTime.now();
    await repo.markCompleteForDate(
      habitId: 'test_habit_1',
      date: today,
      completed: true,
    );

    final afterComplete = await repo.getHabitById('test_habit_1');
    expect(afterComplete!.isDone(today), true);
    expect(afterComplete.currentStreak, 1);

    // Clean up
    await repo.deleteHabit('test_habit_1');
    final afterDelete = await repo.getHabitById('test_habit_1');
    expect(afterDelete, isNull);
  });
}
