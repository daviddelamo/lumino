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
}
