import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../onboarding_provider.dart';
import '../routine_generator.dart';
import '../../../theme.dart';

class RoutinePreviewScreen extends ConsumerWidget {
  const RoutinePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final routine = RoutineGenerator.generate(
      goals: state.selectedGoals.isEmpty ? ['Better sleep'] : state.selectedGoals,
      quizAnswers: state.quizAnswers.isEmpty
          ? {'chronotype': 'morning', 'structure': 'flexible', 'social': 'solo'}
          : state.quizAnswers,
    );

    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StepBar(current: 4, total: 6),
              const SizedBox(height: 24),
              Text('Your starter routine',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF3A2A1A),
                    fontSize: 26,
                  )),
              const SizedBox(height: 6),
              Text('Based on your goals — you can edit it anytime.',
                  style: TextStyle(color: Colors.brown.shade400)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: routine.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final step = routine[i];
                    final colorValue = int.tryParse(
                      step.color.replaceFirst('#', 'FF'),
                      radix: 16,
                    ) ?? 0xFFE8823A;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(colorValue),
                          child: const Icon(Icons.circle, color: Colors.white, size: 16),
                        ),
                        title: Text(step.title),
                        subtitle: Text(
                            '${step.hour.toString().padLeft(2, '0')}:${step.minute.toString().padLeft(2, '0')} · ${step.durationMinutes} min'),
                      ),
                    );
                  },
                ),
              ),
              FilledButton(
                onPressed: () => context.go('/onboarding/notifications'),
                child: const Text('Looks good! →'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  final int current, total;
  const _StepBar({required this.current, required this.total});
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
