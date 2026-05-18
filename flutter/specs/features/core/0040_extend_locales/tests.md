# 0040 · extend_locales — Outside-in test spec

## Goal

Prove that a newly-added locale (`es-ES` or `uk-UA`) can be selected via
`LocaleCubit`, persisted to Hive by `HiveLocaleStorageAdapter`, and correctly
restored on the next "app launch" — and that a pre-existing unrecognised tag
stored in Hive (e.g. the legacy `"en"` from before the rename) causes a silent
fallback to the default locale without crashing.

## Entry point

Scenario 1: `cubit.setLocale(AppLocale.esEs)` followed by `cubit2.init()` on a
second cubit instance backed by the same Hive directory (simulating an app restart).

Scenario 2: `cubit.init()` on a cubit whose adapter reads a Hive box that has
been pre-populated with the legacy tag `"en"`.

## Wired real (production code in the test)

- `HiveLocaleStorageAdapter` (implements `LocaleStoragePort`; backed by a
  temp-directory Hive instance — same approach as `hive_locale_storage_adapter_test.dart`)
- `LocaleStoragePort` (bound to the real adapter, not a mock)
- `LocaleCubit` (the system under test; constructed twice in Scenario 1 to
  simulate an app restart)

## Mocked (system boundaries only)

- **Hive storage**: not mocked — a real `Hive.init(tempDir.path)` instance is
  used, consistent with existing adapter tests. This is a local I/O boundary,
  not a network boundary, and the existing test suite already validates this
  pattern as acceptable.
- **`AppLogger`**: mocked with mocktail (injected into `HiveLocaleStorageAdapter`;
  no calls are expected on the happy path; `logger.error` is not expected in
  either scenario below).

## Test scenarios

### Scenario 1: new locale es-ES is selected, persisted, and restored across restart

**Setup:**
- Initialise Hive with a fresh temporary directory.
- Construct `HiveLocaleStorageAdapter(mockLogger)`.
- Construct `LocaleCubit(adapter)` — call this `cubit1`.

**Act (first launch):**
- Call `cubit1.setLocale(AppLocale.esEs)`.

**Expect (first launch):**
- States emitted by `cubit1`: `[AppLocale.esEs]`
- The Hive box named `"locale"` contains the string `"es-ES"` at key `"locale"`.
- `logger.error` is never called.

**Act (simulated restart — same Hive directory, new cubit instance):**
- Construct a second `LocaleCubit(adapter)` — call this `cubit2`.
- Call `cubit2.init()`.

**Expect (restart):**
- States emitted by `cubit2`: `[AppLocale.esEs]`
- The restored locale matches `AppLocale.esEs` (language tag `"es-ES"`).

---

### Scenario 2: legacy tag "en" stored in Hive falls back silently to default

**Setup:**
- Initialise Hive with a fresh temporary directory.
- Open the `"locale"` box directly and write the string `"en"` at key `"locale"`
  (simulating data written by the app before the rename to regional codes).
- Construct `HiveLocaleStorageAdapter(mockLogger)`.
- Construct `LocaleCubit(adapter)`.

**Act:**
- Call `cubit.init()`.

**Expect:**
- States emitted by `cubit`: `[]` — no emission, because `_parseLocale("en")`
  returns `null` and the cubit leaves the slang default locale unchanged.
- No exception is thrown.
- `logger.error` is never called (the `null` return is a normal code path, not
  an error condition).

## Out of scope for this test

- Widget rendering (covered by widget tests separately).
- Route navigation (not applicable — this slice has no screen).
- The `uk-UA` locale round-trip (covered by the extended unit tests in
  `hive_locale_storage_adapter_test.dart` and `locale_cubit_test.dart`; the
  outside-in test uses `es-ES` as a representative new locale).
- The `LocaleSelectorButton` UI (covered by widget tests separately after the
  implementation is green).
- Slang translation content correctness (`es-ES.json`, `uk-UA.json`); that is
  a content concern verified manually per validation.md M4–M10.
