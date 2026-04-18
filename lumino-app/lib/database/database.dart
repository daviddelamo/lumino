import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables.dart';
import 'daos/task_dao.dart';
import 'daos/habit_dao.dart';
import 'daos/user_dao.dart';

part 'database.g.dart';

// ignore: unused_element
String _uuid() => generateUuid();

@DriftDatabase(
    tables: [Tasks, Habits, HabitEntries, Users],
    daos: [TaskDao, HabitDao, UserDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'lumino.db'));
      return NativeDatabase(file);
    });
  }
}
