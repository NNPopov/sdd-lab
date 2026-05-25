# 0049 · rate_limits_route_to_user_id — Outside-in test spec

## Goal

Prove that `GET /api/v1/user/{user_id}/rate_limits`, called by a superuser with
an integer `user_id`, returns HTTP 200 with the user's data and the rate-limit
rows for the user's tier — and returns HTTP 404 for an unknown `user_id` —
exercising the full HTTP stack with the real repositories and the test Postgres.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/user/{user_id}/rate_limits`
- **Body:** none
- **Auth:** superuser. The route declares `Depends(get_current_superuser)`. The
  test satisfies it by overriding the `get_current_user` dependency with a lambda
  that returns a seeded superuser identity dict (the established pattern in
  `tests/features/users/0016_revoke_moderator/revoke_moderator_outside_in_test.py`).

## Wired real

- FastAPI app from `app.main:app` (full stack: middleware, exception handlers).
- The free function `read_user_rate_limits` (no port/adapter/use-case class — this
  endpoint is a shallow aggregator).
- The shared FastCRUD repositories `crud_users`, `crud_tiers`, `crud_rate_limits`.
- Test Postgres via the `async_client` fixture (savepoint-mode transaction
  rollback per test).
- DI container with `session_factory` overridden to the test transaction.

## Mocked

- **Auth identity:** `app.features.users.dependencies.get_current_user` is
  overridden via `app.dependency_overrides` to return the seeded superuser dict,
  so `get_current_superuser` passes without a real login. This is the auth
  boundary, not the slice's own logic.
- No external HTTP APIs or Redis are touched. Everything else runs against the
  test database.

## Fixtures used

- `oit_engine` / `async_client` (slice `conftest.py`): the `httpx.AsyncClient`
  against the app with per-test savepoint rollback. Copy verbatim from
  `agent_docs/testing.md` § Fixtures.
- **Fat-handler override (mandatory):** `read_user_rate_limits` injects the
  session via `Depends(async_get_db)`, bypassing the DI container. The slice
  `conftest.py` must override **both** `container.session_factory` **and**
  `app.dependency_overrides[async_get_db]` so the function and any container-wired
  code share the same savepoint transaction. Per `agent_docs/testing.md`
  § Fat-handler migration slices. Without the `async_get_db` override the seeded
  rows are invisible to the function (or get committed to the real DB).
- `seeded_superuser` (slice `conftest.py`): inserts a `User` row with
  `is_superuser=True`; returns its identity dict (used for the dependency
  override).
- `seeded_user_with_tier` (slice `conftest.py`): inserts a tier row (e.g.
  `name="pro"`), a rate-limit row referencing that tier (e.g.
  `name="pro_login", path="login", limit=10, period=60`), and a `User` row with
  `tier_id` pointing at that tier; returns the user dict including `id`.

## Test scenarios

### Scenario 1: happy path — superuser reads a user's rate limits by id

**Setup:**

- DB contains: a tier `pro`, a rate-limit row for that tier, and a user linked to
  `pro` (from `seeded_user_with_tier`); a superuser (from `seeded_superuser`).
- Override `get_current_user` → returns the `seeded_superuser` dict.

**Act:**

- `GET /api/v1/user/{user_id}/rate_limits` where `user_id` is
  `seeded_user_with_tier["id"]`, with the auth override in place.

**Expect:**

- Status: `200`.
- Response body carries the user fields (`id` equals the seeded user id,
  `username`, `name`, `email`, `profile_image_url`, `tier_id` equal to the `pro`
  tier id) plus a `tier_rate_limits` list with at least one entry whose fields
  match the seeded rate-limit row (e.g. `name == "pro_login"`).
- DB state: read-only endpoint, no writes; the seeded rate-limit row still exists
  for the tier (confirms the response reflects real DB rows, not a fabricated
  payload).

**Covers requirement(s):** F1, F3, F6, F7.

### Scenario 2: unknown user_id returns 404

**Setup:**

- DB contains the superuser (from `seeded_superuser`) and no user with id
  `999999`.
- Override `get_current_user` → returns the `seeded_superuser` dict.

**Act:**

- `GET /api/v1/user/999999/rate_limits` with the auth override in place.

**Expect:**

- Status: `404`.
- Response body: `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers requirement(s):** F4, F9.

## Red-state trigger

Before implementation, the route is `GET /user/{username}/rate_limits` and the
function looks the user up via `crud_users.get(username=username, ...)`. A request
to `/api/v1/user/{int_id}/rate_limits` binds `username` to the id's string form;
`crud_users.get(username="<id>")` finds no row, so the function raises
`NotFoundDomainError("User not found")` and the call returns 404. Scenario 1's
`200` assertion therefore fails RED until the route is migrated to `{user_id}`
and the lookup uses `id=user_id`. (Scenario 2 may already pass in the red state —
the red signal comes from Scenario 1, per `agent_docs/testing.md` § Fat-handler
migration slices.)

## Out of scope for this test

- 401 (no credentials) and 403 (non-superuser) — covered by the endpoint
  integration test.
- 422 (non-integer path param) — covered by the endpoint integration test.
- The "user has no tier → `tier_rate_limits == []`" branch and the "tier row
  absent → Tier not found" branch — covered by the function-level unit test and
  the endpoint integration test.
- Performance, load, concurrency.
