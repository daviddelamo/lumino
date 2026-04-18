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
    _saveTokensFromResponse(res.data);
  }

  Future<void> login(String email, String password) async {
    final res = await _client.post('/api/auth/login',
        data: {'email': email, 'password': password});
    await _saveTokensFromResponse(res.data);
  }

  Future<void> logout() => _client.clearTokens();

  Future<void> _saveTokensFromResponse(dynamic responseData) async {
    final data = responseData['data'] as Map<String, dynamic>?;
    final accessToken = data?['accessToken'] as String?;
    final refreshToken = data?['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null) {
      throw Exception('Invalid auth response: missing tokens');
    }
    await _client.saveTokens(accessToken, refreshToken);
  }
}
