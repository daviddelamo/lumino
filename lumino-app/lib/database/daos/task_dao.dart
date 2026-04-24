import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Future<String> insertTask(TasksCompanion task) async {
    final id = task.id.present ? task.id.value : generateUuid();
    final companion = task.id.present ? task : task.copyWith(id: Value(id));
    await into(tasks).insert(companion, mode: InsertMode.insertOrReplace);
    return id;
  }

  Future<List<Task>> getTasksForDay(String userId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.startAt.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .get();
  }

  /// Tasks for the today screen: uncompleted tasks from today or earlier,
  /// plus tasks completed today. Tasks only disappear the day after completion.
  Future<List<Task>> getActiveTasks(String userId, DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return (select(tasks)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              ((t.completedAt.isNull() & t.startAt.isSmallerThanValue(dayEnd)) |
                  t.completedAt.isBetweenValues(dayStart, dayEnd)))
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .get();
  }

  Future<void> markComplete(String taskId, DateTime completedAt) =>
      (update(tasks)..where((t) => t.id.equals(taskId))).write(
          TasksCompanion(
              completedAt: Value(completedAt), dirty: const Value(true)));

  Future<void> markIncomplete(String taskId) =>
      (update(tasks)..where((t) => t.id.equals(taskId))).write(
          const TasksCompanion(
              completedAt: Value(null), dirty: Value(true)));

  Future<void> softDelete(String taskId) =>
      (update(tasks)..where((t) => t.id.equals(taskId))).write(TasksCompanion(
          deletedAt: Value(DateTime.now()), dirty: const Value(true)));

  Future<void> updateTask(String taskId, TasksCompanion companion) =>
      (update(tasks)..where((t) => t.id.equals(taskId))).write(companion);

  Future<List<Task>> getDirtyTasks() =>
      (select(tasks)..where((t) => t.dirty.equals(true))).get();

  Future<void> markSynced(String taskId) =>
      (update(tasks)..where((t) => t.id.equals(taskId))).write(TasksCompanion(
          dirty: const Value(false), syncedAt: Value(DateTime.now())));
}
