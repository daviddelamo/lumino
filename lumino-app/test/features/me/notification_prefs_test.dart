import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumino_app/features/me/notification_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults: enabled=true, hour=9, minute=0', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Trigger provider creation and wait for async _load() to complete.
    container.read(notificationPrefsProvider);
    await Future.delayed(Duration.zero);
    final prefs = container.read(notificationPrefsProvider);
    expect(prefs.enabled, true);
    expect(prefs.reminderHour, 9);
    expect(prefs.reminderMinute, 0);
  });

  test('setEnabled persists to SharedPreferences', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(notificationPrefsProvider);
    await Future.delayed(Duration.zero);

    await container.read(notificationPrefsProvider.notifier).setEnabled(false);

    expect(container.read(notificationPrefsProvider).enabled, false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notif_enabled'), false);
  });

  test('setTime persists hour and minute', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(notificationPrefsProvider);
    await Future.delayed(Duration.zero);

    // Disable first so setTime does not call NotificationService (not initialized in tests)
    await container.read(notificationPrefsProvider.notifier).setEnabled(false);
    await container.read(notificationPrefsProvider.notifier).setTime(8, 30);

    final state = container.read(notificationPrefsProvider);
    expect(state.reminderHour, 8);
    expect(state.reminderMinute, 30);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('notif_hour'), 8);
    expect(prefs.getInt('notif_minute'), 30);
  });

  test('loads persisted values on construction', () async {
    SharedPreferences.setMockInitialValues({
      'notif_enabled': false,
      'notif_hour': 20,
      'notif_minute': 45,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Trigger provider creation and wait for async _load() to complete.
    container.read(notificationPrefsProvider);
    await Future.delayed(Duration.zero);

    final prefs = container.read(notificationPrefsProvider);
    expect(prefs.enabled, false);
    expect(prefs.reminderHour, 20);
    expect(prefs.reminderMinute, 45);
  });
}
