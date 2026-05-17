# PRD — Post UUID Exposure and Moderation Log Endpoint (slices 0023–0024)

## Problem Statement

Two gaps remain in the post moderation system introduced in slices 0013–0022.

First, all existing post-listing and post-creation endpoints return only the
integer database ID, not the UUID. The `PostModerationLog` endpoint (slice 0024)
addresses posts by UUID in its URL. Without UUID in listing responses, clients
have no way to construct that URL from the posts they already have.

Second, the `PostModerationLog` table records the full chronological dialogue
between moderators and authors — decisions, remarks, and revision messages —
but there is no API endpoint that exposes this history directly. Authors cannot
review the moderation history for their own posts outside the moderation queue
(which is moderator-only). Moderators have no standalone endpoint to inspect a
single post's dialogue before or after acting on it.

## Solution

Two sequential slices:

**Slice 0023** adds `post_uuid` to all existing post response schemas so that
clients always have the UUID available for further API calls.

**Slice 0024** adds `GET /posts/{post_uuid}/moderation-log` — a read-only
endpoint that returns the full chronological moderation log for a given post,
accessible to the post's author, moderators, and superusers.

## User Stories

### Expose post UUID (slice 0023)

1. As a frontend developer, I want the `GET /users/{username}/posts` response
   to include `post_uuid` for each post item, so that I can construct
   moderation-log URLs from the author's post list.
2. As a frontend developer, I want the `GET /posts` global feed response to
   include `post_uuid` for each post item, so that I can construct
   moderation-log URLs from the public feed.
3. As a frontend developer, I want the `POST /posts` create-post response to
   include `post_uuid`, so that immediately after creation I can link to the
   post's moderation log without an extra fetch.
4. As a frontend developer, I want the `GET /{username}/post/{id}` single-post
   response to include `post_uuid`, so that the post detail page can offer a
   link to the moderation log.

### Get moderation log (slice 0024)

5. As an author, I want to call `GET /posts/{post_uuid}/moderation-log` and
   receive the full history of moderation decisions and my revision messages,
   so that I can track the editorial dialogue for my post.
6. As a moderator, I want to call `GET /posts/{post_uuid}/moderation-log` for
   any post and receive the full log, so that I have complete context before
   acting on a resubmitted post.
7. As a superuser, I want to call `GET /posts/{post_uuid}/moderation-log` for
   any post and receive the full log, so that I can audit the moderation
   process for any content.
8. As an authenticated user who is neither the post's author, a moderator, nor
   a superuser, I want to receive HTTP 403 when calling the moderation-log
   endpoint, so that the log is protected from unauthorized access.
9. As an unauthenticated user, I want to receive HTTP 401 when calling the
   moderation-log endpoint, so that the endpoint requires authentication.
10. As any authorized caller, I want to receive HTTP 404 when calling the
    moderation-log endpoint for a post that does not exist or has been
    soft-deleted, so that I get clear feedback on invalid requests.
11. As an author whose post has just been created and not yet moderated, I want
    to receive HTTP 200 with an empty `items` array, so that the absence of log
    entries is clearly communicated rather than treated as an error.
12. As any authorized caller, I want each log entry to include the `username`
    and `user_id` of the person who performed the action (moderator or author),
    so that I can display who made each decision without an additional API call.
13. As any authorized caller, I want the log entries returned in chronological
    order (oldest first), so that I can read the editorial dialogue in natural
    sequence.
14. As any authorized caller, I want each log entry to include `event_type`,
    `action`, and `message`, so that I can distinguish moderation decisions
    (`moderator_review`) from author revisions (`author_revision`) and display
    the appropriate detail.
15. As a moderator who is also the author of a post, I want to be able to
    call the moderation-log endpoint for my own post, so that reading the log
    is not blocked by the self-review restriction that applies only to
    moderation decisions.

## Implementation Decisions

### Planned slices (in execution order)

| Slice # | Resource | Name | Endpoint(s) |
|---|---|---|---|
| 0023 | posts | `expose_post_uuid` | modifies `list_posts`, `list_all_posts`, `create_post`, `read_post` |
| 0024 | posts | `get_moderation_log` | `GET /posts/{post_uuid}/moderation-log` |

Slice 0023 is a strict prerequisite for 0024.

### Expose post UUID (slice 0023)

- Four existing response schemas gain a `post_uuid` field (UUID type):
  - `list_posts` (`GET /users/{username}/posts`) — added to each list item
  - `list_all_posts` (`GET /posts`) — added to each list item
  - `create_post` (`POST /posts`) — added to the create response
  - `read_post` (`GET /{username}/post/{id}`) — added to the single-post response
- `list_pending_posts` already returns `post_uuid` and is not modified.
- The `uuid` column already exists on the `Post` ORM model; no database
  migration is required.
- Adapter queries that do not already select `uuid` must be updated to include
  it; the field then passes through to the response schema.
- `patch_post` and `erase_post` return only `{ "message": "..." }` strings and
  are not changed.

### Get moderation log (slice 0024)

- New endpoint: `GET /posts/{post_uuid}/moderation-log`
- Authentication: required via `get_current_user`; HTTP 401 if not authenticated
- Authorization: the use-case checks that the requester satisfies at least one
  condition — `requester_user_id == post.created_by_user_id` OR
  `requester_is_moderator` OR `requester_is_superuser` — and raises
  `ForbiddenDomainError` (→ HTTP 403) if none holds
- The use-case raises `NotFoundDomainError` if the post is not found or
  `is_deleted = True` (→ HTTP 404)
- Response shape:
  ```
  {
    "items": [
      {
        "id": int,
        "event_type": "moderator_review" | "author_revision",
        "action": "approved" | "changes_requested" | null,
        "message": str | null,
        "created_at": datetime,
        "actor_user_id": int,
        "actor_username": str
      }
    ]
  }
  ```
- Items are ordered ascending by `created_at` (chronological)
- No pagination — the log is bounded by the number of moderation cycles
- Adapter: looks up the post by `uuid` with `is_deleted = False`, then queries
  `PostModerationLog` filtered by `post_id`, with a JOIN on the `User` table to
  resolve `actor_username`
- The query command carries:
  `post_uuid`, `requester_user_id`, `requester_is_moderator`, `requester_is_superuser`

## Testing Decisions

Good tests verify observable behaviour through the public interface — status
codes, response shapes, and error codes — not which internal methods were called.

### Slice 0023 — expose_post_uuid

- **Outside-in test**: create a post, then call each of the four affected
  endpoints and assert that `post_uuid` is present in the response and is a
  valid UUID. A single scenario exercises all four endpoints.
- **Adapter unit tests**: for `list_posts` and `list_all_posts`, verify that
  the `uuid` field is present and correctly mapped in the returned rows.
- Prior art: `tests/features/posts/0021_list_posts_visibility/` for the list
  endpoint pattern; `tests/features/posts/0020_create_post_status/` for the
  create response pattern.

### Slice 0024 — get_moderation_log

- **Use-case unit test** with mocked port:
  - Post not found → `NotFoundDomainError`
  - Soft-deleted post → `NotFoundDomainError`
  - Requester is not author, not moderator, not superuser → `ForbiddenDomainError`
  - Requester is author → log returned
  - Requester is moderator (not author) → log returned
  - Requester is superuser (not author) → log returned
  - Requester is both author and moderator → log returned (reading is allowed)
  - Empty log → `items` is an empty list
  - Log entries returned in ascending `created_at` order
- **Adapter unit test** with real async session against test Postgres:
  - Returns correct entries joined with usernames for the given post
  - Returns empty list when no log entries exist
  - Ignores entries that belong to other posts
- **Endpoint integration test** via `httpx.AsyncClient`:
  - 401 for unauthenticated request
  - 403 for authenticated user who is not author, moderator, or superuser
  - 404 for non-existent post UUID
  - 404 for soft-deleted post
  - 200 with `{ "items": [] }` for a newly created post (no log entries yet)
  - 200 with correct entries when called by author, by moderator, by superuser
- **Outside-in test**: create a post → moderate (`changes_requested`) → revise
  → call log endpoint as author and assert two entries are present with
  correct `event_type`, `action`, `message`, `actor_username`.
- Prior art: `tests/features/posts/0017_moderate_post/` for the moderation
  endpoint pattern; `tests/features/posts/0019_list_pending_posts/` for the
  log-entry response shape.

## Out of Scope

- Pagination or filtering of the moderation log (bounded by design; may be
  added if posts develop long review cycles in practice).
- Exposing the moderation log to unauthenticated users, even for fully
  approved posts.
- Adding `post_uuid` to `patch_post` or `erase_post` responses (those
  endpoints return only a confirmation message string).
- Filtering log entries by `event_type`, `action`, or date range.
- A notification or badge system to alert authors when new log entries appear.

## Further Notes

- Slice 0023 is a strict prerequisite for 0024: without `post_uuid` in listing
  responses the frontend cannot construct the moderation-log URL.
- The `uuid` column on `Post` uses UUID v7 (`uuid7()`), which is time-ordered;
  it is safe as a URL identifier and does not leak insert-order information.
- The `PostModerationLog` table is append-only. The endpoint is read-only with
  no filtering or deletion.
- A moderator who is also the post's author is permitted to view the log — 
  reading does not create a conflict of interest, unlike approving one's own
  post. The self-review restriction in `moderate_post` is not replicated here.
- `moderator_granted_by_user_id` stores only the last grantor; full grant
  history is out of scope per the original moderation PRD (0012).
- The PRD for both slices lives in `specs/features/posts/0023_expose_post_uuid/`.
  Slice 0024 has its own spec folder at `specs/features/posts/0024_get_moderation_log/`
  for plan, requirements, validation, and tests files.
