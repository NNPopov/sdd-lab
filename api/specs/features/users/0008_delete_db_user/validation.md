# 0008 · delete_db_user — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `uvicorn src.app.main:app --reload` (from the project root).
- Test Postgres running: `docker compose up test-db -d`.
- A superuser account available. Create one if needed:

```bash
python -m scripts.create_first_superuser
```

- A regular (non-superuser) account for the forbidden scenario:

```bash
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice", "username": "alice", "email": "alice@example.com", "password": "Pa$$w0rd1"}'
```

- A valid Bearer token for the superuser:

```bash
curl -s -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=<superuser_password>"
# → {"access_token": "<SUPERUSER_TOKEN>", "token_type": "bearer"}
```

- A valid Bearer token for the regular user:

```bash
curl -s -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=alice&password=Pa$$w0rd1"
# → {"access_token": "<ALICE_TOKEN>", "token_type": "bearer"}
```

Set `SUPERUSER_TOKEN` and `ALICE_TOKEN` in your shell before running the scenarios.

---

## Manual scenarios

### S1 — Happy path: superuser permanently deletes an active user

**Steps:**

1. Confirm `alice` exists in the DB with `is_deleted = false`.
2. Send the delete request:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/db_user/alice \
  -H "Authorization: Bearer $SUPERUSER_TOKEN"
```

**Expected:**

- Status `200`.
- Body `{"message": "User deleted from the database"}`.
- In the DB: no row exists in the `user` table for `alice`.
- In the DB: no row in `token_blacklist` for `$SUPERUSER_TOKEN` (no blacklisting occurs).

**Covers:** F1, F3, F5.

---

### S2 — Superuser hard-deletes a previously soft-deleted user

**Steps:**

1. Soft-delete `alice` using the `DELETE /user/alice` endpoint (0007 slice) with `$ALICE_TOKEN`.
2. Confirm `alice` row exists with `is_deleted = true`.
3. Hard-delete using the superuser:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/db_user/alice \
  -H "Authorization: Bearer $SUPERUSER_TOKEN"
```

**Expected:**

- Status `200`.
- Body `{"message": "User deleted from the database"}`.
- In the DB: the `alice` row is gone (no row at all, including soft-deleted).

**Covers:** F4 (adapter omits `is_deleted` filter — soft-deleted user is still found and deleted).

---

### S3 — Username does not exist

**Steps:**

```bash
curl -s -X DELETE http://localhost:8000/api/v1/db_user/nobody \
  -H "Authorization: Bearer $SUPERUSER_TOKEN"
```

**Expected:**

- Status `404`.
- Body contains a `NotFoundDomainError` message (e.g. `{"message": "User not found"}`).

**Covers:** F2, F9.

---

### S4 — User has dependent records (FK violation)

**Steps:**

1. Create `bob`:

```bash
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Bob", "username": "bob", "email": "bob@example.com", "password": "Pa$$w0rd1"}'
```

2. Create a post owned by `bob` (obtain `$BOB_TOKEN` first):

```bash
curl -s -X POST http://localhost:8000/api/v1/users/bob/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -d '{"title": "Hello", "text": "World"}'
```

3. Attempt to hard-delete `bob` as superuser:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/db_user/bob \
  -H "Authorization: Bearer $SUPERUSER_TOKEN"
```

**Expected:**

- Status `409`.
- Body contains a `DuplicateValueDomainError` message (e.g. `{"message": "User has dependent records"}`).
- In the DB: `bob` row is unchanged; the post is unchanged.

**Covers:** F6, F10.

---

### S5 — Non-superuser attempt

**Steps:**

```bash
curl -s -X DELETE http://localhost:8000/api/v1/db_user/alice \
  -H "Authorization: Bearer $ALICE_TOKEN"
```

**Expected:**

- Status `403`.
- `get_current_superuser` rejects the request before the use-case is invoked.

**Covers:** F8.

---

### S6 — Request with no token

**Steps:**

```bash
curl -s -X DELETE http://localhost:8000/api/v1/db_user/alice
```

**Expected:**

- Status `401`.
- The use-case is never invoked.

**Covers:** F7.

---

### S7 — Request with an expired or malformed token

**Steps:**

```bash
curl -s -X DELETE http://localhost:8000/api/v1/db_user/alice \
  -H "Authorization: Bearer not.a.real.token"
```

**Expected:**

- Status `401`.
- The use-case is never invoked.

**Covers:** F7.

---

## Code review checklist

For the reviewer to verify on the PR before approving. Each item is a yes/no question.

### Architecture

- [ ] Slice folder exists at `src/app/features/users/delete_db_user/` with `domain/`, `data/`, and `presentation/` subfolders.
- [ ] `DeleteDbUserUseCase` is a class with `__init__(self, port: DeleteDbUserPort)` and `async def __call__(self, command: DeleteDbUserCommand) -> DeleteDbUserResult`.
- [ ] `DeleteDbUserPort` lives in `domain/ports/delete_db_user_port.py`, uses `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `DeleteDbUserAdapter` class signature is `class DeleteDbUserAdapter(DeleteDbUserPort):` — explicit inheritance from the port is mandatory.
- [ ] `DeleteDbUserAdapter` is the only place SQLAlchemy is touched in this slice.
- [ ] Router endpoint declares `get_current_superuser` as a positional `_` dependency (not as a named parameter passed to the use-case), keeping auth at the router level.
- [ ] Router uses a single lazy helper function `_get_delete_db_user_use_case()` with the `from .....bootstrap.container import container` pattern — no `Provide[Container.x]` wiring.
- [ ] No cross-slice imports: the only import from outside the slice is `get_current_superuser` from `features/users/dependencies.py` (same feature, not another slice).
- [ ] All imports inside `src/app/` are **relative**. No `from app...` or `from src.app...` anywhere in source files.
- [ ] `DeleteDbUserCommand` contains only `target_username: str` — no requester identity field.
- [ ] `use_cases/user_db_delete.py` is **deleted** and no file imports from it.

### Error handling

- [ ] `DeleteDbUserUseCase` raises only `NotFoundDomainError`; no `HTTPException`.
- [ ] `DeleteDbUserAdapter.get_by_username` has **no `try/except`** — read-only query propagates DB errors to the global handler.
- [ ] `DeleteDbUserAdapter.db_delete` wraps **only `session.commit()`** in a narrow `try/except IntegrityError`; the `except` clause raises `DuplicateValueDomainError("User has dependent records") from exc`.
- [ ] No other exception types are caught in `db_delete`; `OperationalError` and all other infra exceptions propagate unchanged.
- [ ] `raise DuplicateValueDomainError(...) from exc` preserves the original `IntegrityError` cause in the stack trace.
- [ ] No new `DomainError` subclass was added in any feature folder; all domain errors live in `app/domain/errors.py`.
- [ ] Adapter does not log exceptions; the global handler does.

### Files and headers

- [ ] Every new `.py` file in `features/users/delete_db_user/` starts with `# FEATURE: delete_db_user — <purpose>` on line 1.
- [ ] No STABLE file was modified beyond `bootstrap/container.py` (two new providers) and `features/users/router.py` (swap `erase_db_user` for `include_router`).
- [ ] `DeleteDbUserResponse` uses `class DeleteDbUserResponse(BaseModel)` with a `message: str` field.
- [ ] No `model.dict()` — only `model.model_dump()` if serialisation is needed.

### DI

- [ ] `delete_db_user_adapter` and `delete_db_user_use_case` providers are added to `Container` in `bootstrap/container.py`.
- [ ] `delete_db_user_use_case` provider takes `port=delete_db_user_adapter`.
- [ ] `delete_db_user_adapter` provider takes `session_factory=session_factory`.
- [ ] `_get_delete_db_user_use_case()` uses lazy container import — no `wiring_config.modules` entry needed (consistent with the rest of `features/users/`).

### Adapter correctness

- [ ] `get_by_username` query selects from `User` where `User.username == username` with **no** `is_deleted` filter — soft-deleted users must still be found and hard-deleted.
- [ ] `db_delete` issues a `DELETE FROM user WHERE username == :username` statement (not an UPDATE, not a soft-delete).

### Tests

- [ ] Use-case unit test exists at `tests/features/users/0008_delete_db_user/domain/test_use_case.py` and covers `NotFoundDomainError` (port returns `None`) and the happy path (port returns a target, `db_delete` is called).
- [ ] Adapter unit test exists at `tests/features/users/0008_delete_db_user/data/test_adapter.py` and verifies: `get_by_username` returns `DbDeleteUserTarget` for an active row; returns `DbDeleteUserTarget` for a soft-deleted row; returns `None` when no row matches; `db_delete` raises `DuplicateValueDomainError` when `IntegrityError` is raised; other DB exceptions from `db_delete` propagate unchanged.
- [ ] Endpoint integration test exists at `tests/features/users/0008_delete_db_user/presentation/test_router.py` and covers 200, 401, 403, 404, and 409 cases using `httpx.AsyncClient`.
- [ ] Outside-in test at `tests/features/users/0008_delete_db_user/delete_db_user_outside_in_test.py` is present and **GREEN** — this is the acceptance gate.
- [ ] No test calls `session.commit()` when using the `db_session` fixture.

### Quality gates

Run from the project root. All must pass before the slice is considered done:

```bash
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

The `pytest` run includes `tests/smoke/test_app_starts.py`, which boots the app via a real `uvicorn` subprocess and pings `/api/v1/health`. A passing unit and integration suite with a failing smoke test means an import that works under pytest's PYTHONPATH breaks under uvicorn — the most common cause is an accidental `from app...` inside `src/app/`. The slice is **not done** until the smoke test is green.
