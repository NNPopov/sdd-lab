# 0044 · delete_user_route_to_user_id — Outside-in test spec

## Goal

Prove that `DELETE /api/v1/user/{user_id}` soft-deletes the authenticated
user's own account by integer ID, blacklists the access token in the DB, and
rejects a deletion attempt targeting another user's ID with HTTP 403.

## Entry point

- **Method:** `DELETE`
- **Path:** `/api/v1/user/{user_id}` (where `user_id` is the integer primary
  key of the target account)
- **Auth:** Bearer JWT (the requester's own access token)

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `DeleteUserAdapter` — queries and soft-deletes by `User.id`.
- `DeleteUserPort` — bound to `DeleteUserAdapter` in `Container`.
- `DeleteUserUseCase` — enforces existence and ownership checks.
- `TokenBlacklistAdapter` — writes the blacklist entry to the test Postgres.
- Test Postgres via the `async_client` fixture (savepoint-based transaction
  rollback per test; the `session_factory` provider is overridden to use the
  test connection).
- DI container with `session_factory` overridden.

## Mocked

- **`get_current_user` dependency:** overridden via
  `app.dependency_overrides[get_current_user] = lambda: seeded_alice` (or
  `seeded_alice` identity) so that JWT verification is bypassed while the
  token string itself is still forwarded to `blacklist_token`. The override
  is reset in `finally`.

Everything else (adapter, use-case, token blacklist write) runs against the
real test database.

## Fixtures used

- `async_client` (from slice `conftest.py`): `httpx.AsyncClient` wired to the
  app with savepoint rollback; overrides `container.session_factory`.
- `seeded_alice` (from slice `conftest.py`): dict `{"id": <int>, "username":
  "alice", ...}` — the alice user row, inserted inside the test transaction.
- `seeded_bob` (from slice `conftest.py`, Scenario 2 only): dict `{"id":
  <int>, "username": "bob", ...}` — the bob user row.
- `alice_token` (from slice `conftest.py`): a valid JWT string for alice,
  used as the Bearer token value passed to the `Authorization` header and
  forwarded to `blacklist_token`.

## Test scenarios

### Scenario 1: happy path — owner deletes their own account by integer ID

**Setup:**

- `seeded_alice` row exists in the test DB (`is_deleted = false`).
- `get_current_user` overridden to return `seeded_alice`.

**Act:**

- `DELETE /api/v1/user/{seeded_alice["id"]}` with header
  `Authorization: Bearer <alice_token>`.

**Expect:**

- Status: `200`.
- Response body: `{"message": "User deleted"}`.
- DB state: alice's row has `is_deleted = true` and `deleted_at` is non-null
  (verified by raw SQL on the test session after the request).
- DB state: a row with `token = alice_token` exists in the `token_blacklist`
  table (token was blacklisted before the response was returned).

**Covers requirement(s):** F1, F7, F9, F10, F11, F12.

---

### Scenario 2: forbidden — alice attempts to delete bob's account

**Setup:**

- Both `seeded_alice` and `seeded_bob` rows exist in the test DB.
- `get_current_user` overridden to return `seeded_alice` (alice is the
  requester).

**Act:**

- `DELETE /api/v1/user/{seeded_bob["id"]}` with header
  `Authorization: Bearer <alice_token>`.

**Expect:**

- Status: `403`.
- Response body: `{"error": {"code": "forbidden", "message": ""}}`.
- DB state: bob's row is unchanged — `is_deleted` remains `false` (verified
  by raw SQL).
- DB state: no row with `token = alice_token` exists in `token_blacklist`
  (blacklisting only happens after a successful use-case return, which never
  occurred).

**Covers requirement(s):** F5, F6, F8, F14.

## Out of scope for this test

- HTTP 422 for non-integer `user_id` — covered by the endpoint integration
  test in `presentation/test_router.py`.
- HTTP 401 for missing or invalid token — covered by the endpoint integration
  test.
- HTTP 404 for a non-existent `user_id` — covered by the use-case unit test
  (NotFoundDomainError) and the endpoint integration test (404 status code
  assertion).
- Individual SQLAlchemy exception propagation paths — covered by the adapter
  unit test.
- Branches inside `check_owner` beyond the two IDs-differ / IDs-match cases
  above — covered by the use-case unit test.
- Performance, concurrency, load.
