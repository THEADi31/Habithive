import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import 'auth_service.dart';
import 'habit_repository.dart';

/// Manages bidirectional synchronization between SQLite (local source of truth)
/// and Cloud Firestore under users/{uid}/habits/{habitId} with completions subcollection.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userHabitsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('habits');

  /// Pushes a habit and its completions to Firestore when user is signed in.
  Future<void> pushHabit(Habit habit) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    try {
      final habitDoc = _userHabitsRef(user.uid).doc(habit.id);
      await habitDoc.set({
        'name': habit.name,
        'description': habit.description,
        'icon_index': habit.iconIndex,
        'color_index': habit.colorIndex,
        'reminder_time': habit.reminderTime,
        'reminder_enabled': habit.reminderEnabled,
        'created_at': habit.createdAt.toIso8601String(),
        'updated_at': habit.updatedAt.toIso8601String(),
      }, SetOptions(merge: true));

      // Push completions to subcollection
      final completionsRef = habitDoc.collection('completions');
      for (final date in habit.completedDays) {
        await completionsRef.doc(date).set({
          'date': date,
          'completed': true,
        });
      }
      debugPrint('[SyncService] Pushed habit ${habit.id} to Firestore.');
    } catch (e) {
      debugPrint('[SyncService] Failed to push habit ${habit.id}: $e');
    }
  }

  /// Pushes a completion change to Firestore.
  Future<void> pushCompletion({
    required String habitId,
    required String dateKey,
    required bool completed,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    try {
      final habitDoc = _userHabitsRef(user.uid).doc(habitId);
      final completionDoc = habitDoc.collection('completions').doc(dateKey);

      if (completed) {
        await completionDoc.set({
          'date': dateKey,
          'completed': true,
        });
      } else {
        await completionDoc.delete();
      }

      await habitDoc.set({
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      debugPrint('[SyncService] Pushed completion $dateKey ($completed) for $habitId.');
    } catch (e) {
      debugPrint('[SyncService] Failed to push completion: $e');
    }
  }

  /// Deletes a habit and its subcollections from Firestore.
  Future<void> deleteHabit(String habitId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    try {
      final habitDoc = _userHabitsRef(user.uid).doc(habitId);
      final completions = await habitDoc.collection('completions').get();
      for (final doc in completions.docs) {
        await doc.reference.delete();
      }
      await habitDoc.delete();
      debugPrint('[SyncService] Deleted habit $habitId from Firestore.');
    } catch (e) {
      debugPrint('[SyncService] Failed to delete habit $habitId: $e');
    }
  }

  /// Synchronizes Firestore with local SQLite upon user login.
  /// Resolves conflicts using the latest updated_at timestamp.
  Future<void> syncOnLogin(HabitRepository repo) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    try {
      debugPrint('[SyncService] Pulling habits from Firestore for user ${user.uid}...');
      final snapshot = await _userHabitsRef(user.uid).get();
      final remoteHabitIds = <String>{};

      for (final doc in snapshot.docs) {
        remoteHabitIds.add(doc.id);
        final data = doc.data();

        // Fetch completions subcollection
        final completionsSnapshot =
            await doc.reference.collection('completions').get();
        final completedDays = <String>{};
        for (final cDoc in completionsSnapshot.docs) {
          final cData = cDoc.data();
          if (cData['completed'] == true) {
            completedDays.add(cDoc.id);
          }
        }

        final remoteHabit = Habit(
          id: doc.id,
          name: (data['name'] ?? '') as String,
          description: (data['description'] ?? '') as String,
          iconIndex: (data['icon_index'] ?? 0) as int,
          colorIndex: (data['color_index'] ?? 0) as int,
          reminderTime: data['reminder_time'] as String?,
          reminderEnabled: (data['reminder_enabled'] ?? false) as bool,
          createdAt: DateTime.tryParse((data['created_at'] ?? '') as String),
          updatedAt: DateTime.tryParse((data['updated_at'] ?? '') as String),
          completedDays: completedDays,
        );

        final localHabit = await repo.getHabitById(doc.id);

        if (localHabit == null) {
          // New from remote -> store into local SQLite
          await repo.createHabit(remoteHabit);
        } else {
          // Conflict resolution: latest updated_at wins
          if (remoteHabit.updatedAt.isAfter(localHabit.updatedAt)) {
            await repo.updateHabit(remoteHabit);
            // Sync completions
            for (final day in remoteHabit.completedDays) {
              await repo.markCompleteForDate(
                habitId: remoteHabit.id,
                date: DateTime.parse(day),
                completed: true,
              );
            }
          } else if (localHabit.updatedAt.isAfter(remoteHabit.updatedAt)) {
            // Local is newer -> push local to Firestore
            await pushHabit(localHabit);
          }
        }
      }

      // Check if there are local habits that don't exist in Firestore yet (e.g. offline created)
      final allLocalHabits = await repo.getAllHabits();
      for (final local in allLocalHabits) {
        if (!remoteHabitIds.contains(local.id)) {
          await pushHabit(local);
        }
      }

      debugPrint('[SyncService] Sync completed successfully.');
    } catch (e) {
      debugPrint('[SyncService] syncOnLogin error: $e');
    }
  }
}

