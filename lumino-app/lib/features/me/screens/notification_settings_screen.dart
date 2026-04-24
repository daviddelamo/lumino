import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme.dart';
import '../notification_prefs_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    final notifier = ref.read(notificationPrefsProvider.notifier);

    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      appBar: AppBar(
        backgroundColor: LuminoTheme.bg(context),
        elevation: 0,
        title: Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
      ),
      body: ListView(
        children: [
          Divider(height: 0, color: LuminoTheme.divider(context)),
          SwitchListTile(
            secondary: Icon(Icons.notifications_outlined,
                color: LuminoTheme.textSecondary(context), size: 20),
            title: Text('Daily reminder',
                style: Theme.of(context).textTheme.bodyMedium),
            subtitle: Text('Get a nudge to complete your habits',
                style: Theme.of(context).textTheme.bodySmall),
            value: prefs.enabled,
            onChanged: (value) => notifier.setEnabled(value),
          ),
          Divider(height: 0, color: LuminoTheme.divider(context)),
          ListTile(
            enabled: prefs.enabled,
            leading: Icon(Icons.schedule_outlined,
                color: prefs.enabled
                    ? LuminoTheme.textSecondary(context)
                    : LuminoTheme.textSecondary(context).withValues(alpha: 0.4),
                size: 20),
            title: Text('Reminder time',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: prefs.enabled
                          ? null
                          : LuminoTheme.textPrimary(context).withValues(alpha: 0.4),
                    )),
            trailing: Text(
              _formatTime(prefs.reminderHour, prefs.reminderMinute),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: prefs.enabled
                        ? LuminoTheme.primaryColor
                        : LuminoTheme.textSecondary(context).withValues(alpha: 0.4),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            onTap: prefs.enabled ? () => _pickTime(context, prefs, notifier) : null,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    NotificationPrefs prefs,
    NotificationPrefsNotifier notifier,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: prefs.reminderHour, minute: prefs.reminderMinute),
    );
    if (picked != null) {
      await notifier.setTime(picked.hour, picked.minute);
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }
}
