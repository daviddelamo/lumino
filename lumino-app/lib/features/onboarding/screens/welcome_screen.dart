import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Image.asset(
                'assets/images/welcome_hero.png',
                height: 240,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(height: 240),
              ),
              const SizedBox(height: 32),
              Text(
                'Lumino',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: LuminoTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'DAILY RHYTHM',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 4,
                      color: LuminoTheme.textSecondary(context),
                    ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/onboarding/goals'),
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.go('/today'),
                  child: Text(
                    'Skip for now',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: LuminoTheme.textSecondary(context)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
