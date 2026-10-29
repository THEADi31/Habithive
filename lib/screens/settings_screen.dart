import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in at any time to access your habits.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await AuthService.instance.signOut();
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text('This deletes every habit and its history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<HabitProvider>().clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('All data cleared')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final user = AuthService.instance.currentUser;

    const topics = {
      'Module 1': 'App structure, MaterialApp, hot reload, Flutter tooling',
      'Module 2': 'Dart classes, enums, extensions, null safety, async/await, JSON',
      'Module 3': 'Widgets, forms, dialogs, navigation, named routes, light/dark themes',
      'Module 4': 'Provider state, http API, shared_preferences, haptics',
      'Phase 0': 'Quote API cache-busting, local caching, animated switcher, error recovery',
      'Phase 1': 'Local notifications, repeating daily alarms, timezone support, boot receiver',
      'Phase 2': 'SQLite database, foreign key cascade, versioning, repository pattern',
      'Phase 3': 'Firebase Auth (email/password), Firestore cloud sync, security rules',
      'Phase 4': 'Firebase Analytics events, milestones, DebugView configuration',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user != null) ...[
          Text('Account', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: Text(user.email ?? 'Signed in user'),
                  subtitle: const Text('Cloud sync active'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sync with cloud now'),
                  onTap: () async {
                    await context.read<HabitProvider>().syncWithCloud();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sync completed')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Log out', style: TextStyle(color: Colors.red)),
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('Appearance', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('Light')),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('Dark')),
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('Auto')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) =>
                    context.read<SettingsProvider>().setThemeMode(s.first),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Data', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Reset all data'),
            onTap: () => _confirmReset(context),
          ),
        ),
        const SizedBox(height: 16),
        Text('About', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('HabitHive'),
                subtitle: const Text('Version 1.0.0'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'HabitHive',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Built with Flutter',
                ),
              ),
              ExpansionTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('Course topics covered'),
                children: [
                  for (final t in topics.entries)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      title: Text(t.key),
                      subtitle: Text(t.value),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
