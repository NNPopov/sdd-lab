# PRD — Slice 0021: list_posts_visibility

## Problem Statement

The `GET /users/{username}/posts` endpoint returns every post belonging to a
user regardless of its moderation status. After slices 0013–0020 introduced the
moderation workflow, every new post starts in `pending_review` and only becomes
publicly visible once a moderator approves it. Without visibility filtering on
this endpoint, unapproved posts (`pending_review`, `changes_requested`) are
exposed to any caller — including unauthenticated visitors — in direct
contradiction to the moderation contract established in the parent PRD (0012).

Additionally, the per-item post response does not carry a `status` field. An
author who views their own profile feed has no way to distinguish which posts
are awaiting approval, which have been approved, and which require revision.
The same `PostItem` entity is shared with the `list_all_posts` slice (0010),
so adding `status` there also prepares the ground for slice 0022.

## Solution

Modify the `list_posts` slice to enforce visibility rules:

1. **Requester is the post author** (authenticated and
   `requester_username == target_username`): return all posts regardless of
   status so the author can track their moderation queue.
2. **Any other caller** (different authenticated user, unauthenticated visitor):
   return only posts with `status = approved`.

The router resolves the optional current user via `get_optional_user` and
injects their username into `ListPostsQuery`. The adapter applies the
conditional `WHERE status = 'approved'` clause based on whether the requester
is the author. The cache key is updated to differentiate the author view from
the public view so filtered and unfiltered results never contaminate each other.

`status` is added to `PostItem` (shared entity) and `PostItemSchema` so the
response carries each post's current moderation state.

## User Stories

1. As an unauthenticated visitor, I want `GET /users/{username}/posts` to
   return only approved posts, so that unapproved content is never publicly
   visible.
2. As a regular authenticated user viewing another user's profile, I want to
   see only that user's approved posts, so that pending or change-requested
   posts remain hidden from me.
3. As a post author, I want to see all of my own posts regardless of status
   when I call `GET /users/{username}/posts` with my own username, so that I
   can track which of my submissions are pending, approved, or need revision.
4. As a post author, I want each post item in the response to include the
   `status` field, so that I can display moderation badges alongside my posts
   without a follow-up request.
5. As a non-author authenticated user, I want the `status` field on returned
   post items to always be `approved` (since that is the only status visible to
   me), so that I can render a consistent UI state.
6. As a frontend developer, I want the `status` field to always be present in
   the `PostItemSchema`, so that I can rely on it being in every response
   regardless of the requester role.
7. As a moderator or superuser viewing another user's profile via
   `GET /users/{username}/posts`, I want to see only approved posts (same as
   a regular user), so that the `list_pending_posts` endpoint remains the
   authoritative moderation queue.
8. As a frontend developer, I want the existing fields (`id`, `title`, `text`,
   `media_url`, `created_at`, `created_by_user_id`, `username`) to remain
   unchanged in the response, so that adding `status` is a non-breaking
   addition for consumers that ignore unknown fields.
9. As an author, I want to see a `status = pending_review` post in my own
   profile feed, so that I know it is awaiting moderation review.
10. As an author, I want to see a `status = changes_requested` post in my own
    profile feed, so that I know I need to revise it.
11. As an author, I want to see a `status = approved` post in my own profile
    feed, so that I know it is publicly visible.
12. As a regular authenticated user, I want a `GET /users/{username}/posts`
    response with zero items if the target user has no approved posts yet, so
    that I receive a valid empty paginated response rather than an error.

## Implementation Decisions

### Modules modified

- **`list_posts/domain/commands.py`** — `ListPostsQuery` gains
  `requester_username: str | None = None`. A `None` value means the caller is
  unauthenticated; any value that does not match `username` means a different
  authenticated user; a value that matches `username` means the post author.

- **`list_posts/data/adapter.py`** — the adapter checks whether
  `query.requester_username == query.username`. If true, no status filter is
  applied. Otherwise, `WHERE status = 'approved'` is added to both the count
  and rows queries. The `PostItem` mapping gains `status=post.status`.

- **`list_posts/presentation/router.py`** — the endpoint gains an optional
  dependency on `get_optional_user`. The resolved user's `username` is assigned
  to `ListPostsQuery.requester_username`. The cache key is updated to include a
  `view` segment (`author` when `requester_username == username`, `public`
  otherwise) so the two result sets are cached independently.

- **`list_posts/presentation/schemas.py`** — `PostItemSchema` gains
  `status: str`.

- **`posts/_shared/entities.py`** — `PostItem` gains `status: str`. This
  shared entity is also used by `list_all_posts`; the field is required but
  always present from the ORM row (`Post.status` has a DB default).

### Modules NOT modified

- `list_posts/domain/use_case.py` — remains a thin pass-through; the
  visibility decision lives in the adapter based on the query fields.
- `list_posts/domain/ports/list_posts_port.py` — port signature takes
  `ListPostsQuery`, which already absorbs the new field transparently.
- `bootstrap/container.py` — no DI wiring change required.
- `adapters/db/models/post.py` — `status` column already exists (slice 0013);
  no migration needed.

### Cache key strategy

The current cache key
`{username}_posts:page_{page}:items_per_page:{items_per_page}` is shared
across all callers. After this slice, the author view (unfiltered) and the
public view (filtered to approved) must use separate cache entries. The updated
key adds a `view` segment:

```
{username}_posts:{view}:page_{page}:items_per_page:{items_per_page}
```

where `view` is `author` when the requester is the post owner, `public`
otherwise. Cache invalidation patterns that currently reference
`{username}_posts:*` continue to work because the wildcard covers both
segments.

### API contract change

`GET /users/{username}/posts` response items gain one new field:

```
status: "pending_review" | "approved" | "changes_requested"
```

All existing response fields are unchanged.

### Impact on the 0009 outside-in test

The `seeded_posts` fixture in `tests/features/posts/0009_list_posts/conftest.py`
creates posts without setting `status`, so they default to `pending_review`.
The 0009 outside-in test calls the endpoint without authentication. After this
slice, an unauthenticated caller sees only `approved` posts — the two seeded
posts would be filtered out and the test would assert `total_count == 2` against
an actual 0.

The 0009 outside-in test **must be updated before slice 0021 is implemented**:

- Preferred fix: update the `seeded_posts` fixture to set `status="approved"`
  on both posts, or override `status` when seeding within the outside-in test
  itself, so the public-view scenario remains valid.
- Alternative: change the 0009 test to authenticate as the post author and
  assert the author-view scenario. This is less preferred because it changes
  the original test's intent (public visibility of posts).

This is a behaviour change on an existing tested slice, so the update to the
0009 outside-in test is the first implementation step, before any new code is
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

- When `requester_username == username`: all posts (any status) are returned.
- When `requester_username != username`: only posts with `status = approved`
  are returned.
- When `requester_username is None`: only posts with `status = approved`
  are returned.
- The `status` field is correctly mapped on every returned `PostItem`.

Prior art: `tests/features/posts/0009_list_posts/data/test_adapter.py`.

### Endpoint integration test

`httpx.AsyncClient` against the running app with test Postgres:

- Unauthenticated caller → only approved posts visible (test with one
  approved and one pending post for the same author).
- Authenticated caller who is not the author → only approved posts visible.
- Authenticated caller who is the author → all posts visible regardless of
  status.
- Empty result (zero approved posts) → HTTP 200, empty `items`, `total_count = 0`.
- `status` field present in every response item.

Prior art: `tests/features/posts/0009_list_posts/presentation/test_router.py`.

### Outside-in test

One outside-in acceptance test covering the primary happy paths:

1. Register and authenticate an author (`alice`).
2. Create three posts (all default to `pending_review`).
3. Directly set one post to `status = approved` in the DB through the
   test session factory.
4. Unauthenticated `GET /users/alice/posts` → HTTP 200, exactly one item
   with `status = approved`.
5. Authenticated `GET /users/alice/posts` as Alice → HTTP 200, all three
   items (any status).
6. Authenticated `GET /users/alice/posts` as a different user (`bob`) →
   HTTP 200, exactly one item with `status = approved`.

The slice is not done until this test is green and all pre-existing outside-in
tests (including 0009's updated test) remain green.

## Out of Scope

- Visibility filtering on `GET /posts` (global feed) — that is slice 0022
  (`list_all_posts_visibility`).
- Moderator or superuser bypassing the `approved`-only filter on per-user
  profile feeds — moderators use `GET /posts/pending` for their queue.
- Exposing the full `PostModerationLog` on each item in the profile feed —
  the log is available through the pending-posts queue (slice 0019).
- Adding `post_uuid` to the profile-feed response items — that is already out
  of scope for the original `list_posts` slice.
- Pagination or filtering within the per-user post list beyond what already
  exists (page, items_per_page).
- Cache invalidation when a post's status changes (approve / request changes /
  revise) — existing cache invalidation patterns (`{username}_posts:*`) cover
  both the author and public cache segments; no additional invalidation logic
  is introduced.

## Further Notes

- `Post.status` has a database-level default of `"pending_review"` (set in
  slice 0013). Any test fixture that creates `Post` rows without setting
  `status` will produce `pending_review` posts, which are invisible to
  unauthenticated callers after this slice.
- `PostItem` is shared between `list_posts` and `list_all_posts`. Adding
  `status` to it is additive — `list_all_posts` will carry the field forward
  once its adapter maps it, which is a preparatory step for slice 0022.
- The `get_optional_user` dependency already exists in
  `features/users/dependencies.py` and is already used by other endpoints;
  no new dependency function is required.
- The parent PRD (0012) specifies that the filter is author-vs-non-author only,
  not moderator-privileged. Moderators see only approved posts on profile feeds
  just like regular users. This keeps the semantics simple: the profile feed
  is a public-facing surface, and `list_pending_posts` is the moderator's
  dedicated surface.
- Existing outside-in tests for slices 0009 must remain green throughout. If
  modifying the `seeded_posts` fixture affects other 0009 test cases, those
  cases must be audited and updated before implementation begins.
