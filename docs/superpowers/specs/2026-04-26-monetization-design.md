# Lumino Monetization Design

## Goal

Add in-app subscriptions (monthly, yearly, lifetime) to Lumino using RevenueCat for purchase processing, a backend webhook for entitlement storage, and a dismissible bottom-sheet paywall triggered at three contextual gates.

## Scope

- **Premium features:** unlimited habits (beyond 5), full content library (meditations, soundscapes, affirmations), year & all-time statistics
- **Plans:** monthly, yearly, lifetime one-time purchase
- **Platforms:** Android (Google Play Billing via RevenueCat)
- **Backend:** lumino-api validates entitlements server-side; source of truth for `isPremium`

---

## Architecture

### Flutter app

**New package:** `purchases_flutter: ^8.0.0`

**New files:**
- `lib/features/paywall/paywall_config.dart` — RC constants (API key + product IDs as placeholders)
- `lib/features/paywall/paywall_provider.dart` — `entitlementProvider`, `optimisticPremiumProvider`, `isPremiumProvider`
- `lib/features/paywall/paywall_sheet.dart` — `PaywallSheet` bottom modal
- `lib/features/paywall/paywall_gate.dart` — `paywallGate(context, ref)` helper

**Modified files:**
- `lib/main.dart` — initialise RC SDK on app start: `Purchases.configure(PurchasesConfiguration(kRcApiKey))`; call `Purchases.logIn(userId)` after sign-in AND on cold-start if `authProvider` already has a `userId` (i.e. token was persisted)
- `lib/features/habits/habits_provider.dart` — `addHabit` returns `bool` instead of throwing
- `lib/features/habits/screens/habit_form_screen.dart` — handle `false` return → call `paywallGate`
- `lib/features/stats/stats_screen.dart` — lock year chip behind `isPremiumProvider`
- `lib/features/library/library_data.dart` — add `isPremium` field to `LibraryItem`
- `lib/features/library/screens/library_category_screen.dart` — show lock badge, call `paywallGate` on locked tap
- `lib/services/auth_state.dart` — extend `AuthState` with `isPremium: bool` field, populated from `/api/me`

### Spring Boot API

**New files:**
- `src/main/kotlin/com/lumino/api/subscription/Subscription.kt` — entity
- `src/main/kotlin/com/lumino/api/subscription/SubscriptionRepository.kt`
- `src/main/kotlin/com/lumino/api/subscription/SubscriptionService.kt`
- `src/main/kotlin/com/lumino/api/subscription/RevenueCatWebhookController.kt`
- `src/main/resources/db/migration/V8__create_subscriptions.sql`

**Modified files:**
- `src/main/kotlin/com/lumino/api/user/UserService.kt` — `isPremium` computed from subscriptions table
- `src/main/kotlin/com/lumino/api/user/dto/UserResponse.kt` — add `isPremium: Boolean`
- `src/main/resources/application.properties` — add `revenuecat.webhook-secret` property

---

## RevenueCat Configuration (Placeholders)

```dart
const kRcApiKey      = 'REVENUECAT_API_KEY_PLACEHOLDER';
const kEntitlementId = 'lumino_premium';
const kMonthlyId     = 'lumino_monthly';
const kYearlyId      = 'lumino_yearly';
const kLifetimeId    = 'lumino_lifetime';
```

Replace these with real values from the RevenueCat dashboard before going to production.

---

## Data Model

### `subscriptions` table (Flyway V8)

```sql
CREATE TABLE subscriptions (
  id             BIGSERIAL PRIMARY KEY,
  user_id        UUID NOT NULL REFERENCES users(id),
  rc_customer_id VARCHAR(255) NOT NULL,
  product_id     VARCHAR(255) NOT NULL,
  status         VARCHAR(32)  NOT NULL DEFAULT 'ACTIVE',
  expires_at     TIMESTAMPTZ,
  is_lifetime    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
```

**Status values:** `ACTIVE`, `CANCELLED`, `EXPIRED`

**`isPremium` rule:** `status = 'ACTIVE'` AND (`is_lifetime = true` OR `expires_at > NOW()`)

### `AuthState` extension (Flutter)

```dart
class AuthState {
  final String? userId;
  final String? email;
  final String? displayName;
  final bool isPremium;   // new field, default false
}
```

---

## Providers

```dart
// Reads isPremium from /api/me; returns false for anonymous users
final entitlementProvider = FutureProvider<bool>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return false;
  return auth.isPremium;
});

// Set to true immediately after successful RC purchase
final optimisticPremiumProvider = StateProvider<bool>((_) => false);

// Combines both: optimistic wins until next /api/me refresh
final isPremiumProvider = Provider<bool>((ref) {
  if (ref.watch(optimisticPremiumProvider)) return true;
  return ref.watch(entitlementProvider).value ?? false;
});
```

---

## Purchase Flow

1. User hits a gate → `isPremiumProvider` is `false` → `paywallGate(context, ref)` called
2. **Anonymous user:** `paywallGate` pushes to `/onboarding/signup`; no sheet shown
3. **Signed-in user:** `PaywallSheet` slides up via `showModalBottomSheet`
4. User selects plan (yearly pre-selected) and taps "Continue"
5. `Purchases.purchasePackage(pkg)` called
6. **On success:** `optimisticPremiumProvider` set to `true`; sheet dismisses; feature unlocks immediately
7. **On cancel/error:** snackbar with error message; sheet stays open
8. RevenueCat sends webhook to `/api/webhooks/revenuecat` → backend updates `subscriptions` table
9. Next app launch: `/api/me` returns `isPremium: true`; `entitlementProvider` reflects authoritative state; `optimisticPremiumProvider` resets to `false`

---

## Webhook Handler

**Endpoint:** `POST /api/webhooks/revenuecat` (public, no JWT required)

**Validation:** request must include `Authorization` header matching `REVENUECAT_WEBHOOK_SECRET` env var → 401 if missing or wrong

**RC ↔ user matching:** RC `app_user_id` = Lumino `userId` (set via `Purchases.logIn(userId)` after sign-in)

**Handled events:**

| RC event | Action |
|---|---|
| `INITIAL_PURCHASE` | Insert subscription row, `status = ACTIVE` |
| `RENEWAL` | Upsert row, update `expires_at`, `status = ACTIVE` |
| `CANCELLATION` | Set `status = CANCELLED` (access continues until `expires_at`) |
| `EXPIRATION` | Set `status = EXPIRED` |
| `NON_SUBSCRIPTION_PURCHASE` | Insert with `is_lifetime = true`, `expires_at = null` |

Unknown events → 200 OK (ignored, not an error).

---

## PaywallSheet

Presented via `showModalBottomSheet(isScrollControlled: true)`. Uses `DraggableScrollableSheet`.

**Layout:**
1. Drag handle
2. ⭐ "Lumino Premium" heading + subtitle
3. Three feature bullets (unlimited habits, full content library, year statistics)
4. Three plan cards (Monthly / Yearly / Lifetime) — yearly pre-selected, price strings from `storeProduct.priceString`
5. CTA button — "Continue with [selected plan]"
6. Footer: "Restore purchases" (`Purchases.restorePurchases()`) · "Privacy Policy" (URL)

**Anonymous variant:** feature bullets + single CTA "Create account to unlock" — no plan cards.

---

## Feature Gates

### Gate 1 — 6th habit
`HabitsNotifier.addHabit` returns `Future<bool>`:
- `false` when `!isPremium && habits.length >= 5` (no exception thrown)
- `HabitFormScreen` calls `paywallGate(context, ref)` on `false` return

### Gate 2 — Year statistics
`StatsScreen` renders the `_Period.year` chip with a lock icon when `!isPremium`. Tapping it calls `paywallGate` instead of selecting the period.

### Gate 3 — Content library
`LibraryItem` gains `final bool isPremium`. Premium items in `LibraryCategoryScreen` show a `🔒` badge. Tapping a locked item calls `paywallGate`. A subset of items per category remain free.

### `paywallGate` helper
```dart
Future<void> paywallGate(BuildContext context, WidgetRef ref) async {
  final auth = ref.read(authProvider);
  if (!auth.isLoggedIn) {
    context.push('/onboarding/signup');
    return;
  }
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const PaywallSheet(),
  );
}
```

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `REVENUECAT_WEBHOOK_SECRET` | Yes | Shared secret for webhook validation |

Add to `.env.example` and `CLAUDE.md`.

---

## Testing

### Flutter unit tests
- `entitlementProvider` — mock `authProvider` with `isPremium: true/false`, verify value
- `isPremiumProvider` — verify `optimisticPremiumProvider = true` overrides `entitlementProvider`
- `HabitsNotifier.addHabit` — verify returns `false` at habit 6 when not premium, `true` when premium or under limit
- `LibraryItem` — verify free/premium split in catalog

### Spring Boot integration tests (Testcontainers)
- Valid webhook secret + `INITIAL_PURCHASE` → subscription row inserted → `GET /api/me` returns `isPremium: true`
- Invalid webhook secret → 401
- `EXPIRATION` event → subscription row updated → `GET /api/me` returns `isPremium: false`
- `NON_SUBSCRIPTION_PURCHASE` → `is_lifetime = true`, no `expires_at` → `isPremium: true` indefinitely

### Manual (device required)
- Sandbox purchase flow on Android emulator with RC sandbox account
- Restore purchases flow
- Anonymous user → paywall → sign-up redirect
