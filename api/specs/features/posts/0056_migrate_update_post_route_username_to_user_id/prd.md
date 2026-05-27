# PRD — Migrate `update_post` Route from `{username}` to `{user_id}` (slice 0056)

**Slice:** `0056_migrate_update_post_route_username_to_user_id`
**Resource:** posts
**Depends on:** slice 0028 (`update_post`) must be complete, and **slice 0055**
(`migrate_create_post_route_username_to_user_id`) must land first — this slice
consumes two artifacts introduced by 0055: the additive
`get_active_user_by_id` on the shared `UserLookupPort`/`UserLookupAdapter`, and
the now-id-based shared `check_post_owner` policy. Sibling of slices 0042 /
0054; same `{username}` → `{user_id}` initiative.

---

## Problem Statement

The `update_post` endpoint (`PATCH /{username}/post/{id}`) identifies the post
author by their `username` string in the URL path. As with the rest of the API
that has already migrated, a username is mutable, so any stored or shared URL to
the update path can silently break when the user renames, and author resolution
runs through the mutable `User.username` column instead of the stable integer
primary key.

There is also a **latent cache-staleness bug** introduced by the partial
migration of the surrounding slices. `update_post` currently invalidates the
single-post cache under `{username}_post_cache` and the list cache under
`{username}_posts:*`. But `list_posts` (slice 0042) now caches under
`{user_id}_posts:*`, and `get_post` (slice 0054) now reads under
`{user_id}_post_cache`. As a result, an update made via the still-`{username}`
route fails to invalidate the now-`{user_id}`-keyed read/list caches, so clients
can see stale post content and stale post lists until the TTL expires.

The Users API routes, `list_posts` (0042), `get_post` (0054), and `create_post`
(0055) have already migrated. `update_post` is the next Posts API route to align.

## Solution

Replace `{username}` with `{user_id}` (the integer autoincrement primary key of
the `User` model) as the author identifier in the route, making it
`PATCH /{user_id}/post/{id}`. The use-case adopts the established id-based flow:
resolve the target user by id via the shared `get_active_user_by_id` (404 "User
not found" if absent), enforce ownership by integer-id comparison via the shared
`check_post_owner` (403 if the requester is not that user), fetch the post by id
(404 "Post not found" if absent), then update.

The cache keys are repointed from `{username}_…` to `{user_id}_…`, which
**realigns** `update_post`'s invalidation with the keys that `list_posts` (0042)
and `get_post` (0054) already use — fixing the latent staleness bug as a direct
consequence of the migration.

The old `/{username}/post/{id}` route is removed with no backwards-compatibility
shim.

## User Stories

1. As an authenticated API client, I want to update a post by the author's
   integer ID and the post ID (`PATCH /{user_id}/post/{id}`), so that the URL is
   stable even if the author later changes their username.
2. As an authenticated user, I want to update my own post under my `user_id`, so
   that I can edit my content.
3. As an authenticated user, I want to receive HTTP 403 when I try to update a
   post under a `user_id` that is not mine, so that I cannot edit on behalf of
   another user.
4. As an authenticated API client, I want to receive HTTP 404 when the
   `user_id` does not exist or is soft-deleted, so that an invalid author is
   reported as not found before any ownership check.
5. As an authenticated API client, I want to receive HTTP 404 when the post does
   not exist (or is soft-deleted), so that an invalid post is reported as not
   found.
6. As an authenticated API client, I want the 404(user)→403(owner)→404(post)
   ordering to match the current behaviour, so that nothing about the error
   semantics changes apart from the identifier type.
7. As an unauthenticated client, I want to continue to receive HTTP 401 when I
   call `PATCH /{user_id}/post/{id}` without credentials, so that updates stay
   protected exactly as today.
8. As an API client, I want the request body (partial `title`, `text`,
   `media_url`) and its validation to be unchanged, so that only the URL changes.
9. As an API client, I want the response body to be unchanged, so that my
   response parser needs no change.
10. As an API client, I want to receive HTTP 422 when I pass a non-integer value
    for `user_id` in the path, so that type errors surface immediately.
11. As an API client, I want the old `/{username}/post/{id}` URL with a string
    username to no longer match the endpoint (HTTP 422/404), so that the
    breaking change is explicit.
12. As an API client, I want an update to immediately invalidate the cached
    single post and the cached post list for that user, so that I never read
    stale post content or a stale list after an edit.
13. As a developer, I want `update_post` to resolve the author by integer id and
    check ownership by integer id, so that the write path no longer depends on
    the mutable `username` column.

## Implementation Decisions

### Modified module: domain command (`UpdatePostCommand`)

Updated in place — no new class:

- `target_username: str` → `target_user_id: int`.
- `requester_username: str` → `requester_user_id: int`.
- `post_id: int` and the optional `title` / `text` / `media_url` fields are
  unchanged.

### Modified module: use case (`UpdatePostUseCase`)

The flow keeps its current four-step shape; only identifiers and the ownership
mechanism change:

1. `author = get_active_user_by_id(command.target_user_id)`; if `None`, raise
   `NotFoundDomainError("User not found")`.
2. `check_post_owner(command.requester_user_id, author.id)` — raises
   `ForbiddenDomainError` if the requester is not the author. This **replaces**
   the previous inline username comparison and its message ("You can only update
   your own posts"); ownership now delegates to the shared id-based policy
   introduced in slice 0055 (bare 403, consistent with `create_post` /
   `erase_post`).
3. `post = get_post_by_id(command.post_id)`; if `None`, raise
   `NotFoundDomainError("Post not found")`.
4. `update(command)`.

**Pre-existing gap preserved (do NOT fix here):** `get_post_by_id(post_id)`
fetches the post by id **without** filtering by owner. This is unchanged — the
migration preserves behaviour and does not add an owner filter to the post
fetch.

### Modified module: presentation router

- **Route path:** `/{username}/post/{id}` → `/{user_id}/post/{id}`. The author
  path parameter type changes from `str` to `int`; `id` stays `int`.
- **Command construction:** `target_username=username` →
  `target_user_id=user_id`; `requester_username=current_user["username"]` →
  `requester_user_id=current_user["id"]`.
- **Cache decorator:** repoint both keys to `user_id`:
  - `key_prefix` `"{username}_post_cache"` → `"{user_id}_post_cache"`.
  - `pattern_to_invalidate_extra` `["{username}_posts:*"]` →
    `["{user_id}_posts:*"]`.
  - `resource_id_name` continues to reference the post `id`.

### Unchanged module: data adapter (`UpdatePostAdapter`)

No change. `get_post_by_id(post_id)` already takes a plain integer `post_id`
(and JOINs `User` only to populate the display `username` in the returned
`PostItem`), and `update(command)` reads only `command.post_id` and the content
fields — it never referenced the renamed username command fields.

### Dependency on slice 0055 (shared modules already evolved)

This slice **uses** but does not modify the shared `posts/_shared` helpers:

- `get_active_user_by_id` already exists on `UserLookupPort`/`UserLookupAdapter`
  (added additively in 0055).
- `check_post_owner` is already id-based (`requester_user_id`, `owner_user_id`)
  (converted in 0055).

`get_active_user_by_username` is still present (retained for the remaining
unmigrated slices) and is simply not used by `update_post` after this change.

### Authentication and authorization

| Concern | Value |
|---|---|
| Method | `PATCH` |
| Old path | `/{username}/post/{id}` |
| New path | `/{user_id}/post/{id}` |
| Path params | `user_id: int`, `id: int` |
| Authentication | Required (`get_current_user`) |
| Authorization | Requester must equal the target user (`requester_user_id == target_user_id`) |

### API contract

**Request body — unchanged:** partial update with optional `title`, `text`,
`media_url`. **Response body — unchanged.**

**Error responses:**

| Status | Condition |
|---|---|
| 200 | Post updated |
| 401 | No / invalid credentials |
| 403 | Authenticated requester is not the target user |
| 404 | `user_id` not found / soft-deleted, or post not found / soft-deleted |
| 422 | Non-integer value provided for `user_id` |

### No database migration

`Post.created_by_user_id` already exists; the post fetch and update operate on
`Post.id`. No Alembic migration is needed.

## Testing Decisions

Good tests verify observable behaviour through the HTTP interface or the
use-case boundary, not internal SQLAlchemy query structure. All four test levels
apply, except the adapter test (the adapter is unchanged — see opt-out).

### Use-case unit test

Mock the update port and the user-lookup port. Cases:
- **Happy path (owner)** — lookup returns an author whose `id` equals
  `requester_user_id`, post fetch returns a post; assert the update port is
  called and the use-case completes.
- **User not found** — lookup returns `None`; assert
  `NotFoundDomainError("User not found")`; assert post fetch and update are never
  called.
- **Not owner** — lookup returns an author whose `id` differs from
  `requester_user_id`; assert `ForbiddenDomainError`; assert post fetch and
  update are never called.
- **Post not found** — lookup returns the owner, post fetch returns `None`;
  assert `NotFoundDomainError("Post not found")`; assert update is never called.

Prior art: `tests/features/posts/0028_update_post/` use-case unit test.

### Adapter unit test — opt-out

The adapter is **not changed** by this slice, so no new adapter test is added and
the existing `0028_update_post` adapter test continues to apply unchanged. This
is the documented opt-out condition (the layer adds no new behaviour).

### Endpoint integration test

`httpx.AsyncClient` against the running app with the test Postgres.
- **200 owner** — authenticate as the owner; `PATCH /{user_id}/post/{id}` with a
  partial body; assert 200 and that a subsequent read reflects the change.
- **403 non-owner** — authenticate as a different user; assert 403.
- **404 unknown user** — authenticate; target an unknown `user_id`; assert 404.
- **404 unknown post** — authenticate as the owner; target an unknown post id;
  assert 404.
- **401 unauthenticated** — no credentials; assert 401.
- **422 non-integer user_id** — `PATCH /not-an-integer/post/1`; assert 422.
- **Old route gone** — `PATCH /{username}/post/{id}` with a string username;
  assert HTTP 422/404.
- **Cache invalidation** — read the post (populating `{user_id}_post_cache`),
  update it, read again; assert the updated content is returned (no stale read).

Prior art: `tests/features/posts/0028_update_post/presentation/`.

### Outside-in test (acceptance gate)

One end-to-end test with no mocks:

1. Create a user via `POST /users/`; capture the returned `id`. Authenticate.
2. Create a post for that user; capture the post `id`.
3. `PATCH /{user_id}/post/{id}` with a new `title`; assert HTTP 200.
4. `GET /{user_id}/post/{id}`; assert the returned post shows the updated title
   (proves cache invalidation realignment with `get_post`).
5. As a different user, `PATCH /{user_id}/post/{id}`; assert HTTP 403.
6. `PATCH /{username}/post/{id}` with the string username; assert HTTP 422 (old
   route gone).

The slice is not done until this test is green.

## Out of Scope

- `erase_post`, `erase_db_post` — separate migration slices.
- The shared `posts/_shared` helpers — already evolved in 0055; used, not
  modified, here. Removing `get_active_user_by_username` remains the final
  cleanup slice's job.
- Adding an owner filter to `get_post_by_id` — the pre-existing no-owner-filter
  gap is intentionally preserved (behaviour stays identical).
- `get_post` (0054), `create_post` (0055), `list_posts` (0042) — already
  migrated.
- Changing the post `id` to a UUID — frozen; the integer `id` is retained.
- The Flutter client — its calls to the old route will break; accepted and
  handled in the Flutter spec slices.

## Further Notes

- **403 message change (observable).** The previous `update_post`-specific 403
  message ("You can only update your own posts") is removed; ownership now
  delegates to the shared `check_post_owner`, which raises a bare
  `ForbiddenDomainError()`. This unifies 403 behaviour across the post write
  slices (`create_post`, `update_post`, `erase_post`).
- **Cache realignment is the bug fix.** Repointing `update_post`'s invalidation
  from `{username}_…` to `{user_id}_…` is not merely cosmetic: it makes
  `update_post` invalidate the exact keys that `list_posts` (0042,
  `{user_id}_posts:*`) and `get_post` (0054, `{user_id}_post_cache`) now read
  from, eliminating the partial-migration staleness window.
- **Hard dependency on 0055.** If 0055 has not landed, `get_active_user_by_id`
  and the id-based `check_post_owner` will not exist and this slice cannot be
  implemented as specified. Sequence 0055 → 0056.
- The integration and outside-in tests for slice 0028 (`update_post`) reference
  the old `/{username}/post/{id}` URL and will need their URLs updated to
  `/{user_id}/post/{id}` once this migration lands.
- The `update_user` slice remains the reference for the id-based
  resolve-then-authorize flow.
