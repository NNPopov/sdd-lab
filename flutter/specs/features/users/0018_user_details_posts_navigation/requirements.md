# Requirements 0018 — user_details: navigation to user posts

## Scope

Extension of the `user_details` slice — presentation layer only.
No new slice, domain, data, or application layer is created.

---

## Functional Requirements

### FR-01 — "Posts" button in UserDetailsView

`UserDetailsView` displays a "Posts" button below all info rows:

| Element | Value |
|---|---|
| Icon | `Icons.article_outlined` |
| EN label | "Posts" (`context.t.users.list.userPosts`) |
| RU label | "Статьи" (`context.t.users.list.userPosts`) |
| Type | `TextButton.icon`, left-aligned |

### FR-02 — Visual divider

Between the last info row (email / tier / tierSince) and the "Posts" button
a `Divider` (`height: 32`) is displayed.

### FR-03 — onPostsTap callback is required

`UserDetailsView` accepts `onPostsTap: VoidCallback` as a required parameter.
The widget does not know about routes and does not import `auto_route` / `app_router`.

### FR-04 — Navigation from UserDetailsScreen

`UserDetailsScreen` passes `onPostsTap`:
```dart
onPostsTap: () => context.router.push(UserPostsRoute(username: widget.username)),
```
The call is fire-and-forget (without `await`). After returning from `UserPostsRoute`
`UserDetailsCubit.load()` **is not called**.

### FR-05 — Visibility without restrictions

The "Posts" button is always visible: no `PermissionCubit` check, no `isMe`.
All roles (guest, user, manager, admin) see the button.

### FR-06 — Localization without JSON changes

The key `users.list.userPosts` already exists in `en.json` ("Posts") and `ru.json`
("Статьи"). No new keys are added, `dart run slang` is not run.

---

## Non-Functional Requirements

### NFR-01 — Scope limited to presentation layer

The domain/, data/, application/ layers of the `user_details` slice are not modified.

### NFR-02 — Slice isolation

Other slices (list_users, create_user, edit_user, delete_user, posts)
are not affected. `_shared/` is not modified.

### NFR-03 — core/ not affected

`core/` (including i18n JSON) is not modified.

### NFR-04 — Compatibility with auto_route

`UserPostsRoute(username: String)` is already registered in `AppRouter`.
No router changes are required.

### NFR-05 — Tests

New widget tests for `UserDetailsView` and `UserDetailsScreen`.
All existing tests remain green.

---

## Constraints

- Packages: only those already in `pubspec.yaml`. No new dependencies are added.
- Codegen: not needed (JSON is not changed).
- Lint: `dart analyze` without new warnings.
- Test framework: `flutter_test` + `bloc_test` + `mocktail`.
