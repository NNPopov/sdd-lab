# 0040 · delete_tier_by_id — Outside-in test spec

## Goal

Prove that `DELETE /api/v1/tier/{id}` correctly deletes the tier identified by
its integer primary key and returns a confirmation body, and returns 404 when no
tier with the given `id` exists.

## Entry point

The HTTP call the test makes.

- **Method:** `DELETE`
- **Path:** `/api/v1/tier/{id}` where `{id}` is the integer primary key captured
  from the seed INSERT.
- **Body:** none.
- **Auth:** `get_current_superuser` dependency is overridden to `lambda: None` —
  no real JWT token is used; the superuser gate is bypassed at the framework level.

## Wired real

- FastAPI app from `app.main.app` (full stack: middleware, exception handlers,
  `domain_error_handler` → HTTP 404 mapping).
- `DeleteTierAdapter` (reads and deletes by `Tier.id`).
- `DeleteTierPort` (bound to the adapter via `Container`).
- `DeleteTierUseCase` (calls `port.get(command.id)`; raises `NotFoundDomainError`
  if `None`; calls `port.delete(command.id)` on happy path).
- Test Postgres via the `oit_engine` + `async_client` fixtures in
  `tests/features/tiers/0037_delete_tier/conftest.py` (savepoint rollback per test).
- `container.session_factory` overridden to use the test transaction.
- `async_get_db` overridden to the same test transaction (retained from 0037
  conftest for compatibility; not load-bearing for 0040 since the old fat handler
  is gone).

## Mocked

- `get_current_superuser` is replaced with `lambda: None` via
  `app.dependency_overrides` for the duration of each test, then removed in
  `finally`. This lets the test bypass JWT without touching any other layer.

Nothing else is mocked. The test runs entirely against the test database.

## Fixtures used

- `async_client` (from `tests/features/tiers/0037_delete_tier/conftest.py`):
  the `httpx.AsyncClient` wired to the app with per-test transaction rollback.
  Provides `container.session_factory` overridden to the savepoint transaction.
- `_clean_test_tiers` (autouse fixture in same conftest): deletes any tier rows
  named `"silver"` or `"nonexistent"` inside the test transaction before each
  test, protecting against residue from interrupted prior runs.

The seed INSERT captures `id` via `RETURNING id`:

```sql
INSERT INTO tier (name, created_at) VALUES ('silver', NOW()) RETURNING id
```

The returned scalar integer is used as the path segment in the DELETE call and
in the post-deletion DB assertion.

## Test scenarios

### Scenario 1: happy path — existing tier is deleted

**Setup:**

- `_clean_test_tiers` autouse fixture runs: any pre-existing `"silver"` row is
  removed within the test transaction.
- Seed: `INSERT INTO tier (name, created_at) VALUES ('silver', NOW()) RETURNING id`
  — capture the returned integer as `tier_id`.
- `get_current_superuser` dependency override active.

**Act:**

- `await async_client.delete(f"/api/v1/tier/{tier_id}")`

**Expect:**

- Status: `200`.
- Response body: `{"message": "Tier deleted"}`.
- DB state: `SELECT id FROM tier WHERE id = {tier_id}` returns no rows — the
  tier has been removed from the database.

**Covers requirements:** F1, F3, F5, F9, F10.

---

### Scenario 2: not found — no tier with given id

**Setup:**

- No tier row with id `999999` exists (clean test transaction).
- `get_current_superuser` dependency override active.

**Act:**

- `await async_client.delete("/api/v1/tier/999999")`

**Expect:**

- Status: `404`.
- Response body:
  ```json
  {"error": {"code": "notfound", "message": "Tier not found"}}
  ```
- DB state: unchanged (no rows inserted or deleted).

**Covers requirements:** F4, F6.

---

## Target file

This spec describes modifications to the existing outside-in test:

```
tests/features/tiers/0037_delete_tier/delete_tier_outside_in_test.py
```

The test file is updated in-place (not a new file). Changes relative to the
0037 version:

- Seed query gains `RETURNING id`; captured id stored in `tier_id`.
- DELETE path changes from `f"{_ENDPOINT}/silver"` to `f"{_ENDPOINT}/{tier_id}"`.
- Not-found path uses a nonexistent integer (`/999999`) instead of a string
  (`/nonexistent`).
- DB post-deletion assertion filters by `WHERE id = :id` instead of
  `WHERE name = :n`.

## Out of scope for this test

- 422 response for non-integer `{id}` (covered by endpoint integration test).
- 403 Forbidden / 401 Unauthorized (covered by endpoint integration test).
- Adapter-level `get` and `delete` calls in isolation (covered by adapter unit test).
- Use-case branch logic (covered by use-case unit test).
- Performance, load, concurrency.
