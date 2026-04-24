import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client;
  AuthService(this._client);

  // ── Email / Password ────────────────────────────────────────────────────────

  Future<bool> isLoggedIn() async {
    final token = await _client.getAccessToken();
    return token != null;
  }

  Future<void> register(String email, String password) async {
    final res = await _client.post('/api/auth/register',
        data: {'email': email, 'password': password});
    await _saveTokensFromResponse(res.data);
  }

  Future<void> login(String email, String password) async {
    final res = await _client.post('/api/auth/login',
        data: {'email': email, 'password': password});
    await _saveTokensFromResponse(res.data);
  }

  Future<void> logout() => _client.clearTokens();

  // ── Google ──────────────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw AuthCancelledException();

    final auth = await googleUser.authentication;
    final idToken = auth.idToken;
    if (idToken == null) throw Exception('Google sign-in did not return an ID token');

    final res = await _client.post('/api/auth/google', data: {'idToken': idToken});
    await _saveTokensFromResponse(res.data);
  }

  // ── Facebook ─────────────────────────────────────────────────────────────────

  Future<void> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.cancelled) throw AuthCancelledException();
    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw Exception('Facebook sign-in failed: ${result.message}');
    }

    final res = await _client.post('/api/auth/facebook',
        data: {'accessToken': result.accessToken!.tokenString});
    await _saveTokensFromResponse(res.data);
  }

  // ── Internal ────────────────────────────────────────────────────────────────

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

class AuthCancelledException implements Exception {
  @override
  String toString() => 'Sign-in was cancelled';
}
