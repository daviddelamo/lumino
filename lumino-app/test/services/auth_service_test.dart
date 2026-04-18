import 'package:flutter_test/flutter_test.dart';
import 'package:lumino_app/services/api_client.dart';
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
    when(() => mockClient.getAccessToken()).thenAnswer((_) async => null);
    expect(await authService.isLoggedIn(), false);
  });

  test('isLoggedIn returns true when token exists', () async {
    when(() => mockClient.getAccessToken()).thenAnswer((_) async => 'some-token');
    expect(await authService.isLoggedIn(), true);
  });
}
