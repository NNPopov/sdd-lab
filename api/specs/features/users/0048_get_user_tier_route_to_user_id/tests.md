# 0048 · get_user_tier_route_to_user_id — Outside-in test spec

## Goal

Prove that `GET /api/v1/user/{user_id}/tier` resolves a user by integer primary
key and returns that user's tier through the full HTTP stack — and returns 404
for an unknown `user_id` — after the route migration from `{username}` to
`{user_id}`.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/user/{user_id}/tier`
- **Body:** none.
- **Auth:** none (the existing slice-0005 route has no auth dependency).

## Wired real

- FastAPI app (`app.main:app`, full stack: middleware, exception handlers).
- The slice's adapter (`GetUserTierAdapter`).
- The slice's port (`GetUserTierPort`, bound to the adapter in `Container`).
- The slice's use-case (`GetUserTierUseCase`).
- Test Postgres via the slice `conftest.py` fixtures (`oit_engine`,
  `async_client`) with per-test transaction rollback via savepoints.
- DI container with `session_factory` overridden to use the test transaction
  (`container.session_factory.override(test_factory)`).

## Mocked

None — the test runs entirely against the test database. No external HTTP API,
Redis, or clock is touched by this read path.

## Fixtures used

- `async_client` (slice `conftest.py`): `httpx.AsyncClient` wired to the app via
  `ASGITransport`, with the container `session_factory` overridden to the
  per-test transaction.
- `oit_engine` (slice `conftest.py`): per-test async engine that creates the
  schema.
- `seeded_user_with_tier` (slice `conftest.py`): inserts one `Tier` row
  (`name="pro"`) and one `User` row (`username="tieruser"`) whose `tier_id`
  references it, through the overridden session; returns `(tier, user)`. The
  test reads `user.id` from this fixture to build the request URL.

## Test scenarios

### Scenario 1: happy path — get tier by user_id

**Setup:**

- DB contains (via `seeded_user_with_tier`): a `Tier` row `name="pro"` and a
  `User` row `username="tieruser"` with `tier_id` pointing at that tier.
- Mocks configured: none.

**Act:**

- `GET /api/v1/user/{user.id}/tier`, where `user.id` is the integer primary key
  captured from the `seeded_user_with_tier` fixture.

**Expect:**

- Status: `200`.
- Response body is a non-null object whose keys are exactly `tier_id`,
  `tier_name`, `tier_created_at`.
- `tier_id == tier.id`, `tier_name == "pro"`, and `tier_created_at` is present.

**Covers requirement(s):** F1, F4, F8.

### Scenario 2: not found — unknown user_id

**Setup:**

- DB contains no user with the queried id (a large id such as `999999` that was
  never seeded).
- Mocks configured: none.

**Act:**

- `GET /api/v1/user/999999/tier`.

**Expect:**

- Status: `404`.
- Response body: `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers requirement(s):** F5, F8, F9.

## Out of scope for this test

- The 200/`null` "user exists but has no tier" path (covered by the endpoint
  integration test — F2/F7).
- The `TierNotFound` → 404 branch (covered by use-case and adapter unit tests —
  F6).
- 422 for a non-integer path param (covered by the endpoint integration test —
  F3).
- Specific SQLAlchemy exception variants (covered by the adapter unit test).
- Performance, load, concurrency.
