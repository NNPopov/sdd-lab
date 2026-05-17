# 0005 · get_user_tier — Outside-in test spec

## Goal

Prove that `GET /api/v1/user/{username}/tier` returns the correct tier fields
with HTTP 200 when the user has a tier assigned, and HTTP 404 when the username
does not exist.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/user/{username}/tier`
- **Body:** none
- **Auth:** none (public endpoint)

## Wired real

- FastAPI app (full stack: all middleware, exception handlers).
- `GetUserTierAdapter` — queries `User` and `Tier` ORM rows against the test DB.
- `GetUserTierPort` — bound to the adapter in the DI container.
- `GetUserTierUseCase` — checks sentinel returns, raises `NotFoundDomainError`.
- Test Postgres via a per-test `async_sessionmaker` (transaction rollback after
  each test).
- DI container with `session_factory` overridden to use the test transaction's
  connection (savepoint mode), matching the pattern established by the
  `0004_get_user_by_username` conftest.

## Mocked

None — the test runs entirely against the test database. No Redis, no external
HTTP APIs, no clock dependency.

## Fixtures used

- **`async_client`** (defined in the slice `conftest.py`): builds a per-test
  async engine, creates tables, opens a connection + transaction, wraps it in
  a savepoint-mode `async_sessionmaker`, overrides `container.session_factory`,
  yields an `httpx.AsyncClient(transport=ASGITransport(app=app))`, then rolls
  back the transaction. Pattern is identical to
  `tests/features/users/0004_get_user_by_username/conftest.py`.

- **`seeded_user_with_tier`** (defined in the slice `conftest.py`): inserts one
  `Tier` row (`name="pro"`) and one `User` row (`username="tieruser"`,
  `name="Tier User"`, `email="tier@example.com"`, `tier_id=<inserted tier id>`,
  `is_deleted=False`) through the overridden session factory. Returns both ORM
  instances (or a named tuple). This fixture depends on `async_client` so the
  session is already overridden when the rows are inserted.

## Test scenarios

### Scenario 1: happy path — user has a tier

**Setup:**

- DB contains: one `Tier` row (`id=<auto>`, `name="pro"`) and one `User` row
  (`username="tieruser"`, `tier_id=<tier.id>`, `is_deleted=False`).
  Provided by the `seeded_user_with_tier` fixture.
- No mocks.

**Act:**

- `GET /api/v1/user/tieruser/tier`

**Expect:**

- Status: `200`.
- Response body is a JSON object (not `null`) with exactly three keys:
  `tier_id`, `tier_name`, `tier_created_at`.
- `tier_id` equals the seeded tier's `id`.
- `tier_name` equals `"pro"`.
- `tier_created_at` is an ISO-8601 datetime string.
- No extra keys present (no internal fields leaked).
- DB state: unchanged (read-only operation).

**Covers requirement(s):** F1, F2, F17.

---

### Scenario 2: user not found

**Setup:**

- DB contains no user with username `"ghost_xyz"`.
- No mocks.

**Act:**

- `GET /api/v1/user/ghost_xyz/tier`

**Expect:**

- Status: `404`.
- Response body: `{"error": {"code": "notfound", "message": "User not found"}}`.
- DB state: unchanged.

**Covers requirement(s):** F4, F6.

---

## Out of scope for this test

- User with no tier assigned (200 null response): covered by the endpoint
  integration test (`tests/features/users/0005_get_user_tier/presentation/test_router.py`).
- Dangling `tier_id` (tier row absent): covered by the endpoint integration test.
- Soft-delete filter: covered by the endpoint integration test.
- Adapter sentinel return logic (`UserNotFound`, `TierNotFound`): covered by
  adapter unit test and use-case unit test.
- Specific use-case branches beyond the two scenarios above: covered by
  use-case unit test.
- Field-level Pydantic validation errors: not applicable (no request body).
- Performance, load, concurrency.
