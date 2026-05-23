# 0037 · delete_tier — Outside-in test spec

## Goal

Prove that `DELETE /api/v1/tier/{name}` permanently removes the named tier
from the database and returns `{"message": "Tier deleted"}` when called by a
superuser, and that the endpoint returns HTTP 404 when the tier does not exist.

## Entry point

- **Method:** `DELETE`
- **Path:** `/api/v1/tier/{name}` (e.g. `/api/v1/tier/silver`)
- **Body:** none
- **Auth:** Bearer token belonging to a superuser

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `DeleteTierAdapter` — executes SELECT and DELETE against the test Postgres.
- `DeleteTierPort` — bound to `DeleteTierAdapter` in `Container`.
- `DeleteTierUseCase` — orchestrates `port.get` + `port.delete`.
- Test Postgres via the savepoint-rollback fixture (transaction rolled back
  after each test; no rows leak between tests).
- DI container with `session_factory` overridden to use the test transaction.
- `async_get_db` overridden to use the same test transaction (this is a
  fat-handler migration slice; the old `erase_tier` handler bypasses the
  container — override `async_get_db` in addition to `session_factory` to
  ensure all DB access goes through the savepoint).

## Mocked

None — the test runs entirely against the test database. No Redis, no external
HTTP APIs.

## Fixtures used

- `async_client` (defined in slice `conftest.py`): `httpx.AsyncClient` wired
  to the app; overrides `container.session_factory` and `async_get_db` with the
  savepoint-based test transaction; rolls back after each test.
- `superuser_token` (defined in slice `conftest.py` or inherited): inserts a
  superuser row into `user` and returns a valid JWT access token for that user.
  Uses raw SQL (`sqlalchemy.text`) to insert the hashed password.
- `seed_tier` helper (inline or a fixture): inserts one row into the `tier`
  table via raw SQL using the same overridden session factory so the row is
  visible within the savepoint.

## Test scenarios

### Scenario 1: happy path — existing tier is deleted

**Setup:**

- A superuser exists in the `user` table; `superuser_token` holds its JWT.
- A tier row with `name = "silver"` is inserted via raw SQL into the `tier`
  table inside the savepoint transaction.

**Act:**

- `DELETE /api/v1/tier/silver` with header `Authorization: Bearer <superuser_token>`.

**Expect:**

- Status: `200`.
- Response body: `{"message": "Tier deleted"}`.
- DB state: no row with `name = "silver"` remains in the `tier` table
  (verified by a raw `SELECT` on the same session factory after the call).

**Covers requirement(s):** F1, F3, F7, F8.

---

### Scenario 2: not found — tier name does not exist in the database

**Setup:**

- A superuser exists; `superuser_token` holds its JWT.
- No tier with `name = "nonexistent"` exists in the `tier` table.

**Act:**

- `DELETE /api/v1/tier/nonexistent` with header `Authorization: Bearer <superuser_token>`.

**Expect:**

- Status: `404`.
- Response body: `{"error": {"code": "notfound", "message": "Tier not found"}}`.
- DB state: unchanged (no writes occurred).

**Covers requirement(s):** F2, F4.

---

## Out of scope for this test

- HTTP 403 and 401 responses (covered by the endpoint integration test in
  `presentation/test_router.py`).
- `port.delete` being skipped on the not-found path (covered by the use-case
  unit test in `domain/test_use_case.py`).
- `get` returning `None` vs. returning a `TierItem` with correct fields
  (covered by the adapter unit test in `data/test_adapter.py`).
- Zero-rows-matched behaviour for `delete` (covered by the adapter unit test).
- Field-level Pydantic validation errors (no request body; no 422 path exists).
- Performance, load, concurrency.
