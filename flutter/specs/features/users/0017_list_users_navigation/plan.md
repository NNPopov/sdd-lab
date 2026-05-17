# Plan 0017 — list_users: explicit navigation to user details and user posts

Task: extend the `list_users` slice (presentation layer only).
Replace the single `onTap` on the tile with two explicit text buttons:
"Details" (→ `UserDetailsRoute`) and "Posts" (→ `UserPostsRoute`).
After returning from Details — refresh the list. After Posts — no refresh.

---

====== CONTEXT ======

READ:
- `@CLAUDE.md` fully
- `@lib/features/users/list_users/presentation/users_screen.dart` — being modified
- `@lib/features/users/list_users/presentation/widgets/user_tile.dart` — being modified
- `@lib/features/users/list_users/application/users_list_cubit.dart` — only the `refresh()` signature
- `@lib/features/users/_shared/domain/entities/user.dart` — the User type
- `@lib/core/routing/app_router.dart` — confirm that UserDetailsRoute and UserPostsRoute are already registered
- `@lib/core/i18n/i18n/en.json` — adding keys
- `@lib/core/i18n/i18n/ru.json` — adding keys
- `@.claude/skills/bloc/SKILL.md`

DO NOT READ:
- `@lib/features/users/list_users/domain/**`
- `@lib/features/users/list_users/data/**`
- `@lib/features/users/list_users/application/users_list_state.dart`
- `@lib/features/users/user_details/**`
- `@lib/features/users/create_user/**`
- `@lib/features/users/edit_user/**`
- `@lib/features/posts/**`

---

====== API ======

This is a purely frontend change. Backend is not affected.
Both routes are already registered in `AppRouter`:
- `UserDetailsRoute(username: String)` → `/user/:username`
- `UserPostsRoute(username: String)` → `/user/:username/posts`

---

====== Target structure ======

No new files are created. Existing files are modified:

```
lib/features/users/list_users/presentation/
├── users_screen.dart                  ← MODIFY: new callbacks for UserTile
└── widgets/
    └── user_tile.dart                 ← MODIFY: onTap → onDetailsTap + onPostsTap

lib/core/i18n/i18n/
├── en.json                            ← MODIFY: add users.list.userDetails, users.list.userPosts
└── ru.json                            ← MODIFY: add the same keys in Russian
```

After editing the JSON, run codegen: `dart run slang`

---

====== WHAT TO DO ======

### 1) LOCALIZATION — add keys

In `lib/core/i18n/i18n/en.json` add to the `users.list` section:
```json
"userDetails": "Details",
"userPosts": "Posts"
```

In `lib/core/i18n/i18n/ru.json` add to the `users.list` section:
```json
"userDetails": "Детали",
"userPosts": "Статьи"
```

Then — run `dart run slang` to regenerate `translations.g.dart`.

### 2) PRESENTATION — UserTile

File: `lib/features/users/list_users/presentation/widgets/user_tile.dart`

Change the signature:
- Remove `final VoidCallback? onTap`
- Add `final VoidCallback onDetailsTap` (required)
- Add `final VoidCallback onPostsTap` (required)

In `build()`:
- `ListTile.onTap` → `null`
- `trailing` → `Row` with two `TextButton.icon`s:
  - `TextButton.icon(icon: Icon(Icons.person_outline), label: Text(context.t.users.list.userDetails), onPressed: onDetailsTap)`
  - `TextButton.icon(icon: Icon(Icons.article_outlined), label: Text(context.t.users.list.userPosts), onPressed: onPostsTap)`

IMPORTANT: Remove the fallback logic `onTap ?? () => context.router.push(UserDetailsRoute(...))` entirely.
Both callbacks are now required parameters.

IMPORTANT: Remove the import of `auto_route` and `app_router` from `user_tile.dart` — the tile no longer knows about navigation.

### 3) PRESENTATION — UsersScreen

File: `lib/features/users/list_users/presentation/users_screen.dart`

Update the `UserTile` call:
```dart
UserTile(
  user: u,
  onDetailsTap: () async {
    await context.router.push(UserDetailsRoute(username: u.username));
    if (context.mounted) {
      unawaited(context.read<UsersListCubit>().refresh());
    }
  },
  onPostsTap: () {
    context.router.push(UserPostsRoute(username: u.username));
    // NO refresh — Posts do not modify Users data
  },
);
```

---

====== TESTS ======

### test/features/users/list_users/presentation/widgets/user_tile_test.dart

Create a new file. Test `UserTile` in isolation:

a) Tap "Details" → calls `onDetailsTap`, does NOT call `onPostsTap`
b) Tap "Posts" → calls `onPostsTap`, does NOT call `onDetailsTap`
c) Tap on the tile body (outside buttons) → neither callback is called
d) Both button widgets are present with the correct labels and icons

Pattern: use `mocktail` (or simple `bool` flags / `int` counters) to track calls.
Inject localization keys via `AppLocalizationScope` or `TranslationProvider` — see how it is done in existing widget tests.

### test/features/users/list_users/presentation/users_screen_test.dart

Create or extend the existing file. Test `UsersScreen` with a mocked `UsersListCubit`:

a) After tapping "Details" on a tile and returning from the route → `UsersListCubit.refresh()` called
b) After tapping "Posts" on a tile and returning from the route → `UsersListCubit.refresh()` NOT called

Use `MockUsersListCubit extends MockCubit<UsersListState>` (mocktail).

---

====== REPORT ======

On completion provide:
- List of modified files (no new files)
- Confirmation that domain/, data/, application/ of the list_users slice are not touched
- Confirmation that other slices (user_details, create_user, edit_user, posts) are not touched
- Confirmation that core/ is not affected (except i18n JSON)
- Result of `dart run slang` (no errors)
- Result of `dart analyze` (no new warnings)
- Tests: count of new tests, all green

---

====== WHAT NOT TO DO ======

- Do NOT create a new slice — this is an extension of the existing `list_users`
- Do NOT touch domain/, data/, application/ of the list_users slice
- Do NOT add navigation logic inside `UserTile` — only callbacks
- Do NOT leave `onTap` as a fallback or nullable parameter
- Do NOT call `refresh()` after `onPostsTap` — Posts do not change Users data
- Do NOT touch `UserDetailsRoute`, `UserPostsRoute`, `AppRouter` — already registered
- Do NOT add anything to `_shared/` — changes affect only one slice
- Do NOT touch other slices: create_user, user_details, edit_user, posts
