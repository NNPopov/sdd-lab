# 0001 · create_user — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `uvicorn app.main:app --reload` from `src/`.
- Test Postgres running: `docker compose up test-db -d`.
- No pre-existing rows with the test usernames/emails in the development DB
  (or use a fresh DB). The `User` table must exist (`alembic upgrade head`).
- `tier` table must exist (FK target for `User.tier_id`), but no tier row is
  needed — `tier_id` is nullable and defaults to `NULL` on creation.
- No Bearer token required — `POST /api/v1/user` is a public endpoint.

---

## Manual scenarios

### S1 — Happy path: valid new user

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/user \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice Example", "username": "alice", "email": "alice@example.com", "password": "Str0ng!pw"}' \
  | python -m json.tool
```

**Expected:**

- HTTP status `201 Created`.
- Response body is a JSON object with keys `id` (integer), `name`, `username`,
  `email`, `profile_image_url` (non-empty string), `tier_id` (`null`).
- `username` equals `"alice"`, `email` equals `"alice@example.com"`.
- A row exists in the `user` table with matching `username` and `email`.

**Covers:** F1, F4, F15.

---

### S2 — Missing required field

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/user \
  -H "Content-Type: application/json" \
  -d '{"username": "bob", "email": "bob@example.com", "password": "Str0ng!pw"}' \
  | python -m json.tool
```

(The `name` field is omitted.)

**Expected:**

- HTTP status `422 Unprocessable Entity`.
- Response body contains a Pydantic validation error describing the missing
  `name` field.

**Covers:** F2.

---

### S3 — Invalid email format

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/user \
  -H "Content-Type: application/json" \
  -d '{"name": "Bob Example", "username": "bob", "email": "not-an-email", "password": "Str0ng!pw"}' \
  | python -m json.tool
```

**Expected:**

- HTTP status `422 Unprocessable Entity`.
- Response body mentions the `email` field and describes the validation failure.

**Covers:** F2.

---

### S4 — Password fails pattern constraint

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/user \
  -H "Content-Type: application/json" \
  -d '{"name": "Bob Example", "username": "bob", "email": "bob@example.com", "password": "short"}' \
  | python -m json.tool
```

(Password `"short"` is under 8 characters and fails the pattern.)

**Expected:**

- HTTP status `422 Unprocessable Entity`.
- Response body mentions the `password` field.

**Covers:** F2.

---

### S5 — Username fails pattern constraint

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/user \
  -H "Content-Type: application/json" \
  -d '{"name": "Bob Example", "username": "Bob_Example", "email": "bob@example.com", "password": "Str0ng!pw"}' \
  | python -m json.tool
```

(Username `"Bob_Example"` contains uppercase and underscore, failing
`^[a-z0-9]+$`.)

**Expected:**

- HTTP status `422 Unprocessable Entity`.
- Response body mentions the `username` field.

**Covers:** F2.

---

### S6 — Duplicate email

**Precondition:** Run S1 first to seed `alice@example.com`.

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/user \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice Clone", "username": "alice2", "email": "alice@example.com", "password": "Str0ng!pw"}' \
  | python -m json.tool
```

**Expected:**

- HTTP status `409 Conflict`.
- Response body:
  ```json
  {"error": {"code": "duplicatevalue", "message": "Email is already registered"}}
  ```
- No new row inserted in the `user` table.

**Covers:** F5, F7, F9, F13.

---

### S7 — Duplicate username (email is unique)

**Precondition:** Run S1 first to seed username `alice`.

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/user \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice Other", "username": "alice", "email": "different@example.com", "password": "Str0ng!pw"}' \
  | python -m json.tool
```

**Expected:**

- HTTP status `409 Conflict`.
- Response body:
  ```json
  {"error": {"code": "duplicatevalue", "message": "Username not available"}}
  ```
- No new row inserted in the `user` table.

**Covers:** F6, F8, F10, F14.

---

### S8 — Check order: both email and username duplicate reports email error

**Precondition:** Run S1 first (`username=alice`, `email=alice@example.com`).

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/user \
  -H "Content-Type: application/json" \
  -d '{"name": "Full Clone", "username": "alice", "email": "alice@example.com", "password": "Str0ng!pw"}' \
  | python -m json.tool
```

(Both `username` and `email` match the existing user.)

**Expected:**

- HTTP status `409 Conflict`.
- Response body message is `"Email is already registered"` — **not** `"Username not available"`.
- This confirms that email is checked before username (F9).

**Covers:** F9.

---

### S9 — Confirm password is not stored in plain text

**Precondition:** Run S1, then query the database directly.

**Steps:**

```bash
# After S1 succeeds:
docker exec -it <postgres-container> psql -U <user> -d app -c \
  "SELECT hashed_password FROM \"user\" WHERE username = 'alice';"
```

**Expected:**

- The `hashed_password` column contains a bcrypt hash (starts with `$2b$`), not
  the literal string `"Str0ng!pw"`.
- This confirms F10 — hashing happens in the use case before the adapter is
  called.

**Covers:** F10, F11.

---

## Code review checklist

For each item: confirm `yes` before approving the PR. All items must be `yes`.

### Architecture

- [ ] Slice folder exists at `src/app/features/users/create_user/` with the
      four sub-packages: `domain/`, `domain/ports/`, `data/`, `presentation/`.
- [ ] `CreateUserUseCase` is a class; its only public method is
      `__call__(command: CreateUserCommand) -> UserRead` (async).
- [ ] `CreateUserPort` lives in
      `domain/ports/create_user_port.py` and is defined with `typing.Protocol`.
- [ ] `CreateUserAdapter` is the only file in this slice that imports
      `sqlalchemy`; no SQLAlchemy in `domain/` or `presentation/`.
- [ ] The router endpoint: accepts `CreateUserRequest` → builds
      `CreateUserCommand` → awaits use case → converts `UserRead` →
      returns `CreateUserResponse`. No business logic in the endpoint function.
- [ ] `domain/commands.py` imports only stdlib and `pydantic`; no imports from
      `adapters/`, `core/`, or any other feature slice.
- [ ] `domain/ports/create_user_port.py` imports only from `domain/` (commands
      and the shared `UserRead` entity); no framework imports.
- [ ] `CreateUserUseCase` raises only `DomainError` subclasses (`DuplicateValueDomainError`);
      it never raises `HTTPException`.
- [ ] No `try/except` block in `CreateUserUseCase` — the use case lets
      `DomainError` propagate naturally; the exception handler (STABLE) does
      HTTP translation.

### Error handling

- [ ] All three `CreateUserAdapter` methods (`email_exists`, `username_exists`,
      `create`) are wrapped in the double try/except pattern per
      `agent_docs/error_handling.md`.
- [ ] The outer catch in each method: starts with
      `if isinstance(exc, DomainError): raise`, then calls
      `logger.error("...", exc_info=True)`, then raises `UnknownDomainError`.
- [ ] The inner catch of `create` maps `sqlalchemy.exc.IntegrityError` →
      `DuplicateValueDomainError`.
- [ ] The inner catches of `email_exists` and `username_exists` propagate all
      exceptions to the outer catch (no domain mapping needed for SELECT paths).
- [ ] `raise ... from exc` is used in all `raise` statements inside the
      adapter — the original exception is preserved in the chain.
- [ ] No new `DomainError` subclass was added anywhere in
      `features/users/create_user/`. All domain errors come from
      `app/domain/errors.py`.

### Files and headers

- [ ] Every new `.py` file under `features/users/create_user/` has
      `# FEATURE: create_user — <purpose>` as line 1 (not line 2).
- [ ] `bootstrap/container.py` has `# STABLE:` as line 1.
- [ ] `features/users/router.py` is the only existing file modified — one
      import removed (`write_user`), one `include_router` call added. No
      structural changes.
- [ ] `features/users/use_cases/user_create.py` is deleted; no other file
      imports from it.
- [ ] `CreateUserRequest` and `CreateUserResponse` both declare
      `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` call anywhere in the new code — only
      `model.model_dump()`.

### Dependency injection

- [ ] `bootstrap/container.py` declares `session_factory` as
      `providers.Object(local_session)` (not `providers.Resource`).
- [ ] `bootstrap/container.py` declares `create_user_adapter` as
      `providers.Factory(CreateUserAdapter, session_factory=session_factory)`.
- [ ] `bootstrap/container.py` declares `create_user_use_case` as
      `providers.Factory(CreateUserUseCase, port=create_user_adapter)`.
- [ ] `"app.features.users.create_user.presentation.router"` is present in
      `Container.wiring_config.modules`.
- [ ] The module-level `container.wire(modules=...)` call is present in
      `bootstrap/container.py` so wiring fires on first import.
- [ ] The endpoint's use-case parameter uses
      `Annotated[CreateUserUseCase, Depends(Provide[Container.create_user_use_case])]`.

### Open questions resolved before merge

- [ ] `UnknownDomainError` has been added to `app/domain/errors.py` (STABLE
      change, requires explicit user approval — see plan.md Open Question 1).
      The adapter imports and uses it.
- [ ] The `get_password_hash` import strategy in `domain/use_case.py` was
      decided (accept `core/` import, or inject as a callable — see plan.md
      Open Question 2), and the implementation matches the decision.

### Tests

- [ ] `tests/features/users/0001_create_user/domain/test_use_case.py` exists
      and covers: email-duplicate branch, username-duplicate branch (email unique),
      check order (both duplicate → email error), hashing assertion
      (`hashed_password ≠ plain password`), and happy-path return value.
- [ ] `tests/features/users/0001_create_user/data/test_adapter.py` exists and
      covers: `email_exists` True/False, `username_exists` True/False, `create`
      success (`UserRead` fields match), `create` with `IntegrityError` →
      `DuplicateValueDomainError`, and `create` with unexpected exception →
      `UnknownDomainError` + `logger.error` called with `exc_info=True`.
- [ ] `tests/features/users/0001_create_user/presentation/test_router.py`
      exists and uses `httpx.AsyncClient` against the running app with test
      Postgres (via `client` fixture). Covers: 201 happy path, 409 duplicate
      email, 409 duplicate username, 422 missing field.
- [ ] `tests/features/users/0001_create_user/create_user_outside_in_test.py`
      exists and is **GREEN** (full stack, real adapter, test Postgres).
- [ ] No test calls `session.commit()` directly.
- [ ] No test uses `mocker.patch` on a `dependency_injector` provider —
      overrides use `container.X.override(...)` / `reset_override()`.
- [ ] All mocks of `CreateUserPort` use `mocker.AsyncMock(spec=CreateUserPort)`.

### Quality gates (must all pass before merge)

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```
