import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';

typedef WidgetSaver = Future<void> Function(String key, String value);
typedef WidgetUpdater = Future<void> Function();

class WidgetUpdateService {
  static const String _keyType   = 'lumino_widget_type';
  static const String _keyCount  = 'lumino_widget_count';
  static const String _keyUserId = 'lumino_widget_user_id';
  static const String _keyItems  = 'lumino_widget_items';

  final AppDatabase _db;
  final WidgetSaver _save;
  final WidgetUpdater _update;

  WidgetUpdateService(
    this._db, {
    WidgetSaver? save,
    WidgetUpdater? update,
  })  : _save = save ??
            ((k, v) async => HomeWidget.saveWidgetData<String>(k, v)),
        _update = update ??
            (() async {
              await HomeWidget.updateWidget(androidName: 'LuminoSmallWidget');
              await HomeWidget.updateWidget(androidName: 'LuminoLargeWidget');
            });

  Future<void> refreshFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final type   = prefs.getString(_keyType)   ?? 'tasks';
      final count  = prefs.getInt(_keyCount)      ?? 5;
      final userId = prefs.getString(_keyUserId)  ?? 'local';
      await refresh(type: type, count: count, userId: userId);
    } catch (e, st) {
      // Widget update failed; leave the current widget data intact.
      debugPrint('WidgetUpdateService.refreshFromPrefs: $e\n$st');
    }
  }

  /// Fetches today's [type] items and pushes them to the home-screen widgets.
  /// Pass [count] = 0 to return all items without a limit.
  Future<void> refresh({
    required String type,
    required int count,
    required String userId,
  }) async {
    assert(type == 'tasks' || type == 'habits', 'Unknown widget type: $type');
    final List<Map<String, dynamic>> items;
    if (type == 'tasks') {
      items = await _buildTaskItems(userId, count);
    } else {
      items = await _buildHabitItems(userId, count);
    }
    await _save(_keyItems, jsonEncode(items));
    await _update();
  }

  Future<List<Map<String, dynamic>>> _buildTaskItems(
      String userId, int count) async {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final tasks = await _db.taskDao.getTasksForDay(userId, day);
    final limited = count == 0 ? tasks : tasks.take(count).toList();
    final fmt = DateFormat('HH:mm');
    return limited
        .map((t) => {
              'id': t.id,
              'title': t.title,
              'color': t.color,
              'time': fmt.format(t.startAt),
              'completed': t.completedAt != null,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> _buildHabitItems(
      String userId, int count) async {
    final habits = await _db.habitDao.getActiveHabits(userId);
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final ids = habits.map((h) => h.id).toList();
    final entries = await _db.habitDao.getEntriesForDate(ids, day);
    final completedIds = entries.map((e) => e.habitId).toSet();
    final limited = count == 0 ? habits : habits.take(count).toList();
    return limited
        .map((h) => {
              'id': h.id,
              'title': h.title,
              'color': h.color,
              'time': '',
              'completed': completedIds.contains(h.id),
            })
        .toList();
  }
}
