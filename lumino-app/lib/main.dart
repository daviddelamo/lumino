import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database.dart';
import 'features/me/theme_provider.dart';
import 'features/today/tasks_provider.dart';
import 'router.dart';
import 'services/api_client.dart';
import 'services/sync_service.dart';
import 'services/widget_update_service.dart';
import 'theme.dart';
import 'package:audio_service/audio_service.dart';
import 'services/audio_handler.dart';

/// Called in a background isolate when a widget action fires (e.g. habit complete).
@pragma('vm:entry-point')
Future<void> onWidgetAction(Uri? uri) async {
  if (uri == null) return;
  final type = uri.queryParameters['type'];
  final id   = uri.queryParameters['id'];
  if (type != 'complete_habit' || id == null) return;

  WidgetsFlutterBinding.ensureInitialized();
  final prefs  = await SharedPreferences.getInstance();
  final userId = prefs.getString('lumino_widget_user_id') ?? 'local';

  final db    = AppDatabase();
  final today = DateTime.now();
  final day   = DateTime(today.year, today.month, today.day);
  await db.habitDao.upsertEntry(
    HabitEntriesCompanion.insert(
      habitId:   id,
      entryDate: day,
    ),
  );

  final widgetService = WidgetUpdateService(db);
  await widgetService.refresh(
    type:   'habits',
    count:  prefs.getInt('lumino_widget_count') ?? 5,
    userId: userId,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(onWidgetAction);
  final handler = await AudioService.init(
    builder: () => LuminoAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.lumino.lumino_app.audio',
      androidNotificationChannelName: 'Lumino Audio',
      androidNotificationOngoing: true,
    ),
  );
  runApp(ProviderScope(
    overrides: [audioHandlerProvider.overrideWithValue(handler)],
    child: const LuminoApp(),
  ));
}

class LuminoApp extends ConsumerWidget {
  const LuminoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);
    return SyncServiceInit(
      router: router,
      child: MaterialApp.router(
        title: 'Lumino',
        theme: LuminoTheme.light(),
        darkTheme: LuminoTheme.dark(),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        routerConfig: router,
      ),
    );
  }
}

class SyncServiceInit extends ConsumerStatefulWidget {
  final Widget child;
  final GoRouter router;
  const SyncServiceInit({super.key, required this.child, required this.router});

  @override
  ConsumerState<SyncServiceInit> createState() => _SyncServiceInitState();
}

class _SyncServiceInitState extends ConsumerState<SyncServiceInit> {
  late final SyncService _syncService;

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    _syncService = SyncService(db, ApiClient());
    Future.microtask(() => _syncService.sync());
    HomeWidget.widgetClicked.listen(_handleWidgetClick);
    _scheduleMidnightAlarm();
    _persistWidgetUserId(ref.read(currentUserIdProvider));
    ref.listenManual(currentUserIdProvider, (_, userId) => _persistWidgetUserId(userId));
  }

  void _persistWidgetUserId(String? userId) {
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('lumino_widget_user_id', userId ?? 'local'),
    );
  }

  Future<void> _scheduleMidnightAlarm() async {
    try {
      const channel = MethodChannel('com.lumino.lumino_app/widget');
      await channel.invokeMethod<void>('scheduleMidnightAlarm');
    } catch (_) {
      // Non-Android platforms or channel not available
    }
  }

  void _handleWidgetClick(Uri? uri) {
    if (uri == null) return;
    final type = uri.queryParameters['type'];
    final id   = uri.queryParameters['id'];
    if (type == 'task' && id != null) {
      widget.router.go('/today');
    } else if (type == 'habit' && id != null) {
      widget.router.go('/habits/$id');
    }
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
