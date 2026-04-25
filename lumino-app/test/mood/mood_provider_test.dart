import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumino_app/database/database.dart';
import 'package:lumino_app/features/mood/mood_provider.dart';
import 'package:lumino_app/features/today/tasks_provider.dart';

Future<List<MoodEntry>> _awaitMood(ProviderContainer container) async {
  while (container.read(moodProvider) is AsyncLoading) {
    await Future.delayed(const Duration(milliseconds: 10));
  }
  return container.read(moodProvider).value ?? [];
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('initial state resolves to empty list', () async {
    final result = await _awaitMood(container);
    expect(result, isEmpty);
  });

  test('checkIn inserts entry; today state includes it', () async {
    await container.read(moodProvider.notifier).checkIn(4, ['calm', 'focused']);
    final state = await _awaitMood(container);
    expect(state, hasLength(1));
    expect(state.first.moodLevel, 4);
  });

  test('checkIn with note persists note', () async {
    await container.read(moodProvider.notifier).checkIn(3, ['tired'], note: 'long day');
    final state = await _awaitMood(container);
    expect(state.first.note, 'long day');
  });

  test('moodEntriesForMonthProvider returns entries in that month', () async {
    await container.read(moodProvider.notifier).checkIn(5, []);
    final now = DateTime.now();
    final entries = await container
        .read(moodEntriesForMonthProvider((now.year, now.month)).future);
    expect(entries, hasLength(1));
  });

  test('moodEntriesLast14Provider returns entries within 14 days', () async {
    await container.read(moodProvider.notifier).checkIn(2, ['anxious']);
    final entries = await container.read(moodEntriesLast14Provider.future);
    expect(entries, hasLength(1));
  });
}
