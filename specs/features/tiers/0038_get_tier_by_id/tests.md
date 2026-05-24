# 0038 · get_tier_by_id — Outside-in test spec

## Goal

Prove that `GET /api/v1/tier/{tier_id}` resolves a tier by its integer primary
key, returning the full tier body on success and a structured 404 on miss.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/tier/{tier_id}` where `tier_id` is the integer id of the seeded tier.
- **Body:** none.
- **Auth:** none (public endpoint).

## Wired real

- FastAPI app from `create_app()` — full stack: all middleware, global `DomainError`
  exception handler, `domain_error_handler`.
- `GetTierAdapter` — queries `Tier.id == query.id` against the test Postgres.
- `GetTierPort` — bound to `GetTierAdapter` via `Container.get_tier_use_case`.
- `GetTierUseCase` — raises `NotFoundDomainError` when the adapter returns `None`.
- Test Postgres via the `oit_engine` + `async_client` fixtures (savepoint-mode
  transaction rollback per test). All rows seeded inside the test are rolled back
  at teardown; the production DB is never touched.
- `Container.session_factory` overridden to the savepoint-mode factory so that
  `session.commit()` inside the adapter creates a SAVEPOINT, not a real commit.

## Mocked

None — the test runs entirely against the test database. No external HTTP APIs,
no Redis, and no clock patching are required for this slice.

## Fixtures used

- `oit_engine` (slice `conftest.py`): per-test async engine; ensures schema exists.
- `async_client` (slice `conftest.py`): `httpx.AsyncClient` wired to the app with
  the `session_factory` override and outer-transaction rollback. This fixture
  follows the canonical pattern from `agent_docs/testing.md`.

No additional factory fixtures are needed — the tier row is seeded inline using
`sqlalchemy.text` against the overridden `session_factory` inside each scenario.

## Red-state signal

Before the implementation changes, the router serves `GET /tier/{name}` where
the path param is typed `str`. Calling `GET /tier/<integer_id>` matches the
existing route and queries `WHERE Tier.name == "<integer_id>"`. No tier has a
name equal to its own id string, so the adapter returns `None` and the endpoint
returns 404. Scenario 1's assertion on `status_code == 200` fails, confirming
the test is RED. Scenario 2 may pass coincidentally (both old and new behavior
return 404 for a non-existent id), but Scenario 1 is sufficient to gate the
implementation.

## Test scenarios

### Scenario 1: happy path — existing tier by id returns 200

**Setup:**

- Seed one tier row via raw SQL using `container.session_factory()()`:
  ```sql
  INSERT INTO "tier" (name, created_at) VALUES ('oit-gettierbyid-<uuid8>', NOW())
  ```
  Use a unique name prefix (`oit-gettierbyid-`) with a short random hex suffix to
  avoid collisions across test runs.
- After the insert, query the same session for the assigned `id`:
  ```sql
  SELECT id FROM "tier" WHERE name = :name
  ```
  Store the result as `tier_id`.

**Act:**

- `GET /api/v1/tier/{tier_id}` (no Authorization header).

**Expect:**

- Status: `200`.
- Response body is a JSON object with:
  - `id` equal to `tier_id` (integer).
  - `name` equal to the seeded name string.
  - `created_at` present (ISO 8601 datetime string; exact value is not asserted).
- No extra top-level keys beyond `id`, `name`, `created_at`.

**DB state:** the tier row exists (seeded before the call; it is a read-only
endpoint, so no writes occur and no state assertion is required beyond the
presence of the row).

**Covers requirement(s):** F1, F4, F5, F7.

---

### Scenario 2: not found — non-existent id returns 404

**Setup:**

- No tier row with id `999999` exists in the test database (no seed required).

**Act:**

- `GET /api/v1/tier/999999` (no Authorization header).

**Expect:**

- Status: `404`.
- Response body exactly:
  ```json
  {
    "error": {
      "code": "notfound",
      "message": "Tier not found"
    }
  }
  ```

**DB state:** no writes; no assertion required.

**Covers requirement(s):** F2, F6, F8.

## Out of scope for this test

- Non-integer path parameter (422 response) — covered by the endpoint integration
  test (`tests/features/tiers/0035_get_tier/presentation/test_router.py`), which
  FastAPI validates before the use-case is invoked.
- Port inheritance check (`isinstance(adapter, GetTierPort)`) — covered by the
  adapter unit test (`tests/features/tiers/0035_get_tier/data/test_adapter.py`).
- Infrastructure exception propagation — covered by the adapter unit test.
- Use-case branch logic — covered by the use-case unit test.
- Performance, load, concurrency.
