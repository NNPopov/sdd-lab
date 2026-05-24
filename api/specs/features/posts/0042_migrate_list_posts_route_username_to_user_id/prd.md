# PRD — Migrate `list_posts` Route from `{username}` to `{user_id}` (slice 0042)

**Slice:** `0042_migrate_list_posts_route_username_to_user_id`
**Resource:** posts
**Depends on:** slice 0009 (`list_posts`) must be complete; slice 0041
(`migrate_users_routes_username_to_user_id`) — both migrations are part of the
same `{username}` → `{user_id}` initiative and should land together.

---

## Problem Statement

The `list_posts` endpoint (`GET /{username}/posts`) currently identifies the
post author by their `username` string in the URL path. This creates the same
instability as the users API routes: if a user changes their username, every
existing URL to their post list silently breaks. It also forces the adapter to
JOIN the `User` table on `username` rather than filtering directly on the
foreign key column `Post.created_by_user_id`, which is a less efficient lookup
path and couples the query to a mutable attribute.

Slice 0041 migrates all nine Users API routes from `{username}` to `{user_id}`.
The `list_posts` route is the only Posts API route that uses `{username}` as a
path parameter and is in scope for the same migration; it must be updated to be
consistent with the rest of the API surface.

## Solution

Replace `{username}` with `{user_id}` (the integer autoincrement primary key of
the `User` model) as the route identifier for `GET /{user_id}/posts`. The
adapter drops the `User.username`-based WHERE filter and instead filters
directly on `Post.created_by_user_id == query.user_id`. The JOIN to the `User`
table is retained only to populate the `username` field that appears in each
post item in the response body — the response schema is otherwise unchanged.

The author-detection logic (`_get_view`, `is_author`) is updated to compare
integer IDs (`optional_user.get("id") == user_id`) rather than username strings.
The cache key prefix changes from `{username}_posts:...` to `{user_id}_posts:...`
to match the new route parameter.

The old `/{username}/posts` route is removed with no backwards-compatibility
shim.

## User Stories

1. As an API client, I want to list a user's posts by their integer ID
   (`GET /{user_id}/posts`), so that the URL is stable even if the user later
   changes their username.
2. As an authenticated user viewing my own posts, I want the endpoint to
   recognise me as the author when I call `GET /{user_id}/posts` with my own
   `user_id`, so that I see all my posts (including non-approved ones) rather
   than only the publicly visible ones.
3. As an unauthenticated API client, I want to list the approved posts for a
   user by their integer ID, so that I can display a public profile page without
   knowing or storing the author's username.
4. As an authenticated user who is not the post author, I want to receive only
   approved posts when calling `GET /{user_id}/posts`, so that draft or pending
   posts are not exposed to non-authors.
5. As an API client, I want to receive HTTP 200 with an empty `items` list when
   the user exists but has no posts visible to me, so that the absence of posts
   is distinguishable from the absence of the user.
6. As an API client, I want the response body shape (fields on each post item
   and on the page envelope) to remain identical to the current response, so
   that I only need to update the URL and not my response parser.
7. As an API client, I want `username` to still appear in each post item in the
   response body, so that clients can display the author's handle without making
   an additional lookup.
8. As an API client, I want pagination (`page`, `items_per_page`) to behave
   identically to the current implementation, so that no pagination logic needs
   to change on the client side.
9. As an API client, I want to receive HTTP 422 when I pass a non-integer value
   for `user_id` in the path, so that type errors surface immediately.
10. As an API client, I want cached responses for `/{user_id}/posts` to be keyed
    by `user_id` rather than `username`, so that cache lookups remain correct
    after the route change.
11. As an API client, I want the old `/{username}/posts` URL to return HTTP 404
    (route not found) rather than silently matching another route, so that the
    breaking change is explicit and forces a client update.
12. As a developer, I want the adapter to filter posts by `Post.created_by_user_id`
    directly, so that the query does not depend on the `User.username` column and
    is simpler to read and maintain.

## Implementation Decisions

### Modified module: domain query (`ListPostsQuery`)

`ListPostsQuery` is updated in place:

- `username: str` field → `user_id: int`.
- `requester_username: str | None = None` → `requester_user_id: int | None = None`.

No new command class is introduced — the existing class is renamed in its
fields only.

### Modified module: data adapter (`ListPostsAdapter`)

The `list()` method is updated:

**`is_author` check:** `query.requester_username == query.username` →
`query.requester_user_id == query.user_id`. Both sides are now `int | None` and
`int` respectively; `None == <int>` evaluates to `False` correctly.

**Filter condition:** The WHERE clause `User.username == query.username` is
replaced by `Post.created_by_user_id == query.user_id` in both the count
statement and the rows statement. This eliminates the dependency on the mutable
`username` column for filtering.

**JOIN retained:** The JOIN between `Post` and `User` (on
`Post.created_by_user_id == User.id`) is kept in the rows query in order to
SELECT `User.username` for inclusion in each `PostItem` in the response body.
The count query does not need `User.username`, so the JOIN there can be dropped
(only `Post.created_by_user_id == query.user_id` in the WHERE clause is needed).

### Modified module: presentation router

**Route path:** `/{username}/posts` → `/{user_id}/posts`. The path parameter
type changes from `str` to `int`.

**`_get_view` helper:** The author check switches from
`optional_user.get("username") == username` to
`optional_user.get("id") == user_id`. The `get_optional_user` dependency already
returns a dict with an `"id"` key — no auth layer changes needed.

**Cache decorator:** Two changes:
- `key_prefix` changes from
  `"{username}_posts:{view}:page_{page}:items_per_page:{items_per_page}"` to
  `"{user_id}_posts:{view}:page_{page}:items_per_page:{items_per_page}"`.
- `resource_id_name` changes from `"username"` to `"user_id"`.

**Query construction in endpoint handler:**
- `requester_username = username if view == "author" else None` →
  `requester_user_id = user_id if view == "author" else None`.
- `ListPostsQuery(username=username, ...)` →
  `ListPostsQuery(user_id=user_id, requester_user_id=requester_user_id, ...)`.

### API contract

| Concern | Value |
|---|---|
| Method | `GET` |
| Old path | `/{username}/posts` |
| New path | `/{user_id}/posts` |
| Path param | `user_id: int` |
| Query params | `page: int = 1`, `items_per_page: int = 10` (unchanged) |
| Authentication | Optional — unauthenticated access returns approved posts only |
| Authorization | None required for the public view |

**Response body (HTTP 200) — unchanged shape:**

The `ListPostsResponse` envelope and `PostItemSchema` fields remain identical.
Each post item still includes the `username` field (populated from the User JOIN).

**Error responses:**

| Status | Condition |
|---|---|
| 200 | User exists (or does not exist — both return items list, possibly empty) |
| 422 | Non-integer value provided for `user_id` |

Note: the endpoint does not return 404 when `user_id` is not found — it returns
200 with an empty `items` list. This matches the existing behaviour of
`list_posts` (the use-case does not check for user existence; it simply returns
whatever posts match the filter).

### No database migration

`Post.created_by_user_id` (integer FK to `User.id`) already exists on the `Post`
ORM model. No Alembic migration is needed.

### Cache invalidation

Existing cache entries keyed under `{username}_posts:...` will become stale
orphans after deployment (they will expire naturally per the existing TTL and
will no longer be populated). No explicit cache flush is required. New entries
will be written under `{user_id}_posts:...` from the first request onwards.

### `UserLookupPort` / `UserLookupAdapter` untouched

The `_shared/` lookup infrastructure for posts (used by `create_post`,
`get_post`, `update_post`, `erase_post`, `erase_db_post`) performs username-based
lookups to resolve author identity on write paths. These are out of scope and
must not be modified.

## Testing Decisions

Good tests verify observable behaviour through the HTTP interface or through the
use-case boundary. They do not assert internal SQLAlchemy query structure.

### Use-case unit test

Mock the port. Cases:
- **Author view** — pass `requester_user_id == user_id`; assert the use-case
  passes `is_author`-equivalent context through the query; assert the port
  receives a `ListPostsQuery` with `requester_user_id` set to the same value as
  `user_id`.
- **Public view** — pass `requester_user_id=None`; assert the query carries
  `requester_user_id=None`.
- **Happy path** — mock port to return a `PostPage`; assert use-case returns it
  unchanged.

Prior art: `tests/features/posts/0009_list_posts/` use-case unit test.

### Adapter unit test

Real async session against the test Postgres database.
- **Public view (non-author)** — create a user and two posts (one `approved`,
  one `pending`); call adapter with a different `requester_user_id`; assert only
  the approved post appears.
- **Author view** — call adapter with `requester_user_id == user_id`; assert
  both posts appear.
- **Empty result** — call adapter with a `user_id` that has no posts; assert
  `PostPage.items` is empty and `total_count` is 0.
- **Non-existent user_id** — call adapter with a `user_id` that does not exist
  in the database; assert empty `PostPage` is returned (no exception).

Prior art: `tests/features/posts/0009_list_posts/` adapter unit test.

### Endpoint integration test

`httpx.AsyncClient` against the running app with test Postgres.
- **200 public view** — create a user and an approved post; call
  `GET /{user_id}/posts` unauthenticated; assert HTTP 200 and the post appears
  in `items`.
- **200 author view** — authenticate as the post owner; assert both approved and
  non-approved posts appear.
- **200 non-author authenticated view** — authenticate as a different user;
  assert only approved posts appear.
- **200 empty** — call with a valid `user_id` that has no posts; assert
  `items: []` and `total_count: 0`.
- **422** — call `GET /not-an-integer/posts`; assert HTTP 422.
- **Old route gone** — call `GET /{username}/posts` with a string username;
  assert HTTP 422 or 404 (FastAPI will not match the new int-typed route).

Prior art: `tests/features/posts/0009_list_posts/presentation/`.

### Outside-in test (acceptance gate)

One end-to-end test with no mocks:

1. Create a user via `POST /users/`; capture the returned `id`.
2. Create an approved post for that user.
3. Call `GET /{user_id}/posts` unauthenticated; assert HTTP 200 and the post
   appears in `items` with correct fields including `username`.
4. Authenticate as the post owner; call `GET /{user_id}/posts`; assert that
   author-only posts (e.g. `pending`) are also visible.
5. Call `GET /{username}/posts` with the string username; assert HTTP 422 (the
   old route is gone).

The slice is not done until this test is green.

**Opt-outs:** none — all four test levels apply.

## Out of Scope

- `create_post`, `get_post`, `update_post`, `erase_post`, `erase_db_post` — these
  post routes use other identifiers and are not part of this migration.
- `UserLookupPort` / `UserLookupAdapter` in `posts/_shared/` — used by the
  above out-of-scope routes; must not be touched.
- `list_all_posts` (`GET /posts/`) — lists posts across all users and does not
  use a `{username}` path param; unaffected.
- `list_pending_posts` — no `{username}` param; unaffected.
- Removing `username` from the `PostItem` / `PostItemSchema` response — the
  field is retained so clients can display the author's handle.
- Cache invalidation flush on deploy — stale `{username}_posts:...` keys expire
  naturally via the existing TTL.
- Admin UI (CRUDAdmin) changes.

## Further Notes

- The outside-in test for slice 0009 (`list_posts`) will need its URL updated
  to `/{user_id}/posts` once this migration lands, since the old route no longer
  exists.
- The `PostItem.username` field is populated from the `User` JOIN in the rows
  query. Because all posts in a single `GET /{user_id}/posts` response belong
  to the same user, the `username` value is the same on every item. This
  redundancy is retained for backwards compatibility with response consumers.
- If a `user_id` is provided that does not correspond to any user in the
  database, the endpoint returns HTTP 200 with an empty list rather than 404.
  This is unchanged behaviour: the current implementation also returns an empty
  list for an unknown username. Changing this to a 404 is out of scope.
- This migration is intentionally scoped to `list_posts` only. The
  `UserLookupAdapter` (which performs username-based user resolution for write
  paths) is left untouched because its callers (`create_post`, `get_post`, etc.)
  are not part of this task.
