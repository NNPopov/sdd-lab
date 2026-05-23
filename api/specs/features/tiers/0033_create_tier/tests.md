# 0033 · create_tier — Outside-in test spec

## Goal

Prove that a superuser can create a new tier via `POST /api/v1/tier`, that the
response carries the created tier's fields, and that a duplicate-name attempt
returns HTTP 409.

## Entry point

- **Method:** `POST`
- **Path:** `/api/v1/tier`
- **Body:** `{"name": "gold"}`
- **Auth:** Bearer token for a superuser account.

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `CreateTierAdapter` — issues a real `INSERT` against the test Postgres.
- `CreateTierPort` — bound to `CreateTierAdapter` in `Container`.
- `CreateTierUseCase` — fully wired.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the test runs entirely against the test database. No external HTTP APIs,
Redis, or clock dependencies are involved in tier creation.

## Fixtures used

- **`client`** (from `tests/conftest.py`): `httpx.AsyncClient` against the app,
  with the `db_session` override applied to `Container.session_factory`.
- **`db_session`** (from `tests/conftest.py`): per-test transaction, rolled back
  at teardown.
- **`superuser_token`** (in `tests/features/tiers/0033_create_tier/conftest.py`):
  seeds one superuser row in the `users` table via `db_session`, mints a valid
  JWT access token for that user, and returns the raw token string. The superuser
  must have `is_superuser = True` so `get_current_superuser` passes. Required
  fields: `username`, `email`, `hashed_password`, `is_superuser = True`.

## Test scenarios

### Scenario 1: happy path — superuser creates a tier

**Setup:**

- DB contains no tier row with `name == "gold"`.
- `superuser_token` fixture has seeded a superuser and returned a JWT.

**Act:**

- `POST /api/v1/tier` with body `{"name": "gold"}` and header
  `Authorization: Bearer <superuser_token>`.

**Expect:**

- Status: `201`.
- Response body is a JSON object containing:
  - `"name"` equal to `"gold"`.
  - `"id"` is a positive integer.
  - `"created_at"` is a non-null ISO-8601 timestamp string.
- DB state: exactly one row exists in the `tier` table with `name == "gold"`.

**Covers requirement(s):** F1, F8, F10.

---

### Scenario 2: duplicate name — second insert returns 409

**Setup:**

- DB already contains a row in `tier` with `name == "gold"` (inserted by
  calling `POST /api/v1/tier` with `{"name": "gold"}` as the first act in this
  scenario, or via a direct `db_session` seed in the fixture).

**Act:**

- `POST /api/v1/tier` again with body `{"name": "gold"}` and the same
  `Authorization: Bearer <superuser_token>` header.

**Expect:**

- Status: `409`.
- Response body: `{"message": "Tier name already exists"}`.
- DB state: still exactly one row with `name == "gold"` (the second insert did
  not produce a duplicate row).

**Covers requirement(s):** F5.

## Out of scope for this test

- HTTP 401 / 403 / 422 status codes (covered by the endpoint integration test
  at `tests/features/tiers/0033_create_tier/presentation/test_router.py`).
- Specific `IntegrityError` variants other than unique-constraint (covered by
  the adapter unit test).
- Use-case internal behavior (covered by the use-case unit test).
- Concurrent insert behavior under load.
