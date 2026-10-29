import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics service wrapping Firebase Analytics.
///
/// Complies with privacy requirements: does not log personal data such as habit names or emails.
class AnalyticsService {
  static FirebaseAnalytics? _instance;

  static FirebaseAnalytics? get _analytics {
    try {
      _instance ??= FirebaseAnalytics.instance;
      return _instance;
    } catch (e) {
      debugPrint('[analytics] FirebaseAnalytics instance unavailable: $e');
      return null;
    }
  }

  /// NavigatorObserver to track screen transitions automatically.
  static FirebaseAnalyticsObserver? get observer {
    final a = _analytics;
    if (a == null) return null;
    try {
      return FirebaseAnalyticsObserver(analytics: a);
    } catch (_) {
      return null;
    }
  }

  /// Sets the user identifier upon login, or clears it upon logout.
  static Future<void> setUserId(String? userId) async {
    try {
      await _analytics?.setUserId(id: userId);
      debugPrint('[analytics] setUserId: $userId');
    } catch (e) {
      debugPrint('[analytics] setUserId fallback: $e');
    }
  }

  /// Logs user sign-up event.
  static Future<void> logSignUp({String method = 'email'}) async {
    try {
      await _analytics?.logSignUp(signUpMethod: method);
      debugPrint('[analytics] sign_up method: $method');
    } catch (e) {
      debugPrint('[analytics] logSignUp error: $e');
    }
  }

  /// Logs user login event.
  static Future<void> logLogin({String method = 'email'}) async {
    try {
      await _analytics?.logLogin(loginMethod: method);
      debugPrint('[analytics] login method: $method');
    } catch (e) {
      debugPrint('[analytics] logLogin error: $e');
    }
  }

  /// Logs user logout event and clears user ID.
  static Future<void> logLogout() async {
    try {
      await _analytics?.logEvent(name: 'logout');
      await setUserId(null);
      debugPrint('[analytics] logout');
    } catch (e) {
      debugPrint('[analytics] logLogout error: $e');
    }
  }

  /// Logs habit creation (habit_id only, no personal name).
  static Future<void> logHabitCreated({required String habitId}) async {
    try {
      await _analytics?.logEvent(
        name: 'habit_created',
        parameters: {'habit_id': habitId},
      );
      debugPrint('[analytics] habit_created: $habitId');
    } catch (e) {
      debugPrint('[analytics] logHabitCreated error: $e');
    }
  }

  /// Logs habit completion, including streak length, and checks for milestone events.
  static Future<void> logHabitCompleted({
    required String habitId,
    required int streakLength,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'habit_completed',
        parameters: {
          'habit_id': habitId,
          'streak_length': streakLength,
        },
      );
      debugPrint(
          '[analytics] habit_completed: $habitId (streak: $streakLength)');

      // Check milestones (7 days, 30 days)
      if (streakLength == 7 || streakLength == 30) {
        await logStreakMilestone(
          habitId: habitId,
          milestone: streakLength,
          streakLength: streakLength,
        );
      }
    } catch (e) {
      debugPrint('[analytics] logHabitCompleted error: $e');
    }
  }

  /// Logs habit deletion.
  static Future<void> logHabitDeleted({required String habitId}) async {
    try {
      await _analytics?.logEvent(
        name: 'habit_deleted',
        parameters: {'habit_id': habitId},
      );
      debugPrint('[analytics] habit_deleted: $habitId');
    } catch (e) {
      debugPrint('[analytics] logHabitDeleted error: $e');
    }
  }

  /// Logs reminder enabled.
  static Future<void> logReminderEnabled({required String habitId}) async {
    try {
      await _analytics?.logEvent(
        name: 'reminder_enabled',
        parameters: {'habit_id': habitId},
      );
      debugPrint('[analytics] reminder_enabled: $habitId');
    } catch (e) {
      debugPrint('[analytics] logReminderEnabled error: $e');
    }
  }

  /// Logs reminder disabled.
  static Future<void> logReminderDisabled({required String habitId}) async {
    try {
      await _analytics?.logEvent(
        name: 'reminder_disabled',
        parameters: {'habit_id': habitId},
      );
      debugPrint('[analytics] reminder_disabled: $habitId');
    } catch (e) {
      debugPrint('[analytics] logReminderDisabled error: $e');
    }
  }

  /// Logs streak milestone achievement (e.g. 7 days, 30 days).
  static Future<void> logStreakMilestone({
    required String habitId,
    required int milestone,
    required int streakLength,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'streak_milestone',
        parameters: {
          'habit_id': habitId,
          'milestone': milestone,
          'streak_length': streakLength,
        },
      );
      debugPrint(
          '[analytics] streak_milestone: habit=$habitId, milestone=$milestone');
    } catch (e) {
      debugPrint('[analytics] logStreakMilestone error: $e');
    }
  }

  /// General logger for existing calls or diagnostic events.
  static void log(String event, [Map<String, Object>? params]) {
    debugPrint('[analytics] $event ${params ?? {}}');
    try {
      _analytics?.logEvent(name: event, parameters: params);
    } catch (_) {}
  }
}
