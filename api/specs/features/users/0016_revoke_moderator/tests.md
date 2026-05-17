# 0016 · revoke_moderator — Outside-in test spec

## Goal

Prove that a superuser can demote a moderator through the HTTP API, that the
database row is updated (`is_moderator = False`, `moderator_granted_by_user_id
= None`), and that the revocation is immediately visible on the read path —
and that attempting to revoke a user who is not currently a moderator returns
HTTP 409 with a clear error message.

## Entry point

The HTTP call the test makes.

- **Method:** `PATCH`
- **Path:** `/api/v1/users/{username}/revoke-moderator`
- **Body:** none
- **Auth:** Bearer token for a superuser account

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `RevokeModeratorAdapter` — the slice's concrete SQLAlchemy adapter.
- `RevokeModeratorPort` — bound to the adapter in `Container`.
- `RevokeModeratorUseCase` — the slice's use-case.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.
- The `assign_moderator` stack (slice 0015) — called during setup to promote
  the target user before the revocation test runs.

## Mocked

None — the test runs entirely against the test database. No external HTTP APIs,
Redis, or clock dependencies are touched by this slice.

## Fixtures used

- `client` (from `tests/conftest.py`): the `httpx.AsyncClient` bound to the
  running app with the test transaction session.
- `db_session`: the per-test transaction; used for direct DB assertions.
- Superuser fixture (from `tests/conftest.py` or the slice's `conftest.py`):
  seeds a user row with `is_superuser = True` and supplies a valid Bearer
  token. If no project-wide superuser fixture exists, the test creates a user
  via `POST /api/v1/users` and then flips `is_superuser = True` directly on
  the DB row via `db_session`, then obtains a token via the login endpoint.

## Test scenarios

### Scenario 1: happy path — revoke moderator, assert DB and read path

**Setup:**

1. Create a target user via `POST /api/v1/users` with
   `username="bob"`, `email="bob@example.com"`, `password="Pa$$w0rd1"`.
2. Obtain a superuser Bearer token (via the superuser fixture or login
   endpoint).
3. Promote `bob` to moderator by calling
   `PATCH /api/v1/user/bob/assign-moderator` with the superuser token
   (slice 0015 endpoint); assert HTTP 200 to confirm setup succeeded.

**Act:**

- `PATCH /api/v1/users/bob/revoke-moderator` with `Authorization: Bearer <superuser_token>`.

**Expect:**

- Status: `200`.
- Response body fields:
  - `username == "bob"`
  - `is_moderator == false`
  - `id`, `name`, `email`, `profile_image_url`, `tier_id` match the user
    created in setup.
- DB state (queried via `db_session`): the `user` row for `username="bob"` has
  `is_moderator = False` **and** `moderator_granted_by_user_id = None`.
- Read-path confirmation: `GET /api/v1/users/user/bob` (unauthenticated)
  returns HTTP 200 with `is_moderator == false`.

**Covers requirement(s):** F6, F7, F8, F12, F15.

---

### Scenario 2: target user is not currently a moderator — 409

**Setup:**

1. Create a target user via `POST /api/v1/users` with
   `username="carol"`, `email="carol@example.com"`, `password="Pa$$w0rd2"`.
   Do **not** call assign-moderator; `carol.is_moderator` defaults to `False`.
2. Obtain a superuser Bearer token.

**Act:**

- `PATCH /api/v1/users/carol/revoke-moderator` with `Authorization: Bearer <superuser_token>`.

**Expect:**

- Status: `409`.
- Response body: `{"message": "User is not a moderator"}`.
- DB state: the `user` row for `username="carol"` is unchanged —
  `is_moderator` is still `False`, `moderator_granted_by_user_id` is still
  `None`.

**Covers requirement(s):** F5, F14.

## Out of scope for this test

- 401 / 403 auth failures (covered by endpoint integration test).
- 404 unknown username (covered by endpoint integration test).
- Use-case second-layer `ForbiddenDomainError` check (covered by use-case unit
  test; not reachable through the HTTP stack when the router-level guard fires
  first).
- Adapter `get_by_username` not-found and soft-deleted-user paths (covered by
  adapter unit test).
- Specific SQLAlchemy exception propagation (covered by adapter unit test; no
  adapter catches are present in this slice).
- Performance, load, concurrency.
