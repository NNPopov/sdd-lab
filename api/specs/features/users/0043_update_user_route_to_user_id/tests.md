# 0043 · update_user_route_to_user_id — Outside-in test spec

## Goal

Prove that `PATCH /api/v1/user/{user_id}` updates the target user's profile
when called by the owner, and returns HTTP 403 when called by a different
authenticated user.

## Entry point

- **Method:** `PATCH`
- **Path:** `/api/v1/user/{user_id}`
- **Body:** `UpdateUserRequest` (e.g. `{"name": "Alice Updated"}`)
- **Auth:** Bearer JWT obtained by logging in as the requesting user

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `UpdateUserAdapter` (performs the `SELECT` and `UPDATE` against the test Postgres).
- `UpdateUserPort` (bound to `UpdateUserAdapter` in `Container`).
- `UpdateUserUseCase` (enforces ownership and duplicate checks).
- Test Postgres via the `async_client` fixture (savepoint transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the test runs entirely against the test database.

## Fixtures used

- `async_client` (from slice `conftest.py`): `httpx.AsyncClient` with
  `ASGITransport`, `session_factory` overridden to the savepoint transaction.
- `oit_engine` (from slice `conftest.py`): ensures schema exists before the test.
- Inline seeding: raw SQL `INSERT` statements inside each scenario to create
  users and obtain their integer IDs and JWT tokens via `POST /api/v1/login`.

## Test scenarios

### Scenario 1: happy path — owner updates own profile

**Setup:**

- DB contains a user with `username="alice"`, `email="alice@example.com"`,
  `password="Password1!"` (hashed), `is_deleted=False`. Record the returned `id`
  as `alice_id`.
- A valid JWT for `alice` is obtained by calling `POST /api/v1/login` with
  `alice`'s credentials. Record it as `token_alice`.

**Act:**

- `PATCH /api/v1/user/{alice_id}` with header `Authorization: Bearer {token_alice}`
  and body `{"name": "Alice Updated"}`.

**Expect:**

- Status: `200`.
- Response body: `{"message": "User updated"}`.
- DB state: the `users` row for `alice_id` has `name == "Alice Updated"`.

**Covers requirement(s):** F1, F11, F15.

### Scenario 2: forbidden — different user attempts to update

**Setup:**

- DB contains user `alice` (id `alice_id`) and user `bob` (id `bob_id`), both
  `is_deleted=False`.
- A valid JWT for `bob` is obtained via `POST /api/v1/login`. Record it as
  `token_bob`.

**Act:**

- `PATCH /api/v1/user/{alice_id}` with header `Authorization: Bearer {token_bob}`
  and body `{"name": "Hijacked"}`.

**Expect:**

- Status: `403`.
- Response body: `{"error": {"code": "forbidden", "message": ""}}`.
- DB state: `alice`'s `name` is unchanged.

**Covers requirement(s):** F5, F13, F14.

## Out of scope for this test

- Non-integer `user_id` path param (422) — covered by endpoint integration test.
- Missing/invalid token (401) — covered by endpoint integration test.
- Non-existent `user_id` (404) — covered by endpoint integration test.
- Duplicate email / username (409) — covered by endpoint integration test and
  adapter unit test.
- `email_exists` / `username_exists` skip-if-unchanged branches — covered by
  use-case unit test.
- `IntegrityError` → `DuplicateValueDomainError` translation — covered by
  adapter unit test.
- Performance, load, concurrency.
