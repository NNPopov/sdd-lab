# PRD — Migrate `erase_post` Route from `{username}` to `{user_id}` (slice 0057)

**Slice:** `0057_migrate_erase_post_route_username_to_user_id`
**Resource:** posts
**Depends on:** slice 0029 (`erase_post`) must be complete, and **slice 0055**
(`migrate_create_post_route_username_to_user_id`) must land first. 0055 already
converted the shared `check_post_owner` to id-based and **partially pre-migrated
`erase_post`** (its command's `requester_user_id`, its router, and its ownership
call site) so the suite stayed green. This slice completes the **target-side**
migration that 0055 deliberately left untouched. Sibling of slices 0042 / 0054 /
0055 / 0056; same `{username}` → `{user_id}` initiative.

---

## Problem Statement

The `erase_post` endpoint (`DELETE /{username}/post/{id}`) still identifies the
post author by their `username` string in the URL path, even though its
*requester* identity and ownership check were already moved to integer ids in
slice 0055. As with the rest of the migrated API, a username is mutable, so any
stored or shared delete URL can silently break when the user renames, and the
target author is still resolved through the mutable `User.username` column
instead of the stable integer primary key.

`erase_post` also carries the same **latent cache-staleness bug** that
`update_post` (slice 0056) fixed: it invalidates the single-post cache under
`{username}_post_cache` and the list cache under `{username}_posts`, but
`get_post` (slice 0054) now reads `{user_id}_post_cache` and `list_posts` (slice
0042) now caches `{user_id}_posts:*`. So a deletion made via the still-`{username}`
route fails to invalidate the now-`{user_id}`-keyed read/list caches, and clients
can keep seeing the deleted post (and a stale list) until the TTL expires.

The Users API routes, `list_posts` (0042), `get_post` (0054), `create_post`
(0055), and `update_post` (0056) have already migrated. `erase_post` is the next
Posts API route to align; only its target identifier and cache keys remain.

## Solution

Replace `{username}` with `{user_id}` (the integer autoincrement primary key of
the `User` model) as the author identifier in the route, making it
`DELETE /{user_id}/post/{id}`. The use-case resolves the target user by id via
the shared `get_active_user_by_id` (404 "User not found" if absent). The
ownership check, the owner-scoped post lookup, and the soft delete are **already
id-based** (from slice 0055 and earlier) and are unchanged. The cache keys are
repointed from `{username}_…` to `{user_id}_…`, which **realigns**
`erase_post`'s invalidation with the keys that `get_post` (0054) and
`list_posts` (0042) already use — fixing the latent staleness bug as a direct
consequence of the migration.

The old `/{username}/post/{id}` route is removed with no backwards-compatibility
shim.

## User Stories

1. As an authenticated API client, I want to delete a post by the author's
   integer ID and the post ID (`DELETE /{user_id}/post/{id}`), so that the URL is
   stable even if the author later changes their username.
2. As an authenticated user, I want to delete my own post under my `user_id`, so
   that I can remove my content.
3. As an authenticated user, I want to receive HTTP 403 when I try to delete a
   post under a `user_id` that is not mine, so that I cannot delete on behalf of
   another user.
4. As an authenticated API client, I want to receive HTTP 404 when the `user_id`
   does not exist or is soft-deleted, so that an invalid author is reported as
   not found before the post lookup.
5. As an authenticated API client, I want to receive HTTP 404 when the post does
   not exist or is not owned by the given `user_id`, so that an invalid post is
   reported as not found.
6. As an authenticated API client, I want the 404(user)→403(owner)→404(post)
   ordering to match the current behaviour, so that nothing about the error
   semantics changes apart from the identifier type.
7. As an unauthenticated client, I want to continue to receive HTTP 401 when I
   call `DELETE /{user_id}/post/{id}` without credentials, so that deletes stay
   protected exactly as today.
8. As an API client, I want the response body (`{"message": "Post deleted"}`)
   to be unchanged, so that my response parser needs no change.
9. As an API client, I want to receive HTTP 422 when I pass a non-integer value
   for `user_id` in the path, so that type errors surface immediately.
10. As an API client, I want the old `/{username}/post/{id}` URL with a string
    username to no longer match the endpoint (HTTP 422/404), so that the
    breaking change is explicit.
11. As an API client, I want a deletion to immediately invalidate the cached
    single post and the cached post list for that user, so that I never read a
    deleted post or a stale list after a delete.
12. As a developer, I want `erase_post` to resolve the target author by integer
    id, so that the delete path no longer depends on the mutable `username`
    column.

## Implementation Decisions

### Modified module: domain command (`ErasePostCommand`)

Updated in place — no new class:

- `username: str` (the target author) → `user_id: int`.
- `requester_user_id: int` is **unchanged** (already migrated in slice 0055).
- `post_id: int` is unchanged.

### Modified module: use case (`ErasePostUseCase`)

Only the target lookup changes:

1. `user = get_active_user_by_id(command.user_id)`; if `None`, raise
   `NotFoundDomainError("User not found")`. (Was
   `get_active_user_by_username(command.username)`.)
2. `check_post_owner(command.requester_user_id, user.id)` — **unchanged**; the
   ownership check is already id-based and raises a bare `ForbiddenDomainError`
   (from slice 0055).
3. `post = find_post(command.post_id, owner_id=user.id)`; if `None`, raise
   `NotFoundDomainError("Post not found")` — **unchanged**.
4. `soft_delete(command.post_id)` — **unchanged**.

### Modified module: presentation router

- **Route path:** `/{username}/post/{id}` → `/{user_id}/post/{id}`. The author
  path parameter type changes from `str` to `int`; `id` stays `int`.
- **Command construction:** `username=username` → `user_id=user_id`.
  `requester_user_id=current_user["id"]` is unchanged.
- **Cache decorator:** repoint both keys to `user_id`:
  - `key_prefix` `"{username}_post_cache"` → `"{user_id}_post_cache"`.
  - `to_invalidate_extra` `{"{username}_posts": "{username}"}` →
    `{"{user_id}_posts": "{user_id}"}`.
  - `resource_id_name` continues to reference the post `id`.

### Unchanged module: data adapter (`ErasePostAdapter`) and port

No change. `find_post(post_id, owner_id)` already filters
`Post.created_by_user_id == owner_id` (an integer), and `soft_delete(post_id)`
operates on `Post.id`. Neither references `username`.

### Dependency on slice 0055 (shared modules and partial pre-migration)

This slice **uses** but does not modify the shared `posts/_shared` helpers:

- `get_active_user_by_id` already exists on `UserLookupPort`/`UserLookupAdapter`
  (added additively in 0055).
- `check_post_owner` is already id-based (converted in 0055).
- `ErasePostCommand.requester_user_id` and the router's
  `requester_user_id=current_user["id"]` were already introduced in 0055.

`get_active_user_by_username` is still present (retained for the remaining
unmigrated `erase_db_post` slice) and is simply no longer used by `erase_post`
after this change.

### Authentication and authorization

| Concern | Value |
|---|---|
| Method | `DELETE` |
| Old path | `/{username}/post/{id}` |
| New path | `/{user_id}/post/{id}` |
| Path params | `user_id: int`, `id: int` |
| Authentication | Required (`get_current_user`) |
| Authorization | Requester must equal the target user (`requester_user_id == user_id`) |

### API contract

**Response body — unchanged:** `{"message": "Post deleted"}`.

**Error responses:**

| Status | Condition |
|---|---|
| 200 | Post soft-deleted |
| 401 | No / invalid credentials |
| 403 | Authenticated requester is not the target user |
| 404 | `user_id` not found / soft-deleted, or post not found / not owned by `user_id` |
| 422 | Non-integer value provided for `user_id` |

### No database migration

`Post.created_by_user_id` already exists; the post lookup and soft delete operate
on `Post.id` / `Post.created_by_user_id`. No Alembic migration is needed.

## Testing Decisions

Good tests verify observable behaviour through the HTTP interface or the
use-case boundary, not internal SQLAlchemy query structure. The use-case,
endpoint, and outside-in levels apply; the adapter test opts out (the adapter is
unchanged).

### Use-case unit test

Mock the erase port and the user-lookup port. Cases:
- **Happy path (owner)** — lookup returns an author whose `id` equals
  `requester_user_id`, `find_post` returns a record; assert `soft_delete` is
  called.
- **User not found** — lookup returns `None`; assert
  `NotFoundDomainError("User not found")`; assert `find_post` and `soft_delete`
  are never called.
- **Not owner** — lookup returns an author whose `id` differs from
  `requester_user_id`; assert `ForbiddenDomainError`; assert `find_post` and
  `soft_delete` are never called.
- **Post not found / not owned** — lookup returns the owner, `find_post` returns
  `None`; assert `NotFoundDomainError("Post not found")`; assert `soft_delete` is
  never called.

The existing `0029_erase_post` use-case unit test already drives the ownership
check with ids (updated in 0055); this slice updates the **target lookup** in
those tests from username to id.

### Adapter unit test — opt-out

The adapter is **not changed** by this slice, so no new adapter test is added and
the existing `0029_erase_post` adapter test continues to apply unchanged.

### Endpoint integration test

`httpx.AsyncClient` against the running app with the test Postgres.
- **200 owner** — authenticate as the owner; `DELETE /{user_id}/post/{id}`;
  assert 200 and that a subsequent read returns 404 (or the post no longer
  appears).
- **403 non-owner** — authenticate as a different user; assert 403.
- **404 unknown user** — authenticate; target an unknown `user_id`; assert 404.
- **404 unknown post** — authenticate as the owner; target an unknown post id;
  assert 404.
- **401 unauthenticated** — no credentials; assert 401.
- **422 non-integer user_id** — `DELETE /not-an-integer/post/1`; assert 422.
- **Old route gone** — `DELETE /{username}/post/{id}` with a string username;
  assert HTTP 422/404.
- **Cache invalidation** — read the post (populating `{user_id}_post_cache`),
  delete it, read again; assert the post is gone (no stale read).

Prior art: `tests/features/posts/0029_erase_post/presentation/`.

### Outside-in test (acceptance gate)

One end-to-end test with no mocks:

1. Create a user via `POST /users/`; capture the returned `id`. Authenticate.
2. Create a post for that user; capture the post `id`.
3. `GET /{user_id}/post/{id}`; assert HTTP 200 (populates the read cache).
4. `DELETE /{user_id}/post/{id}`; assert HTTP 200.
5. `GET /{user_id}/post/{id}`; assert HTTP 404 (proves the delete invalidated the
   `{user_id}`-keyed read cache).
6. As a different user, `DELETE /{user_id}/post/{id}` on another of their posts;
   assert HTTP 403.
7. `DELETE /{username}/post/{id}` with the string username; assert HTTP 422 (old
   route gone).

The slice is not done until this test is green.

## Out of Scope

- `erase_db_post` — the final route-migration slice (superuser hard delete); not
  changed here.
- The shared `posts/_shared` helpers — already evolved in 0055; used, not
  modified, here. Removing `get_active_user_by_username` remains the final
  cleanup slice's job (it is still needed by `erase_db_post` until that slice
  migrates).
- The ownership mechanism and 403 message — already id-based and message-less
  since 0055; unchanged.
- `get_post` (0054), `create_post` (0055), `update_post` (0056), `list_posts`
  (0042) — already migrated.
- Changing the post `id` to a UUID — frozen; the integer `id` is retained.
- The Flutter client — its calls to the old route will break; accepted and
  handled in the Flutter spec slices.

## Further Notes

- **No 403 message change in this slice.** Unlike `create_post` (0055) and
  `update_post` (0056), `erase_post` already raised a bare `ForbiddenDomainError`
  via the shared `check_post_owner` (since 0055), so there is no message change
  here.
- **Cache realignment is the bug fix.** Repointing `erase_post`'s invalidation
  from `{username}_…` to `{user_id}_…` makes it invalidate the exact keys that
  `get_post` (0054, `{user_id}_post_cache`) and `list_posts` (0042,
  `{user_id}_posts:*`) now read from, eliminating the partial-migration staleness
  window for deletions.
- **Hard dependency on 0055.** This slice builds directly on 0055's partial
  pre-migration of `erase_post`; sequence 0055 → 0057. (It does not depend on
  0056.)
- The integration and outside-in tests for slice 0029 (`erase_post`) reference
  the old `/{username}/post/{id}` URL and will need their URLs updated to
  `/{user_id}/post/{id}` once this migration lands.
- After this slice, `erase_db_post` is the only remaining `{username}` post route
  and the only remaining consumer of `get_active_user_by_username`, which is what
  the final cleanup slice removes.
