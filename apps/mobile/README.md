# Flutter Client

This directory contains the M-Dosthi Flutter application. Its REST API source is in the sibling monorepo directory `services/api`; the old Spring Boot copy and local credentials formerly documented here are not used.

## Requirements

- Flutter SDK compatible with the constraints in `pubspec.yaml`.
- Chrome for `-d chrome`, or another Flutter-supported device/platform.
- The Spring Boot API on port 9090 for login and other server-backed features.

## Run In A Browser

From the repository root, start the API first as described in [the setup guide](../../docs/setup.md#4-run-flutter-and-the-api). In another terminal:

```bash
cd apps/mobile
flutter pub get
flutter run -d chrome --dart-define=API_HOST=localhost:9090
```

To use Flutter's web-server target instead of launching Chrome:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3001 \
  --dart-define=API_HOST=localhost:9090
```

Open the local URL Flutter prints. Keep the Flutter process running during use. For an Android emulator, use `API_HOST=10.0.2.2:9090`; for a physical device, use the development computer's LAN hostname/IP.

`API_HOST` accepts only the hostname and port; the client uses HTTP. Never add credentials or patient data to Dart source, command-line arguments, or committed files.

## Project Areas

- `lib/`: screens and workflows including admin, chat, surveyor and wellbeing features; shared services and utilities are also here.
- `assets/`: images, icons, questionnaire content and media.
- `test/`: Flutter tests.
- `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/`: platform-specific runners and settings.
- `pubspec.yaml` / `pubspec.lock`: dependency constraints and resolved versions.

For DB configuration, API startup, platform-specific setup and troubleshooting, see the [repository setup guide](../../docs/setup.md) and [root README](../../README.md).