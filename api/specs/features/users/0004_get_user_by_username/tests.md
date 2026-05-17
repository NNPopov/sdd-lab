# 0004 · get_user_by_username — Outside-in test spec

## Goal

Prove that `GET /api/v1/user/{username}` returns the correct user payload for
an existing active user and returns HTTP 404 for a username that does not exist.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/user/{username}`
- **Body:** none
- **Auth:** none (public endpoint)

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `GetUserByUsernameAdapter` — executes the real SQLAlchemy `SELECT` against
  the test Postgres.
- `GetUserByUsernamePort` — bound to the adapter in `Container`.
- `GetUserByUsernameUseCase` — raises `NotFoundDomainError` on `None`.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the test runs entirely against the test database.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` pointed at the app
  with the test transaction wired in.
- `db_session`: the per-test transaction; rolls back at teardown so no rows
  persist between tests.
- `seeded_user` (slice `conftest.py`): inserts one active user row directly
  into `db_session` and yields the row's data. Concrete values:
  - `name = "Alice Tester"`
  - `username = "alicetester"`
  - `email = "alice@example.com"`
  - `hashed_password = "<bcrypt hash of 'Pa$$w0rd'>"`
  - `profile_image_url = "https://www.profileimageurl.com"`
  - `tier_id = None`
  - `is_deleted = False`

## Test scenarios

### Scenario 1: happy path — existing active user

**Setup:**

- DB contains the `seeded_user` row (`username = "alicetester"`,
  `is_deleted = False`).
- No mocks required.

**Act:**

- `GET /api/v1/user/alicetester`

**Expect:**

- Status: `200`.
- Response body contains exactly the six fields with values matching
  the seeded row:
  - `username == "alicetester"`
  - `name == "Alice Tester"`
  - `email == "alice@example.com"`
  - `profile_image_url == "https://www.profileimageurl.com"`
  - `tier_id` is `null`
  - `id` is a positive integer

**DB state:** no write occurred; DB state is unchanged from setup (read-only
operation).

**Covers requirement(s):** F1, F2, F8, F9, F10.

---

### Scenario 2: failure path — username does not exist

**Setup:**

- DB contains no user with `username = "ghost"` (empty DB at test start is
  sufficient; no seed required).
- No mocks required.

**Act:**

- `GET /api/v1/user/ghost`

**Expect:**

- Status: `404`.
- Response body: `{"message": "User not found"}`.

**DB state:** no write occurred; DB state is unchanged (read-only operation).

**Covers requirement(s):** F3, F4, F5, F6.

---

## Out of scope for this test

- Soft-deleted user returning 404 (covered by endpoint integration test,
  scenario S3 in validation.md).
- Infrastructure failures returning 500 (covered by S4 in validation.md and
  N2 in code review checklist).
- Field-level Pydantic validation errors (no request body; path parameter is
  always a string — no 422 path exists for this endpoint).
- Internal use-case branches beyond the two scenarios above (covered by
  use-case unit test).
- Adapter `SELECT` predicate details (covered by adapter unit test).
- Performance, load, concurrency.
