import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'routes.dart';
import 'services/analytics_service.dart';
import 'theme/app_theme.dart';

class HabitHiveApp extends StatelessWidget {
  const HabitHiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<SettingsProvider>().themeMode;
    final observer = AnalyticsService.observer;

    return MaterialApp(
      title: 'HabitHive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      navigatorKey: Routes.navigatorKey,
      navigatorObservers: [
        if (observer != null) observer,
      ],
      initialRoute: Routes.home,
      onGenerateRoute: Routes.generate,
    );
  }
}
