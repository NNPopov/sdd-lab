# Plan — 0040 extend_locales

## Task

Extend the app locale support from 2 locales (`en`, `ru`) to 4 regional locales
(`en-US`, `ru-RU`, `es-ES`, `uk-UA`). This is a pure infrastructure change:
no new screens, no new slices, no new DI registrations. Every change stays inside
`core/i18n/`, `core/widgets/locale_selector_button.dart`, and the two test files.

---

## Context

### Read

- `CLAUDE.md` — hard rules and verification checklist
- `lib/core/i18n/i18n/en.json` — 223 strings, source of truth for translations
- `lib/core/i18n/i18n/ru.json` — existing Russian translation (rename target)
- `lib/core/i18n/locale_cubit.dart` — locale orchestration; state is `AppLocale`
- `lib/core/i18n/locale_storage_port.dart` — port interface
- `lib/core/i18n/hive_locale_storage_adapter.dart` — Hive persistence; uses `locale.languageTag`
- `lib/core/widgets/locale_selector_button.dart` — hardcoded `_nativeNames` map to update
- `test/core/i18n/locale_cubit_test.dart` — tests to extend
- `test/core/i18n/hive_locale_storage_adapter_test.dart` — tests to extend
- `slang.yaml` — `base_locale` to update
- `agent_docs/localization.md` — project localization conventions

### Do NOT Read

- Any feature slice (`lib/features/**`)
- Generated files (`*.g.dart`, `*.freezed.dart`)
- `lib/core/routing/**`, `lib/core/auth/**`

---

## No API

This slice has no backend API. All changes are local to the app.

---

## Target File Set

Files **renamed**:
```
lib/core/i18n/i18n/en.json         → en-US.json
lib/core/i18n/i18n/ru.json         → ru-RU.json
```

Files **created**:
```
lib/core/i18n/i18n/es-ES.json      (new — machine-translated from en-US.json)
lib/core/i18n/i18n/uk-UA.json      (new — machine-translated from en-US.json)
```

Files **modified**:
```
slang.yaml                                          (base_locale: en → en-US)
lib/core/i18n/translations.g.dart                  (regenerated)
lib/core/i18n/translations_en.g.dart               (regenerated, renamed internally)
lib/core/i18n/translations_ru.g.dart               (regenerated, renamed internally)
lib/core/i18n/translations_es_es.g.dart            (new, generated)
lib/core/i18n/translations_uk_ua.g.dart            (new, generated)
lib/core/widgets/locale_selector_button.dart        (_nativeNames map + button label)
test/core/i18n/locale_cubit_test.dart              (AppLocale refs + new cases)
test/core/i18n/hive_locale_storage_adapter_test.dart (AppLocale refs + new cases)
```

No other files touched.

---

## Step-by-Step Implementation

### Step 1 — Update slang.yaml

Change:
```
base_locale: en
```
To:
```
base_locale: en-US
```

Everything else in `slang.yaml` remains unchanged.

### Step 2 — Rename and create JSON source files

1. Rename `lib/core/i18n/i18n/en.json` → `en-US.json` (content unchanged).
2. Rename `lib/core/i18n/i18n/ru.json` → `ru-RU.json` (content unchanged).
3. Create `lib/core/i18n/i18n/es-ES.json` — full machine translation of all 223 keys into
   Castilian Spanish. Preserve all interpolation variables exactly (`$username`,
   `{name}`) and all structural nesting identical to `en-US.json`.
4. Create `lib/core/i18n/i18n/uk-UA.json` — full machine translation of all 223 keys into
   Ukrainian. Same rules: preserve variables and structure.

**Translation guidelines (es-ES):**
- Use formal "usted" register where appropriate; prefer neutral register overall.
- Keep technical labels short: "Nombre de usuario", "Contraseña", "Guardar", etc.
- Character-count-sensitive fields (titleTooShort/titleTooLong) keep the original
  English character limits — only translate the surrounding prose.

**Translation guidelines (uk-UA):**
- Use standard Ukrainian orthography (post-2019 reform).
- Preserve Cyrillic; do not transliterate.
- Same character-limit rules as above.

### Step 3 — Regenerate slang output

Run:
```
dart run slang
```

This replaces all `*.g.dart` files under `lib/core/i18n/`. The generated
`AppLocale` enum will now contain:

```dart
enum AppLocale {
  enUs,   // languageTag: 'en-US'
  ruRu,   // languageTag: 'ru-RU'
  esEs,   // languageTag: 'es-ES'
  ukUa,   // languageTag: 'uk-UA'
}
```

Do not hand-edit generated files.

### Step 4 — Update locale_selector_button.dart

Two changes:

**a) Button label** — replace `locale.languageTag.toUpperCase()` with the
language subtag only, so the button shows `EN` / `RU` / `ES` / `UK` instead
of `EN-US` / `RU-RU` / etc.:

```dart
child: Text(locale.languageTag.split('-').first.toUpperCase()),
```

**b) `_nativeNames` map** — replace the existing two-entry map:

```dart
static const Map<AppLocale, String> _nativeNames = {
  AppLocale.enUs: 'English',
  AppLocale.ruRu: 'Русский',
  AppLocale.esEs: 'Español',
  AppLocale.ukUa: 'Українська',
};
```

### Step 5 — Update Dart references to AppLocale enum values

Find every reference to the old enum values and rename:

| Old | New |
|---|---|
| `AppLocale.en` | `AppLocale.enUs` |
| `AppLocale.ru` | `AppLocale.ruRu` |

Known locations:
- `locale_cubit_test.dart` — `registerFallbackValue(AppLocale.en)`, all
  `AppLocale.en` / `AppLocale.ru` in `blocTest` bodies
- `hive_locale_storage_adapter_test.dart` — `AppLocale.en` / `AppLocale.ru`
  in save/load assertions; stored tag strings `'en'` → `'en-US'`, `'ru'` → `'ru-RU'`

Run `dart analyze` to catch any missed reference.

### Step 6 — Extend tests

**locale_cubit_test.dart** — add two `blocTest` cases inside `group('setLocale()')`:

```
setLocale(AppLocale.esEs) → emits [AppLocale.esEs],
  verify: saveLocale(AppLocale.esEs) called once

setLocale(AppLocale.ukUa) → emits [AppLocale.ukUa],
  verify: saveLocale(AppLocale.ukUa) called once
```

Also update `registerFallbackValue` to use `AppLocale.enUs`.

**hive_locale_storage_adapter_test.dart** — add cases in both groups:

In `group('saveLocale()')`:
```
stores 'es-ES' for AppLocale.esEs
stores 'uk-UA' for AppLocale.ukUa
```

In `group('loadLocale()')`:
```
returns AppLocale.esEs after saveLocale(AppLocale.esEs)
returns AppLocale.ukUa after saveLocale(AppLocale.ukUa)
```

### Step 7 — Verify

Run in order:
```
dart format .
dart analyze
flutter test test/core/i18n/
```

All must pass with zero warnings and zero failures.

---

## Tests

See Step 6 above. No new test files — extend the two existing files.

Test quality rule: assert only on the public contract (emitted `AppLocale` value,
stored/loaded tag string). Do not assert on Hive box names or slang internals.

---

## Report

Provide on completion:
- List of renamed files, new files, and modified files
- Confirmation that no feature slice was touched
- Output of `dart analyze` (must be clean)
- Output of `flutter test test/core/i18n/` (must be green)
- Screenshot or text of the locale selector showing all four entries

---

## Out of Scope

- DO NOT create a new slice folder or route for this change.
- DO NOT modify `main.dart`, `app_router.dart`, or DI configuration — the
  `LocaleCubit` is already registered as `@lazySingleton` and needs no changes.
- DO NOT add human-reviewed translations — machine quality is accepted.
- DO NOT add `es-MX`, `es-AR`, or any other regional variant.
- DO NOT change the Hive box name (`"locale"`) or key (`"locale"`).
- DO NOT run `build_runner` — slang is invoked via `dart run slang` only
  (as specified in `build.yaml`).
- DO NOT touch any file outside `lib/core/i18n/`, `lib/core/widgets/locale_selector_button.dart`,
  and the two test files. If another file needs to change — stop and report.
