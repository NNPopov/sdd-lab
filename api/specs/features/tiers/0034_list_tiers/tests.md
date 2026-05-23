# 0034 · list_tiers — Outside-in test spec

## Goal

Prove that `GET /api/v1/tiers` traverses the full stack — router, DI container,
`ListTiersUseCase`, `ListTiersAdapter`, test Postgres — and returns a correctly
shaped paginated response both when tiers exist and when the table is empty.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/tiers`
- **Query parameters:** `page` (default 1), `items_per_page` (default 10)
- **Auth:** none

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `ListTiersAdapter` — issues real SQL COUNT and SELECT against test Postgres.
- `ListTiersPort` — bound to `ListTiersAdapter` in `Container`.
- `ListTiersUseCase` — delegates to the port.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction
  (handled by the `client` fixture in `tests/conftest.py`).

## Mocked

None — the test runs entirely against the test database. No external HTTP APIs,
no Redis, no clock dependency.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` with
  `ASGITransport` pointed at the app; `session_factory` already overridden to
  the per-test transaction.
- `db_session` (from `tests/conftest.py`): per-test async session with
  transaction rollback at teardown.
- `seeded_tiers` (slice `conftest.py`): inserts two `Tier` ORM rows (`name="free"`,
  `name="pro"`) into the test transaction and flushes; yields the list of
  inserted ORM objects so the test can compare `id` and `created_at` values.

## Test scenarios

### Scenario 1: happy path — two tiers in the database

**Setup:**

- `seeded_tiers` fixture inserts two rows into the `tier` table:
  `name="free"` and `name="pro"`, in that order.

**Act:**

- `GET /api/v1/tiers` with no query parameters (defaults apply: `page=1`,
  `items_per_page=10`).

**Expect:**

- Status: `200`.
- Response body shape: `{"items": [...], "total_count": 2, "page": 1,
  "items_per_page": 10}`.
- No `data` key. No `has_more` key.
- `items` has exactly 2 entries.
- Each item has `id` (int), `name` (str), `created_at` (ISO 8601 datetime
  string).
- `items[0].name == "free"`, `items[1].name == "pro"` (ascending `id` order).
- `items[0].id` and `items[1].id` match the `id` values from the
  `seeded_tiers` fixture.

**DB state:** read-only — no rows written by this request.

**Covers requirements:** F1, F6, F7, F10.

---

### Scenario 2: empty database — returns 200 with empty items list

**Setup:**

- No tiers inserted; `seeded_tiers` fixture is not used.

**Act:**

- `GET /api/v1/tiers` with no query parameters.

**Expect:**

- Status: `200`.
- Response body: `{"items": [], "total_count": 0, "page": 1,
  "items_per_page": 10}`.

**DB state:** read-only — no rows written by this request.

**Covers requirements:** F2.

## Out of scope for this test

- `page=0` and `items_per_page=0` / `>100` rejection (covered by endpoint
  integration test via 422 validation).
- Unauthenticated access assertion (covered by endpoint integration test).
- Pagination offset correctness beyond two scenarios (covered by adapter unit
  test with seed-3, page-2 case).
- Field-level Pydantic validation errors (covered by endpoint integration test).
- `ORDER BY id` stability across many pages (covered by adapter unit test).
- Performance, load, concurrency.
