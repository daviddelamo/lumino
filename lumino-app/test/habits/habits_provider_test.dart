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
}
