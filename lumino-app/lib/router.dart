import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/onboarding/screens/goals_screen.dart';
import 'features/onboarding/screens/quiz_screen.dart';
import 'features/onboarding/screens/routine_preview_screen.dart';
import 'features/onboarding/screens/notifications_screen.dart';
import 'features/onboarding/screens/signup_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding/welcome',
    routes: [
      GoRoute(path: '/onboarding/welcome', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/onboarding/goals', builder: (c, s) => const GoalsScreen()),
      GoRoute(path: '/onboarding/quiz', builder: (c, s) => const QuizScreen()),
      GoRoute(path: '/onboarding/preview', builder: (c, s) => const RoutinePreviewScreen()),
      GoRoute(path: '/onboarding/notifications', builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: '/onboarding/signup', builder: (c, s) => const SignupScreen()),
      GoRoute(path: '/today', builder: (c, s) => const Scaffold(body: Center(child: Text('Today')))),
    ],
  );
});
