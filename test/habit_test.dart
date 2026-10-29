import 'package:flutter_test/flutter_test.dart';
import 'package:habit_hive/models/habit.dart';
import 'package:habit_hive/utils/date_helpers.dart';

void main() {
  final today = DateTime.now().dayOnly;

  test('current streak counts consecutive days ending today', () {
    final habit = Habit(
      id: '1',
      name: 'Read',
      completedDays: {
        today.dateKey,
        today.addDays(-1).dateKey,
        today.addDays(-2).dateKey,
      },
    );
    expect(habit.currentStreak, 3);
  });

  test('streak survives if today is not done yet', () {
    final habit = Habit(
      id: '2',
      name: 'Run',
      completedDays: {today.addDays(-1).dateKey, today.addDays(-2).dateKey},
    );
    expect(habit.currentStreak, 2);
  });

  test('best streak finds the longest run', () {
    final habit = Habit(
      id: '3',
      name: 'Code',
      completedDays: {
        today.addDays(-10).dateKey,
        today.addDays(-9).dateKey,
        today.addDays(-8).dateKey,
        today.addDays(-7).dateKey,
        today.addDays(-1).dateKey,
      },
    );
    expect(habit.bestStreak, 4);
  });

  test('json round trip keeps data', () {
    final habit = Habit(
      id: '4',
      name: 'Water',
      iconIndex: 2,
      colorIndex: 1,
      completedDays: {today.dateKey},
    );
    final copy = Habit.fromJson(habit.toJson());
    expect(copy.name, 'Water');
    expect(copy.iconIndex, 2);
    expect(copy.isDone(DateTime.now()), true);
  });
}
