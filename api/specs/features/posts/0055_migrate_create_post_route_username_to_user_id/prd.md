# PRD — Migrate `create_post` Route from `{username}` to `{user_id}` (slice 0055)

**Slice:** `0055_migrate_create_post_route_username_to_user_id`
**Resource:** posts
**Depends on:** slice 0011 (`create_post`) and slice 0032 (`extract_user_lookup`)
must be complete. Sibling of slice 0054
(`migrate_get_post_route_username_to_user_id`) — same `{username}` → `{user_id}`
initiative, but **no code dependency** on 0054 (disjoint files). This slice is
the first write-path migration and therefore the first to evolve the shared
`posts/_shared` lookup and ownership modules.

---

## Problem Statement

The `create_post` endpoint (`POST /{username}/post`) identifies the post author
by their `username` string in the URL path. This is the same instability the
rest of the API has already moved past: a username is mutable, so any stored or
shared URL targeting a user's create-post path can silently break when that user
renames. It also forces author resolution through the mutable `User.username`
column rather than the stable integer primary key.

The Users API routes, `list_posts` (slice 0042), and `get_post` (slice 0054)
have already migrated from `{username}` to `{user_id}`. `create_post` is the
next Posts API route to align, and the first that exercises the shared
write-path helpers in `posts/_shared` (`UserLookupPort`/`UserLookupAdapter` and
the `check_post_owner` ownership policy).

## Solution

Replace `{username}` with `{user_id}` (the integer autoincrement primary key of
the `User` model) as the author identifier in the route, making it
`POST /{user_id}/post`. The flow mirrors the established id-based reference
(`update_user`): resolve the target user by id (404 "User not found" if absent),
then enforce ownership by comparing integer IDs (403 if the authenticated
requester is not that user), then create the post with
`created_by_user_id = target_user_id`.

To support id-based resolution, the shared `UserLookupPort` /
`UserLookupAdapter` gain a new method `get_active_user_by_id(user_id)`
**additively** — the existing `get_active_user_by_username` remains so that the
other not-yet-migrated write slices stay green. The shared ownership policy
`check_post_owner` is **converted** from a username comparison to an integer-id
comparison (`requester_user_id`, `owner_user_id`). Because `erase_post` is the
only current caller of `check_post_owner` and has no requester id available,
this slice also makes a contained change to `erase_post` so the test suite stays
green (details below).

The old `/{username}/post` route is removed with no backwards-compatibility
shim.

## User Stories

1. As an authenticated API client, I want to create a post for a user by their
   integer ID (`POST /{user_id}/post`), so that the URL is stable even if that
   user later changes their username.
2. As an authenticated user, I want to create a post under my own `user_id`, so
   that I can publish content as myself.
3. As an authenticated user, I want to receive HTTP 403 when I try to create a
   post under a `user_id` that is not mine, so that I cannot publish as someone
   else.
4. As an authenticated API client, I want to receive HTTP 404 when I create a
   post for a `user_id` that does not exist (or is soft-deleted), so that an
   invalid author is reported as not found before any ownership check.
5. As an authenticated API client, I want the 404-before-403 ordering to match
   the rest of the id-based API (resolve user, then check ownership), so that
   behaviour is consistent across endpoints.
6. As an unauthenticated client, I want to continue to receive HTTP 401 when I
   call `POST /{user_id}/post` without credentials, so that creation stays
   protected exactly as today.
7. As an API client, I want the request body (`title`, `text`, `media_url`) and
   validation rules to be unchanged, so that only the URL changes for me.
8. As an API client, I want the response body shape (`id`, `title`, `text`,
   `media_url`, `created_by_user_id`, `created_at`, `status`, `post_uuid`) to be
   identical to the current response, so that my response parser needs no change.
9. As an API client, I want a newly created post to keep its current default
   status (`pending_review`), so that the moderation workflow is unaffected.
10. As an API client, I want to receive HTTP 422 when I pass a non-integer value
    for `user_id` in the path, so that type errors surface immediately.
11. As an API client, I want the old `/{username}/post` URL with a string
    username to no longer match the endpoint (HTTP 422/404), so that the
    breaking change is explicit and forces a client update.
12. As a developer, I want the shared user-lookup helper to resolve authors by
    integer id, so that the write path no longer depends on the mutable
    `username` column.
13. As a developer, I want the shared `check_post_owner` policy to compare
    integer ids, so that ownership checks across post write slices converge on a
    single stable identifier.
14. As a developer, I want `erase_post` to remain green after `check_post_owner`
    is converted, so that the migration does not introduce a regression in an
    unmigrated slice.

## Implementation Decisions

### Modified module: domain command (`CreatePostCommand`)

Updated in place — no new class:

- `target_username: str` → `target_user_id: int`.
- `requester_username: str` → `requester_user_id: int`.
- `title`, `text`, `media_url` unchanged.
- `CreatePostInternalCommand` is unchanged (it already carries
  `created_by_user_id: int`).

### Modified module: use case (`CreatePostUseCase`)

The flow mirrors the `update_user` reference:

1. `author = get_active_user_by_id(command.target_user_id)`; if `None`, raise
   `NotFoundDomainError("User not found")`.
2. `check_post_owner(command.requester_user_id, author.id)` — raises
   `ForbiddenDomainError` if the requester is not the author.
3. Build `CreatePostInternalCommand(created_by_user_id=author.id, ...)` and call
   the create port.

The previous inline username comparison and its message ("You can only post
under your own username") are removed; ownership now delegates to the shared
`check_post_owner` policy (see § Modified shared module: ownership policy).

### Modified module: presentation router

- **Route path:** `/{username}/post` → `/{user_id}/post`. Path parameter type
  changes from `str` to `int`.
- **Command construction:** `target_username=username` →
  `target_user_id=user_id`; `requester_username=current_user["username"]` →
  `requester_user_id=current_user["id"]`. The `get_current_user` dependency
  already exposes an `id` key — no auth-layer change.
- **No cache decorator change:** `create_post` has no `@cache` decorator today
  and gains none.

### Unchanged module: data adapter (`CreatePostAdapter`)

The create adapter already operates on `created_by_user_id` (an integer) via
`CreatePostInternalCommand`. It requires no change.

### Modified shared module: user lookup (`UserLookupPort` / `UserLookupAdapter`)

**Additive** change (Phase 1 of the shared-helper evolution):

- Add `get_active_user_by_id(user_id: int) -> UserIdentity | None` to the port
  Protocol and the adapter. The adapter filters
  `User.id == user_id AND User.is_deleted == False` and maps to `UserIdentity`,
  mirroring the existing `get_active_user_by_username` and the id existence
  lookup used by `get_user_by_id`.
- `get_active_user_by_username` is **retained** so the not-yet-migrated write
  slices (`update_post`, `erase_post`, `erase_db_post`) keep compiling and
  passing. Its removal is deferred to the final cleanup slice.

### Modified shared module: ownership policy (`check_post_owner`)

**Converted** from username- to id-based comparison:

- Signature `check_post_owner(requester_username: str, owner_username: str)` →
  `check_post_owner(requester_user_id: int, owner_user_id: int)`.
- It continues to raise a bare `ForbiddenDomainError()` (no message), exactly as
  today — only the compared values change from strings to ints.

### Cross-slice change: `erase_post` (kept green, route NOT migrated)

`erase_post` is the only current caller of `check_post_owner` and has no
requester id in its command, so converting the policy forces a contained change
to `erase_post` to keep the suite green:

- `ErasePostCommand`: `requester_username: str` → `requester_user_id: int`
  (the `username` target field and `post_id` are unchanged).
- `erase_post` router: pass `requester_user_id=current_user["id"]` instead of
  `requester_username=current_user["username"]`.
- `erase_post` use case: `check_post_owner(command.requester_username,
  user.username)` → `check_post_owner(command.requester_user_id, user.id)`.

**Explicitly NOT changed in `erase_post` here:** its route stays
`DELETE /{username}/post/{id}`; its `get_active_user_by_username(command.username)`
lookup stays; its cache keys stay `{username}_…`. The full `erase_post` route
migration (path, cache keys, target lookup) remains its own later slice.

### Authentication and authorization

| Concern | Value |
|---|---|
| Method | `POST` |
| Old path | `/{username}/post` |
| New path | `/{user_id}/post` |
| Path param | `user_id: int` |
| Authentication | Required (`get_current_user`) |
| Authorization | Requester must equal the target user (`requester_user_id == target_user_id`) |

### API contract

**Request body — unchanged:** `title` (1–30 chars), `text` (1–63206 chars),
`media_url` (optional). `extra="forbid"` is retained.

**Response body (HTTP 201) — unchanged shape:** `CreatePostResponse` keeps all
current fields. Note `create_post` does **not** include a `username` field in
its response (only `created_by_user_id`); this is unchanged.

**Error responses:**

| Status | Condition |
|---|---|
| 201 | Post created for the authenticated owner |
| 401 | No / invalid credentials |
| 403 | Authenticated requester is not the target user |
| 404 | `user_id` does not exist or is soft-deleted |
| 422 | Non-integer value provided for `user_id` |

### No database migration

`Post.created_by_user_id` (integer FK to `User.id`) already exists. No Alembic
migration is needed.

## Testing Decisions

Good tests verify observable behaviour through the HTTP interface or the
use-case / adapter boundary, not internal SQLAlchemy query structure. All four
test levels apply for `create_post`; the shared changes add targeted tests; the
`erase_post` adaptation updates one existing unit test.

### Use-case unit test (`create_post`)

Mock both the create port and the user-lookup port. Cases:
- **Happy path (owner)** — lookup returns an author whose `id` equals
  `requester_user_id`; assert the create port receives a
  `CreatePostInternalCommand` with `created_by_user_id == target_user_id` and the
  use-case returns the created post.
- **User not found** — lookup returns `None`; assert
  `NotFoundDomainError("User not found")` and that the create port is never
  called.
- **Not owner** — lookup returns an author whose `id` differs from
  `requester_user_id`; assert `ForbiddenDomainError` and that the create port is
  never called.

Prior art: `tests/features/posts/0011_create_post/` use-case unit test.

### Shared adapter unit test (`UserLookupAdapter.get_active_user_by_id`)

Real async session against the test Postgres database, added alongside the
existing username tests in `tests/features/posts/0032_extract_user_lookup/`:
- **Found** — create an active user; `get_active_user_by_id(id)` returns a
  matching `UserIdentity`.
- **Unknown id** — returns `None`.
- **Soft-deleted user** — returns `None`.

The existing `get_active_user_by_username` tests remain (the method is retained).

### Endpoint integration test (`create_post`)

`httpx.AsyncClient` against the running app with the test Postgres.
- **201 owner** — authenticate as the user; `POST /{user_id}/post`; assert 201
  and the response fields, including default `status`.
- **403 non-owner** — authenticate as user A; `POST /{userB_id}/post`; assert 403.
- **404 unknown user** — authenticate; `POST /{unknown_id}/post`; assert 404.
- **401 unauthenticated** — no credentials; assert 401.
- **422 non-integer user_id** — `POST /not-an-integer/post`; assert 422.
- **Old route gone** — `POST /{username}/post` with a string username; assert
  HTTP 422/404.

Prior art: `tests/features/posts/0011_create_post/presentation/`.

### Cross-slice regression (`erase_post`)

Update the `erase_post` use-case unit test to drive the ownership check with
`requester_user_id` / `user.id` instead of usernames. The `erase_post` endpoint
and outside-in tests are unchanged because its route and behaviour are
unchanged. Run the full suite before and after and prove zero net-new failures
(see user memory `project_route_migration_downstream_tests`).

### Outside-in test (acceptance gate)

One end-to-end test with no mocks:

1. Create a user via `POST /users/`; capture the returned `id`.
2. Authenticate as that user.
3. `POST /{user_id}/post` with a valid body; assert HTTP 201 and the response
   fields.
4. As the same user, `POST /{otherUser_id}/post`; assert HTTP 403.
5. `POST /{username}/post` with the string username; assert HTTP 422 (old route
   gone).

The slice is not done until this test is green.

## Out of Scope

- `update_post`, `erase_post` (route), `erase_db_post` — separate migration
  slices. Only `erase_post`'s **ownership-check call site** is touched here, and
  only to keep the suite green; its route, cache keys, and target lookup are
  unchanged.
- Removing `get_active_user_by_username` from `UserLookupPort`/`UserLookupAdapter`
  — deferred to the final cleanup slice; it is retained here for the unmigrated
  callers.
- `get_post` (slice 0054) and `list_posts` (slice 0042) — already migrated.
- Adding a `username` field to the `create_post` response — it never had one;
  not added.
- Adding/altering cache on `create_post` — it has no cache decorator and gains
  none.
- Changing the post `id` to a UUID — frozen; the integer `id` is retained.
- The Flutter client — its calls to the old route will break; accepted and
  handled in the Flutter spec slices.

## Further Notes

- **403 message change (observable).** The previous `create_post`-specific 403
  message ("You can only post under your own username") is removed; ownership now
  delegates to the shared `check_post_owner`, which raises a bare
  `ForbiddenDomainError()` (matching `erase_post`). This removes the stale
  `username` reference from the 403 and unifies the 403 behaviour across post
  write slices. If a user-facing 403 message is later desired, it can be added in
  a follow-up without affecting this migration.
- **Phase 1 / Phase 2 note.** Converting `check_post_owner` to id-based pulls
  work that the migration handoff originally scheduled for the final cleanup
  slice forward into this slice (a deliberate, user-approved decision). The
  cleanup slice's remaining responsibilities are unchanged: remove
  `get_active_user_by_username`, finish the remaining route migrations, and any
  remaining message rewording.
- **Test-tree-green discipline.** Because `check_post_owner` is shared, the
  `erase_post` call site and its unit test must be updated in the same slice;
  otherwise the suite would go red. Baseline the full suite before and after.
- The `update_user` slice is the reference for the id-based
  resolve-then-authorize flow (`get_*_by_id` → 404, then `check_owner` → 403).
- The integration and outside-in tests for slice 0011 (`create_post`) reference
  the old `/{username}/post` URL and will need their URLs updated to
  `/{user_id}/post` once this migration lands.
