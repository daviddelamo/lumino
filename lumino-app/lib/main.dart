import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: LuminoApp()));
}

class LuminoApp extends StatelessWidget {
  const LuminoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lumino',
      theme: LuminoTheme.light(),
      darkTheme: LuminoTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
