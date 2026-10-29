import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../services/auth_service.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// Routes between LoginScreen and HomeShell using the FirebaseAuth authStateChanges stream.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastSyncedUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          // Trigger Firestore sync once on login
          if (_lastSyncedUid != user.uid) {
            _lastSyncedUid = user.uid;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<HabitProvider>().syncWithCloud();
              }
            });
          }
          return const HomeShell();
        }

        _lastSyncedUid = null;
        return const LoginScreen();
      },
    );
  }
}

