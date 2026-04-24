import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/onboarding/screens/goals_screen.dart';
import 'features/onboarding/screens/quiz_screen.dart';
import 'features/onboarding/screens/routine_preview_screen.dart';
import 'features/onboarding/screens/notifications_screen.dart';
import 'features/onboarding/screens/signup_screen.dart';
import 'features/today/screens/today_screen.dart';
import 'features/today/screens/week_view_screen.dart';
import 'features/habits/screens/habits_screen.dart';
import 'features/habits/screens/habit_form_screen.dart';
import 'features/habits/screens/habit_detail_screen.dart';
import 'features/me/screens/me_screen.dart';
import 'features/me/screens/notification_settings_screen.dart';
import 'features/widget_config/widget_config_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding/welcome', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/onboarding/goals', builder: (c, s) => const GoalsScreen()),
      GoRoute(path: '/onboarding/quiz', builder: (c, s) => const QuizScreen()),
      GoRoute(path: '/onboarding/preview', builder: (c, s) => const RoutinePreviewScreen()),
      GoRoute(path: '/onboarding/notifications', builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: '/onboarding/signup', builder: (c, s) => const SignupScreen()),
      GoRoute(path: '/today', builder: (c, s) => const TodayScreen()),
      GoRoute(path: '/today/week', builder: (c, s) => const WeekViewScreen()),
      GoRoute(path: '/habits', builder: (c, s) => const HabitsScreen()),
      GoRoute(path: '/habits/add', builder: (c, s) => const HabitFormScreen()),
      GoRoute(path: '/habits/:id', builder: (c, s) => HabitDetailScreen(habitId: s.pathParameters['id']!)),
      GoRoute(path: '/me', builder: (c, s) => const MeScreen()),
      GoRoute(path: '/me/notifications', builder: (c, s) => const NotificationSettingsScreen()),
      GoRoute(path: '/widget-config', builder: (c, s) => const WidgetConfigScreen()),
    ],
  );
});
