# Monetization App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate RevenueCat into the Flutter app — RC SDK setup, entitlement providers, `PaywallSheet`, and premium gates on habits (6th habit), content library items, and year statistics.

**Architecture:** `AuthState` gains `isPremium` from `/api/me`. `isPremiumProvider` combines an authoritative `entitlementProvider` with an `optimisticPremiumProvider` that flips immediately after purchase. `paywallGate` helper shows the sheet or redirects to sign-up. Three feature gates call it: `HabitsNotifier.addHabit` returns `bool`, library items show a lock badge, and the year stats chip redirects to paywall.

**Tech Stack:** `purchases_flutter ^8.0.0`, Riverpod 2, Flutter

---

## File Map

| Action | Path |
|--------|------|
| Modify | `pubspec.yaml` |
| Create | `lib/features/paywall/paywall_config.dart` |
| Modify | `lib/services/auth_state.dart` |
| Modify | `lib/main.dart` |
| Create | `lib/features/paywall/paywall_provider.dart` |
| Create | `lib/features/paywall/paywall_gate.dart` |
| Create | `lib/features/paywall/paywall_sheet.dart` |
| Modify | `lib/features/habits/habits_provider.dart` |
| Modify | `lib/features/habits/screens/habit_form_screen.dart` |
| Modify | `lib/features/library/library_data.dart` |
| Modify | `lib/features/library/screens/library_category_screen.dart` |
| Modify | `lib/features/stats/stats_screen.dart` |
| Create | `test/features/paywall/paywall_provider_test.dart` |

---

### Task 1: Add purchases_flutter dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:`, add:
```yaml
  purchases_flutter: ^8.0.0
```

- [ ] **Step 2: Fetch packages**

```bash
cd lumino-app && flutter pub get
```

Expected: resolves without conflict.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add purchases_flutter dependency"
```

---

### Task 2: RC constants and AuthState.isPremium

**Files:**
- Create: `lib/features/paywall/paywall_config.dart`
- Modify: `lib/services/auth_state.dart`

- [ ] **Step 1: Write paywall_config.dart**

`lib/features/paywall/paywall_config.dart`:
```dart
const kRcApiKey      = 'REVENUECAT_API_KEY_PLACEHOLDER';
const kEntitlementId = 'lumino_premium';
const kMonthlyId     = 'lumino_monthly';
const kYearlyId      = 'lumino_yearly';
const kLifetimeId    = 'lumino_lifetime';
```

- [ ] **Step 2: Extend AuthState with isPremium**

Replace `lib/services/auth_state.dart` with:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'api_client.dart';
import '../features/paywall/paywall_config.dart';

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
```

- [ ] **Step 3: Verify compilation**

```bash
cd lumino-app && flutter analyze lib/services/auth_state.dart lib/features/paywall/paywall_config.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/paywall/paywall_config.dart lib/services/auth_state.dart
git commit -m "feat: add RC constants and isPremium to AuthState"
```

---

### Task 3: Initialize RevenueCat SDK in main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add RC initialization to main()**

In `lib/main.dart`, add the import at the top:
```dart
import 'package:purchases_flutter/purchases_flutter.dart';
import 'features/paywall/paywall_config.dart';
```

Then in `main()`, add RC configuration **before** `runApp`. Place it right after `HomeWidget.registerInteractivityCallback(onWidgetAction)`:
```dart
await Purchases.configure(PurchasesConfiguration(kRcApiKey));
```

The resulting `main()` body should look like:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(onWidgetAction);
  await Purchases.configure(PurchasesConfiguration(kRcApiKey));
  final handler = await AudioService.init(
    builder: () => LuminoAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.lumino.lumino_app.audio',
      androidNotificationChannelName: 'Lumino Audio',
      androidNotificationOngoing: true,
    ),
  );
  runApp(ProviderScope(
    overrides: [audioHandlerProvider.overrideWithValue(handler)],
    child: const LuminoApp(),
  ));
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd lumino-app && flutter analyze lib/main.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialize RevenueCat SDK on app start"
```

---

### Task 4: Entitlement providers

**Files:**
- Create: `lib/features/paywall/paywall_provider.dart`

- [ ] **Step 1: Write the failing test first**

`test/features/paywall/paywall_provider_test.dart`:
```dart
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
      await Future.delayed(Duration.zero);
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
```

- [ ] **Step 2: Run test — verify it fails**

```bash
cd lumino-app && flutter test test/features/paywall/paywall_provider_test.dart
```

Expected: FAIL — `paywall_provider.dart` doesn't exist yet.

- [ ] **Step 3: Write paywall_provider.dart**

`lib/features/paywall/paywall_provider.dart`:
```dart
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
```

- [ ] **Step 4: Run test — verify it passes**

```bash
cd lumino-app && flutter test test/features/paywall/paywall_provider_test.dart
```

Expected: 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/paywall/paywall_provider.dart \
        test/features/paywall/paywall_provider_test.dart
git commit -m "feat: add entitlement providers with optimistic unlock"
```

---

### Task 5: paywallGate helper

**Files:**
- Create: `lib/features/paywall/paywall_gate.dart`

- [ ] **Step 1: Write paywall_gate.dart**

`lib/features/paywall/paywall_gate.dart`:
```dart
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
```

- [ ] **Step 2: Verify compilation**

```bash
cd lumino-app && flutter analyze lib/features/paywall/paywall_gate.dart
```

Expected: no errors (will warn about missing PaywallSheet until Task 6 completes — that's fine).

- [ ] **Step 3: Commit**

```bash
git add lib/features/paywall/paywall_gate.dart
git commit -m "feat: add paywallGate helper"
```

---

### Task 6: PaywallSheet widget

**Files:**
- Create: `lib/features/paywall/paywall_sheet.dart`

- [ ] **Step 1: Write paywall_sheet.dart**

`lib/features/paywall/paywall_sheet.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../theme.dart';
import 'paywall_config.dart';
import 'paywall_provider.dart';

class PaywallSheet extends ConsumerStatefulWidget {
  const PaywallSheet({super.key});

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  String _selectedId = kYearlyId;
  bool _purchasing = false;
  List<Package>? _packages;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final pkgs = offerings.current?.availablePackages ?? [];
      if (mounted) setState(() => _packages = pkgs);
    } catch (_) {
      // No offerings available in sandbox/test — packages remain null
    }
  }

  Package? get _selectedPackage => _packages?.where(
        (p) => p.storeProduct.productIdentifier == _selectedId,
      ).firstOrNull;

  Future<void> _purchase() async {
    final pkg = _selectedPackage;
    if (pkg == null) return;
    setState(() => _purchasing = true);
    try {
      await Purchases.purchasePackage(pkg);
      ref.read(optimisticPremiumProvider.notifier).state = true;
      if (mounted) Navigator.of(context).pop();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Purchase failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    try {
      final info = await Purchases.restorePurchases();
      final isActive =
          info.entitlements.all[kEntitlementId]?.isActive ?? false;
      if (isActive) {
        ref.read(optimisticPremiumProvider.notifier).state = true;
        if (mounted) Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active subscription found')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  String _priceFor(String productId) {
    if (_packages == null) return '...';
    final pkg = _packages!
        .where((p) => p.storeProduct.productIdentifier == productId)
        .firstOrNull;
    return pkg?.storeProduct.priceString ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: LuminoTheme.bg(context),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Center(
                child: Text('⭐ Lumino Premium',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Unlock everything to build your best life',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              _FeatureBullet(
                  icon: Icons.repeat_rounded,
                  text: 'Unlimited habits (free tier: 5)'),
              const SizedBox(height: 12),
              _FeatureBullet(
                  icon: Icons.library_music_outlined,
                  text: 'Full content library — meditations, soundscapes, affirmations'),
              const SizedBox(height: 12),
              _FeatureBullet(
                  icon: Icons.bar_chart_rounded,
                  text: 'Year & all-time statistics'),
              const SizedBox(height: 32),
              _PlanCard(
                label: 'Monthly',
                price: _priceFor(kMonthlyId),
                productId: kMonthlyId,
                selected: _selectedId == kMonthlyId,
                onTap: () => setState(() => _selectedId = kMonthlyId),
              ),
              const SizedBox(height: 12),
              _PlanCard(
                label: 'Yearly',
                price: _priceFor(kYearlyId),
                productId: kYearlyId,
                selected: _selectedId == kYearlyId,
                badge: 'Best value',
                onTap: () => setState(() => _selectedId = kYearlyId),
              ),
              const SizedBox(height: 12),
              _PlanCard(
                label: 'Lifetime',
                price: _priceFor(kLifetimeId),
                productId: kLifetimeId,
                selected: _selectedId == kLifetimeId,
                onTap: () => setState(() => _selectedId = kLifetimeId),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _purchasing ? null : _purchase,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _purchasing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Continue with ${_labelFor(_selectedId)}'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _restore,
                    child: const Text('Restore purchases'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _labelFor(String id) => switch (id) {
        kMonthlyId  => 'Monthly',
        kYearlyId   => 'Yearly',
        kLifetimeId => 'Lifetime',
        _           => 'Plan',
      };
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: LuminoTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String label;
  final String price;
  final String productId;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.label,
    required this.price,
    required this.productId,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? LuminoTheme.primaryColor.withValues(alpha: 0.1)
              : LuminoTheme.surface(context),
          border: Border.all(
            color: selected
                ? LuminoTheme.primaryColor
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: LuminoTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(badge!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(price,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd lumino-app && flutter analyze lib/features/paywall/
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/paywall/paywall_sheet.dart lib/features/paywall/paywall_gate.dart
git commit -m "feat: add PaywallSheet and paywallGate"
```

---

### Task 7: HabitsNotifier.addHabit returns bool

**Files:**
- Modify: `lib/features/habits/habits_provider.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/habits/habits_provider_test.dart` (inside `main()`):

```dart
  test('addHabit returns false when at 5 habits and not premium', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    for (var i = 1; i <= 5; i++) {
      await db.habitDao.insertHabit(HabitsCompanion.insert(
        userId: 'u1',
        title: 'Habit $i',
        type: 'bool',
        frequencyRule: '{"type":"daily"}',
      ));
    }
    final container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
    addTearDown(container.dispose);
    while (container.read(habitsNotifierProvider) is AsyncLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    final added = await container.read(habitsNotifierProvider.notifier).addHabit(
          isPremium: false,
          title: 'Sixth',
          iconId: 'circle',
          color: '#E8823A',
          type: 'bool',
          targetValue: 1,
          frequencyRule: '{"type":"daily"}',
        );
    expect(added, isFalse);
    await db.close();
  });

  test('addHabit returns true when at 5 habits and is premium', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    for (var i = 1; i <= 5; i++) {
      await db.habitDao.insertHabit(HabitsCompanion.insert(
        userId: 'u1',
        title: 'Habit $i',
        type: 'bool',
        frequencyRule: '{"type":"daily"}',
      ));
    }
    final container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
    addTearDown(container.dispose);
    while (container.read(habitsNotifierProvider) is AsyncLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    final added = await container.read(habitsNotifierProvider.notifier).addHabit(
          isPremium: true,
          title: 'Sixth',
          iconId: 'circle',
          color: '#E8823A',
          type: 'bool',
          targetValue: 1,
          frequencyRule: '{"type":"daily"}',
        );
    expect(added, isTrue);
    await db.close();
  });
```

- [ ] **Step 2: Run test — verify it fails**

```bash
cd lumino-app && flutter test test/habits/habits_provider_test.dart
```

Expected: FAIL — `addHabit` doesn't have `isPremium` parameter yet.

- [ ] **Step 3: Update addHabit in habits_provider.dart**

Change the `addHabit` method signature and body in `lib/features/habits/habits_provider.dart`:

Replace this block:
```dart
  Future<void> addHabit({
    required String title,
    required String iconId,
    required String color,
    required String type,
    required double targetValue,
    String? unit,
    required String frequencyRule,
  }) async {
    if (state.value != null && state.value!.length >= 5) {
      throw Exception('Free tier allows up to 5 habits');
    }
    await _db.habitDao.insertHabit(HabitsCompanion.insert(
      userId: _userId,
      title: title,
      iconId: Value(iconId),
      color: Value(color),
      type: type,
      targetValue: Value(targetValue),
      frequencyRule: frequencyRule,
      unit: Value(unit),
    ));
    await _load();
    await _widgetService.refreshFromPrefs();
  }
```

With this:
```dart
  Future<bool> addHabit({
    required bool isPremium,
    required String title,
    required String iconId,
    required String color,
    required String type,
    required double targetValue,
    String? unit,
    required String frequencyRule,
  }) async {
    if (!isPremium && state.value != null && state.value!.length >= 5) {
      return false;
    }
    await _db.habitDao.insertHabit(HabitsCompanion.insert(
      userId: _userId,
      title: title,
      iconId: Value(iconId),
      color: Value(color),
      type: type,
      targetValue: Value(targetValue),
      frequencyRule: frequencyRule,
      unit: Value(unit),
    ));
    await _load();
    await _widgetService.refreshFromPrefs();
    return true;
  }
```

- [ ] **Step 4: Run test — verify it passes**

```bash
cd lumino-app && flutter test test/habits/habits_provider_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/habits/habits_provider.dart \
        test/habits/habits_provider_test.dart
git commit -m "feat: addHabit returns bool instead of throwing on free tier limit"
```

---

### Task 8: HabitFormScreen calls paywallGate on false return

**Files:**
- Modify: `lib/features/habits/screens/habit_form_screen.dart`

- [ ] **Step 1: Update the import and _save() method**

In `lib/features/habits/screens/habit_form_screen.dart`:

Add import at the top (after existing imports):
```dart
import '../../paywall/paywall_gate.dart';
import '../../paywall/paywall_provider.dart';
```

Replace the `_save()` method:
```dart
  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final isPremium = ref.read(isPremiumProvider);
    final added = await ref.read(habitsNotifierProvider.notifier).addHabit(
          isPremium: isPremium,
          title: _titleCtrl.text.trim(),
          iconId: _iconId,
          color: _color,
          type: _type,
          targetValue: _target,
          frequencyRule: _frequencyRule,
        );
    if (!mounted) return;
    if (!added) {
      setState(() => _saving = false);
      await paywallGate(context, ref);
      return;
    }
    context.pop();
  }
```

Remove the `try/catch` block that was wrapping the old `addHabit` call (it's no longer needed since `addHabit` no longer throws). Also remove the `_error` display in the build method if it was only used for the free-tier exception — keep any other error UI.

- [ ] **Step 2: Verify compilation**

```bash
cd lumino-app && flutter analyze lib/features/habits/screens/habit_form_screen.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/habits/screens/habit_form_screen.dart
git commit -m "feat: show paywall when free tier habit limit reached"
```

---

### Task 9: LibraryItem.isPremium and catalog split

**Files:**
- Modify: `lib/features/library/library_data.dart`

- [ ] **Step 1: Write the failing test**

In `test/features/library/library_data_test.dart`, add inside `main()`:

```dart
  test('each category has at least one free item', () {
    for (final cat in LibraryCategory.values) {
      if (cat == LibraryCategory.affirmation) continue; // affirmations use separate list
      final items = kLibraryCatalog.where((i) => i.category == cat);
      final freeItems = items.where((i) => !i.isPremium);
      expect(freeItems, isNotEmpty,
          reason: '$cat should have at least one free item');
    }
  });

  test('some items are marked premium', () {
    expect(kLibraryCatalog.any((i) => i.isPremium), isTrue);
  });
```

- [ ] **Step 2: Run test — verify it fails**

```bash
cd lumino-app && flutter test test/features/library/library_data_test.dart
```

Expected: FAIL — `LibraryItem` has no `isPremium` field yet.

- [ ] **Step 3: Add isPremium to LibraryItem and update catalog**

In `lib/features/library/library_data.dart`:

Add `isPremium` field to `LibraryItem`:
```dart
class LibraryItem {
  final String id;
  final String title;
  final String description;
  final LibraryCategory category;
  final String audioUrl;
  final Duration duration;
  final String emoji;
  final Color color;
  final bool isPremium;   // new field

  const LibraryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.audioUrl,
    required this.duration,
    required this.emoji,
    required this.color,
    this.isPremium = false,
  });
}
```

Then update `kLibraryCatalog` to mark premium items. Keep the first item in each category free, mark the rest premium. For example:
```dart
// Meditations — first one free, rest premium
LibraryItem(id: 'med_morning', ..., isPremium: false),   // Morning Calm — FREE
LibraryItem(id: 'med_body_scan', ..., isPremium: true),  // Body Scan — PREMIUM
LibraryItem(id: 'med_breath', ..., isPremium: true),     // Breath Focus — PREMIUM

// Soundscapes — first one free, rest premium
LibraryItem(id: 'sound_rain', ..., isPremium: false),    // Gentle Rain — FREE
LibraryItem(id: 'sound_forest', ..., isPremium: true),   // Forest Morning — PREMIUM
LibraryItem(id: 'sound_ocean', ..., isPremium: true),    // Ocean Waves — PREMIUM
LibraryItem(id: 'sound_white', ..., isPremium: true),    // White Noise — PREMIUM
```

Add `isPremium: false` (or `true`) to every existing item in the catalog. Do not remove any existing fields.

- [ ] **Step 4: Run test — verify it passes**

```bash
cd lumino-app && flutter test test/features/library/library_data_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/library/library_data.dart \
        test/features/library/library_data_test.dart
git commit -m "feat: add isPremium field to LibraryItem and split catalog"
```

---

### Task 10: LibraryCategoryScreen lock badge and paywallGate

**Files:**
- Modify: `lib/features/library/screens/library_category_screen.dart`

- [ ] **Step 1: Update the screen to handle locked items**

Replace `lib/features/library/screens/library_category_screen.dart` with:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../library_data.dart';
import '../library_provider.dart';
import '../../../theme.dart';
import '../../paywall/paywall_gate.dart';
import '../../paywall/paywall_provider.dart';

class LibraryCategoryScreen extends ConsumerWidget {
  final LibraryCategory category;
  const LibraryCategoryScreen({super.key, required this.category});

  String get _title => switch (category) {
        LibraryCategory.meditation => 'Meditations',
        LibraryCategory.soundscape => 'Soundscapes',
        LibraryCategory.affirmation => 'Affirmations',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(libraryForCategoryProvider(category));
    final favorites = ref.watch(favoritesProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: LuminoTheme.bg(context),
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: LuminoTheme.bg(context),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          final locked = item.isPremium && !isPremium;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LibraryItemCard(
              item: item,
              isFavorite: favorites.contains(item.id),
              locked: locked,
              onTap: () {
                if (locked) {
                  paywallGate(context, ref);
                } else {
                  context.push('/library/player', extra: item);
                }
              },
              onFavoriteToggle: locked
                  ? null
                  : () => ref.read(favoritesProvider.notifier).toggle(item.id),
            ),
          );
        },
      ),
    );
  }
}

class _LibraryItemCard extends StatelessWidget {
  final LibraryItem item;
  final bool isFavorite;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const _LibraryItemCard({
    required this.item,
    required this.isFavorite,
    required this.locked,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  String _fmt(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.color.withValues(alpha: locked ? 0.04 : 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: item.color
                          .withValues(alpha: locked ? 0.07 : 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                        child: Text(item.emoji,
                            style: TextStyle(
                                fontSize: 26,
                                color: locked
                                    ? null
                                    : null))),
                  ),
                  if (locked)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lock,
                            size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                                color: locked ? Colors.grey : null)),
                    const SizedBox(height: 2),
                    Text(item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: locked ? Colors.grey : null)),
                    const SizedBox(height: 4),
                    Text(
                      _fmt(item.duration),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: locked
                                ? Colors.grey
                                : item.color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              if (!locked)
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : null,
                    size: 20,
                  ),
                  onPressed: onFavoriteToggle,
                )
              else
                const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd lumino-app && flutter analyze lib/features/library/screens/library_category_screen.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/library/screens/library_category_screen.dart
git commit -m "feat: lock premium library items behind paywall gate"
```

---

### Task 11: StatsScreen year chip locked for non-premium

**Files:**
- Modify: `lib/features/stats/stats_screen.dart`

- [ ] **Step 1: Update _PeriodChips to support locked periods**

In `lib/features/stats/stats_screen.dart`:

Add import at the top:
```dart
import '../paywall/paywall_gate.dart';
import '../paywall/paywall_provider.dart';
```

Change `_PeriodChips` to accept a `locked` set and update its `build` to show a lock icon:
```dart
class _PeriodChips extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onChanged;
  final Set<_Period> locked;

  const _PeriodChips({
    required this.selected,
    required this.onChanged,
    this.locked = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _Period.values.map((opt) {
        final isSelected = opt == selected;
        final isLocked = locked.contains(opt);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? LuminoTheme.primaryColor
                    : LuminoTheme.surface(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    opt.label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : LuminoTheme.textPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.lock,
                      size: 12,
                      color: isSelected
                          ? Colors.white70
                          : LuminoTheme.textPrimary(context)
                              .withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

In `_StatsScreenState.build`, read `isPremiumProvider` and update `_PeriodChips` usage:
```dart
  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final period = _selected.period;
    // ... rest of build unchanged ...

    // Replace the existing _PeriodChips widget call with:
    _PeriodChips(
      selected: _selected,
      locked: isPremium ? {} : {_Period.year},
      onChanged: (p) {
        if (p == _Period.year && !isPremium) {
          paywallGate(context, ref);
          return;
        }
        setState(() => _selected = p);
      },
    ),
```

- [ ] **Step 2: Verify compilation**

```bash
cd lumino-app && flutter analyze lib/features/stats/stats_screen.dart
```

Expected: no errors.

- [ ] **Step 3: Run all tests**

```bash
cd lumino-app && flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/stats/stats_screen.dart
git commit -m "feat: lock year stats chip behind paywall for non-premium users"
```

---

### Task 12: Final test run

- [ ] **Step 1: Run full Flutter test suite**

```bash
cd lumino-app && flutter test
```

Expected: all tests pass, no regressions.

- [ ] **Step 2: Run Flutter analyze**

```bash
cd lumino-app && flutter analyze
```

Expected: no errors (warnings about unused imports are acceptable if unavoidable).

- [ ] **Step 3: Commit any fixes**

If any test or analysis failures required fixes, commit them:
```bash
git add -p
git commit -m "fix: address post-review issues in monetization"
```
