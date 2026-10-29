import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

/// Local storage using the shared_preferences plugin.
class StorageService {
  static const _habitsKey = 'habits_v1';
  static const _themeKey = 'theme_mode';

  Future<List<Habit>> loadHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_habitsKey);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Could not load habits: $e');
      return [];
    }
  }

  Future<void> saveHabits(List<Habit> habits) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _habitsKey, jsonEncode(habits.map((h) => h.toJson()).toList()));
    } catch (e) {
      debugPrint('Could not save habits: $e');
    }
  }

  Future<ThemeMode> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_themeKey);
      return ThemeMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (e) {
      debugPrint('Could not save theme: $e');
    }
  }
}
