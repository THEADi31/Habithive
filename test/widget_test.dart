import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:habit_hive/app.dart';
import 'package:habit_hive/providers/habit_provider.dart';
import 'package:habit_hive/providers/settings_provider.dart';
import 'package:habit_hive/services/database_helper.dart';
import 'package:habit_hive/services/habit_repository.dart';
import 'package:habit_hive/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('HabitHiveApp smoke test', (WidgetTester tester) async {
    final storage = StorageService();
    final habitRepo = HabitRepository(DatabaseHelper.instance);
    final habits = HabitProvider(habitRepo);
    final settings = SettingsProvider(storage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HabitProvider>.value(value: habits),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ],
        child: const HabitHiveApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('HabitHive'), findsWidgets);
  });
}
