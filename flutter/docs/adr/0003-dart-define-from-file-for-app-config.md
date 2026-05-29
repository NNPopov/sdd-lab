# Use `--dart-define-from-file` for app configuration, not assets or dotenv

## Status

accepted

## Context

The Flutter client targets web (deployed behind nginx in Kubernetes on AWS), mobile (Android / iOS), and desktop. The only configuration value today is `baseUrl`, and it differs by deployment target: `http://127.0.0.1:8000/api/v1` for most local builds, `http://10.0.2.2:8000/api/v1` for the Android emulator, and the relative path `/api/v1` for the web build behind the K8s ingress that routes `/api/*` to FastAPI.

Three delivery mechanisms were considered: (1) `flutter_dotenv` loading a `.env` file, (2) JSON files registered as Flutter assets and read at startup via `rootBundle`, and (3) `--dart-define-from-file` injecting values at compile time, consumed via `String.fromEnvironment`.

## Decision

Use `--dart-define-from-file=flutter/config/<env>-<platform>.json` on every build. The values are read by a `const factory AppConfig.fromEnvironment()` on a freezed data class, registered as a `get_it` singleton via an `@module` in `core/config/`. `AppModule.dio(AppConfig)` consumes it. `main.dart` asserts `baseUrl.isNotEmpty` immediately after `configureDependencies()` so a missing flag fails loudly at startup with a message pointing the developer at `flutter/config/`.

Per-(env × platform) JSON files live in `flutter/config/`, outside Flutter's `assets/` so they are NOT bundled into the web build.

## Consequences

- One build = one environment. CI / Dockerfile must pass the right `--dart-define-from-file` flag for each target. The Docker build for prod web uses `--dart-define-from-file=config/prod-web.json`.
- A web bundle no longer ships JSON files describing every other environment. Each web build's bundle reveals only its own `BASE_URL`.
- `flutter_dotenv` is no longer needed and should not be reintroduced.
- Tests that bootstrap the real DI graph must override the `AppConfig` registration (no `--dart-define-from-file` is passed by `flutter test`).
- Production mobile builds are explicitly **out of scope** for now — there is no domain on the K8s ingress yet, so `prod-mobile.json` is deferred and not committed.

## Considered alternatives

- **`flutter_dotenv`** — rejected. On web, the `.env` file is bundled as a public asset, loads asynchronously, and exposes every value to anyone who fetches the bundle. The async load also complicates DI startup.
- **JSON files registered as Flutter assets** — rejected. Same web exposure as dotenv (every committed env config is publicly accessible by URL), still async at startup, and the bundle ships every environment's URLs together.
- **Plain top-level constants in a single `config.dart` file** — rejected. Not testable, requires editing source to switch env, no per-build differentiation.
