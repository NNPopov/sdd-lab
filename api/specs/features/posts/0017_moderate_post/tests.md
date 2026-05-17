# 0017 · moderate_post — Outside-in test spec

## Goal

Prove that a moderator can approve a `pending_review` post through the HTTP endpoint
and that the decision is persisted — `Post.status` updated and a `PostModerationLog`
row inserted — with the correct fields.

## Entry point

- **Method:** `POST`
- **Path:** `/api/v1/posts/{post_uuid}/moderate`
- **Body:** `ModeratePostRequest` — `{"action": "approved"}`
- **Auth:** Bearer token for a user with `is_moderator = True`

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `ModeratePostAdapter` — executes the `SELECT` on `Post` and the `UPDATE` +
  `INSERT INTO post_moderation_log` against the test Postgres.
- `ModeratePostPort` bound to `ModeratePostAdapter` in the DI container.
- `ModeratePostUseCase` — runs all five guards before calling the adapter.
- Test Postgres via the `db_session` fixture (transaction rolled back per test).
- DI container with `session_factory` overridden to use the test transaction.
- `get_current_moderator_or_superuser` dependency (wired to the real `get_current_user`
  which reads from the test DB).

## Mocked

None — the test runs entirely against the test database. No Redis, no external
HTTP calls, no clock patch are needed for this slice.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` with
  `ASGITransport(app=app)` and the session factory overridden to use
  `db_session`.
- `db_session` (from `tests/conftest.py`): per-test async session wrapped in
  a transaction that rolls back at teardown.
- `create_user_fn` (slice `conftest.py`): helper that calls
  `POST /api/v1/users` and returns the created user dict (id, username, uuid).
- `login_fn` (slice `conftest.py`): helper that exchanges a username/password
  pair for a Bearer token string via the auth endpoint.
- `set_moderator_fn` (slice `conftest.py`): helper that sets
  `is_moderator = True` on a user row directly via `db_session` (using a
  SQLAlchemy `UPDATE` statement), then returns the updated user id. This
  bypasses the HTTP layer to avoid a dependency on slice 0015 being available
  in this test.
- `create_post_fn` (slice `conftest.py`): helper that calls the existing
  `POST /api/v1/users/{username}/posts` endpoint with a Bearer token and
  returns the created post dict (uuid, status).

## Test scenarios

### Scenario 1: happy path — moderator approves a pending_review post

**Setup:**

1. Call `create_user_fn(username="author_user", email="author@example.com",
   password="Pa$$w0rd1")` → note `author_id`.
2. Call `login_fn(username="author_user", password="Pa$$w0rd1")` → `author_token`.
3. Call `create_post_fn(username="author_user", token=author_token,
   title="Test post", text="Some content")` → note `post_uuid`; assert the
   response includes `status = "pending_review"`.
4. Call `create_user_fn(username="mod_user", email="mod@example.com",
   password="Pa$$w0rd2")` → note `mod_id`.
5. Call `set_moderator_fn(user_id=mod_id)` via `db_session` to set
   `is_moderator = True`.
6. Call `login_fn(username="mod_user", password="Pa$$w0rd2")` → `mod_token`.

**Act:**

- `await client.post(f"/api/v1/posts/{post_uuid}/moderate",
  json={"action": "approved"},
  headers={"Authorization": f"Bearer {mod_token}"})`

**Expect:**

- Status: `200`.
- Response body:
  - `post_uuid` equals `post_uuid` from setup.
  - `status == "approved"`.
  - `log_entry.event_type == "moderator_review"`.
  - `log_entry.action == "approved"`.
  - `log_entry.message` is `null`.
  - `log_entry.id` is a positive integer.
  - `log_entry.created_at` is a valid ISO-8601 datetime string.
- DB state via `db_session`:
  - Fetch the `Post` row by `uuid = post_uuid`; assert `status == "approved"`.
  - Fetch the `PostModerationLog` row by `post_id`; assert exactly one row
    exists with `event_type == "moderator_review"`, `action == "approved"`,
    `user_id == mod_id`, and `message` is `NULL`.

**Covers requirements:** F1, F11, F14, F15, F17.

---

### Scenario 2: failure path — moderator cannot approve their own post

**Setup:**

1. Call `create_user_fn(username="mod_author", email="modauthor@example.com",
   password="Pa$$w0rd3")` → note `mod_author_id`.
2. Call `set_moderator_fn(user_id=mod_author_id)` via `db_session`.
3. Call `login_fn(username="mod_author", password="Pa$$w0rd3")` → `mod_author_token`.
4. Call `create_post_fn(username="mod_author", token=mod_author_token,
   title="My own post", text="Written by the moderator themselves")` →
   note `own_post_uuid`.

**Act:**

- `await client.post(f"/api/v1/posts/{own_post_uuid}/moderate",
  json={"action": "approved"},
  headers={"Authorization": f"Bearer {mod_author_token}"})`

**Expect:**

- Status: `403`.
- Response body: `{"message": "Moderators may not review their own posts"}`.
- DB state via `db_session`:
  - Fetch the `Post` row by `uuid = own_post_uuid`; assert
    `status == "pending_review"` (unchanged).
  - Fetch `PostModerationLog` by `post_id`; assert **no rows** exist.

**Covers requirements:** F8.

## Out of scope for this test

- Unauthenticated access (401): covered by endpoint integration test.
- Unprivileged user access (403 — not moderator): covered by endpoint
  integration test.
- Post not found (404): covered by endpoint integration test and adapter unit
  test.
- Terminal-state guard (409 — already approved): covered by endpoint integration
  test.
- Schema validation failures (422): covered by endpoint integration test.
- `changes_requested` action (separate success path with message): covered by
  endpoint integration test and adapter unit test.
- Superuser (non-moderator) moderating a post: covered by endpoint integration
  test.
- Individual use-case guard branches beyond self-review: covered by use-case
  unit test.
- Specific SQLAlchemy exception propagation: covered by adapter unit test.
- Performance, concurrency, load.
