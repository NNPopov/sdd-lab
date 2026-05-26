# Feature Spec — 0050 user_details_edit_user_route_to_user_id

> Implementation prompt for the combined `user_details` + `edit_user` route migration
> from `{username}` to `{user_id}`. Sources: `prd.md`, `CONTEXT.md`, ADR-0001, and the
> current slice code. Read this top-to-bottom before touching code.

---

## 1. HEADER

Migrate the **user-details** and **edit-user** verticals from a `username`-keyed API and
deep-link surface to an **integer `user_id`** one — in **one slice, one commit, one
acceptance gate** (ADR-0001). The two flows share `UsersApiClient.getUser(...)`, so the
shared method's signature cannot be half-migrated.

All user-visible behavior is unchanged: the detail screen shows the same data, the
owner-only edit guard still holds, the edit form still PATCHes the same body, and the same
failure surfaces are mapped. Only the **identity that selects which user** to read/patch
moves from the handle string to the id.

**Governing rule (CONTEXT.md):** migrate `username` → `int userId` **only** where it
identifies the *target* of a request (URL path segment, port/adapter lookup parameter,
`AuthCubit.isMe`, ownership comparisons). **Never** touch `username` where it is a stored
or displayed **handle** (`User.username`, `CurrentUser.username`, the PATCH-body
`UserUpdate.username`, `@username` labels). Classify every occurrence as *identity* or
*handle* before editing. A blind find-and-replace is forbidden.

---

## 2. CONTEXT

### READ
- `@CLAUDE.md` — fully (hard rules, layering, verification).
- `@CONTEXT.md` — the identity-vs-handle glossary; this is the decision rule for every edit.
- `@docs/adr/0001-merge-user-details-and-edit-user-route-migration.md` — why the two slices
  share one gate.
- `@specs/features/users/0050_user_details_edit_user_route_to_user_id/prd.md`.
- The two slices being migrated (read in full):
  - `@lib/features/users/user_details/**`
  - `@lib/features/users/edit_user/**`
- Shared + core touch-points:
  - `@lib/features/users/_shared/data/users_api_client.dart` — `getUser`/`updateUser`.
  - `@lib/features/users/_shared/domain/entities/user.dart` — has `int id` already.
  - `@lib/core/auth/application/auth_cubit.dart` — `isMe(String)` → `isMe(int)`.
  - `@lib/core/auth/domain/entities/current_user.dart` — has `int id` already (slice 0048).
  - `@lib/core/routing/app_router.dart` — the two path strings to change.
  - `@lib/core/routing/app_shell_screen.dart` — user-menu "my profile" navigation.
  - `@lib/features/users/list_users/presentation/users_screen.dart` — list → details nav.
- Analogs (lean on, do NOT copy):
  - `@test/features/tiers/0047_delete_tier_id_contract/**` — pattern for the combined
    contract outside-in test (real adapters + use-cases + cubits, mocked API client,
    `verify` the id reaches the client).
  - `@test/features/users/0038_owner_only_user_edit/**` — the existing owner-only
    outside-in test that becomes the `isMe(id)` contract.

### DO NOT READ
- Any Posts slice (`lib/features/posts/**`) — out of scope; their `:username` paths stay.
- Sibling user-action slices: `moderator_contract/`, `update_user_tier/`,
  `get_user_tier/`, `erase_db_user/`, `delete_user/` — they keep the handle for now.
- `create_user/`, `list_users/` internals beyond the one navigation call site.
- Generated files except to regenerate them (`*.gr.dart`, `*.g.dart`, `*.freezed.dart`).

---

## 3. API

Two methods on the shared `UsersApiClient`. Both move the **path identity** to an integer;
nothing else about the contract changes.

```
GET   /user/{user_id}           → UserDto          (was /user/{username})
PATCH /user/{user_id}           → 200, no body     (was /user/{username})
        Body: UpdateUserRequestDto { name?, username?, email?, profileImageUrl? }
        ↑ body is UNCHANGED — `username` here is the new HANDLE the user typed.
```

Header: `Authorization: Bearer <token>` (via interceptor, unchanged).

**`getUser` failure mapping (preserve exactly):**
- 401 → `UnauthorizedFailure`
- 403 → `ForbiddenFailure`
- 404 → `NotFoundFailure('User not found')`
- default → `e.error` if `Failure`, else `NetworkFailure`
- catch-all `on Object` → `UnknownFailure`, `logger.error` called.

**`updateUser` failure mapping (preserve all five + catch-all):**
- 401 → `UnauthorizedFailure`
- 403 → `ForbiddenFailure`
- 404 → `NotFoundFailure('User not found')`
- 409 → `ConflictFailure`
- 422 → `FieldValidationFailure` (parsed from `detail` list)
- default → `e.error` if `Failure`, else `NetworkFailure`
- catch-all `on Object` → `UnknownFailure`, `logger.error` called.

`updateUser` returns `Future<void>`; the adapter still builds the updated `User` locally by
applying the patch to `original` (CQS style — server returns no body). That local
`_applyUpdate` and its `username` handling stay exactly as they are.

---

## 4. STRUCTURE — files touched (migration, not new tree)

No new files. The slice folders stay structurally separate (two cubits, two route pages —
ADR-0001). Edits, grouped by layer:

```
_shared (REQUIRES build_runner for the retrofit *.g.dart)
└── data/users_api_client.dart
      getUser(@Path('username') String username)  → getUser(@Path('user_id') int userId)
      updateUser(@Path('username') String username, body) → updateUser(@Path('user_id') int userId, body)
      ↑ updateUser BODY untouched.

core/auth
└── application/auth_cubit.dart
      bool isMe(String username) → bool isMe(int userId)  // currentUser?.id == userId
      (CurrentUser.id already exists — slice 0048, no change to current_user.dart)

core/routing  (REQUIRES build_runner for app_router.gr.dart)
├── app_router.dart
│     'user/:username'      → 'user/:user_id'        (UserDetailsRoute)
│     'user/:username/edit' → 'user/:user_id/edit'   (EditUserRoute)
│     ↑ sibling 'user/:username/posts...' paths NOT touched.
└── app_shell_screen.dart
      _onMenuAction: myProfile → UserDetailsRoute(userId: currentUser.id)
                     myPosts  → UserPostsRoute(username: currentUser.username)  // handle, unchanged

user_details vertical
├── presentation/user_details_route.dart
│     @PathParam('username') String username → @PathParam('user_id') int userId
├── presentation/user_details_screen.dart
│     widget field username:String → userId:int; load(userId); appBar title from loaded User
│     EditUserRoute(username:) → EditUserRoute(userId: <loaded user.id>); reload by id
│     UserPostsRoute(username:) ← from loaded User.username (handle bridge)
│     _UserDetailsAppBarActions(username:) → (userId:)
├── presentation/user_action_visibility.dart
│     from(..., String username) → from(..., int userId); isMe = currentUser?.id == userId
├── application/user_details_cubit.dart
│     load(String) / retry(String) → load(int) / retry(int)
├── domain/usecases/get_user_usecase.dart   call(String) → call(int)
├── domain/ports/get_user_port.dart          call(String) → call(int)
└── data/get_user_adapter.dart               call(int userId) → _api.getUser(userId)

edit_user vertical
├── presentation/edit_user_route.dart
│     @PathParam('username') String username → @PathParam('user_id') int userId
├── presentation/edit_user_screen.dart
│     widget field username:String → userId:int; loadInitial(userId)
├── application/edit_user_cubit.dart
│     loadInitial(String) → loadInitial(int); isMe(username) → isMe(userId)
│     getUser path arg → userId    (submit/UserUpdate body UNCHANGED — handle stays)
├── domain/usecases/get_user_for_edit_usecase.dart  call(String) → call(int)
├── domain/ports/get_user_for_edit_port.dart        call(String) → call(int)
├── data/get_user_for_edit_adapter.dart             call(int userId) → _api.getUser(userId)
└── data/update_user_adapter.dart
      _api.updateUser(original.username, ...) → _api.updateUser(original.id, ...)
      ↑ PATCH PATH identity → original.id. Body username + _applyUpdate username UNCHANGED.

list_users vertical
└── presentation/users_screen.dart
      onDetailsTap: UserDetailsRoute(username: u.username) → UserDetailsRoute(userId: u.id)
      (onPostsTap UserPostsRoute(username:) NOT touched — handle, posts not migrated)
```

---

## 5. WHAT TO DO — step by step

Work bottom-up per vertical so each layer compiles against the one below before the screen
is touched. Run `build_runner` once after the `_shared` + routing path edits.

**1) `_shared` API client.** Change `getUser` and `updateUser` path params to
`@Path('user_id') int userId`. Leave `updateUser`'s `@Body()` exactly as is. This breaks
both `get_user_adapter` and `get_user_for_edit_adapter` (intended — that is the coupling).

**2) `core/auth`.** `AuthCubit.isMe(String username)` → `isMe(int userId)` returning
`currentUser?.id == userId`. Sole production caller is `EditUserCubit.loadInitial`.
`CurrentUser.id` already exists; no DTO/entity change.

**3) user_details domain → data → application.**
- `GetUserPort.call(int userId)`, `GetUserUseCase.call(int userId) => _port(userId)`.
- `GetUserAdapter.call(int userId)` → `_api.getUser(userId)`; failure mapping unchanged;
  catch-all `logger.error` unchanged.
- `UserDetailsCubit.load(int userId)` / `retry(int userId)`. `updateIsModerator` unchanged.

**4) edit_user domain → data → application.**
- `GetUserForEditPort.call(int userId)`, `GetUserForEditUseCase.call(int userId)`.
- `GetUserForEditAdapter.call(int userId)` → `_api.getUser(userId)`; mapping unchanged.
- `update_user_adapter`: change **only** the PATCH path identity
  `original.username` → `original.id`. The body (`update.username`, the new handle) and
  `_applyUpdate` stay byte-for-byte. `UpdateUserUseCase` and `UpdateUserPort` signatures
  (`{required User original, required UserUpdate update}`) are unchanged — `original`
  already carries `id`.
- `EditUserCubit.loadInitial(int userId)`: emit `loadingInitialData`; guard
  `if (!_authCubit.isMe(userId))` → `loadError(Failure.forbidden(...))`; else
  `_getUser(userId)`. `submit` unchanged.

**5) Routing paths + page params.**
- `app_router.dart`: change exactly the two `UserDetails`/`EditUser` path strings. Leave the
  four sibling `user/:username/posts...` declarations and the EditUser `authGuard` alone.
- `UserDetailsPage` / `EditUserPage`: `@PathParam('user_id') required this.userId`,
  field `final int userId;`, pass `userId:` to the screen.

**6) Screens.**
- `UserDetailsScreen`: field `final int userId`; `initState` → `load(widget.userId)`;
  `retry(widget.userId)`. The AppBar title was `Text(widget.username)` — now source the
  handle from the loaded `User` (e.g. show the title once `UserDetailsLoaded`, falling back
  to empty/placeholder while loading), since the screen no longer receives a handle.
  - Edit button: `EditUserRoute(userId: <loaded user.id>)`; after pop, `cubit.load(<id>)`
    (re-load by id, not by `updated?.username`).
  - `onPostsTap`: `UserPostsRoute(username: <loaded user.username>)` — **handle bridge**,
    sourced from the loaded `User` (posts routes are not migrated).
  - `_UserDetailsAppBarActions(userId:)`; pass `userId` into `UserActionVisibility.from`.
    The sibling buttons (`AssignModeratorButton(username:)`, `UpdateUserTierButton(username:)`,
    `EraseDbUserButton(username:)`) still take the **handle** — source it from the loaded
    `User.username` (already available in that widget via the `UserDetailsCubit` selector).
    `DeleteAccountButton(userId:)` already takes an id.
- `EditUserScreen`: field `final int userId`; `initState`/retry →
  `loadInitial(widget.userId)`. Listener/builder bodies unchanged.

**7) `UserActionVisibility.from`.** Replace the `String username` param with `int userId`;
compute `isMe = (auth is AuthAuthenticated ? auth.currentUser?.id : null) == userId`.
`showEdit`/`showDelete` still follow `isMe`. The permission-derived flags
(`showErase`, `canEditTier`, `canManageModerators`) are untouched.

**8) Navigation call sites.**
- `users_screen.dart` `onDetailsTap` → `UserDetailsRoute(userId: u.id)`.
- `app_shell_screen.dart` `_onMenuAction`: `myProfile` → `UserDetailsRoute(userId: ...)`.
  The handler currently receives only `String username`; pass the `currentUser` (or both id
  and handle) through so `myProfile` uses `currentUser.id` while `myPosts` keeps
  `currentUser.username`.

**9) build_runner + verify.** Run
`dart run build_runner build --delete-conflicting-outputs` (regenerates the retrofit client
and `app_router.gr.dart`). Then `dart format .`, `dart analyze`, and the test suite.

No new localization keys. No `pubspec.yaml` changes.

---

## 6. TESTS

Acceptance gates first, then the per-layer re-green (these are specified in detail in
`tests.md`; this block states the contract the implementation must satisfy):

- **Owner-only outside-in test** (`test/features/users/0038_owner_only_user_edit/...`):
  update it to express ownership **by id** — this is the `isMe(int)` contract and is the
  test updated *first* (it should go red against the pre-change code, green after).
- **Combined contract outside-in test** (new, mirroring
  `test/features/tiers/0047_delete_tier_id_contract/`): wire real adapters + use-cases +
  cubits, mock `UsersApiClient`, and `verify(() => api.getUser(<int>))` and
  `verify(() => api.updateUser(<int>, any()))`. No live backend.

Per-layer (default four-layer coverage; re-green the existing tests, migrating
username→id):
- **Adapters:** `getUser(<int>)` / `updateUser(<int>, body)` success; full failure mapping
  preserved (getUser 401/403/404/default; updateUser 401/403/404/409/422/default); catch-all
  `logger.error` verified.
- **Use-cases:** read-for-edit and get-user delegate with the integer id; update still
  passes the unchanged body and still short-circuits on empty `UserUpdate`.
- **Action visibility:** `UserActionVisibility.from(...)` → `isMe`/`showEdit`/`showDelete`
  true iff `currentUser.id == userId`.
- **Cubits (`bloc_test`):** `UserDetailsCubit` load-by-id transitions; `EditUserCubit`
  `loadInitial` incl. the `isMe(id)` forbidden branch, and `submit` transitions.
- **Widgets:** detail screen renders by id; edit screen guards non-owners, submits.
- **`isMe` (unit):** `AuthCubit.isMe(id)` true for the current user's id, false otherwise.
- **Routing/navigation re-green:** `app_shell_screen_test`, `tab_navigation_test`,
  `tab_root_reset_test`, `users_screen_test` — updated to construct the id-based routes.

---

## 7. REPORT (what the implementing agent returns)

- List of files changed (none created), grouped by vertical / core / shared.
- Confirmation that **no out-of-scope slice** was touched (posts, moderator, tier, erase,
  delete, create, login) and that no handle occurrence was migrated to id.
- Confirmation `build_runner` was run and `app_router.gr.dart` + `users_api_client.g.dart`
  regenerated.
- The two acceptance-gate outside-in tests: red-before / green-after evidence.
- `dart format` clean, `dart analyze` clean, full `flutter test` green (and an explicit
  count of downstream tests re-greened).

---

## 8. WHAT NOT TO DO

- ❌ Do **not** migrate any **handle**: `User.username`, `CurrentUser.username`, the
  PATCH-body `UpdateUserRequestDto.username` / `UserUpdate.username`, `_applyUpdate`'s
  username, `@username` labels, login, or the create-user form.
- ❌ Do **not** touch the sibling `user/:username/posts...` route paths or the Posts slices.
- ❌ Do **not** change `updateUser`'s request body or its failure mapping (all five codes
  stay).
- ❌ Do **not** merge `UserDetailsCubit`/`EditUserCubit`, their ports, adapters, screens, or
  routes — they stay separate (ADR-0001). Only spec, commit, and gate are shared.
- ❌ Do **not** migrate the sibling action buttons (AssignModerator, UpdateUserTier,
  EraseDbUser) or `getUserTier` to id — they keep the handle this slice.
- ❌ Do **not** add a dependency, a new route, a new localization key, or an
  `AuthSession`/`CurrentUser` change.
- ❌ Do **not** add a catch-all-less adapter path; keep every `on Object catch (e, st)` with
  `logger.error`.
