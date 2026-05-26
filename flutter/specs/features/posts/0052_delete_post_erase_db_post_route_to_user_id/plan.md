# Feature Spec — 0052 delete_post_erase_db_post_route_to_user_id

> Implementation prompt for migrating the **delete-post (DELETE)** and **erase-db-post
> (privileged DELETE)** verticals from a `{username}`-keyed API to an integer **`{user_id}`**
> one, and for removing the temporary 0051 handle-bridge from the post-detail action row.
> Sources: `prd.md`, `CONTEXT.md`, `docs/adr/0002-posts-route-migration-fine-grained-slices.md`,
> ADR-0001, slice 0051's plan, and the current slice code. Read this top-to-bottom before
> touching code.

---

## 1. HEADER

Migrate the `delete_post` (DELETE) and `erase_db_post` (privileged DELETE) verticals so the
identity that selects *whose* post is being deleted/erased moves from the author's **handle
string** to the author's integer **`user_id`** — end to end, with **no user-visible behavior
change**. This is the **second** of three posts route slices (ADR-0002): 0051 migrated
read/edit, this slice migrates delete/erase, and 0053 migrates by-author (`user_posts`/
`create_post`).

This slice also **finishes the post-detail action row**. After 0051 the row is *mixed by
design*: Edit addresses the post by `user_id`, while Delete/Erase still take the author's
**handle** sourced from the loaded `Post.username`. Because `getPost`/`PostDto` carry **no
handle**, that value is always `null`, so the 0051 bridge keeps Delete/Erase **hidden**. With
both buttons keyed by `userId` here, the `handle = post.username` read and its two
`handle != null` visibility guards are **removed**, and Delete/Erase render unconditionally on
the loaded post — exactly as before the route migration began.

**Governing rule (CONTEXT.md):** migrate `username` → `int userId` **only** where it
identifies the *target* of a request (URL path segment, port/adapter lookup parameter,
ownership comparison). **Never** touch `username` where it is a stored or displayed **handle**
(`Post.username`, `CurrentUser.username`, `@username` labels). Classify every occurrence as
*identity* or *handle* before editing. A blind find-and-replace is forbidden.

**No behavior change.** Tooltips, confirmation dialogs, the success/forbidden snackbar
messages, the `PostDeleted` event published on success, and the pop-on-success navigation are
all **unchanged**. The DELETE requests are body-less and stay body-less. This is a pure
identifier change (author handle → author id).

---

## 2. CONTEXT

### READ
- `@CLAUDE.md` — fully (hard rules, layering, verification).
- `@CONTEXT.md` — the identity-vs-handle glossary; the decision rule for every edit.
- `@docs/adr/0002-posts-route-migration-fine-grained-slices.md` — why posts is split into
  three slices; why this slice removes the mixed-key row.
- `@specs/features/posts/0052_delete_post_erase_db_post_route_to_user_id/prd.md`.
- `@specs/features/posts/0051_post_details_edit_post_route_to_user_id/plan.md` — the directly
  preceding slice; it introduced the handle-bridge this slice removes (lean on, do **NOT** copy).
- The two verticals being migrated (read in full):
  - `@lib/features/posts/delete_post/**`
  - `@lib/features/posts/erase_db_post/**`
- The screen hosting both buttons (only the action row changes):
  - `@lib/features/posts/post_details/presentation/post_details_screen.dart`
- Shared + core touch-points:
  - `@lib/features/posts/_shared/data/posts_api_client.dart` — `deletePost`/`eraseDbPost`.
  - `@lib/core/auth/application/auth_cubit.dart` — `currentUser` (`int id`, `bool isSuperuser`).
- Analogs (lean on, do **NOT** copy):
  - `@lib/features/users/delete_user/**` — the users-side delete route already migrated to
    `int userId` with ownership-by-id; the reference shape for the use-case guard (slice 0049).
  - `@test/features/posts/erase_db_post/data/erase_db_post_adapter_test.dart` — the full
    failure-mapping + double-catch + `logger.error` pattern to preserve.
  - `@test/features/tiers/0047_delete_tier_id_contract/**` — pattern for the contract
    outside-in test (real adapters + use-cases + cubits, mocked API client + `AuthCubit`,
    `verify` the integer id reaches the client).

### DO NOT READ
- Other posts slices: `post_details/` internals beyond the action row, `edit_post/`,
  `create_post/`, `user_posts/`, `moderate_post/`, `pending_posts/`, `list_posts/` — out of
  scope; their routes/methods stay (or were already migrated in 0051).
- The `_shared` DTOs (`post_dto.dart`, `post_item_dto.dart`) — `created_by_user_id` was made
  required in 0051; this slice adds nothing to them. The DELETE/erase requests carry no body.
- Any `users/`, `tiers/`, `auth/` slice internals beyond `delete_user/` (analog) and the
  `AuthCubit.currentUser` getter.
- Generated files except to regenerate them (`posts_api_client.g.dart`, `*.freezed.dart`).

---

## 3. API

Two methods on the shared `PostsApiClient`. Both move the **path identity** to an integer;
nothing else about the contract changes — both remain body-less `DELETE`s. The other seven
methods on the client (`getPosts`, `getUserPosts`, `createPost`, `getPost`, `patchPost`,
`getPendingPosts`, `moderatePost`, `revisePost`, `getModerationLog`) are **NOT** touched
(`getPost`/`patchPost` already migrated in 0051; `getUserPosts`/`createPost` → 0053).

```
DELETE /{user_id}/post/{id}      → 200, no body   (was /{username}/post/{id})
DELETE /{user_id}/db_post/{id}   → 200, no body   (was /{username}/db_post/{id})
        ↑ both are body-less; only the path identity changes.
```

Header: `Authorization: Bearer <token>` (via interceptor, unchanged).

**`deletePost` failure mapping (preserve exactly — `DeletePostAdapter`):**
- 401 → `UnauthorizedFailure(detail ?? 'Unauthorized')`
- 403 → `ForbiddenFailure(detail ?? 'Forbidden')`
- 404 → `NotFoundFailure(detail ?? 'Post not found')`
- default → if `e.error is Failure` re-surface it; else `NetworkFailure(e.message)`
- catch-all `on Object` → `UnknownFailure`, `logger.error('DeletePostAdapter.call failed', …)`.

**`eraseDbPost` failure mapping (preserve exactly — `EraseDbPostAdapter`):**
- 401 → `UnauthorizedFailure(detail ?? 'Unauthorized')`
- 403 → `ForbiddenFailure(detail ?? 'Forbidden')`
- 404 → `NotFoundFailure(detail ?? 'Post not found')`
- ≥500 → `ServerFailure(statusCode, detail)`
- default → if `e.error is Failure` re-surface it; else `NetworkFailure(e.message)`
- catch-all `on Object` → `UnknownFailure`, `logger.error('EraseDbPostAdapter.call failed', …)`.

**Server-side authorization (unchanged):** the backend still permits delete only on one's own
post (else 403) and erase only for a superuser (else 403). The client guards mirror this
**before** the network call — see §5 steps 2 and 3.

---

## 4. STRUCTURE — files touched (migration, not new tree)

No new files. No routing changes (neither vertical owns an `auto_route` page; they are buttons
hosted inside `post_details`). Edits grouped by layer. `(BR)` = requires
`dart run build_runner build --delete-conflicting-outputs`.

```
_shared
└── data/posts_api_client.dart  (BR — retrofit posts_api_client.g.dart)
      deletePost(@Path('username') String username, @Path('id') int id)
         → deletePost(@Path('user_id') int userId, @Path('id') int id)        // DELETE /{user_id}/post/{id}
      eraseDbPost(@Path('username') String username, @Path('id') int id)
         → eraseDbPost(@Path('user_id') int userId, @Path('id') int id)       // DELETE /{user_id}/db_post/{id}
      ↑ all other methods untouched.

delete_post vertical
├── domain/ports/delete_post_port.dart       call(String username, int id) → call(int userId, int id)
├── domain/usecases/delete_post_usecase.dart ownership guard (identity):
│       currentUser == null || currentUser.username != username
│          → currentUser == null || currentUser.id != userId
│       returns the SAME Failure.forbidden(message: "Cannot delete another user's post")
│       then _port(userId, id)
├── data/delete_post_adapter.dart            call(int userId, int id) → _api.deletePost(userId, id)
│                                             failure mapping (401/403/404 + network) +
│                                             catch-all logger.error UNCHANGED
├── application/delete_post_cubit.dart        confirmAndDelete(String username, int id)
│                                                → confirmAndDelete(int userId, int id)
│                                             _deletePost(userId, id); PostDeleted(id) UNCHANGED
├── application/delete_post_state.dart        UNCHANGED
└── presentation/delete_post_button.dart      field username:String → userId:int (outer + _Inner)
                                               confirmAndDelete(userId, id); UI/tooltip/dialog UNCHANGED

erase_db_post vertical
├── domain/ports/erase_db_post_port.dart      call(String username, int id) → call(int userId, int id)
├── domain/usecases/erase_db_post_usecase.dart call({String username, int id, bool isSuperuser})
│                                                → call({int userId, int id, bool isSuperuser})
│       superuser guard UNCHANGED (if (!isSuperuser) return Failure.permissionDenied())
│       then _port(userId, id)
├── data/erase_db_post_adapter.dart           call(int userId, int id) → _api.eraseDbPost(userId, id)
│                                             failure mapping (401/403/404/≥500/network) +
│                                             catch-all logger.error UNCHANGED
├── application/erase_db_post_cubit.dart       confirmAndErase(String username, int id)
│                                                → confirmAndErase(int userId, int id)
│                                             _eraseDbPost(userId: userId, id: id, isSuperuser: …)
│                                             PostDeleted(id) UNCHANGED
├── application/erase_db_post_state.dart       UNCHANGED
└── presentation/erase_db_post_button.dart     field username:String → userId:int (outer + _Inner)
                                                confirmAndErase(userId, id); UI/tooltip/dialog UNCHANGED

post_details screen (bridge removal — action row only)
└── presentation/post_details_screen.dart
      _PostDetailsActions.build:
        REMOVE  final handle = postState.post.username;     // + its bridge comment
        DeletePostButton(username: handle, id: id) inside `if (handle != null)`
           → DeletePostButton(userId: userId, id: id)        // unconditional under `if (isAuthor)`
        EraseDbPostButton(username: handle, id: id) inside `if (showErase && handle != null)`
           → EraseDbPostButton(userId: userId, id: id)       // guarded only by `if (showErase)`
      ↑ isAuthor / isSuperuser / showErase logic, the Edit IconButton, and _PostDetailsBody
        are all UNCHANGED. `userId` is the screen's existing route param (the author id).
```

> **Correction vs prd.md** (the code is authoritative): the delete ownership guard returns
> `Failure.forbidden(message: "Cannot delete another user's post")` **today**, not
> `Failure.permissionDenied()`. PRD story 12 says "mirroring the users-side `delete_user`
> slice 0049" — that mirroring applies to the **comparison shape** (`currentUser.id == userId`
> instead of a handle compare), **not** to the failure type. Keep the existing
> `Failure.forbidden(...)` with its current message verbatim. (The erase use-case already
> returns `Failure.permissionDenied()` for a non-superuser — also unchanged.)

---

## 5. WHAT TO DO — step by step

Work bottom-up so each layer compiles against the one below before the screen is touched. Run
`build_runner` once after the `_shared` edit.

**1) `_shared` API client.** In `posts_api_client.dart`, change `deletePost` and `eraseDbPost`
path params to `@Path('user_id') int userId` and the path templates to `/{user_id}/post/{id}`
and `/{user_id}/db_post/{id}`. Leave the other methods exactly as-is. This breaks
`delete_post_adapter` and `erase_db_post_adapter` (intended — that is the coupling).

**2) delete_post domain → data → application → presentation.**
- `DeletePostPort.call(int userId, int id)`.
- `DeletePostUseCase.call(int userId, int id)`: change the guard from
  `currentUser == null || currentUser.username != username` to
  `currentUser == null || currentUser.id != userId`. Return the **same**
  `Failure.forbidden(message: "Cannot delete another user's post")`. Then `_port(userId, id)`.
- `DeletePostAdapter.call(int userId, int id)` → `_api.deletePost(userId, id)`. The
  401/403/404 + network mapping, the `_detail` helper, and the catch-all `logger.error` stay
  byte-for-byte.
- `DeletePostCubit.confirmAndDelete(int userId, int id)` → `_deletePost(userId, id)`. The
  `deleting` → `success`/`failure` transitions, `PostDeleted(id)` publish, `requestConfirmation`,
  and `cancel` are unchanged.
- `DeletePostButton` (+ `_DeletePostButtonInner`): field `final int userId` (was `username`);
  pass `userId` to `_DeletePostButtonInner` and to `confirmAndDelete(userId, id)`. The icon,
  tooltip, confirmation dialog, success snackbar + `router.pop()`, and failure snackbar are
  unchanged.

**3) erase_db_post domain → data → application → presentation.**
- `EraseDbPostPort.call(int userId, int id)`.
- `EraseDbPostUseCase.call({required int userId, required int id, required bool isSuperuser})`:
  keep the `if (!isSuperuser) return const Left(Failure.permissionDenied())` guard exactly;
  then `_port(userId, id)`.
- `EraseDbPostAdapter.call(int userId, int id)` → `_api.eraseDbPost(userId, id)`. The
  401/403/404/≥500/network mapping, the `_detail` helper, and the catch-all `logger.error`
  stay byte-for-byte.
- `EraseDbPostCubit.confirmAndErase(int userId, int id)` → `_eraseDbPost(userId: userId,
  id: id, isSuperuser: _authCubit.currentUser?.isSuperuser ?? false)`. The `deleting` →
  `success`/`failure` transitions, `PostDeleted(id)` publish, `requestConfirmation`, and
  `cancel` are unchanged.
- `EraseDbPostButton` (+ `_EraseDbPostButtonInner`): field `final int userId` (was `username`);
  pass `userId` to `_EraseDbPostButtonInner` and to `confirmAndErase(userId, id)`. UI unchanged.

**4) post_details action row (bridge removal).** In `post_details_screen.dart`,
`_PostDetailsActions.build`:
- Delete the `final handle = postState.post.username;` line and its bridge comment.
- `DeletePostButton(username: handle, id: id)` → `DeletePostButton(userId: userId, id: id)`,
  rendered unconditionally inside the existing `if (isAuthor) ...[ … ]` block (drop the
  `if (handle != null)` guard around it).
- `EraseDbPostButton(username: handle, id: id)` → `EraseDbPostButton(userId: userId, id: id)`,
  rendered under `if (showErase)` (drop the `&& handle != null`).
- `isAuthor` (`currentUser?.id == userId`), `isSuperuser`, `showErase`, the early
  `SizedBox.shrink()` returns, the Edit `IconButton`, and `_PostDetailsBody` are **unchanged**.
  `userId` is the screen's existing route param, already used for the `isAuthor` check.

**5) build_runner + verify.** Run
`dart run build_runner build --delete-conflicting-outputs` (regenerates the retrofit client
`posts_api_client.g.dart`; no freezed/router changes in this slice). Then `dart format .`,
`dart analyze` (must be clean — watch for the now-unused `postState.post.username` read and any
now-unused imports), and the test suite.

No new localization keys. No DTO changes. No routing changes. No `pubspec.yaml` changes.

---

## 6. TESTS

Acceptance gate first, then the per-layer re-green (detailed in `tests.md`; this block states
the contract the implementation must satisfy). Default four-layer coverage applies.

- **Slice contract outside-in (acceptance gate)** — mirroring
  `test/features/tiers/0047_delete_tier_id_contract/`: wire the **real** `delete_post` and
  `erase_db_post` adapter + use-case + cubit, mock `PostsApiClient` and `AuthCubit`, and
  `verify(() => api.deletePost(<int userId>, id))` and
  `verify(() => api.eraseDbPost(<int userId>, id))` with the integer id. No live backend.
- **Adapters (unit):** `DeletePostAdapter` success calls `deletePost(<int>, id)`; failure
  mapping (401/403/404 + network) + catch-all `logger.error` preserved. `EraseDbPostAdapter`
  success calls `eraseDbPost(<int>, id)`; failure mapping (401/403/404/≥500 server + network)
  + catch-all `logger.error` preserved.
- **Use-cases (unit):** `DeletePostUseCase` delegates to the port with the integer id when
  `currentUser.id == userId`, and returns `Failure.forbidden` (no port call) when the ids
  differ or `currentUser == null`. `EraseDbPostUseCase` delegates with the integer id when
  `isSuperuser`, and returns `Failure.permissionDenied` (no port call) otherwise.
- **Cubits (`bloc_test`):** `DeletePostCubit.confirmAndDelete(<int>, id)` → deleting →
  success (publishes `PostDeleted`) / failure; `requestConfirmation` and `cancel` transitions
  unchanged. `EraseDbPostCubit.confirmAndErase(<int>, id)` likewise (with the superuser flag
  sourced from `AuthCubit`).
- **Widgets:** the `DeletePostButton`/`EraseDbPostButton` widgets drive their cubit with the
  integer `userId`. The `post_details` action row shows Delete (+ Edit) for the author
  (`currentUser.id == userId`) and Erase for a non-author superuser — **without** a handle
  present on the loaded post (the 0051 bridge is gone). A non-author non-superuser sees neither.
- **Downstream re-green:** existing `delete_post`/`erase_db_post` cubit/use-case/adapter tests
  migrated username→id; the `post_details` screen test updated for the bridge removal
  (Delete/Erase now shown without a handle).

---

## 7. REPORT (what the implementing agent returns)

- List of files changed (none created), grouped by vertical / `_shared` / `post_details`.
- Confirmation that **no out-of-scope slice** was touched (post_details read path, edit_post,
  create_post, user_posts, moderate_post, pending_posts, list_posts) and that no **handle**
  was migrated to id (`Post.username`, `CurrentUser.username`, `@username` labels untouched).
- Confirmation that **no routing change** was made (neither vertical owns a route) and that
  `build_runner` regenerated `posts_api_client.g.dart`.
- The slice contract outside-in test: red-before / green-after evidence.
- `dart format` clean, `dart analyze` clean, full `flutter test` green — with an explicit
  count of downstream tests re-greened.

---

## 8. WHAT NOT TO DO

- ❌ Do **not** change the delete ownership failure from `Failure.forbidden(...)` to
  `Failure.permissionDenied()` — only the *comparison* migrates to id; the failure type and
  message stay as they are today.
- ❌ Do **not** migrate any **handle**: `Post.username`, `CurrentUser.username`, or `@username`
  labels. Only the request-target identity becomes `userId`.
- ❌ Do **not** add a `username` field to `PostDto` (or otherwise populate `Post.username` from
  `getPost`) to source the buttons — they take the route `userId`, not the loaded handle.
- ❌ Do **not** add a route, `@PathParam`, or `auto_route` page for delete/erase — they are
  buttons hosted inside `post_details`; **no** path string in `core/routing` changes.
- ❌ Do **not** touch the other `PostsApiClient` methods, the `_shared` DTOs, or anything in
  `post_details` beyond the action row (the read path was migrated in 0051).
- ❌ Do **not** change the DELETE request semantics (they are body-less), the confirmation
  dialogs, the success/forbidden snackbar messages, the `PostDeleted` event, or the
  pop-on-success navigation.
- ❌ Do **not** drop any `on Object catch (e, st)` + `logger.error` catch-all in an adapter,
  and do **not** alter the failure mapping (`deletePost` 401/403/404/network; `eraseDbPost`
  401/403/404/≥500/network).
- ❌ Do **not** add a dependency, a new localization key, or change `CurrentUser` / `AuthSession`.
