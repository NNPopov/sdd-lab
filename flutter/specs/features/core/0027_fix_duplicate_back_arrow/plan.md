# Plan — 0027: Fix Duplicate Back Arrow in Shell AppBar

## Summary

A two-property change to `lib/core/routing/app_shell_screen.dart`:

- Remove `leading: const AutoLeadingButton()` from the shell `AppBar`.
- Add `automaticallyImplyLeading: false` to the same `AppBar`.

No new files are created. One production file is modified. One existing test file is
updated to match the new behaviour (the `AutoLeadingButton` group in
`app_shell_screen_test.dart` directly asserted the presence of the widget that is
being removed).

---

## Context

Read before implementing:

- `lib/core/routing/app_shell_screen.dart` — the only production file changed.
- `test/core/routing/app_shell_screen_test.dart` — existing tests; the
  `'AppShellScreen — AutoLeadingButton'` group must be updated.
- `lib/core/routing/app_router.dart` — confirm no other widget injects a leading
  button into the shell `AppBar`.

Do **not** read any feature slice files. Do **not** read `tab_navigation_test.dart`
or `tab_root_reset_test.dart` — they are unrelated.

---

## What already exists

```
lib/core/routing/app_shell_screen.dart     ← ONLY PRODUCTION FILE TO MODIFY
test/core/routing/app_shell_screen_test.dart  ← TEST FILE TO UPDATE
```

Current shell `AppBar` (lines 27–32 of `app_shell_screen.dart`):

```dart
appBar: AppBar(
  leading: const AutoLeadingButton(),   // ← remove this line
  title: Text(context.t.app.title),
  bottom: _AppNavBar(tabsRouter: tabsRouter),
  actions: const [LocaleSelectorButton(), _AuthAppBarAction()],
),
```

Existing test assertions that will break:

- `expect(find.byType(AutoLeadingButton), findsOneWidget)` — `AutoLeadingButton`
  will no longer be in the tree.
- `expect(find.byType(BackButton), findsWidgets)` after pushing a child route —
  previously found two back buttons (shell + child screen). After the fix, only one
  remains (the child screen's own AppBar).

---

## Step 1 — Modify `AppShellScreen`

File: `lib/core/routing/app_shell_screen.dart`

Make exactly two changes to the `AppBar` widget inside `AppShellScreen.build`:

1. **Remove** the `leading` property line entirely:
   ```dart
   leading: const AutoLeadingButton(),
   ```

2. **Add** `automaticallyImplyLeading: false` as the first property of `AppBar`:
   ```dart
   appBar: AppBar(
     automaticallyImplyLeading: false,
     title: Text(context.t.app.title),
     bottom: _AppNavBar(tabsRouter: tabsRouter),
     actions: const [LocaleSelectorButton(), _AuthAppBarAction()],
   ),
   ```

**Why `automaticallyImplyLeading: false` is required:** Without it, Flutter's
`AppBar` still checks the underlying `Navigator` and auto-inserts a back button when
there is a route to pop — which is always true while a detail screen is active.
Removing `AutoLeadingButton` alone would silently reintroduce the duplicate via the
framework's default behaviour.

**Imports:** `AutoLeadingButton` is from `package:auto_route/auto_route.dart`, which
is already imported for `AutoTabsRouter`. After removing the `leading` property,
verify whether `AutoLeadingButton` is still referenced elsewhere in the file. If not,
the import line can stay (it is still used by `AutoTabsRouter`) — do not remove it.

---

## Step 2 — Update `app_shell_screen_test.dart`

File: `test/core/routing/app_shell_screen_test.dart`

The group `'AppShellScreen — AutoLeadingButton'` contains three tests. All three need
updating to match the new behaviour.

### TC-A: "AutoLeadingButton is present in the widget tree" (line 228–239)

This test now documents the opposite fact. **Replace** the assertion:

```dart
// OLD
expect(find.byType(AutoLeadingButton), findsOneWidget);

// NEW — shell AppBar has no AutoLeadingButton after the fix
expect(find.byType(AutoLeadingButton), findsNothing);
```

Update the test name to reflect the new intent:
`'AutoLeadingButton is NOT present in the shell AppBar'`

### TC-B: "no BackButton rendered at root of Users tab (canPop is false)" (line 241–253)

No assertion change needed — the expected result (`findsNothing`) is still correct.
The shell AppBar no longer shows a back button, and the root tab screen (UsersScreen)
has no route to pop, so no back button appears anywhere. The test remains valid.

The test name can optionally be updated to:
`'no back button rendered at the root of the Users tab'`

### TC-C: "BackButton appears after pushing a route" (line 255–306)

The assertion currently expects multiple back buttons:
```dart
expect(find.byType(BackButton), findsWidgets);
```

After the fix, the shell shows no back button, but the pushed child screen's own
`AppBar` still auto-implies one. Exactly one `BackButton` will be rendered.

**Replace** the assertion and update the comment:

```dart
// Shell AppBar has no back button (automaticallyImplyLeading: false).
// The pushed child screen's own AppBar auto-implies exactly one BackButton.
expect(find.byType(BackButton), findsOneWidget);
```

Update the test name to:
`'exactly one BackButton in child screen AppBar after pushing a route'`

---

## Files changed

| Path | Status |
|---|---|
| `lib/core/routing/app_shell_screen.dart` | Modified — `leading` removed, `automaticallyImplyLeading: false` added |
| `test/core/routing/app_shell_screen_test.dart` | Modified — 3 assertions/names updated in `AutoLeadingButton` group |

No other file is touched. No cubit, use-case, adapter, domain, or routing
configuration file is modified. No `build_runner` run is needed.

---

## Verification checklist

- `dart format .` — no diff.
- `dart analyze` — no warnings.
- `flutter test test/core/routing/app_shell_screen_test.dart` — all tests pass.
- `flutter test test/core/routing/` — `tab_navigation_test.dart` and
  `tab_root_reset_test.dart` remain green (they are unaffected by this change).
- No `build_runner` run needed (no codegen-affecting files changed).
