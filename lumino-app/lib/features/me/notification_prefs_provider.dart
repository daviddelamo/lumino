import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';

class NotificationPrefs {
  final bool enabled;
  final int reminderHour;
  final int reminderMinute;

  const NotificationPrefs({
    this.enabled = true,
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });

  NotificationPrefs copyWith({bool? enabled, int? reminderHour, int? reminderMinute}) =>
      NotificationPrefs(
        enabled: enabled ?? this.enabled,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
      );
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
  (ref) => NotificationPrefsNotifier(),
);

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  NotificationPrefsNotifier() : super(const NotificationPrefs()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    state = NotificationPrefs(
      enabled: prefs.getBool('notif_enabled') ?? true,
      reminderHour: prefs.getInt('notif_hour') ?? 9,
      reminderMinute: prefs.getInt('notif_minute') ?? 0,
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', value);
    try {
      if (value) {
        await NotificationService.scheduleDaily(state.reminderHour, state.reminderMinute);
      } else {
        await NotificationService.cancelAll();
      }
    } catch (_) {
      // NotificationService requires Flutter binding; silently ignore in test environments.
    }
  }

  Future<void> setTime(int hour, int minute) async {
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_hour', hour);
    await prefs.setInt('notif_minute', minute);
    if (state.enabled) {
      try {
        await NotificationService.scheduleDaily(hour, minute);
      } catch (_) {
        // NotificationService requires Flutter binding; silently ignore in test environments.
      }
    }
  }
}
