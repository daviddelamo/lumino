class RoutineStep {
  final String title;
  final String iconId;
  final String color;
  final int hour;
  final int minute;
  final int durationMinutes;

  const RoutineStep({
    required this.title,
    required this.iconId,
    required this.color,
    required this.hour,
    required this.minute,
    required this.durationMinutes,
  });
}

class RoutineGenerator {
  static List<RoutineStep> generate({
    required List<String> goals,
    required Map<String, String> quizAnswers,
  }) {
    final isMorning = quizAnswers['chronotype'] == 'morning';
    final startHour = isMorning ? 6 : 9;
    final steps = <RoutineStep>[];

    steps.add(RoutineStep(
      title: isMorning ? 'Wake up & stretch' : 'Start your day',
      iconId: 'sun',
      color: '#E8823A',
      hour: startHour,
      minute: 0,
      durationMinutes: 10,
    ));

    if (goals.contains('Mindfulness') || goals.contains('Better sleep')) {
      steps.add(RoutineStep(
        title: 'Morning meditation',
        iconId: 'yoga',
        color: '#9B72D0',
        hour: startHour,
        minute: 15,
        durationMinutes: 10,
      ));
    }

    if (goals.contains('Exercise')) {
      steps.add(RoutineStep(
        title: 'Workout',
        iconId: 'run',
        color: '#4CAF82',
        hour: startHour + 1,
        minute: 0,
        durationMinutes: 30,
      ));
    }

    if (goals.contains('Hydration') || goals.contains('Nutrition')) {
      steps.add(RoutineStep(
        title: 'Healthy breakfast',
        iconId: 'food',
        color: '#F9C06A',
        hour: startHour + (goals.contains('Exercise') ? 2 : 1),
        minute: 0,
        durationMinutes: 20,
      ));
    }

    if (goals.contains('Study') || goals.contains('Work focus')) {
      steps.add(RoutineStep(
        title: 'Focus block',
        iconId: 'brain',
        color: '#5B6EF5',
        hour: startHour + 3,
        minute: 0,
        durationMinutes: 90,
      ));
    }

    if (goals.contains('Journaling')) {
      steps.add(const RoutineStep(
        title: 'Evening journal',
        iconId: 'pencil',
        color: '#E8823A',
        hour: 21,
        minute: 0,
        durationMinutes: 15,
      ));
    }

    if (goals.contains('Better sleep')) {
      steps.add(const RoutineStep(
        title: 'Wind down',
        iconId: 'moon',
        color: '#9B72D0',
        hour: 22,
        minute: 0,
        durationMinutes: 20,
      ));
    }

    if (steps.length < 3) {
      steps.add(RoutineStep(
        title: 'Drink water',
        iconId: 'water',
        color: '#5B6EF5',
        hour: startHour + 1,
        minute: 30,
        durationMinutes: 5,
      ));
    }

    return steps..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
  }
}
