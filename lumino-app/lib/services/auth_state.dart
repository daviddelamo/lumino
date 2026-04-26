import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'api_client.dart';

class AuthState {
  final String? userId;
  final String? email;
  final String? displayName;
  final bool isPremium;

  const AuthState({
    this.userId,
    this.email,
    this.displayName,
    this.isPremium = false,
  });
  const AuthState.anonymous()
      : userId = null,
        email = null,
        displayName = null,
        isPremium = false;

  bool get isLoggedIn => userId != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _client;

  AuthNotifier(this._client) : super(const AuthState.anonymous()) {
    _init();
  }

  Future<void> _init() async {
    final token = await _client.getAccessToken();
    if (token == null) return;
    await _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await _client.get('/api/me');
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return;
      state = AuthState(
        userId: data['id'] as String?,
        email: data['email'] as String?,
        displayName: data['displayName'] as String?,
        isPremium: (data['isPremium'] as bool?) ?? false,
      );
      final uid = state.userId;
      if (uid != null) {
        await Purchases.logIn(uid);
      }
    } catch (_) {
      await _client.clearTokens();
      state = const AuthState.anonymous();
    }
  }

  Future<void> onSignedIn() => _fetchProfile();

  Future<void> signOut() async {
    final refreshToken = await _client.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _client.post('/api/auth/logout',
            data: {'refreshToken': refreshToken});
      } catch (_) {}
    }
    await _client.clearTokens();
    try {
      await Purchases.logOut();
    } catch (_) {}
    state = const AuthState.anonymous();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ApiClient()),
);
