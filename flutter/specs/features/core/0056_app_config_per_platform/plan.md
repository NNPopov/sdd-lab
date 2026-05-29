# 0056 — App Config per Platform — Implementation Plan

> Source: `prd.md` (this folder) + reading the existing DI/network/startup code.
> This is a **core-infrastructure slice**, not a feature slice. It has **no API
> endpoint, no use-case, no Cubit, no screen**. The standard four-layer slice
> structure does not apply; the structure below is the real target.

---

## 1. Title

Introduce compile-time app configuration via `--dart-define-from-file`. A freezed
`AppConfig` (single field `baseUrl`) reads `String.fromEnvironment('BASE_URL')`,
is registered as a `get_it` singleton through a new `@module`, and is consumed by
`AppModule.dio()` instead of the hardcoded URL. `main.dart` fails loud at startup
if `baseUrl` is empty. The legacy `assets/config/` JSON files and their `pubspec`
asset entry are removed. The Dockerfile bakes in `config/prod-web.json`.

No UX surface. The only observable runtime behaviour is: *correct `baseUrl` →
Dio is built against it; missing definition → app refuses to start with a message
naming the fix.*

---

## 2. Context

### READ
- `@CLAUDE.md` — fully (already loaded).
- `@specs/features/core/0056_app_config_per_platform/prd.md` — the contract.
- `@docs/adr/0003-dart-define-from-file-for-app-config.md` — the rationale (exists).
- `@lib/core/di/app_module.dart` — **changed**: `dio()` gains an `AppConfig` arg.
- `@lib/core/network/dio_client.dart` — **unchanged**, but read to confirm
  `DioClient.create({required String baseUrl})` is the consumption point.
- `@lib/core/auth/auth_module.dart` — nearest prior art for a thin `@module`.
- `@lib/core/di/injection.dart` — `configureDependencies({String env})`; not changed.
- `@lib/main.dart` — **changed**: add the fail-loud assertion after
  `configureDependencies()`, before any other `getIt<...>` call.
- `@lib/features/users/_shared/domain/entities/user.dart` — freezed data-class
  prior art (`@freezed sealed class ... with _$...`, `const factory`).
- `@pubspec.yaml` (lines 50–51) — **changed**: remove the `- assets/config/` entry.
- `@docker/Dockerfile.flutter` — **changed**: swap the `--dart-define` flag.

### DO NOT READ
- Any `features/**` slice except the `user.dart` entity cited above.
- Any `*.g.dart` / `*.freezed.dart` / `*.config.dart` generated file (regenerated).
- `flutter_dotenv` / asset-loading code — explicitly rejected by the ADR.

---

## 3. "API" — the configuration contract

There is no HTTP endpoint. The "contract" is the JSON-key ↔ environment-variable ↔
field mapping consumed at **compile time**.

```
--dart-define-from-file=<path>.json   →   String.fromEnvironment('BASE_URL')   →   AppConfig.baseUrl
```

### JSON schema (flat, top-level keys; one key per `fromEnvironment` call)
```json
{ "BASE_URL": "<url>" }
```
The legacy nested shape `{ "baseUrl": "..." }` is **incompatible** with
`--dart-define-from-file` (it injects each top-level key as a define) and is replaced.

### Files produced (all committed, under `flutter/config/`)
| File | `BASE_URL` |
|---|---|
| `config/local-web.json` | `http://127.0.0.1:8000/api/v1` |
| `config/local-android-emulator.json` | `http://10.0.2.2:8000/api/v1` |
| `config/local-ios-simulator.json` | `http://127.0.0.1:8000/api/v1` |
| `config/local-desktop.json` | `http://127.0.0.1:8000/api/v1` |
| `config/prod-web.json` | `/api/v1` |

`prod-mobile.json` is **intentionally absent** (no production domain yet — see PRD
Out of Scope). Its absence is the documented signal that prod-mobile is unsolved.

### Failure modes
- **No `--dart-define-from-file` flag passed** → `String.fromEnvironment('BASE_URL')`
  returns `''` (its no-default fallback) → startup assertion throws `StateError`.
- **Flag passed, key present but empty** → same: empty `baseUrl` → `StateError`.
- There is no network error mode in this slice; downstream adapters keep their own
  error mapping unchanged.

---

## 4. Target structure

```
flutter/
├── config/                              # NEW — outside assets/, NOT web-bundled
│   ├── local-web.json
│   ├── local-android-emulator.json
│   ├── local-ios-simulator.json
│   ├── local-desktop.json
│   ├── prod-web.json
│   └── README.md                        # NEW — file→purpose→`flutter run` cmd table
│
├── lib/core/config/                     # NEW module folder
│   ├── app_config.dart                  # @freezed AppConfig + const factory fromEnvironment()
│   ├── app_config.freezed.dart          # generated
│   ├── config_module.dart               # @module ConfigModule → lazySingleton AppConfig
│   └── require_valid_app_config.dart    # pure helper: throws StateError if baseUrl empty
│
└── (deleted)
    ├── assets/config/dev.json           # DELETE
    └── assets/config/prod.json          # DELETE
```

### Changed existing files
- `lib/core/di/app_module.dart` — `dio()` → `dio(AppConfig config)`.
- `lib/main.dart` — call `requireValidAppConfig(getIt<AppConfig>())` after
  `configureDependencies()`.
- `pubspec.yaml` — remove `- assets/config/`.
- `docker/Dockerfile.flutter` — replace `--dart-define=ENVIRONMENT=production`
  with `--dart-define-from-file=config/prod-web.json`.

**Rationale for placement:** `core/config/` sits in `core/`, which `features/`
already depends on transitively through `core/network/`. `core/` continues to know
nothing about `features/`. The JSON lives in `flutter/config/` (not `assets/`) so
the web bundle never ships it; the Dockerfile's `COPY flutter/ .` into `WORKDIR
/build` makes `config/prod-web.json` resolvable relative to the build.

---

## 5. What to do — step by step

### Step 1 — `core/config/app_config.dart` (the data class)
Immutable freezed data class, single field, plus the env-reading const factory.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';

@freezed
sealed class AppConfig with _$AppConfig {
  const factory AppConfig({required String baseUrl}) = _AppConfig;

  /// Reads compile-time values injected via `--dart-define-from-file`.
  /// Returns an empty [baseUrl] when no flag was passed — the startup
  /// assertion ([requireValidAppConfig]) turns that into a loud failure.
  const factory AppConfig.fromEnvironment() = _fromEnvironment;
}
```

**CRITICAL — `const factory` cannot call `String.fromEnvironment` directly.** A
freezed `const factory` must redirect to a const constructor; it cannot run
expression logic. Two acceptable shapes — pick whichever the freezed version in
this repo supports, verified by `dart run build_runner build`:

- **Preferred:** keep only the default `const factory AppConfig({required String
  baseUrl})` on the freezed class, and expose the environment read as a separate
  top-level const in the same file:
  ```dart
  const appConfigFromEnvironment = AppConfig(
    baseUrl: String.fromEnvironment('BASE_URL'),
  );
  ```
  `String.fromEnvironment` is a `const`-evaluable constructor, so this is a valid
  compile-time constant. `ConfigModule` returns `appConfigFromEnvironment`.

This avoids fighting freezed over a second factory. The PRD's
`AppConfig.fromEnvironment()` wording is satisfied semantically by
`appConfigFromEnvironment`; do not contort freezed to literally produce a named
factory if the generator rejects it.

### Step 2 — `core/config/config_module.dart` (DI registration)
Thin `@module`, mirrors `AuthModule`.

```dart
import 'package:flutter_application_1/core/config/app_config.dart';
import 'package:injectable/injectable.dart';

@module
abstract class ConfigModule {
  @lazySingleton
  AppConfig get appConfig => appConfigFromEnvironment;
}
```

### Step 3 — `core/config/require_valid_app_config.dart` (fail-loud helper)
Pure function, no Flutter/DI dependency, so it is unit-testable in isolation.

```dart
import 'package:flutter_application_1/core/config/app_config.dart';

/// Throws [StateError] when [config.baseUrl] is empty — i.e. the build was run
/// without `--dart-define-from-file`. The message names the missing flag and
/// lists every valid config file so the developer fixes it in one read.
void requireValidAppConfig(AppConfig config) {
  if (config.baseUrl.isNotEmpty) return;
  throw StateError(
    'BASE_URL is empty: the app was built without '
    '--dart-define-from-file. Re-run with one of:\n'
    '  flutter/config/local-web.json\n'
    '  flutter/config/local-android-emulator.json\n'
    '  flutter/config/local-ios-simulator.json\n'
    '  flutter/config/local-desktop.json\n'
    '  flutter/config/prod-web.json\n'
    'e.g. flutter run --dart-define-from-file=flutter/config/local-desktop.json',
  );
}
```
The message **must** contain the substrings `--dart-define-from-file`,
`flutter/config/`, and at least one valid filename — the unit test asserts these.

### Step 4 — change `core/di/app_module.dart` (consume AppConfig)
```dart
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config/app_config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AppModule {
  @lazySingleton
  Dio dio(AppConfig config) => DioClient.create(baseUrl: config.baseUrl);
}
```
`injectable` resolves the `AppConfig` argument from the graph automatically — no
other call site changes. `DioClient.create` is **untouched**.

### Step 5 — change `lib/main.dart` (fail-loud at startup)
Immediately after `configureDependencies();` and **before** the first other
`getIt<...>()` call (currently `getIt<AppLogger>()`):
```dart
configureDependencies();
requireValidAppConfig(getIt<AppConfig>());
```
Add the import for `require_valid_app_config.dart`. Nothing else in `main.dart`
moves. Throwing here is caught by the existing `runZonedGuarded` → reported via
`FlutterError.reportError`, satisfying "crash within one second with a clear
message".

### Step 6 — create the five JSON files + README under `flutter/config/`
Exact contents per the table in §3. README lists each file, its purpose, and the
matching `flutter run --dart-define-from-file=flutter/config/<file>` command.

### Step 7 — remove legacy config inputs
- Delete `assets/config/dev.json` and `assets/config/prod.json`.
- Remove the `- assets/config/` line from `pubspec.yaml` (line 51); if `assets:`
  then has no remaining entries, remove the empty `assets:` key too (verify the
  surrounding `flutter:` block stays valid YAML).

### Step 8 — change `docker/Dockerfile.flutter`
Replace:
```
RUN flutter build web \
    --release \
    --web-renderer canvaskit \
    --dart-define=ENVIRONMENT=production
```
with:
```
RUN flutter build web \
    --release \
    --web-renderer canvaskit \
    --dart-define-from-file=config/prod-web.json
```
`--web-renderer canvaskit` stays. The `COPY flutter/ .` already brings
`config/prod-web.json` into the build context at `/build/config/prod-web.json`.

### Step 9 — regenerate & verify
- `dart run build_runner build --delete-conflicting-outputs` (freezed + injectable
  config picks up `AppConfig`, `ConfigModule`, and the new `dio(AppConfig)` arg).
- `dart format .` → no diff.
- `dart analyze` → no warnings.
- `flutter test` → green (see §6 for the new tests; bootstrap-graph tests must
  override `AppConfig`).

---

## 6. Tests

This slice has **no use-case / adapter / Cubit / widget layers**, so the default
four-layer policy in `CLAUDE.md` does not map. Tests assert the *behavioural
contract*, never the mechanism (no asserting `String.fromEnvironment` was called or
that `@module` is annotated). Full enumeration lives in `tests.md`; the plan-level
shape:

`test/core/config/`:

a) `app_config_test.dart` (unit, pure Dart)
   - `AppConfig(baseUrl: 'x')` constructs and exposes `baseUrl == 'x'`.
   - `appConfigFromEnvironment.baseUrl == ''` when the test process runs with no
     `--dart-define` (this is the default for `flutter test`).

b) `require_valid_app_config_test.dart` (unit, pure Dart)
   - empty `baseUrl` → throws `StateError` whose message contains
     `--dart-define-from-file`, `flutter/config/`, and at least one filename.
   - non-empty `baseUrl` → returns normally (no throw).

c) `app_module_test.dart` (unit)
   - `AppModule().dio(const AppConfig(baseUrl: 'https://x/api/v1'))` yields a `Dio`
     whose `options.baseUrl == 'https://x/api/v1'`.

**Out of Dart test scope (CI guard, lives in `.github/workflows/ci.yml`):** a
build-time smoke job running `flutter build web --dart-define-from-file=flutter/
config/prod-web.json` and `flutter build apk --debug --dart-define-from-file=
flutter/config/local-android-emulator.json`. Documented here, not implemented as a
unit test.

Downstream adapter/Cubit/widget tests are **unchanged** — they mock `Dio` directly
and never see `AppConfig`.

---

## 7. Report (what the implementing agent must deliver)

- New files: `lib/core/config/{app_config.dart, app_config.freezed.dart,
  config_module.dart, require_valid_app_config.dart}`, five `flutter/config/*.json`,
  `flutter/config/README.md`, three test files under `test/core/config/`.
- Changed files: `lib/core/di/app_module.dart`, `lib/main.dart`, `pubspec.yaml`,
  `docker/Dockerfile.flutter`, `lib/core/di/injection.config.dart` (generated).
- Deleted files: `assets/config/dev.json`, `assets/config/prod.json`.
- Confirmation: **no `features/**` file changed**; `core/` still imports nothing
  from `features/`.
- Verification log: `dart format` clean, `dart analyze` clean, `build_runner` ran,
  `flutter test` green.
- Manual confirmation that `flutter run --dart-define-from-file=flutter/config/
  local-desktop.json` boots against `127.0.0.1:8000`, and that omitting the flag
  throws the `StateError` at startup.

---

## 8. What NOT to do

- ❌ Do **not** read config JSON via `rootBundle` / register it as an asset — that
  re-introduces the web-bundle exposure the ADR rejects.
- ❌ Do **not** add `flutter_dotenv` or any new `pubspec` dependency.
- ❌ Do **not** add a default value to `String.fromEnvironment('BASE_URL')` — the
  empty-string fallback is what the startup assertion relies on to fail loud.
- ❌ Do **not** commit `prod-mobile.json` or any `https://<ALB-DNS>` placeholder.
- ❌ Do **not** introduce an "environment name" (`dev`/`prod`) concept in source —
  the app only needs `baseUrl`. (`injectable`'s `Environment.dev/.prod` axis is
  orthogonal and stays untouched.)
- ❌ Do **not** touch `DioClient.create`, the nginx config block, `--web-renderer
  canvaskit`, or any `features/**` slice.
- ❌ Do **not** rename-and-shadow the old `assets/config/*.json`; delete them.
- ❌ Do **not** fall back to a default URL anywhere — missing config must crash.
```
