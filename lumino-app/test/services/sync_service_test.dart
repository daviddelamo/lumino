import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lumino_app/database/database.dart';
import 'package:lumino_app/services/api_client.dart';
import 'package:lumino_app/services/sync_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late AppDatabase db;
  late MockApiClient api;
  late SyncService svc;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    api = MockApiClient();
    svc = SyncService(db, api);
  });

  tearDown(() => db.close());

  test('sync does nothing when not logged in', () async {
    when(() => api.getAccessToken()).thenAnswer((_) async => null);
    await svc.sync();
    verifyNever(() => api.get(any(), queryParameters: any(named: 'queryParameters')));
  });

  test('sync calls pullLatest when logged in with no dirty tasks', () async {
    when(() => api.getAccessToken()).thenAnswer((_) async => 'token');
    when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/api/tasks'),
              data: {'data': []},
              statusCode: 200,
            ));
    await svc.sync();
    verify(() => api.get('/api/tasks', queryParameters: any(named: 'queryParameters'))).called(1);
  });

  test('dirty deleted task calls api.delete', () async {
    when(() => api.getAccessToken()).thenAnswer((_) async => 'token');
    when(() => api.delete(any())).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 204,
        ));
    when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/api/tasks'),
              data: {'data': []},
              statusCode: 200,
            ));
    // Insert a dirty deleted task
    await db.taskDao.insertTask(TasksCompanion.insert(
      userId: 'me',
      title: 'deleted task',
      iconId: const Value('circle'),
      color: const Value('#E8823A'),
      startAt: DateTime.now(),
      dirty: const Value(true),
      deletedAt: Value(DateTime.now()),
    ));
    await svc.sync();
    verify(() => api.delete(any())).called(1);
  });

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
}
