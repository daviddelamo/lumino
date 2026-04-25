# Mood Tracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a daily mood check-in feature with a coloured-tile bottom sheet, a history screen showing a monthly calendar heatmap and 14-day trend chart, and dirty-flag sync — all wired into TodayScreen and MeScreen navigation.

**Architecture:** Standalone Drift module (`MoodEntries` table + `MoodDao`, schema v2) backed by a Riverpod `MoodNotifier` (today's entries for the TodayScreen button) and two `FutureProvider` variants for the history screen. UI is a `showModalBottomSheet` check-in sheet and a `ConsumerStatefulWidget` history screen using `fl_chart` for the trend line.

**Tech Stack:** Flutter/Dart, Drift (SQLite), Riverpod `StateNotifier` + `FutureProvider.family`, go_router, fl_chart ^0.69.0

---

### Task 1: MoodEntries table, MoodDao, and schema migration

**Files:**
- Modify: `lib/database/tables.dart`
- Create: `lib/database/daos/mood_dao.dart`
- Modify: `lib/database/database.dart`
- Test: `test/database/database_test.dart` (add at end of existing `main()`)

- [ ] **Step 1: Write failing tests — add to end of `main()` in `test/database/database_test.dart`**

```dart
  test('can insert a mood entry and retrieve it by date range', () async {
    final now = DateTime(2026, 4, 24, 9, 0);
    await db.moodDao.insertEntry(MoodEntriesCompanion.insert(
      userId: 'test-user',
      moodLevel: 4,
      tags: const Value('["calm","focused"]'),
      loggedAt: now,
    ));
    final entries = await db.moodDao.getEntriesForDateRange(
      'test-user',
      DateTime(2026, 4, 24),
      DateTime(2026, 4, 24, 23, 59, 59),
    );
    expect(entries, hasLength(1));
    expect(entries.first.moodLevel, 4);
    expect(entries.first.tags, '["calm","focused"]');
  });

  test('getDirtyEntries returns only dirty rows for user', () async {
    await db.moodDao.insertEntry(MoodEntriesCompanion.insert(
      userId: 'test-user',
      moodLevel: 3,
      loggedAt: DateTime(2026, 4, 24),
    ));
    await db.moodDao.insertEntry(MoodEntriesCompanion.insert(
      userId: 'test-user',
      moodLevel: 2,
      loggedAt: DateTime(2026, 4, 24),
      dirty: const Value(false),
    ));
    final dirty = await db.moodDao.getDirtyEntries('test-user');
    expect(dirty, hasLength(1));
    expect(dirty.first.moodLevel, 3);
  });

  test('markSynced sets dirty to false', () async {
    await db.moodDao.insertEntry(MoodEntriesCompanion.insert(
      userId: 'test-user',
      moodLevel: 5,
      loggedAt: DateTime(2026, 4, 24),
    ));
    final before = await db.moodDao.getDirtyEntries('test-user');
    expect(before, hasLength(1));
    await db.moodDao.markSynced([before.first.id]);
    final after = await db.moodDao.getDirtyEntries('test-user');
    expect(after, isEmpty);
  });
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd lumino-app && flutter test test/database/database_test.dart
```
Expected: compilation error — `db.moodDao` does not exist.

- [ ] **Step 3: Add `MoodEntries` class to `lib/database/tables.dart`**

Add this class after the `Users` class, before the `_uuid()` function:

```dart
class MoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  IntColumn get moodLevel => integer()();
  TextColumn get tags =>
      text().withDefault(const Constant('[]'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
}
```

- [ ] **Step 4: Create `lib/database/daos/mood_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'mood_dao.g.dart';

@DriftAccessor(tables: [MoodEntries])
class MoodDao extends DatabaseAccessor<AppDatabase> with _$MoodDaoMixin {
  MoodDao(super.db);

  Future<int> insertEntry(MoodEntriesCompanion entry) =>
      into(moodEntries).insert(entry);

  Future<List<MoodEntry>> getEntriesForDateRange(
    String userId,
    DateTime from,
    DateTime to,
  ) =>
      (select(moodEntries)
            ..where((e) =>
                e.userId.equals(userId) &
                e.loggedAt.isBetweenValues(from, to))
            ..orderBy([(e) => OrderingTerm.asc(e.loggedAt)]))
          .get();

  Future<List<MoodEntry>> getDirtyEntries(String userId) =>
      (select(moodEntries)
            ..where((e) => e.userId.equals(userId) & e.dirty.equals(true)))
          .get();

  Future<void> markSynced(List<int> ids) =>
      (update(moodEntries)..where((e) => e.id.isIn(ids)))
          .write(const MoodEntriesCompanion(dirty: Value(false)));
}
```

- [ ] **Step 5: Update `lib/database/database.dart` — add `MoodEntries`, `MoodDao`, bump schema version to 2, add migration**

Replace the entire file contents:

```dart
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
```

- [ ] **Step 6: Run build_runner**

```bash
cd lumino-app && dart run build_runner build --delete-conflicting-outputs
```
Expected: no errors; `lib/database/daos/mood_dao.g.dart` created, `lib/database/database.g.dart` updated.

- [ ] **Step 7: Run tests — should pass**

```bash
cd lumino-app && flutter test test/database/database_test.dart
```
Expected: all tests PASS.

- [ ] **Step 8: Run full test suite**

```bash
cd lumino-app && flutter test
```
Expected: all tests PASS.

- [ ] **Step 9: Commit**

```bash
cd lumino-app && git add lib/database/tables.dart lib/database/daos/mood_dao.dart lib/database/daos/mood_dao.g.dart lib/database/database.dart lib/database/database.g.dart test/database/database_test.dart
git commit -m "feat: add MoodEntries table, MoodDao, and schema migration v2"
```

---

### Task 2: MoodNotifier and mood providers

**Files:**
- Create: `lib/features/mood/mood_provider.dart`
- Create: `test/mood/mood_provider_test.dart`

- [ ] **Step 1: Create `test/mood/mood_provider_test.dart`**

```dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumino_app/database/database.dart';
import 'package:lumino_app/features/mood/mood_provider.dart';
import 'package:lumino_app/features/today/tasks_provider.dart';

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

  test('initial state is loading then empty list', () async {
    final result = await container.read(moodProvider.future);
    expect(result, isEmpty);
  });

  test('checkIn inserts entry; today state includes it', () async {
    await container.read(moodProvider.notifier).checkIn(4, ['calm', 'focused']);
    final state = await container.read(moodProvider.future);
    expect(state, hasLength(1));
    expect(state.first.moodLevel, 4);
  });

  test('checkIn with note persists note', () async {
    await container.read(moodProvider.notifier).checkIn(3, ['tired'], note: 'long day');
    final state = await container.read(moodProvider.future);
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
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd lumino-app && flutter test test/mood/mood_provider_test.dart
```
Expected: compilation error — `mood_provider.dart` not found.

- [ ] **Step 3: Create `lib/features/mood/mood_provider.dart`**

```dart
import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../features/today/tasks_provider.dart';

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
  final db = ref.watch(dbProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'local';
  final (year, month) = yearMonth;
  final from = DateTime(year, month);
  final to = DateTime(year, month + 1, 0, 23, 59, 59);
  return db.moodDao.getEntriesForDateRange(userId, from, to);
});

final moodEntriesLast14Provider =
    FutureProvider<List<MoodEntry>>((ref) async {
  final db = ref.watch(dbProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'local';
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, now.day)
      .subtract(const Duration(days: 13));
  final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return db.moodDao.getEntriesForDateRange(userId, from, to);
});
```

**Note:** The test uses `container.read(moodProvider.future)` — with `StateNotifier<AsyncValue<T>>`, there is no built-in `.future` on the provider. The test should instead await the notifier's guard. Update `test/mood/mood_provider_test.dart` to use a helper:

Replace all occurrences of `container.read(moodProvider.future)` with:

```dart
Future<List<MoodEntry>> _awaitMood(ProviderContainer container) async {
  while (container.read(moodProvider) is AsyncLoading) {
    await Future.delayed(const Duration(milliseconds: 10));
  }
  return container.read(moodProvider).value ?? [];
}
```

And in each test, use `await _awaitMood(container)` instead of `await container.read(moodProvider.future)`.

Full updated `test/mood/mood_provider_test.dart`:

```dart
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
```

- [ ] **Step 4: Run tests — should pass**

```bash
cd lumino-app && flutter test test/mood/mood_provider_test.dart
```
Expected: all 5 tests PASS.

- [ ] **Step 5: Run full test suite**

```bash
cd lumino-app && flutter test
```
Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
cd lumino-app && git add lib/features/mood/mood_provider.dart test/mood/mood_provider_test.dart
git commit -m "feat: add MoodNotifier and mood providers"
```

---

### Task 3: Add fl_chart and MoodCheckInSheet

**Files:**
- Modify: `lumino-app/pubspec.yaml`
- Create: `lib/features/mood/mood_check_in_sheet.dart`

- [ ] **Step 1: Add `fl_chart` to `pubspec.yaml`**

In `lumino-app/pubspec.yaml`, in the `dependencies:` section, add after `home_widget: ^0.7.0`:

```yaml
  fl_chart: ^0.69.0
```

- [ ] **Step 2: Fetch the dependency**

```bash
cd lumino-app && flutter pub get
```
Expected: resolves without error; `fl_chart` appears in `.dart_tool/package_config.json`.

- [ ] **Step 3: Create `lib/features/mood/mood_check_in_sheet.dart`**

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import 'mood_provider.dart';

const _moodColors = [
  Color(0xFFE05C5C),
  Color(0xFFE8913A),
  Color(0xFFE8C23A),
  Color(0xFF8BC48A),
  Color(0xFF52B788),
];
const _moodEmojis = ['😢', '😕', '😐', '🙂', '😄'];
const _moodLabels = ['Awful', 'Bad', 'Okay', 'Good', 'Amazing'];
const _allTags = [
  'anxious', 'calm', 'energised', 'tired',
  'grateful', 'stressed', 'focused', 'social',
];

class MoodCheckInSheet extends ConsumerStatefulWidget {
  const MoodCheckInSheet({super.key});

  @override
  ConsumerState<MoodCheckInSheet> createState() => _MoodCheckInSheetState();
}

class _MoodCheckInSheetState extends ConsumerState<MoodCheckInSheet> {
  int? _selectedLevel;
  final Set<String> _selectedTags = {};
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedLevel == null || _saving) return;
    setState(() => _saving = true);
    await ref.read(moodProvider.notifier).checkIn(
          _selectedLevel!,
          _selectedTags.toList(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mood logged'),
          action: SnackBarAction(
            label: 'See history',
            onPressed: () => GoRouter.of(context).push('/mood/history'),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: LuminoTheme.divider(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'How are you feeling?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          _MoodTileRow(
            selectedLevel: _selectedLevel,
            onSelect: (level) => setState(() => _selectedLevel = level),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) => Text(
              _moodLabels[i],
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: _selectedLevel == i + 1
                        ? LuminoTheme.primaryColor
                        : LuminoTheme.textSecondary(context),
                    fontWeight: _selectedLevel == i + 1
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
            )),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allTags.map((tag) {
              final selected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() {
                  selected ? _selectedTags.remove(tag) : _selectedTags.add(tag);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? LuminoTheme.primaryColor
                        : LuminoTheme.divider(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected
                              ? Colors.white
                              : LuminoTheme.textSecondary(context),
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              hintText: 'Add a note… (optional)',
              hintStyle: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: LuminoTheme.textSecondary(context)),
              filled: true,
              fillColor: LuminoTheme.surface(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedLevel != null && !_saving ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: LuminoTheme.primaryColor,
                disabledBackgroundColor:
                    LuminoTheme.primaryColor.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Save',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodTileRow extends StatelessWidget {
  final int? selectedLevel;
  final ValueChanged<int> onSelect;

  const _MoodTileRow({required this.selectedLevel, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final level = i + 1;
        final selected = selectedLevel == level;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: selected ? 60 : 50,
              decoration: BoxDecoration(
                color: _moodColors[i],
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(color: LuminoTheme.primaryColor, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  _moodEmojis[i],
                  style: TextStyle(fontSize: selected ? 26 : 20),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

List<String> decodeMoodTags(String json) {
  try {
    return (jsonDecode(json) as List).cast<String>();
  } catch (_) {
    return [];
  }
}
```

- [ ] **Step 4: Run full test suite**

```bash
cd lumino-app && flutter test
```
Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
cd lumino-app && git add pubspec.yaml pubspec.lock lib/features/mood/mood_check_in_sheet.dart
git commit -m "feat: add fl_chart dependency and MoodCheckInSheet with coloured tile picker"
```

---

### Task 4: MoodHistoryScreen

**Files:**
- Create: `lib/features/mood/mood_history_screen.dart`

- [ ] **Step 1: Create `lib/features/mood/mood_history_screen.dart`**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../database/database.dart';
import '../../shared/widgets/lumino_nav_bar.dart';
import '../../theme.dart';
import 'mood_provider.dart';

const _moodColors = [
  Color(0xFFE05C5C),
  Color(0xFFE8913A),
  Color(0xFFE8C23A),
  Color(0xFF8BC48A),
  Color(0xFF52B788),
];

class MoodHistoryScreen extends ConsumerStatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  ConsumerState<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends ConsumerState<MoodHistoryScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _prevMonth() => setState(() {
        if (_month == 1) {
          _year--;
          _month = 12;
        } else {
          _month--;
        }
      });

  void _nextMonth() {
    final now = DateTime.now();
    if (_year == now.year && _month == now.month) return;
    setState(() {
      if (_month == 12) {
        _year++;
        _month = 1;
      } else {
        _month++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _year == now.year && _month == now.month;
    final monthEntries = ref.watch(moodEntriesForMonthProvider((_year, _month)));
    final last14Entries = ref.watch(moodEntriesLast14Provider);

    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      appBar: AppBar(
        backgroundColor: LuminoTheme.bg(context),
        elevation: 0,
        title: Text('Mood History',
            style: Theme.of(context).textTheme.headlineSmall),
        iconTheme: IconThemeData(color: LuminoTheme.textPrimary(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthHeader(
              year: _year,
              month: _month,
              isCurrentMonth: isCurrentMonth,
              onPrev: _prevMonth,
              onNext: _nextMonth,
            ),
            const SizedBox(height: 16),
            monthEntries.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (entries) =>
                  _MonthCalendar(year: _year, month: _month, entries: entries),
            ),
            const SizedBox(height: 8),
            const _ColorLegend(),
            const SizedBox(height: 24),
            Text(
              'LAST 14 DAYS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1,
                    color: LuminoTheme.textSecondary(context),
                  ),
            ),
            const SizedBox(height: 12),
            last14Entries.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (entries) => _TrendChart(entries: entries),
            ),
            const SizedBox(height: 24),
            monthEntries.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (entries) =>
                  _StatsRow(entries: entries, year: _year, month: _month),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const LuminoNavBar(currentIndex: 0),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final int year;
  final int month;
  final bool isCurrentMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.year,
    required this.month,
    required this.isCurrentMonth,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          color: LuminoTheme.textPrimary(context),
        ),
        Text(
          DateFormat('MMMM yyyy').format(DateTime(year, month)),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          onPressed: isCurrentMonth ? null : onNext,
          icon: Icon(
            Icons.chevron_right,
            color: isCurrentMonth
                ? LuminoTheme.textSecondary(context)
                : LuminoTheme.textPrimary(context),
          ),
        ),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  final int year;
  final int month;
  final List<MoodEntry> entries;

  const _MonthCalendar({
    required this.year,
    required this.month,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final byDay = <int, List<int>>{};
    for (final e in entries) {
      byDay.putIfAbsent(e.loggedAt.day, () => []).add(e.moodLevel);
    }
    final avgByDay = byDay.map((day, levels) {
      final avg = levels.reduce((a, b) => a + b) / levels.length;
      return MapEntry(day, avg.round().clamp(1, 5));
    });

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final offset = DateTime(year, month, 1).weekday - 1; // Mon=0
    final today = DateTime.now();
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        Row(
          children: dayLabels
              .map((l) => Expanded(
                    child: Center(
                      child: Text(
                        l,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: LuminoTheme.textSecondary(context),
                            ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.4,
          ),
          itemCount: offset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox.shrink();
            final day = index - offset + 1;
            final cellDate = DateTime(year, month, day);
            final isFuture = cellDate.isAfter(today);
            final isToday = year == today.year &&
                month == today.month &&
                day == today.day;
            final level = avgByDay[day];

            Color cellColor;
            double opacity;
            if (isFuture) {
              cellColor = LuminoTheme.divider(context);
              opacity = 0.0;
            } else if (level == null) {
              cellColor = LuminoTheme.divider(context);
              opacity = 0.3;
            } else {
              cellColor = _moodColors[level - 1];
              opacity = 1.0;
            }

            return Opacity(
              opacity: opacity,
              child: Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(5),
                  border: isToday
                      ? Border.all(color: LuminoTheme.primaryColor, width: 2)
                      : null,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ColorLegend extends StatelessWidget {
  const _ColorLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ..._moodColors.map((c) => Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
        const SizedBox(width: 4),
        Text(
          'Low → High',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: LuminoTheme.textSecondary(context),
              ),
        ),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<MoodEntry> entries;
  const _TrendChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final spots = <FlSpot>[];

    for (int i = 0; i < 14; i++) {
      final day = today.subtract(Duration(days: 13 - i));
      final dayEntries = entries.where((e) {
        final d = DateTime(e.loggedAt.year, e.loggedAt.month, e.loggedAt.day);
        return d == day;
      }).toList();
      if (dayEntries.isNotEmpty) {
        final avg = dayEntries.map((e) => e.moodLevel).reduce((a, b) => a + b) /
            dayEntries.length;
        spots.add(FlSpot(i.toDouble(), avg));
      }
    }

    if (spots.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: LuminoTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('No entries in the last 14 days',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: LuminoTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: LineChart(
        LineChartData(
          minY: 1,
          maxY: 5,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: LuminoTheme.primaryColor,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) => spot.x == spots.last.x,
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<MoodEntry> entries;
  final int year;
  final int month;

  const _StatsRow({
    required this.entries,
    required this.year,
    required this.month,
  });

  static int _streak(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;
    final days = entries
        .map((e) => DateTime(e.loggedAt.year, e.loggedAt.month, e.loggedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i - 1].difference(days[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    if (days.first.isBefore(todayNorm.subtract(const Duration(days: 1)))) return 0;
    return streak;
  }

  static String _emoji(double avg) {
    if (avg < 1.5) return '😢';
    if (avg < 2.5) return '😕';
    if (avg < 3.5) return '😐';
    if (avg < 4.5) return '🙂';
    return '😄';
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final loggedDays = entries
        .map((e) => DateTime(e.loggedAt.year, e.loggedAt.month, e.loggedAt.day))
        .toSet()
        .length;
    final avgMood = entries.isEmpty
        ? 0.0
        : entries.map((e) => e.moodLevel).reduce((a, b) => a + b) /
            entries.length;

    return Row(
      children: [
        _StatTile(
          emoji: entries.isEmpty ? '😶' : _emoji(avgMood),
          value: entries.isEmpty ? '—' : avgMood.toStringAsFixed(1),
          label: 'Avg mood',
        ),
        const SizedBox(width: 12),
        _StatTile(emoji: '🔥', value: '${_streak(entries)}', label: 'Day streak'),
        const SizedBox(width: 12),
        _StatTile(
          emoji: '✅',
          value: '$loggedDays/$daysInMonth',
          label: 'Logged',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatTile({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: LuminoTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: LuminoTheme.textSecondary(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run full test suite**

```bash
cd lumino-app && flutter test
```
Expected: all tests PASS.

- [ ] **Step 3: Commit**

```bash
cd lumino-app && git add lib/features/mood/mood_history_screen.dart
git commit -m "feat: add MoodHistoryScreen with calendar heatmap, trend chart, and stats"
```

---

### Task 5: Mood button in TodayScreen

**Files:**
- Modify: `lib/features/today/screens/today_screen.dart`

- [ ] **Step 1: Add imports to `today_screen.dart`**

At the top of `lib/features/today/screens/today_screen.dart`, after the last existing import, add:

```dart
import '../../mood/mood_check_in_sheet.dart';
import '../../mood/mood_provider.dart';
```

- [ ] **Step 2: Replace `_TodayHeader` with `ConsumerWidget` version**

Replace the entire `_TodayHeader` class (from `class _TodayHeader extends StatelessWidget` through its closing `}`) with:

```dart
class _TodayHeader extends ConsumerWidget {
  final DateTime date;
  final AsyncValue<List<Task>> tasksAsync;

  const _TodayHeader({required this.date, required this.tasksAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = tasksAsync.valueOrNull ?? [];
    final completed = tasks.where((t) => t.completedAt != null).length;
    final total = tasks.length;
    final moodState = ref.watch(moodProvider);
    final todayLevel = moodState.valueOrNull?.isNotEmpty == true
        ? moodState.valueOrNull!.last.moodLevel
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d').format(date),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _greeting(date.hour),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => GoRouter.of(context).go('/today/week'),
                    child: ProgressRing(
                      completed: completed,
                      total: total,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == 0 ? 'No tasks' : '$completed/$total',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: LuminoTheme.bg(context),
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => const MoodCheckInSheet(),
                ),
                child: _MoodButton(level: todayLevel),
              ),
            ],
          ),
          if (total > 0 && completed == total) ...[
            const SizedBox(height: 8),
            Text(
              'All done — great work today.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: LuminoTheme.primaryColor),
            ),
          ],
        ],
      ),
    );
  }

  static String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _MoodButton extends StatelessWidget {
  final int? level;
  const _MoodButton({this.level});

  static const _colors = [
    Color(0xFFE05C5C),
    Color(0xFFE8913A),
    Color(0xFFE8C23A),
    Color(0xFF8BC48A),
    Color(0xFF52B788),
  ];
  static const _emojis = ['😢', '😕', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context) {
    final color = level != null
        ? _colors[level! - 1]
        : LuminoTheme.divider(context);
    final emoji = level != null ? _emojis[level! - 1] : '😶';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
    );
  }
}
```

- [ ] **Step 3: Run full test suite**

```bash
cd lumino-app && flutter test
```
Expected: all tests PASS.

- [ ] **Step 4: Commit**

```bash
cd lumino-app && git add lib/features/today/screens/today_screen.dart
git commit -m "feat: add mood check-in button to TodayScreen header"
```

---

### Task 6: Router and MeScreen navigation

**Files:**
- Modify: `lib/router.dart`
- Modify: `lib/features/me/screens/me_screen.dart`

- [ ] **Step 1: Add `/mood/history` route to `lib/router.dart`**

Add import after the last existing import:
```dart
import 'features/mood/mood_history_screen.dart';
```

Add route after the `/me/notifications` route (before the closing `],`):
```dart
      GoRoute(path: '/mood/history', builder: (c, s) => const MoodHistoryScreen()),
```

- [ ] **Step 2: Add "Mood history" tile to `lib/features/me/screens/me_screen.dart`**

Locate the `_SettingsGroup` that contains the dark-mode `SwitchListTile` and the Notifications tile. After that group's closing `),`, add a new group:

```dart
                  _SettingsGroup(children: [
                    _SettingsTile(
                      icon: Icons.mood_outlined,
                      label: 'Mood history',
                      onTap: () => context.push('/mood/history'),
                    ),
                  ]),
```

- [ ] **Step 3: Run full test suite**

```bash
cd lumino-app && flutter test
```
Expected: all tests PASS.

- [ ] **Step 4: Commit**

```bash
cd lumino-app && git add lib/router.dart lib/features/me/screens/me_screen.dart
git commit -m "feat: wire /mood/history route and MeScreen navigation tile"
```

---

### Task 7: Mood sync in SyncService

**Files:**
- Modify: `lib/services/sync_service.dart`
- Modify: `test/services/sync_service_test.dart`

- [ ] **Step 1: Add failing test to `test/services/sync_service_test.dart`**

Add this test inside the existing `main()` block (the test uses the same `db`, `api`, `svc` variables already set up):

```dart
  test('sync pushes dirty mood entries to the mood API endpoint', () async {
    await db.moodDao.insertEntry(MoodEntriesCompanion.insert(
      userId: 'me',
      moodLevel: 4,
      loggedAt: DateTime(2026, 4, 24, 9, 0),
    ));
    when(() => api.getAccessToken()).thenAnswer((_) async => 'token');
    when(() => api.post(any(), data: any(named: 'data')))
        .thenAnswer((_) async => Response(
              data: {'data': {}},
              statusCode: 201,
              requestOptions: RequestOptions(path: ''),
            ));
    when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(
              data: {'data': []},
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

    await svc.sync(userId: 'me');

    // Dirty entry must now be marked synced
    final stillDirty = await db.moodDao.getDirtyEntries('me');
    expect(stillDirty, isEmpty);
    // POST to /api/mood was called once
    verify(() => api.post('/api/mood', data: any(named: 'data'))).called(1);
  });
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd lumino-app && flutter test test/services/sync_service_test.dart
```
Expected: the new test FAILS (no mood sync in SyncService yet).

- [ ] **Step 3: Add `_syncMood` to `lib/services/sync_service.dart`**

Add import at the top (after the existing imports):
```dart
import 'package:shared_preferences/shared_preferences.dart';
```

In the `sync()` method, add `await _syncMood(uid);` after `await _pullLatest(uid);`:
```dart
  Future<void> sync({String? userId}) async {
    if (_syncing) return;
    _syncing = true;
    try {
      final token = await _api.getAccessToken();
      if (token == null) return;
      final uid = userId ?? 'local';
      await _pushDirtyTasks();
      await _pullLatest(uid);
      await _syncMood(uid);
      await _widgetService.refreshFromPrefs();
    } finally {
      _syncing = false;
    }
  }
```

Add this method at the end of the `SyncService` class, before the closing `}`:

```dart
  Future<void> _syncMood(String userId) async {
    final dirty = await _db.moodDao.getDirtyEntries(userId);
    for (final entry in dirty) {
      try {
        await _api.post('/api/mood', data: {
          'moodLevel': entry.moodLevel,
          'tags': entry.tags,
          'note': entry.note,
          'loggedAt': entry.loggedAt.toUtc().toIso8601String(),
        });
        await _db.moodDao.markSynced([entry.id]);
      } on DioException catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final since =
          prefs.getString('lastMoodPullAt') ?? DateTime(2020).toIso8601String();
      final res = await _api.get('/api/mood', queryParameters: {'since': since});
      final raw = res.data;
      if (raw is Map<String, dynamic>) {
        final list = raw['data'];
        if (list is List) {
          for (final m in list) {
            if (m is! Map<String, dynamic>) continue;
            await _db.moodDao.insertEntry(MoodEntriesCompanion.insert(
              userId: userId,
              moodLevel: m['moodLevel'] as int,
              tags: Value(m['tags'] as String? ?? '[]'),
              note: Value(m['note'] as String?),
              loggedAt: DateTime.parse(m['loggedAt'] as String),
              dirty: const Value(false),
            ));
          }
        }
      }
      await prefs.setString(
          'lastMoodPullAt', DateTime.now().toUtc().toIso8601String());
    } on DioException catch (_) {}
  }
```

- [ ] **Step 4: Run tests — should pass**

```bash
cd lumino-app && flutter test test/services/sync_service_test.dart
```
Expected: all tests PASS.

- [ ] **Step 5: Run full test suite**

```bash
cd lumino-app && flutter test
```
Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
cd lumino-app && git add lib/services/sync_service.dart test/services/sync_service_test.dart
git commit -m "feat: add mood sync to SyncService (push dirty + pull from API)"
```
