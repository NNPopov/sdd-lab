# Plan: User Header Menu (0041)

## Overview

This slice is a **pure widget modification** — no new Cubit, adapter, port,
use-case, or route is added. The only production file changed is
`lib/core/routing/app_shell_screen.dart`. Two localization keys are added to
all four locale files. Tests extend `test/core/routing/app_shell_screen_test.dart`.

## Files Changed

| File | Change |
|---|---|
| `lib/core/routing/app_shell_screen.dart` | Replace username text + logout `IconButton` with a `PopupMenuButton` anchored to the username |
| `lib/core/i18n/i18n/en-US.json` | Add `userMenu.myProfile`, `userMenu.myPosts` |
| `lib/core/i18n/i18n/ru-RU.json` | Same |
| `lib/core/i18n/i18n/es-ES.json` | Same |
| `lib/core/i18n/i18n/uk-UA.json` | Same |
| `test/core/routing/app_shell_screen_test.dart` | Add group `'_AuthAppBarAction — user menu'` |

No new Dart files are created. No routes, Cubits, adapters, or ports are added.

## Step-by-Step Implementation

### 1 — Localization keys

Add a new top-level `"userMenu"` key in all four locale files:

**en-US.json**
```json
"userMenu": {
  "myProfile": "My Profile",
  "myPosts": "My Posts"
}
```

**ru-RU.json**
```json
"userMenu": {
  "myProfile": "Мой профиль",
  "myPosts": "Мои публикации"
}
```

**es-ES.json**
```json
"userMenu": {
  "myProfile": "Mi perfil",
  "myPosts": "Mis publicaciones"
}
```

**uk-UA.json**
```json
"userMenu": {
  "myProfile": "Мій профіль",
  "myPosts": "Мої публікації"
}
```

After editing all four files, regenerate slang and code:
```
dart run build_runner build --delete-conflicting-outputs
```

### 2 — `app_shell_screen.dart` — private enum

Add a file-level private enum above `_AuthAppBarAction`:

```dart
enum _UserMenuAction { myProfile, myPosts, signOut }
```

### 3 — `_AuthAppBarAction` — rewrite `AuthAuthenticated` branch

Inside `_AuthAppBarAction.build`, replace the `AuthAuthenticated` case:

**Before:**
```dart
AuthAuthenticated(:final currentUser) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(currentUser?.username ?? ''),
    IconButton(
      icon: const Icon(Icons.logout),
      tooltip: context.t.auth.logout.confirm,
      onPressed: () => _confirmLogout(context),
    ),
  ],
),
```

**After:**
```dart
AuthAuthenticated(:final currentUser) when currentUser != null =>
  PopupMenuButton<_UserMenuAction>(
    onSelected: (action) => _onMenuAction(context, action, currentUser.username),
    itemBuilder: (_) => [
      PopupMenuItem(
        value: _UserMenuAction.myProfile,
        child: Text(context.t.userMenu.myProfile),
      ),
      PopupMenuItem(
        value: _UserMenuAction.myPosts,
        child: Text(context.t.userMenu.myPosts),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: _UserMenuAction.signOut,
        child: Text(context.t.auth.logout.confirm),
      ),
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(currentUser.username),
    ),
  ),
AuthAuthenticated() => const SizedBox.shrink(),
```

The `when currentUser != null` guard uses Dart 3 pattern matching. The
fall-through `AuthAuthenticated()` case handles the `currentUser == null`
scenario by rendering nothing — matching the PRD's null-safety requirement.

### 4 — `_AuthAppBarAction` — `_onMenuAction` helper

Add a new private method alongside the existing `_confirmLogout`:

```dart
void _onMenuAction(
  BuildContext context,
  _UserMenuAction action,
  String username,
) {
  switch (action) {
    case _UserMenuAction.myProfile:
      unawaited(context.router.push(UserDetailsRoute(username: username)));
    case _UserMenuAction.myPosts:
      unawaited(context.router.push(UserPostsRoute(username: username)));
    case _UserMenuAction.signOut:
      _confirmLogout(context);
  }
}
```

`context.router` inside the `AppShellScreen` builder resolves to the
`AutoTabsRouter`'s controller. Auto_route will resolve `UserDetailsRoute` and
`UserPostsRoute` to their registered location under `UsersTabRoute`. The user
arrives at the destination regardless of the currently active tab.

The existing `_confirmLogout` method is **unchanged**.

### 5 — Tests

Extend `test/core/routing/app_shell_screen_test.dart` with a new group below
the existing ones. The existing mocks, `prepare()` helper, and `_buildApp()`
function are reused without modification.

Additional stub registrations required in `setUp` or per-test `prepare()`:
`UserDetailsCubit`, `GetUserTierCubit`, `UpdateUserTierCubit`, and
`UserPostsCubit` must be registered via `getIt.registerFactory` so the
destination pages do not crash when pushed.

**Group: `'_AuthAppBarAction — user menu'`**

| # | Test name | Assertion |
|---|---|---|
| a | `'shows username as tappable widget when authenticated'` | `find.text('alice')` present |
| b | `'opening the menu shows My Profile, My Posts, and Sign out'` | All three labels found after tap + settle |
| c | `'tapping My Profile navigates to user details screen'` | After tap, user details screen title `'alice'` appears |
| d | `'tapping My Posts navigates to user posts screen'` | After tap, user posts screen for `'alice'` appears |
| e | `'tapping Sign out opens the confirmation dialog'` | `find.byType(AlertDialog)` present |
| f | `'standalone logout IconButton is no longer present'` | `find.byIcon(Icons.logout)` → `findsNothing` |
| g | `'unauthenticated: no username or menu, shows Sign in button'` | No username text; Sign in button present |
| h | `'authenticated with null currentUser: no popup menu rendered'` | `find.byType(PopupMenuButton)` → `findsNothing` |

## Verification

```sh
dart run build_runner build --delete-conflicting-outputs
dart format .
dart analyze
flutter test test/core/routing/app_shell_screen_test.dart
```

## What NOT to Do

- Do **not** add routes to `app_router.dart`.
- Do **not** create any file under `lib/features/`.
- Do **not** add or modify any Cubit, port, adapter, or use-case.
- Do **not** add localization keys outside the new `userMenu` top-level key.
- Do **not** modify `_confirmLogout` in any way.
- Do **not** modify `AuthCubit`, `AuthState`, or `CurrentUser`.
- Do **not** touch any file beyond the six listed in the table above.
