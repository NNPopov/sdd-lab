# 0024 · get_moderation_log — Outside-in test spec

## Goal

Prove that `GET /api/v1/posts/{post_uuid}/moderation-log` returns the full
chronological log with resolved `actor_username` values to an authorized caller,
and returns `403 Forbidden` to an authenticated user who is neither the post's
author, a moderator, nor a superuser.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/posts/{post_uuid}/moderation-log`
- **Body:** none
- **Auth:** Bearer token (injected via `dependency_overrides[get_current_user]` in
  tests, consistent with the pattern in `tests/features/posts/0019_list_pending_posts/`)

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers,
  `DomainError` → HTTP translation).
- `GetModerationLogAdapter` (performs the `PostModerationLog` + `User` JOIN query).
- `GetModerationLogPort` bound to the adapter in `Container`.
- `GetModerationLogUseCase`.
- Test Postgres via `async_sessionmaker` with `join_transaction_mode="create_savepoint"`;
  rolled back at teardown via the outer transaction in the `async_client` fixture.
- DI container's `session_factory` overridden to use the test connection.

## Mocked

None — the test runs entirely against the test database. Redis is not touched
by this endpoint (no `@cache` decorator, per plan.md § 7 and the caching rule
for security-sensitive data in `agent_docs/entry_points/fastapi.md`).
`get_current_user` is replaced with `dependency_overrides` to avoid token
issuance, which is the established pattern across all posts outside-in tests.

## Fixtures used

Defined in `tests/features/posts/0024_get_moderation_log/conftest.py`:

- **`oit_engine`** — per-test `AsyncEngine` that creates schema (via
  `Base.metadata.create_all`) and disposes on teardown. Mirrors
  `tests/features/posts/0019_list_pending_posts/conftest.py::oit_engine`.
- **`async_client`** — `httpx.AsyncClient` wired to the FastAPI app through
  `ASGITransport`. Overrides `container.session_factory` with a savepoint-mode
  `async_sessionmaker` so adapter commits create SAVEPOINTs; rolls back the
  outer transaction at teardown.
- **`seeded_gml_author`** — inserts a `User` row (`username="gmlauthor"`,
  `is_moderator=False`, `is_superuser=False`). Returns a `dict` with `id`,
  `username`, `is_moderator`, `is_superuser`.
- **`seeded_gml_moderator`** — inserts a `User` row (`username="gmlmod"`,
  `is_moderator=True`, `is_superuser=False`). Returns a `dict` with the same
  shape as `seeded_gml_author`.
- **`seeded_gml_plain_user`** — inserts a `User` row (`username="gmlplain"`,
  `is_moderator=False`, `is_superuser=False`). Used only in Scenario 2.
- **`seeded_gml_post_with_log`** — depends on `seeded_gml_author` and
  `seeded_gml_moderator`. Seeds the following DB state:
  - One `Post` row (`created_by_user_id=seeded_gml_author["id"]`,
    `title="Test Post"`, `text="Post body."`, `status="pending_review"`).
  - One `PostModerationLog` row with `event_type="moderator_review"`,
    `action="changes_requested"`, `message="Please fix the intro."`,
    `user_id=seeded_gml_moderator["id"]`, `created_at=now - timedelta(seconds=2)`.
  - Post status set to `"changes_requested"` after the first log row.
  - One `PostModerationLog` row with `event_type="author_revision"`,
    `action=None`, `message="Fixed the intro."`,
    `user_id=seeded_gml_author["id"]`, `created_at=now`.
  - Post status reset to `"pending_review"` after the second log row.
  - Returns a `dict` with `id`, `uuid`, `status`.

## Test scenarios

### Scenario 1: happy path — author reads a log with two chronologically ordered entries

**Setup:**

- DB contains: one `Post` row owned by `gmlauthor`; two `PostModerationLog` rows as
  described in `seeded_gml_post_with_log` (entry 0 older than entry 1).
- `get_current_user` overridden to return `seeded_gml_author` (the post's author,
  `is_moderator=False`, `is_superuser=False`).

**Act:**

- `GET /api/v1/posts/{post_uuid}/moderation-log` using the `uuid` from
  `seeded_gml_post_with_log`.

**Expect:**

- Status: `200`.
- Response body shape: `{"items": [...]}` with `len(items) == 2`.
- `items[0]`:
  - `event_type == "moderator_review"`
  - `action == "changes_requested"`
  - `message == "Please fix the intro."`
  - `actor_username == "gmlmod"` (resolved via JOIN — not stored in the log row)
  - `actor_user_id == seeded_gml_moderator["id"]`
  - `created_at` is a valid ISO 8601 timestamp
- `items[1]`:
  - `event_type == "author_revision"`
  - `action is None`
  - `message == "Fixed the intro."`
  - `actor_username == "gmlauthor"`
  - `actor_user_id == seeded_gml_author["id"]`
- Chronological order: `items[0]["created_at"] < items[1]["created_at"]`.
- DB state: no rows were written; the two `PostModerationLog` rows and the `Post`
  row are unchanged (read-only endpoint).

**Covers requirements:** F1, F6, F11, F12, F13.

---

### Scenario 2: forbidden — plain user receives 403

**Setup:**

- DB contains: the same `Post` from `seeded_gml_post_with_log`.
- `get_current_user` overridden to return `seeded_gml_plain_user`
  (`is_moderator=False`, `is_superuser=False`, `id != post.created_by_user_id`).

**Act:**

- `GET /api/v1/posts/{post_uuid}/moderation-log` using the same `post_uuid`.

**Expect:**

- Status: `403`.
- Response body: `{"message": "Access to moderation log requires being the author, a moderator, or a superuser"}`.
- DB state: no rows written; no log queries were executed (use-case raises
  `ForbiddenDomainError` after the existence check but before `get_log` is called).

**Covers requirements:** F5.

## Out of scope for this test

- 401 for unauthenticated requests (covered by endpoint integration test; the
  outside-in test bypasses token verification via `dependency_overrides`).
- 404 for non-existent or soft-deleted posts (covered by use-case unit test and
  endpoint integration test).
- Moderator-only access and superuser-only access scenarios (covered by
  endpoint integration test; they share the same adapter and use-case path as
  Scenario 1).
- Empty log (`items == []`) for a post with no history (covered by endpoint
  integration test).
- Specific SQLAlchemy failure modes in the adapter (covered by adapter unit test).
- Performance, load, concurrency.
