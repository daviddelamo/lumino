# Lumino App

Flutter productivity app — tasks, habits, and daily planning.

## Prerequisites

- Flutter 3.x (`flutter --version` to verify)
- Android SDK (for Android builds)
- ADB installed and in PATH (`adb version` to verify)
- A connected Android device or running emulator with USB debugging enabled

## Build a Release APK

### 1. Set the API base URL

Edit `lib/core/api_client.dart` (or `lib/services/api_client.dart`) and set `baseUrl` to your deployed API:

```dart
static const String baseUrl = 'https://your-api-host.com';
```

### 2. Build the APK

```bash
cd lumino-app
flutter build apk --release
```

The APK is output to:
```
build/app/outputs/flutter-apk/app-release.apk
```

For a smaller download, build a split APK per ABI:

```bash
flutter build apk --split-per-abi --release
```

This produces three APKs:
- `app-armeabi-v7a-release.apk` — 32-bit ARM (older devices)
- `app-arm64-v8a-release.apk` — 64-bit ARM (most modern devices)
- `app-x86_64-release.apk` — x86_64 (emulators)

### 3. Install via ADB

Connect your device with USB debugging enabled, then:

```bash
# Install to connected device
adb install build/app/outputs/flutter-apk/app-release.apk

# For split APKs, install the one matching your device architecture:
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Verify device is connected
adb devices
```

### 4. Re-install over existing installation

If the app is already installed and you want to replace it:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Development

```bash
cd lumino-app
flutter pub get
flutter run
```

## Run tests

```bash
flutter test
```
