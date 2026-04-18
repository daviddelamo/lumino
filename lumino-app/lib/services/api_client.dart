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

class _AuthInterceptor extends QueuedInterceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  final String _baseUrl;

  _AuthInterceptor(this._storage, this._dio, this._baseUrl);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final response = await Dio(BaseOptions(baseUrl: _baseUrl))
              .post('/api/auth/refresh', data: {'refreshToken': refreshToken});
          final newAccessToken = response.data['data']['accessToken'] as String?;
          if (newAccessToken != null) {
            await _storage.write(key: 'access_token', value: newAccessToken);
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await _dio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          await _storage.delete(key: 'access_token');
          await _storage.delete(key: 'refresh_token');
        }
      }
    }
    handler.next(err);
  }
}
