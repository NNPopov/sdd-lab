# 0007 · delete_user — Outside-in test spec

## Goal

Prove that an authenticated user can soft-delete their own account through the HTTP stack, that the user row is marked `is_deleted = True` in the database, and that the caller's access token appears in the `token_blacklist` table — and that an attempt to delete a different user's account is rejected with HTTP 403.

## Entry point

- **Method:** `DELETE`
- **Path:** `/api/v1/user/{username}`
- **Body:** none
- **Auth:** Bearer token (the caller's valid access token, obtained via `POST /api/v1/login`)

## Wired real

- FastAPI app from `create_app()` (full stack: all middleware, exception handlers, DI container).
- `DeleteUserAdapter` — queries and updates the `user` table in the test Postgres.
- `DeleteUserPort` — bound to `DeleteUserAdapter` in `Container`.
- `DeleteUserUseCase` — runs the existence check, ownership check, and soft-delete in sequence.
- `TokenBlacklistService` — writes the blacklisted token to the `token_blacklist` table in the test Postgres.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction connection.

## Mocked

None — the test runs entirely against the test database. There is no Redis cache, no external HTTP API, and no clock dependency in this slice.

## Fixtures used

- **`client`** (from `tests/conftest.py`): `httpx.AsyncClient` wired against the app with the test transaction.
- **`db_session`** (from `tests/conftest.py`): per-test async session; rolled back at teardown so no test row persists.
- **`registered_user`** (in `tests/features/users/0007_delete_user/conftest.py`): a factory fixture that calls `POST /api/v1/users` through `client` and returns the created username plus its raw password. Creates user `alice` with email `alice@example.com` and password `Pa$$w0rd1`.
- **`alice_token`** (in slice `conftest.py`): depends on `registered_user`; calls `POST /api/v1/login` through `client` and returns the raw Bearer token string for `alice`.

## Test scenarios

### Scenario 1: happy path — owner deletes their own account

**Setup:**

- DB contains: one user row for `alice` (`is_deleted = False`), seeded by the `registered_user` fixture.
- `alice_token` holds a valid Bearer token for `alice`.
- No rows in `token_blacklist` for this token before the call.

**Act:**

- Send `DELETE /api/v1/user/alice` with header `Authorization: Bearer <alice_token>`.

**Expect:**

- Status: `200`.
- Response body: `{"message": "User deleted"}`.
- DB state — `user` table: the row for `alice` has `is_deleted = True` and `deleted_at` is not null.
- DB state — `token_blacklist` table: a row exists whose `token` column matches `<alice_token>`.

**Covers requirements:** F1, F4, F6, F7.

---

### Scenario 2: requester attempts to delete a different user's account

**Setup:**

- DB contains: one user row for `alice` (`is_deleted = False`, from `registered_user`).
- DB contains: one user row for `bob` (`is_deleted = False`), seeded by an additional call to `POST /api/v1/users` with `username="bob"`, `email="bob@example.com"`, `password="Pa$$w0rd1"` inside the test body.
- `alice_token` holds a valid Bearer token for `alice`.

**Act:**

- Send `DELETE /api/v1/user/bob` with header `Authorization: Bearer <alice_token>`.

**Expect:**

- Status: `403`.
- Response body: `{"message": "Forbidden"}` or equivalent `ForbiddenDomainError` message from the exception handler.
- DB state — `user` table: the row for `bob` is unchanged (`is_deleted = False`, `deleted_at` is null).
- DB state — `token_blacklist` table: no new row was added (the use-case raised before token blacklisting was reached).

**Covers requirements:** F3, F9.

---

## Out of scope for this test

- `404` when the target username does not exist — covered by the endpoint integration test (`test_router.py`).
- `401` when no token or an expired token is provided — covered by the endpoint integration test.
- `404` when the user is already soft-deleted — covered by the adapter unit test and endpoint integration test.
- Field-level Pydantic validation errors — not applicable (DELETE has no request body).
- The exact SQLAlchemy SQL emitted by `soft_delete` — covered by the adapter unit test.
- Use-case branch ordering (existence check before ownership check) — covered by the use-case unit test.
- `TokenBlacklistService` JWT-decode behavior — covered by the `TokenBlacklistService` unit test.
- Performance, concurrency, or load.
