# PRD — List Pending Posts (slice 0019)

## Problem Statement

Moderators and superusers have no dedicated way to see which posts need their
attention. Posts in `pending_review` (awaiting a first decision) and posts in
`changes_requested` (awaiting an author revision that has since been
re-submitted) are not surfaced anywhere as an actionable queue. A reviewer must
know a specific post's UUID to act on it. Without a queue endpoint, the
moderation workflow established in slices 0015–0018 cannot be operated in
practice.

## Solution

Add a `GET /posts/pending` endpoint that returns a paginated list of all
non-terminal posts — those with status `pending_review` or
`changes_requested` — accessible only to authenticated users who are
moderators or superusers. Each item in the list includes the full post content,
the author's username, the current status, and the complete chronological
moderation log so that a reviewer has everything needed to make a decision
without a follow-up request.

## User Stories

1. As a moderator, I want to retrieve a paginated list of posts that are
   waiting for my review, so that I can work through the moderation queue
   efficiently.
2. As a superuser, I want to access the same pending-posts queue as moderators,
   so that I can step in and review posts when needed.
3. As a moderator, I want each post in the queue to include the post's current
   status (`pending_review` or `changes_requested`), so that I immediately know
   whether this is a first review or a re-review after revisions.
4. As a moderator, I want each post in the queue to display the author's
   username, so that I can identify who submitted it without a separate lookup.
5. As a moderator, I want each post in the queue to include the full title and
   body text, so that I can read and evaluate the content inline.
6. As a moderator, I want each post in the queue to include an optional
   `media_url`, so that I know whether media is attached.
7. As a moderator, I want each post in the queue to include `created_at` and
   `updated_at` timestamps, so that I can see how long it has been waiting and
   when the author last revised it.
8. As a moderator reviewing a re-submitted post, I want to see the full ordered
   moderation log for that post (all prior moderator remarks and author
   revision messages), so that I have the complete dialogue context before
   making a new decision.
9. As a moderator, I want the moderation log entries to appear in
   chronological order (oldest first), so that I can follow the conversation
   thread naturally.
10. As a moderator, I want each log entry to show the event type
    (`moderator_review` or `author_revision`), the action taken if any, the
    message if any, and the timestamp, so that I can understand what happened
    at each step.
11. As a moderator, I want to paginate the queue using `page` and
    `items_per_page` query parameters, so that I can process large queues
    without loading all posts at once.
12. As a moderator, I want the response to include the total count of pending
    posts, so that I know how large the queue is and how many pages remain.
13. As a non-moderator authenticated user, I want to receive HTTP 403 when I
    try to access `GET /posts/pending`, so that the moderation queue is
    restricted to authorised reviewers.
14. As an unauthenticated user, I want to receive HTTP 401 when I try to access
    `GET /posts/pending`, so that the endpoint is always behind authentication.
15. As a moderator, I want posts that have been approved to be excluded from the
    queue, so that I only see actionable items.
16. As a moderator, I want posts that have been soft-deleted to be excluded from
    the queue, so that deleted content does not clutter the review list.
17. As a moderator, I want posts whose authors have been soft-deleted to be
    excluded from the queue, so that the list only contains active content.
18. As a moderator, I want to receive an empty list with `total_count = 0`
    when there are no pending posts, so that the response structure is always
    consistent and predictable.
19. As a moderator, I want the queue ordered by `created_at` descending (newest
    first), so that the most recently submitted content is easiest to find.

## Implementation Decisions

### New slice folder

A new `list_pending_posts/` slice is created under
`features/posts/`, following the same `domain/`, `data/`, `presentation/`
layout used by `moderate_post` and `revise_post`.

### New domain entities

- **`PendingModerationLogEntry`** — carries `id`, `event_type`, `action`,
  `message`, `created_at` for one log row. Analogous to `ModerationLogEntry`
  in `moderate_post`, but lives in this slice's `domain/entities.py` to avoid
  cross-slice domain imports.
- **`PendingPostItem`** — carries `post_uuid`, `title`, `text`, `media_url`,
  `status`, `created_at`, `updated_at`, `author_username`, and
  `moderation_log: list[PendingModerationLogEntry]`.
- **`PendingPostPage`** — wraps `items: list[PendingPostItem]`, `total_count`,
  `page`, `items_per_page`.

### Query command

`ListPendingPostsQuery` (in `domain/commands.py`) carries:
- `page: int`
- `items_per_page: int`
- `requester_is_privileged: bool` — passed by the router from the auth
  dependency; used by the use case as a defence-in-depth guard.

### Use case

`ListPendingPostsUseCase.__call__` raises `ForbiddenDomainError` if
`requester_is_privileged` is `False`, then delegates entirely to the port.
No other business logic lives here — the privilege check mirrors the pattern
in `ModeratePostUseCase`.

### Port

`ListPendingPostsPort` (runtime-checkable `Protocol`) exposes a single method:

```
list(query: ListPendingPostsQuery) -> PendingPostPage
```

### Adapter — two-query strategy

The adapter avoids N+1 by splitting the work into two database queries inside
one session:

1. **Count + paginated posts query** — joins `Post` and `User`, filters
   `Post.status IN ('pending_review', 'changes_requested')`, excludes soft-
   deleted posts and users, orders by `Post.created_at DESC`, applies
   `OFFSET`/`LIMIT`.
2. **Bulk log query** — fetches all `PostModerationLog` rows whose `post_id`
   is in the set of IDs returned by query 1, ordered by `created_at ASC`.

The adapter then merges the two result sets in Python: for each post, it
attaches the matching log entries to form the `PendingPostItem`. This strategy
keeps the adapter simple and fully testable in isolation.

### Router

`GET /posts/pending` uses the existing
`get_current_moderator_or_superuser` dependency (already in
`features/users/dependencies.py`). Query parameters `page` (default 1) and
`items_per_page` (default 10) are read from the query string. The router
builds a `ListPendingPostsQuery`, calls the use case, and maps the result to
the response schema.

The router is registered in `features/posts/router.py` via
`router.include_router(list_pending_posts_router)`.

### DI container

A new `list_pending_posts_use_case` provider is added to
`bootstrap/container.py`, wiring `ListPendingPostsAdapter` with the shared
`db_session_factory` and injecting it into `ListPendingPostsUseCase`.

### API contract

```
GET /api/v1/posts/pending?page=1&items_per_page=10
Authorization: Bearer <token>   # moderator or superuser

200 OK
{
  "items": [
    {
      "post_uuid": "<uuid>",
      "title": "...",
      "text": "...",
      "media_url": null,
      "status": "pending_review" | "changes_requested",
      "created_at": "<iso8601>",
      "updated_at": "<iso8601>" | null,
      "author_username": "...",
      "moderation_log": [
        {
          "id": 1,
          "event_type": "moderator_review" | "author_revision",
          "action": "approved" | "changes_requested" | null,
          "message": "..." | null,
          "created_at": "<iso8601>"
        }
      ]
    }
  ],
  "total_count": 42,
  "page": 1,
  "items_per_page": 10
}

401 Unauthorized   — no or invalid token
403 Forbidden      — authenticated but not moderator/superuser
```

### No new ORM models or migrations

All required tables (`post`, `user`, `post_moderation_log`) and columns exist
from slice 0013. No schema change is needed.

## Testing Decisions

Good tests verify observable behaviour through the public interface. They do
not assert which internal methods were called or how many SQL statements were
issued.

### Use-case unit test

Mock the port. Assert:
- `ForbiddenDomainError` raised when `requester_is_privileged = False`.
- Happy path: port's `list()` is called with the correct query and its return
  value is passed through unchanged.

Prior art: `tests/features/users/0007_delete_user/` use-case unit test.

### Adapter unit test

Use a real async session against the test Postgres database. Assert:
- Only posts with status `pending_review` or `changes_requested` appear in
  results; `approved` posts are excluded.
- Soft-deleted posts are excluded.
- Posts by soft-deleted users are excluded.
- The returned `moderation_log` entries are ordered chronologically (oldest
  first) and contain the correct fields.
- Pagination (`page`, `items_per_page`, `total_count`) behaves correctly.
- An empty queue returns `total_count = 0` and an empty `items` list.

Prior art: `tests/features/posts/0017_moderate_post/` adapter unit test.

### Endpoint integration test

`httpx.AsyncClient` against the running app with test Postgres. Assert:
- `200 OK` with correct response shape for a moderator token.
- `200 OK` with correct response shape for a superuser token.
- `401 Unauthorized` for an unauthenticated request.
- `403 Forbidden` for a regular (non-moderator) user token.
- Items include `author_username` and `moderation_log`.
- `approved` posts do not appear in the response.

Prior art: `tests/features/posts/0017_moderate_post/presentation/test_router.py`.

### Outside-in test (acceptance gate)

One end-to-end test covering the primary happy path:
1. Create a moderator and a regular author.
2. Create a post (which enters `pending_review`).
3. Moderator calls `POST /posts/{uuid}/moderate` with
   `changes_requested` and a remark — post moves to `changes_requested`,
   log has one entry.
4. Author calls `PATCH /posts/{uuid}/revise` — post returns to
   `pending_review`, log has two entries.
5. Moderator calls `GET /posts/pending` — asserts the post appears with
   `status = pending_review` and `moderation_log` containing both entries in
   chronological order.

The slice is not done until this test is green.

## Out of Scope

- Filtering the pending queue by status (e.g. only `pending_review` or only
  `changes_requested`) — a single combined list is sufficient for now.
- Sorting options other than `created_at DESC`.
- Searching or filtering by author username.
- Pagination on the per-post moderation log returned within each item.
- Any changes to the `approved` terminal state — once approved, a post is
  excluded from this endpoint and cannot be re-queued.
- Caching the pending queue — its content changes frequently and caching
  would require careful invalidation; omitted for simplicity.

## Further Notes

- The two-query strategy (paginated posts + bulk log fetch) keeps the adapter
  simple and avoids the Cartesian product that a single joined query would
  produce when posts have multiple log entries. Python-side merging is
  straightforward because the post set is already page-size bounded.
- The `get_current_moderator_or_superuser` dependency raises `ForbiddenException`
  (HTTP 403) before the use case is reached, so the use-case guard serves
  only as defence-in-depth — the same pattern used in `moderate_post`.
- `updated_at` on the `Post` model is nullable (set only on first update);
  the response schema must allow `null` for posts that have never been
  revised since creation.
