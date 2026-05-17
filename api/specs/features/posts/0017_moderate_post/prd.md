# PRD — Moderate Post (slice 0017)

**Parent PRD:** `specs/features/moderation/0012_moderation/prd.md`
**Depends on:**
- slice 0013 (`moderation_db_foundation`) — `Post.status` column and `PostModerationLog` table must exist
- slice 0015 (`assign_moderator`) — moderator users must be assignable through the API
- slice 0016 (`revoke_moderator`) — complete moderator role management before first use in moderation flow
**Slice:** `0017_moderate_post`
**Resource:** posts
**Endpoint introduced:** `POST /posts/{post_uuid}/moderate`

---

## Problem Statement

Posts are created with `status = pending_review` (as designed in the DB foundation), but
there is no API endpoint for a moderator or superuser to act on them. The moderation
workflow is fully blocked: the state machine exists in the database, but the transition
from `pending_review` → `approved` or `pending_review` → `changes_requested` has no
HTTP entry point. Additionally, there is no `get_current_moderator_or_superuser`
authentication dependency yet, so moderator-only routes cannot be guarded by the standard
dependency injection pattern used for superuser-only routes.

Moderators currently have no way to exercise their role through the API. Authors receive
no feedback, and no posts can ever reach the public-facing `approved` state.

## Solution

Introduce a `POST /posts/{post_uuid}/moderate` endpoint accessible to users who have
`is_moderator = True` or `is_superuser = True`. The endpoint accepts an `action`
(`approved` or `changes_requested`) and an optional `message`. The use-case enforces all
business rules — privilege check, existence check, self-review prevention, terminal-state
guard, and message requirement for change requests — before writing the state transition
to `Post.status` and appending a `PostModerationLog` row. The response returns the post
UUID, the new status, and the created log entry.

A new `get_current_moderator_or_superuser` dependency is also introduced in
`features/users/dependencies.py` to gate this endpoint (and reused by slice 0019,
`list_pending_posts`).

## User Stories

1. As a moderator, I want to approve a post by its UUID so that it becomes publicly
   visible to all users.
2. As a moderator, I want to request changes on a post and leave a remark so that the
   author understands exactly what needs to be revised before the post can be approved.
3. As a superuser, I want to approve or request changes on posts so that I can step in
   and perform moderation without needing the moderator flag.
4. As a moderator, I want to be prevented from approving or requesting changes on my
   own posts so that self-approval is impossible.
5. As a moderator, I want to receive HTTP 409 when I try to moderate a post that is
   already in the `approved` terminal state so that I cannot issue duplicate decisions.
6. As a moderator, I want to receive HTTP 404 when I moderate a post UUID that does
   not exist so that I get immediate, unambiguous feedback on invalid requests.
7. As a moderator, I want the `message` field to be optional when I approve a post so
   that I am not forced to write a comment for routine approvals.
8. As a moderator, I want the `message` field to be required when I request changes
   so that the author always receives actionable feedback.
9. As an authenticated user who is neither a moderator nor a superuser, I want to
   receive HTTP 403 when I call the moderate endpoint so that ordinary users cannot
   make moderation decisions.
10. As an unauthenticated client, I want to receive HTTP 401 when I call the moderate
    endpoint without a valid token so that the endpoint is not publicly accessible.
11. As a moderator, I want the response to include the new post status and the log entry
    that was just created so that I can confirm the decision was recorded without issuing
    a separate read request.
12. As a system, I want each moderation decision to append an immutable
    `PostModerationLog` row tagged `event_type = moderator_review` so that the full
    audit trail of decisions is preserved for future context.
13. As an author whose post is approved, I want the post's `status` to change to
    `approved` in the database so that it becomes eligible to appear in public listings.
14. As an author whose post has changes requested, I want the post's `status` to change
    to `changes_requested` in the database so that I can see it is awaiting my revision.
15. As a moderator, I want the `action` field to be validated as one of the two
    recognised values (`approved` or `changes_requested`) so that malformed requests
    are rejected at the schema boundary before reaching business logic.
16. As a moderator, I want the self-review guard to compare the requester's user ID
    against the post's `created_by_user_id` so that the check is reliable regardless
    of username changes or other profile updates.
17. As a platform operator, I want a new `get_current_moderator_or_superuser`
    FastAPI dependency that enforces `is_moderator OR is_superuser` so that this guard
    can be reused across all moderator-gated endpoints without duplicating logic.

## Implementation Decisions

### New `get_current_moderator_or_superuser` dependency

Add to `features/users/dependencies.py`. Wraps `get_current_user` and raises
`ForbiddenException` if the resolved user has neither `is_moderator = True` nor
`is_superuser = True`. Returns the full user dict. Named consistently with the existing
`get_current_superuser`.

This dependency is a FEATURE file modification (the file header is already
`# FEATURE: users — authentication/authorization dependencies.`). It introduces no new
files.

### New slice folder: `features/posts/moderate_post/`

Standard vertical-slice layout:

```
features/posts/moderate_post/
├── domain/
│   ├── commands.py          — ModeratePostCommand
│   ├── entities.py          — PostForModeration, ModerationLogEntry, ModeratedPostResult
│   ├── use_case.py          — ModeratePostUseCase
│   └── ports/
│       └── moderate_post_port.py   — ModeratePostPort (Protocol, @runtime_checkable)
├── data/
│   └── adapter.py           — ModeratePostAdapter(ModeratePostPort)
└── presentation/
    ├── schemas.py            — ModeratePostRequest, ModeratePostResponse
    └── router.py             — POST /posts/{post_uuid}/moderate
```

### Domain command — `ModeratePostCommand`

Fields:
- `post_uuid: UUID` — from the URL path
- `requester_user_id: int` — the integer PK of the acting user; used for the
  self-review check and for writing `PostModerationLog.user_id`
- `requester_is_privileged: bool` — `True` if the requester has `is_moderator` or
  `is_superuser`; populated by the router from the resolved dependency
- `action: str` — `"approved"` or `"changes_requested"`
- `message: str | None` — optional for `approved`, required for `changes_requested`

### Domain entities

**`PostForModeration`** — lightweight read model returned by the port's lookup method:
- `id: int` — integer PK; used for referencing in the log insert
- `uuid: UUID`
- `status: str`
- `created_by_user_id: int` — compared against `requester_user_id` for the self-review
  guard

**`ModerationLogEntry`** — represents the `PostModerationLog` row created by this
decision:
- `id: int`
- `event_type: str` (always `"moderator_review"` for this endpoint)
- `action: str | None`
- `message: str | None`
- `created_at: datetime`

**`ModeratedPostResult`** — the use-case return value:
- `post_uuid: UUID`
- `status: str` — the new status after the decision
- `log_entry: ModerationLogEntry`

### Port — `ModeratePostPort`

`@runtime_checkable` Protocol with two methods:

- `get_post_by_uuid(post_uuid: UUID) → PostForModeration | None` — fetches the post
  row for existence, status, and author-ID checks.
- `apply_decision(post_id: int, post_uuid: UUID, action: str, moderator_user_id: int,
  message: str | None) → ModeratedPostResult` — atomically updates `Post.status` to
  `action` and inserts a `PostModerationLog` row; returns the combined result entity.

### Use-case — `ModeratePostUseCase`

Sequence:
1. If `command.requester_is_privileged` is `False` → raise `ForbiddenDomainError`.
2. Call `port.get_post_by_uuid(command.post_uuid)`.
3. If result is `None` → raise `NotFoundDomainError("Post not found")`.
4. If `result.created_by_user_id == command.requester_user_id` → raise
   `ForbiddenDomainError("Moderators may not review their own posts")`.
5. If `result.status == "approved"` → raise
   `DuplicateValueDomainError("Post is already approved")`.
6. If `command.action == "changes_requested"` and `command.message` is `None` → raise
   `ForbiddenDomainError("A message is required when requesting changes")`.
7. Call `port.apply_decision(result.id, result.uuid, command.action,
   command.requester_user_id, command.message)`.
8. Return the resulting `ModeratedPostResult`.

The use-case never raises `HTTPException` or imports anything from `adapters/`,
`core/`, or `presentation/`.

### Adapter — `ModeratePostAdapter(ModeratePostPort)`

Concrete SQLAlchemy 2.0 async implementation.

`get_post_by_uuid`: executes `SELECT` on `Post` filtered by `uuid`; returns a mapped
`PostForModeration` or `None`. Only fetches columns needed for business checks (`id`,
`uuid`, `status`, `created_by_user_id`).

`apply_decision`: within the same session, executes two operations:
1. `UPDATE post SET status = action, updated_at = now() WHERE id = post_id`
2. `INSERT INTO post_moderation_log (post_id, user_id, event_type, action, message)
   VALUES (...)` — returning the inserted row to populate `ModerationLogEntry`.

Returns a `ModeratedPostResult` populated from the updated post UUID, the new status,
and the inserted log row.

The adapter does not wrap operations in `try/except Exception`. Unknown infrastructure
failures propagate to the global handler in `adapters/http/exception_handlers.py`.

### Presentation schema — `ModeratePostRequest`

Pydantic model with `model_config = ConfigDict(from_attributes=True)`:
- `action: Literal["approved", "changes_requested"]`
- `message: str | None = None`

A `@model_validator(mode="after")` enforces that `message` is not `None` when
`action == "changes_requested"`, returning HTTP 422 at the schema boundary (before the
use-case is invoked). The use-case enforces the same rule as a second-layer defence for
non-HTTP callers.

### Presentation schema — `ModeratePostResponse`

Pydantic model with `model_config = ConfigDict(from_attributes=True)`:
- `post_uuid: UUID`
- `status: str`
- `log_entry: ModerationLogEntrySchema` (nested Pydantic model with `id`, `event_type`,
  `action`, `message`, `created_at`)

### Router

`POST /api/v1/posts/{post_uuid}/moderate`:
- Depends on `get_current_moderator_or_superuser` (raises 401 if unauthenticated, 403
  if authenticated but lacks privilege)
- Constructs `ModeratePostCommand` from the path param, request body, and resolved
  current-user dict
- Calls `await use_case(command)`
- Returns `ModeratePostResponse` with HTTP 200

### DI container

A new provider binding wires `ModeratePostUseCase` with `ModeratePostAdapter` injected
as the port. The adapter requires the async DB session provider.

### API contract

**`POST /api/v1/posts/{post_uuid}/moderate`**

| Concern | Value |
|---|---|
| Authentication | Bearer JWT required |
| Authorization | `is_moderator OR is_superuser` must be `true` |
| Path param | `post_uuid: UUID` |

**Request body:**

| Field | Type | Required |
|---|---|---|
| `action` | `"approved" \| "changes_requested"` | yes |
| `message` | `str \| null` | required when `action = "changes_requested"` |

**Response (HTTP 200):**

| Field | Type | Notes |
|---|---|---|
| `post_uuid` | `UUID` | |
| `status` | `str` | new post status |
| `log_entry.id` | `int` | |
| `log_entry.event_type` | `str` | always `"moderator_review"` |
| `log_entry.action` | `str \| null` | mirrors `action` from request |
| `log_entry.message` | `str \| null` | mirrors `message` from request |
| `log_entry.created_at` | `datetime` | UTC timestamp of the decision |

**Error responses:**

| Status | Condition |
|---|---|
| 401 | Missing or invalid Bearer token |
| 403 | User is not a moderator or superuser |
| 403 | Requester is the post's author (self-review) |
| 403 | `action = changes_requested` and `message` is null (use-case enforcement) |
| 404 | Post UUID not found |
| 409 | Post is already in `approved` terminal state |
| 422 | `action` is not one of the two recognised values |
| 422 | `action = changes_requested` and `message` is null (schema enforcement) |

### State machine context

```
moderate_post (approved)           pending_review  →  approved
moderate_post (changes_requested)  pending_review  →  changes_requested
```

`approved` is a terminal state. A post that is already `approved` cannot be re-reviewed.
A post in `changes_requested` can be re-submitted by the author (slice 0018,
`revise_post`), after which it returns to `pending_review` and becomes reviewable again.

### No modifications to existing slices

This slice adds entirely new files, with one exception: `features/users/dependencies.py`
gains `get_current_moderator_or_superuser`. No existing routers, adapters, or
use-cases are modified.

## Testing Decisions

Good tests verify observable behaviour through the public interface. They do not
assert which internal methods were called unless the call is itself the observable
behaviour.

### Use-case unit tests

Mock the port. Cover each guard in isolation:

- **Privilege check** — pass `requester_is_privileged=False`; assert
  `ForbiddenDomainError` is raised; assert `port.get_post_by_uuid` is never called.
- **Post not found** — mock `port.get_post_by_uuid()` to return `None`; assert
  `NotFoundDomainError` is raised; assert `port.apply_decision` is never called.
- **Self-review** — mock the port to return a post whose `created_by_user_id` equals
  the `requester_user_id`; assert `ForbiddenDomainError` is raised.
- **Already approved** — mock the port to return a post with `status = "approved"`;
  assert `DuplicateValueDomainError` is raised.
- **Message required** — pass `action = "changes_requested"` and `message = None`;
  assert `ForbiddenDomainError` is raised.
- **Happy path — approve** — mock both port methods to succeed; assert `port.apply_decision`
  is called with `action = "approved"` and `message = None`; assert the returned entity
  matches the port's return value.
- **Happy path — changes requested** — same, with `action = "changes_requested"` and a
  non-null `message`.

Prior art: `tests/features/users/0007_delete_user/` use-case unit test.

### Adapter unit tests

Uses a real async session against the test Postgres database.

- **`get_post_by_uuid` — not found** — call with a random UUID; assert `None` is
  returned.
- **`get_post_by_uuid` — found** — insert a post row; call the method; assert the
  returned entity fields match the row.
- **`apply_decision` — approve happy path** — insert a `pending_review` post; call
  `apply_decision("approved", ...)`; assert the returned `ModeratedPostResult` has
  `status = "approved"`; fetch the post row directly and assert `status = "approved"`;
  fetch the `PostModerationLog` row and assert `event_type = "moderator_review"`,
  `action = "approved"`.
- **`apply_decision` — changes_requested happy path** — same, verifying
  `action = "changes_requested"` and that `message` is stored.

Prior art: `tests/features/users/0001_create_user/` adapter unit test.

### Endpoint integration tests

`httpx.AsyncClient` against the running app with test Postgres.

- **401** — call without Authorization header; assert HTTP 401.
- **403 — unprivileged** — authenticate as a regular (non-moderator, non-superuser)
  user; assert HTTP 403.
- **403 — self-review** — create a post under the moderator's own account; call
  moderate on that post as the same moderator; assert HTTP 403.
- **404** — authenticate as a moderator; call with a non-existent UUID; assert HTTP 404.
- **409 — already approved** — moderate a post to `approved`; call moderate again on
  the same post; assert HTTP 409.
- **422 — missing message** — call with `action = "changes_requested"` and no
  `message`; assert HTTP 422.
- **200 — approve** — create a post, call moderate with `action = "approved"`; assert
  HTTP 200, `status = "approved"` in response, `log_entry.event_type = "moderator_review"`.
- **200 — changes_requested** — same, verifying `action` and `message` in log entry.
- **Superuser can moderate** — authenticate as a superuser (not a moderator); assert
  HTTP 200 on a valid moderation request.

Prior art: `tests/features/posts/0011_create_post/` integration test.

### Outside-in test (acceptance gate)

One end-to-end test covering the primary happy path with no mocks:

1. Create a regular user (the post author).
2. Authenticate as the author; create a post — assert response status is
   `pending_review`.
3. Create a moderator user (or use a fixture that assigns the moderator flag).
4. Authenticate as the moderator.
5. Call `POST /posts/{post_uuid}/moderate` with `action = "approved"` — assert HTTP 200
   and `status = "approved"` in the response.
6. Call `GET /users/{author_username}/posts` as an unauthenticated client — assert the
   post appears in the listing (confirming that `approved` status makes it publicly
   visible, even though full visibility filtering is slice 0021's responsibility, the
   basic record presence confirms the status is persisted).

The slice is not done until this test is green.

**Opt-outs:** none — all four test levels apply.

## Out of Scope

- Transitioning an `approved` post to any other state (no "reject" or "un-approve"
  action exists in this design).
- Moderating a post that is in `changes_requested` state — the parent PRD's state
  machine only allows moderation from `pending_review`. A post returns to
  `pending_review` only after the author revises it (slice 0018).
- Returning the full post body (title, text, media_url) in the moderation response —
  the response contains only UUID, status, and the log entry.
- Paginating or filtering the moderation log in the response — a single entry (the one
  just created) is returned.
- Notifications (email or in-app) to the author when a decision is made.
- Bulk moderation (acting on multiple posts in one request).
- `get_current_moderator_or_superuser` dependency gating on `list_pending_posts` —
  that is slice 0019's responsibility; the dependency is introduced here and reused
  there.
- The `changes_requested` → `pending_review` transition — that is slice 0018
  (`revise_post`).

## Further Notes

- The `PostModerationLog` table is append-only. The adapter must never `UPDATE` or
  `DELETE` rows in that table.
- `DuplicateValueDomainError` is the correct domain error class to signal HTTP 409 for
  the "already approved" case, consistent with the existing convention for conflict
  errors (e.g. "user is already a moderator" in slice 0015).
- The `get_current_moderator_or_superuser` dependency mirrors `get_current_superuser`
  in structure. It does **not** replace `get_current_superuser` for other endpoints —
  each endpoint uses whichever guard matches its privilege requirement.
- Slice 0020 (`create_post_status`) will modify `create_post` to explicitly set
  `status = pending_review` on insert. Until 0020 is implemented, the ORM model's
  column default (`default="pending_review"`) already ensures new posts start in the
  correct state, so the moderate_post slice functions correctly even before 0020 lands.
- The `Post.updated_at` column is set to the current UTC time by `apply_decision`
  alongside the status change, making it clear when the moderation event occurred.
