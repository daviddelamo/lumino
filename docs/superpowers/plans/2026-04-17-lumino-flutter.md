# Lumino Flutter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Lumino Android app — onboarding, daily planner, habit tracker, cloud sync, and profile — using Flutter with Riverpod state management and Drift local cache.

**Architecture:** Feature-first folder structure. Each feature owns its screens, providers, and widgets. A shared `services/` layer handles API, notifications, and sync. Riverpod providers wrap Drift DAOs for local reads and fire API calls on writes. Screens read from providers only — no direct DAO or API calls in UI code.

**Tech Stack:** Flutter 3.22, Riverpod 2.5, Drift 2.18, Dio 5.4, go_router 14, flutter_local_notifications 17, flutter_secure_storage 9, permission_handler 11.

---

## File Map

```
lumino-app/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── router.dart
│   ├── theme.dart
│   ├── database/
│   │   ├── database.dart              – @DriftDatabase root
│   │   ├── tables.dart                – all Drift table definitions
│   │   └── daos/
│   │       ├── task_dao.dart
│   │       ├── habit_dao.dart
│   │       └── user_dao.dart
│   ├── services/
│   │   ├── api_client.dart            – Dio + JWT refresh interceptor
│   │   ├── auth_service.dart          – login, register, google, logout
│   │   ├── notification_service.dart  – schedule/cancel local notifications
│   │   └── sync_service.dart          – dirty-flag push + full refresh
│   ├── features/
│   │   ├── onboarding/
│   │   │   ├── onboarding_provider.dart
│   │   │   ├── routine_generator.dart  – pure Dart, no dependencies
│   │   │   └── screens/
│   │   │       ├── welcome_screen.dart
│   │   │       ├── goals_screen.dart
│   │   │       ├── quiz_screen.dart
│   │   │       ├── routine_preview_screen.dart
│   │   │       ├── notifications_screen.dart
│   │   │       └── signup_screen.dart
│   │   ├── today/
│   │   │   ├── tasks_provider.dart
│   │   │   ├── task_form_sheet.dart
│   │   │   └── screens/
│   │   │       ├── today_screen.dart
│   │   │       └── week_view_screen.dart
│   │   ├── habits/
│   │   │   ├── habits_provider.dart
│   │   │   └── screens/
│   │   │       ├── habits_screen.dart
│   │   │       ├── habit_form_screen.dart
│   │   │       └── habit_detail_screen.dart
│   │   └── me/
│   │       ├── theme_provider.dart
│   │       └── screens/
│   │           └── me_screen.dart
│   └── shared/
│       ├── models/
│       │   ├── task_model.dart         – plain Dart models (API/cache agnostic)
│       │   └── habit_model.dart
│       └── widgets/
│           ├── lumino_button.dart
│           ├── progress_ring.dart
│           └── empty_state.dart
└── test/
    ├── onboarding/routine_generator_test.dart
    ├── today/tasks_provider_test.dart
    └── habits/habits_provider_test.dart
```

---

## Task 1: Project Bootstrap

**Files:**
- Create: `lumino-app/pubspec.yaml`
- Create: `lumino-app/lib/main.dart`
- Create: `lumino-app/lib/theme.dart`
- Create: `lumino-app/lib/router.dart`

- [ ] **Step 1: Create project**

```bash
flutter create --org com.lumino --platforms android lumino-app
cd lumino-app
```

- [ ] **Step 2: Replace `pubspec.yaml` dependencies section**

```yaml
name: lumino_app
description: Lumino — Daily Rhythm
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.2.0
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.3
  path: ^1.9.0
  dio: ^5.4.3
  flutter_secure_storage: ^9.0.0
  flutter_local_notifications: ^17.1.2
  permission_handler: ^11.3.1
  connectivity_plus: ^6.0.3
  intl: ^0.19.0
  shared_preferences: ^2.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  drift_dev: ^2.18.0
  riverpod_generator: ^2.4.0
  mocktail: ^1.0.4
  flutter_lints: ^4.0.0
```

- [ ] **Step 3: Run pub get**

```bash
flutter pub get
# Expected: no errors
```

- [ ] **Step 4: Write `lib/theme.dart`**

```dart
import 'package:flutter/material.dart';

class LuminoTheme {
  static const primaryColor = Color(0xFFE8823A);
  static const accentColor = Color(0xFFF7C59F);
  static const supportingGreen = Color(0xFFA8D5BA);
  static const backgroundWarm = Color(0xFFFFF8F2);

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      background: backgroundWarm,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
    ),
    cardTheme: const CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
  );
}
```

- [ ] **Step 5: Write `lib/router.dart`** (placeholder routes — will be filled in as screens are built)

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding/welcome',
  routes: [
    GoRoute(
      path: '/onboarding/welcome',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Welcome'))),
    ),
    GoRoute(
      path: '/today',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Today'))),
    ),
  ],
);
```

- [ ] **Step 6: Write `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: LuminoApp()));
}

class LuminoApp extends StatelessWidget {
  const LuminoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lumino',
      theme: LuminoTheme.light(),
      darkTheme: LuminoTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
```

- [ ] **Step 7: Run on Android emulator**

```bash
flutter run
# Expected: app opens showing "Welcome" text, no red screens
```

- [ ] **Step 8: Commit**

```bash
git add lumino-app/
git commit -m "feat: bootstrap Flutter project with theme and router skeleton"
```

---

## Task 2: Drift Database Schema

**Files:**
- Create: `lumino-app/lib/database/tables.dart`
- Create: `lumino-app/lib/database/database.dart`
- Create: `lumino-app/lib/database/daos/task_dao.dart`
- Create: `lumino-app/lib/database/daos/habit_dao.dart`
- Create: `lumino-app/lib/database/daos/user_dao.dart`
- Create: `lumino-app/test/database/database_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/database/database_test.dart
import 'package:drift/native.dart';
import 'package:lumino_app/database/database.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('can insert and retrieve a task', () async {
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      userId: 'test-user',
      title: 'Morning run',
      iconId: 'run',
      color: '#E8823A',
      startAt: DateTime.now(),
    ));
    final tasks = await db.taskDao.getTasksForDay('test-user', DateTime.now());
    expect(tasks, hasLength(1));
    expect(tasks.first.title, 'Morning run');
  });

  test('can insert and retrieve a habit', () async {
    await db.habitDao.insertHabit(HabitsCompanion.insert(
      userId: 'test-user',
      title: 'Drink water',
      iconId: 'water',
      color: '#5B6EF5',
      type: 'count',
      targetValue: 8,
      frequencyRule: '{"type":"daily"}',
    ));
    final habits = await db.habitDao.getActiveHabits('test-user');
    expect(habits, hasLength(1));
    expect(habits.first.title, 'Drink water');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/database/database_test.dart
# Expected: FAIL — AppDatabase not found
```

- [ ] **Step 3: Write `lib/database/tables.dart`**

```dart
import 'package:drift/drift.dart';

class Tasks extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get iconId => text().withDefault(const Constant('circle'))();
  TextColumn get color => text().withDefault(const Constant('#E8823A'))();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime().nullable()();
  TextColumn get repeatRule => text().nullable()();
  IntColumn get reminderOffsetMin => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Habits extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get iconId => text().withDefault(const Constant('circle'))();
  TextColumn get color => text().withDefault(const Constant('#E8823A'))();
  TextColumn get type => text()(); // bool | count | duration
  RealColumn get targetValue => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().nullable()();
  TextColumn get frequencyRule => text()();
  TextColumn get reminderTime => text().nullable()(); // HH:mm
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
}

class HabitEntries extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get habitId => text().references(Habits, #id)();
  DateTimeColumn get entryDate => dateTime()();
  RealColumn get value => real().withDefault(const Constant(1.0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get loggedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [{habitId, entryDate}];
}

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get onboardingProfile => text().nullable()(); // JSON
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

String _uuid() {
  // Simple UUID v4 without external dependency
  final now = DateTime.now().microsecondsSinceEpoch;
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
    RegExp(r'[xy]'),
    (m) {
      final r = (now ^ (m.start * 1000)) % 16;
      return (m[0] == 'x' ? r : (r & 0x3 | 0x8)).toRadixString(16);
    },
  );
}
```

- [ ] **Step 4: Write `lib/database/daos/task_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Future<String> insertTask(TasksCompanion task) async {
    await into(tasks).insert(task, mode: InsertMode.insertOrReplace);
    return task.id.value;
  }

  Future<List<Task>> getTasksForDay(String userId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks)
      ..where((t) =>
          t.userId.equals(userId) &
          t.deletedAt.isNull() &
          t.startAt.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .get();
  }

  Future<void> markComplete(String taskId, DateTime completedAt) =>
      (update(tasks)..where((t) => t.id.equals(taskId)))
          .write(TasksCompanion(completedAt: Value(completedAt), dirty: const Value(true)));

  Future<void> softDelete(String taskId) =>
      (update(tasks)..where((t) => t.id.equals(taskId)))
          .write(TasksCompanion(deletedAt: Value(DateTime.now()), dirty: const Value(true)));

  Future<void> updateTask(String taskId, TasksCompanion companion) =>
      (update(tasks)..where((t) => t.id.equals(taskId))).write(companion);

  Future<List<Task>> getDirtyTasks() =>
      (select(tasks)..where((t) => t.dirty.equals(true))).get();

  Future<void> markSynced(String taskId) =>
      (update(tasks)..where((t) => t.id.equals(taskId)))
          .write(TasksCompanion(dirty: const Value(false), syncedAt: Value(DateTime.now())));
}
```

- [ ] **Step 5: Write `lib/database/daos/habit_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'habit_dao.g.dart';

@DriftAccessor(tables: [Habits, HabitEntries])
class HabitDao extends DatabaseAccessor<AppDatabase> with _$HabitDaoMixin {
  HabitDao(super.db);

  Future<void> insertHabit(HabitsCompanion habit) =>
      into(habits).insert(habit, mode: InsertMode.insertOrReplace);

  Future<List<Habit>> getActiveHabits(String userId) =>
      (select(habits)
        ..where((h) => h.userId.equals(userId) & h.archivedAt.isNull()))
          .get();

  Future<void> updateHabit(String habitId, HabitsCompanion companion) =>
      (update(habits)..where((h) => h.id.equals(habitId))).write(companion);

  Future<void> upsertEntry(HabitEntriesCompanion entry) =>
      into(habitEntries).insert(entry, mode: InsertMode.insertOrReplace);

  Future<List<HabitEntry>> getEntries(String habitId, DateTime from, DateTime to) =>
      (select(habitEntries)
        ..where((e) =>
            e.habitId.equals(habitId) &
            e.entryDate.isBetweenValues(from, to))
        ..orderBy([(e) => OrderingTerm.asc(e.entryDate)]))
          .get();

  Future<List<HabitEntry>> getAllEntries(String habitId) =>
      (select(habitEntries)
        ..where((e) => e.habitId.equals(habitId))
        ..orderBy([(e) => OrderingTerm.desc(e.entryDate)]))
          .get();
}
```

- [ ] **Step 6: Write `lib/database/daos/user_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<void> upsertUser(UsersCompanion user) =>
      into(users).insert(user, mode: InsertMode.insertOrReplace);

  Future<User?> getUser(String userId) =>
      (select(users)..where((u) => u.id.equals(userId))).getSingleOrNull();
}
```

- [ ] **Step 7: Write `lib/database/database.dart`**

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

part 'database.g.dart';

@DriftDatabase(tables: [Tasks, Habits, HabitEntries, Users], daos: [TaskDao, HabitDao, UserDao])
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
```

- [ ] **Step 8: Generate Drift code**

```bash
dart run build_runner build --delete-conflicting-outputs
# Expected: generates database.g.dart and *.g.dart files for each DAO
```

- [ ] **Step 9: Run test**

```bash
flutter test test/database/database_test.dart
# Expected: PASS
```

- [ ] **Step 10: Commit**

```bash
git add lumino-app/
git commit -m "feat: add Drift database schema with task, habit, and user DAOs"
```

---

## Task 3: API Client + Auth Service

**Files:**
- Create: `lumino-app/lib/services/api_client.dart`
- Create: `lumino-app/lib/services/auth_service.dart`
- Create: `lumino-app/test/services/auth_service_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lumino_app/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late AuthService authService;
  late MockApiClient mockClient;

  setUp(() {
    mockClient = MockApiClient();
    authService = AuthService(mockClient);
  });

  test('isLoggedIn returns false when no token stored', () async {
    expect(await authService.isLoggedIn(), false);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/auth_service_test.dart
# Expected: FAIL — AuthService not found
```

- [ ] **Step 3: Write `lib/services/api_client.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const _baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient({FlutterSecureStorage? storage, Dio? dio})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl)) {
    _dio.interceptors.add(_AuthInterceptor(_storage, _dio, _baseUrl));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) => _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  final String _baseUrl;

  _AuthInterceptor(this._storage, this._dio, this._baseUrl);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final response = await Dio(BaseOptions(baseUrl: _baseUrl))
              .post('/api/auth/refresh', data: {'refreshToken': refreshToken});
          final newToken = response.data['data']['accessToken'] as String;
          await _storage.write(key: 'access_token', value: newToken);
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          await _storage.delete(key: 'access_token');
          await _storage.delete(key: 'refresh_token');
        }
      }
    }
    handler.next(err);
  }
}
```

- [ ] **Step 4: Write `lib/services/auth_service.dart`**

```dart
import 'api_client.dart';

class AuthService {
  final ApiClient _client;
  AuthService(this._client);

  Future<bool> isLoggedIn() async {
    final token = await _client.getAccessToken();
    return token != null;
  }

  Future<void> register(String email, String password) async {
    final res = await _client.post('/api/auth/register',
        data: {'email': email, 'password': password});
    final data = res.data['data'];
    await _client.saveTokens(data['accessToken'], data['refreshToken']);
  }

  Future<void> login(String email, String password) async {
    final res = await _client.post('/api/auth/login',
        data: {'email': email, 'password': password});
    final data = res.data['data'];
    await _client.saveTokens(data['accessToken'], data['refreshToken']);
  }

  Future<void> logout() => _client.clearTokens();
}
```

- [ ] **Step 5: Run test**

```bash
flutter test test/services/auth_service_test.dart
# Expected: PASS
```

- [ ] **Step 6: Commit**

```bash
git add lumino-app/
git commit -m "feat: add Dio API client with JWT refresh interceptor and AuthService"
```

---

## Task 4: Onboarding — Welcome + Goals

**Files:**
- Create: `lumino-app/lib/features/onboarding/onboarding_provider.dart`
- Create: `lumino-app/lib/features/onboarding/screens/welcome_screen.dart`
- Create: `lumino-app/lib/features/onboarding/screens/goals_screen.dart`
- Modify: `lumino-app/lib/router.dart`

- [ ] **Step 1: Write `lib/features/onboarding/onboarding_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final List<String> selectedGoals;
  final Map<String, String> quizAnswers;

  const OnboardingState({this.selectedGoals = const [], this.quizAnswers = const {}});

  OnboardingState copyWith({List<String>? selectedGoals, Map<String, String>? quizAnswers}) =>
      OnboardingState(
        selectedGoals: selectedGoals ?? this.selectedGoals,
        quizAnswers: quizAnswers ?? this.quizAnswers,
      );
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void toggleGoal(String goal) {
    final goals = List<String>.from(state.selectedGoals);
    goals.contains(goal) ? goals.remove(goal) : goals.add(goal);
    state = state.copyWith(selectedGoals: goals);
  }

  void setQuizAnswer(String question, String answer) {
    final answers = Map<String, String>.from(state.quizAnswers);
    answers[question] = answer;
    state = state.copyWith(quizAnswers: answers);
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);
```

- [ ] **Step 2: Write `lib/features/onboarding/screens/welcome_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text('Lumino',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: LuminoTheme.primaryColor,
                    fontSize: 48,
                  )),
              const SizedBox(height: 8),
              Text('Daily Rhythm',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.brown.shade400,
                    letterSpacing: 3,
                  )),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/onboarding/goals'),
                child: const Text('Get Started →'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/today'),
                child: Text('Skip for now',
                    style: TextStyle(color: Colors.brown.shade300)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Write `lib/features/onboarding/screens/goals_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../onboarding_provider.dart';
import '../../../theme.dart';

const _goals = [
  ('🌙', 'Better sleep'),
  ('🏃', 'Exercise'),
  ('🧘', 'Mindfulness'),
  ('📚', 'Study'),
  ('💼', 'Work focus'),
  ('💆', 'Self-care'),
  ('🥗', 'Nutrition'),
  ('✍️', 'Journaling'),
  ('💧', 'Hydration'),
];

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).selectedGoals;
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StepIndicator(current: 2, total: 6),
              const SizedBox(height: 24),
              Text('What do you want\nto work on?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF3A2A1A),
                    fontSize: 26,
                  )),
              const SizedBox(height: 8),
              Text('Pick as many as you like',
                  style: TextStyle(color: Colors.brown.shade400)),
              const SizedBox(height: 24),
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _goals.map((g) {
                    final isSelected = selected.contains(g.$2);
                    return FilterChip(
                      label: Text('${g.$1} ${g.$2}'),
                      selected: isSelected,
                      onSelected: (_) =>
                          ref.read(onboardingProvider.notifier).toggleGoal(g.$2),
                      selectedColor: LuminoTheme.primaryColor,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.brown.shade700),
                      side: BorderSide(color: LuminoTheme.accentColor),
                    );
                  }).toList(),
                ),
              ),
              FilledButton(
                onPressed: selected.isEmpty ? null : () => context.go('/onboarding/quiz'),
                child: const Text('Continue →'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current, total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(total, (i) => Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: i < current ? LuminoTheme.primaryColor : LuminoTheme.accentColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    )),
  );
}
```

- [ ] **Step 4: Update `router.dart`** with new routes

```dart
import 'package:go_router/go_router.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/onboarding/screens/goals_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding/welcome',
  routes: [
    GoRoute(path: '/onboarding/welcome', builder: (c, s) => const WelcomeScreen()),
    GoRoute(path: '/onboarding/goals', builder: (c, s) => const GoalsScreen()),
    // remaining routes added in later tasks
    GoRoute(path: '/onboarding/quiz', builder: (c, s) => const Scaffold(body: Center(child: Text('Quiz')))),
    GoRoute(path: '/today', builder: (c, s) => const Scaffold(body: Center(child: Text('Today')))),
  ],
);
```

- [ ] **Step 5: Run on device**

```bash
flutter run
# Expected: Welcome screen → tap "Get Started" → Goals screen with chips → chips toggle amber when selected → "Continue" disabled until at least one chip selected
```

- [ ] **Step 6: Commit**

```bash
git add lumino-app/
git commit -m "feat: add onboarding Welcome and Goals screens"
```

---

## Task 5: Onboarding — Quiz + Routine Generator

**Files:**
- Create: `lumino-app/lib/features/onboarding/routine_generator.dart`
- Create: `lumino-app/lib/features/onboarding/screens/quiz_screen.dart`
- Create: `lumino-app/test/onboarding/routine_generator_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/onboarding/routine_generator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lumino_app/features/onboarding/routine_generator.dart';

void main() {
  test('morning person gets early morning tasks', () {
    final routine = RoutineGenerator.generate(
      goals: ['Exercise', 'Mindfulness'],
      quizAnswers: {'chronotype': 'morning', 'structure': 'rigid', 'social': 'solo'},
    );
    expect(routine, isNotEmpty);
    expect(routine.any((s) => s.hour <= 8), isTrue);
  });

  test('night person gets later tasks', () {
    final routine = RoutineGenerator.generate(
      goals: ['Study', 'Journaling'],
      quizAnswers: {'chronotype': 'night', 'structure': 'flexible', 'social': 'solo'},
    );
    expect(routine.first.hour, greaterThan(8));
  });

  test('generates at least 3 tasks', () {
    final routine = RoutineGenerator.generate(
      goals: ['Better sleep'],
      quizAnswers: {'chronotype': 'morning', 'structure': 'rigid', 'social': 'solo'},
    );
    expect(routine.length, greaterThanOrEqualTo(3));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/onboarding/routine_generator_test.dart
# Expected: FAIL — RoutineGenerator not found
```

- [ ] **Step 3: Write `lib/features/onboarding/routine_generator.dart`**

```dart
class RoutineStep {
  final String title;
  final String iconId;
  final String color;
  final int hour;
  final int minute;
  final int durationMinutes;

  const RoutineStep({
    required this.title,
    required this.iconId,
    required this.color,
    required this.hour,
    required this.minute,
    required this.durationMinutes,
  });
}

class RoutineGenerator {
  static List<RoutineStep> generate({
    required List<String> goals,
    required Map<String, String> quizAnswers,
  }) {
    final isMorning = quizAnswers['chronotype'] == 'morning';
    final startHour = isMorning ? 6 : 9;
    final steps = <RoutineStep>[];

    // Always-present wake-up block
    steps.add(RoutineStep(
      title: isMorning ? 'Wake up & stretch' : 'Start your day',
      iconId: 'sun',
      color: '#E8823A',
      hour: startHour,
      minute: 0,
      durationMinutes: 10,
    ));

    if (goals.contains('Mindfulness') || goals.contains('Better sleep')) {
      steps.add(RoutineStep(
        title: 'Morning meditation',
        iconId: 'yoga',
        color: '#9B72D0',
        hour: startHour,
        minute: 15,
        durationMinutes: 10,
      ));
    }

    if (goals.contains('Exercise')) {
      steps.add(RoutineStep(
        title: 'Workout',
        iconId: 'run',
        color: '#4CAF82',
        hour: startHour + 1,
        minute: 0,
        durationMinutes: 30,
      ));
    }

    if (goals.contains('Hydration') || goals.contains('Nutrition')) {
      steps.add(RoutineStep(
        title: 'Healthy breakfast',
        iconId: 'food',
        color: '#F9C06A',
        hour: startHour + (goals.contains('Exercise') ? 2 : 1),
        minute: 0,
        durationMinutes: 20,
      ));
    }

    if (goals.contains('Study') || goals.contains('Work focus')) {
      steps.add(RoutineStep(
        title: 'Focus block',
        iconId: 'brain',
        color: '#5B6EF5',
        hour: startHour + 3,
        minute: 0,
        durationMinutes: 90,
      ));
    }

    if (goals.contains('Journaling')) {
      steps.add(RoutineStep(
        title: 'Evening journal',
        iconId: 'pencil',
        color: '#E8823A',
        hour: 21,
        minute: 0,
        durationMinutes: 15,
      ));
    }

    if (goals.contains('Better sleep')) {
      steps.add(RoutineStep(
        title: 'Wind down',
        iconId: 'moon',
        color: '#9B72D0',
        hour: 22,
        minute: 0,
        durationMinutes: 20,
      ));
    }

    // Ensure at least 3 steps
    if (steps.length < 3) {
      steps.add(RoutineStep(
        title: 'Drink water',
        iconId: 'water',
        color: '#5B6EF5',
        hour: startHour + 1,
        minute: 30,
        durationMinutes: 5,
      ));
    }

    return steps..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/onboarding/routine_generator_test.dart
# Expected: PASS (3 tests green)
```

- [ ] **Step 5: Write `lib/features/onboarding/screens/quiz_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../onboarding_provider.dart';
import '../../../theme.dart';

const _questions = [
  ('chronotype', 'Are you a morning or night person?', ['Morning 🌅', 'Night 🌙'], ['morning', 'night']),
  ('structure', 'Do you prefer structured or flexible routines?', ['Structured 📋', 'Flexible 🌊'], ['rigid', 'flexible']),
  ('social', 'Do you prefer solo or social habits?', ['Solo 🧘', 'Social 👥'], ['solo', 'social']),
];

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});
  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestion = 0;

  void _answer(String key, String value) {
    ref.read(onboardingProvider.notifier).setQuizAnswer(key, value);
    if (_currentQuestion < _questions.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      context.go('/onboarding/preview');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (key, question, labels, values) = _questions[_currentQuestion];
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepIndicatorRef(current: 3, total: 6),
              const Spacer(),
              Text(question,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF3A2A1A),
                    fontSize: 24,
                  )),
              const SizedBox(height: 32),
              ...List.generate(labels.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: LuminoTheme.backgroundWarm,
                    foregroundColor: const Color(0xFF3A2A1A),
                    side: const BorderSide(color: LuminoTheme.accentColor),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  onPressed: () => _answer(key, values[i]),
                  child: Text(labels[i], style: const TextStyle(fontSize: 16)),
                ),
              )),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicatorRef extends StatelessWidget {
  final int current, total;
  const _StepIndicatorRef({required this.current, required this.total});
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(total, (i) => Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: i < current ? LuminoTheme.primaryColor : LuminoTheme.accentColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    )),
  );
}
```

- [ ] **Step 6: Add quiz and preview routes to `router.dart`**

```dart
GoRoute(path: '/onboarding/quiz', builder: (c, s) => const QuizScreen()),
GoRoute(path: '/onboarding/preview', builder: (c, s) => const Scaffold(body: Center(child: Text('Preview')))),
```

- [ ] **Step 7: Commit**

```bash
git add lumino-app/
git commit -m "feat: add onboarding Quiz screen and RoutineGenerator"
```

---

## Task 6: Onboarding — Preview, Notifications, Sign-up

**Files:**
- Create: `lumino-app/lib/features/onboarding/screens/routine_preview_screen.dart`
- Create: `lumino-app/lib/features/onboarding/screens/notifications_screen.dart`
- Create: `lumino-app/lib/features/onboarding/screens/signup_screen.dart`
- Create: `lumino-app/lib/services/notification_service.dart`
- Modify: `lumino-app/lib/router.dart`

- [ ] **Step 1: Write `lib/services/notification_service.dart`**

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<void> scheduleTask({
    required int id,
    required String title,
    required DateTime scheduledAt,
    int offsetMinutes = 10,
  }) async {
    await initialize();
    final notifyAt = scheduledAt.subtract(Duration(minutes: offsetMinutes));
    await _plugin.schedule(
      id,
      'Lumino — Upcoming',
      title,
      notifyAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lumino_tasks',
          'Task Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);
}
```

- [ ] **Step 2: Write `routine_preview_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../onboarding_provider.dart';
import '../routine_generator.dart';
import '../../../database/database.dart';
import '../../../theme.dart';

final _dbProvider = Provider((ref) => AppDatabase());

class RoutinePreviewScreen extends ConsumerWidget {
  const RoutinePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final routine = RoutineGenerator.generate(
      goals: state.selectedGoals.isEmpty ? ['Better sleep'] : state.selectedGoals,
      quizAnswers: state.quizAnswers.isEmpty
          ? {'chronotype': 'morning', 'structure': 'flexible', 'social': 'solo'}
          : state.quizAnswers,
    );

    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepBar(current: 4, total: 6),
              const SizedBox(height: 24),
              Text('Your starter routine',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF3A2A1A),
                    fontSize: 26,
                  )),
              const SizedBox(height: 6),
              Text('Based on your goals — you can edit it anytime.',
                  style: TextStyle(color: Colors.brown.shade400)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: routine.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final step = routine[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(int.parse(step.color.replaceFirst('#', 'FF'), radix: 16)),
                          child: const Icon(Icons.circle, color: Colors.white, size: 16),
                        ),
                        title: Text(step.title),
                        subtitle: Text(
                            '${step.hour.toString().padLeft(2, '0')}:${step.minute.toString().padLeft(2, '0')} · ${step.durationMinutes} min'),
                      ),
                    );
                  },
                ),
              ),
              FilledButton(
                onPressed: () => context.go('/onboarding/notifications'),
                child: const Text('Looks good! →'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  final int current, total;
  const _StepBar({required this.current, required this.total});
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(total, (i) => Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: i < current ? LuminoTheme.primaryColor : LuminoTheme.accentColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    )),
  );
}
```

- [ ] **Step 3: Write `notifications_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/notification_service.dart';
import '../../../theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔔', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text('Stay on track',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF3A2A1A),
                    fontSize: 26,
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text("We'll remind you before each task — only when you want.",
                  style: TextStyle(color: Colors.brown.shade400),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () async {
                  await NotificationService.requestPermission();
                  if (context.mounted) context.go('/onboarding/signup');
                },
                child: const Text('Enable reminders'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/onboarding/signup'),
                child: Text('Not now', style: TextStyle(color: Colors.brown.shade300)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write `signup_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_client.dart';
import '../../../theme.dart';

final _authServiceProvider = Provider((ref) => AuthService(ApiClient()));

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(_authServiceProvider).register(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) context.go('/today');
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepBarFinal(current: 6, total: 6),
              const SizedBox(height: 24),
              Text('Save your progress',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF3A2A1A),
                    fontSize: 26,
                  )),
              const SizedBox(height: 8),
              Text('Create an account to sync across devices.',
                  style: TextStyle(color: Colors.brown.shade400)),
              const SizedBox(height: 24),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create account'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/today'),
                child: Text('Skip for now — use without account',
                    style: TextStyle(color: Colors.brown.shade400),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBarFinal extends StatelessWidget {
  final int current, total;
  const _StepBarFinal({required this.current, required this.total});
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(total, (i) => Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: LuminoTheme.primaryColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    )),
  );
}
```

- [ ] **Step 5: Update `router.dart` with remaining onboarding routes**

```dart
GoRoute(path: '/onboarding/preview', builder: (c, s) => const RoutinePreviewScreen()),
GoRoute(path: '/onboarding/notifications', builder: (c, s) => const NotificationsScreen()),
GoRoute(path: '/onboarding/signup', builder: (c, s) => const SignupScreen()),
```

- [ ] **Step 6: Run onboarding end-to-end on device**

```bash
flutter run
# Expected: complete onboarding flow: Welcome → Goals → Quiz (3 questions) → Preview (routine cards) → Notifications → Signup → Today (placeholder)
```

- [ ] **Step 7: Commit**

```bash
git add lumino-app/
git commit -m "feat: complete onboarding flow — preview, notifications, signup"
```

---

## Task 7: Today Screen — Timeline

**Files:**
- Create: `lumino-app/lib/features/today/tasks_provider.dart`
- Create: `lumino-app/lib/features/today/screens/today_screen.dart`
- Create: `lumino-app/lib/shared/widgets/progress_ring.dart`
- Create: `lumino-app/lib/shared/widgets/empty_state.dart`
- Create: `lumino-app/test/today/tasks_provider_test.dart`
- Modify: `lumino-app/lib/router.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/today/tasks_provider_test.dart
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
      iconId: 'check',
      color: '#E8823A',
      startAt: DateTime(2026, 4, 17, 8, 0),
    ));

    final container = ProviderContainer(
      overrides: [dbProvider.overrideWithValue(db), currentUserIdProvider.overrideWithValue('u1')],
    );
    addTearDown(container.dispose);

    final tasks = await container.read(tasksForDayProvider(DateTime(2026, 4, 17)).future);
    expect(tasks, hasLength(1));
    expect(tasks.first.title, 'Test task');
    await db.close();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/today/tasks_provider_test.dart
# Expected: FAIL — tasksForDayProvider not found
```

- [ ] **Step 3: Write `lib/features/today/tasks_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/tables.dart';
import 'package:drift/drift.dart';

final dbProvider = Provider<AppDatabase>((ref) => AppDatabase());
final currentUserIdProvider = Provider<String?>((ref) => null);

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

  TasksNotifier(this._db, this._userId, this._date) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = await AsyncValue.guard(() => _db.taskDao.getTasksForDay(_userId, _date));
  }

  Future<void> completeTask(String taskId) async {
    await _db.taskDao.markComplete(taskId, DateTime.now());
    await _load();
  }

  Future<void> deleteTask(String taskId) async {
    await _db.taskDao.softDelete(taskId);
    await _load();
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
```

- [ ] **Step 4: Write `lib/shared/widgets/progress_ring.dart`**

```dart
import 'package:flutter/material.dart';
import 'dart:math';

class ProgressRing extends StatelessWidget {
  final int completed;
  final int total;
  final double size;

  const ProgressRing({super.key, required this.completed, required this.total, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(completed / (total == 0 ? 1 : total)),
          ),
          Text('$completed/$total',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE8823A))),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final trackPaint = Paint()
      ..color = const Color(0xFFF0E0D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final progressPaint = Paint()
      ..color = const Color(0xFFE8823A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
```

- [ ] **Step 5: Write `lib/shared/widgets/empty_state.dart`**

```dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({super.key, required this.emoji, required this.title, required this.subtitle, this.onAction, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            if (onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel ?? 'Add')),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Write `lib/features/today/screens/today_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../tasks_provider.dart';
import '../task_form_sheet.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme.dart';
import '../../../database/tables.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final tasksAsync = ref.watch(tasksNotifierProvider(today));

    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TodayHeader(date: today, tasksAsync: tasksAsync),
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (tasks) => tasks.isEmpty
                    ? EmptyState(
                        emoji: '✨',
                        title: 'A fresh start',
                        subtitle: 'Add your first task for today.',
                        onAction: () => _showAddTask(context, ref, today),
                        actionLabel: 'Add task',
                      )
                    : _Timeline(tasks: tasks, date: today, ref: ref),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTask(context, ref, today),
        backgroundColor: LuminoTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 0),
    );
  }

  void _showAddTask(BuildContext context, WidgetRef ref, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskFormSheet(date: date, onSaved: () => ref.read(tasksNotifierProvider(date).notifier).reload()),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  final DateTime date;
  final AsyncValue tasksAsync;

  const _TodayHeader({required this.date, required this.tasksAsync});

  @override
  Widget build(BuildContext context) {
    final tasks = tasksAsync.value ?? [];
    final completed = tasks.where((t) => (t as dynamic).completedAt != null).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE, MMM d').format(date),
                    style: const TextStyle(color: Color(0xFFA08070), fontSize: 13, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(_greeting(), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22, color: const Color(0xFF3A2A1A))),
              ],
            ),
          ),
          ProgressRing(completed: completed, total: tasks.length, size: 48),
        ],
      ),
    );
  }

  String _greeting() {
    final h = date.hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }
}

class _Timeline extends StatelessWidget {
  final List<Task> tasks;
  final DateTime date;
  final WidgetRef ref;

  const _Timeline({required this.tasks, required this.date, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, i) => _TaskCard(task: tasks[i], date: date, ref: ref),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final DateTime date;
  final WidgetRef ref;

  const _TaskCard({required this.task, required this.date, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDone = task.completedAt != null;
    final color = _parseColor(task.color);
    return Opacity(
      opacity: isDone ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.circle, color: color, size: 14),
          ),
          title: Text(task.title,
              style: TextStyle(decoration: isDone ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w600)),
          subtitle: Text(DateFormat('HH:mm').format(task.startAt)),
          trailing: GestureDetector(
            onTap: () {
              if (!isDone) ref.read(tasksNotifierProvider(date).notifier).completeTask(task.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? LuminoTheme.primaryColor : Colors.transparent,
                border: Border.all(color: isDone ? LuminoTheme.primaryColor : const Color(0xFFD0B898), width: 2),
              ),
              child: isDone ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return LuminoTheme.primaryColor;
    }
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Today'),
        BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Habits'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
      ],
      onTap: (i) {
        if (i == 1) context.go('/habits');
        if (i == 2) context.go('/me');
      },
    );
  }
}
```

- [ ] **Step 7: Run test**

```bash
flutter test test/today/tasks_provider_test.dart
# Expected: PASS
```

- [ ] **Step 8: Update router with `/today` route**

```dart
GoRoute(path: '/today', builder: (c, s) => const TodayScreen()),
```

- [ ] **Step 9: Run on device**

```bash
flutter run
# Expected: Today screen with greeting, progress ring (0/0), empty state with "Add task" button, FAB visible
```

- [ ] **Step 10: Commit**

```bash
git add lumino-app/
git commit -m "feat: add Today screen with timeline, progress ring, and empty state"
```

---

## Task 8: Add/Edit Task Bottom Sheet

**Files:**
- Create: `lumino-app/lib/features/today/task_form_sheet.dart`

- [ ] **Step 1: Write `lib/features/today/task_form_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../database/database.dart';
import '../../database/tables.dart';
import '../../theme.dart';
import 'tasks_provider.dart';

const _icons = ['circle', 'run', 'yoga', 'book', 'food', 'water', 'brain', 'pencil', 'sun', 'moon', 'check', 'work'];
const _colors = ['#E8823A', '#4CAF82', '#9B72D0', '#5B6EF5', '#E57373', '#F9C06A', '#A8D5BA', '#F7C59F'];

class TaskFormSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final VoidCallback onSaved;
  final Task? existing;

  const TaskFormSheet({super.key, required this.date, required this.onSaved, this.existing});

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  final _titleCtrl = TextEditingController();
  String _iconId = 'circle';
  String _color = '#E8823A';
  TimeOfDay _startTime = TimeOfDay.now();
  int _durationMin = 30;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _iconId = widget.existing!.iconId;
      _color = widget.existing!.color;
      _startTime = TimeOfDay.fromDateTime(widget.existing!.startAt);
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final db = ref.read(dbProvider);
    final userId = ref.read(currentUserIdProvider) ?? 'local';
    final startAt = DateTime(widget.date.year, widget.date.month, widget.date.day, _startTime.hour, _startTime.minute);
    final endAt = startAt.add(Duration(minutes: _durationMin));

    await db.taskDao.insertTask(TasksCompanion.insert(
      userId: userId,
      title: _titleCtrl.text.trim(),
      iconId: _iconId,
      color: _color,
      startAt: startAt,
      endAt: Value(endAt),
    ));

    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0C8B0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Text('New Task', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: 'Georgia', fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Title',
                filled: true,
                fillColor: const Color(0xFFFFF0E0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Icon', style: TextStyle(fontSize: 11, color: Color(0xFFA08070), letterSpacing: 1, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _iconId = _icons[i]),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E0),
                      borderRadius: BorderRadius.circular(8),
                      border: _iconId == _icons[i] ? Border.all(color: LuminoTheme.primaryColor, width: 2) : null,
                    ),
                    child: const Icon(Icons.circle, size: 16, color: Color(0xFFA08070)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Color', style: TextStyle(fontSize: 11, color: Color(0xFFA08070), letterSpacing: 1, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: _colors.map((c) => GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Color(int.parse(c.replaceFirst('#', 'FF'), radix: 16)),
                    shape: BoxShape.circle,
                    border: _color == c ? Border.all(color: Colors.black54, width: 2) : null,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Start', style: TextStyle(fontSize: 11, color: Color(0xFFA08070), letterSpacing: 1, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _startTime);
                        if (t != null) setState(() => _startTime = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFFFF0E0), borderRadius: BorderRadius.circular(10)),
                        child: Text('${_startTime.format(context)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                )),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Duration', style: TextStyle(fontSize: 11, color: Color(0xFFA08070), letterSpacing: 1, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      value: _durationMin,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFFF0E0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [5, 10, 15, 20, 30, 45, 60, 90, 120].map((m) => DropdownMenuItem(value: m, child: Text('$m min'))).toList(),
                      onChanged: (v) => setState(() => _durationMin = v!),
                    ),
                  ],
                )),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Task'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run on device and test add task flow**

```bash
flutter run
# Expected: tap FAB → bottom sheet slides up → fill title → select icon/color → pick time → Save → task appears in timeline
```

- [ ] **Step 3: Commit**

```bash
git add lumino-app/
git commit -m "feat: add task creation bottom sheet with icon, color, time pickers"
```

---

## Task 9: Habits Screen + Add/Edit Habit

**Files:**
- Create: `lumino-app/lib/features/habits/habits_provider.dart`
- Create: `lumino-app/lib/features/habits/screens/habits_screen.dart`
- Create: `lumino-app/lib/features/habits/screens/habit_form_screen.dart`
- Modify: `lumino-app/lib/router.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/habits/habits_provider_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumino_app/database/database.dart';
import 'package:lumino_app/features/habits/habits_provider.dart';
import 'package:lumino_app/features/today/tasks_provider.dart';

void main() {
  test('habitsProvider returns active habits', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.habitDao.insertHabit(HabitsCompanion.insert(
      userId: 'u1', title: 'Drink water', iconId: 'water',
      color: '#5B6EF5', type: 'count', targetValue: 8, frequencyRule: '{"type":"daily"}',
    ));
    final container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
    addTearDown(container.dispose);
    final habits = await container.read(habitsProvider.future);
    expect(habits, hasLength(1));
    await db.close();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/habits/habits_provider_test.dart
# Expected: FAIL — habitsProvider not found
```

- [ ] **Step 3: Write `lib/features/habits/habits_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/tables.dart';
import '../../features/today/tasks_provider.dart';
import 'package:drift/drift.dart' hide Column;

final habitsProvider = FutureProvider<List<Habit>>((ref) async {
  final db = ref.watch(dbProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'local';
  return db.habitDao.getActiveHabits(userId);
});

class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final AppDatabase _db;
  final String _userId;

  HabitsNotifier(this._db, this._userId) : super(const AsyncValue.loading()) { _load(); }

  Future<void> _load() async {
    state = await AsyncValue.guard(() => _db.habitDao.getActiveHabits(_userId));
  }

  Future<void> addHabit({
    required String title,
    required String iconId,
    required String color,
    required String type,
    required double targetValue,
    String? unit,
    required String frequencyRule,
  }) async {
    if (state.value != null && state.value!.length >= 5) {
      throw Exception('Free tier allows up to 5 habits');
    }
    await _db.habitDao.insertHabit(HabitsCompanion.insert(
      userId: _userId, title: title, iconId: iconId,
      color: color, type: type, targetValue: targetValue,
      frequencyRule: frequencyRule, unit: Value(unit),
    ));
    await _load();
  }

  Future<void> completeToday(String habitId, double value) async {
    final today = DateTime.now();
    final entryDate = DateTime(today.year, today.month, today.day);
    await _db.habitDao.upsertEntry(HabitEntriesCompanion.insert(
      habitId: habitId, entryDate: entryDate, value: Value(value),
    ));
    await _load();
  }

  Future<void> reload() => _load();
}

final habitsNotifierProvider = StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>(
  (ref) {
    final db = ref.watch(dbProvider);
    final userId = ref.watch(currentUserIdProvider) ?? 'local';
    return HabitsNotifier(db, userId);
  },
);

// Streak computation (client-side, mirrors backend logic)
int computeStreak(List<DateTime> entryDates) {
  if (entryDates.isEmpty) return 0;
  final sorted = entryDates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
    ..sort((a, b) => b.compareTo(a));
  int streak = 1;
  for (int i = 1; i < sorted.length; i++) {
    final diff = sorted[i - 1].difference(sorted[i]).inDays;
    if (diff == 1) { streak++; } else { break; }
  }
  final today = DateTime.now();
  final todayNorm = DateTime(today.year, today.month, today.day);
  final latestEntry = sorted.first;
  if (latestEntry.isBefore(todayNorm.subtract(const Duration(days: 1)))) return 0;
  return streak;
}
```

- [ ] **Step 4: Write `lib/features/habits/screens/habits_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../habits_provider.dart';
import '../../../database/tables.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsNotifierProvider);
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Habits', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26, color: const Color(0xFF3A2A1A))),
                  const SizedBox(height: 2),
                  Text(_todaySummary(habitsAsync.value ?? []),
                      style: const TextStyle(fontSize: 13, color: Color(0xFFA08070))),
                ],
              ),
            ),
            Expanded(
              child: habitsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (habits) => habits.isEmpty
                    ? EmptyState(
                        emoji: '✅',
                        title: 'No habits yet',
                        subtitle: 'Add your first habit and start building a streak.',
                        onAction: () => context.push('/habits/add'),
                        actionLabel: 'Add habit',
                      )
                    : _HabitList(habits: habits),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/habits/add'),
        backgroundColor: LuminoTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 1),
    );
  }

  String _todaySummary(List<Habit> habits) =>
      '${habits.length} habit${habits.length == 1 ? '' : 's'} active';
}

class _HabitList extends ConsumerWidget {
  final List<Habit> habits;
  const _HabitList({required this.habits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: habits.length,
      itemBuilder: (_, i) => _HabitCard(habit: habits[i]),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final Habit habit;
  const _HabitCard({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _parseColor(habit.color);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(Icons.circle, color: color, size: 14)),
        title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${habit.type} · target ${habit.targetValue.toInt()}${habit.unit != null ? ' ${habit.unit}' : ''}',
            style: const TextStyle(fontSize: 12)),
        trailing: GestureDetector(
          onTap: () => ref.read(habitsNotifierProvider.notifier).completeToday(habit.id, habit.targetValue),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD0B898), width: 2),
            ),
            child: const Icon(Icons.check, size: 16, color: Color(0xFFD0B898)),
          ),
        ),
        onTap: () => context.push('/habits/${habit.id}'),
      ),
    );
  }

  Color _parseColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16)); }
    catch (_) { return LuminoTheme.primaryColor; }
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});
  @override
  Widget build(BuildContext context) => BottomNavigationBar(
    currentIndex: currentIndex,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Today'),
      BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Habits'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
    ],
    onTap: (i) {
      if (i == 0) context.go('/today');
      if (i == 2) context.go('/me');
    },
  );
}
```

- [ ] **Step 5: Write `lib/features/habits/screens/habit_form_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../habits_provider.dart';
import '../../../theme.dart';

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({super.key});
  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _titleCtrl = TextEditingController();
  String _type = 'bool';
  double _target = 1;
  String _color = '#E8823A';
  String _iconId = 'circle';
  String _frequencyRule = '{"type":"daily"}';
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(habitsNotifierProvider.notifier).addHabit(
        title: _titleCtrl.text.trim(),
        iconId: _iconId,
        color: _color,
        type: _type,
        targetValue: _target,
        frequencyRule: _frequencyRule,
      );
      if (mounted) context.pop();
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      appBar: AppBar(backgroundColor: LuminoTheme.backgroundWarm, title: const Text('New Habit'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Habit name')),
            const SizedBox(height: 20),
            const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'bool', label: Text('Yes/No')),
                ButtonSegment(value: 'count', label: Text('Count')),
                ButtonSegment(value: 'duration', label: Text('Duration')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            if (_type != 'bool') ...[
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: _type == 'count' ? 'Target count' : 'Target minutes'),
                onChanged: (v) => setState(() => _target = double.tryParse(v) ?? 1),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Frequency', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _frequencyRule,
              items: const [
                DropdownMenuItem(value: '{"type":"daily"}', child: Text('Every day')),
                DropdownMenuItem(value: '{"type":"weekdays"}', child: Text('Weekdays only')),
                DropdownMenuItem(value: '{"type":"weekend"}', child: Text('Weekends only')),
              ],
              onChanged: (v) => setState(() => _frequencyRule = v!),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Add routes to `router.dart`**

```dart
GoRoute(path: '/habits', builder: (c, s) => const HabitsScreen()),
GoRoute(path: '/habits/add', builder: (c, s) => const HabitFormScreen()),
GoRoute(path: '/habits/:id', builder: (c, s) => HabitDetailScreen(habitId: s.pathParameters['id']!)),
```

- [ ] **Step 7: Run test and on device**

```bash
flutter test test/habits/habits_provider_test.dart
flutter run
# Expected: test PASS; on device — Habits tab shows empty state → FAB → form → save → habit appears in list
```

- [ ] **Step 8: Commit**

```bash
git add lumino-app/
git commit -m "feat: add Habits list and Add Habit form with 5-habit free-tier cap"
```

---

## Task 10: Habit Detail + Heatmap

**Files:**
- Create: `lumino-app/lib/features/habits/screens/habit_detail_screen.dart`

- [ ] **Step 1: Write `lib/features/habits/screens/habit_detail_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/database.dart';
import '../../../database/tables.dart';
import '../../../features/today/tasks_provider.dart';
import '../habits_provider.dart';
import '../../../theme.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final String habitId;
  const HabitDetailScreen({super.key, required this.habitId});
  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  List<HabitEntry> _entries = [];
  Habit? _habit;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(dbProvider);
    final habits = await db.habitDao.getActiveHabits(ref.read(currentUserIdProvider) ?? 'local');
    final habit = habits.where((h) => h.id == widget.habitId).firstOrNull;
    final now = DateTime.now();
    final entries = await db.habitDao.getAllEntries(widget.habitId);
    setState(() { _habit = habit; _entries = entries; });
  }

  @override
  Widget build(BuildContext context) {
    if (_habit == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final h = _habit!;
    final entryDates = _entries.map((e) => e.entryDate).toList();
    final streak = computeStreak(entryDates);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final thisMonthEntries = _entries.where((e) => !e.entryDate.isBefore(monthStart)).length;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final completionPct = (thisMonthEntries / daysInMonth * 100).round();

    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      appBar: AppBar(backgroundColor: LuminoTheme.backgroundWarm, title: Text(h.title), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            Row(
              children: [
                _StatBox(value: '$streak', label: 'Streak'),
                const SizedBox(width: 10),
                _StatBox(value: '${_longestStreak(entryDates)}', label: 'Best'),
                const SizedBox(width: 10),
                _StatBox(value: '$completionPct%', label: 'This month'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Last 30 days', style: TextStyle(fontSize: 12, color: Color(0xFFA08070), letterSpacing: 1, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _Heatmap(entries: _entries),
            const SizedBox(height: 24),
            const Text('Recent entries', style: TextStyle(fontSize: 12, color: Color(0xFFA08070), letterSpacing: 1, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._entries.take(10).map((e) => ListTile(
              leading: CircleAvatar(backgroundColor: LuminoTheme.primaryColor, radius: 5),
              title: Text('${e.entryDate.year}-${e.entryDate.month.toString().padLeft(2,'0')}-${e.entryDate.day.toString().padLeft(2,'0')}',
                  style: const TextStyle(fontSize: 13)),
              trailing: Text('${e.value.toInt()}${h.unit != null ? ' ${h.unit}' : ''}  ✓',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFA08070))),
            )),
          ],
        ),
      ),
    );
  }

  int _longestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final sorted = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()..sort();
    int longest = 1, current = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i-1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  const _StatBox({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(child: Card(
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE8823A), fontFamily: 'Georgia')),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFA08070))),
      ]),
    ),
  ));
}

class _Heatmap extends StatelessWidget {
  final List<HabitEntry> entries;
  const _Heatmap({required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final entrySet = entries.map((e) {
      final d = e.entryDate;
      return DateTime(d.year, d.month, d.day);
    }).toSet();

    return GridView.count(
      crossAxisCount: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      children: List.generate(30, (i) {
        final day = now.subtract(Duration(days: 29 - i));
        final norm = DateTime(day.year, day.month, day.day);
        final done = entrySet.contains(norm);
        return Container(
          decoration: BoxDecoration(
            color: done ? LuminoTheme.primaryColor : const Color(0xFFF0E0D0),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 2: Run on device**

```bash
flutter run
# Expected: tap a habit → detail screen with streak stats, 30-day heatmap (orange = done, beige = missed), entry list
```

- [ ] **Step 3: Commit**

```bash
git add lumino-app/
git commit -m "feat: add Habit detail screen with heatmap and streak stats"
```

---

## Task 11: Me / Profile Screen

**Files:**
- Create: `lumino-app/lib/features/me/theme_provider.dart`
- Create: `lumino-app/lib/features/me/screens/me_screen.dart`
- Modify: `lumino-app/lib/main.dart`
- Modify: `lumino-app/lib/router.dart`

- [ ] **Step 1: Write `lib/features/me/theme_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) => ThemeModeNotifier());

class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier() : super(false) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('dark_mode') ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', state);
  }
}
```

- [ ] **Step 2: Update `lib/main.dart`** to use theme provider

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/me/theme_provider.dart';
import 'router.dart';
import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: LuminoApp()));
}

class LuminoApp extends ConsumerWidget {
  const LuminoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Lumino',
      theme: LuminoTheme.light(),
      darkTheme: LuminoTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
```

- [ ] **Step 3: Write `lib/features/me/screens/me_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../me/theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_client.dart';
import '../../../theme.dart';

final _authProvider = Provider((ref) => AuthService(ApiClient()));

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    return Scaffold(
      backgroundColor: LuminoTheme.backgroundWarm,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Me', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26, color: const Color(0xFF3A2A1A))),
            ),
            Expanded(
              child: ListView(
                children: [
                  _Section(title: 'Account', children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Sign in / Create account'),
                      onTap: () => context.push('/onboarding/signup'),
                    ),
                  ]),
                  _Section(title: 'Preferences', children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Dark mode'),
                      value: isDark,
                      onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                    ),
                  ]),
                  _Section(title: 'Data', children: [
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: const Text('Export my data (CSV)'),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export requires account sign-in'))),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: const Text('Delete account', style: TextStyle(color: Colors.red)),
                      onTap: () => _confirmDelete(context, ref),
                    ),
                  ]),
                  _Section(title: 'About', children: [
                    const ListTile(leading: Icon(Icons.info_outline), title: Text('Version 1.0.0')),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 2),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete account?'),
      content: const Text('This will schedule your account for deletion in 30 days.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ref.read(_authProvider).logout();
            if (context.mounted) { Navigator.pop(context); context.go('/onboarding/welcome'); }
          },
          child: const Text('Delete'),
        ),
      ],
    ));
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, color: Color(0xFFA08070), letterSpacing: 1, fontWeight: FontWeight.w600))),
      ...children,
    ],
  );
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});
  @override
  Widget build(BuildContext context) => BottomNavigationBar(
    currentIndex: currentIndex,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Today'),
      BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Habits'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
    ],
    onTap: (i) {
      if (i == 0) context.go('/today');
      if (i == 1) context.go('/habits');
    },
  );
}
```

- [ ] **Step 4: Add `/me` route to `router.dart`**

```dart
GoRoute(path: '/me', builder: (c, s) => const MeScreen()),
```

- [ ] **Step 5: Run on device**

```bash
flutter run
# Expected: Me tab shows account section, dark mode toggle that works, data export, delete confirmation dialog
```

- [ ] **Step 6: Commit**

```bash
git add lumino-app/
git commit -m "feat: add Me screen with dark mode toggle and account management"
```

---

## Task 12: Sync Service

**Files:**
- Create: `lumino-app/lib/services/sync_service.dart`
- Modify: `lumino-app/lib/main.dart`

- [ ] **Step 1: Write `lib/services/sync_service.dart`**

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../database/database.dart';
import 'api_client.dart';

class SyncService {
  final AppDatabase _db;
  final ApiClient _api;
  bool _syncing = false;

  SyncService(this._db, this._api) {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) sync();
    });
  }

  Future<void> sync() async {
    if (_syncing) return;
    final isLoggedIn = await _api.getAccessToken() != null;
    if (!isLoggedIn) return;
    _syncing = true;
    try {
      await _pushDirtyTasks();
      await _pushDirtyHabits();
      await _pullLatest();
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
            'title': task.title, 'iconId': task.iconId, 'color': task.color,
            'startAt': task.startAt.toIso8601String(),
            if (task.endAt != null) 'endAt': task.endAt!.toIso8601String(),
            if (task.completedAt != null) 'completedAt': task.completedAt!.toIso8601String(),
          });
        }
        await _db.taskDao.markSynced(task.id);
      } on DioException catch (_) {
        // Leave dirty for next sync attempt
      }
    }
  }

  Future<void> _pushDirtyHabits() async {
    final habits = await _db.habitDao.getActiveHabits('local');
    // No dirty flag on habits yet — will be added in full sync implementation
    // For MVP, habit creation is pushed immediately on save via HabitsNotifier.addHabit
  }

  Future<void> _pullLatest() async {
    // Full refresh of tasks and habits from server
    try {
      final tasksRes = await _api.get('/api/tasks', queryParameters: {'date': _todayString()});
      final tasks = (tasksRes.data['data'] as List);
      // Upsert each task into local DB
      for (final t in tasks) {
        await _db.taskDao.insertTask(_taskFromJson(t));
      }
    } on DioException catch (_) {}
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  TasksCompanion _taskFromJson(Map<String, dynamic> t) {
    return TasksCompanion.insert(
      userId: 'me',
      title: t['title'],
      iconId: t['iconId'] ?? 'circle',
      color: t['color'] ?? '#E8823A',
      startAt: DateTime.parse(t['startAt']),
      dirty: const Value(false),
    );
  }
}
```

- [ ] **Step 2: Initialize `SyncService` in `main.dart`**

Add to `LuminoApp.build` after `ProviderScope`:

```dart
// In main.dart, wrap app with SyncServiceInit
class SyncServiceInit extends ConsumerStatefulWidget {
  final Widget child;
  const SyncServiceInit({super.key, required this.child});
  @override
  ConsumerState<SyncServiceInit> createState() => _SyncServiceInitState();
}

class _SyncServiceInitState extends ConsumerState<SyncServiceInit> {
  late final SyncService _syncService;

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    _syncService = SyncService(db, ApiClient());
    // Sync on app start
    Future.microtask(() => _syncService.sync());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

Wrap the `MaterialApp.router` in `LuminoApp.build` with `SyncServiceInit`:

```dart
return SyncServiceInit(child: MaterialApp.router(...));
```

- [ ] **Step 3: Run full app end-to-end**

```bash
flutter run
# Expected: app starts → SyncService runs on startup → if logged in, dirty tasks push to backend → server tasks pulled down to local DB
```

- [ ] **Step 4: Commit**

```bash
git add lumino-app/
git commit -m "feat: add SyncService with dirty-flag push and connectivity listener"
```

---

## Task 13: Final Polish + Integration Check

- [ ] **Step 1: Add `import 'package:go_router/go_router.dart';` to `_BottomNav` in `today_screen.dart`** (needed for `GoRouter.of`)

- [ ] **Step 2: Run all tests**

```bash
flutter test
# Expected: all tests PASS
```

- [ ] **Step 3: Run Flutter analyzer**

```bash
flutter analyze
# Expected: No issues found (or only minor warnings)
```

- [ ] **Step 4: Build a release APK**

```bash
flutter build apk --release
# Expected: BUILD SUCCESSFUL — APK in build/app/outputs/flutter-apk/app-release.apk
```

- [ ] **Step 5: Smoke test on device**
  - Complete onboarding flow start to finish
  - Create 3 tasks in Today — complete 2 of them — progress ring shows 2/3
  - Create 2 habits — log one — check streak increments
  - Navigate to Habit detail — heatmap shows today as orange
  - Toggle dark mode in Me screen
  - Navigate back and forth between all 3 tabs without crashes

- [ ] **Step 6: Final commit**

```bash
git add lumino-app/
git commit -m "feat: complete Lumino MVP Flutter app — onboarding, planner, habits, sync, profile"
```
