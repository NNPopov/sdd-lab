# 0040 · extend_locales — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The app supports exactly four locales: en-US (English), ru-RU (Russian), es-ES (Castilian Spanish), and uk-UA (Ukrainian). |
| F2 | The locale selector bottom sheet lists all four locales, each identified by its native name: "English", "Русский", "Español", "Українська". |
| F3 | Selecting a locale from the bottom sheet applies the corresponding translation to all visible UI strings immediately. |
| F4 | The selected locale is persisted to local storage and restored on the next app launch. |
| F5 | The AppBar locale button displays the two-letter language subtag of the active locale in uppercase (e.g. "EN", "RU", "ES", "UK"). |
| F6 | If the value stored in local storage does not match any supported locale tag, the app silently falls back to the default locale (en-US) without throwing an error or showing a crash screen. |
| F7 | All 223 translation keys defined in en-US.json are present in every locale JSON file (ru-RU, es-ES, uk-UA); no key may be absent from any file. |
| F8 | Selecting es-ES renders all app UI strings in Castilian Spanish, including authentication, navigation, posts, tiers, and user management screens. |
| F9 | Selecting uk-UA renders all app UI strings in Ukrainian, covering the same set of screens as F8. |
| F10 | The locale selection made by the user survives app restart and is restored without requiring the user to re-select. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | All locale codes use BCP 47 regional tags (en-US, ru-RU, es-ES, uk-UA); no bare language-only tags (en, ru) remain anywhere in source code, JSON files, or configuration. |
| N2 | `slang.yaml` has `base_locale: en-US`; the base JSON file is named `en-US.json`. |
| N3 | The generated `AppLocale` enum contains exactly four values: `enUs`, `ruRu`, `esEs`, `ukUa`, with `languageTag` properties `"en-US"`, `"ru-RU"`, `"es-ES"`, `"uk-UA"` respectively. |
| N4 | `HiveLocaleStorageAdapter._parseLocale` returns `null` for any tag that does not match a known `AppLocale.languageTag`; it must not throw. |
| N5 | The locale button label in `LocaleSelectorButton` is derived from `locale.languageTag` at runtime (e.g. `languageTag.split('-').first.toUpperCase()`); no locale code is hardcoded in widget source. |
| N6 | `dart run slang` completes with zero warnings after all four JSON files are in place. |
| N7 | No `*.g.dart` file is hand-edited; all locale content changes flow through the JSON source files followed by `dart run slang`. |
| N8 | `dart format .` produces no diff and `dart analyze` reports zero warnings after all changes. |
| N9 | The only files modified outside `lib/core/i18n/` are `lib/core/widgets/locale_selector_button.dart` and the two test files under `test/core/i18n/`; no feature slice or other core module is touched. |
| N10 | The `HiveLocaleStorageAdapter` test suite covers save/load round-trips for all four `AppLocale` values, including `esEs` and `ukUa`. |
| N11 | The `LocaleCubit` test suite covers `setLocale` for all four `AppLocale` values, including `esEs` and `ukUa`. |
| N12 | Locale codegen is invoked exclusively via `dart run slang`; `build_runner` is not used for this task. |
| N13 | Interpolation variables (`$username`, `{name}`) and structural key nesting are identical across all four locale JSON files. |

## Out of scope

- Human proofreading or professional translation of es-ES.json or uk-UA.json.
- Regional variants beyond es-ES (e.g. es-MX, es-AR, es-419).
- Right-to-left layout support.
- Plural form rules for Spanish or Ukrainian beyond what slang derives from the English base.
- Hive data migration for devices that have the legacy `"en"` or `"ru"` string stored — the existing null-return fallback in the adapter handles these gracefully.
- Any change to the locale-switching UI beyond the native-name map and the button label computation.
