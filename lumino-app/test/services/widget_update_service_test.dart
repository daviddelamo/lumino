import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lumino_app/services/widget_update_service.dart';
import 'package:lumino_app/database/database.dart';
import 'package:lumino_app/database/daos/task_dao.dart';
import 'package:lumino_app/database/daos/habit_dao.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MockAppDatabase extends Mock implements AppDatabase {}
class MockTaskDao extends Mock implements TaskDao {}
class MockHabitDao extends Mock implements HabitDao {}

void main() {
  late MockAppDatabase db;
  late MockTaskDao taskDao;
  late MockHabitDao habitDao;
  late List<String> savedKeys;
  late List<String> savedValues;
  late int updateCallCount;

  setUp(() {
    db = MockAppDatabase();
    taskDao = MockTaskDao();
    habitDao = MockHabitDao();
    savedKeys = [];
    savedValues = [];
    updateCallCount = 0;
    when(() => db.taskDao).thenReturn(taskDao);
    when(() => db.habitDao).thenReturn(habitDao);
  });

  WidgetUpdateService makeService() => WidgetUpdateService(
        db,
        save: (k, v) async {
          savedKeys.add(k);
          savedValues.add(v);
        },
        update: () async => updateCallCount++,
      );

  test('refresh with task type serialises tasks to JSON', () async {
    final task = Task(
      id: 'task-1',
      userId: 'user-1',
      title: 'Morning run',
      iconId: 'run',
      color: '#E8823A',
      startAt: DateTime(2026, 4, 19, 8, 0),
      updatedAt: DateTime(2026, 4, 19),
      dirty: false,
    );
    when(() => taskDao.getTasksForDay(any(), any())).thenAnswer((_) async => [task]);

    final service = makeService();
    await service.refresh(type: 'tasks', count: 5, userId: 'user-1');

    final itemsIndex = savedKeys.indexOf('lumino_widget_items');
    expect(itemsIndex, isNot(-1));
    final items = jsonDecode(savedValues[itemsIndex]) as List;
    expect(items.length, 1);
    expect(items[0]['id'], 'task-1');
    expect(items[0]['title'], 'Morning run');
    expect(items[0]['time'], '08:00');
    expect(items[0]['completed'], false);
    expect(updateCallCount, 1);
  });

  test('refresh with habit type serialises habits to JSON', () async {
    final habit = Habit(
      id: 'habit-1',
      userId: 'user-1',
      title: 'Drink water',
      iconId: 'water',
      color: '#A8D5BA',
      type: 'bool',
      targetValue: 1,
      frequencyRule: 'daily',
      archivedAt: null,
      createdAt: DateTime(2026, 4, 19),
      updatedAt: DateTime(2026, 4, 19),
      dirty: false,
    );
    when(() => habitDao.getActiveHabits(any())).thenAnswer((_) async => [habit]);
    when(() => habitDao.getEntriesForDate(any(), any())).thenAnswer((_) async => []);

    final service = makeService();
    await service.refresh(type: 'habits', count: 5, userId: 'user-1');

    final itemsIndex = savedKeys.indexOf('lumino_widget_items');
    final items = jsonDecode(savedValues[itemsIndex]) as List;
    expect(items.length, 1);
    expect(items[0]['id'], 'habit-1');
    expect(items[0]['title'], 'Drink water');
    expect(items[0]['completed'], false);
    expect(updateCallCount, 1);
  });

  test('count limits number of serialised items', () async {
    final tasks = List.generate(
      6,
      (i) => Task(
        id: 'task-$i',
        userId: 'user-1',
        title: 'Task $i',
        iconId: 'circle',
        color: '#E8823A',
        startAt: DateTime(2026, 4, 19, 8 + i, 0),
        updatedAt: DateTime(2026, 4, 19),
        dirty: false,
      ),
    );
    when(() => taskDao.getTasksForDay(any(), any())).thenAnswer((_) async => tasks);

    final service = makeService();
    await service.refresh(type: 'tasks', count: 3, userId: 'user-1');

    final itemsIndex = savedKeys.indexOf('lumino_widget_items');
    final items = jsonDecode(savedValues[itemsIndex]) as List;
    expect(items.length, 3);
  });

  test('count 0 returns all items', () async {
    final tasks = List.generate(
      8,
      (i) => Task(
        id: 'task-$i',
        userId: 'user-1',
        title: 'Task $i',
        iconId: 'circle',
        color: '#E8823A',
        startAt: DateTime(2026, 4, 19, 8 + i, 0),
        updatedAt: DateTime(2026, 4, 19),
        dirty: false,
      ),
    );
    when(() => taskDao.getTasksForDay(any(), any())).thenAnswer((_) async => tasks);

    final service = makeService();
    await service.refresh(type: 'tasks', count: 0, userId: 'user-1');

    final itemsIndex = savedKeys.indexOf('lumino_widget_items');
    final items = jsonDecode(savedValues[itemsIndex]) as List;
    expect(items.length, 8);
  });

  test('refreshFromPrefs reads prefs and updates widget', () async {
    SharedPreferences.setMockInitialValues({
      'lumino_widget_type': 'tasks',
      'lumino_widget_count': 3,
      'lumino_widget_user_id': 'u1',
    });

    final task = Task(
      id: 'task-prefs-1',
      userId: 'u1',
      title: 'Prefs task',
      iconId: 'circle',
      color: '#E8823A',
      startAt: DateTime(2026, 4, 24, 9, 0),
      updatedAt: DateTime(2026, 4, 24),
      dirty: false,
    );
    when(() => taskDao.getTasksForDay(any(), any())).thenAnswer((_) async => [task]);

    final service = makeService();
    await service.refreshFromPrefs();

    final itemsIndex = savedKeys.indexOf('lumino_widget_items');
    expect(itemsIndex, isNot(-1));
    final items = jsonDecode(savedValues[itemsIndex]) as List;
    expect(items.length, 1);
    expect(updateCallCount, 1);
  });
}
