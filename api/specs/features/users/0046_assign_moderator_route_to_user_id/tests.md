# 0046 · assign_moderator_route_to_user_id — Outside-in test spec

## Goal

Prove that a superuser can grant moderator status to a user identified by an
**integer `user_id`** through `PATCH /api/v1/user/{user_id}/assign-moderator`,
and that re-assigning an existing moderator is rejected — end-to-end through the
full HTTP stack with the real adapter and the test Postgres.

## Entry point

- **Method:** `PATCH`
- **Path:** `/api/v1/user/{user_id}/assign-moderator`
- **Body:** none
- **Auth:** superuser. The test injects the acting superuser by overriding the
  `get_current_user` dependency with the `seeded_superuser` dict; the
  `get_current_superuser` dependency then resolves it as a superuser.

## Wired real

- FastAPI app from `app.main:app` (full stack: middleware, exception handlers).
- The slice's adapter (`AssignModeratorAdapter`).
- The slice's port (`AssignModeratorPort`, bound to the adapter in `Container`).
- The slice's use-case (`AssignModeratorUseCase`).
- Test Postgres via the `async_client` fixture (savepoint-mode transaction
  rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the test runs entirely against the test database. Only the
`get_current_user` dependency is overridden to supply the acting superuser
identity (auth, not an external system boundary).

## Fixtures used

- `async_client` (slice `conftest.py`): the `httpx.AsyncClient` against the app
  with per-test savepoint rollback.
- `seeded_target_user` (slice `conftest.py`): inserts one non-moderator `User`
  row (`username="targetmod"`, `is_moderator=False`) and returns its `id`.
- `seeded_superuser` (slice `conftest.py`): inserts a real superuser `User` row
  so the `moderator_granted_by_user_id` FK is satisfied; returns its `id`. Used
  both as the acting caller and as the expected grantor.

## Test scenarios

### Scenario 1: happy path — assign moderator by integer id

**Setup:**

- DB contains the `seeded_target_user` row (`is_moderator = false`) and the
  `seeded_superuser` row.
- `get_current_user` is overridden to return the `seeded_superuser` dict.

**Act:**

- `PATCH /api/v1/user/{seeded_target_user["id"]}/assign-moderator` with no body.

**Expect:**

- Status: `200`.
- Response body matches `AssignModeratorResponse`: `id == seeded_target_user["id"]`,
  `username == "targetmod"`, `is_moderator == true`, and the fields `name`,
  `email`, `profile_image_url`, `tier_id` present.
- Response body does **not** include `moderator_granted_by_user_id`.
- DB state: the target's `"user"` row has `is_moderator = true` and
  `moderator_granted_by_user_id == seeded_superuser["id"]`.

**Covers requirement(s):** F1, F5, F6, F7, F9, F10, F11.

### Scenario 2: conflict — target is already a moderator

**Setup:**

- DB contains the `seeded_target_user` row, promoted to moderator before the
  call (UPDATE `is_moderator = true`, `moderator_granted_by_user_id =
  seeded_superuser["id"]` inside the test transaction).
- `get_current_user` is overridden to return the `seeded_superuser` dict.

**Act:**

- `PATCH /api/v1/user/{seeded_target_user["id"]}/assign-moderator` with no body.

**Expect:**

- Status: `409`.
- Response body: `{"error": {"code": "duplicatevalue", "message": "User is already a moderator"}}`.
- DB state: the target's row is unchanged — `is_moderator` remains `true` and
  `moderator_granted_by_user_id` remains `seeded_superuser["id"]` (no second
  write).

**Covers requirement(s):** F8, F13.

## Red-state trigger

Before implementation, the route pattern is `/user/{username}/assign-moderator`.
A request to `/api/v1/user/{integer_id}/assign-moderator` matches the old route
with `username` bound to the integer's string form; the use-case then calls
`get_by_username("<id>")`, finds no such username, and returns `404`. Scenario 1
asserts `200` and therefore fails RED until the route is migrated to
`{user_id}` and the lookup uses `get_by_id`.

## Out of scope for this test

- 401 (missing token), 403 (non-superuser), and 422 (non-integer path param) —
  covered by the endpoint integration test.
- 404 for a genuinely non-existent `user_id` — covered by the endpoint
  integration and use-case unit tests.
- Specific SQLAlchemy exception variants — covered by the adapter unit test.
- The `requester_is_superuser=False` use-case branch — covered by the use-case
  unit test.
- Performance, load, concurrency.
