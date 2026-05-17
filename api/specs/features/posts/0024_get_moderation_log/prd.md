# PRD — Get Moderation Log (slice 0024)

## Problem Statement

The `PostModerationLog` table records the full chronological dialogue between
moderators and authors — decisions, remarks, and revision messages — but there
is no API endpoint that exposes this history directly. Authors cannot review
the moderation history for their own posts outside the moderation queue (which
is moderator-only). Moderators have no standalone endpoint to inspect a single
post's dialogue before or after acting on it.

## Prerequisite

Slice 0023 (`expose_post_uuid`) must be completed first. Clients need `post_uuid`
in listing responses to construct the URL for this endpoint.

## Solution

Add `GET /posts/{post_uuid}/moderation-log` — a read-only endpoint that returns
the full chronological moderation log for a given post, accessible to the
post's author, moderators, and superusers.

## User Stories

1. As an author, I want to call `GET /posts/{post_uuid}/moderation-log` and
   receive the full history of moderation decisions and my revision messages,
   so that I can track the editorial dialogue for my post.
2. As a moderator, I want to call `GET /posts/{post_uuid}/moderation-log` for
   any post and receive the full log, so that I have complete context before
   acting on a resubmitted post.
3. As a superuser, I want to call `GET /posts/{post_uuid}/moderation-log` for
   any post and receive the full log, so that I can audit the moderation
   process for any content.
4. As an authenticated user who is neither the post's author, a moderator, nor
   a superuser, I want to receive HTTP 403 when calling the moderation-log
   endpoint, so that the log is protected from unauthorized access.
5. As an unauthenticated user, I want to receive HTTP 401 when calling the
   moderation-log endpoint, so that the endpoint requires authentication.
6. As any authorized caller, I want to receive HTTP 404 when calling the
   moderation-log endpoint for a post that does not exist or has been
   soft-deleted, so that I get clear feedback on invalid requests.
7. As an author whose post has just been created and not yet moderated, I want
   to receive HTTP 200 with an empty `items` array, so that the absence of log
   entries is clearly communicated rather than treated as an error.
8. As any authorized caller, I want each log entry to include the `username`
   and `user_id` of the person who performed the action (moderator or author),
   so that I can display who made each decision without an additional API call.
9. As any authorized caller, I want the log entries returned in chronological
   order (oldest first), so that I can read the editorial dialogue in natural
   sequence.
10. As any authorized caller, I want each log entry to include `event_type`,
    `action`, and `message`, so that I can distinguish moderation decisions
    (`moderator_review`) from author revisions (`author_revision`) and display
    the appropriate detail.
11. As a moderator who is also the author of a post, I want to be able to
    call the moderation-log endpoint for my own post, so that reading the log
    is not blocked by the self-review restriction that applies only to
    moderation decisions.

## Implementation Decisions

### Endpoint

`GET /posts/{post_uuid}/moderation-log`

### Authentication and authorisation

- Authentication: required via `get_current_user`; HTTP 401 if not authenticated.
- Authorization: the use-case checks that the requester satisfies at least one
  condition — `requester_user_id == post.created_by_user_id` OR
  `requester_is_moderator` OR `requester_is_superuser` — and raises
  `ForbiddenDomainError` (→ HTTP 403) if none holds.
- A moderator who is also the post's author is permitted to view the log;
  reading does not create a conflict of interest, unlike approving one's own post.

### Response shape

```json
{
  "items": [
    {
      "id": 1,
      "event_type": "moderator_review",
      "action": "changes_requested",
      "message": "Please fix the title formatting.",
      "created_at": "2026-05-16T10:05:00Z",
      "actor_user_id": 7,
      "actor_username": "alice_mod"
    },
    {
      "id": 2,
      "event_type": "author_revision",
      "action": null,
      "message": "Fixed the title as requested.",
      "created_at": "2026-05-16T11:00:00Z",
      "actor_user_id": 42,
      "actor_username": "john"
    }
  ]
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | Internal ID of the log entry |
| `event_type` | `"moderator_review"` \| `"author_revision"` | yes | Type of event |
| `action` | `"approved"` \| `"changes_requested"` \| `null` | no | Moderator decision; `null` for author revisions |
| `message` | string \| `null` | no | Moderator remark or author revision message |
| `created_at` | ISO 8601 datetime (UTC) | yes | Timestamp of the event |
| `actor_user_id` | integer | yes | ID of the user who performed the action |
| `actor_username` | string | yes | Username of the user who performed the action |

Items are ordered ascending by `created_at` (chronological, oldest first).

### Error responses

| HTTP | When |
|---|---|
| 401 Unauthorized | Request without a token or with an invalid token |
| 403 Forbidden | Authenticated but not author, moderator, or superuser |
| 404 Not Found | Post with this UUID does not exist or `is_deleted = True` |

### Adapter behaviour

- Looks up the post by `uuid` with `is_deleted = False`; raises
  `NotFoundDomainError` if not found.
- Queries `PostModerationLog` filtered by `post_id`, with a JOIN on the `User`
  table to resolve `actor_username`.
- Returns entries ordered by `created_at` ascending.
- Returns empty list (not an error) when no log entries exist.

### Query command fields

`post_uuid`, `requester_user_id`, `requester_is_moderator`, `requester_is_superuser`

### No database migration required

`PostModerationLog` table and all required columns already exist.

## Testing Decisions

### Use-case unit test (mocked port)

- Post not found → `NotFoundDomainError`
- Soft-deleted post → `NotFoundDomainError`
- Requester is not author, not moderator, not superuser → `ForbiddenDomainError`
- Requester is author → log returned
- Requester is moderator (not author) → log returned
- Requester is superuser (not author) → log returned
- Requester is both author and moderator → log returned
- Empty log → `items` is an empty list
- Log entries returned in ascending `created_at` order

### Adapter unit test (real async session, test Postgres)

- Returns correct entries joined with usernames for the given post
- Returns empty list when no log entries exist
- Ignores entries that belong to other posts

### Endpoint integration test (httpx.AsyncClient)

- 401 for unauthenticated request
- 403 for authenticated user who is not author, moderator, or superuser
- 404 for non-existent post UUID
- 404 for soft-deleted post
- 200 with `{ "items": [] }` for a newly created post (no log entries yet)
- 200 with correct entries when called by author, by moderator, by superuser

### Outside-in test (acceptance gate)

Create a post → moderate (`changes_requested`) → revise → call log endpoint as
author and assert two entries are present with correct `event_type`, `action`,
`message`, `actor_username`.

Prior art: `tests/features/posts/0017_moderate_post/` for the moderation
endpoint pattern; `tests/features/posts/0019_list_pending_posts/` for the
log-entry response shape.

## Out of Scope

- Pagination or filtering of the moderation log.
- Exposing the log to unauthenticated users, even for approved posts.
- Filtering entries by `event_type`, `action`, or date range.
- A notification or badge system to alert authors when new log entries appear.
- Full grant history for `moderator_granted_by_user_id` (out of scope per 0012).
