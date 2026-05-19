# 0027 · migrate_di_wiring — Outside-in test spec

## Goal

Verify that after the DI wiring migration, `Provide[Container.x]` injections in slice routers and `shared_dependencies.py` resolve to actual instances — not to the provider sentinel — and that observable HTTP behaviour is preserved end-to-end across both wiring categories introduced by this slice.

## Entry points

Two representative entry points, one per wiring category under test:

**Category A** — router with a single `Provide[...]` parameter, no auth:

- **Method:** `POST`
- **Path:** `/api/v1/user`
- **Body:** `CreateUserRequest`
- **Auth:** none

**Category B** — authenticated endpoint that exercises `shared_dependencies.get_current_user` with its `Provide[Container.token_blacklist_adapter]` without any auth mock:

- **Method:** `GET`
- **Path:** `/api/v1/user/me/`
- **Auth:** Bearer token

## Wired real

- FastAPI app from `app.main.app` (full stack: middleware, exception handlers).
- `CreateUserAdapter` bound to `Container.create_user_use_case` — no override.
- `TokenBlacklistAdapter` bound to `Container.token_blacklist_adapter` — no override.
- `CreateUserUseCase` and any use-case behind `/user/me/` — no override.
- Test Postgres via `oit_engine` and `async_client` fixtures (savepoint-mode transaction rollback per test).
- DI container with `session_factory` overridden to use the test connection.
- `async_get_db` FastAPI dependency overridden with the same test connection so `get_current_user`'s DB queries see test-seeded data.

## Mocked

None — the test runs entirely against the test database. The token blacklist adapter writes to the `token_blacklist` table, not Redis. No external HTTP APIs are called.

## Fixtures used

- `oit_engine` (in slice `conftest.py`): per-test async engine; `Base.metadata.create_all` run once to ensure schema exists.
- `_oit_connection` (in slice `conftest.py`): single connection shared by `async_client` and `oit_db_session`; outer transaction rolled back at teardown.
- `async_client` (in slice `conftest.py`): `AsyncClient` with `ASGITransport`; overrides `container.session_factory` and `async_get_db` to use `_oit_connection` in savepoint mode.
- `oit_db_session` (in slice `conftest.py`): `AsyncSession` on `_oit_connection` for direct DB-state assertions.

No slice-specific factory fixtures are needed — both scenarios seed data through the HTTP API.

## Test scenarios

### Scenario 1: Basic router wiring — create user (no auth)

**Setup:**

- DB contains: no rows (fresh test transaction).
- Mocks configured: none.

**Act:**

- `POST /api/v1/user` with body `{"name": "Wiring Tester", "username": "wiringtester", "email": "wiring@example.com", "password": "Pa$$w0rd1"}`.

**Expect:**

- Status: `201`.
- Response body contains `id` (int), `username == "wiringtester"`, `email == "wiring@example.com"`.
- DB state: a row exists in `user` with `username == "wiringtester"`.

If `Provide[Container.create_user_use_case]` resolved to the sentinel object instead of the use-case instance, the endpoint would raise `AttributeError` and return `500`. A `201` proves the injection resolved correctly.

**Covers requirement(s):** F1, F4, F6, F10, F13.

---

### Scenario 2: Shared-dependencies wiring — authenticated request without auth mock

**Setup:**

- DB contains: user `wiringtester2` inserted by calling `POST /api/v1/user` with `{"name": "Wiring Tester 2", "username": "wiringtester2", "email": "wiring2@example.com", "password": "Pa$$w0rd2"}` (expect 201).
- Access token obtained by calling `POST /api/v1/login` with credentials `username=wiring2@example.com, password=Pa$$w0rd2` (expect 200; capture `access_token` from response JSON).
- Mocks configured: none — `get_current_user` is NOT overridden via `app.dependency_overrides`.

**Act:**

- `GET /api/v1/user/me/` with header `Authorization: Bearer <access_token>`.

**Expect:**

- Status: `200`.
- Response body contains `username == "wiringtester2"` and `is_superuser == False`.
- DB state: no row in `token_blacklist` for `<access_token>` (token was not blacklisted by this request).

This scenario runs `shared_dependencies.get_current_user` for real, including its `Provide[Container.token_blacklist_adapter]` injection. If that injection resolved to the sentinel, the blacklist check would raise `AttributeError` and return `500`. A `200` proves the shared-dependencies wiring is correct.

**Covers requirement(s):** F1, F5, F8, F9, F10, F13.

---

## Out of scope for this test

- Verifying all 17 router modules individually — the existing outside-in tests for each slice cover this exhaustively and serve as the full regression gate (F13).
- Token blacklisting on delete or logout (covered by `0007_delete_user` and `0025_refactor_token_blacklist` outside-in tests).
- The two-provider case in `delete_user` router (`Container.delete_user_use_case` + `Container.token_blacklist_adapter`) — verified by `0007_delete_user_outside_in_test.py` remaining green.
- Import-level circular-import errors (covered by `tests/smoke/test_app_starts.py`, which runs as part of every `pytest` invocation).
- Field-level validation errors (covered by existing endpoint integration tests).
- Performance, load, concurrency.
