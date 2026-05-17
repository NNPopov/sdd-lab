# Plan 0018 — user_details: navigation to user posts

Task: extend the `user_details` slice — presentation layer only.
Add a "Posts" button below the user information in `UserDetailsView`,
separated by a `Divider`. Navigation to `UserPostsRoute` — fire-and-forget, without
reloading `UserDetailsCubit` on return.

---

====== CONTEXT ======

READ:
- `@CLAUDE.md` fully
- `@lib/features/users/user_details/presentation/widgets/user_details_view.dart` — being modified
- `@lib/features/users/user_details/presentation/user_details_screen.dart` — being modified
- `@lib/core/routing/app_router.dart` — confirm that `UserPostsRoute` is already registered
- `@lib/core/i18n/i18n/en.json` — verify that `users.list.userPosts` = "Posts" already exists
- `@lib/core/i18n/i18n/ru.json` — verify that `users.list.userPosts` = "Статьи" already exists
- `@.claude/skills/bloc/SKILL.md`

DO NOT READ:
- `@lib/features/users/user_details/domain/**`
- `@lib/features/users/user_details/data/**`
- `@lib/features/users/user_details/application/**`
- `@lib/features/users/list_users/**`
- `@lib/features/users/edit_user/**`
- `@lib/features/users/create_user/**`
- `@lib/features/posts/**`

---

====== API ======

This is a purely frontend change. Backend is not affected.
The route is already registered in `AppRouter`:
- `UserPostsRoute(username: String)` → `/user/:username/posts`

No new i18n keys are added. Reuse:
- `context.t.users.list.userPosts` → "Posts" (EN) / "Статьи" (RU)

`dart run slang` does not need to be run.

---

====== Target structure ======

No new files are created. Existing files are modified:

```
lib/features/users/user_details/presentation/
├── user_details_screen.dart         ← MODIFY: pass onPostsTap to UserDetailsView
└── widgets/
    └── user_details_view.dart       ← MODIFY: add onPostsTap + Divider + TextButton.icon
```

---

====== WHAT TO DO ======

### 1) PRESENTATION — UserDetailsView

File: `lib/features/users/user_details/presentation/widgets/user_details_view.dart`

Add required parameter:
```dart
final VoidCallback onPostsTap;
```

In constructor:
```dart
const UserDetailsView({
  required this.user,
  required this.tierLoading,
  required this.onPostsTap,   // ← new
  this.tierName,
  this.tierCreatedAt,
  super.key,
});
```

In `build()`, after the last `_InfoRow`/tier block, add to `Column.children`:
```dart
const Divider(height: 32),
Align(
  alignment: Alignment.centerLeft,
  child: TextButton.icon(
    icon: const Icon(Icons.article_outlined),
    label: Text(context.t.users.list.userPosts),
    onPressed: onPostsTap,
  ),
),
```

IMPORTANT: `UserDetailsView` does not know about navigation — it only calls the callback.
Do not add an import of `auto_route` or `app_router` to this file.

### 2) PRESENTATION — UserDetailsScreen

File: `lib/features/users/user_details/presentation/user_details_screen.dart`

In `BlocBuilder<UserDetailsCubit, UserDetailsState>` update the place where
`UserDetailsView` is built — pass `onPostsTap`:

```dart
UserDetailsLoaded(:final user) =>
  BlocBuilder<GetUserTierCubit, GetUserTierState>(
    builder: (context, tierState) => UserDetailsView(
      user: user,
      tierName: tierState is GetUserTierLoaded ? tierState.tier.tierName : null,
      tierCreatedAt: tierState is GetUserTierLoaded ? tierState.tier.tierCreatedAt : null,
      tierLoading: tierState is GetUserTierLoading,
      onPostsTap: () => context.router.push(             // ← new
        UserPostsRoute(username: widget.username),
      ),
    ),
  ),
```

IMPORTANT: Navigation — fire-and-forget (`context.router.push` without `await`).
After returning from `UserPostsRoute`, `UserDetailsCubit.load()` is NOT called.
Viewing posts does not change profile data.

---

====== TESTS ======

### test/features/users/user_details/presentation/widgets/user_details_view_test.dart

Create the file. Test `UserDetailsView` in isolation (mock data, no router):

a) "Posts" button is present: `Icons.article_outlined` + label "Posts"
b) Tap the "Posts" button → `onPostsTap` called exactly 1 time
c) `Divider` is present between the info rows and the "Posts" button

Use a call counter or `bool` flag instead of a mock for `onPostsTap`.

### test/features/users/user_details/presentation/user_details_screen_test.dart

Create or extend the existing file. Test `UserDetailsScreen`
with a mocked `UserDetailsCubit`:

a) Tap "Posts" → router receives `UserPostsRoute(username: username)` (use `MockRouter`)
b) After returning from `UserPostsRoute` → `UserDetailsCubit.load()` is NOT called again

Pattern: `MockUserDetailsCubit extends MockCubit<UserDetailsState>` (mocktail).
See the analog in `test/features/users/list_users/presentation/` (slice 0017).

---

====== REPORT ======

On completion provide:
- List of modified files (no new files)
- Confirmation that domain/, data/, application/ of the user_details slice are not touched
- Confirmation that other slices are not affected
- Confirmation that `core/` is not modified (i18n JSON not touched)
- Result of `dart analyze` (no new warnings)
- Tests: count of new tests, all green

---

====== WHAT NOT TO DO ======

- Do NOT create a new slice — this is an extension of the existing `user_details`
- Do NOT touch domain/, data/, application/ of the user_details slice
- Do NOT add navigation logic inside `UserDetailsView` — only the callback
- Do NOT add `await` before `context.router.push(UserPostsRoute(...))` — fire-and-forget
- Do NOT call `cubit.load()` after returning from posts — no refresh needed
- Do NOT add new i18n keys — reuse `users.list.userPosts`
- Do NOT run `dart run slang` — JSON is not changed
- Do NOT add permission or isMe checks — the button is visible to all roles
- Do NOT touch `UserPostsRoute`, `AppRouter`, `_shared/`, `core/`
- Do NOT touch other slices: list_users, create_user, edit_user, posts
