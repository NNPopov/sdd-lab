# 0015 · assign_moderator — Outside-in test spec

## Goal

Prove that a superuser can call `PATCH /user/{username}/assign-moderator`, that
the target user's `is_moderator` flag is persisted to the database with the
grantor's ID recorded, and that the updated state is immediately visible through
the `GET /user/{username}` read path.

## Entry point

- **Method:** `PATCH`
- **Path:** `/api/v1/user/{username}/assign-moderator`
- **Body:** none
- **Auth:** Bearer token belonging to a superuser

## Wired real

- FastAPI app from `create_app()` (full middleware and exception handler stack).
- `AssignModeratorAdapter` (DB read + UPDATE).
- `AssignModeratorPort` (bound to the adapter in `Container`).
- `AssignModeratorUseCase`.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.
- `GetUserByUsernameAdapter` and `GetUserByUsernameUseCase` (read path, scenario 1
  step 5 — wired real to confirm persistence).

## Mocked

None — the test runs entirely against the test database. No Redis, no external
HTTP calls, no clock patching.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` bound to the app
  with the test transaction injected.
- `db_session`: the per-test Postgres transaction (rolled back at teardown).
- `superuser_factory` (in `tests/features/users/0015_assign_moderator/conftest.py`):
  creates a user row via `POST /api/v1/users` and then sets `is_superuser=TRUE`
  directly on the row through `db_session`. Yields `(username, password, id)`.
- `regular_user_factory` (same conftest, or reuse existing): creates a normal
  user row via `POST /api/v1/users`. Yields `(username, password, id)`.

The factories use the `client` fixture and `db_session` to stay inside the
same database transaction so the rollback cleans everything up.

## Test scenarios

### Scenario 1: happy path — assign moderator, verify response and persistence

**Setup:**

- DB contains a regular user `"target_user"` with `is_moderator=False` (seeded
  by `regular_user_factory`).
- DB contains a superuser `"admin_user"` with `is_superuser=True`
  (seeded by `superuser_factory`). Record this user's `id` as `superuser_id`.
- Obtain a Bearer token for `admin_user` via
  `POST /api/v1/auth/login` with `username="admin_user"` and the factory
  password. Store as `superuser_token`.

**Act:**

- `PATCH /api/v1/user/target_user/assign-moderator` with
  `Authorization: Bearer {superuser_token}` and no request body.

**Expect:**

- Status: `200`.
- Response body matches `AssignModeratorResponse`:
  - `is_moderator == True`
  - `username == "target_user"`
  - `id`, `name`, `email`, `profile_image_url` are present and non-null.
  - `tier_id` is present (may be `null`).
  - `moderator_granted_by_user_id` is **absent** from the response body.
- DB state (query through `db_session`):
  - `user.is_moderator == True` for `username="target_user"`.
  - `user.moderator_granted_by_user_id == superuser_id`.

**Additional read-path step (still part of scenario 1):**

- `GET /api/v1/user/target_user` with no Authorization header.
- Expect status `200` and `"is_moderator": true` in the response body,
  confirming the change is visible through the independent read path.

**Covers requirements:** F1, F7, F9, F10, F11, F12, F13, F14.

---

### Scenario 2: duplicate assignment — 409 when target is already a moderator

**Setup:**

- DB contains a regular user `"target_user"` with `is_moderator=False` (seeded
  by `regular_user_factory`).
- DB contains a superuser `"admin_user"` (seeded by `superuser_factory`). Obtain
  `superuser_token` as in Scenario 1.
- Call `PATCH /api/v1/user/target_user/assign-moderator` once to promote the
  user (this first call is setup, not the assertion).
- Record the current `moderator_granted_by_user_id` from `db_session` for
  assertion after the second call.

**Act:**

- Call `PATCH /api/v1/user/target_user/assign-moderator` a **second time** with
  the same `superuser_token`.

**Expect:**

- Status: `409`.
- Response body: `{"message": "User is already a moderator"}`.
- DB state: unchanged — `is_moderator` is still `True` and
  `moderator_granted_by_user_id` is unchanged from after the first call.

**Covers requirements:** F6, F19.

---

## Out of scope for this test

- 401 (unauthenticated) and 403 (non-superuser) paths — covered by the
  endpoint integration test.
- 404 (user not found) — covered by the endpoint integration test and
  adapter unit test.
- Soft-deleted user lookup exclusion — covered by the adapter unit test.
- Specific SQLAlchemy exception variants — covered by the adapter unit test.
- `ForbiddenDomainError` from the use-case second-layer check
  (`requester_is_superuser=False`) — covered by the use-case unit test; the
  outside-in test relies on `get_current_superuser` as the outer gate.
- Performance, load, concurrency.
