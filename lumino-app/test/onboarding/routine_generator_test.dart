import 'package:flutter_test/flutter_test.dart';
import 'package:lumino_app/features/onboarding/routine_generator.dart';

void main() {
  test('morning person gets early morning tasks', () {
    final routine = RoutineGenerator.generate(
      goals: ['Exercise', 'Mindfulness'],
      quizAnswers: {'chronotype': 'morning', 'structure': 'rigid', 'social': 'solo'},
    );
    expect(routine, isNotEmpty);
    expect(routine.any((s) => s.hour <= 8), isTrue);
  });

  test('night person gets later tasks', () {
    final routine = RoutineGenerator.generate(
      goals: ['Study', 'Journaling'],
      quizAnswers: {'chronotype': 'night', 'structure': 'flexible', 'social': 'solo'},
    );
    expect(routine.first.hour, greaterThan(8));
  });

  test('generates at least 3 tasks', () {
    final routine = RoutineGenerator.generate(
      goals: ['Better sleep'],
      quizAnswers: {'chronotype': 'morning', 'structure': 'rigid', 'social': 'solo'},
    );
    expect(routine.length, greaterThanOrEqualTo(3));
  });
}
