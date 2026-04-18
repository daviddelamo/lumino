import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../onboarding_provider.dart';
import '../../../theme.dart';

const _questions = [
  ('chronotype', 'Are you a morning or night person?', ['Morning 🌅', 'Night 🌙'], ['morning', 'night']),
  ('structure', 'Do you prefer structured or flexible routines?', ['Structured 📋', 'Flexible 🌊'], ['rigid', 'flexible']),
  ('social', 'Do you prefer solo or social habits?', ['Solo 🧘', 'Social 👥'], ['solo', 'social']),
];

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});
  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestion = 0;

  void _answer(String key, String value) {
    ref.read(onboardingProvider.notifier).setQuizAnswer(key, value);
    if (_currentQuestion < _questions.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      context.go('/onboarding/preview');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (key, question, labels, values) = _questions[_currentQuestion];
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StepIndicator(current: 3, total: 6),
              const Spacer(),
              Text(question,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF3A2A1A),
                    fontSize: 24,
                  )),
              const SizedBox(height: 32),
              ...List.generate(labels.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: LuminoTheme.backgroundWarm,
                    foregroundColor: const Color(0xFF3A2A1A),
                    side: const BorderSide(color: LuminoTheme.accentColor),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  onPressed: () => _answer(key, values[i]),
                  child: Text(labels[i], style: const TextStyle(fontSize: 16)),
                ),
              )),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current, total;
  const _StepIndicator({required this.current, required this.total});
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(total, (i) => Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: i < current ? LuminoTheme.primaryColor : LuminoTheme.accentColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    )),
  );
}
