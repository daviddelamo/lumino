import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../habits/habits_provider.dart' show longestStreak;
import '../today/tasks_provider.dart';

typedef StatsPeriod = ({DateTime from, DateTime to});

class StatsData {
  final int tasksCompleted;
  final int tasksTotal;
  final double habitCompletionRate;
  final double avgMood;
  final int bestStreak;
  final String? bestStreakHabit;

  const StatsData({
    required this.tasksCompleted,
    required this.tasksTotal,
    required this.habitCompletionRate,
    required this.avgMood,
    required this.bestStreak,
    this.bestStreakHabit,
  });
}

class DailyPoint {
  final DateTime date;
  final double habitRate;
  final double mood;

  const DailyPoint(
      {required this.date, required this.habitRate, required this.mood});
}

final statsProvider =
    FutureProvider.family<StatsData, StatsPeriod>((ref, period) async {
  final db = ref.watch(dbProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'local';
  final from = DateTime(period.from.year, period.from.month, period.from.day);
  final to = DateTime(period.to.year, period.to.month, period.to.day);

  final tasks =
      await db.taskDao.getTasksForDateRange(userId, from, to);
  final tasksCompleted = tasks.where((t) => t.completedAt != null).length;

  final habits = await db.habitDao.getActiveHabits(userId);
  double habitRate = 0;
  int bestStreak = 0;
  String? bestStreakHabit;

  if (habits.isNotEmpty) {
    int totalExpected = 0;
    int totalCompleted = 0;

    for (final habit in habits) {
      final entries =
          await db.habitDao.getEntries(habit.id, from, to);
      final days = to.difference(from).inDays + 1;
      totalExpected += days;
      totalCompleted += entries.length;

      final allEntries = await db.habitDao.getAllEntries(habit.id);
      final dates = allEntries.map((e) => e.entryDate).toList()..sort();
      final streak = longestStreak(dates);
      if (streak > bestStreak) {
        bestStreak = streak;
        bestStreakHabit = habit.title;
      }
    }

    habitRate =
        (totalExpected > 0 ? totalCompleted / totalExpected : 0.0).clamp(0.0, 1.0);
  }

  final moodEntries =
      await db.moodDao.getEntriesForDateRange(userId, from, to);
  final avgMood = moodEntries.isEmpty
      ? 0.0
      : moodEntries.map((e) => e.moodLevel).reduce((a, b) => a + b) /
          moodEntries.length;

  return StatsData(
    tasksCompleted: tasksCompleted,
    tasksTotal: tasks.length,
    habitCompletionRate: habitRate,
    avgMood: avgMood,
    bestStreak: bestStreak,
    bestStreakHabit: bestStreakHabit,
  );
});

final dailyStatsProvider =
    FutureProvider.family<List<DailyPoint>, StatsPeriod>((ref, period) async {
  final db = ref.watch(dbProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'local';
  final from = DateTime(period.from.year, period.from.month, period.from.day);
  final to = DateTime(period.to.year, period.to.month, period.to.day);

  final habits = await db.habitDao.getActiveHabits(userId);
  final moodEntries =
      await db.moodDao.getEntriesForDateRange(userId, from, to);

  final moodByDay = <DateTime, List<int>>{};
  for (final e in moodEntries) {
    final day =
        DateTime(e.loggedAt.year, e.loggedAt.month, e.loggedAt.day);
    moodByDay.putIfAbsent(day, () => []).add(e.moodLevel);
  }

  final habitsByDay = <DateTime, int>{};
  for (final habit in habits) {
    final entries =
        await db.habitDao.getEntries(habit.id, from, to);
    for (final e in entries) {
      final day = DateTime(
          e.entryDate.year, e.entryDate.month, e.entryDate.day);
      habitsByDay[day] = (habitsByDay[day] ?? 0) + 1;
    }
  }

  final days = to.difference(from).inDays + 1;
  return List.generate(days, (i) {
    final day = from.add(Duration(days: i));
    final norm = DateTime(day.year, day.month, day.day);

    final completedCount = habitsByDay[norm] ?? 0;
    final habitRate =
        habits.isEmpty ? 0.0 : (completedCount / habits.length).clamp(0.0, 1.0);

    final moods = moodByDay[norm] ?? [];
    final mood = moods.isEmpty
        ? 0.0
        : moods.reduce((a, b) => a + b) / moods.length;

    return DailyPoint(date: norm, habitRate: habitRate, mood: mood);
  });
});

final habitBreakdownProvider =
    FutureProvider.family<List<(String, double)>, StatsPeriod>(
        (ref, period) async {
  final db = ref.watch(dbProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'local';
  final from = DateTime(period.from.year, period.from.month, period.from.day);
  final to = DateTime(period.to.year, period.to.month, period.to.day);
  final habits = await db.habitDao.getActiveHabits(userId);
  if (habits.isEmpty) return [];

  final days = to.difference(from).inDays + 1;
  if (days <= 0) return [];

  final result = <(String, double)>[];
  for (final h in habits) {
    final entries =
        await db.habitDao.getEntries(h.id, from, to);
    result.add((h.title, (entries.length / days).clamp(0.0, 1.0)));
  }
  result.sort((a, b) => b.$2.compareTo(a.$2));
  return result;
});
