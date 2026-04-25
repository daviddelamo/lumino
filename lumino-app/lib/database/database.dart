import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables.dart';
import 'daos/task_dao.dart';
import 'daos/habit_dao.dart';
import 'daos/user_dao.dart';
import 'daos/mood_dao.dart';

part 'database.g.dart';

// ignore: unused_element
String _uuid() => generateUuid();

@DriftDatabase(
    tables: [Tasks, Habits, HabitEntries, Users, MoodEntries],
    daos: [TaskDao, HabitDao, UserDao, MoodDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(moodEntries);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'lumino.db'));
      return NativeDatabase(file);
    });
  }
}
