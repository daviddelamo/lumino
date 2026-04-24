import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import 'api_client.dart';
import 'widget_update_service.dart';

class SyncService {
  final AppDatabase _db;
  final ApiClient _api;
  bool _syncing = false;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  late final WidgetUpdateService _widgetService;

  SyncService(this._db, this._api, {Connectivity? connectivity}) {
    _widgetService = WidgetUpdateService(_db);
    _connectivitySub = (connectivity ?? Connectivity())
        .onConnectivityChanged
        .listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) sync();
    });
  }

  void dispose() => _connectivitySub.cancel();

  Future<void> sync({String? userId}) async {
    if (_syncing) return;
    _syncing = true;
    try {
      final token = await _api.getAccessToken();
      if (token == null) return;
      final uid = userId ?? 'local';
      await _pushDirtyTasks();
      await _pullLatest(uid);
      await _widgetService.refreshFromPrefs();
    } finally {
      _syncing = false;
    }
  }

  Future<void> _pushDirtyTasks() async {
    final dirty = await _db.taskDao.getDirtyTasks();
    for (final task in dirty) {
      try {
        if (task.deletedAt != null) {
          await _api.delete('/api/tasks/${task.id}');
        } else {
          await _api.post('/api/tasks', data: {
            'title': task.title,
            'iconId': task.iconId,
            'color': task.color,
            'startAt': task.startAt.toUtc().toIso8601String(),
            if (task.endAt != null) 'endAt': task.endAt!.toUtc().toIso8601String(),
            if (task.completedAt != null)
              'completedAt': task.completedAt!.toUtc().toIso8601String(),
          });
        }
        await _db.taskDao.markSynced(task.id);
      } on DioException catch (_) {
        // Leave dirty for next sync attempt
      }
    }
  }

  Future<void> _pullLatest(String userId) async {
    try {
      final tasksRes = await _api.get('/api/tasks',
          queryParameters: {'date': _todayString()});
      final raw = tasksRes.data;
      if (raw is! Map<String, dynamic>) return;
      final list = raw['data'];
      if (list is! List) return;
      for (final t in list) {
        if (t is! Map<String, dynamic>) continue;
        await _db.taskDao.insertTask(_taskFromJson(t, userId));
      }
    } on DioException catch (_) {}
  }

  String _todayString() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  TasksCompanion _taskFromJson(Map<String, dynamic> t, String userId) {
    return TasksCompanion.insert(
      userId: userId,
      title: t['title'] as String,
      iconId: Value(t['iconId'] as String? ?? 'circle'),
      color: Value(t['color'] as String? ?? '#E8823A'),
      startAt: DateTime.parse(t['startAt'] as String),
      dirty: const Value(false),
    );
  }
}
