import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';

final _authProvider = Provider<AuthService>((ref) => AuthService(ApiClient()));

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    final results = await Future.wait([
      ref.read(_authProvider).isLoggedIn(),
      Future.delayed(const Duration(milliseconds: 1600)),
    ]);
    if (!mounted) return;
    final isLoggedIn = results[0] as bool;
    context.go(isLoggedIn ? '/today' : '/onboarding/welcome');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [
              Color(0xFFF7C59F), // peach centre
              LuminoTheme.backgroundWarm, // warm white edges
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo image — replace Icon with Image.asset once asset is ready:
                // Image.asset('assets/images/welcome_hero.png', width: 120)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFF7C59F), LuminoTheme.primaryColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: LuminoTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.wb_sunny_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  'Lumino',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: LuminoTheme.primaryColor,
                        fontSize: 42,
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Daily Rhythm',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFA08070),
                        letterSpacing: 3,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
