import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_state.dart';

final entitlementProvider = FutureProvider<bool>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return false;
  return auth.isPremium;
});

final optimisticPremiumProvider = StateProvider<bool>((_) => false);

final isPremiumProvider = Provider<bool>((ref) {
  if (ref.watch(optimisticPremiumProvider)) return true;
  return ref.watch(entitlementProvider).value ?? false;
});
