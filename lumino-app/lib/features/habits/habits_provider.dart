import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../today/tasks_provider.dart';

final habitsProvider = FutureProvider<List<Habit>>((ref) async {
  final db = ref.watch(dbProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'local';
  return db.habitDao.getActiveHabits(userId);
});

class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final AppDatabase _db;
  final String _userId;

  HabitsNotifier(this._db, this._userId) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = await AsyncValue.guard(() => _db.habitDao.getActiveHabits(_userId));
  }

  Future<void> addHabit({
    required String title,
    required String iconId,
    required String color,
    required String type,
    required double targetValue,
    String? unit,
    required String frequencyRule,
  }) async {
    if (state.value != null && state.value!.length >= 5) {
      throw Exception('Free tier allows up to 5 habits');
    }
    await _db.habitDao.insertHabit(HabitsCompanion.insert(
      userId: _userId,
      title: title,
      iconId: Value(iconId),
      color: Value(color),
      type: type,
      targetValue: Value(targetValue),
      frequencyRule: frequencyRule,
      unit: Value(unit),
    ));
    await _load();
  }

  Future<void> completeToday(String habitId, double value) async {
    final today = DateTime.now();
    final entryDate = DateTime(today.year, today.month, today.day);
    await _db.habitDao.upsertEntry(HabitEntriesCompanion.insert(
      habitId: habitId,
      entryDate: entryDate,
      value: Value(value),
    ));
    await _load();
  }

  Future<void> reload() => _load();
}

final habitsNotifierProvider =
    StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>(
  (ref) {
    final db = ref.watch(dbProvider);
    final userId = ref.watch(currentUserIdProvider) ?? 'local';
    return HabitsNotifier(db, userId);
  },
);

int computeStreak(List<DateTime> entryDates) {
  if (entryDates.isEmpty) return 0;
  final sorted = entryDates
      .map((d) => DateTime(d.year, d.month, d.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));
  int streak = 1;
  for (int i = 1; i < sorted.length; i++) {
    final diff = sorted[i - 1].difference(sorted[i]).inDays;
    if (diff == 1) {
      streak++;
    } else {
      break;
    }
  }
  final today = DateTime.now();
  final todayNorm = DateTime(today.year, today.month, today.day);
  final latestEntry = sorted.first;
  if (latestEntry.isBefore(todayNorm.subtract(const Duration(days: 1)))) return 0;
  return streak;
}

int longestStreak(List<DateTime> entryDates) {
  if (entryDates.isEmpty) return 0;
  final sorted = entryDates
      .map((d) => DateTime(d.year, d.month, d.day))
      .toSet()
      .toList()
    ..sort();
  int longest = 1, current = 1;
  for (int i = 1; i < sorted.length; i++) {
    if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 1;
    }
  }
  return longest;
}
