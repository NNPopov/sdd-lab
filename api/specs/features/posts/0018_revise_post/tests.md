# 0018 · revise_post — Outside-in test spec

## Goal

Prove that the full `moderate_post → revise_post` round-trip works end-to-end:
an author can revise a post that a moderator moved to `changes_requested`, the post
returns to `pending_review`, and an immutable `PostModerationLog` row tagged
`author_revision` is created — all through the HTTP stack with the real adapter and
test Postgres.

## Entry point

- **Method:** `PATCH`
- **Path:** `/api/v1/posts/{post_uuid}/revise`
- **Body:** `RevisePostRequest` — `{"title": "...", "message": "..."}`
- **Auth:** Bearer token of the post's author

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `RevisePostAdapter` — the slice's adapter.
- `RevisePostPort` — bound to `RevisePostAdapter` in `Container`.
- `RevisePostUseCase` — the slice's use-case.
- `ModeratePostAdapter` and `ModeratePostUseCase` — used in Scenario 1 setup to
  drive the post into `changes_requested`; exercises the moderate_post → revise_post
  integration without mocking.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the test runs entirely against the test database. No external HTTP APIs,
Redis, or clock dependencies are touched by this slice.

## Fixtures used

- `client` (from `tests/conftest.py`): the `httpx.AsyncClient` against the app.
- `db_session` (from `tests/conftest.py`): the per-test transaction; rolled back
  after each test.
- No slice-specific factory fixtures are needed; all prerequisite rows are created
  through the HTTP endpoints within the test itself.

## Test scenarios

### Scenario 1: happy path — full moderate → revise round-trip

**Setup:**

1. Register a user `author1` via `POST /api/v1/users`.
2. Obtain an auth token for `author1` via `POST /api/v1/auth/token`.
3. Create a post as `author1` via `POST /api/v1/posts` with
   `title="Original Title"` and `text="Original body."`; confirm the response
   `status` is `"pending_review"`. Capture `post_uuid`.
4. Register a user `mod1` via `POST /api/v1/users`.
5. Assign the moderator flag to `mod1` directly on the DB row via `db_session`
   (set `is_moderator=True`); no superuser token is required in the test.
6. Obtain an auth token for `mod1` via `POST /api/v1/auth/token`.
7. Call `POST /api/v1/posts/{post_uuid}/moderate` as `mod1` with body
   `{"action": "changes_requested", "message": "Please improve the title."}`;
   confirm the response `status` is `"changes_requested"`.

**Act:**

Call `PATCH /api/v1/posts/{post_uuid}/revise` as `author1` with body
`{"title": "Revised Title", "message": "Fixed the title as requested."}`.

**Expect:**

- Status: `200`.
- Response body fields:
  - `post_uuid` equals the UUID from setup.
  - `title` is `"Revised Title"`.
  - `text` is `"Original body."` (unchanged — `text` was not supplied in the request).
  - `status` is `"pending_review"`.
  - `updated_at` is a valid UTC datetime.
  - `log_entry.event_type` is `"author_revision"`.
  - `log_entry.action` is `null`.
  - `log_entry.message` is `"Fixed the title as requested."`.
  - `log_entry.id` is a positive integer.
  - `log_entry.created_at` is a valid UTC datetime.
- DB state (asserted via `db_session`):
  - The `post` row has `status = "pending_review"` and `title = "Revised Title"`.
  - The `text` column of the post row is still `"Original body."`.
  - A `post_moderation_log` row exists for this post with `event_type = "author_revision"`,
    `action = NULL`, and `message = "Fixed the title as requested."`.
  - Exactly two `post_moderation_log` rows exist for this post (one from the
    moderate step in setup, one from the revise step).

**Covers requirement(s):** F1, F7, F8, F9, F10, F11, F12, F13, F14, F15.

---

### Scenario 2: status guard — author cannot revise a post not in `changes_requested`

**Setup:**

1. Register a user `author2` via `POST /api/v1/users`.
2. Obtain an auth token for `author2` via `POST /api/v1/auth/token`.
3. Create a post as `author2` via `POST /api/v1/posts` with
   `title="Fresh Post"` and `text="Not yet moderated."`; the post starts in
   `"pending_review"`. Capture `post_uuid`. Do **not** call the moderate endpoint —
   the post remains in `pending_review`.

**Act:**

Call `PATCH /api/v1/posts/{post_uuid}/revise` as `author2` with body
`{"title": "Attempted revision"}`.

**Expect:**

- Status: `403`.
- Response body: `{"message": "Post is not in changes_requested status"}`.
- DB state (asserted via `db_session`):
  - The `post` row still has `status = "pending_review"` and
    `title = "Fresh Post"` — unchanged.
  - No `post_moderation_log` row exists for this post.

**Covers requirement(s):** F6.

## Out of scope for this test

- Field-level schema validation (HTTP 422 for missing `title` and `text`) — covered by
  the endpoint integration test.
- Unauthenticated access (HTTP 401) — covered by the endpoint integration test.
- Ownership guard (HTTP 403 for a different user) — covered by the endpoint integration
  test and the use-case unit test.
- Specific adapter exception paths (e.g. DB unreachable) — covered by the adapter unit
  test.
- Use-case branches beyond the two scenarios above (post not found, approved status) —
  covered by the use-case unit test.
- Performance, load, or concurrency.
