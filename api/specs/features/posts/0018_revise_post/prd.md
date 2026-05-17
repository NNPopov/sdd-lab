# PRD — Revise Post (slice 0018)

**Parent PRD:** `specs/features/moderation/0012_moderation/prd.md`
**Depends on:**
- slice 0013 (`moderation_db_foundation`) — `Post.status` column and `PostModerationLog` table must exist
- slice 0017 (`moderate_post`) — a post must be movable to `changes_requested` before a revision can be submitted
**Slice:** `0018_revise_post`
**Resource:** posts
**Endpoint introduced:** `PATCH /posts/{post_uuid}/revise`

---

## Problem Statement

After a moderator requests changes on a post (slice 0017), the post's status becomes
`changes_requested` and the author has received a remark explaining what must be fixed.
However, there is currently no API endpoint for the author to act on that feedback.
Authors cannot update the post's content, they cannot signal that they have addressed
the moderator's remarks, and the post cannot re-enter the `pending_review` queue.
The moderation dialogue is therefore one-directional: a moderator can push a post into
`changes_requested`, but the author has no path back.

## Solution

Introduce a `PATCH /posts/{post_uuid}/revise` endpoint that allows the post author to
update the title and/or body of a post that is in `changes_requested` status, optionally
attach a reply message, and automatically reset the post's status to `pending_review`
so that it re-enters the moderation queue. Each revision appends an immutable
`PostModerationLog` row tagged `event_type = author_revision`, preserving the full
editorial dialogue between author and moderator.

## User Stories

1. As an author, I want to update the title of a post that has had changes requested,
   so that I can address the moderator's feedback about the title.
2. As an author, I want to update the body text of a post that has had changes requested,
   so that I can fix the content the moderator flagged.
3. As an author, I want to update both the title and body in a single revision request,
   so that I do not need to make two separate calls to address multiple issues.
4. As an author, I want to leave an optional message when submitting a revision, so that
   I can explain to the moderator what I changed and why.
5. As an author, I want my revised post to automatically return to `pending_review` after
   I submit the revision, so that the moderator sees it in the queue without me needing
   to trigger a separate re-submit action.
6. As an author, I want to receive HTTP 403 when I try to revise a post that is not in
   `changes_requested` status (e.g. it is still `pending_review` or already `approved`),
   so that revisions are only accepted when actionable moderator feedback exists.
7. As an author, I want to receive HTTP 403 when I try to revise a post that belongs to
   another user, so that I cannot overwrite another author's content.
8. As an author, I want to receive HTTP 404 when I try to revise a post UUID that does
   not exist, so that I get immediate, unambiguous feedback on invalid requests.
9. As an authenticated user, I want to receive HTTP 401 when I call the revise endpoint
   without a valid token, so that the endpoint is not publicly accessible.
10. As an author, I want to receive HTTP 422 when I submit a revision with neither a
    title nor a body update, so that empty no-op revisions are rejected at the schema
    boundary before reaching business logic.
11. As an author, I want the response to include the updated post fields and the new
    `pending_review` status, so that I can confirm the revision was applied without
    issuing a separate read request.
12. As a moderator reviewing a re-submitted post, I want to see the `author_revision` log
    entry that was created alongside the revision, so that I have context for what the
    author changed and any message they attached.
13. As the system, I want each author revision to append an immutable `PostModerationLog`
    row tagged `event_type = author_revision` with `action = None` and the optional
    author message, so that the full editorial dialogue is preserved in chronological
    order.
14. As an author, I want the `updated_at` timestamp of the revised post to reflect the
    time of my revision, so that the post record accurately shows when it was last
    modified.
15. As a moderator, I want a post that returns to `pending_review` after an author
    revision to be fully reviewable again — I can approve it or request further changes —
    so that the revision cycle can repeat until the post meets standards.

## Implementation Decisions

### New slice folder: `features/posts/revise_post/`

Standard vertical-slice layout, mirroring `moderate_post/`:

```
features/posts/revise_post/
├── domain/
│   ├── commands.py          — RevisePostCommand
│   ├── entities.py          — PostForRevision, RevisionLogEntry, RevisedPostResult
│   ├── use_case.py          — RevisePostUseCase
│   └── ports/
│       └── revise_post_port.py   — RevisePostPort (Protocol, @runtime_checkable)
├── data/
│   └── adapter.py           — RevisePostAdapter(RevisePostPort)
└── presentation/
    ├── schemas.py            — RevisePostRequest, RevisePostResponse
    └── router.py             — PATCH /posts/{post_uuid}/revise
```

### Domain command — `RevisePostCommand`

Fields:
- `post_uuid: UUID` — from the URL path
- `requester_user_id: int` — the integer PK of the authenticated author; used for the
  ownership check and for writing `PostModerationLog.user_id`
- `title: str | None` — optional new title; `None` means leave unchanged
- `text: str | None` — optional new body; `None` means leave unchanged
- `message: str | None` — optional author reply attached to the revision log entry

### Domain entities

**`PostForRevision`** — lightweight read model returned by the port's lookup method:
- `id: int` — integer PK; used for the UPDATE and log INSERT
- `uuid: UUID`
- `status: str` — checked against `"changes_requested"` before proceeding
- `created_by_user_id: int` — compared against `requester_user_id` for the ownership
  check

**`RevisionLogEntry`** — represents the `PostModerationLog` row created by this
revision:
- `id: int`
- `event_type: str` — always `"author_revision"` for this endpoint
- `action: str | None` — always `None` for author revisions
- `message: str | None` — the author's optional reply message
- `created_at: datetime`

**`RevisedPostResult`** — the use-case return value:
- `post_uuid: UUID`
- `title: str` — the post title after the revision (updated or unchanged)
- `text: str` — the post body after the revision (updated or unchanged)
- `status: str` — always `"pending_review"` after a successful revision
- `updated_at: datetime` — the timestamp set by the adapter
- `log_entry: RevisionLogEntry`

### Port — `RevisePostPort`

`@runtime_checkable` Protocol with two methods:

- `get_post_by_uuid(post_uuid: UUID) → PostForRevision | None` — fetches the post row
  for existence, status, and ownership checks.
- `apply_revision(post_id: int, post_uuid: UUID, title: str | None, text: str | None,
  author_user_id: int, message: str | None) → RevisedPostResult` — atomically updates
  `Post.title` and/or `Post.text` (only non-`None` fields), sets `Post.status` to
  `"pending_review"`, refreshes `Post.updated_at`, and inserts a `PostModerationLog`
  row; returns the combined result entity.

### Use-case — `RevisePostUseCase`

Sequence:
1. Call `port.get_post_by_uuid(command.post_uuid)`.
2. If result is `None` → raise `NotFoundDomainError("Post not found")`.
3. If `result.created_by_user_id != command.requester_user_id` → raise
   `ForbiddenDomainError("You may only revise your own posts")`.
4. If `result.status != "changes_requested"` → raise
   `ForbiddenDomainError("Post is not in changes_requested status")`.
5. Call `port.apply_revision(result.id, result.uuid, command.title, command.text,
   command.requester_user_id, command.message)`.
6. Return the resulting `RevisedPostResult`.

The use-case never raises `HTTPException` or imports anything from `adapters/`,
`core/`, or `presentation/`.

### Adapter — `RevisePostAdapter(RevisePostPort)`

Concrete SQLAlchemy 2.0 async implementation.

`get_post_by_uuid`: executes `SELECT` on `Post` filtered by `uuid`; returns a mapped
`PostForRevision` or `None`. Only fetches the columns needed for business checks (`id`,
`uuid`, `status`, `created_by_user_id`).

`apply_revision`: within the same session:
1. Builds an `UPDATE post SET status = 'pending_review', updated_at = now()` statement;
   conditionally adds `title` and `text` to the SET clause only for non-`None` values.
2. Fetches the updated row to obtain current `title`, `text`, and `updated_at` for the
   response.
3. Inserts a `PostModerationLog` row with `event_type = "author_revision"`, `action = None`,
   and `message = message`.
4. Commits and refreshes the log row.
5. Returns `RevisedPostResult` populated from the updated post and the log row.

The adapter does not wrap operations in `try/except Exception`. Unknown infrastructure
failures propagate to the global handler in `adapters/http/exception_handlers.py`.

### Presentation schema — `RevisePostRequest`

Pydantic model with `model_config = ConfigDict(from_attributes=True)`:
- `title: str | None = None`
- `text: str | None = None`
- `message: str | None = None`

A `@model_validator(mode="after")` enforces that at least one of `title` or `text` is
provided (not both `None`), returning HTTP 422 at the schema boundary before the
use-case is invoked.

### Presentation schema — `RevisePostResponse`

Pydantic model with `model_config = ConfigDict(from_attributes=True)`:
- `post_uuid: UUID`
- `title: str`
- `text: str`
- `status: str`
- `updated_at: datetime`
- `log_entry: RevisionLogEntrySchema` (nested Pydantic model with `id`, `event_type`,
  `action`, `message`, `created_at`)

### Router

`PATCH /api/v1/posts/{post_uuid}/revise`:
- Depends on `get_current_user` (raises 401 if unauthenticated)
- Constructs `RevisePostCommand` from the path param, request body, and resolved
  current-user dict (`current_user["id"]`)
- Calls `await use_case(command)`
- Returns `RevisePostResponse` with HTTP 200

### DI container

A new provider binding in `bootstrap/container.py` wires `RevisePostUseCase` with
`RevisePostAdapter` injected as the port. The adapter receives the async DB session
factory provider.

A new entry in `features/posts/router.py` registers the revise-post router under the
posts prefix.

### API contract

**`PATCH /api/v1/posts/{post_uuid}/revise`**

| Concern | Value |
|---|---|
| Authentication | Bearer JWT required |
| Authorization | Requester must be the post author |
| Path param | `post_uuid: UUID` |

**Request body:**

| Field | Type | Required |
|---|---|---|
| `title` | `str \| null` | at least one of `title`/`text` must be present |
| `text` | `str \| null` | at least one of `title`/`text` must be present |
| `message` | `str \| null` | optional author reply |

**Response (HTTP 200):**

| Field | Type | Notes |
|---|---|---|
| `post_uuid` | `UUID` | |
| `title` | `str` | post title after revision |
| `text` | `str` | post body after revision |
| `status` | `str` | always `"pending_review"` |
| `updated_at` | `datetime` | UTC timestamp of the revision |
| `log_entry.id` | `int` | |
| `log_entry.event_type` | `str` | always `"author_revision"` |
| `log_entry.action` | `str \| null` | always `null` for author revisions |
| `log_entry.message` | `str \| null` | mirrors `message` from request |
| `log_entry.created_at` | `datetime` | UTC timestamp of the revision |

**Error responses:**

| Status | Condition |
|---|---|
| 401 | Missing or invalid Bearer token |
| 403 | Post does not belong to the requester |
| 403 | Post is not in `changes_requested` status |
| 404 | Post UUID not found |
| 422 | Neither `title` nor `text` is provided |

### State machine context

```
revise_post   changes_requested  →  pending_review
```

After a successful revision, the post is back in `pending_review` and can be approved
or have further changes requested by a moderator. `approved` remains a terminal state
that the revise endpoint cannot touch (enforced by the status guard).

### No modifications to existing stable slices

This slice adds entirely new files. The only modifications to existing files are:
- `bootstrap/container.py` gains a `revise_post_use_case` provider binding
- `features/posts/router.py` registers the new revise-post router

## Testing Decisions

Good tests verify observable behaviour through the public interface. They do not assert
which internal methods were called unless the call is itself the observable behaviour.

### Use-case unit tests

Mock the port. Cover each guard in isolation:

- **Post not found** — mock `port.get_post_by_uuid()` to return `None`; assert
  `NotFoundDomainError` is raised; assert `port.apply_revision` is never called.
- **Ownership check** — mock the port to return a post whose `created_by_user_id`
  differs from `command.requester_user_id`; assert `ForbiddenDomainError` is raised.
- **Wrong status — pending_review** — mock the port to return a post with
  `status = "pending_review"`; assert `ForbiddenDomainError` is raised.
- **Wrong status — approved** — mock the port to return a post with `status = "approved"`;
  assert `ForbiddenDomainError` is raised.
- **Happy path — title only** — mock both port methods to succeed; provide `title` but
  `text = None`; assert `port.apply_revision` is called with `title=<value>`,
  `text=None`; assert the returned entity matches the port's return value.
- **Happy path — text only** — same with `title = None` and non-`None` `text`.
- **Happy path — both fields + message** — provide both `title` and `text` and a
  `message`; assert all fields are forwarded to the port.

Prior art: `tests/features/users/0007_delete_user/` use-case unit test,
`tests/features/posts/0017_moderate_post/` use-case unit test.

### Adapter unit tests

Uses a real async session against the test Postgres database.

- **`get_post_by_uuid` — not found** — call with a random UUID; assert `None` is
  returned.
- **`get_post_by_uuid` — found** — insert a post row; call the method; assert the
  returned entity fields match the row.
- **`apply_revision` — title-only update** — insert a `changes_requested` post;
  call `apply_revision(title="New Title", text=None, ...)`; assert `RevisedPostResult`
  has `title = "New Title"`, original `text`, `status = "pending_review"`; fetch the
  post row directly and assert `status = "pending_review"` and `title` changed.
- **`apply_revision` — text-only update** — same, verifying only `text` changed.
- **`apply_revision` — both fields updated** — provide both `title` and `text`; assert
  both are updated in the DB row.
- **`apply_revision` — log row created** — after calling `apply_revision`, fetch the
  `PostModerationLog` row and assert `event_type = "author_revision"`, `action = None`,
  and `message` matches the input.

Prior art: `tests/features/users/0001_create_user/` adapter unit test,
`tests/features/posts/0017_moderate_post/` adapter unit test.

### Endpoint integration tests

`httpx.AsyncClient` against the running app with test Postgres.

- **401** — call without Authorization header; assert HTTP 401.
- **403 — wrong owner** — authenticate as user B; call revise on a post owned by user A
  that is in `changes_requested`; assert HTTP 403.
- **403 — wrong status (pending_review)** — authenticate as the author; call revise on
  a post that is in `pending_review`; assert HTTP 403.
- **403 — wrong status (approved)** — same, post in `approved` state.
- **404** — authenticate as any user; call with a non-existent UUID; assert HTTP 404.
- **422 — no fields** — call with `{}` body (neither `title` nor `text`); assert
  HTTP 422.
- **200 — title update** — create a post, moderate it to `changes_requested`, then call
  revise with a new `title`; assert HTTP 200, `status = "pending_review"` in response,
  `log_entry.event_type = "author_revision"`.
- **200 — with message** — same flow, providing a `message`; assert `log_entry.message`
  matches.

Prior art: `tests/features/posts/0017_moderate_post/` integration test.

### Outside-in test (acceptance gate)

One end-to-end test covering the primary happy path with no mocks:

1. Create a regular user (the post author).
2. Authenticate as the author; create a post — confirm `status = "pending_review"`.
3. Create a moderator user and assign the moderator flag.
4. Authenticate as the moderator; call `POST /posts/{post_uuid}/moderate` with
   `action = "changes_requested"` and a `message` — confirm `status = "changes_requested"`.
5. Authenticate as the author; call `PATCH /posts/{post_uuid}/revise` with an updated
   `title` and an optional reply `message` — assert HTTP 200, `status = "pending_review"`,
   and `log_entry.event_type = "author_revision"`.
6. Authenticate as the moderator; confirm the post is visible in the pending queue (or
   directly verify the post status via a DB assertion or re-read).

The slice is not done until this test is green.

**Opt-outs:** none — all four test levels apply.

## Out of Scope

- Revising a post that is in `pending_review` or `approved` status — revisions are
  only accepted from `changes_requested`.
- Revising a post authored by another user — the author identity is verified against
  the JWT-resolved user.
- Hard-deleting or permanently rejecting a post through the revise endpoint.
- Returning the full `PostModerationLog` history in the response — only the log entry
  created by this revision is returned.
- Paginating or filtering the moderation log in the response.
- Notifications (email or in-app) to the moderator when a revision is submitted.
- Partial update of fields other than `title` and `text` (e.g. `media_url`) — those
  remain unchanged.
- The `pending_review` → `approved` and `pending_review` → `changes_requested`
  transitions — those are slice 0017 (`moderate_post`).
- The `list_pending_posts` endpoint that makes the re-queued post visible to moderators —
  that is slice 0019.

## Further Notes

- The `PostModerationLog` table is append-only. The adapter must never `UPDATE` or
  `DELETE` rows in that table.
- The adapter's UPDATE statement must only include `title`/`text` in the SET clause when
  those fields are non-`None`. A `None` value means "leave unchanged", not "clear the
  field". Both `title` and `text` are non-nullable in the DB schema, so clearing them
  via a `None` write would be incorrect.
- `ForbiddenDomainError` is used for both the ownership check and the wrong-status
  guard, consistent with how `moderate_post` uses `ForbiddenDomainError` for its
  analogous guards. Both translate to HTTP 403 via `adapters/http/exception_handlers.py`.
- Slices 0021 and 0022 will later filter post listings by status. Until those land, the
  revise endpoint's effect (resetting status to `pending_review`) is still fully
  observable by reading the response or querying the DB directly in tests.
- The outside-in test for this slice intentionally exercises the full
  `moderate_post` → `revise_post` round-trip, making it an implicit integration guard
  for the `changes_requested` → `pending_review` transition that slice 0017 leaves
  incomplete.
