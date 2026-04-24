import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumino_app/main.dart';

void main() {
  testWidgets('LuminoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LuminoApp()));
    // Drain microtasks from SyncService init and connectivity plugin timers
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
  });
}
