# 0001 · create_user — Outside-in test spec

## Goal

Prove that the full `create_user` slice — router, use case, adapter, Postgres,
and exception handlers — composes correctly: a valid POST creates a user and
returns `201`; a duplicate email request returns `409` with the exact error
payload and leaves no extra row in the database.

## Entry point

- **Method:** `POST`
- **Path:** `/api/v1/user`
- **Body:** `CreateUserRequest` — JSON object with `name`, `username`, `email`,
  `password`.
- **Auth:** None — the endpoint is public.

## Wired real

- FastAPI app from `create_application()` (full stack: `LoggerMiddleware`,
  `ClientCacheMiddleware`, `domain_error_handler`, all registered exception
  handlers).
- `CreateUserAdapter` — the concrete port implementation that writes to Postgres.
- `CreateUserUseCase` — the class with `__call__`; password hashing and
  uniqueness checks run for real.
- `CreateUserPort` — bound to `CreateUserAdapter` through `Container`.
- Test Postgres via the `db_session` fixture (per-test transaction, rolled back
  at teardown so each scenario starts from a clean state).
- `Container` with `session_factory` overridden to route writes through the
  test transaction.

## Mocked

None — the slice has no external HTTP API dependency, does not touch Redis,
and does not read the clock. The test runs entirely against the test database.

## Fixtures used

- **`client`** (from `tests/conftest.py`): `httpx.AsyncClient` backed by
  `ASGITransport(app=app)`; the `app` fixture already overrides
  `container.session_factory` with the per-test transaction.
- **`db_session`** (from `tests/conftest.py`): the `AsyncSession` bound to the
  per-test rolled-back transaction. Used by the test to assert on DB state
  (row count) after each act.

No slice-specific fixture is required. Creating a user has no prerequisite rows
— `tier_id` is nullable and defaults to `NULL`; no tier row is needed.

## Test scenarios

### Scenario 1: happy path — new user created

**Setup:**

- DB contains: no `user` row with `username="alice99"` or
  `email="alice99@example.com"`.
- Mocks configured: none.

**Act:**

POST to `/api/v1/user` with body:

```json
{
  "name": "Alice Example",
  "username": "alice99",
  "email": "alice99@example.com",
  "password": "Str0ng!pw"
}
```

**Expect:**

- Status: `201`.
- Response body is a JSON object that matches `CreateUserResponse`:
  - `id` is a positive integer.
  - `name` equals `"Alice Example"`.
  - `username` equals `"alice99"`.
  - `email` equals `"alice99@example.com"`.
  - `profile_image_url` is a non-empty string.
  - `tier_id` is `null`.
- DB state: exactly one row in the `user` table with `username = 'alice99'`
  and `email = 'alice99@example.com'`.

**Covers requirements:** F1, F3, F4, F12, F15.

---

### Scenario 2: duplicate email — 409 with correct payload, no extra row

**Setup:**

- Seed a pre-existing user: POST to `/api/v1/user` with
  `username="alice99"`, `email="alice99@example.com"`, `name="Alice Example"`,
  `password="Str0ng!pw"` (the same call as Scenario 1 — use the API itself
  to seed, so the adapter and DB are in a known state).
- After seeding, the DB contains exactly one row for `alice99@example.com`.

**Act:**

POST to `/api/v1/user` with body:

```json
{
  "name": "Alice Clone",
  "username": "alice_clone",
  "email": "alice99@example.com",
  "password": "Str0ng!pw"
}
```

(A different `username` but the same `email` as the existing user.)

**Expect:**

- Status: `409`.
- Response body:
  ```json
  {
    "error": {
      "code": "duplicatevalue",
      "message": "Email is already registered"
    }
  }
  ```
- DB state: still exactly one row with `email = 'alice99@example.com'` — no
  duplicate was inserted.

**Covers requirements:** F5, F7, F9, F13, F16, F17.

## Out of scope for this test

- Field-level validation errors (missing field, invalid email format, short
  password) — covered by the endpoint integration test
  (`presentation/test_router.py`).
- Duplicate username with a unique email — covered by the endpoint integration
  test.
- The email-before-username check order when both are duplicate — covered by
  the use-case unit test (`domain/test_use_case.py`, F9).
- `IntegrityError` → `DuplicateValueDomainError` mapping in the inner catch —
  covered by the adapter unit test (`data/test_adapter.py`, F16).
- Unexpected adapter failure path (`UnknownDomainError`) — covered by the
  adapter unit test (`data/test_adapter.py`, F17).
- Performance, load, concurrency.
