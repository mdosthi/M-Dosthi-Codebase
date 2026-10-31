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

## Run Or Build With Docker

From the repository root, `docker compose up --build -d` starts the legacy JSP site, Flutter web app, Spring API, RMI service, and MySQL. Open `http://localhost:8080/M-Dosthi/` for the JSP app and `http://localhost:8081/` for Flutter web. Flutter web reaches the API through the same-origin Nginx proxy. See the [Docker Compose setup guide](../../docs/setup.md#run-the-apps-with-docker-compose) for database and API-host configuration.

Build an Android APK with `docker compose run --build --rm android-apk`. The APK is written to `dist/android/app-release.apk`. The Android platform runner is generated inside the build container because this checkout does not include `apps/mobile/android/`. Set `ANDROID_API_HOST` in the root `.env` to the reachable API host and port; the default `10.0.2.2:9090` is for the standard Android emulator.

## Project Areas

- `lib/`: screens and workflows including admin, chat, surveyor and wellbeing features; shared services and utilities are also here.
- `assets/`: images, icons, questionnaire content and media.
- `test/`: Flutter tests.
- `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/`: platform-specific runners and settings.
- `pubspec.yaml` / `pubspec.lock`: dependency constraints and resolved versions.

For DB configuration, API startup, platform-specific setup and troubleshooting, see the [repository setup guide](../../docs/setup.md) and [root README](../../README.md).