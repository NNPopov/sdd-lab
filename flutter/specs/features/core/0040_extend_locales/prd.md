# PRD — 0040 extend_locales

## Problem Statement

The app currently supports two locales — English (`en`) and Russian (`ru`) — using non-regional language tags. This prevents:

1. Adding new languages with the same base code but different regions (e.g. `es-MX` alongside `es-ES`).
2. Reaching Spanish-speaking and Ukrainian-speaking user segments.
3. Maintaining a consistent naming convention across all supported locales.

## Solution

Rename the existing locales to regional tags (`en-US`, `ru-RU`), and add two new fully-translated locales: Castilian Spanish (`es-ES`) and Ukrainian (`uk-UA`). Translations are auto-generated from the English source. All four locales appear in the in-app locale selector. The generated slang enum and all Dart code references are updated accordingly.

## User Stories

1. As a Spanish-speaking user, I want to switch the app language to Español, so that I can use the app comfortably in my native language.
2. As a Ukrainian-speaking user, I want to switch the app language to Українська, so that I can read all app text in Ukrainian.
3. As any user, I want to see Spanish listed as "Español" in the language selector, so that I can identify it by its native name without knowing English.
4. As any user, I want to see Ukrainian listed as "Українська" in the language selector, so that I can identify it by its native name.
5. As any user, I want my previously-selected language (English or Russian) to be preserved after the app update, so that I don't need to re-select my language — or, if the stored tag is no longer recognised, the app falls back to the default locale without crashing.
6. As any user, I want all four locales — English, Russian, Spanish, Ukrainian — to appear in the locale selector bottom sheet, so that I can choose any of them.
7. As a developer, I want all locale tags to use regional codes (`en-US`, `ru-RU`, `es-ES`, `uk-UA`), so that the convention is consistent and extensible.
8. As a developer, I want the slang-generated `AppLocale` enum to reflect the new regional codes (`enUs`, `ruRu`, `esEs`, `ukUa`), so that compile-time safety is maintained everywhere locale values are used.
9. As a developer, I want the `HiveLocaleStorageAdapter` to return `null` (triggering fallback to the default locale) for any stored tag it does not recognise, so that legacy `"en"` / `"ru"` values stored in Hive do not cause a runtime error after the rename.
10. As a developer, I want the `LocaleSelectorButton` native-name map to include all four locales with their native names, so that new locales display correctly without additional code changes.
11. As a QA engineer, I want parametrised smoke tests for the two new locales in `locale_cubit_test` and `hive_locale_storage_adapter_test`, so that save/load round-trips for `es-ES` and `uk-UA` are explicitly verified.

## Implementation Decisions

### Locale code renaming

- Source JSON files renamed: `en.json` → `en-US.json`, `ru.json` → `ru-RU.json`.
- New source JSON files created: `es-ES.json`, `uk-UA.json`.
- `slang.yaml` `base_locale` updated from `en` to `en-US`.
- slang regenerated via `dart run slang`; all generated `.g.dart` files replaced.

### AppLocale enum values

| Old | New |
|---|---|
| `AppLocale.en` | `AppLocale.enUs` |
| `AppLocale.ru` | `AppLocale.ruRu` |
| — | `AppLocale.esEs` |
| — | `AppLocale.ukUa` |

All Dart references updated in a single pass.

### Translations

- `es-ES.json` and `uk-UA.json` populated with machine translations covering all 223 keys.
- No placeholder or `(ignored)` markers needed — full coverage for all keys.
- Translation quality is acceptable for a test application; no human review required.

### Locale selector native names

The hardcoded map in `LocaleSelectorButton` extended to four entries:

| Tag | Display name |
|---|---|
| `en-US` | English |
| `ru-RU` | Русский |
| `es-ES` | Español |
| `uk-UA` | Українська |

### Hive persistence migration

- No migration logic required (no production release has occurred).
- `HiveLocaleStorageAdapter` already returns `null` for unrecognised tags; legacy `"en"` / `"ru"` values will cause a transparent fallback to the default locale (`en-US`) on first launch after update.

### Lazy loading

New locale classes (`translations_es_es.g.dart`, `translations_uk_ua.g.dart`) imported as `deferred` in the generated file, consistent with the existing Russian locale pattern.

### Code generation

Run `dart run slang` (not `build_runner`) after modifying JSON files, as specified in `build.yaml`.

## Testing Decisions

### What makes a good test here

Tests should verify observable behaviour — that a given `AppLocale` value is correctly serialised to / deserialised from its language tag string, and that the `LocaleCubit` emits the expected state. Tests must not assert on internal Hive key names or slang internals.

### Modules to test

- **`HiveLocaleStorageAdapter`** — extend the existing parametrised test to include `(AppLocale.esEs, 'es-ES')` and `(AppLocale.ukUa, 'uk-UA')` round-trip cases.
- **`LocaleCubit`** — extend the existing `setLocale` parametrised test to include `esEs` and `ukUa` cases, verifying the cubit emits the new locale and persists it.

### Prior art

- `test/core/i18n/locale_cubit_test.dart` — existing parametrised `setLocale` tests for `en` and `ru`.
- `test/core/i18n/hive_locale_storage_adapter_test.dart` — existing round-trip tests.

Widget and use-case layers are not affected; no new widget or use-case tests are required.

## Out of Scope

- Human proofreading or professional translation of `es-ES.json` or `uk-UA.json`.
- Regional variants beyond `es-ES` (e.g. `es-MX`, `es-AR`).
- Plural forms for Spanish and Ukrainian beyond what slang auto-handles from the English base.
- Right-to-left layout support (neither Spanish nor Ukrainian is RTL).
- Any change to the locale-switching UI beyond updating the native-name map.
- Adding a fourth locale to screens that currently only reference `AppLocale.en` / `AppLocale.ru` by name — all such references are updated as part of the rename, not extended.

## Further Notes

- slang version in use: `^4.0.0`. Regional locale codes (`en-US`) are fully supported by this version.
- The `build.yaml` disables `slang_build_runner`; slang must be run manually with `dart run slang`.
- After codegen, `dart format .` and `dart analyze` must both pass with no warnings before the slice is considered done.
- The outside-in test for this slice is a Dart test that verifies the full save → restart → load → emit cycle for all four locales.
