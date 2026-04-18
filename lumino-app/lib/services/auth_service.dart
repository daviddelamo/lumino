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
    await _client.saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
  }

  Future<void> login(String email, String password) async {
    final res = await _client.post('/api/auth/login',
        data: {'email': email, 'password': password});
    final data = res.data['data'];
    await _client.saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
  }

  Future<void> logout() => _client.clearTokens();
}
