# 0006 · update_user — Outside-in test spec

## Goal

Prove that an authenticated user can update their own profile fields through
`PATCH /api/v1/user/{username}`, and that a user who does not own the target
profile receives `403 Forbidden`.

## Entry point

- **Method:** `PATCH`
- **Path:** `/api/v1/user/{username}` — `{username}` is the path param of the
  profile being updated.
- **Body:** JSON matching `UpdateUserRequest` (all fields optional).
- **Auth:** Bearer token in `Authorization` header, obtained by calling
  `POST /api/v1/login` with the owner's credentials as part of test setup.

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `UpdateUserAdapter` — queries and updates the `users` table via SQLAlchemy.
- `UpdateUserPort` — bound to `UpdateUserAdapter` in `Container`.
- `UpdateUserUseCase` — runs ownership check, duplicate checks, delegates
  write to port.
- `check_owner` — called by the use case from `_shared/policies.py`.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the test runs entirely against the test database. No Redis, no
external HTTP, no clock patching required.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` bound to the app
  with the test transaction.
- `db_session`: the per-test transaction, rolled back after each test.
- `existing_user` (in `tests/features/users/0006_update_user/conftest.py`):
  inserts one `users` row with known credentials:
  `username="alice"`, `email="alice@example.com"`, `name="Alice"`,
  `hashed_password=get_password_hash("Str1ngst!")`, `is_deleted=False`.
  Returns the inserted row dict.
- `other_user` (same conftest): inserts a second row:
  `username="bob"`, `email="bob@example.com"`, `name="Bob"`,
  `hashed_password=get_password_hash("Str1ngst!")`, `is_deleted=False`.
- `alice_token` (same conftest): calls
  `POST /api/v1/login` with `username=alice&password=Str1ngst!` through the
  `client`, extracts and returns the `access_token` string.
- `bob_token` (same conftest): same pattern for `bob`.

Note: `existing_user` and `other_user` must insert directly into the
`db_session` transaction (not via the create-user endpoint) so that the
password hash is known and the login call can succeed.

## Test scenarios

### Scenario 1: happy path — owner updates their own profile

**Setup:**

- DB contains: one `alice` row (from `existing_user` fixture).
- `alice_token` obtained from login.

**Act:**

- `PATCH /api/v1/user/alice`
- Headers: `Authorization: Bearer <alice_token>`, `Content-Type: application/json`
- Body: `{"name": "Alice Updated"}`

**Expect:**

- Status: `200 OK`.
- Response body: `{"message": "User updated"}`.
- DB state: the `alice` row in `users` now has `name == "Alice Updated"`.
  All other fields (`username`, `email`, `profile_image_url`) are unchanged.

**Covers requirement(s):** F1, F13.

---

### Scenario 2: most important failure path — wrong owner is forbidden

**Setup:**

- DB contains: one `alice` row and one `bob` row (from `existing_user` and
  `other_user` fixtures).
- `bob_token` obtained from login.

**Act:**

- `PATCH /api/v1/user/alice`
- Headers: `Authorization: Bearer <bob_token>`, `Content-Type: application/json`
- Body: `{"name": "Hacked"}`

**Expect:**

- Status: `403 Forbidden`.
- Response body: `{"message": ""}` or a body whose HTTP status is 403
  (exact message depends on `ForbiddenDomainError` default — verify against
  `app/domain/errors.py`; `ForbiddenDomainError()` is constructed with no
  message in the use case, so `exc.message` is `""`).
- DB state: the `alice` row is unchanged; `name` is still `"Alice"`.

**Covers requirement(s):** F3, F8, F14.

---

## Out of scope for this test

- Field-level validation errors (`422`) — covered by the endpoint integration
  test (`tests/features/users/0006_update_user/presentation/test_router.py`).
- `404 Not Found` and `409 Conflict` paths — covered by the endpoint integration
  test and adapter unit test.
- Skip-if-unchanged logic for `email_exists` / `username_exists` (F11, F12) —
  covered by the use-case unit test with mocked port.
- `updated_at` timestamp correctness (F21) and partial-write field selection
  (F22) — covered by the adapter unit test.
- Performance, load, concurrency.
