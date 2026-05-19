# 0025 · refactor_token_blacklist — Outside-in test spec

## Goal

Prove that after the architectural refactor the token-blacklist flow works
end-to-end through HTTP — a token blacklisted on logout is rejected on a
subsequent authenticated request with 401, a fresh token is accepted with 200,
and the architecture gate reports `KEPT` for `Core must not import Adapters`.

## Entry point

Three scenarios use different HTTP calls and one subprocess call:

| Scenario | Call |
|---|---|
| 1 — blacklisted token rejected | `POST /api/v1/login`, `POST /api/v1/logout`, `GET /api/v1/user/me/` |
| 2 — valid token accepted | `POST /api/v1/login`, `GET /api/v1/user/me/` |
| 3 — architecture gate | subprocess: `python scripts/check_arch.py` |

Supporting setup call used in both HTTP scenarios:

- **Method:** `POST`
- **Path:** `/api/v1/user`
- **Body:** `CreateUserRequest` — `name`, `username`, `email`, `password`
- **Auth:** none

Login call:

- **Method:** `POST`
- **Path:** `/api/v1/login`
- **Body:** `application/x-www-form-urlencoded` — `username` (accepts email), `password`
- **Auth:** none

Logout call:

- **Method:** `POST`
- **Path:** `/api/v1/logout`
- **Body:** none
- **Auth:** `Authorization: Bearer <access_token>` + `refresh_token` HttpOnly cookie

Authenticated endpoint:

- **Method:** `GET`
- **Path:** `/api/v1/user/me/`
- **Auth:** `Authorization: Bearer <access_token>`

## Wired real

- FastAPI app from `app.main.app` (full stack: middleware, exception handlers).
- `TokenBlacklistAdapter` — wired to `Container.token_blacklist_adapter` after the refactor.
- `TokenBlacklistPort` — bound to the adapter in the DI container.
- `get_current_user` in `shared_dependencies.py` — injects `blacklist: TokenBlacklistPort`
  via `Depends(Provide[Container.token_blacklist_adapter])` and passes it to `verify_token`.
- `verify_token` in `core/security.py` — delegates blacklist check to the port.
- `CreateUserUseCase` and `CreateUserAdapter` — used only for the seed step.
- Test Postgres via `oit_engine` fixture (transaction rollback per test).
- DI container `session_factory` overridden to use the test transaction connection.

## Mocked

None — the test runs entirely against the test database. Redis is not involved
in the token-blacklist path. No clock mocking is needed because token expiry
within the test window is not a concern (tokens expire in minutes/days, the
test runs in milliseconds).

## Fixtures used

- `async_client` (from slice `conftest.py`): `httpx.AsyncClient` wired to the
  app via `ASGITransport`. The underlying connection is bound to a per-test
  transaction that rolls back at teardown. The DI container's `session_factory`
  is overridden to use a savepoint-based factory on the same connection, so all
  adapter writes (including `token_blacklist` rows) are visible within the test
  and rolled back after.
- `oit_db_session` (from slice `conftest.py`): an `AsyncSession` bound to the
  same connection as `async_client`, used for direct DB-state assertions within
  a scenario. Must be created from the same `connection` object, not a fresh
  connection, so it can see writes committed by the adapter's savepoints.

## Test scenarios

### Scenario 1: blacklisted access token is rejected on authenticated request

**Setup:**

- DB contains no users.

**Act (sequential steps):**

1. `POST /api/v1/user` with body
   `{"name": "Alice Auth", "username": "aliceauth", "email": "alice.auth@example.com", "password": "Pa$$w0rd1"}`.
   Expect 201. Discard response body.
2. `POST /api/v1/login` with form data
   `username=alice.auth@example.com`, `password=Pa$$w0rd1`.
   Expect 200. Extract `access_token` from response body.
   The client stores the `refresh_token` HttpOnly cookie automatically.
3. `POST /api/v1/logout` with header `Authorization: Bearer <access_token>`.
   The client sends the stored `refresh_token` cookie automatically.
   Expect 200, body `{"message": "Logged out successfully"}`.
4. `GET /api/v1/user/me/` with header `Authorization: Bearer <access_token>`
   (same token as step 2, now blacklisted).

**Expect:**

- Step 4 status: `401`.
- Step 4 response body: `{"detail": "User not authenticated."}`.
- DB state: a row exists in `token_blacklist` with `token` equal to the
  `access_token` extracted in step 2. This is confirmed indirectly by the
  401 response (which proves `is_blacklisted` returned `True`), but may also
  be asserted directly via `oit_db_session` querying
  `SELECT EXISTS (SELECT 1 FROM token_blacklist WHERE token = :token)`.

**Covers requirement(s):** F21, F17, F10, F9, F15.

---

### Scenario 2: valid (non-blacklisted) token is accepted on authenticated request

**Setup:**

- DB contains no users.

**Act (sequential steps):**

1. `POST /api/v1/user` with body
   `{"name": "Bob Valid", "username": "bobvalid", "email": "bob.valid@example.com", "password": "Pa$$w0rd2"}`.
   Expect 201.
2. `POST /api/v1/login` with form data
   `username=bob.valid@example.com`, `password=Pa$$w0rd2`.
   Expect 200. Extract `access_token` from response body.
3. `GET /api/v1/user/me/` with header `Authorization: Bearer <access_token>`.

**Expect:**

- Step 3 status: `200`.
- Step 3 response body matches `UserMeRead` shape:
  `username == "bobvalid"`, `email == "bob.valid@example.com"`,
  `is_superuser == False`, `is_moderator == False`.
- DB state: no row in `token_blacklist` (no logout was performed).

**Covers requirement(s):** F21, F15, F9.

---

### Scenario 3: architecture gate — `Core must not import Adapters` is KEPT

**Setup:**

- No DB state required. This scenario runs entirely as a subprocess check.

**Act:**

- `subprocess.run(["python", "scripts/check_arch.py"], capture_output=True, text=True,
  cwd=<project_root>)`

**Expect:**

- `process.returncode == 0`.
- `"KEPT"` appears in `process.stdout` for the contract
  `Core must not import Adapters`. The exact string to search for is
  `"Core must not import Adapters"` with `"KEPT"` on the same output line
  or in proximity (match the format produced by `check_arch.py`).
- No previously-KEPT contract appears as `BROKEN` in the output (guard
  against regressions in other contracts).

**Covers requirement(s):** F22, F12, N5.

## Out of scope for this test

- Field-level Pydantic validation errors on login/logout/user-create (covered
  by endpoint integration tests).
- `TokenBlacklistAdapter` exception propagation (covered by the adapter unit
  test in `tests/adapters/db/token_blacklist/test_adapter.py`).
- Blacklisted refresh token rejected on `POST /api/v1/refresh` (covered by
  the endpoint integration test in `tests/features/auth/test_auth.py`).
- Branches inside `verify_token` beyond the blacklist check (covered by unit
  tests on `security.py` if added, or implicitly by the integration test).
- Performance, load, concurrency.
