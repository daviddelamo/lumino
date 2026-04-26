import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumino_app/database/database.dart';
import 'package:lumino_app/features/stats/stats_provider.dart';
import 'package:lumino_app/features/today/tasks_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  final period = (from: DateTime(2024, 6, 1), to: DateTime(2024, 6, 30));

  group('statsProvider', () {
    test('empty database returns all-zero stats', () async {
      final stats = await container.read(statsProvider(period).future);
      expect(stats.tasksTotal, 0);
      expect(stats.tasksCompleted, 0);
      expect(stats.habitCompletionRate, 0.0);
      expect(stats.avgMood, 0.0);
      expect(stats.bestStreak, 0);
    });

    test('counts completed vs total tasks', () async {
      await db.taskDao.insertTask(TasksCompanion(
        userId: const Value('u1'),
        title: const Value('Done'),
        startAt: Value(DateTime(2024, 6, 15)),
        completedAt: Value(DateTime(2024, 6, 15, 12)),
      ));
      await db.taskDao.insertTask(TasksCompanion(
        userId: const Value('u1'),
        title: const Value('Pending'),
        startAt: Value(DateTime(2024, 6, 16)),
      ));

      final stats = await container.read(statsProvider(period).future);
      expect(stats.tasksTotal, 2);
      expect(stats.tasksCompleted, 1);
    });

    test('computes average mood from entries in range', () async {
      await db.moodDao.insertEntry(MoodEntriesCompanion(
        userId: const Value('u1'),
        moodLevel: const Value(4),
        loggedAt: Value(DateTime(2024, 6, 10)),
      ));
      await db.moodDao.insertEntry(MoodEntriesCompanion(
        userId: const Value('u1'),
        moodLevel: const Value(2),
        loggedAt: Value(DateTime(2024, 6, 20)),
      ));

      final stats = await container.read(statsProvider(period).future);
      expect(stats.avgMood, 3.0);
    });

    test('ignores mood entries outside range', () async {
      await db.moodDao.insertEntry(MoodEntriesCompanion(
        userId: const Value('u1'),
        moodLevel: const Value(5),
        loggedAt: Value(DateTime(2024, 5, 31)), // before range
      ));

      final stats = await container.read(statsProvider(period).future);
      expect(stats.avgMood, 0.0);
    });
  });

  group('dailyStatsProvider', () {
    test('returns one DailyPoint per day in range', () async {
      final points = await container.read(dailyStatsProvider(period).future);
      expect(points.length, 30); // June has 30 days
    });

    test('mood is 0 for days with no entry', () async {
      final points = await container.read(dailyStatsProvider(period).future);
      expect(points.every((p) => p.mood == 0.0), isTrue);
    });
  });

  group('habitBreakdownProvider', () {
    test('returns empty list when no habits', () async {
      final items =
          await container.read(habitBreakdownProvider(period).future);
      expect(items, isEmpty);
    });
  });

  group('dailyStatsProvider with data', () {
    test('includes mood on days with entries', () async {
      await db.moodDao.insertEntry(MoodEntriesCompanion(
        userId: const Value('u1'),
        moodLevel: const Value(4),
        loggedAt: Value(DateTime(2024, 6, 15)),
      ));
      final points =
          await container.read(dailyStatsProvider(period).future);
      final june15 = points.firstWhere(
          (p) => p.date == DateTime(2024, 6, 15));
      expect(june15.mood, 4.0);
    });

    test('averages multiple mood entries on same day', () async {
      await db.moodDao.insertEntry(MoodEntriesCompanion(
        userId: const Value('u1'),
        moodLevel: const Value(2),
        loggedAt: Value(DateTime(2024, 6, 10, 9)),
      ));
      await db.moodDao.insertEntry(MoodEntriesCompanion(
        userId: const Value('u1'),
        moodLevel: const Value(4),
        loggedAt: Value(DateTime(2024, 6, 10, 20)),
      ));
      final points =
          await container.read(dailyStatsProvider(period).future);
      final june10 = points.firstWhere(
          (p) => p.date == DateTime(2024, 6, 10));
      expect(june10.mood, 3.0);
    });
  });
}
