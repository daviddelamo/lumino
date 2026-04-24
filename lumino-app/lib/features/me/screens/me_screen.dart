import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme_provider.dart';
import '../../../services/auth_state.dart';
import '../../../shared/widgets/lumino_nav_bar.dart';
import '../../../theme.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(auth: auth),
            Expanded(
              child: ListView(
                children: [
                  _SettingsGroup(children: [
                    if (auth.isLoggedIn)
                      _SettingsTile(
                        icon: Icons.logout,
                        label: 'Sign out',
                        destructive: true,
                        onTap: () => _confirmSignOut(context, ref),
                      )
                    else
                      _SettingsTile(
                        icon: Icons.person_outline,
                        label: 'Sign in / Create account',
                        onTap: () => context.push('/onboarding/signup'),
                      ),
                  ]),
                  _SettingsGroup(children: [
                    SwitchListTile(
                      secondary: Icon(Icons.dark_mode_outlined,
                          color: LuminoTheme.textSecondary(context), size: 20),
                      title: Text('Dark mode',
                          style: Theme.of(context).textTheme.bodyMedium),
                      value: isDark,
                      onChanged: (_) =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () => context.push('/me/notifications'),
                    ),
                  ]),
                  _SettingsGroup(children: [
                    _SettingsTile(
                      icon: Icons.download_outlined,
                      label: 'Export my data (CSV)',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Export requires account sign-in')),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.delete_outline,
                      label: 'Delete account',
                      destructive: true,
                      onTap: () => _confirmDelete(context, ref),
                    ),
                  ]),
                  const _SettingsGroup(children: [
                    _SettingsTile(
                      icon: Icons.info_outline,
                      label: 'Version 1.0.0',
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const LuminoNavBar(currentIndex: 2),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/today');
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This will schedule your account for deletion in 30 days.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/onboarding/welcome');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final AuthState auth;
  const _ProfileHeader({required this.auth});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(auth.displayName ?? auth.email);
    final name = auth.displayName ?? auth.email ?? 'Local user';
    final showEmail = auth.displayName != null && auth.email != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: LuminoTheme.primaryColor.withValues(alpha: 0.12),
            child: initials != null
                ? Text(
                    initials,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: LuminoTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                  )
                : const Icon(Icons.person, color: LuminoTheme.primaryColor, size: 32),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.headlineSmall),
                if (showEmail) ...[
                  const SizedBox(height: 2),
                  Text(auth.email!, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 6),
                Text(
                  auth.isLoggedIn ? '☁  Cloud sync on' : 'Local only',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: auth.isLoggedIn
                            ? LuminoTheme.primaryColor
                            : LuminoTheme.textSecondary(context),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _initials(String? name) {
    if (name == null || name.isEmpty) return null;
    final display = name.contains('@') ? name.split('@').first : name;
    final parts = display.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Divider(height: 0, color: LuminoTheme.divider(context)),
          ...children,
          const SizedBox(height: 8),
        ],
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.destructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : LuminoTheme.textPrimary(context);
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color)),
      onTap: onTap,
    );
  }
}
