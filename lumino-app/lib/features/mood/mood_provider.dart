import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../today/tasks_provider.dart';

class MoodNotifier extends StateNotifier<AsyncValue<List<MoodEntry>>> {
  final AppDatabase _db;
  final String _userId;

  MoodNotifier(this._db, this._userId) : super(const AsyncValue.loading()) {
    _loadToday();
  }

  Future<void> _loadToday() async {
    state = await AsyncValue.guard(() {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return _db.moodDao.getEntriesForDateRange(_userId, start, end);
    });
  }

  Future<void> checkIn(int level, List<String> tags, {String? note}) async {
    await _db.moodDao.insertEntry(MoodEntriesCompanion.insert(
      userId: _userId,
      moodLevel: level,
      tags: Value(jsonEncode(tags)),
      note: Value(note),
      loggedAt: DateTime.now(),
    ));
    await _loadToday();
  }
}

final moodProvider =
    StateNotifierProvider<MoodNotifier, AsyncValue<List<MoodEntry>>>((ref) {
  final db = ref.watch(dbProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'local';
  return MoodNotifier(db, userId);
});

final moodEntriesForMonthProvider =
    FutureProvider.family<List<MoodEntry>, (int, int)>((ref, yearMonth) async {
  ref.watch(moodProvider); // invalidate when today's entries change
  final db = ref.watch(dbProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'local';
  final (year, month) = yearMonth;
  final from = DateTime(year, month);
  final to = DateTime(year, month + 1, 0, 23, 59, 59);
  return db.moodDao.getEntriesForDateRange(userId, from, to);
});

final moodEntriesLast14Provider =
    FutureProvider<List<MoodEntry>>((ref) async {
  ref.watch(moodProvider); // invalidate when today's entries change
  final db = ref.watch(dbProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'local';
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, now.day)
      .subtract(const Duration(days: 13));
  final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return db.moodDao.getEntriesForDateRange(userId, from, to);
});
