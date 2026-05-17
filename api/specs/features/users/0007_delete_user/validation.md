# 0007 · delete_user — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `uvicorn src.app.main:app --reload` (from the project root).
- Test Postgres running: `docker compose up test-db -d` (or the dev DB is up).
- A registered user account — create one first if needed:

```bash
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice", "username": "alice", "email": "alice@example.com", "password": "Pa$$w0rd1"}'
```

- A valid Bearer token for that user:

```bash
curl -s -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=alice&password=Pa$$w0rd1"
# → {"access_token": "<TOKEN>", "token_type": "bearer"}
```

Set `TOKEN=<value from above>` in your shell before running the scenarios.

---

## Manual scenarios

### S1 — Happy path: authenticated owner deletes their account

**Steps:**

1. Send the delete request as `alice` for `alice`:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/user/alice \
  -H "Authorization: Bearer $TOKEN"
```

**Expected:**

- Status `200`.
- Body `{"message": "User deleted"}`.
- In the DB: the `user` row for `alice` has `is_deleted = true` and `deleted_at` is not null.
- In the DB: a row exists in `token_blacklist` for `$TOKEN`.

**Covers:** F1, F4, F6, F7.

---

### S2 — Token is invalidated after deletion

**Steps:**

1. Run S1 to delete `alice` and obtain `$TOKEN` (record the token before running S1).
2. Immediately retry any authenticated request with the same `$TOKEN`:

```bash
curl -s -X GET http://localhost:8000/api/v1/user/alice \
  -H "Authorization: Bearer $TOKEN"
```

**Expected:**

- Status `401`.
- The token was blacklisted by the delete operation; the server rejects it.

**Covers:** F7.

---

### S3 — Target user does not exist

**Steps:**

1. Request deletion of a username that was never registered:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/user/nobody \
  -H "Authorization: Bearer $TOKEN"
```

**Expected:**

- Status `404`.
- Body `{"message": "User not found"}` (or similar `NotFoundDomainError` message).

**Covers:** F2, F10.

---

### S4 — Target user is already soft-deleted

**Steps:**

1. Run S1 to soft-delete `alice` (log in fresh as a different user for the `$TOKEN` if needed, or create a second account).
2. As a superuser (or using the `db_user` hard-delete endpoint for setup), repeat a DELETE on `alice`:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/user/alice \
  -H "Authorization: Bearer $SUPERUSER_TOKEN"
```

**Expected:**

- Status `404` — the adapter's `get_by_username` filters `is_deleted == false`, so the already-deleted user is invisible.

**Covers:** F2, F5.

---

### S5 — Authenticated user tries to delete a different account

**Steps:**

1. Register a second user `bob`:

```bash
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Bob", "username": "bob", "email": "bob@example.com", "password": "Pa$$w0rd1"}'
```

2. Log in as `alice` to obtain `$ALICE_TOKEN`.
3. Attempt to delete `bob` using Alice's token:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/user/bob \
  -H "Authorization: Bearer $ALICE_TOKEN"
```

**Expected:**

- Status `403`.
- Body contains a `ForbiddenDomainError` message.
- `bob` row is unchanged in the DB (`is_deleted` remains `false`).

**Covers:** F3, F9.

---

### S6 — Request with no token

**Steps:**

```bash
curl -s -X DELETE http://localhost:8000/api/v1/user/alice
```

**Expected:**

- Status `401`.
- `get_current_user` rejects the request before the use-case is invoked.

**Covers:** F8.

---

### S7 — Request with an expired or malformed token

**Steps:**

```bash
curl -s -X DELETE http://localhost:8000/api/v1/user/alice \
  -H "Authorization: Bearer not.a.real.token"
```

**Expected:**

- Status `401`.
- The use-case and adapter are never called.

**Covers:** F8.

---

## Code review checklist

For the reviewer to verify on the PR before approving. Each item is a yes/no question.

### Architecture

- [ ] Slice folder exists at `src/app/features/users/delete_user/` with `domain/`, `data/`, and `presentation/` subfolders.
- [ ] `DeleteUserUseCase` is a class with `__init__(self, port: DeleteUserPort)` and `async def __call__(self, command: DeleteUserCommand) -> DeleteUserResult`.
- [ ] `DeleteUserPort` lives in `domain/ports/delete_user_port.py`, uses `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `DeleteUserAdapter` class signature is `class DeleteUserAdapter(DeleteUserPort):` — explicit inheritance from the port.
- [ ] `TokenBlacklistPort` lives in `src/app/ports/token_blacklist.py` with a `# STABLE:` header, `@runtime_checkable`, and one method `async def blacklist(self, token: str) -> None`.
- [ ] `TokenBlacklistService` lives in `src/app/core/token_blacklist_service.py` with a `# STABLE:` header and explicit `(TokenBlacklistPort)` inheritance.
- [ ] `TokenBlacklistService` imports only from `stdlib`, third-party libraries, `core/security.py` constants, and `adapters/db/token_blacklist/repository.py`; it does not import from `features/`.
- [ ] Router calls `await token_blacklist.blacklist(token)` **after** `await use_case(command)` returns — order matters.
- [ ] `DeleteUserAdapter` is the only place SQLAlchemy is touched in this slice.
- [ ] Router has two lazy helper functions: `_get_delete_user_use_case()` and `_get_token_blacklist_service()`, both using the `from .....bootstrap.container import container` pattern.
- [ ] No cross-slice imports outside `users/_shared/` (the `check_owner` policy import is the only cross-slice import allowed).
- [ ] All imports inside `src/app/` are **relative**. No `from app...` or `from src.app...` anywhere in source files.
- [ ] `core/security.py` is **unchanged**.
- [ ] `use_cases/user_delete.py` is **deleted** and no file imports from it.

### Error handling

- [ ] `DeleteUserUseCase` raises only `NotFoundDomainError` and `ForbiddenDomainError`; no `HTTPException`.
- [ ] `DeleteUserAdapter.get_by_username` has **no `try/except`** — read-only queries propagate DB errors to the global handler.
- [ ] `DeleteUserAdapter.soft_delete` has **no `try/except`** — the UPDATE has no unique-constraint path to catch.
- [ ] `TokenBlacklistService.blacklist` has **no `try/except`** — JWT decode errors and DB write errors propagate to the global handler.
- [ ] No new `DomainError` subclass was added in any feature folder; all domain errors live in `app/domain/errors.py`.

### Files and headers

- [ ] Every new `.py` file in `features/users/delete_user/` starts with `# FEATURE: delete_user — <purpose>` on line 1.
- [ ] `src/app/ports/token_blacklist.py` starts with `# STABLE:` on line 1.
- [ ] `src/app/core/token_blacklist_service.py` starts with `# STABLE:` on line 1.
- [ ] No STABLE file was modified beyond `bootstrap/container.py` (three new providers) and `features/users/router.py` (swap `erase_user` for `include_router`).
- [ ] `DeleteUserResponse` has `model_config = ConfigDict(from_attributes=True)` if it wraps any ORM-derived data (not strictly required for a plain message, but consistent).
- [ ] No `model.dict()` — only `model.model_dump()`.

### DI

- [ ] `token_blacklist_service`, `delete_user_adapter`, and `delete_user_use_case` providers are added to `Container` in `bootstrap/container.py`.
- [ ] `delete_user_use_case` provider takes `port=delete_user_adapter`.
- [ ] `token_blacklist_service` provider takes `session_factory=session_factory`.
- [ ] Both `_get_delete_user_use_case()` and `_get_token_blacklist_service()` use lazy container imports (not `Provide[Container.x]`), consistent with the rest of `features/users/`.

### Tests

- [ ] Use-case unit test exists at `tests/features/users/0007_delete_user/domain/test_use_case.py` and covers `NotFoundDomainError`, `ForbiddenDomainError`, and the happy path calling `port.soft_delete`.
- [ ] Adapter unit test exists at `tests/features/users/0007_delete_user/data/test_adapter.py` and verifies `get_by_username` returns `None` for missing/soft-deleted rows and `soft_delete` issues an UPDATE with the correct fields.
- [ ] `TokenBlacklistService` unit test exists at `tests/core/test_token_blacklist_service.py` and verifies the `create` call is made with the correct `expires_at`.
- [ ] Endpoint integration test exists at `tests/features/users/0007_delete_user/presentation/test_router.py` and covers 200, 401, 403, and 404 cases using `httpx.AsyncClient`.
- [ ] Outside-in test at `tests/features/users/0007_delete_user/delete_user_outside_in_test.py` is present and **GREEN** — this is the acceptance gate.
- [ ] No test calls `session.commit()` when using the `db_session` fixture (would defeat rollback).

### Quality gates

Run from the project root. All must pass before the slice is considered done:

```bash
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

The `pytest` run includes `tests/smoke/test_app_starts.py`, which boots the app via a real `uvicorn` subprocess and pings `/api/v1/health`. A passing unit and integration suite with a failing smoke test means an import that works under pytest's PYTHONPATH breaks under uvicorn — the most common cause is an accidental `from app...` inside `src/app/`. The slice is **not done** until the smoke test is green.
