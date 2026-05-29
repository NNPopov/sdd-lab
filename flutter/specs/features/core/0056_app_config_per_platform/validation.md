# 0056 · app_config_per_platform — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | `flutter run -d chrome --dart-define-from-file=flutter/config/local-web.json` with FastAPI running on `127.0.0.1:8000` | App boots; network calls hit `http://127.0.0.1:8000/api/v1`. (F2) |
| M2 | `flutter run --dart-define-from-file=flutter/config/local-desktop.json` | App boots; calls hit `http://127.0.0.1:8000/api/v1`. (F2) |
| M3 | `flutter run --dart-define-from-file=flutter/config/local-ios-simulator.json` on the iOS simulator | App boots; calls hit `http://127.0.0.1:8000/api/v1`. (F2) |
| M4 | `flutter run --dart-define-from-file=flutter/config/local-android-emulator.json` on the Android emulator | App boots; calls hit `http://10.0.2.2:8000/api/v1`, not the emulator's own loopback. (F3) |
| M5 | `flutter run` with **no** `--dart-define-from-file` flag | App throws a `StateError` at startup within ~1s; it does not reach a screen and does not silently call `localhost`. (F5) |
| M6 | Read the M5 error message | Message contains the text `--dart-define-from-file`, the path `flutter/config/`, and at least one valid filename (e.g. `local-desktop.json`). (F6) |
| M7 | Build a config file with `{ "BASE_URL": "" }` and run with it | Same startup `StateError` as the missing-flag case. (F5) |
| M8 | `flutter build web --release --dart-define-from-file=flutter/config/prod-web.json` | Build succeeds; bundled app uses base URL `/api/v1`. (F4) |
| M9 | `docker build -f docker/Dockerfile.flutter .` then serve the image | Web app loads; API calls resolve against the same-origin `/api/v1` ingress path. (F9) |
| M10 | In the served prod web bundle, fetch `<host>/assets/config/dev.json` and `<host>/assets/config/prod.json` | Both return 404 — no environment config is exposed as a public asset. (F10) |
| M11 | `ls flutter/config/` | Exactly five JSON files present (`local-web`, `local-android-emulator`, `local-ios-simulator`, `local-desktop`, `prod-web`); `prod-mobile.json` is absent. (F8) |
| M12 | `flutter test` without passing any `--dart-define` flag | All tests pass, including any that bootstrap DI (they override `AppConfig`); none trip the startup failure. (F11) |

## Code review

- [ ] `AppConfig` is a freezed immutable class with a single `baseUrl` field. (N1)
- [ ] The environment read uses `String.fromEnvironment('BASE_URL')` with **no** default argument. (N2)
- [ ] `ConfigModule` is an `@module` registering `AppConfig` as a `@lazySingleton`. (N3)
- [ ] The non-empty check is a standalone pure function (`requireValidAppConfig`) with no Flutter/get_it imports. (N4)
- [ ] `AppModule.dio` takes `AppConfig` and passes `config.baseUrl` to `DioClient.create`; the hardcoded `http://127.0.0.1:8000/api/v1` is gone. (F1, F7)
- [ ] `main.dart` calls `requireValidAppConfig(getIt<AppConfig>())` immediately after `configureDependencies()` and before any other `getIt` call. (F5)
- [ ] All five config files live under `flutter/config/`, not under `assets/`. (N5)
- [ ] Each config file uses the flat `{ "BASE_URL": "..." }` schema; no nested `baseUrl` key remains. (N6)
- [ ] No file under `lib/core/config/` imports anything from `lib/features/`. (N7)
- [ ] `git diff pubspec.yaml` shows no new dependency added. (N8)
- [ ] `assets/config/dev.json` and `assets/config/prod.json` are deleted and the `- assets/config/` entry is removed from `pubspec.yaml`. (N9)
- [ ] `DioClient.create`, the nginx config block, and `--web-renderer canvaskit` are unchanged in the diff. (N11)
- [ ] No `dev`/`prod` environment-name string is introduced in source; `configureDependencies` env handling is untouched. (N12)
- [ ] `docker/Dockerfile.flutter` uses `--dart-define-from-file=config/prod-web.json` in place of `--dart-define=ENVIRONMENT=production`. (F9)
- [ ] Tests assert behaviour (Dio baseUrl, fail-loud message) and do not assert `String.fromEnvironment` calls or `@module` annotations. (N13)
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
