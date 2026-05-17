# PRD — Slice 0022: list_all_posts_visibility

## Problem Statement

The `GET /posts` endpoint returns every non-deleted post regardless of its
moderation status. After slices 0013–0020 introduced the moderation workflow,
every new post starts in `pending_review` and only becomes publicly visible once
a moderator approves it. Without visibility filtering on this endpoint,
unapproved posts (`pending_review`, `changes_requested`) are exposed to any
caller — including unauthenticated visitors — in direct contradiction to the
moderation contract established in the parent PRD (0012).

Privileged users (moderators and superusers) need full visibility into all posts
in the global feed so they can operate without switching to the dedicated
`GET /posts/pending` queue for every status check.

## Solution

Modify the `list_all_posts` slice to enforce visibility rules:

1. **Requester is a moderator or superuser** (`requester_is_privileged = True`):
   return all posts regardless of status so privileged reviewers have complete
   visibility.
2. **Any other caller** (regular authenticated user or unauthenticated visitor):
   return only posts with `status = approved`.

The router resolves the optional current user via `get_optional_user` and sets
`requester_is_privileged = user.is_moderator or user.is_superuser`. The adapter
applies the conditional `WHERE status = 'approved'` clause. The cache key is
updated to differentiate the privileged view from the public view so filtered
and unfiltered results never contaminate each other.

`status` is already present on `PostItem` (added in slice 0021) and is already
mapped in the `ListAllPostsAdapter`. This slice adds only the filtering logic
and the router change.

## User Stories

1. As an unauthenticated visitor, I want `GET /posts` to return only approved
   posts, so that unapproved content is never publicly visible.
2. As a regular authenticated user, I want to see only approved posts in the
   global feed, so that pending or change-requested posts remain hidden from me.
3. As a moderator, I want to see all posts in the global feed regardless of
   status, so that I have full visibility when reviewing content.
4. As a superuser, I want to see all posts in the global feed regardless of
   status, so that I can exercise full administrative oversight.
5. As a frontend developer, I want the `status` field to always be present in
   the response items, so that I can render moderation badges consistently
   (status is already in the response from slice 0021's changes to `PostItem`).
6. As a moderator, I want to see a `status = pending_review` post in the global
   feed, so that I can identify which posts await my review without navigating to
   the dedicated pending queue.
7. As a moderator, I want to see a `status = changes_requested` post in the
   global feed, so that I have full awareness of the content lifecycle.
8. As an unauthenticated visitor, I want to receive an empty paginated response
   (not an error) when no posts have been approved yet, so that the client
   handles the empty state gracefully.
9. As a regular authenticated user, I want the existing response fields
   (`id`, `title`, `text`, `media_url`, `created_at`, `created_by_user_id`,
   `username`, `status`) to remain unchanged, so that adding the filter is a
   non-breaking change.
10. As a frontend developer, I want the cache to be segmented by privilege level,
    so that a privileged user's view never leaks unapproved content into the
    public cache entry.

## Implementation Decisions

### Modules modified

- **`list_all_posts/domain/commands.py`** — `ListAllPostsQuery` gains
  `requester_is_privileged: bool = False`. A `False` value means the caller is
  unauthenticated or a regular user; `True` means the caller is a moderator or
  superuser.

- **`list_all_posts/data/adapter.py`** — the adapter checks
  `query.requester_is_privileged`. If `False`, `WHERE status = 'approved'` is
  added to both the count and rows queries. If `True`, no status filter is
  applied. No other changes to the adapter.

- **`list_all_posts/presentation/router.py`** — the endpoint gains an optional
  dependency on `get_optional_user` (already exists in
  `features/users/dependencies.py`). The resolved user's `is_moderator` and
  `is_superuser` flags are combined to set `requester_is_privileged` on the
  query. The cache key is updated to include a `view` segment (`privileged` or
  `public`) so the two result sets are cached independently.

### Modules NOT modified

- `list_all_posts/domain/use_case.py` — remains a thin pass-through; no
  business logic change.
- `list_all_posts/domain/ports/list_all_posts_port.py` — port signature takes
  `ListAllPostsQuery`, which absorbs the new field transparently.
- `list_all_posts/presentation/schemas.py` — `PostItemSchema` already carries
  `status: str` (added in slice 0021 via the shared `PostItem` entity).
- `posts/_shared/entities.py` — `PostItem` already carries `status: str`.
- `bootstrap/container.py` — no DI wiring change required.
- `adapters/db/models/post.py` — `status` column already exists (slice 0013).

### Cache key strategy

The current cache key `all_posts:page_{page}:items_per_page:{items_per_page}`
is shared across all callers. After this slice, the privileged view (unfiltered)
and the public view (filtered to approved) must use separate cache entries.
The updated key adds a `view` segment:

```
all_posts:{view}:page_{page}:items_per_page:{items_per_page}
```

where `view` is `privileged` when `requester_is_privileged = True`, `public`
otherwise. Cache invalidation patterns that currently reference `all_posts:*`
continue to work because the wildcard covers both segments.

### API contract change

`GET /posts` response items already carry `status` from slice 0021. The only
observable behaviour change for public callers is that posts with
`status != approved` are no longer returned. For privileged callers, the
full post list including non-approved items is returned.

### Impact on the 0010 outside-in test

The `seed_users_and_posts` fixture in
`tests/features/posts/0010_list_all_posts/conftest.py` creates posts without
setting `status`, so they default to `pending_review`. The 0010 outside-in test
calls the endpoint without authentication (`async_client` sends no auth header).
After slice 0022, an unauthenticated caller sees only `approved` posts — the
three seeded posts would be filtered out and the test would assert
`total_count == 3` against an actual 0.

The 0010 outside-in test **must be updated before slice 0022 is implemented**:

- Preferred fix: update the `seed_users_and_posts` fixture to set
  `status="approved"` on all three seeded posts so the public-view scenario
  remains valid.
- Alternative: add a separate privileged-caller scenario to the 0010 test that
  authenticates as a moderator and then verifies all posts are visible.

This is a behaviour change on an existing tested slice, so the update to the
0010 outside-in test is the first implementation step, before any new code is
written.

## Testing Decisions

Good tests verify observable behaviour through the public interface — HTTP
status codes, response bodies, and DB state — not implementation details or
which internal methods were called.

### Use-case unit test

Not required for this slice. The use-case contains no new logic; it remains a
thin pass-through. The filtering decision is the adapter's responsibility based
on the query fields.

### Adapter unit test

Using a real async session against the test Postgres database, verify:

- When `requester_is_privileged = False`: only posts with `status = approved`
  are returned; `total_count` reflects filtered count.
- When `requester_is_privileged = True`: all posts regardless of status are
  returned; `total_count` reflects unfiltered count.
- The `status` field is correctly mapped on every returned `PostItem`.

Prior art: `tests/features/posts/0010_list_all_posts/` (adapter test if
present) and `tests/features/posts/0009_list_posts/data/test_adapter.py`.

### Endpoint integration test

`httpx.AsyncClient` against the running app with test Postgres:

- Unauthenticated caller → only approved posts visible (test with one approved
  and one pending post).
- Authenticated regular user → only approved posts visible.
- Authenticated moderator → all posts visible regardless of status.
- Authenticated superuser → all posts visible regardless of status.
- Empty result (zero approved posts, unauthenticated caller) → HTTP 200, empty
  `items`, `total_count = 0`.
- `status` field present in every response item.

Prior art: `tests/features/posts/0010_list_all_posts/` integration test.

### Outside-in test

One outside-in acceptance test covering the primary happy paths:

1. Register and authenticate an author (`alice`).
2. Create three posts (all default to `pending_review`).
3. Directly set one post to `status = approved` in the DB through the test
   session factory.
4. Register a moderator (`mod`) via the assign-moderator endpoint (requires
   a seeded superuser).
5. Unauthenticated `GET /posts` → HTTP 200, exactly one item with
   `status = approved`.
6. Authenticated `GET /posts` as a regular user (`alice`) → HTTP 200, exactly
   one item with `status = approved`.
7. Authenticated `GET /posts` as `mod` (moderator) → HTTP 200, all three items
   regardless of status.

The slice is not done until this test is green and all pre-existing outside-in
tests (including 0010's updated test) remain green.

## Out of Scope

- Visibility filtering on `GET /users/{username}/posts` — that was slice 0021
  (`list_posts_visibility`).
- Exposing the full `PostModerationLog` on each item in the global feed — the
  log is available through the pending-posts queue (slice 0019).
- Adding `post_uuid` to global feed response items — out of scope for the
  original `list_all_posts` slice.
- Cache invalidation when a post's status changes — existing invalidation
  patterns (`all_posts:*`) cover both the privileged and public cache segments.
- Rate limiting on the global feed endpoint beyond what already exists.
- Pagination or filtering on the global feed beyond what already exists
  (page, items_per_page).

## Further Notes

- `Post.status` has a database-level default of `"pending_review"` (set in
  slice 0013). Any test fixture that creates `Post` rows without setting
  `status` will produce `pending_review` posts, which are invisible to
  non-privileged callers after this slice.
- `PostItem.status` and `PostItemSchema.status` are already in place from slice
  0021. The `ListAllPostsAdapter` already maps `status=post.status`. This slice
  adds only the conditional filter on top of an already complete mapping.
- The `get_optional_user` dependency already exists in
  `features/users/dependencies.py` and is already used by other endpoints; no
  new dependency function is required.
- Moderator privilege (`is_moderator`) and superuser privilege (`is_superuser`)
  both grant full visibility in the global feed. The `get_current_moderator`
  dependency (added in earlier slices) accepts either flag; the same compound
  check applies here, but the dependency itself is not injected — only the
  optional user is resolved and the flags are read from it.
- The parent PRD (0012) specifies that the global feed is unfiltered for
  privileged users. This is the key difference from the per-user profile feed
  (slice 0021), where moderators see only approved posts just like regular users.
- Existing outside-in tests for slice 0010 must remain green throughout. The
  0010 fixture must be updated (set `status="approved"`) before any code change.
