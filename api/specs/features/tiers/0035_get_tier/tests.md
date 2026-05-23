# 0035 · get_tier — Outside-in test spec

## Goal

Prove that `GET /api/v1/tier/{name}` returns a correctly shaped `GetTierResponse` for an existing
tier, and HTTP 404 with the expected message when the name is absent from the database.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/tier/{name}` — `name` is a path parameter
- **Body:** none
- **Auth:** none (public endpoint)

## Wired real

- FastAPI app from `create_app()` (full stack: all middleware, exception handlers).
- `GetTierAdapter` — executes the real SQLAlchemy SELECT against the test Postgres.
- `GetTierPort` — bound to `GetTierAdapter` in `Container`.
- `GetTierUseCase` — raises `NotFoundDomainError` when the adapter returns `None`.
- Test Postgres via the `db_session` fixture (transaction rolled back after each test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the test runs entirely against the test database. This slice has no cache, no
external HTTP calls, and no Redis dependency.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` pointing at the test app.
- `db_session` (from `tests/conftest.py`): per-test async session; transaction rolled back at
  teardown.
- `seeded_tier` (slice `conftest.py`): inserts one `Tier` row directly via `db_session` and
  returns a dict with `id`, `name`, and `created_at`. Seeds `name="gold"` with a concrete
  known name so the test can form the URL without guessing.

## Test scenarios

### Scenario 1: happy path — existing tier returns 200

**Setup:**

- DB contains one tier row: `name="gold"` (inserted by the `seeded_tier` fixture).

**Act:**

- `GET /api/v1/tier/gold`

**Expect:**

- Status: `200`.
- Response body is a JSON object with exactly three fields:
  - `id` — integer, matches the value from `seeded_tier["id"]`.
  - `name` — string `"gold"`.
  - `created_at` — ISO 8601 datetime string, matches `seeded_tier["created_at"]` (within one
    second tolerance to absorb serialization rounding).
- DB state: the `tier` table still contains exactly the same row (no write occurred).

**Covers requirement(s):** F1, F2, F5 (use-case returns `TierItem`), F7 (adapter maps row).

---

### Scenario 2: not-found — unknown name returns 404

**Setup:**

- DB contains no tier with `name="nonexistent_tier_xyz"`.

**Act:**

- `GET /api/v1/tier/nonexistent_tier_xyz`

**Expect:**

- Status: `404`.
- Response body: `{"message": "Tier not found"}`.
- DB state: unchanged (no rows inserted or deleted).

**Covers requirement(s):** F3, F6 (use-case raises `NotFoundDomainError`), F8 (adapter returns
`None`).

---

## Out of scope for this test

- Field-level Pydantic validation (no request body; path parameter cannot be empty in FastAPI
  routing).
- Authentication / authorization errors (this endpoint has no auth).
- Infrastructure failures (DB down → 500) — behaviour is guaranteed by the global handler, not
  by this slice's logic.
- Pagination, filtering, or listing (separate slice 0034).
- Specific SQLAlchemy exception propagation — covered by the adapter unit test if it exists.
- Use-case branch logic beyond the two scenarios above — covered by the use-case unit test.
