import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ApiClient()));
