import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumino_app/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('getTasksForDateRange returns only tasks whose startAt falls in range',
      () async {
    await db.taskDao.insertTask(TasksCompanion(
      userId: const Value('u1'),
      title: const Value('In range'),
      startAt: Value(DateTime(2024, 6, 15)),
    ));
    await db.taskDao.insertTask(TasksCompanion(
      userId: const Value('u1'),
      title: const Value('Too early'),
      startAt: Value(DateTime(2024, 6, 1)),
    ));
    await db.taskDao.insertTask(TasksCompanion(
      userId: const Value('u1'),
      title: const Value('Too late'),
      startAt: Value(DateTime(2024, 6, 30)),
    ));

    final result = await db.taskDao.getTasksForDateRange(
        'u1', DateTime(2024, 6, 10), DateTime(2024, 6, 20));
    expect(result.length, 1);
    expect(result.first.title, 'In range');
  });

  test('getTasksForDateRange excludes soft-deleted tasks', () async {
    final id = await db.taskDao.insertTask(TasksCompanion(
      userId: const Value('u1'),
      title: const Value('Deleted'),
      startAt: Value(DateTime(2024, 6, 15)),
    ));
    await db.taskDao.softDelete(id);

    final result = await db.taskDao.getTasksForDateRange(
        'u1', DateTime(2024, 6, 10), DateTime(2024, 6, 20));
    expect(result, isEmpty);
  });

  test('getTasksForDateRange includes tasks on the start day', () async {
    await db.taskDao.insertTask(TasksCompanion(
      userId: const Value('u1'),
      title: const Value('Start day'),
      startAt: Value(DateTime(2024, 6, 10)),
    ));
    final result = await db.taskDao
        .getTasksForDateRange('u1', DateTime(2024, 6, 10), DateTime(2024, 6, 20));
    expect(result.length, 1);
  });

  test('getTasksForDateRange includes tasks on the end day', () async {
    await db.taskDao.insertTask(TasksCompanion(
      userId: const Value('u1'),
      title: const Value('End day'),
      startAt: Value(DateTime(2024, 6, 20, 23, 30)),
    ));
    final result = await db.taskDao
        .getTasksForDateRange('u1', DateTime(2024, 6, 10), DateTime(2024, 6, 20));
    expect(result.length, 1);
  });

  test('getTasksForDateRange excludes tasks from other users', () async {
    await db.taskDao.insertTask(TasksCompanion(
      userId: const Value('other'),
      title: const Value('Other user'),
      startAt: Value(DateTime(2024, 6, 15)),
    ));
    final result = await db.taskDao
        .getTasksForDateRange('u1', DateTime(2024, 6, 10), DateTime(2024, 6, 20));
    expect(result, isEmpty);
  });
}
