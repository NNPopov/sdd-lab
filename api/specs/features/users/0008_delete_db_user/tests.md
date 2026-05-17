# 0008 · delete_db_user — Outside-in test spec

## Goal

Prove that a superuser calling `DELETE /api/v1/db_user/{username}` permanently
removes the target user row from the database, and that the same request returns
409 with the row intact when the user has dependent records.

## Entry point

- **Method:** `DELETE`
- **Path:** `/api/v1/db_user/{username}`
- **Body:** none
- **Auth:** Bearer token belonging to a superuser

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `DeleteDbUserAdapter` — the slice's concrete adapter.
- `DeleteDbUserPort` — bound to `DeleteDbUserAdapter` in `Container`.
- `DeleteDbUserUseCase` — wired to the adapter.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the test runs entirely against the test database.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` wired to the app
  with the test transaction.
- `db_session`: the per-test transaction; provides direct DB access for setup
  and assertions.
- `seeded_superuser` (in slice `conftest.py`): inserts a user row with
  `is_superuser=True` and known credentials directly via `db_session`.
- `superuser_token` (in slice `conftest.py`): a valid signed JWT for
  `seeded_superuser` with a 30-minute expiry, constructed with
  `core.security.create_access_token`.
- `seeded_alice` (in slice `conftest.py`): inserts an active user row with
  `username="alice"`, `is_superuser=False`, `is_deleted=False` directly via
  `db_session`.
- `seeded_alice_with_post` (in slice `conftest.py`): inserts `alice` plus one
  `post` row with `created_by_user_id=alice.id`, used only in Scenario 2.

## Test scenarios

### Scenario 1: happy path — superuser permanently deletes an active user

**Setup:**

- DB contains: `seeded_alice` (active user, `is_deleted=False`).
- DB contains: `seeded_superuser` with `superuser_token` available.
- No posts or other records reference `alice.id`.

**Act:**

- `DELETE /api/v1/db_user/alice` with `Authorization: Bearer <superuser_token>`.

**Expect:**

- Status: `200`.
- Response body: `{"message": "User deleted from the database"}`.
- DB state: no row exists in the `user` table where `username == "alice"` —
  the row was permanently removed, not soft-deleted.

**Covers requirement(s):** F1, F3, F5.

---

### Scenario 2: FK violation — user has dependent records returns 409

**Setup:**

- DB contains: `seeded_alice_with_post` (`alice` row plus a `post` row with
  `created_by_user_id=alice.id`).
- DB contains: `seeded_superuser` with `superuser_token` available.

**Act:**

- `DELETE /api/v1/db_user/alice` with `Authorization: Bearer <superuser_token>`.

**Expect:**

- Status: `409`.
- Response body: `{"message": "User has dependent records"}`.
- DB state: the `alice` row still exists unchanged (hard delete was rolled
  back by the adapter catching `IntegrityError`).
- DB state: the `post` row still exists (no cascade delete occurred).

**Covers requirement(s):** F6, F10.

## Out of scope for this test

- `404` for a missing username (covered by endpoint integration test).
- `401` for missing or invalid token (covered by endpoint integration test).
- `403` for a non-superuser caller (covered by endpoint integration test).
- Adapter-level `IntegrityError` catch logic in isolation (covered by adapter
  unit test).
- Use-case `NotFoundDomainError` branch (covered by use-case unit test).
- Behavior when the target user is soft-deleted (covered by endpoint
  integration test which seeds a soft-deleted row and asserts 200 + row
  removal).
- Performance, load, concurrency.
