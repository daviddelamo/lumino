import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_state.dart';
import 'paywall_sheet.dart';

Future<void> paywallGate(BuildContext context, WidgetRef ref) async {
  final auth = ref.read(authProvider);
  if (!auth.isLoggedIn) {
    context.push('/onboarding/signup');
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const PaywallSheet(),
  );
}
