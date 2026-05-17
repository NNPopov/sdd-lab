# 0020 · create_post_status — Outside-in test spec

## Goal

Prove that `POST /api/v1/{username}/post` returns `"status": "pending_review"`
in the 201 response body and that the database row carries the same value,
while existing authorization and error behavior remain intact.

## Entry point

- **Method:** `POST`
- **Path:** `/api/v1/alice/post`
- **Body:** `{"title": "Hello world", "text": "My first post.", "media_url": null}`
- **Auth:** `get_current_user` dependency overridden to return the seeded
  `alice` dict (same pattern as existing 0011 tests). No real JWT required in
  the test harness.

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `CreatePostAdapter` — the real adapter, bound to the test Postgres session.
- `CreatePostPort` — satisfied by `CreatePostAdapter`.
- `CreatePostUseCase` — the real use-case.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction
  (the `async_client` / `app` fixture in `tests/conftest.py` does this).

## Mocked

None — the test runs entirely against the test database. Redis and external
HTTP are not touched by this slice. The `get_current_user` dependency is
overridden with `app.dependency_overrides` (not a mock of the adapter or
use-case).

## Fixtures used

- `async_client` (from `tests/conftest.py`): the `httpx.AsyncClient` wired to
  the app with the test DB transaction.
- `seeded_alice: dict` (from `tests/features/posts/0011_create_post/conftest.py`
  or the global conftest): inserts an active `User` row for `alice` and yields
  a dict with at least `{"id": <int>, "username": "alice"}`.

No additional slice-level fixtures are needed; `seeded_alice` is sufficient.

## Test scenarios

### Scenario 1: happy path — post is created with status pending_review

**Setup:**

- DB contains an active `User` row for `alice` (from `seeded_alice` fixture).
- `get_current_user` dependency overridden to return `seeded_alice`.
- No existing `Post` rows.

**Act:**

- `POST /api/v1/alice/post` with body
  `{"title": "Hello world", "text": "My first post.", "media_url": null}`.

**Expect:**

- Status: `201`.
- Response body includes `"status": "pending_review"`.
- Response body includes all pre-existing fields: `"id"` (integer),
  `"title": "Hello world"`, `"text": "My first post."`,
  `"media_url": null`, `"created_by_user_id": <alice's id>`,
  `"created_at"` (present).
- Response body does **not** include `"uuid"` or `"is_deleted"`.
- DB state: a `Post` row exists with `title = "Hello world"` and
  `status = "pending_review"` (verified by direct SQL through the test
  session factory).

**Covers requirement(s):** F1, F2, F3, F4.

---

### Scenario 2: existing guard intact — forbidden when requester is not the path owner

**Setup:**

- DB contains active `User` rows for both `alice` (seeded) and `bob` (seeded).
- `get_current_user` dependency overridden to return `seeded_bob`.

**Act:**

- `POST /api/v1/alice/post` with body
  `{"title": "Intruder title", "text": "Intruder content."}`.

**Expect:**

- Status: `403`.
- Response body:
  `{"error": {"code": "forbidden", "message": "You can only post under your own username"}}`.
- DB state: no `Post` row with `title = "Intruder title"` exists (verified by
  direct SQL through the test session factory).

**Covers requirement(s):** F5, F6.

---

## Out of scope for this test

- Field-level validation errors (422) — covered by endpoint integration test in
  `tests/features/posts/0011_create_post/presentation/test_router.py`.
- User-not-found (404) — covered by the same endpoint integration test.
- Unauthenticated request (401) — covered by the same endpoint integration test.
- Explicit confirmation that the adapter sets `status` via keyword argument vs
  ORM default — covered by adapter unit test
  (`tests/features/posts/0020_create_post_status/data/test_adapter.py`).
- Performance, load, concurrency.
