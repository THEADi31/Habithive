import 'package:flutter/material.dart';

import 'models/habit.dart';
import 'screens/auth_gate.dart';
import 'screens/habit_detail_screen.dart';
import 'screens/habit_form_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

/// Named routes. Arguments are passed through RouteSettings.
class Routes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const home = '/';
  static const detail = '/habit';
  static const form = '/habit/form';
  static const login = '/login';
  static const signup = '/signup';

  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case detail:
        final id = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => HabitDetailScreen(habitId: id));
      case form:
        final habit = settings.arguments as Habit?;
        return MaterialPageRoute(
            builder: (_) => HabitFormScreen(existing: habit));
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case home:
      default:
        return MaterialPageRoute(builder: (_) => const AuthGate());
    }
  }
}
