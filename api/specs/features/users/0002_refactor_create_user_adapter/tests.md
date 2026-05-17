# 0002 · refactor_create_user_adapter — Outside-in test spec

## Goal

Verify that the refactored `create_user` adapter and port produce the same
end-to-end HTTP behavior as before: successful registration returns 201, and a
duplicate-email attempt returns 409.

## Entry point

The HTTP call the test makes.

- **Method:** `POST`
- **Path:** `/api/v1/user`
- **Body:** `CreateUserRequest` (`name`, `username`, `email`, `password`)
- **Auth:** none

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `CreateUserAdapter` (the refactored adapter — no try/except in read methods,
  scoped commit-only catch in `create`).
- `CreateUserPort` bound to `CreateUserAdapter` in `Container`.
- `CreateUserUseCase` (unchanged from slice 0001).
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the test runs entirely against the test database.

## Fixtures used

- `client` (from `tests/conftest.py`): the `httpx.AsyncClient` against the
  running app, scoped per test.
- `db_session`: per-test transaction; rolls back after each scenario so
  scenarios are independent.

## Test scenarios

### Scenario 1: happy path — user created successfully

**Setup:**

- DB is empty (no pre-existing user rows).

**Act:**

- POST to `/api/v1/user` with body
  `{"name": "Alice", "username": "alice", "email": "alice@example.com", "password": "Pa$$w0rd1"}`.

**Expect:**

- Status: `201`.
- Response body contains `id` (non-null UUID), `name == "Alice"`,
  `username == "alice"`, `email == "alice@example.com"`.
- Password is **absent** from the response body.
- DB state: exactly one `users` row exists with `username == "alice"` and
  `email == "alice@example.com"`.

**Covers requirement(s):** F7.

---

### Scenario 2: duplicate email — 409 returned

**Setup:**

- DB already contains a user with `email == "alice@example.com"` (created by
  running the same POST as Scenario 1, or seeded directly via the session).

**Act:**

- POST to `/api/v1/user` with body
  `{"name": "Bob", "username": "bob", "email": "alice@example.com", "password": "Pa$$w0rd1"}`.

**Expect:**

- Status: `409`.
- Response body: `{"message": "Email is already registered"}` (the message the
  use-case sets when `email_exists` returns `True`).
- DB state: still exactly one `users` row with `email == "alice@example.com"`;
  no `bob` row created.

**Covers requirement(s):** F8 (use-case path via `email_exists`).

---

## Out of scope for this test

- `IntegrityError`-level duplicate catching in the adapter (the commit-level
  guard, F8 adapter path) — covered by adapter unit test.
- Non-`IntegrityError` propagation from `commit` (F9) — covered by adapter
  unit test.
- Exception propagation from read-only queries (F3, F6) — covered by adapter
  unit test; impractical to verify end-to-end without stopping the DB.
- Duplicate username path (use-case check via `username_exists`) — covered by
  endpoint integration test for slice 0001.
- Field-level Pydantic validation errors (422) — covered by endpoint
  integration test for slice 0001.
- Performance, load, concurrency.
