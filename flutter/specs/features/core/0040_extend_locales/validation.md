# 0040 · extend_locales — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Tap the locale button in the AppBar while any locale is active | Bottom sheet opens with exactly four entries: "English", "Русский", "Español", "Українська" |
| M2 | With en-US active, inspect the AppBar locale button label | Button shows "EN" — not "EN-US" |
| M3 | With ru-RU active, inspect the AppBar locale button label | Button shows "RU" — not "RU-RU" |
| M4 | Select "Español" from the bottom sheet | AppBar button immediately shows "ES"; all currently visible strings switch to Spanish |
| M5 | With es-ES active, navigate to the Login screen | Title, field labels ("Nombre de usuario", "Contraseña"), and button caption display in Spanish |
| M6 | With es-ES active, navigate to the Tiers list | Section title, empty-state message, and any error banner display in Spanish |
| M7 | With es-ES active, open the create-post screen | All labels, hints, and button captions display in Spanish |
| M8 | Select "Українська" from the bottom sheet | AppBar button immediately shows "UK"; all currently visible strings switch to Ukrainian |
| M9 | With uk-UA active, navigate to the Login screen | Title, field labels, and button caption display in Ukrainian (Cyrillic) |
| M10 | With uk-UA active, navigate to the Users list | Section title, list items, and action labels display in Ukrainian |
| M11 | Select "Español", force-quit and reopen the app | App reopens in Spanish without requiring re-selection |
| M12 | Select "Українська", force-quit and reopen the app | App reopens in Ukrainian without requiring re-selection |
| M13 | Select "English", force-quit and reopen the app | App reopens in English |
| M14 | Using Hive Inspector or a debug build helper, write the string `"en"` to the locale Hive box, then cold-start the app | App starts in English (en-US) without a crash, error dialog, or unhandled exception |
| M15 | Using the same method, write `"de"` (an unsupported tag) to the locale Hive box, then cold-start the app | App starts in the default locale (en-US) without a crash |
| M16 | Open the locale bottom sheet while es-ES is active | A checkmark (✓) icon appears next to "Español" and only next to "Español" |
| M17 | Open the locale bottom sheet while uk-UA is active | A checkmark (✓) icon appears next to "Українська" and only next to "Українська" |
| M18 | With es-ES active, open a tier-details screen and trigger a "not found" error | Error message displays in Spanish |
| M19 | With uk-UA active, open the delete-account confirmation dialog | Dialog title, message, and both button captions display in Ukrainian |

## Code review

- [ ] `slang.yaml` contains `base_locale: en-US`; the base JSON file is named `en-US.json`
- [ ] Four JSON files exist under `lib/core/i18n/i18n/`: `en-US.json`, `ru-RU.json`, `es-ES.json`, `uk-UA.json`
- [ ] `es-ES.json` and `uk-UA.json` contain the same top-level keys and nesting structure as `en-US.json` — no key is missing or extra (confirmed by slang completing with zero warnings)
- [ ] Interpolation variables (`$username`, `{name}`) are preserved verbatim in `es-ES.json` and `uk-UA.json`
- [ ] Generated `AppLocale` enum contains exactly four values: `enUs`, `ruRu`, `esEs`, `ukUa`
- [ ] `grep -rn "AppLocale\.en[^U]" lib/` returns zero matches (old `AppLocale.en` fully replaced)
- [ ] `grep -rn "AppLocale\.ru[^R]" lib/` returns zero matches (old `AppLocale.ru` fully replaced)
- [ ] `LocaleSelectorButton._nativeNames` map contains exactly four entries: `enUs → "English"`, `ruRu → "Русский"`, `esEs → "Español"`, `ukUa → "Українська"`
- [ ] `LocaleSelectorButton` button label uses `locale.languageTag.split('-').first.toUpperCase()` — no hardcoded locale code string in the widget
- [ ] `HiveLocaleStorageAdapter._parseLocale` iterates `AppLocale.values` and matches on `languageTag`; the method returns `null` for unrecognised tags and does not throw
- [ ] `hive_locale_storage_adapter_test.dart` contains save/load round-trip test cases for `AppLocale.esEs` (`"es-ES"`) and `AppLocale.ukUa` (`"uk-UA"`)
- [ ] `locale_cubit_test.dart` contains `setLocale` test cases for `AppLocale.esEs` and `AppLocale.ukUa` that verify both the emitted state and the `saveLocale` call
- [ ] The diff contains no changes outside `lib/core/i18n/`, `lib/core/widgets/locale_selector_button.dart`, `slang.yaml`, and `test/core/i18n/` — no feature slice or other core module is touched
- [ ] No `*.g.dart` file under `lib/core/i18n/` has been hand-edited (slang re-run produces an identical result)
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
