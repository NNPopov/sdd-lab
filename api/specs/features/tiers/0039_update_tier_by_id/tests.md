# 0039 · update_tier_by_id — Outside-in test spec

## Goal

Prove that `PATCH /api/v1/tier/{id}` renames the matching tier by its integer primary key and returns 409 when the new name is already taken, exercising the full HTTP stack with the real adapter and test Postgres.

## Entry point

- **Method:** `PATCH`
- **Path:** `/api/v1/tier/{id}` where `{id}` is the integer primary key returned by `RETURNING id` after seeding.
- **Body:** `{"name": "<new_name>"}` — the desired new name.
- **Auth:** superuser required. Bypassed in tests by overriding `get_current_superuser` via `app.dependency_overrides[get_current_superuser] = lambda: None`.

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `UpdateTierAdapter` — the slice's adapter; queries and updates by `Tier.id`.
- `UpdateTierPort` — bound to `UpdateTierAdapter` in `Container`.
- `UpdateTierUseCase` — performs the not-found check and delegates to the adapter.
- Test Postgres via the `async_client` fixture (savepoint-mode transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction connection.

## Mocked

None — the test runs entirely against the test database. The superuser auth dependency is bypassed with `app.dependency_overrides`, not a port mock.

## Fixtures used

- `async_client` (from `tests/features/tiers/0036_update_tier/conftest.py`): `httpx.AsyncClient` against the app, with the DI `session_factory` overridden to use the savepoint transaction.
- `_seed_tier(name: str) -> int` (helper defined inline in the test): executes `INSERT INTO tier (name, created_at) VALUES (:name, NOW()) RETURNING id` via the overridden `session_factory`, commits (creating a savepoint), and returns the integer `id`.

## Test scenarios

### Scenario 1: happy path — rename by id

**Setup:**

- Call `_seed_tier("silver")` → captures returned `tier_id` (e.g. `42`).
- Override `get_current_superuser` to return `None` (no auth check).

**Act:**

- `PATCH /api/v1/tier/{tier_id}` with body `{"name": "platinum"}`.

**Expect:**

- Status: `200`.
- Response body: `{"message": "Tier updated"}`.
- DB state: a row with `id == tier_id` exists with `name == "platinum"` and a non-null `updated_at`; no row with `name == "silver"` remains.

**Covers requirement(s):** F1, F9, F10, F14.

### Scenario 2: duplicate name returns 409

**Setup:**

- Call `_seed_tier("silver")` → `silver_id`.
- Call `_seed_tier("gold")` → ensures a "gold" row exists.
- Override `get_current_superuser` to return `None`.

**Act:**

- `PATCH /api/v1/tier/{silver_id}` with body `{"name": "gold"}`.

**Expect:**

- Status: `409`.
- Response body: `{"error": {"code": "duplicatevalue", "message": "Tier name already exists"}}`.
- DB state: the row with `id == silver_id` still has `name == "silver"`; the "gold" row is unchanged.

**Covers requirement(s):** F11, F15.

## Out of scope for this test

- Field-level validation (missing `name`, empty `name`, non-integer `id`) — covered by the endpoint integration test.
- Not-found path (no tier with the given id) — covered by the endpoint integration test and use-case unit test.
- `IntegrityError` variant details (unique vs FK) — covered by the adapter unit test.
- Authorization rejection (403, 401) — covered by the endpoint integration test.
- Performance, load, concurrency.
