# 0056 · app_config_per_platform — Outside-in test spec

## Goal

Prove the slice's externally observable contract: given a resolved `AppConfig`, the
HTTP client is constructed against its `baseUrl`; given an empty config (no
`--dart-define-from-file`), the startup guard refuses to proceed with a message that
names the fix.

> **Note on shape.** This is a core-infrastructure slice with **no Cubit, no port,
> no use-case, and no network boundary**. The usual "mock Dio, wire the Cubit"
> outside-in shape does not apply: `Dio` here is the *artifact being built*, not a
> collaborator to stub. The outside-in surface is therefore the two pure entry
> points below. Nothing is mocked — there is no system boundary to fake. A
> build-time smoke test (real `flutter build` with each config file) is the true
> end-to-end guard and lives in CI (`.github/workflows/ci.yml`), not in `flutter test`.

## Entry point

Two public-surface calls, exercised in one test file:

- `AppModule().dio(config)` — the DI factory that downstream code consumes.
- `requireValidAppConfig(config)` — the startup fail-loud guard from `main.dart`.

## Wired real (production code in the test)

- `AppConfig` (the freezed config data class)
- `AppModule` (the `@module` whose `dio(AppConfig)` factory builds the client)
- `DioClient.create` (transitively exercised through `AppModule.dio`)
- `requireValidAppConfig` (the pure startup guard)

## Mocked (system boundaries only)

- **Nothing.** There is no network call, no storage, and no other process boundary
  in this slice. `AppConfig` is constructed directly with a literal `baseUrl`; no
  `--dart-define-from-file` flag is passed to the test process (the default for
  `flutter test`).

## Test scenarios

### Scenario 1: configured baseUrl flows through to the Dio client

**Setup:**
- `const config = AppConfig(baseUrl: 'https://x/api/v1');`

**Act:**
- `final dio = AppModule().dio(config);`

**Expect:**
- `dio.options.baseUrl == 'https://x/api/v1'`.
- `requireValidAppConfig(config)` returns normally (does not throw).
- No side effects, no exceptions.

### Scenario 2: missing/empty config fails loud at the startup guard

**Setup:**
- `const config = AppConfig(baseUrl: '');` (the value `String.fromEnvironment('BASE_URL')`
  resolves to when no `--dart-define-from-file` flag was passed).

**Act:**
- `requireValidAppConfig(config)`

**Expect:**
- Throws a `StateError`.
- The thrown message contains all of: the substring `--dart-define-from-file`, the
  substring `flutter/config/`, and at least one valid filename (e.g.
  `local-desktop.json`).
- `AppModule().dio(config)` is **not** reached at startup because the guard throws
  first (the test asserts the guard throws before any client is used).

## Out of scope for this test

- The actual `flutter build web/apk` with each config file — covered by the CI
  build-time smoke job, not by `flutter test`.
- Verifying that `String.fromEnvironment('BASE_URL')` was called or that the JSON
  files parse — mechanism detail, not observable behaviour.
- DI-graph wiring assertions (`@module`/`@lazySingleton` annotations) — covered by
  `build_runner` succeeding, not by a runtime test.
- Deletion of `assets/config/*` and the `pubspec.yaml` asset entry — verified by
  code review (validation.md), not by a Dart test.
