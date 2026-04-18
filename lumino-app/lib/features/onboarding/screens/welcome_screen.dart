import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text('Lumino',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: LuminoTheme.primaryColor,
                    fontSize: 48,
                  )),
              const SizedBox(height: 8),
              Text('Daily Rhythm',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.brown.shade400,
                    letterSpacing: 3,
                  )),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/onboarding/goals'),
                child: const Text('Get Started →'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/today'),
                child: Text('Skip for now',
                    style: TextStyle(color: Colors.brown.shade300)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
