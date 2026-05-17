# PRD: 0020 — Language Selection Button (Locale Selector)

## Problem Statement

Users cannot change the application interface language while using it. The language is fixed at startup and is not persisted between sessions. For an application targeting both Russian- and English-speaking audiences, the absence of a language switcher degrades the user experience.

## Solution

A button with the short code of the current locale ("EN" / "RU") is added to the top of the screen (AppBar). Tapping it opens a modal bottom sheet with a list of available languages. The selected language is applied immediately and saved to local storage (Hive) — on the next launch the app starts with the saved locale.

## User Stories

1. As a user, I want to see the current interface language as a short label in the AppBar, so that I understand which language the app is currently running in.
2. As a user, I want to tap the language button and see a list of available languages, so that I can choose the one I need.
3. As a user, I want to see language names in their native language ("English", "Русский"), so that I can easily identify the desired language.
4. As a user, I want to see a checkmark next to the active language in the list, so that I know which language is currently selected.
5. As a user, I want the selected language to be applied immediately without restarting the app, so that the change is convenient and fast.
6. As a user, I want the selected language to be saved when closing and reopening the app, so that I don't have to switch the language every time.
7. As an unauthenticated user, I want access to the language button next to the "Sign In" button, so that I can choose a language before logging in.
8. As an authenticated user, I want access to the language button regardless of authorization state, so that I can change the language at any time.
9. As a user, I want to close the bottom sheet without selecting a language (swipe or tap outside the area), so that I don't accidentally change the language.
10. As a user, I want the interface to fully re-render in the new language after switching (including AppBar, tabs, form texts), without needing to restart.

## Implementation Decisions

### Modules

| Module | Action | Description |
|---|---|---|
| `LocaleStoragePort` | New | Narrow port: `saveLocale(AppLocale)` and `Future<AppLocale?> loadLocale()` |
| `HiveLocaleStorageAdapter` | New | Implements `LocaleStoragePort` via Hive. Stores locale code as a string ("en", "ru") |
| `LocaleCubit` | Modified | Receives `LocaleStoragePort` via DI constructor; adds `init()` method — loads saved locale and emits it |
| `LocaleSelectorButton` | New | Stateless widget in `core/widgets/`. Reads current locale from `LocaleCubit` via `BlocBuilder`, displays "EN"/"RU". On tap shows `_LocaleBottomSheet` |
| `AppShellScreen` | Modified | Adds `LocaleSelectorButton` as the first element in AppBar `actions` (to the left of `_AuthAppBarAction`) |
| `main.dart` | Modified | After `configureDependencies()` calls `localeCubit.init()` to load the saved locale |
| `pubspec.yaml` | Modified | Adds `hive` + `hive_flutter` |

### Architectural Decisions

- `LocaleSelectorButton` — reusable widget in `core/widgets/`, not embedded in app_shell_screen.dart as a private class.
- `LocaleStoragePort` and `HiveLocaleStorageAdapter` live in `core/i18n/` (domain + data), alongside `LocaleCubit`.
- `LocaleCubit` does not read/write storage directly — only through the port. This ensures testability.
- Locale initialization happens via an explicit `init()`, called from `main.dart` — no async operations in the constructor.
- `HiveLocaleStorageAdapter` stores the locale as a string (code: "en", "ru") in a named Hive box. Parsing the code into `AppLocale` — inside the adapter.
- The button remains visible in any `AuthCubit` state — this is a global app setting, independent of authorization.

### Port Interface

```
LocaleStoragePort:
  Future<void> saveLocale(AppLocale locale)
  Future<AppLocale?> loadLocale()
```

### LocaleCubit.init() Behaviour

1. Calls `_storage.loadLocale()`
2. If a saved locale is found — calls `setLocale(savedLocale)`
3. If not — stays on `LocaleSettings.currentLocale` (system locale by default)

### LocaleCubit.setLocale() Behaviour

1. Calls `LocaleSettings.setLocale(locale)` (slang)
2. Calls `_storage.saveLocale(locale)` (persistence)
3. Emits the applied locale

### Bottom Sheet

- No header required — the list of languages speaks for itself.
- Each item: language name in its native language + `Icon(Icons.check)` on the right if it is the current locale.
- After selection, the bottom sheet closes automatically.

## Testing Decisions

**Principle:** test the external behaviour of the module, not implementation details.

### What to test

| Module | Test type | What we verify |
|---|---|---|
| `LocaleCubit` | `bloc_test` | `init()` with saved locale → emits saved; `init()` without saved → stays on current; `setLocale(ru)` → emits `AppLocale.ru` and calls `saveLocale` |
| `HiveLocaleStorageAdapter` | Unit | `saveLocale` → writes code; `loadLocale` → returns correct `AppLocale`; `loadLocale` with empty box → returns `null`; unknown code → returns `null` |
| `LocaleSelectorButton` | Widget test | Displays current locale code; after tap — bottom sheet visible; tapping a language in the sheet → `LocaleCubit.setLocale` is called |

### Mocks

- `LocaleStoragePort` is mocked via `mocktail`.
- `LocaleCubit` is mocked via `mocktail` in widget tests for `LocaleSelectorButton`.

### Prior Art Examples

- `test/core/auth/application/auth_cubit_test.dart` — `bloc_test` pattern with mocktail.
- `test/features/users/list_users/` — widget test pattern with mocked Cubit.

## Out of Scope

- Adding new languages (beyond EN and RU, already supported by `slang`).
- Language detection by geolocation or IP.
- A dedicated settings page with a language option.
- Country flags in the interface.
- Automatic switching to the device language on first launch (`LocaleSettings.currentLocale` is used).
- RTL support.

## Further Notes

- `hive` is included in the CLAUDE.md §2 tech stack as a planned dependency for caching — this is its first use in the project. Hive must be initialized (`Hive.initFlutter()`) in `main.dart` before `configureDependencies()`.
- This slice has no domain-usecase layer (like `0007_app_shell`) — `LocaleCubit` orchestrates the port directly, since the logic is trivial (save/load a string).
- Codegen is not required after implementation (no changes to `auto_route`/`retrofit`/`freezed`), but `dart run slang` is needed if new i18n keys are added for the bottom sheet title.
