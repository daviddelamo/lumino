import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme_provider.dart';
import '../me_providers.dart';
import '../../../theme.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Me',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 26, color: const Color(0xFF3A2A1A))),
            ),
            Expanded(
              child: ListView(
                children: [
                  _Section(title: 'Account', children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Sign in / Create account'),
                      onTap: () => context.push('/onboarding/signup'),
                    ),
                  ]),
                  _Section(title: 'Preferences', children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Dark mode'),
                      value: isDark,
                      onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                    ),
                  ]),
                  _Section(title: 'Data', children: [
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: const Text('Export my data (CSV)'),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export requires account sign-in')),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: const Text('Delete account', style: TextStyle(color: Colors.red)),
                      onTap: () => _confirmDelete(context, ref),
                    ),
                  ]),
                  const _Section(title: 'About', children: [
                    ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Version 1.0.0'),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 2),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This will schedule your account for deletion in 30 days.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authServiceProvider).logout();
              if (context.mounted) {
                context.go('/onboarding/welcome');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFA08070),
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600),
            ),
          ),
          ...children,
        ],
      );
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) => BottomNavigationBar(
        currentIndex: currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Habits'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
        ],
        onTap: (i) {
          if (i == 0) context.go('/today');
          if (i == 1) context.go('/habits');
        },
      );
}
