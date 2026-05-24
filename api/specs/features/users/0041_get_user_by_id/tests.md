# 0041 · get_user_by_id — Outside-in test spec

## Goal

Prove that `GET /api/v1/user/{user_id}` retrieves a user by integer primary key
and that a string value in the path (the old username-based URL shape) is
rejected with 422.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/user/{user_id}`
- **Body:** none
- **Auth:** none

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `GetUserByIdAdapter` — executes the primary-key + soft-delete SQLAlchemy query.
- `GetUserByIdPort` — bound to the adapter in `Container`.
- `GetUserByIdUseCase` — raises `NotFoundDomainError` when the adapter returns `None`.
- Test Postgres via the `oit_engine` fixture (schema ensured at start).
- DI container with `session_factory` overridden to use the savepoint test
  transaction (per `agent_docs/testing.md` § Fixtures).

## Mocked

None — the test runs entirely against the test database.

## Fixtures used

- `async_client` (slice `conftest.py`): `httpx.AsyncClient` with
  `ASGITransport(app=app)` and `session_factory` overridden to the savepoint
  transaction. Each test rolls back at teardown.
- No additional seed fixtures needed; the user row is created inline via
  `POST /api/v1/users` as part of Scenario 1.

## Test scenarios

### Scenario 1: happy path — existing user returns 200 with all fields

**Setup:**

- Create a user by calling `POST /api/v1/users` with body:
  `{"username": "alice", "name": "Alice Test", "email": "alice@example.com",
  "password": "Pa$$w0rd1"}`.
- Capture the `id` from the `201` response.

**Act:**

- `GET /api/v1/user/{id}` using the captured `id`.

**Expect:**

- Status: `200`.
- Response body is a JSON object with exactly these fields and values:
  - `id` equals the captured `id`.
  - `username` equals `"alice"`.
  - `name` equals `"Alice Test"`.
  - `email` equals `"alice@example.com"`.
  - `profile_image_url` is a string (may be empty or a default URL).
  - `tier_id` is `null` or an integer.
  - `is_moderator` equals `false`.
- DB state: unchanged (read-only endpoint; the user row created in setup still
  exists and is unmodified).

**Covers requirement(s):** F1, F2, F6, F11.

---

### Scenario 2: string path value (old username route) returns 422

**Setup:**

- None required. No user needs to exist.

**Act:**

- `GET /api/v1/user/alice` — passing a string where `user_id: int` is expected.

**Expect:**

- Status: `422`.
- Response body contains FastAPI's validation error structure (Pydantic coercion
  failure for the `user_id` path parameter — value `"alice"` is not a valid
  integer).
- DB state: no change (request rejected before the adapter is reached).

**Covers requirement(s):** F4, F10.

---

## Out of scope for this test

- 404 response for a non-existent integer ID (covered by the endpoint
  integration test).
- Soft-deleted user returning 404 (covered by the endpoint integration test).
- Specific SQLAlchemy or DB exceptions (covered by the adapter unit test, though
  this adapter has no try/except — it is purely read-only).
- Use-case not-found branch in isolation (covered by the use-case unit test).
- Performance, load, concurrency.
