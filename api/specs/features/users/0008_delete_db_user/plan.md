# 0008 · delete_db_user — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0008_delete_db_user
- **PRD:** ./prd.md
- **Reference slice:** `../0007_delete_user/plan.md` — same delete shape; closest
  operation match. Key differences: hard delete instead of soft delete; no
  ownership check; no token blacklisting; `get_by_username` omits `is_deleted`
  filter; adapter catches FK `IntegrityError`.
- **HTTP path:** `DELETE /api/v1/db_user/{username}`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `delete_db_user_adapter` and
    `delete_db_user_use_case` providers.
  - `features/users/router.py` — swap the inline `erase_db_user` wiring for
    `include_router(delete_db_user_router)`.

## 2. Context summary

A superuser sends `DELETE /api/v1/db_user/{username}` to permanently erase a
user row from the database. Superuser authorisation is enforced at the router
level via `get_current_superuser`; the use-case receives no requester
information. The use-case checks that the target user exists (regardless of
soft-delete state), then delegates to the port's `db_delete` method. The
adapter executes a raw `DELETE` and catches `IntegrityError` from FK violations,
translating it to `DuplicateValueDomainError`. On success the router returns
`{"message": "User deleted from the database"}` with HTTP 200. The old flat
function `use_cases/user_db_delete.py` is deleted once the slice is live.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `username` | `str` | Username of the account to permanently delete |

**Request body:** none.

**Response body** (`DeleteDbUserResponse`):

| Field | Type | Notes |
|---|---|---|
| `message` | `str` | Always `"User deleted from the database"` on success |

**Status codes:**

- `200 OK` — user row permanently deleted.
- `401 Unauthorized` — token missing, invalid, or expired (raised by
  `get_current_superuser`).
- `403 Forbidden` — caller is not a superuser (raised by `get_current_superuser`).
- `404 Not Found` — `NotFoundDomainError`; username does not exist.
- `409 Conflict` — `DuplicateValueDomainError`; FK violation; user has
  dependent records that prevent deletion.
- `500 Internal Server Error` — any other infrastructure failure propagates to
  the global catch-all handler.

## 4. File structure

New files:

```
src/app/features/users/delete_db_user/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py             # DeleteDbUserCommand
│   ├── entities.py             # DbDeleteUserTarget, DeleteDbUserResult
│   ├── ports/
│   │   ├── __init__.py
│   │   └── delete_db_user_port.py   # DeleteDbUserPort
│   └── use_case.py             # DeleteDbUserUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py              # DeleteDbUserAdapter
└── presentation/
    ├── __init__.py
    ├── router.py
    └── schemas.py              # DeleteDbUserResponse
```

No new ORM model. No Alembic migration (no schema change).

Files modified:

```
src/app/bootstrap/container.py           # add two new providers
src/app/features/users/router.py         # swap inline erase_db_user for include_router
```

Files deleted:

```
src/app/features/users/use_cases/user_db_delete.py
```

## 5. Implementation steps

### Step 1 — Domain: Command

**File:** `src/app/features/users/delete_db_user/domain/commands.py`

Header: `# FEATURE: delete_db_user — domain command.`

```python
class DeleteDbUserCommand(BaseModel):
    target_username: str
```

No requester field. Superuser authorisation is a router concern; the use-case
does not know who is calling.

---

### Step 2 — Domain: Entities

**File:** `src/app/features/users/delete_db_user/domain/entities.py`

Header: `# FEATURE: delete_db_user — domain entities.`

Two classes:

- `DbDeleteUserTarget(BaseModel)`: `username: str` — minimal existence result;
  only username is needed because there is no ownership check.
- `DeleteDbUserResult(BaseModel)`: `message: str = "User deleted from the
  database"` — use-case return value.

`BaseModel` only. No framework imports per `agent_docs/architecture.md` §
Layer rules (`domain/` imports only stdlib and pydantic).

---

### Step 3 — Domain: Port

**File:** `src/app/features/users/delete_db_user/domain/ports/delete_db_user_port.py`

Header: `# FEATURE: delete_db_user — port protocol.`

```python
@runtime_checkable
class DeleteDbUserPort(Protocol):
    async def get_by_username(self, username: str) -> DbDeleteUserTarget | None: ...
    async def db_delete(self, username: str) -> None: ...
```

`@runtime_checkable` is mandatory per `agent_docs/architecture.md` §
Terminology: port and adapter.

---

### Step 4 — Domain: Use case

**File:** `src/app/features/users/delete_db_user/domain/use_case.py`

Header: `# FEATURE: delete_db_user — use case.`

`class DeleteDbUserUseCase`:
- `__init__(self, port: DeleteDbUserPort)`.
- `async def __call__(self, command: DeleteDbUserCommand) -> DeleteDbUserResult`:
  1. `target = await self._port.get_by_username(command.target_username)`.
  2. If `target is None`, raise `NotFoundDomainError("User not found")`.
  3. `await self._port.db_delete(command.target_username)`.
  4. Return `DeleteDbUserResult()`.

No ownership check, no token handling. The use-case raises only `DomainError`
subclasses and never raises `HTTPException` per `agent_docs/error_handling.md`.

---

### Step 5 — Data: Adapter

**File:** `src/app/features/users/delete_db_user/data/adapter.py`

Header: `# FEATURE: delete_db_user — data adapter.`

`class DeleteDbUserAdapter(DeleteDbUserPort)` — explicit inheritance from the
port is mandatory per `agent_docs/architecture.md` § Adapter pattern.

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`get_by_username(username)`: `SELECT` from `User` where
`User.username == username` **without** an `is_deleted` filter — hard delete
must work on both active and soft-deleted accounts. Returns
`DbDeleteUserTarget(username=row.username)` if found, else `None`. No
`try/except` per `agent_docs/error_handling.md` § Right shape: read-only query,
no catch.

`db_delete(username)`: execute a raw SQLAlchemy
`DELETE FROM user WHERE User.username == username`. Wrap only the `session.commit()`
in a narrow `try/except`:

```python
try:
    await session.commit()
except IntegrityError as exc:
    raise DuplicateValueDomainError("User has dependent records") from exc
```

Per `agent_docs/error_handling.md`, FK violations (PostgreSQL sqlstate `23503`)
are caught and translated to `DuplicateValueDomainError`. All other infrastructure
exceptions propagate unchanged to the global handler. The `from exc` chain
preserves the original stack trace.

---

### Step 6 — Presentation: Schemas

**File:** `src/app/features/users/delete_db_user/presentation/schemas.py`

Header: `# FEATURE: delete_db_user — request/response schemas.`

Only a response schema is needed (no request body):

```python
class DeleteDbUserResponse(BaseModel):
    message: str
```

---

### Step 7 — Presentation: Router

**File:** `src/app/features/users/delete_db_user/presentation/router.py`

Header: `# FEATURE: delete_db_user — HTTP router.`

Follow the lazy container import pattern used by every existing router in this
feature (the project does not use `dependency_injector`'s `Provide` wiring in
presentation routers):

```python
def _get_delete_db_user_use_case() -> DeleteDbUserUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.delete_db_user_use_case()
```

Endpoint signature:

```python
@router.delete("/db_user/{username}", response_model=DeleteDbUserResponse, status_code=200)
async def delete_db_user_endpoint(
    username: str,
    use_case: Annotated[DeleteDbUserUseCase, Depends(_get_delete_db_user_use_case)],
    _: Annotated[dict, Depends(get_current_superuser)],
) -> DeleteDbUserResponse:
```

Body:
1. Build `DeleteDbUserCommand(target_username=username)`.
2. `result = await use_case(command)`.
3. Return `DeleteDbUserResponse(message=result.message)`.

`get_current_superuser` is imported from `...dependencies` (relative, within
the `users` feature). It is declared as a positional `_` parameter so FastAPI
evaluates it as a dependency while the use-case body ignores the caller's
identity. No `Request` parameter. No `oauth2_scheme` dependency. No `try/except`.

---

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — minimal addition only)

Add two providers after the existing `delete_user_use_case` entry:

```python
delete_db_user_adapter = providers.Factory(
    DeleteDbUserAdapter,
    session_factory=session_factory,
)

delete_db_user_use_case = providers.Factory(
    DeleteDbUserUseCase,
    port=delete_db_user_adapter,
)
```

Add the two corresponding imports at the top of the file. No `wiring_config`
changes needed — the project uses lazy container imports in routers, not
`dependency_injector`'s `Provide` wiring.

---

### Step 9 — Router registration

**File:** `src/app/features/users/router.py`

Remove:
```python
from .use_cases.user_db_delete import erase_db_user
router.delete("/db_user/{username}", dependencies=[Depends(get_current_superuser)])(erase_db_user)
```

Add:
```python
from .delete_db_user.presentation.router import router as delete_db_user_router
router.include_router(delete_db_user_router)
```

The `get_current_superuser` dependency moves from the parent router's inline
registration into the slice's own router, keeping auth co-located with the
endpoint.

---

### Step 10 — Delete old implementation

Delete `src/app/features/users/use_cases/user_db_delete.py`. Before deleting,
grep for `user_db_delete` and `erase_db_user` across `src/` to confirm no other
file imports from it.

---

### Step 11 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/users/0008_delete_db_user/delete_db_user_outside_in_test.py -v
```

The slice is not done until all four pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/users/0008_delete_db_user/domain/test_use_case.py`.
  Mock `DeleteDbUserPort`. Assert:
  - `get_by_username` returns `None` → raises `NotFoundDomainError`.
  - `get_by_username` returns a target → `port.db_delete` is called and
    `DeleteDbUserResult(message="User deleted from the database")` is returned.
  Prior art: `tests/features/users/0007_delete_user/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/users/0008_delete_db_user/data/test_adapter.py`.
  Mock async session factory. Assert:
  - `get_by_username` returns `DbDeleteUserTarget` when a row is found (test
    both active and soft-deleted rows — neither should be filtered).
  - `get_by_username` returns `None` when no row matches.
  - `db_delete` raises `DuplicateValueDomainError` when `session.commit()`
    raises `IntegrityError`.
  - Any other DB exception from `db_delete` propagates unchanged.
  Prior art: `tests/features/users/0007_delete_user/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/users/0008_delete_db_user/presentation/test_router.py`.
  `httpx.AsyncClient` against test Postgres. Assert:
  - Superuser DELETE of an active user → `200 {"message": "User deleted from
    the database"}` and the row is absent from the database.
  - Superuser DELETE of a soft-deleted user → `200` and row is absent.
  - Non-existent `{username}` → `404`.
  - User with dependent posts → `409`.
  - Regular user (non-superuser) → `403`.
  - Missing / invalid token → `401`.
  Prior art:
  `tests/features/users/0007_delete_user/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/users/0008_delete_db_user/delete_db_user_outside_in_test.py`.
  Full HTTP stack: real adapter, test Postgres. Assert:
  - Happy path: superuser DELETE → `200`; user row no longer exists in the DB.
  - Conflict case: seed user with a post; superuser DELETE → `409`; user row
    is unchanged.
  Acceptance gate for the slice.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Soft deletion — handled by `delete_user` (0007).
- Token blacklisting on hard delete — the deleted user's tokens expire
  naturally; the calling superuser's token is not invalidated.
- Cascade deletion of dependent records (posts, etc.) — FK constraint is
  surfaced as 409; schema-level cascade is a separate infrastructure change.
- Rate limiting — endpoint is behind superuser auth.
- Caching — no read path; nothing to cache or invalidate.

## 8. Open questions

None. All design decisions were resolved in the grill-me session preceding
the PRD.
