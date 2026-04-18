import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumino_app/database/database.dart';
import 'package:lumino_app/features/today/tasks_provider.dart';

void main() {
  test('tasksForDayProvider returns tasks for date', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.taskDao.insertTask(TasksCompanion.insert(
      userId: 'u1',
      title: 'Test task',
      iconId: const Value('check'),
      color: const Value('#E8823A'),
      startAt: DateTime(2026, 4, 17, 8, 0),
    ));

    final container = ProviderContainer(
      overrides: [
        dbProvider.overrideWithValue(db),
        currentUserIdProvider.overrideWithValue('u1'),
      ],
    );
    addTearDown(container.dispose);

    final tasks = await container.read(tasksForDayProvider(DateTime(2026, 4, 17)).future);
    expect(tasks, hasLength(1));
    expect(tasks.first.title, 'Test task');
    await db.close();
  });
}
