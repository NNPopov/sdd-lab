# 0056 · app_config_per_platform — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The app's API base URL is supplied at build time via `--dart-define-from-file=<env>-<platform>.json` and is not hardcoded in source. |
| F2 | Running with `flutter/config/local-web.json`, `local-ios-simulator.json`, or `local-desktop.json` points the app at `http://127.0.0.1:8000/api/v1`. |
| F3 | Running with `flutter/config/local-android-emulator.json` points the app at `http://10.0.2.2:8000/api/v1`. |
| F4 | The production web build points the app at the relative URL `/api/v1`. |
| F5 | When no `--dart-define-from-file` flag is passed (or `BASE_URL` is empty), the app refuses to start and throws an error at startup rather than failing later on the first API call. |
| F6 | The startup failure message names the missing `--dart-define-from-file` flag, references `flutter/config/`, and lists the valid config files. |
| F7 | The Dio HTTP client is constructed against the `baseUrl` taken from the resolved `AppConfig`. |
| F8 | All five config files (`local-web`, `local-android-emulator`, `local-ios-simulator`, `local-desktop`, `prod-web`) are present and committed with non-secret values. |
| F9 | The production web Docker build bakes in `BASE_URL=/api/v1` via `--dart-define-from-file=config/prod-web.json`. |
| F10 | The web bundle does not expose any environment config file as a publicly fetchable asset. |
| F11 | Tests that bootstrap the DI graph can override the `AppConfig` registration so they run without a `--dart-define-from-file` flag and without tripping the startup failure. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | `AppConfig` is an immutable freezed data class exposing a single `baseUrl` field, extensible by adding one field in one place. |
| N2 | The compile-time read uses `String.fromEnvironment('BASE_URL')` with no default value, so an unset variable resolves to the empty string. |
| N3 | `AppConfig` is registered as a `get_it` `lazySingleton` through a dedicated `@module` (`ConfigModule`). |
| N4 | The startup non-empty check is a pure, dependency-free function so it is unit-testable without bootstrapping the app. |
| N5 | Config files live in `flutter/config/` (outside `assets/`) so they are never bundled into the web build. |
| N6 | Config JSON uses a flat top-level schema (`{ "BASE_URL": "..." }`); the legacy nested `{ "baseUrl": "..." }` shape is removed. |
| N7 | The new code lives in `core/config/`; `core/` continues to import nothing from `features/`. |
| N8 | No new third-party dependency is added to `pubspec.yaml`. |
| N9 | The legacy `assets/config/` directory, its two JSON files, and the `pubspec.yaml` asset entry are deleted, not renamed or shadowed. |
| N10 | The freezed and injectable generated files are produced by `dart run build_runner build --delete-conflicting-outputs`, not hand-edited. |
| N11 | `DioClient.create`, the Dockerfile's embedded nginx config, and the `--web-renderer canvaskit` flag remain unchanged. |
| N12 | No source-level "environment name" (dev/prod) concept is introduced; the app consumes only `baseUrl`, and `injectable`'s `Environment` axis is untouched. |
| N13 | Behavioural tests assert the observable contract (Dio built against `baseUrl`; missing config fails loud) and do not couple to the mechanism (`String.fromEnvironment` calls, `@module` shape, generated-file existence). |
| N14 | `dart format` produces no diff and `dart analyze` produces no warnings for the changed and new files. |

## Out of scope

- `prod-mobile.json` and any production mobile URL or `https://<ALB-DNS>` placeholder.
- Physical-device local configs requiring a per-developer LAN IP.
- A staging environment and any `staging-*` config files.
- Secret values in any config file.
- Backwards compatibility with the old `assets/config/` JSON files.
- A runtime "switch environment" UI.
- Nginx config changes in `Dockerfile.flutter`.
- Use of `injectable`'s `Environment.dev` / `.prod` adapter-swapping mechanism.
