# 0050 · update_user_tier_route_to_user_id — Outside-in test spec

## Goal

Prove that `PATCH /api/v1/user/{user_id}/tier`, called by a superuser with an
integer `user_id` and a `{"tier_id": <id>}` body, updates the user's tier and
returns HTTP 200 with the success message — with the change visible through a
follow-up `GET /api/v1/user/{user_id}/tier` (slice 0048) — and returns HTTP 404
for an unknown `user_id`, exercising the full HTTP stack with the real
repositories and the test Postgres.

## Entry point

- **Method:** `PATCH`
- **Path:** `/api/v1/user/{user_id}/tier`
- **Body:** `UserTierUpdate` (`{"tier_id": <int>}`)
- **Auth:** superuser. The route declares `Depends(get_current_superuser)`. The
  test satisfies it by overriding the `get_current_user` dependency with a lambda
  that returns a seeded superuser identity dict (the established pattern in
  `tests/features/users/0049_rate_limits_route_to_user_id/`).

## Wired real

- FastAPI app from `app.main:app` (full stack: middleware, exception handlers).
- The free function `patch_user_tier` (no port/adapter/use-case class — this
  endpoint is a shallow aggregator).
- The free function `get_user_tier` route handler (slice 0048) used to verify
  the persisted change.
- The shared FastCRUD repositories `crud_users`, `crud_tiers`.
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
- **Fat-handler override (mandatory):** `patch_user_tier` injects the session via
  `Depends(async_get_db)`, bypassing the DI container. The slice `conftest.py`
  must override **both** `container.session_factory` **and**
  `app.dependency_overrides[async_get_db]` so the function and any container-wired
  code share the same savepoint transaction. Per `agent_docs/testing.md`
  § Fat-handler migration slices. Without the `async_get_db` override the seeded
  rows are invisible to the function (or get committed to the real DB).
- `seeded_superuser` (slice `conftest.py`): inserts a `User` row with
  `is_superuser=True`; returns its identity dict (used for the dependency
  override).
- `seeded_user_and_tier` (slice `conftest.py`): inserts a tier row (e.g.
  `name="pro"`) and a `User` row (initially with `tier_id=None` or a different
  tier); returns the user dict including `id` and the tier id.

## Test scenarios

### Scenario 1: happy path — superuser updates a user's tier by id

**Setup:**

- DB contains: a tier `pro` and a user (from `seeded_user_and_tier`); a superuser
  (from `seeded_superuser`).
- Override `get_current_user` → returns the `seeded_superuser` dict.

**Act:**

- `PATCH /api/v1/user/{user_id}/tier` where `user_id` is
  `seeded_user_and_tier["id"]`, with body `{"tier_id": <pro tier id>}` and the
  auth override in place.
- Then `GET /api/v1/user/{user_id}/tier` for the same `user_id` (slice 0048).

**Expect:**

- PATCH status: `200`.
- PATCH response body: `{"message": "User <name> Tier updated"}` where `<name>`
  is the seeded user's `name`.
- GET status: `200`, and its body reflects the updated tier (`tier_id` /
  tier name equal to the `pro` tier just assigned).
- DB state: the `user` row for `user_id` has `tier_id` equal to the `pro` tier id
  (confirms the update was persisted, not just echoed in the message).

**Covers requirement(s):** F1, F2, F3, F6, F7.

### Scenario 2: unknown user_id returns 404

**Setup:**

- DB contains the superuser (from `seeded_superuser`), the `pro` tier, and no
  user with id `999999`.
- Override `get_current_user` → returns the `seeded_superuser` dict.

**Act:**

- `PATCH /api/v1/user/999999/tier` with body `{"tier_id": <pro tier id>}` and the
  auth override in place.

**Expect:**

- Status: `404`.
- Response body: `{"error": {"code": "notfound", "message": "User not found"}}`.
- DB state: no user row is created or modified.

**Covers requirement(s):** F4, F9.

## Red-state trigger

Before implementation, the route is `PATCH /user/{username}/tier` and the
function looks the user up via `crud_users.get(username=username, ...)` and
updates via `crud_users.update(..., username=username)`. A request to
`/api/v1/user/{int_id}/tier` binds `username` to the id's string form;
`crud_users.get(username="<id>")` finds no row, so the function raises
`NotFoundDomainError("User not found")` and the call returns 404. Scenario 1's
`200` assertion therefore fails RED until the route is migrated to `{user_id}`
and both the lookup and the update use `id=user_id`. (Scenario 2 may already pass
in the red state — the red signal comes from Scenario 1, per
`agent_docs/testing.md` § Fat-handler migration slices.)

## Out of scope for this test

- 401 (no credentials) and 403 (non-superuser) — covered by the endpoint
  integration test.
- 422 (non-integer path param or malformed body) — covered by the endpoint
  integration test.
- The "tier row absent → Tier not found" branch — covered by the function-level
  unit test and the endpoint integration test.
- Performance, load, concurrency.
