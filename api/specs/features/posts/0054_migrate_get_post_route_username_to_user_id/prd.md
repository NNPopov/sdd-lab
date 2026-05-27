# PRD — Migrate `get_post` Route from `{username}` to `{user_id}` (slice 0054)

**Slice:** `0054_migrate_get_post_route_username_to_user_id`
**Resource:** posts
**Depends on:** slice 0026 (`get_post`) must be complete; slice 0042
(`migrate_list_posts_route_username_to_user_id`) sets the precedent for this
migration and should be mirrored. All post-route `{username}` → `{user_id}`
migrations belong to the same initiative and should land together.

---

## Problem Statement

The `get_post` endpoint (`GET /{username}/post/{id}`) currently identifies the
post author by their `username` string in the URL path. This is the same
instability that the rest of the API has already moved away from: if a user
changes their username, every existing URL to one of their posts silently
breaks. It also forces the adapter to resolve the author through the mutable
`User.username` column instead of filtering directly on the foreign key
`Post.created_by_user_id`, coupling the read path to an attribute that can
change.

The Users API routes and the `list_posts` route (slice 0042) have already been
migrated from `{username}` to `{user_id}`. `get_post` is one of the remaining
Posts API routes still keyed on `{username}` and must be brought in line with
the rest of the API surface so the whole public read surface uses stable
integer identifiers.

## Solution

Replace `{username}` with `{user_id}` (the integer autoincrement primary key of
the `User` model) as the author identifier in the route, making it
`GET /{user_id}/post/{id}`. The adapter drops the `User.username`-based WHERE
filter and instead filters directly on `Post.created_by_user_id == user_id`
together with `Post.id == post_id`. The JOIN to the `User` table is retained
only to populate the `username` field that still appears in the response body;
the response schema is otherwise unchanged.

The visibility logic for non-approved posts is updated to compare integer IDs
(`requester_user_id == user_id`) instead of username strings, while the
privileged-viewer bypass (superuser or moderator) is preserved exactly as
today. Consistent with the current `get_post` behaviour, **no explicit user
existence lookup is added** — `get_post` is a public read path, so a missing or
mismatched author still results in a generic "Post not found" (404) rather than
distinguishing "user not found" from "post not found". This avoids leaking
which user IDs exist.

The cache key prefix changes from `{username}_post_cache` to
`{user_id}_post_cache` to match the new route parameter. The old
`/{username}/post/{id}` route is removed with no backwards-compatibility shim.

## User Stories

1. As an API client, I want to fetch a single post by the author's integer ID
   and the post ID (`GET /{user_id}/post/{id}`), so that the URL is stable even
   if the author later changes their username.
2. As an unauthenticated API client, I want to read an approved post by the
   author's integer ID, so that I can display it on a public page without
   knowing or storing the author's username.
3. As an authenticated user viewing my own post, I want the endpoint to
   recognise me as the author when I call `GET /{user_id}/post/{id}` with my own
   `user_id`, so that I can read my own non-approved (e.g. pending) post.
4. As a superuser or moderator, I want to read any post regardless of its
   approval status when I call `GET /{user_id}/post/{id}`, so that my existing
   privileged access is unchanged after the route migration.
5. As an authenticated user who is not the author and is not privileged, I want
   to receive HTTP 404 for a non-approved post, so that draft or pending posts
   are not exposed to non-authors.
6. As an API client, I want to receive HTTP 404 when the post does not exist (or
   does not belong to the given `user_id`), so that an invalid combination of
   author and post is reported as not found.
7. As an API client, I want to receive HTTP 404 (not a distinct "user not
   found") when the `user_id` does not correspond to any user, so that the
   endpoint does not leak which user IDs exist.
8. As an API client, I want the response body shape to remain identical to the
   current response, so that I only need to update the URL and not my response
   parser.
9. As an API client, I want `username` to still appear in the post response
   body, so that I can display the author's handle without making an additional
   lookup.
10. As an API client, I want to receive HTTP 422 when I pass a non-integer value
    for `user_id` in the path, so that type errors surface immediately.
11. As an API client, I want the old `/{username}/post/{id}` URL with a string
    username to no longer match the endpoint (HTTP 422/404), so that the
    breaking change is explicit and forces a client update.
12. As an API client, I want cached responses for a post to be keyed by
    `user_id` rather than `username`, so that cache lookups remain correct after
    the route change.
13. As a developer, I want the adapter to filter posts by
    `Post.created_by_user_id` directly, so that the read query does not depend on
    the mutable `User.username` column.

## Implementation Decisions

### Modified module: domain query (`GetPostQuery`)

The existing query object is updated in place — no new class is introduced:

- `username: str` field → `user_id: int`.
- `requester_username: str | None = None` → `requester_user_id: int | None = None`.
- `post_id: int` is unchanged.
- `requester_is_privileged: bool = False` is unchanged.

### Modified module: use case (`GetPostUseCase`)

The visibility branch for non-approved posts changes only its author
comparison: `requester_username == username` becomes
`requester_user_id == user_id`. Both the `None`-requester case (anonymous) and
the privileged-viewer bypass keep their current semantics. The use-case
continues to raise `NotFoundDomainError("Post not found")` for a missing post
and for a non-approved post viewed by a non-author, non-privileged requester. No
user existence check is added.

### Modified module: data adapter (`GetPostAdapter`)

- **Filter condition:** the WHERE clause `User.username == query.username` is
  replaced by `Post.created_by_user_id == query.user_id`. The post is still
  pinned by `Post.id == query.post_id`.
- **JOIN retained:** the JOIN between `Post` and `User`
  (`Post.created_by_user_id == User.id`) is kept so the query can SELECT
  `User.username` for inclusion in the response body.
- **Existing soft-delete and not-found behaviour is preserved:** the
  `User.is_deleted == False` and `Post.is_deleted == False` filters remain, and
  a non-matching row still yields `None` (which the use-case maps to 404).

### Modified module: presentation router

- **Route path:** `/{username}/post/{id}` → `/{user_id}/post/{id}`. The author
  path parameter type changes from `str` to `int`; `id` remains `int`.
- **Requester resolution:** the requester's identity passed into the query
  switches from the authenticated user's `username` to their `id`
  (`requester_user_id`). The `get_optional_user` dependency already exposes an
  `id` key — no auth-layer change is required. The
  `requester_is_privileged` derivation (superuser or moderator) is unchanged.
- **Cache decorator:** `key_prefix` changes from `"{username}_post_cache"` to
  `"{user_id}_post_cache"`. `resource_id_name` continues to reference the post
  `id`. There is no extra invalidation pattern on this read endpoint.

### Authentication and authorization

| Concern | Value |
|---|---|
| Method | `GET` |
| Old path | `/{username}/post/{id}` |
| New path | `/{user_id}/post/{id}` |
| Path params | `user_id: int`, `id: int` |
| Authentication | Optional (`get_optional_user`) |
| Authorization | None for approved posts; non-approved posts visible only to the author or a privileged viewer (superuser/moderator) |

### API contract

**Response body (HTTP 200) — unchanged shape.** `GetPostResponse` keeps all its
current fields, including `username` (populated from the User JOIN),
`created_by_user_id`, `post_uuid`, and `status`.

**Error responses:**

| Status | Condition |
|---|---|
| 200 | Post exists, belongs to `user_id`, and is visible to the requester |
| 404 | Post not found, not owned by `user_id`, or non-approved and requester is neither author nor privileged; also when `user_id` is unknown |
| 422 | Non-integer value provided for `user_id` (or `id`) |

### No database migration

`Post.created_by_user_id` (integer FK to `User.id`) already exists on the `Post`
ORM model. No Alembic migration is needed.

### Cache invalidation

Existing entries keyed under `{username}_post_cache:...` become stale orphans
after deployment and expire naturally per the existing TTL; no explicit flush is
required. New entries are written under `{user_id}_post_cache:...` from the
first request onwards.

### `posts/_shared` untouched

`get_post` does not use the `posts/_shared` user-lookup port/adapter or the
`check_post_owner` policy (it performs no user-existence lookup and no ownership
check). These shared modules are therefore out of scope for this slice and must
not be modified here.

## Testing Decisions

Good tests verify observable behaviour through the HTTP interface or through the
use-case / adapter boundary. They do not assert internal SQLAlchemy query
structure. All four test levels apply; no opt-outs.

### Use-case unit test

Mock the port. Cases:
- **Approved post** — port returns an approved `PostItem`; assert it is returned
  unchanged regardless of requester.
- **Non-approved, author view** — port returns a non-approved post,
  `requester_user_id == user_id`; assert the post is returned.
- **Non-approved, privileged view** — `requester_user_id != user_id`,
  `requester_is_privileged=True`; assert the post is returned.
- **Non-approved, non-author non-privileged** — assert
  `NotFoundDomainError("Post not found")` is raised.
- **Post missing** — port returns `None`; assert `NotFoundDomainError`.

Prior art: `tests/features/posts/0026_get_post/` use-case unit test.

### Adapter unit test

Real async session against the test Postgres database.
- **Found by id** — create a user and an approved post; call the adapter with
  the matching `user_id` and `post_id`; assert the `PostItem` is returned with
  `username` populated from the JOIN.
- **Wrong author** — call with a different `user_id`; assert `None`.
- **Missing post** — call with a `post_id` that does not exist; assert `None`.
- **Soft-deleted post** — soft-delete the post; assert `None`.
- **Soft-deleted author** — soft-delete the user; assert `None`.

Prior art: `tests/features/posts/0026_get_post/` adapter unit test, and
slice 0042's by-id adapter test.

### Endpoint integration test

`httpx.AsyncClient` against the running app with the test Postgres.
- **200 approved, unauthenticated** — assert the approved post is returned with
  the expected fields including `username`.
- **200 non-approved, author** — authenticate as the author; assert the
  non-approved post is returned.
- **200 non-approved, privileged** — authenticate as a superuser/moderator;
  assert the non-approved post is returned.
- **404 non-approved, non-author** — authenticate as a different
  non-privileged user; assert HTTP 404.
- **404 unknown post** — request a non-existent `post_id`; assert HTTP 404.
- **422 non-integer user_id** — call `GET /not-an-integer/post/1`; assert 422.
- **Old route gone** — call with a string username; assert HTTP 422/404 (the
  new int-typed route does not match a string).

Prior art: `tests/features/posts/0026_get_post/presentation/`.

### Outside-in test (acceptance gate)

One end-to-end test with no mocks:

1. Create a user via `POST /users/`; capture the returned `id`.
2. Create an approved post for that user; capture the post `id`.
3. Call `GET /{user_id}/post/{id}` unauthenticated; assert HTTP 200 and the post
   fields, including `username`.
4. Create a non-approved (e.g. pending) post; authenticate as the author; call
   `GET /{user_id}/post/{id}`; assert HTTP 200 (author can see it).
5. Call `GET /{username}/post/{id}` with the string username; assert HTTP 422
   (the old route is gone).

The slice is not done until this test is green.

## Out of Scope

- `create_post`, `update_post`, `erase_post`, `erase_db_post` — separate
  migration slices in the same initiative; not changed here.
- `posts/_shared` user-lookup port/adapter and the `check_post_owner` policy —
  not used by `get_post`; the broader id-based cleanup of those modules belongs
  to its own cleanup slice.
- `list_posts` (`GET /{user_id}/posts`) — already migrated in slice 0042.
- Adding a distinct "user not found" (404) response — `get_post` intentionally
  keeps its current no-user-lookup behaviour to avoid leaking which user IDs
  exist.
- Changing the post `id` to a UUID — frozen; the integer `id` is retained.
- Removing `username` from the response body — retained for backwards
  compatibility.
- Cache invalidation flush on deploy — stale `{username}_post_cache:...` keys
  expire via the existing TTL.
- The Flutter client (separate working dir) — its calls to the old route will
  break; this is accepted and handled in the Flutter spec slices.

## Further Notes

- The outside-in and integration tests for slice 0026 (`get_post`) reference the
  old `/{username}/post/{id}` URL and will need their URLs updated to
  `/{user_id}/post/{id}` once this migration lands, since the old route no
  longer exists.
- Route migrations can break OTHER slices' tests that share fixtures or routes.
  Before and after implementing this slice, baseline the full test suite and
  prove zero net-new failures (see user memory
  `project_route_migration_downstream_tests`).
- This slice mirrors slice 0042 exactly in mechanism (rename query fields, switch
  the adapter filter to `Post.created_by_user_id`, retain the JOIN for the
  display `username`, repoint the cache key), with one deliberate difference:
  `get_post` adds **no** user-existence lookup, preserving its current public
  read semantics.
