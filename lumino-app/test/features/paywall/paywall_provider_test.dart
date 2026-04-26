import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumino_app/features/paywall/paywall_provider.dart';

void main() {
  group('isPremiumProvider', () {
    test('returns false when entitlement is false and optimistic is false',
        () async {
      final container = ProviderContainer(overrides: [
        entitlementProvider.overrideWith((ref) => Future.value(false)),
      ]);
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);
      expect(container.read(isPremiumProvider), isFalse);
    });

    test('returns true when entitlement is true', () async {
      final container = ProviderContainer(overrides: [
        entitlementProvider.overrideWith((ref) => Future.value(true)),
      ]);
      addTearDown(container.dispose);
      await container.read(entitlementProvider.future);
      expect(container.read(isPremiumProvider), isTrue);
    });

    test('optimistic true overrides false entitlement', () async {
      final container = ProviderContainer(overrides: [
        entitlementProvider.overrideWith((ref) => Future.value(false)),
      ]);
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);
      expect(container.read(isPremiumProvider), isFalse);

      container.read(optimisticPremiumProvider.notifier).state = true;
      expect(container.read(isPremiumProvider), isTrue);
    });

    test('optimistic resets to false independently', () async {
      final container = ProviderContainer(overrides: [
        entitlementProvider.overrideWith((ref) => Future.value(false)),
      ]);
      addTearDown(container.dispose);
      container.read(optimisticPremiumProvider.notifier).state = true;
      expect(container.read(isPremiumProvider), isTrue);

      container.read(optimisticPremiumProvider.notifier).state = false;
      await Future.delayed(Duration.zero);
      expect(container.read(isPremiumProvider), isFalse);
    });
  });
}
