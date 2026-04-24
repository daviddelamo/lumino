import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../services/auth_state.dart';
import '../../services/widget_update_service.dart';

final dbProvider = Provider<AppDatabase>((ref) => AppDatabase());
final currentUserIdProvider = Provider<String?>((ref) => ref.watch(authProvider).userId);

final tasksForDayProvider = FutureProvider.family<List<Task>, DateTime>((ref, date) async {
  final db = ref.watch(dbProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return db.taskDao.getTasksForDay(userId, date);
});

class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final AppDatabase _db;
  final String _userId;
  final DateTime _date;
  late final WidgetUpdateService _widgetService;

  TasksNotifier(this._db, this._userId, this._date) : super(const AsyncValue.loading()) {
    _widgetService = WidgetUpdateService(_db);
    _load();
  }

  Future<void> _load() async {
    state = await AsyncValue.guard(() => _db.taskDao.getActiveTasks(_userId, _date));
  }

  Future<void> completeTask(String taskId) async {
    await _db.taskDao.markComplete(taskId, DateTime.now());
    await _load();
    await _widgetService.refreshFromPrefs();
  }

  Future<void> uncompleteTask(String taskId) async {
    await _db.taskDao.markIncomplete(taskId);
    await _load();
    await _widgetService.refreshFromPrefs();
  }

  Future<void> deleteTask(String taskId) async {
    await _db.taskDao.softDelete(taskId);
    await _load();
    await _widgetService.refreshFromPrefs();
  }

  Future<void> reload() => _load();
}

final tasksNotifierProvider = StateNotifierProvider.family<TasksNotifier, AsyncValue<List<Task>>, DateTime>(
  (ref, date) {
    final db = ref.watch(dbProvider);
    final userId = ref.watch(currentUserIdProvider) ?? 'local';
    return TasksNotifier(db, userId, date);
  },
);
