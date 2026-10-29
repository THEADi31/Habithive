import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../services/storage_service.dart';

/// Holds the theme choice (light / dark / system) and saves it.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage);

  final StorageService _storage;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    _themeMode = await _storage.loadThemeMode();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    AnalyticsService.log('theme_changed', {'mode': mode.name});
    notifyListeners();
    _storage.saveThemeMode(mode);
  }
}
