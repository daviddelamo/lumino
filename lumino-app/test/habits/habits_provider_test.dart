import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumino_app/database/database.dart';
import 'package:lumino_app/features/habits/habits_provider.dart';
import 'package:lumino_app/features/today/tasks_provider.dart';

void main() {
  test('habitsProvider returns active habits', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.habitDao.insertHabit(HabitsCompanion.insert(
      userId: 'u1',
      title: 'Drink water',
      iconId: const Value('water'),
      color: const Value('#5B6EF5'),
      type: 'count',
      targetValue: const Value(8.0),
      frequencyRule: '{"type":"daily"}',
    ));
    final container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
    addTearDown(container.dispose);
    final habits = await container.read(habitsProvider.future);
    expect(habits, hasLength(1));
    await db.close();
  });

  test('addHabit returns false when at 5 habits and not premium', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    for (var i = 1; i <= 5; i++) {
      await db.habitDao.insertHabit(HabitsCompanion.insert(
        userId: 'u1',
        title: 'Habit $i',
        type: 'bool',
        frequencyRule: '{"type":"daily"}',
      ));
    }
    final container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
    addTearDown(container.dispose);
    while (container.read(habitsNotifierProvider) is AsyncLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    final added = await container.read(habitsNotifierProvider.notifier).addHabit(
          isPremium: false,
          title: 'Sixth',
          iconId: 'circle',
          color: '#E8823A',
          type: 'bool',
          targetValue: 1,
          frequencyRule: '{"type":"daily"}',
        );
    expect(added, isFalse);
    await db.close();
  });

  test('addHabit returns true when at 5 habits and is premium', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    for (var i = 1; i <= 5; i++) {
      await db.habitDao.insertHabit(HabitsCompanion.insert(
        userId: 'u1',
        title: 'Habit $i',
        type: 'bool',
        frequencyRule: '{"type":"daily"}',
      ));
    }
    final container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
    addTearDown(container.dispose);
    while (container.read(habitsNotifierProvider) is AsyncLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    final added = await container.read(habitsNotifierProvider.notifier).addHabit(
          isPremium: true,
          title: 'Sixth',
          iconId: 'circle',
          color: '#E8823A',
          type: 'bool',
          targetValue: 1,
          frequencyRule: '{"type":"daily"}',
        );
    expect(added, isTrue);
    await db.close();
  });
}
