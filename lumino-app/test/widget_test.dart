import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumino_app/features/me/theme_provider.dart';
import 'package:lumino_app/router.dart';
import 'package:lumino_app/theme.dart';

void main() {
  testWidgets('LuminoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: _TestApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends ConsumerWidget {
  const _TestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Lumino',
      theme: LuminoTheme.light(),
      darkTheme: LuminoTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
