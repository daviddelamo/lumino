import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../services/auth_state.dart';
import '../../../services/api_client.dart';
import '../../../theme.dart';

final _authServiceProvider = Provider<AuthService>((ref) => AuthService(ApiClient()));

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAuth(Future<void> Function() action) async {
    setState(() { _loading = true; _error = null; });
    final router = GoRouter.of(context);
    try {
      await action();
      await ref.read(authProvider.notifier).onSignedIn();
      if (mounted) router.go('/today');
    } on AuthCancelledException {
      if (mounted) setState(() => _loading = false);
    } on DioException catch (e) {
      final msg = e.message?.isNotEmpty == true ? e.message! : 'Network error — check your connection';
      if (mounted) setState(() { _error = msg; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(_authServiceProvider);
    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _StepBarFull(current: 6, total: 6),
              const SizedBox(height: 24),
              Text('Save your progress',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF3A2A1A), fontSize: 26,
                  )),
              const SizedBox(height: 4),
              Text('Create an account to sync across devices.',
                  style: TextStyle(color: Colors.brown.shade400)),
              const SizedBox(height: 28),

              // ── Social buttons ──────────────────────────────────────────────
              _SocialButton(
                onPressed: _loading ? null : () => _handleAuth(auth.signInWithGoogle),
                icon: _GoogleIcon(),
                label: 'Continue with Google',
              ),
              const SizedBox(height: 12),
              _SocialButton(
                onPressed: _loading ? null : () => _handleAuth(auth.signInWithFacebook),
                icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 22),
                label: 'Continue with Facebook',
              ),

              // ── Divider ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: TextStyle(color: Colors.brown.shade300, fontSize: 13)),
                  ),
                  const Expanded(child: Divider()),
                ]),
              ),

              // ── Email / Password ────────────────────────────────────────────
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : () => _handleAuth(
                  () => auth.register(_emailCtrl.text.trim(), _passwordCtrl.text),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create account'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading ? null : () => _handleAuth(
                  () => auth.login(_emailCtrl.text.trim(), _passwordCtrl.text),
                ),
                child: Text('Sign in to existing account',
                    style: TextStyle(color: Colors.brown.shade400)),
              ),

              // ── Skip ────────────────────────────────────────────────────────
              const SizedBox(height: 4),
              TextButton(
                onPressed: _loading ? null : () => context.go('/today'),
                child: Text('Skip — use without account',
                    style: TextStyle(color: Colors.brown.shade300, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3A2A1A),
        side: const BorderSide(color: Color(0xFFE0C8B0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// Painted Google G — no asset required
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    final sweeps = [
      (Colors.red.shade600, -10.0 * 3.14159 / 180, 100.0 * 3.14159 / 180),
      (Colors.amber.shade400, 90.0 * 3.14159 / 180, 100.0 * 3.14159 / 180),
      (Colors.green.shade500, 190.0 * 3.14159 / 180, 90.0 * 3.14159 / 180),
      (Colors.blue.shade600, 280.0 * 3.14159 / 180, 80.0 * 3.14159 / 180),
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    for (final (color, start, sweep) in sweeps) {
      paint.color = color;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: r * 0.72), start, sweep, false, paint);
    }

    // horizontal bar of the G
    paint
      ..color = Colors.blue.shade600
      ..strokeWidth = size.width * 0.18;
    canvas.drawLine(
      Offset(r * 0.72, r),
      Offset(r * 1.72, r),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StepBarFull extends StatelessWidget {
  final int current, total;
  const _StepBarFull({required this.current, required this.total});
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(total, (i) => Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: LuminoTheme.primaryColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    )),
  );
}
