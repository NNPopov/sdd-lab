# PRD — Migrate `erase_db_post` Route from `{username}` to `{user_id}` (slice 0058)

**Slice:** `0058_migrate_erase_db_post_route_username_to_user_id`
**Resource:** posts
**Depends on:** slice 0030 (`erase_db_post`) and slice 0031
(`fix_erase_db_post_cascade`) must be complete, and **slice 0055**
(`migrate_create_post_route_username_to_user_id`) must land first — this slice
consumes the additive `get_active_user_by_id` introduced on the shared
`UserLookupPort`/`UserLookupAdapter` in 0055. Sibling of slices 0042 / 0054 /
0055 / 0056 / 0057; this is the **fifth and final route-migration slice** of the
`{username}` → `{user_id}` initiative. The cleanup slice follows.

---

## Problem Statement

The `erase_db_post` endpoint (`DELETE /{username}/db_post/{id}`) — the
superuser-only hard delete — still identifies the post author by their
`username` string in the URL path. It is the last Posts API route still keyed on
`{username}`. As with every other route in this initiative, a username is
mutable, so any stored or shared hard-delete URL can silently break when the
user renames, and the target author is still resolved through the mutable
`User.username` column instead of the stable integer primary key.

`erase_db_post` also carries the same **latent cache-staleness bug** that
`update_post` (0056) and `erase_post` (0057) fixed: it invalidates the
single-post cache under `{username}_post_cache` and the list cache under
`{username}_posts`, but `get_post` (0054) now reads `{user_id}_post_cache` and
`list_posts` (0042) now caches `{user_id}_posts:*`. So a hard delete via the
still-`{username}` route fails to invalidate the now-`{user_id}`-keyed
read/list caches, and clients can keep seeing the destroyed post (and a stale
list) until the TTL expires.

Additionally, `erase_db_post` is the **last consumer** of the shared
`get_active_user_by_username` lookup. Until it migrates, the cleanup slice cannot
remove that method.

## Solution

Replace `{username}` with `{user_id}` (the integer autoincrement primary key of
the `User` model) as the author identifier in the route, making it
`DELETE /{user_id}/db_post/{id}`. The use-case resolves the target user by id via
the shared `get_active_user_by_id` (404 "User not found" if absent), then
performs the owner-scoped post lookup and the hard delete, both of which are
**already id-based** and unchanged. There is **no ownership check** — the
endpoint is gated by `get_current_superuser` and a superuser may hard-delete any
user's post; this is unchanged.

The cache keys are repointed from `{username}_…` to `{user_id}_…`, which
**realigns** `erase_db_post`'s invalidation with the keys that `get_post` (0054)
and `list_posts` (0042) already use — fixing the latent staleness bug as a
direct consequence of the migration.

The old `/{username}/db_post/{id}` route is removed with no
backwards-compatibility shim.

## User Stories

1. As a superuser API client, I want to hard-delete a post by the author's
   integer ID and the post ID (`DELETE /{user_id}/db_post/{id}`), so that the URL
   is stable even if the author later changes their username.
2. As a superuser, I want to hard-delete any user's post regardless of
   ownership, so that my existing moderation/cleanup capability is unchanged
   after the route migration.
3. As a superuser API client, I want to receive HTTP 404 when the `user_id` does
   not exist or is soft-deleted, so that an invalid author is reported as not
   found before the post lookup.
4. As a superuser API client, I want to receive HTTP 404 when the post does not
   exist or is not owned by the given `user_id`, so that an invalid post is
   reported as not found.
5. As a superuser API client, I want the 404(user)→404(post) ordering to match
   the current behaviour, so that nothing about the error semantics changes apart
   from the identifier type.
6. As a non-superuser authenticated user, I want to continue to receive HTTP 403
   when I call `DELETE /{user_id}/db_post/{id}`, so that the superuser gate is
   unchanged.
7. As an unauthenticated client, I want to continue to receive HTTP 401 when I
   call the endpoint without credentials, so that the hard delete stays
   protected exactly as today.
8. As an API client, I want the response body
   (`{"message": "Post deleted from the database"}`) to be unchanged, so that my
   response parser needs no change.
9. As an API client, I want to receive HTTP 422 when I pass a non-integer value
   for `user_id` in the path, so that type errors surface immediately.
10. As an API client, I want the old `/{username}/db_post/{id}` URL with a string
    username to no longer match the endpoint (HTTP 422/404), so that the
    breaking change is explicit.
11. As an API client, I want a hard delete to immediately invalidate the cached
    single post and the cached post list for that user, so that I never read a
    destroyed post or a stale list afterwards.
12. As a developer, I want `erase_db_post` to resolve the target author by
    integer id, so that the hard-delete path no longer depends on the mutable
    `username` column.
13. As a developer, I want `erase_db_post` migrated so that
    `get_active_user_by_username` has no remaining consumer and the cleanup slice
    can remove it.

## Implementation Decisions

### Modified module: domain command (`EraseDbPostCommand`)

Updated in place — no new class:

- `username: str` (the target author) → `user_id: int`.
- `post_id: int` is unchanged.
- There is no requester field — the endpoint performs no ownership check
  (superuser-only), and this is unchanged.

### Modified module: use case (`EraseDbPostUseCase`)

Only the target lookup changes:

1. `user = get_active_user_by_id(command.user_id)`; if `None`, raise
   `NotFoundDomainError("User not found")`. (Was
   `get_active_user_by_username(command.username)`.)
2. `post = find_post(command.post_id, owner_id=user.id)`; if `None`, raise
   `NotFoundDomainError("Post not found")` — **unchanged**.
3. `hard_delete(command.post_id)` — **unchanged** (including its moderation-log
   cascade behaviour from slice 0031).

No ownership check is added — the superuser gate at the router boundary is the
only authorization, exactly as today.

### Modified module: presentation router

- **Route path:** `/{username}/db_post/{id}` → `/{user_id}/db_post/{id}`. The
  author path parameter type changes from `str` to `int`; `id` stays `int`.
- **Auth dependency:** `get_current_superuser` — unchanged.
- **Command construction:** `username=username` → `user_id=user_id`.
- **Cache decorator:** repoint both keys to `user_id`:
  - `key_prefix` `"{username}_post_cache"` → `"{user_id}_post_cache"`.
  - `to_invalidate_extra` `{"{username}_posts": "{username}"}` →
    `{"{user_id}_posts": "{user_id}"}`.
  - `resource_id_name` continues to reference the post `id`.

### Unchanged module: data adapter (`EraseDbPostAdapter`) and port

No change. `find_post(post_id, owner_id)` already filters
`Post.created_by_user_id == owner_id` (an integer), and `hard_delete(post_id)`
operates on `Post.id` (loading `moderation_logs` for the cascade). Neither
references `username`.

### Dependency on slice 0055 (shared lookup)

This slice **uses** but does not modify the shared `posts/_shared` helpers:
`get_active_user_by_id` already exists on `UserLookupPort`/`UserLookupAdapter`
(added additively in 0055). After this slice, `get_active_user_by_username` has
no remaining consumer; removing it is the cleanup slice's job, not this slice's.

### Authentication and authorization

| Concern | Value |
|---|---|
| Method | `DELETE` |
| Old path | `/{username}/db_post/{id}` |
| New path | `/{user_id}/db_post/{id}` |
| Path params | `user_id: int`, `id: int` |
| Authentication | Required, superuser only (`get_current_superuser`) |
| Authorization | Superuser gate only; no per-post ownership check |

### API contract

**Response body — unchanged:** `{"message": "Post deleted from the database"}`.

**Error responses:**

| Status | Condition |
|---|---|
| 200 | Post hard-deleted |
| 401 | No / invalid credentials |
| 403 | Authenticated user is not a superuser |
| 404 | `user_id` not found / soft-deleted, or post not found / not owned by `user_id` |
| 422 | Non-integer value provided for `user_id` |

### No database migration

`Post.created_by_user_id` already exists; the post lookup and hard delete operate
on `Post.id` / `Post.created_by_user_id`. No Alembic migration is needed.

## Testing Decisions

Good tests verify observable behaviour through the HTTP interface or the
use-case boundary, not internal SQLAlchemy query structure. The use-case,
endpoint, and outside-in levels apply; the adapter test opts out (the adapter is
unchanged).

### Use-case unit test

Mock the erase port and the user-lookup port. Cases:
- **Happy path** — lookup returns a user, `find_post` returns a record; assert
  `hard_delete` is called with the post id.
- **User not found** — lookup returns `None`; assert
  `NotFoundDomainError("User not found")`; assert `find_post` and `hard_delete`
  are never called.
- **Post not found / not owned** — lookup returns the user, `find_post` returns
  `None`; assert `NotFoundDomainError("Post not found")`; assert `hard_delete` is
  never called.

The existing `0030_erase_db_post` use-case unit test drives the lookup by
username; this slice updates it to drive the lookup by id.

### Adapter unit test — opt-out

The adapter is **not changed** by this slice, so no new adapter test is added and
the existing `0030_erase_db_post` / `0031_fix_erase_db_post_cascade` adapter
tests (including the moderation-log cascade test) continue to apply unchanged.

### Endpoint integration test

`httpx.AsyncClient` against the running app with the test Postgres.
- **200 superuser** — authenticate as a superuser; `DELETE /{user_id}/db_post/{id}`;
  assert 200 and that a subsequent read returns 404.
- **403 non-superuser** — authenticate as a regular user; assert 403.
- **404 unknown user** — authenticate as a superuser; target an unknown
  `user_id`; assert 404.
- **404 unknown post** — authenticate as a superuser; target an unknown post id;
  assert 404.
- **401 unauthenticated** — no credentials; assert 401.
- **422 non-integer user_id** — `DELETE /not-an-integer/db_post/1`; assert 422.
- **Old route gone** — `DELETE /{username}/db_post/{id}` with a string username;
  assert HTTP 422/404.
- **Cache invalidation** — read the post (populating `{user_id}_post_cache`),
  hard-delete it, read again; assert the post is gone (no stale read).

Prior art: `tests/features/posts/0030_erase_db_post/presentation/` and
`tests/features/posts/0031_fix_erase_db_post_cascade/`.

### Outside-in test (acceptance gate)

One end-to-end test with no mocks:

1. Create a user via `POST /users/`; capture the returned `id`.
2. Create a post for that user; capture the post `id`.
3. Authenticate as a superuser; `GET /{user_id}/post/{id}`; assert HTTP 200
   (populates the read cache).
4. `DELETE /{user_id}/db_post/{id}`; assert HTTP 200.
5. `GET /{user_id}/post/{id}`; assert HTTP 404 (proves the hard delete
   invalidated the `{user_id}`-keyed read cache and removed the row).
6. `DELETE /{username}/db_post/{id}` with the string username; assert HTTP 422
   (old route gone).

The slice is not done until this test is green.

## Out of Scope

- Removing `get_active_user_by_username` from `UserLookupPort`/`UserLookupAdapter`
  and updating its adapter test
  (`tests/features/posts/0032_extract_user_lookup/`) — that is the **cleanup
  slice's** job. This slice only removes the last *caller*; it leaves the method
  in place so the cleanup slice can delete it cleanly.
- Adding a per-post ownership check — `erase_db_post` is superuser-only by
  design; no ownership check is added.
- The `find_post` soft-delete filter and the `hard_delete` cascade behaviour —
  preserved exactly as established in slices 0030 / 0031.
- `get_post` (0054), `create_post` (0055), `update_post` (0056), `erase_post`
  (0057), `list_posts` (0042) — already migrated.
- Changing the post `id` to a UUID — frozen; the integer `id` is retained.
- The Flutter client — its calls to the old route will break; accepted and
  handled in the Flutter spec slices.

## Further Notes

- **No ownership/message decisions in this slice.** Unlike `create_post` (0055)
  and `update_post` (0056), `erase_db_post` performs no ownership check and
  raises no `ForbiddenDomainError` of its own, so there is no policy or 403
  message change here.
- **Cache realignment is the bug fix.** Repointing `erase_db_post`'s
  invalidation from `{username}_…` to `{user_id}_…` makes it invalidate the
  exact keys that `get_post` (0054, `{user_id}_post_cache`) and `list_posts`
  (0042, `{user_id}_posts:*`) now read from, eliminating the partial-migration
  staleness window for hard deletes.
- **Hard dependency on 0055.** This slice consumes `get_active_user_by_id` added
  in 0055; sequence 0055 → 0058. (It does not depend on 0056 or 0057.)
- **Completes the route migration.** After this slice, every Posts API route uses
  `{user_id}` and `get_active_user_by_username` has zero callers. The remaining
  work — removing `get_active_user_by_username` from the shared port/adapter,
  updating the `0032_extract_user_lookup` adapter test, and grepping for any
  residual "username" wording — belongs to the final cleanup slice.
- The integration and outside-in tests for slices 0030 / 0031 reference the old
  `/{username}/db_post/{id}` URL and will need their URLs updated to
  `/{user_id}/db_post/{id}` once this migration lands.
