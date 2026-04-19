# Lumino — Feature Tracker

## MVP Phase 1

### Onboarding
- [x] Welcome screen with animated logo
- [x] Goals selection (multi-select chips)
- [x] Personality quiz (3 questions)
- [x] Routine preview card list
- [x] Notification permission request (contextual)
- [x] Sign up / skip screen (email + Google OAuth)

### Daily Planner
- [x] Today timeline view with progress ring
- [x] Task card (icon, title, time, complete button)
- [x] Add / edit task bottom sheet
- [x] One-tap task completion with haptic feedback
- [x] Repeat rules (daily, specific days, every N days, weekly, monthly)
- [x] Local notifications per task
- [x] Week view with per-day completion dots
- [x] Friendly empty state

### Habits
- [x] Habit list with streak badges and progress bars
- [x] Add / edit habit (title, icon, color, type, frequency)
- [x] Boolean / Count / Duration habit types
- [x] Habit entries logging
- [x] Streak computation (current + longest)
- [x] 30-day heatmap
- [x] Habit detail screen
- [x] Archive habit

### Cloud Sync
- [x] Email + password registration and login
- [x] Google OAuth login
- [ ] JWT issuance and refresh (Spring Boot) — deferred to backend plan
- [x] Refresh token storage in Android Keystore
- [x] Drift local cache with `dirty` flag
- [x] SyncService — push dirty rows on connectivity
- [x] Full refresh on app start
- [x] Anonymous local mode (no account required)

### Profile / Settings
- [x] Profile screen (avatar, display name, account status)
- [x] Sign in / sign out
- [x] Light / Dark theme toggle
- [ ] Notification settings — UI stub (settings screen not yet wired to local notification prefs)
- [x] CSV data export (stub — shows sign-in required message)
- [x] Account deletion (30-day soft delete)

---

## Phase 2 (future)

### Monetization
- [ ] Paywall screen (weekly / monthly / quarterly / yearly)
- [ ] RevenueCat integration (Google Play Billing)
- [ ] Server-side receipt validation
- [ ] Entitlement system (free vs premium)
- [ ] Contextual paywall triggers (6th habit, premium templates, long-range stats)

### Mood Tracker
- [ ] Mood check-in (5-level emoji scale)
- [ ] Tags and notes on mood entries
- [ ] Mood calendar view
- [ ] Mood trend chart

### Content Library
- [ ] Library home screen (categories)
- [ ] Guided meditations
- [ ] Soundscapes
- [ ] Affirmations
- [ ] Background audio playback with lock-screen controls
- [ ] Favorites and recently played

### Widgets
- [ ] Home-screen widget (2×2, 4×2)
- [ ] Quick-complete from widget

### Statistics
- [ ] Monthly / yearly wrapped summary
- [ ] Habit-mood correlation view
- [ ] Shareable progress graphics
