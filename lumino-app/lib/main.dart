import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/me/theme_provider.dart';
import 'features/today/tasks_provider.dart';
import 'router.dart';
import 'services/api_client.dart';
import 'services/sync_service.dart';
import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: LuminoApp()));
}

class LuminoApp extends ConsumerWidget {
  const LuminoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);
    return SyncServiceInit(
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
  const SyncServiceInit({super.key, required this.child});
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
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
