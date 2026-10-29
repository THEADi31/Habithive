import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';
import '../routes.dart';

/// Handles local notifications, daily repeating reminders, and permission requests.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Initialize Timezones
    try {
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint('[NotificationService] Timezone fallback to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Platform settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 3. Initialize plugin with notification response callback
    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final habitId = response.payload;
        if (habitId != null && habitId.isNotEmpty) {
          _navigateToHabit(habitId);
        }
      },
    );

    _isInitialized = true;

    // 4. Check if the app was launched by tapping a notification
    try {
      final launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToHabit(payload);
          });
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Error reading launch details: $e');
    }
  }

  void _navigateToHabit(String habitId) {
    Routes.navigatorKey.currentState?.pushNamed(
      Routes.detail,
      arguments: habitId,
    );
  }

  /// Requests notification and alarm permissions on Android and iOS.
  Future<bool> requestPermissions() async {
    bool granted = true;

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final notifGranted =
          await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
      if (notifGranted != null && !notifGranted) granted = false;
    }

    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final iosGranted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (iosGranted != null && !iosGranted) granted = false;
    }

    return granted;
  }

  int _notificationId(String habitId) {
    return habitId.hashCode.abs() % 2147483647;
  }

  /// Schedules a repeating daily notification at the specified [hour] and [minute].
  Future<void> scheduleDailyHabitReminder({
    required String habitId,
    required String habitName,
    required int hour,
    required int minute,
  }) async {
    await cancelReminder(habitId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Daily reminders to complete your habits',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id: _notificationId(habitId),
      title: 'Habit Reminder: $habitName',
      body: 'Time to make progress on $habitName today!',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: habitId,
    );
  }

  /// Cancels any scheduled reminder for the specified habit.
  Future<void> cancelReminder(String habitId) async {
    await _notificationsPlugin.cancel(id: _notificationId(habitId));
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Synchronizes a habit's reminder configuration with the notification scheduler.
  Future<void> syncHabitReminder(Habit habit) async {
    if (habit.reminderEnabled && habit.reminderTime != null) {
      final parts = habit.reminderTime!.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          await scheduleDailyHabitReminder(
            habitId: habit.id,
            habitName: habit.name,
            hour: hour,
            minute: minute,
          );
          return;
        }
      }
    }
    await cancelReminder(habit.id);
  }
}
