# Requirements 0017 — list_users: explicit navigation to user details and user posts

## Scope

Extension of the `list_users` slice — presentation layer only.
No new slice, domain, data, or application layer is created.

---

## Functional Requirements

### FR-01 — Two explicit actions on the tile

Each user tile in the list must display two buttons in the `trailing` area:

| Button | Icon | Label (EN / RU) | Destination |
|---|---|---|---|
| Details | `Icons.person_outline` | "Details" / "Детали" | `UserDetailsRoute(username)` |
| Posts | `Icons.article_outlined` | "Posts" / "Статьи" | `UserPostsRoute(username)` |

### FR-02 — Tile body is not tappable

`ListTile.onTap` is set to `null`. A tap on the tile body (outside the two buttons) triggers no navigation.

### FR-03 — Details navigation with refresh

Tapping "Details" → `context.router.push(UserDetailsRoute(username))`.
After returning from the Details screen → `UsersListCubit.refresh()`.

### FR-04 — Posts navigation without refresh

Tapping "Posts" → `context.router.push(UserPostsRoute(username))`.
After returning from the Posts screen → refresh **is not called** (Posts do not change the User objects in the list).

### FR-05 — Callbacks are required

`UserTile` accepts `onDetailsTap: VoidCallback` and `onPostsTap: VoidCallback` as required parameters.
The fallback logic `onTap ?? router.push(...)` is removed entirely.

### FR-06 — Navigation logic not in UserTile

`UserTile` remains presentation-pure: it does not know about routes, does not import `app_router.dart`.
All navigation logic is in `UsersScreen`.

### FR-07 — Localization via slang

Two new keys under `users.list`:
- `userDetails`: EN "Details", RU "Детали"
- `userPosts`: EN "Posts", RU "Статьи"

Strings are not hardcoded in code.

---

## Non-Functional Requirements

### NFR-01 — Scope limited to presentation layer

The domain/, data/, application/ layers of the `list_users` slice are not modified.

### NFR-02 — Slice isolation

Other slices (user_details, create_user, edit_user, posts) are not affected.
`_shared/` is not modified.

### NFR-03 — core/ not affected (except i18n JSON)

The only change in `core/` is adding two strings to the `en.json` and `ru.json` JSON files.

### NFR-04 — Compatibility with auto_route

Both routes are already registered in `AppRouter`. No router changes are required.

### NFR-05 — Tests

New widget tests for `UserTile` and `UsersScreen`. All existing tests remain green.

---

## Constraints

- Packages: only those already in `pubspec.yaml`. No new dependencies are added.
- Codegen: `dart run slang` after changing JSON.
- Lint: `dart analyze` without new warnings.
- Test framework: `flutter_test` + `bloc_test` + `mocktail`.
