import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding/welcome',
    routes: [
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Welcome'))),
      ),
      GoRoute(
        path: '/today',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Today'))),
      ),
    ],
  );
});
