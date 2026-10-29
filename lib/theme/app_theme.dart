import 'package:flutter/material.dart';

/// Bright (light) and dark themes built from one seed colour.
class AppTheme {
  static const Color seed = Color(0xFF6C4CF1);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final isLight = brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isLight ? const Color(0xFFF7F5FF) : const Color(0xFF12111A),
    );
  }
}
