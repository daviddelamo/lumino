import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lumino_app/database/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('can insert and retrieve a task', () async {
    await db.taskDao.insertTask(TasksCompanion.insert(
      userId: 'test-user',
      title: 'Morning run',
      iconId: const Value('run'),
      color: const Value('#E8823A'),
      startAt: DateTime.now(),
    ));
    final tasks = await db.taskDao.getTasksForDay('test-user', DateTime.now());
    expect(tasks, hasLength(1));
    expect(tasks.first.title, 'Morning run');
  });

  test('can insert and retrieve a habit', () async {
    await db.habitDao.insertHabit(HabitsCompanion.insert(
      userId: 'test-user',
      title: 'Drink water',
      iconId: const Value('water'),
      color: const Value('#5B6EF5'),
      type: 'count',
      targetValue: const Value(8.0),
      frequencyRule: '{"type":"daily"}',
    ));
    final habits = await db.habitDao.getActiveHabits('test-user');
    expect(habits, hasLength(1));
    expect(habits.first.title, 'Drink water');
  });

  test('can insert a mood entry and retrieve it by date range', () async {
    final now = DateTime(2026, 4, 24, 9, 0);
    await db.moodDao.insertEntry(MoodEntriesCompanion.insert(
      userId: 'test-user',
      moodLevel: 4,
      tags: const Value('["calm","focused"]'),
      loggedAt: now,
    ));
    final entries = await db.moodDao.getEntriesForDateRange(
      'test-user',
      DateTime(2026, 4, 24),
      DateTime(2026, 4, 24, 23, 59, 59),
    );
    expect(entries, hasLength(1));
    expect(entries.first.moodLevel, 4);
    expect(entries.first.tags, '["calm","focused"]');
  });

  test('getDirtyEntries returns only dirty rows for user', () async {
    await db.moodDao.insertEntry(MoodEntriesCompanion.insert(
      userId: 'test-user',
      moodLevel: 3,
      loggedAt: DateTime(2026, 4, 24),
    ));
    await db.moodDao.insertEntry(MoodEntriesCompanion.insert(
      userId: 'test-user',
      moodLevel: 2,
      loggedAt: DateTime(2026, 4, 24),
      dirty: const Value(false),
    ));
    final dirty = await db.moodDao.getDirtyEntries('test-user');
    expect(dirty, hasLength(1));
    expect(dirty.first.moodLevel, 3);
  });

  test('markSynced sets dirty to false', () async {
    await db.moodDao.insertEntry(MoodEntriesCompanion.insert(
      userId: 'test-user',
      moodLevel: 5,
      loggedAt: DateTime(2026, 4, 24),
    ));
    final before = await db.moodDao.getDirtyEntries('test-user');
    expect(before, hasLength(1));
    await db.moodDao.markSynced([before.first.id]);
    final after = await db.moodDao.getDirtyEntries('test-user');
    expect(after, isEmpty);
  });
}
