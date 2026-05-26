# 0052 · delete_post_erase_db_post_route_to_user_id — Outside-in test spec

## Goal

Prove that deleting and erasing a post both address it by the author's **integer
`user_id`**: `DeletePostCubit.confirmAndDelete` makes the client call `deletePost(<int>, id)`
and `EraseDbPostCubit.confirmAndErase` makes it call `eraseDbPost(<int>, id)`, that both
publish `PostDeleted(id)` on success, and that the pre-network guards refuse by **id** — a
non-author delete and a non-superuser erase are rejected with no client call.

## Entry point

Two cubits exercise the two migrated verticals through their public surface:

- `deletePostCubit.confirmAndDelete(42, 7)` — the delete vertical.
- `eraseDbPostCubit.confirmAndErase(42, 7)` — the erase vertical.

## Wired real (production code in the test)

- `DeletePostAdapter` (the delete_post Adapter), bound as `DeletePostPort`.
- `DeletePostUseCase`.
- `DeletePostCubit` (system under test for the delete vertical).
- `EraseDbPostAdapter` (the erase_db_post Adapter), bound as `EraseDbPostPort`.
- `EraseDbPostUseCase`.
- `EraseDbPostCubit` (system under test for the erase vertical).

## Mocked (system boundaries only)

- **`PostsApiClient`**: the HTTP boundary.
  - `deletePost(42, 7)` completes normally (server returns no body).
  - `eraseDbPost(42, 7)` completes normally (server returns no body).
- **`AuthCubit`**: `currentUser` returns a `CurrentUser` fixture whose `id` and `isSuperuser`
  are set per scenario (id `42` author / id `99` non-author; `isSuperuser: true`/`false`).
- **`PostEventBus`**: a mock whose `publish(...)` is observed (verifies `PostDeleted(7)`).
- **`AppLogger`**: a mock injected into both adapters (no error expected on the happy paths).

## Test scenarios

### Scenario 1: the author deleting a post calls `deletePost` with the integer user id

**Setup:**
- `AuthCubit.currentUser` returns a fixture with `id: 42`.
- `PostsApiClient.deletePost(42, 7)` completes normally.

**Act:**
- `deletePostCubit.confirmAndDelete(42, 7)`

**Expect:**
- States emitted by the Cubit: `[DeletePostDeleting, DeletePostSuccess]`.
- Side effects observed: `PostEventBus.publish` received a `PostDeleted` with `id == 7`.
- Mocks verified: `PostsApiClient.deletePost(42, 7)` called exactly once with the **integer**
  `42` (not a username string).

### Scenario 2: a non-author is forbidden by id and no delete is sent

**Setup:**
- `AuthCubit.currentUser` returns a fixture with `id: 99` (≠ the target author id `42`).

**Act:**
- `deletePostCubit.confirmAndDelete(42, 7)`

**Expect:**
- States emitted by the Cubit: `[DeletePostDeleting, DeletePostFailure(ForbiddenFailure)]`.
- Side effects observed: `PostEventBus.publish` received nothing.
- Mocks verified: `PostsApiClient.deletePost` is **never** called (ownership decided by
  `currentUser.id == userId`).

### Scenario 3: a superuser erasing a post calls `eraseDbPost` with the integer user id

**Setup:**
- `AuthCubit.currentUser` returns a fixture with `isSuperuser: true`.
- `PostsApiClient.eraseDbPost(42, 7)` completes normally.

**Act:**
- `eraseDbPostCubit.confirmAndErase(42, 7)`

**Expect:**
- States emitted by the Cubit: `[EraseDbPostDeleting, EraseDbPostSuccess]`.
- Side effects observed: `PostEventBus.publish` received a `PostDeleted` with `id == 7`.
- Mocks verified: `PostsApiClient.eraseDbPost(42, 7)` called exactly once with the **integer**
  `42`.

### Scenario 4: a non-superuser is permission-denied and no erase is sent

**Setup:**
- `AuthCubit.currentUser` returns a fixture with `isSuperuser: false`.

**Act:**
- `eraseDbPostCubit.confirmAndErase(42, 7)`

**Expect:**
- States emitted by the Cubit: `[EraseDbPostDeleting, EraseDbPostFailure(PermissionDenied)]`.
- Side effects observed: `PostEventBus.publish` received nothing.
- Mocks verified: `PostsApiClient.eraseDbPost` is **never** called (superuser guard runs
  before the network call).

## Out of scope for this test

- Widget rendering — the id-keyed Delete/Erase buttons, the action row showing Delete (+ Edit)
  for the author and Erase for a non-author superuser **without** a loaded handle, and the
  bridge removal are covered by widget tests separately.
- Route navigation and the success pop / snackbars — covered by widget tests separately.
- The adapters' HTTP failure mapping (deletePost 401/403/404/network; eraseDbPost
  401/403/404/≥500/network) and the catch-all `logger.error` — covered by adapter unit tests.
- The `requestConfirmation` / `cancel` confirmation transitions — covered by cubit unit tests.
