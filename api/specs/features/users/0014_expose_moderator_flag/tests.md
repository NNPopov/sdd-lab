# 0014 · expose_moderator_flag — Outside-in test spec

## Goal

Prove that both `GET /api/v1/user/{username}` and `GET /api/v1/user/me/`
surface `is_moderator` correctly — returning `false` for a default user and
`true` after the flag is set directly in the test database.

## Entry points

This test exercises two public/authenticated read endpoints in sequence:

- **Method / Path 1:** `GET /api/v1/user/{username}` — public, no auth.
- **Method / Path 2:** `GET /api/v1/user/me/` — authenticated, Bearer token.

Auth for path 2: a Bearer token obtained by calling `POST /api/v1/auth/login`
with the test user's credentials after the user is created.

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `GetUserByUsernameAdapter` and `GetUserByUsernameUseCase` (slice 0004).
- `get_current_user` dependency and the `read_users_me` use-case (users/_shared).
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the test runs entirely against the test database. Neither `GET`
endpoint touches Redis or any external HTTP API.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` bound to the
  running test app via `ASGITransport`.
- `db_session` (from `tests/conftest.py`): per-test async session; the entire
  test is wrapped in a transaction that rolls back at teardown.

No slice-specific `conftest.py` is needed. User creation, login, and the
direct moderator-flag update are all performed inline through the API and
`db_session` respectively.

## Test scenarios

### Scenario 1: non-moderator user — both endpoints return `is_moderator: false`

**Setup:**

- No seed rows required (other than the default tier row if the app enforces one
  at creation time; the `db_session` fixture handles the transaction boundary).

**Act (four calls in order):**

1. `POST /api/v1/users` with body `{"username": "alice", "email": "alice@example.com", "password": "Pa$$w0rd1"}` — creates the user; expected status `201`.
2. `POST /api/v1/auth/login` with form-data `username=alice, password=Pa$$w0rd1` — returns a Bearer token; expected status `200`.
3. `GET /api/v1/user/alice` — no `Authorization` header.
4. `GET /api/v1/user/me/` with `Authorization: Bearer <token from step 2>`.

**Expect:**

- Step 1 status: `201`; response body contains `"username": "alice"`.
- Step 2 status: `200`; response body contains `"access_token"`.
- Step 3 status: `200`; response body contains `"is_moderator": false`.
  The field must be present — not absent, not `null`.
- Step 4 status: `200`; response body contains `"is_moderator": false` and
  `"is_superuser": false`.
  Both fields must be present.

**DB state:** one non-deleted row in `user` with `username == "alice"` and
`is_moderator == False`.

**Covers requirements:** F5, F7, F8, F9, F12.

---

### Scenario 2: moderator flag set in DB — both endpoints return `is_moderator: true`

**Setup:**

- Continue from Scenario 1 (same `db_session` transaction).
  User `alice` exists with `is_moderator = False`.

**Act (three calls in order):**

1. Execute an `UPDATE` against the test DB via `db_session`:
   `UPDATE "user" SET is_moderator = TRUE WHERE username = 'alice'`
   (or the SQLAlchemy equivalent using the `User` ORM model).
   Flush the session so the change is visible to subsequent reads within the
   same transaction.
2. `GET /api/v1/user/alice` — no `Authorization` header.
3. `GET /api/v1/user/me/` with `Authorization: Bearer <same token as Scenario 1>`.

**Expect:**

- Step 2 status: `200`; response body contains `"is_moderator": true`.
- Step 3 status: `200`; response body contains `"is_moderator": true`.

**DB state:** the same row for `alice` now has `is_moderator == True`
(within the test transaction; rolled back at teardown).

**Covers requirements:** F6, F10, F12.

## Out of scope for this test

- `GET /api/v1/users` (list users) not containing `is_moderator` — verified by
  the endpoint integration test for slice 0003 and by code review (F11).
- Field-level Pydantic validation and 422 responses — covered by endpoint
  integration tests.
- The 404 path for an unknown username — covered by the existing
  outside-in test for slice 0004.
- Adapter-level `is_moderator` mapping correctness in isolation — covered by
  the adapter unit test (F2).
- Performance, concurrency, or load behavior.
