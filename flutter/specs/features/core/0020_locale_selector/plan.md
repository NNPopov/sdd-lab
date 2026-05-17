# Plan: 0020 — Language Selection Button (Locale Selector)

## Title

Task: add a language selection button to the application AppBar (`core/i18n` + `core/widgets`).
The button shows the current locale code ("EN"/"RU"), and on tap opens a bottom sheet with a list
of languages. The selected language is applied immediately and saved in Hive — on the next launch
the app starts with the saved locale.

**This is a core slice without a domain-usecase layer.** `LocaleCubit` orchestrates `LocaleStoragePort`
directly — the logic is trivial (save/load a string).

---

## Context

### READ:
- `@CLAUDE.md` in full
- `@lib/core/i18n/locale_cubit.dart` — will be modified: add `@lazySingleton`, `LocaleStoragePort` in constructor, `init()` method
- `@lib/core/i18n/translations.g.dart` — to understand the types `AppLocale`, `LocaleSettings`, `AppLocaleUtils`
- `@lib/core/routing/app_shell_screen.dart` — will be modified: add `LocaleSelectorButton` to `actions`
- `@lib/main.dart` — will be modified: `Hive.initFlutter()`, `localeCubit.init()`, `BlocProvider.value`
- `@lib/core/auth/application/auth_cubit.dart` — pattern for `@lazySingleton` + `BlocProvider.value` in main
- `@lib/core/di/injection.dart` — understand the import format in generated DI
- `@pubspec.yaml` — will be modified: add `hive` and `hive_flutter`
- `@.claude/skills/bloc/SKILL.md`

### DO NOT READ:
- `@lib/core/routing/app_router.gr.dart` (generated)
- `@lib/core/di/injection.config.dart` (generated)
- `@lib/features/**` — no features are affected
- `@lib/core/auth/data/**` — not needed
- `@lib/core/auth/infrastructure/**` — not needed
- `@lib/core/rbac/**` — not needed

---

## API

No HTTP calls. Storage — Hive box `"locale"`, key `"locale"`, value — locale code string
(`"en"` / `"ru"`).

---

## Target Structure

### New files:

```
lib/core/i18n/
├── locale_storage_port.dart          # narrow port: saveLocale + loadLocale
└── hive_locale_storage_adapter.dart  # @LazySingleton(as: LocaleStoragePort)

lib/core/widgets/                     # folder created for the first time
└── locale_selector_button.dart       # stateless, BlocBuilder<LocaleCubit>
                                      # + private _LocaleBottomSheet
```

### Files to modify:

```
lib/core/i18n/locale_cubit.dart       # @lazySingleton, constructor with port, init()
lib/core/routing/app_shell_screen.dart # add LocaleSelectorButton to actions
lib/main.dart                          # Hive.initFlutter, localeCubit.init(), BlocProvider.value
pubspec.yaml                           # hive: ^2.x, hive_flutter: ^1.x
```

---

## What to do

### 1) DEPENDENCIES — pubspec.yaml

Add to `dependencies:`:
```yaml
hive: ^2.2.3
hive_flutter: ^1.1.0
```

Run `flutter pub get`.

---

### 2) PORT — locale_storage_port.dart

Create `lib/core/i18n/locale_storage_port.dart`:

```dart
import 'package:flutter_application_1/core/i18n/translations.g.dart';

abstract class LocaleStoragePort {
  Future<void> saveLocale(AppLocale locale);
  Future<AppLocale?> loadLocale();
}
```

---

### 3) ADAPTER — hive_locale_storage_adapter.dart

Create `lib/core/i18n/hive_locale_storage_adapter.dart`:

```dart
@LazySingleton(as: LocaleStoragePort)
class HiveLocaleStorageAdapter implements LocaleStoragePort {
  static const _boxName = 'locale';
  static const _key = 'locale';

  @override
  Future<void> saveLocale(AppLocale locale) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_key, locale.languageTag);
  }

  @override
  Future<AppLocale?> loadLocale() async {
    final box = await Hive.openBox<String>(_boxName);
    final code = box.get(_key);
    if (code == null) return null;
    return _parseLocale(code);
  }

  AppLocale? _parseLocale(String code) {
    for (final l in AppLocale.values) {
      if (l.languageTag == code) return l;
    }
    return null;
  }
}
```

---

### 4) APPLICATION — locale_cubit.dart

Modify `lib/core/i18n/locale_cubit.dart`:

**IMPORTANT:** add `@lazySingleton` + `LocaleStoragePort` dependency.
The `setLocale` method now saves the locale to storage.

```dart
@lazySingleton
class LocaleCubit extends Cubit<AppLocale> {
  LocaleCubit(this._storage) : super(LocaleSettings.currentLocale);

  final LocaleStoragePort _storage;

  Future<void> init() async {
    final saved = await _storage.loadLocale();
    if (saved != null) await setLocale(saved);
  }

  Future<void> setLocale(AppLocale locale) async {
    final applied = await LocaleSettings.setLocale(locale);
    await _storage.saveLocale(applied);
    emit(applied);
  }

  Future<void> useDeviceLocale() async {
    final locale = await LocaleSettings.useDeviceLocale();
    emit(locale);
  }
}
```

---

### 5) PRESENTATION — locale_selector_button.dart

Create the `lib/core/widgets/` folder and file `lib/core/widgets/locale_selector_button.dart`.

The widget reads the current locale from `LocaleCubit`. On tap, opens a bottom sheet.

```dart
class LocaleSelectorButton extends StatelessWidget {
  const LocaleSelectorButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, AppLocale>(
      builder: (context, locale) => TextButton(
        onPressed: () => _showLocaleSheet(context, locale),
        child: Text(locale.languageTag.toUpperCase()),
      ),
    );
  }

  void _showLocaleSheet(BuildContext context, AppLocale current) {
    final cubit = context.read<LocaleCubit>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _LocaleBottomSheet(
        current: current,
        onSelect: (locale) {
          unawaited(cubit.setLocale(locale));
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}
```

`_LocaleBottomSheet` — private StatelessWidget:

```dart
class _LocaleBottomSheet extends StatelessWidget {
  const _LocaleBottomSheet({required this.current, required this.onSelect});

  final AppLocale current;
  final ValueChanged<AppLocale> onSelect;

  static const _nativeNames = {
    AppLocale.en: 'English',
    AppLocale.ru: 'Русский',
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: AppLocale.values
            .map(
              (locale) => ListTile(
                title: Text(_nativeNames[locale] ?? locale.languageTag),
                trailing: locale == current ? const Icon(Icons.check) : null,
                onTap: () => onSelect(locale),
              ),
            )
            .toList(),
      ),
    );
  }
}
```

---

### 6) INTEGRATION — app_shell_screen.dart

Add `LocaleSelectorButton` as the **first** element in `actions` (to the left of `_AuthAppBarAction`):

```dart
actions: const [LocaleSelectorButton(), _AuthAppBarAction()],
```

---

### 7) INTEGRATION — main.dart

Three changes:

**a) Hive initialization** — BEFORE `configureDependencies()`:

```dart
WidgetsFlutterBinding.ensureInitialized();
await Hive.initFlutter();   // ← add
configureDependencies();
```

Import: `import 'package:hive_flutter/hive_flutter.dart';`

**b) Call `localeCubit.init()`** — after `authCubit.bootstrap()`:

```dart
await authCubit.bootstrap();
await getIt<LocaleCubit>().init();   // ← add
runApp(App());
```

**c) BlocProvider in App.build()** — replace `LocaleCubit` creation with `BlocProvider.value`:

```dart
// BEFORE:
BlocProvider(
  create: (_) => LocaleCubit(),
  child: TranslationProvider(...),
)

// AFTER:
BlocProvider.value(
  value: getIt<LocaleCubit>(),
  child: TranslationProvider(...),
)
```

---

### 8) CODEGEN

After all changes, run:
```
dart run build_runner build --delete-conflicting-outputs
```

This regenerates `injection.config.dart` with the new `@lazySingleton LocaleCubit` and
`@LazySingleton(as: LocaleStoragePort) HiveLocaleStorageAdapter`.

New i18n keys are **not needed** — language names are hardcoded in their native language in `_LocaleBottomSheet`.
`dart run slang` does not need to be run.

---

## Tests

Create:

```
test/core/i18n/locale_cubit_test.dart
test/core/i18n/hive_locale_storage_adapter_test.dart
test/core/widgets/locale_selector_button_test.dart
```

### a) locale_cubit_test.dart

Mock `LocaleStoragePort` via mocktail.

```
- init() when loadLocale() returns AppLocale.ru → emits [AppLocale.ru]
  and saveLocale(AppLocale.ru) is called
- init() when loadLocale() returns null → emits nothing (stays initial)
- setLocale(AppLocale.ru) → emits [AppLocale.ru], saveLocale(AppLocale.ru) is called
- setLocale(AppLocale.en) → emits [AppLocale.en], saveLocale(AppLocale.en) is called
```

### b) hive_locale_storage_adapter_test.dart

Initialize Hive with a temp directory in `setUp`, close boxes in `tearDown`.
Pattern: `Hive.init(Directory.systemTemp.path)`.

```
- saveLocale(AppLocale.en) → box.get('locale') == 'en'
- saveLocale(AppLocale.ru) → box.get('locale') == 'ru'
- loadLocale() after saveLocale(AppLocale.ru) → AppLocale.ru
- loadLocale() with empty box → null
- loadLocale() with unknown code ('de') → null
```

### c) locale_selector_button_test.dart

Mock `LocaleCubit` via mocktail.

```
- with AppLocale.en: text 'EN' is displayed
- with AppLocale.ru: text 'RU' is displayed
- tap on button → bottom sheet becomes visible (contains 'English' and 'Русский')
- tap 'Русский' in bottom sheet → cubit.setLocale(AppLocale.ru) is called
- active language in sheet is marked with a checkmark (Icon(Icons.check) is visible next to current locale)
- tap on language → bottom sheet closes
```

---

## Report

Upon completion, provide:
- List of new files and modified files
- Confirmation that `injection.config.dart` was regenerated (`build_runner`)
- Confirmation that no feature slices were affected
- UX walkthrough against the validation.md checklist
- Tests: number of new tests, execution result

---

## What NOT to do

- DO NOT create a usecase layer for this slice — `LocaleCubit` orchestrates the port directly,
  the logic is trivial
- DO NOT add keys to `en.json`/`ru.json` for language names — they are hardcoded in
  `_nativeNames` in their native language
- DO NOT run `dart run slang` — there are no new keys
- DO NOT add `LocaleSelectorButton` to any screens other than `app_shell_screen.dart`
- DO NOT call `Hive.initFlutter()` inside the adapter — Hive initialization happens in
  `main()` once, before `configureDependencies()`
- DO NOT use `BlocProvider(create: (_) => LocaleCubit(...))` in `main.dart` — only
  `BlocProvider.value(value: getIt<LocaleCubit>())`
- DO NOT leave `useDeviceLocale()` unchanged if it should also save the locale —
  the PRD does not describe this method, do not change its behaviour
- DO NOT add a title to the bottom sheet — the PRD explicitly states no header is needed
- DO NOT touch `app_router.dart` — navigation does not change
