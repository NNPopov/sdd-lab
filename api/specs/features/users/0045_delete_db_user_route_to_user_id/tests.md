# 0045 · delete_db_user_route_to_user_id — Outside-in test spec

## Goal

Prove that `DELETE /api/v1/db_user/{user_id}` hard-deletes a user row by its
integer primary key when called by a superuser (row is gone from the DB), and
that the delete is rejected with HTTP 409 when the target row has a dependent
record (the row is left intact).

## Entry point

- **Method:** `DELETE`
- **Path:** `/api/v1/db_user/{user_id}` (where `user_id` is the integer primary
  key of the target account)
- **Auth:** superuser (the `get_current_user` dependency is overridden to return
  a dict with `is_superuser == True`, which satisfies `get_current_superuser`)

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `DeleteDbUserAdapter` — queries by `User.id` and hard-deletes by `User.id`.
- `DeleteDbUserPort` — bound to `DeleteDbUserAdapter` in `Container`.
- `DeleteDbUserUseCase` — enforces the existence check and calls `db_delete`.
- Test Postgres via the `async_client` fixture (savepoint-based transaction
  rollback per test; the `session_factory` provider is overridden to use the
  test connection).
- DI container with `session_factory` overridden.

## Mocked

- **`get_current_user` dependency:** overridden via
  `app.dependency_overrides[get_current_user] = lambda: _SUPERUSER`, where
  `_SUPERUSER` is a dict with `is_superuser == True`. This bypasses JWT
  verification while still satisfying the superuser gate. The override is reset
  in `finally`.

Everything else (adapter, use-case, the hard delete against the DB) runs against
the real test database.

## Fixtures used

- `async_client` (from slice `conftest.py`): `httpx.AsyncClient` wired to the
  app with savepoint rollback; overrides `container.session_factory`.
- `seeded_alice` (from slice `conftest.py`): dict `{"id": <int>, "username":
  "alice", ...}` — an active user row, inserted inside the test transaction.
- `seeded_alice_with_post` (from slice `conftest.py`, Scenario 2 only): dict
  `{"id": <int>, "username": "alice"}` — an active user row plus a `Post`
  referencing `alice.id`, so a hard delete violates the post→user foreign key.

## Test scenarios

### Scenario 1: happy path — superuser hard-deletes a user by integer ID

**Setup:**

- `seeded_alice` row exists in the test DB.
- `get_current_user` overridden to return `_SUPERUSER`.

**Act:**

- `DELETE /api/v1/db_user/{seeded_alice["id"]}` with header
  `Authorization: Bearer fake-token`.

**Expect:**

- Status: `200`.
- Response body: `{"message": "User deleted from the database"}`.
- DB state: no row with `username == "alice"` remains in the `user` table
  (verified by raw SQL on the test session after the request).

**Covers requirement(s):** F1, F5, F6, F7, F8, F9, F10.

---

### Scenario 2: conflict — target has a dependent record, delete is rejected

**Setup:**

- `seeded_alice_with_post` exists: an `alice` user row plus a `Post` whose
  `created_by_user_id` references `alice.id`.
- `get_current_user` overridden to return `_SUPERUSER`.

**Act:**

- `DELETE /api/v1/db_user/{seeded_alice_with_post["id"]}` with header
  `Authorization: Bearer fake-token`.

**Expect:**

- Status: `409`.
- Response body: `error.code == "duplicatevalue"` and `error.message` contains
  `"dependent"` (the adapter's `IntegrityError → DuplicateValueDomainError`
  translation).
- DB state: the `alice` row is unchanged — still present (verified by raw SQL).

**Covers requirement(s):** F11, F13.

## Out of scope for this test

- HTTP 422 for non-integer `user_id` — covered by the endpoint integration test
  in `presentation/test_router.py`.
- HTTP 401 for a missing or invalid token — covered by the endpoint integration
  test.
- HTTP 403 for an authenticated non-superuser — covered by the endpoint
  integration test.
- HTTP 404 for a non-existent `user_id` — covered by the use-case unit test
  (`NotFoundDomainError`) and the endpoint integration test.
- Individual SQLAlchemy exception propagation paths beyond `IntegrityError` —
  covered by the adapter unit test.
- Performance, concurrency, load.
