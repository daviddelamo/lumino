import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../onboarding_provider.dart';
import '../../../theme.dart';

const _goals = [
  ('🌙', 'Better sleep'),
  ('🏃', 'Exercise'),
  ('🧘', 'Mindfulness'),
  ('📚', 'Study'),
  ('💼', 'Work focus'),
  ('💆', 'Self-care'),
  ('🥗', 'Nutrition'),
  ('✍️', 'Journaling'),
  ('💧', 'Hydration'),
];

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).selectedGoals;
    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StepIndicator(current: 2, total: 6),
              const SizedBox(height: 16),
              Center(
                child: Image.asset(
                  'assets/images/onboarding_goals.png',
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 160),
                ),
              ),
              const SizedBox(height: 16),
              Text('What do you want\nto work on?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF3A2A1A),
                    fontSize: 26,
                  )),
              const SizedBox(height: 8),
              Text('Pick as many as you like',
                  style: TextStyle(color: Colors.brown.shade400)),
              const SizedBox(height: 24),
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _goals.map((g) {
                    final isSelected = selected.contains(g.$2);
                    return FilterChip(
                      label: Text('${g.$1} ${g.$2}'),
                      selected: isSelected,
                      onSelected: (_) =>
                          ref.read(onboardingProvider.notifier).toggleGoal(g.$2),
                      selectedColor: LuminoTheme.primaryColor,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.brown.shade700),
                      side: const BorderSide(color: LuminoTheme.accentColor),
                    );
                  }).toList(),
                ),
              ),
              FilledButton(
                onPressed: selected.isEmpty ? null : () => context.go('/onboarding/quiz'),
                child: const Text('Continue →'),
              ),
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
