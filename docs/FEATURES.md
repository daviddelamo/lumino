# Lumino — Feature Tracker

## MVP Phase 1

### Onboarding
- [ ] Welcome screen with animated logo
- [ ] Goals selection (multi-select chips)
- [ ] Personality quiz (3 questions)
- [ ] Routine preview card list
- [ ] Notification permission request (contextual)
- [ ] Sign up / skip screen (email + Google OAuth)

### Daily Planner
- [ ] Today timeline view with progress ring
- [ ] Task card (icon, title, time, complete button)
- [ ] Add / edit task bottom sheet
- [ ] One-tap task completion with haptic feedback
- [ ] Repeat rules (daily, specific days, every N days, weekly, monthly)
- [ ] Local notifications per task
- [ ] Week view with per-day completion dots
- [ ] Friendly empty state

### Habits
- [ ] Habit list with streak badges and progress bars
- [ ] Add / edit habit (title, icon, color, type, frequency)
- [ ] Boolean / Count / Duration habit types
- [ ] Habit entries logging
- [ ] Streak computation (current + longest)
- [ ] 30-day heatmap
- [ ] Habit detail screen
- [ ] Archive habit

### Cloud Sync
- [ ] Email + password registration and login
- [ ] Google OAuth login
- [ ] JWT issuance and refresh (Spring Boot)
- [ ] Refresh token storage in Android Keystore
- [ ] Drift local cache with `dirty` flag
- [ ] SyncService — push dirty rows on connectivity
- [ ] Full refresh on app start
- [ ] Anonymous local mode (no account required)

### Profile / Settings
- [ ] Profile screen (avatar, display name, account status)
- [ ] Sign in / sign out
- [ ] Light / Dark theme toggle
- [ ] Notification settings
- [ ] CSV data export
- [ ] Account deletion (30-day soft delete)

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
