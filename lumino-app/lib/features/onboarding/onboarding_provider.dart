import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final List<String> selectedGoals;
  final Map<String, String> quizAnswers;

  const OnboardingState({this.selectedGoals = const [], this.quizAnswers = const {}});

  OnboardingState copyWith({List<String>? selectedGoals, Map<String, String>? quizAnswers}) =>
      OnboardingState(
        selectedGoals: selectedGoals ?? this.selectedGoals,
        quizAnswers: quizAnswers ?? this.quizAnswers,
      );
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void toggleGoal(String goal) {
    final goals = List<String>.from(state.selectedGoals);
    goals.contains(goal) ? goals.remove(goal) : goals.add(goal);
    state = state.copyWith(selectedGoals: goals);
  }

  void setQuizAnswer(String question, String answer) {
    final answers = Map<String, String>.from(state.quizAnswers);
    answers[question] = answer;
    state = state.copyWith(quizAnswers: answers);
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);
