import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'habit_dao.g.dart';

@DriftAccessor(tables: [Habits, HabitEntries])
class HabitDao extends DatabaseAccessor<AppDatabase> with _$HabitDaoMixin {
  HabitDao(super.db);

  Future<void> insertHabit(HabitsCompanion habit) =>
      into(habits).insert(habit, mode: InsertMode.insertOrReplace);

  Future<List<Habit>> getActiveHabits(String userId) =>
      (select(habits)
            ..where((h) => h.userId.equals(userId) & h.archivedAt.isNull()))
          .get();

  Future<void> updateHabit(String habitId, HabitsCompanion companion) =>
      (update(habits)..where((h) => h.id.equals(habitId))).write(companion);

  Future<void> upsertEntry(HabitEntriesCompanion entry) =>
      into(habitEntries).insert(entry, mode: InsertMode.insertOrReplace);

  Future<void> deleteEntry(String habitId, DateTime date) =>
      (delete(habitEntries)
            ..where((e) => e.habitId.equals(habitId) & e.entryDate.equals(date)))
          .go();

  Future<List<HabitEntry>> getEntriesForDate(List<String> habitIds, DateTime date) =>
      (select(habitEntries)
            ..where((e) => e.habitId.isIn(habitIds) & e.entryDate.equals(date)))
          .get();

  Future<List<HabitEntry>> getEntries(
          String habitId, DateTime from, DateTime to) =>
      (select(habitEntries)
            ..where((e) =>
                e.habitId.equals(habitId) &
                e.entryDate.isBetweenValues(from, to))
            ..orderBy([(e) => OrderingTerm.asc(e.entryDate)]))
          .get();

  Future<List<HabitEntry>> getAllEntries(String habitId) =>
      (select(habitEntries)
            ..where((e) => e.habitId.equals(habitId))
            ..orderBy([(e) => OrderingTerm.desc(e.entryDate)]))
          .get();
}
