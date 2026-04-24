# Tasks

## Active

### MVP Phase 1 — Remaining

### Phase 2 — Mood Tracker

- [ ] **Mood check-in screen** - lumino-app: 5-level emoji scale daily check-in
- [ ] **Mood tags and notes** - lumino-app: attach tags and free-text notes to mood entries
- [ ] **Mood calendar view** - lumino-app: calendar heatmap showing daily mood
- [ ] **Mood trend chart** - lumino-app: line/bar chart showing mood over time

### Phase 2 — Content Library

- [ ] **Library home screen** - lumino-app: categories grid (meditations, soundscapes, affirmations)
- [ ] **Guided meditations** - lumino-app: playback screen for guided meditation audio
- [ ] **Soundscapes** - lumino-app: ambient audio playback (rain, forest, white noise, etc.)
- [ ] **Affirmations** - lumino-app: daily affirmation cards / audio
- [ ] **Background audio playback** - lumino-app: lock-screen controls via `audio_service` or similar
- [ ] **Favorites and recently played** - lumino-app: persist and surface user's library history

### Phase 2 — Widgets

- [x] **Home-screen widget (2×2 and 4×2)** - lumino-app: Android home-screen widget showing today's tasks
- [x] **Quick-complete from widget** - lumino-app: tap to complete a task directly from the widget

### Phase 2 — Statistics

- [ ] **Monthly / yearly wrapped summary** - lumino-app: end-of-period stats recap screen
- [ ] **Habit-mood correlation view** - lumino-app: chart correlating habit streaks with mood scores
- [ ] **Shareable progress graphics** - lumino-app: generate and share a progress image card

## Waiting On


### Phase 2 — Monetization

- [ ] **Paywall screen** - lumino-app: build weekly / monthly / quarterly / yearly plan selection screen
- [ ] **RevenueCat integration** - lumino-app: integrate RevenueCat SDK with Google Play Billing
- [ ] **Server-side receipt validation** - lumino-api: validate RevenueCat webhooks and receipts
- [ ] **Entitlement system** - lumino-app + lumino-api: free vs premium gates across features
- [ ] **Contextual paywall triggers** - lumino-app: show paywall on 6th habit, premium templates, long-range stats access


## Someday

## Done

- [x] **JWT issuance and refresh (Spring Boot)** - lumino-api: implement short-lived access token + refresh token endpoint in backend
  - Deferred from Phase 1; `JwtService` stub exists but refresh endpoint not wired
- [x] **Notification settings UI** - lumino-app: wire the settings screen to local notification preferences
  - Currently a UI stub; `NotificationService` exists but prefs toggles don't persist
