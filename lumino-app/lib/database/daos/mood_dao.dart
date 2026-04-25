import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'mood_dao.g.dart';

@DriftAccessor(tables: [MoodEntries])
class MoodDao extends DatabaseAccessor<AppDatabase> with _$MoodDaoMixin {
  MoodDao(super.db);

  Future<int> insertEntry(MoodEntriesCompanion entry) =>
      into(moodEntries).insert(entry);

  Future<List<MoodEntry>> getEntriesForDateRange(
    String userId,
    DateTime from,
    DateTime to,
  ) =>
      (select(moodEntries)
            ..where((e) =>
                e.userId.equals(userId) &
                e.loggedAt.isBetweenValues(from, to))
            ..orderBy([(e) => OrderingTerm.asc(e.loggedAt)]))
          .get();

  // Filters by userId unlike TaskDao.getDirtyTasks — mood sync is user-scoped at the service layer.
  Future<List<MoodEntry>> getDirtyEntries(String userId) =>
      (select(moodEntries)
            ..where((e) => e.userId.equals(userId) & e.dirty.equals(true)))
          .get();

  Future<void> markSynced(List<int> ids) =>
      (update(moodEntries)..where((e) => e.id.isIn(ids)))
          .write(const MoodEntriesCompanion(dirty: Value(false)));
}
