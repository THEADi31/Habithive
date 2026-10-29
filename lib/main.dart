import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/habit_provider.dart';
import 'providers/settings_provider.dart';
import 'services/database_helper.dart';
import 'services/habit_repository.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[Firebase] Initialization error: $e');
  }

  // Initialize notifications service
  await NotificationService.instance.initialize();

  // Initialize SQLite repository and perform migration if any
  final habitRepo = HabitRepository(DatabaseHelper.instance);
  await habitRepo.init();

  final storage = StorageService();
  final habits = HabitProvider(habitRepo);
  final settings = SettingsProvider(storage);
  await Future.wait([habits.load(), settings.load()]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<HabitProvider>.value(value: habits),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ],
      child: const HabitHiveApp(),
    ),
  );
}
