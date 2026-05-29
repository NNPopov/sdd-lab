# 0056 — App Config per Platform

## Problem Statement

The Flutter client targets web (served by nginx behind a Kubernetes ingress on AWS), Android (emulator), iOS (simulator), and desktop. It speaks to a FastAPI backend whose URL differs across these targets. Today the URL is hardcoded in a DI module to `http://127.0.0.1:8000/api/v1`. The repository also carries `assets/config/dev.json` and `assets/config/prod.json` registered as Flutter assets, but no code actually reads them — so the only way to point the app at anything other than `localhost:8000` is to edit source. Web builds shipped to Kubernetes hit `localhost` (broken). Android emulator builds cannot reach the host's `localhost` at all (the emulator's loopback is itself; the host is reachable as `10.0.2.2`). A developer cannot pick an environment at build time, the Dockerfile cannot pick one for production, and nothing surfaces the mistake when no environment is picked.

## Solution

Introduce **compile-time configuration via `--dart-define-from-file`**, with one JSON file per (env × platform) pair under `flutter/config/`. A freezed `AppConfig` data class reads its single field, `baseUrl`, from a `String.fromEnvironment('BASE_URL')` call inside a `const factory AppConfig.fromEnvironment()`. The config is registered as a `get_it` singleton via a thin `@module`; the existing `AppModule.dio()` consumes it instead of hardcoding the URL. At startup, `main.dart` asserts that `baseUrl` is non-empty and, if not, throws an error pointing the developer at `flutter/config/<env>-<platform>.json` and the missing `--dart-define-from-file` flag. The Dockerfile is updated to pass `--dart-define-from-file=config/prod-web.json`. The old `assets/config/` directory and its `pubspec.yaml` entry are removed, so the web bundle no longer ships any environment file as a public asset.

## User Stories

1. As a developer running the app locally against a desktop or web target, I want to run `flutter run --dart-define-from-file=flutter/config/local-desktop.json`, so that the app talks to my locally running FastAPI on `127.0.0.1:8000`.
2. As a developer running the app on the Android emulator, I want to run `flutter run --dart-define-from-file=flutter/config/local-android-emulator.json`, so that the app talks to the host's FastAPI via the emulator's `10.0.2.2:8000` and does not silently try to call its own loopback.
3. As a developer running the app on the iOS simulator, I want to run `flutter run --dart-define-from-file=flutter/config/local-ios-simulator.json`, so that the app talks to the host's FastAPI via `127.0.0.1:8000`.
4. As a developer building the web bundle for local debugging, I want to run `flutter run -d chrome --dart-define-from-file=flutter/config/local-web.json`, so that the app calls `http://127.0.0.1:8000/api/v1` with CORS configured on the API.
5. As a Kubernetes operator deploying the web bundle to AWS, I want the CI/CD Docker build to bake in `BASE_URL=/api/v1`, so that the SPA's network calls go through the same ALB ingress that already routes `/api/*` to FastAPI — no absolute URL, no domain coupling.
6. As a developer who forgot the `--dart-define-from-file` flag, I want the app to crash within one second of startup with a clear error message naming the missing flag and listing the valid files in `flutter/config/`, so that I diagnose the mistake immediately instead of chasing a misleading 404 on the first API call.
7. As a security-conscious reviewer, I want the web bundle to NOT expose JSON files for every other environment, so that production users cannot read `http://<our-host>/assets/config/dev.json` and discover internal URLs and any future non-secret config that lives there.
8. As a future developer touching production deployment, I want a single, obvious source of truth for the prod URL (`flutter/config/prod-web.json`), so that I do not chase the value across `assets/`, source files, Dockerfile flags, and K8s manifests.
9. As a developer extending the config with a second parameter (e.g. a feature flag, log level, or environment marker), I want the AppConfig class to be an immutable freezed record, so that I add one field in one place and the rest of the codebase consumes it through DI.
10. As a developer writing tests for adapters that depend on Dio, I want to override the `AppConfig` registration in test setup, so that tests bootstrap without a `--dart-define-from-file` flag and without hitting the startup assert.
11. As a developer reading the codebase six months from now, I want an ADR explaining why `--dart-define-from-file` was chosen over `flutter_dotenv` and asset-loaded JSON, so that I do not propose reverting to dotenv "for simplicity" and re-introduce the web-bundle exposure risk.
12. As an operator planning a future production mobile rollout, I want the slice to leave a clear placeholder (`prod-mobile.json` does NOT exist today), so that I am forced to settle the missing DNS / domain question before shipping mobile to production rather than silently inheriting `localhost` defaults.
13. As a maintainer of `docker/Dockerfile.flutter`, I want a single `--dart-define-from-file=config/prod-web.json` line to replace the legacy `--dart-define=ENVIRONMENT=production`, so that future builds use the same mechanism as local development and no second concept of "environment" leaks into the build.
14. As a developer onboarding to the project, I want each `flutter/config/*.json` file to be present and committed (with non-secret values), so that `flutter run --dart-define-from-file=flutter/config/<env>.json` works without per-developer setup or secret distribution.

## Implementation Decisions

- **Mechanism: `--dart-define-from-file`.** The handoff document's recommendation is adopted. `flutter_dotenv` and asset-loaded JSON were rejected; see ADR `docs/adr/0003-dart-define-from-file-for-app-config.md`. The decisive factor was web-bundle exposure: any asset or `.env` file in the Flutter web bundle is publicly accessible by URL, and shipping every environment's URLs together leaks internal infrastructure.
- **Configuration matrix: env × platform.** Two axes — env in `{local, prod}`, platform in `{web, android-emulator, ios-simulator, desktop}`. Five files are produced now: `local-web.json`, `local-android-emulator.json`, `local-ios-simulator.json`, `local-desktop.json`, `prod-web.json`. Each file is committed even when its `BASE_URL` is identical to another file's — pre-splitting per platform avoids a rename across launch configurations the first time a platform-specific parameter appears.
- **`prod-mobile.json` is explicitly out of scope.** The Kubernetes ingress at `k8s/06-ingress.yaml` has no domain configured and relies on the ALB-provided DNS name; mobile apps cannot use a relative URL and shipping `https://<ALB-DNS-HERE>/api/v1` as a placeholder is not committed. A real production mobile build is deferred until a real domain exists.
- **File location: `flutter/config/`.** Outside `assets/` so the web bundle does not ship the files. `docker/Dockerfile.flutter`'s `COPY flutter/ .` step picks up the directory automatically; the build runs `--dart-define-from-file=config/prod-web.json` relative to its `WORKDIR /build`.
- **JSON schema.** Flat top-level keys, each consumed by a corresponding `String.fromEnvironment(...)` call. Today: `{ "BASE_URL": "..." }`. The existing `assets/config/*.json` files use a nested object with a `baseUrl` property — that shape is incompatible with `--dart-define-from-file` and is replaced.
- **Per-file values.**
  - `local-web.json` → `BASE_URL = http://127.0.0.1:8000/api/v1`
  - `local-android-emulator.json` → `BASE_URL = http://10.0.2.2:8000/api/v1`
  - `local-ios-simulator.json` → `BASE_URL = http://127.0.0.1:8000/api/v1`
  - `local-desktop.json` → `BASE_URL = http://127.0.0.1:8000/api/v1`
  - `prod-web.json` → `BASE_URL = /api/v1`
- **`AppConfig` shape.** Single freezed immutable data class. One `const factory AppConfig.fromEnvironment()` that calls `String.fromEnvironment('BASE_URL')` with no default. No sealed class hierarchy per environment — the values vary, not the behavior.
- **DI wiring.** A new `@module` (e.g. `ConfigModule`) registers `AppConfig` as a `lazySingleton`. The existing `AppModule.dio()` is changed to take `AppConfig` as a constructor argument and pass `config.baseUrl` into `DioClient.create`. No other call site changes.
- **Fail-loud startup contract.** `main.dart` asserts `getIt<AppConfig>().baseUrl.isNotEmpty` immediately after `configureDependencies()`. On failure, it throws a `StateError` whose message names the missing flag and lists the five valid files. No silent fallback to a default URL.
- **Removal of legacy config inputs.** `pubspec.yaml`'s `- assets/config/` asset entry is removed. `assets/config/dev.json` and `assets/config/prod.json` are deleted. The Dockerfile's `--dart-define=ENVIRONMENT=production` is replaced by `--dart-define-from-file=config/prod-web.json`.
- **No env-name concept in source.** The app does not need to know "is this prod?" — it only needs the `BASE_URL`. If a future feature genuinely requires branching on env, a new field is added to the JSON (e.g. `ENV`) and `AppConfig` learns about it then.
- **Adherence to project rules.** The new files live in `core/config/`, which `features/` may transitively depend on through `core/network/`. `core/` continues to know nothing about `features/`. The freezed file is generated by `dart run build_runner build --delete-conflicting-outputs`. No new third-party dependency is added.

## Testing Decisions

A good test for this slice exercises **the externally observable contract** of the new module — "given a `BASE_URL` definition, Dio is constructed against it; given no definition, the app refuses to start with a message that names the fix." It does NOT assert that `String.fromEnvironment` was called, that `@module` is annotated correctly, or that the freezed file exists. Tests that are coupled to the mechanism rather than the behavior would have to be rewritten every time the JSON schema or the `@module` shape changes.

This slice has no user-case / adapter / Cubit / widget layers, so the default four-layer test policy from `CLAUDE.md` does not map. Tests planned:

- **AppConfig defaults (unit).** Construct `AppConfig.fromEnvironment()` in a process where no `--dart-define` is passed; assert `baseUrl == ''`. Prior art: pure-Dart unit tests under `test/core/` (e.g. `test/core/auth/domain/`), constructing freezed values directly.
- **Startup assertion (unit, on the helper).** Extract the "validate AppConfig non-empty" check into a small pure function (e.g. `requireValidAppConfig(AppConfig)`) and unit-test that it throws a `StateError` whose message contains `--dart-define-from-file`, `flutter/config/`, and at least one valid filename. Keeping the assertion behind a pure helper makes it testable without bootstrapping the full app. Prior art: pure-function tests in `test/core/errors/` and `test/core/rbac/`.
- **AppModule.dio consumes AppConfig (unit).** Construct the module, hand it an `AppConfig(baseUrl: 'https://x/api/v1')`, call `dio(config)`, and assert `dio.options.baseUrl == 'https://x/api/v1'`. Prior art: tests of factory functions in `test/core/network/` (if present) or trivially in this slice's own folder.
- **Build-time smoke (CI, not a Dart test).** A CI job runs `flutter build web --dart-define-from-file=flutter/config/prod-web.json` and `flutter build apk --debug --dart-define-from-file=flutter/config/local-android-emulator.json`, verifying that each commits succeeds. This is a deployment regression guard, not a unit test, and lives in `.github/workflows/ci.yml`.

Adapter / Cubit / Widget tests for downstream slices remain unchanged — they mock `Dio` directly and never see `AppConfig`. No widget-level test is added for the missing-flag path; the startup assert is enforced by the helper unit test.

## Out of Scope

- **`prod-mobile.json`.** No production URL exists for mobile apps until a real domain is configured on the Kubernetes ingress. The file is intentionally not committed; the absence is the documented signal that mobile-in-production is unsolved.
- **Physical-device local configs.** "Local Android device" and "local iOS device" need the dev's LAN IP, which varies per developer. Not in scope until a developer actually requests it; the workaround is to copy `local-android-emulator.json` to a gitignored file and edit the IP.
- **Staging environment.** The current deployment story is local + prod. A `staging-*` set of files can be added when a staging cluster exists.
- **Secret values.** No `flutter/config/*.json` file contains a secret. The current parameter (`BASE_URL`) is not secret, and any future secret stays on the backend; the client reaches it through proxies, never through compile-time injection. The ADR explicitly notes this.
- **Backwards compatibility with the old `assets/config/` files.** They are deleted, not renamed-and-shadowed. No code reads them, so deletion is safe.
- **A runtime "switch env" UI.** The app cannot change env at runtime — `--dart-define-from-file` is compile-time. This is by design; runtime selection would require reintroducing asset-loaded JSON.
- **Nginx config changes.** `Dockerfile.flutter`'s embedded nginx config remains as-is — the relative `/api/v1` baseUrl works with the existing K8s ingress routing.
- **`injectable`'s `Environment.dev` / `.prod` mechanism.** That's an orthogonal axis for swapping adapter implementations and is not used by this slice. `configureDependencies(env: ...)` continues to default to `dev` and is not touched.

## Further Notes

- The ADR for this decision already exists at `docs/adr/0003-dart-define-from-file-for-app-config.md`.
- A short README snippet under `flutter/config/README.md` is desirable but optional — it would list each file with its purpose and the corresponding `flutter run` command. To be settled in `feature-spec`.
- VS Code launch configurations and a future `Makefile` could pre-bake the `--dart-define-from-file` flag per env; these are ergonomic conveniences and not part of this slice's contract.
- The handoff document `handof_flatter_env_001.md` at the repo root captured the option discussion and is superseded by this PRD plus the ADR; it can be archived or deleted once this slice ships.
- The existing `Dockerfile.flutter` flag `--web-renderer canvaskit` is unrelated and remains untouched here.
- This slice does not affect the user-id / handle migration tracked in slices 0044–0055.
