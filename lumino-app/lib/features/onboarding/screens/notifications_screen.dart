import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/notification_service.dart';
import '../../../theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔔', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text('Stay on track',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF3A2A1A),
                    fontSize: 26,
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text("We'll remind you before each task — only when you want.",
                  style: TextStyle(color: Colors.brown.shade400),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () async {
                  await NotificationService.requestPermission();
                  if (context.mounted) context.go('/onboarding/signup');
                },
                child: const Text('Enable reminders'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/onboarding/signup'),
                child: Text('Not now', style: TextStyle(color: Colors.brown.shade300)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
