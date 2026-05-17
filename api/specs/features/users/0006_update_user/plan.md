# 0006 · update_user — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0006_update_user
- **PRD:** ./prd.md
- **Reference slice:** `../0001_create_user/plan.md` — same write + duplicate-check shape; closest operation match in the roadmap.
- **HTTP path:** `PATCH /api/v1/user/{username}`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `update_user_adapter` and `update_user_use_case` providers.

## 2. Context summary

An authenticated user sends a `PATCH /api/v1/user/{username}` request to update their own profile fields (`name`, `username`, `email`, `profile_image_url`). All fields are optional; only the provided ones are written. The router resolves the caller's identity from the JWT token via `get_current_user`, builds an `UpdateUserCommand` (including both the target username from the path and the requester's username from the token), and delegates to `UpdateUserUseCase`. The use case enforces ownership via a shared `check_owner` helper, verifies that any new email or username is not already taken, and delegates the write to `UpdateUserPort`. The adapter performs the SQL update and translates `IntegrityError` from the commit into `DuplicateValueDomainError`. The use case returns an `UpdatedUserResult` with a confirmation message. The old free-function implementation in `use_cases/user_update.py` is deleted once the new slice is in place.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `username` | `str` | Username of the profile to update |

**Request body** (`UpdateUserRequest`):

| Field | Type | Validation |
|---|---|---|
| `name` | `str \| None` | `min_length=2`, `max_length=30`, default `None` |
| `username` | `str \| None` | `min_length=2`, `max_length=20`, `pattern=r"^[a-z0-9_]+$"`, default `None` |
| `email` | `EmailStr \| None` | valid e-mail, default `None` |
| `profile_image_url` | `str \| None` | URL pattern, default `None` |

**Response body** (`UpdateUserResponse`):

| Field | Type |
|---|---|
| `message` | `str` |

**Status codes:**

- `200 OK` — update applied; `{"message": "User updated"}`.
- `401 Unauthorized` — token missing or invalid (`UnauthorizedException` from `get_current_user`).
- `403 Forbidden` — `ForbiddenDomainError`; requester does not own the target profile.
- `404 Not Found` — `NotFoundDomainError`; target `username` does not exist or is soft-deleted.
- `409 Conflict` — `DuplicateValueDomainError`; new email or new username already in use.
- `422 Unprocessable Entity` — Pydantic field-level validation failure (pattern, length).

## 4. File structure

New files:

```
src/app/features/users/_shared/
├── __init__.py
└── policies.py              # check_owner(requester, owner) -> None

src/app/features/users/update_user/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py          # UpdateUserCommand
│   ├── entities.py          # ExistingUser, UpdatedUserResult
│   ├── ports/
│   │   ├── __init__.py
│   │   └── update_user_port.py  # UpdateUserPort
│   └── use_case.py          # UpdateUserUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py           # UpdateUserAdapter
└── presentation/
    ├── __init__.py
    ├── router.py
    └── schemas.py           # UpdateUserRequest, UpdateUserResponse
```

Files modified:

```
src/app/bootstrap/container.py           # add update_user_adapter, update_user_use_case
src/app/features/users/router.py         # remove patch_user; add include_router
```

Files deleted:

```
src/app/features/users/use_cases/user_update.py
```

No new ORM model. No Alembic migration (no schema change).

## 5. Implementation steps

### Step 1 — Shared policy

**File:** `src/app/features/users/_shared/policies.py`

Header: `# FEATURE: users._shared — ownership policy.`

Define `check_owner(requester_username: str, owner_username: str) -> None`. If they differ, raise `ForbiddenDomainError()`. Import only from `domain/errors.py`. This is pure Python with no I/O.

Create `src/app/features/users/_shared/__init__.py` (empty, no header required for empty `__init__.py`).

Verify: `check_owner("alice", "alice")` returns `None`; `check_owner("alice", "bob")` raises `ForbiddenDomainError`.

### Step 2 — Domain: Commands

**File:** `src/app/features/users/update_user/domain/commands.py`

Header: `# FEATURE: update_user — domain command.`

```
class UpdateUserCommand(BaseModel):
    target_username: str
    requester_username: str
    name: str | None = None
    username: str | None = None
    email: str | None = None
    profile_image_url: str | None = None
```

`BaseModel` only; no framework imports. The command holds all data the use case needs, including the authorization identity.

### Step 3 — Domain: Entities

**File:** `src/app/features/users/update_user/domain/entities.py`

Header: `# FEATURE: update_user — domain entities.`

Two entities:

- `ExistingUser(BaseModel)` — returned by `port.get_by_username`. Fields: `username: str`, `email: str`. Minimal: only what the use case needs to check ownership and duplicates.
- `UpdatedUserResult(BaseModel)` — returned by `UpdateUserUseCase.__call__`. Fields: `message: str = "User updated"`.

### Step 4 — Domain: Port

**File:** `src/app/features/users/update_user/domain/ports/update_user_port.py`

Header: `# FEATURE: update_user — port protocol.`

```
@runtime_checkable
class UpdateUserPort(Protocol):
    async def get_by_username(self, username: str) -> ExistingUser | None: ...
    async def email_exists(self, email: str) -> bool: ...
    async def username_exists(self, username: str) -> bool: ...
    async def update(self, command: UpdateUserCommand) -> None: ...
```

All four methods represent distinct use-case responsibilities. Following `CreateUserPort` precedent for multi-method ports on a single use case.

### Step 5 — Domain: Use case

**File:** `src/app/features/users/update_user/domain/use_case.py`

Header: `# FEATURE: update_user — use case.`

`UpdateUserUseCase.__init__(self, port: UpdateUserPort)` — single dependency.

`async def __call__(self, command: UpdateUserCommand) -> UpdatedUserResult`:

1. `existing = await self._port.get_by_username(command.target_username)` — if `None`, raise `NotFoundDomainError("User not found")`.
2. `check_owner(command.requester_username, existing.username)` — raises `ForbiddenDomainError` if mismatch.
3. If `command.email is not None and command.email != existing.email`: call `self._port.email_exists(command.email)`; raise `DuplicateValueDomainError("Email is already registered")` if `True`.
4. If `command.username is not None and command.username != existing.username`: call `self._port.username_exists(command.username)`; raise `DuplicateValueDomainError("Username not available")` if `True`.
5. `await self._port.update(command)`.
6. Return `UpdatedUserResult()`.

Import `check_owner` from `features/users/_shared/policies.py` using relative import: `from ..._shared.policies import check_owner`.

The use case never raises `HTTPException`. It does not catch.

### Step 6 — Data: Adapter

**File:** `src/app/features/users/update_user/data/adapter.py`

Header: `# FEATURE: update_user — data adapter.`

`class UpdateUserAdapter(UpdateUserPort)` — explicit inheritance required (per `agent_docs/architecture.md` § Terminology).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`get_by_username(username)`: `SELECT` from `User` where `username == username AND is_deleted == False`. Return `ExistingUser(username=row.username, email=row.email)` if found, else `None`. No `try/except` (per `agent_docs/error_handling.md` § Right shape: read-only query, no catch).

`email_exists(email)` and `username_exists(username)`: same pattern — `SELECT`, return bool, no catch.

`update(command)`: build a dict of non-`None` update fields from the command (excluding `target_username` and `requester_username`). Include `updated_at = datetime.now(UTC)`. Execute `sqlalchemy.update(User).where(User.username == command.target_username).values(**update_values)`. Narrow `try/except` around `session.commit()` only: catch `IntegrityError`, raise `DuplicateValueDomainError("Email or username already taken") from exc`. All other exceptions propagate.

### Step 7 — Presentation: Schemas

**File:** `src/app/features/users/update_user/presentation/schemas.py`

Header: `# FEATURE: update_user — request/response schemas.`

`UpdateUserRequest(BaseModel)`: `model_config = ConfigDict(extra="forbid")`. Fields mirror PRD contract — all optional, same validation constraints as `UserUpdate` in `features/users/schemas.py` (no inheritance; independent definition).

`UpdateUserResponse(BaseModel)`: `message: str`.

### Step 8 — Presentation: Router

**File:** `src/app/features/users/update_user/presentation/router.py`

Header: `# FEATURE: update_user — HTTP router.`

Follow the lazy-container-import pattern used in every existing router in this feature:

```python
def _get_update_user_use_case() -> UpdateUserUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.update_user_use_case()
```

Endpoint signature:

```python
@router.patch("/user/{username}", response_model=UpdateUserResponse, status_code=200)
async def update_user(
    username: str,
    request: UpdateUserRequest,
    current_user: Annotated[dict, Depends(get_current_user)],
    use_case: Annotated[UpdateUserUseCase, Depends(_get_update_user_use_case)],
) -> UpdateUserResponse:
```

Router body: build `UpdateUserCommand(target_username=username, requester_username=current_user["username"], **request.model_dump())`, await use case, return `UpdateUserResponse(message=result.message)`.

Import `get_current_user` from `...dependencies` (relative, stays within the `users` feature).

No `try/except`. No business logic. No direct DB access.

### Step 9 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — minimal addition only)

Add two providers after the last existing use-case provider:

```python
update_user_adapter = providers.Factory(
    UpdateUserAdapter,
    session_factory=session_factory,
)

update_user_use_case = providers.Factory(
    UpdateUserUseCase,
    port=update_user_adapter,
)
```

Add the corresponding imports at the top of the file.

### Step 10 — Router registration

**File:** `src/app/features/users/router.py`

Remove:
```python
from .use_cases.user_update import patch_user
router.patch("/user/{username}")(patch_user)
```

Add:
```python
from .update_user.presentation.router import router as update_user_router
router.include_router(update_user_router)
```

`bootstrap/router.py` is **not touched** — it already aggregates `users_router`.

### Step 11 — Delete old implementation

Delete `src/app/features/users/use_cases/user_update.py`. Verify no other file imports from it before deletion.

Also verify whether `UserUpdate` in `features/users/schemas.py` is referenced by any remaining file. If no other use case or router imports it, remove it to avoid dead code.

### Step 12 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/users/0006_update_user/update_user_outside_in_test.py -v
```

The slice is not done until all four pass, including the smoke test (`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** — `tests/features/users/0006_update_user/domain/test_use_case.py`.
  Mock `UpdateUserPort`. Assert:
  - `get_by_username` returns `None` → raises `NotFoundDomainError`.
  - `get_by_username` returns a user with a different username than `requester_username` → raises `ForbiddenDomainError`.
  - New email differs from existing and `email_exists` returns `True` → raises `DuplicateValueDomainError("Email is already registered")`.
  - New username differs from existing and `username_exists` returns `True` → raises `DuplicateValueDomainError("Username not available")`.
  - All checks pass → `port.update` is called and `UpdatedUserResult(message="User updated")` is returned.
  - Email unchanged (same as existing) → `email_exists` is **not** called.
  - Username unchanged (same as existing) → `username_exists` is **not** called.

- **Policy unit test** — `tests/features/users/_shared/test_policies.py`.
  No mocking needed. Assert `check_owner("alice", "alice")` returns `None`; `check_owner("alice", "bob")` raises `ForbiddenDomainError`.

- **Adapter unit test** — `tests/features/users/0006_update_user/data/test_adapter.py`.
  Mock `async_sessionmaker` / `AsyncSession`. Assert:
  - `get_by_username` returns `ExistingUser` when row found; `None` when not.
  - `email_exists` / `username_exists` return correct booleans.
  - `update` with `IntegrityError` on commit → `DuplicateValueDomainError`.
  - `update` with any other exception → propagates unchanged.

- **Endpoint integration test** — `tests/features/users/0006_update_user/presentation/test_router.py`.
  `httpx.AsyncClient` against test Postgres. Assert:
  - Valid token, owns the user, valid body → `200 {"message": "User updated"}`.
  - Valid token, does not own the user → `403`.
  - Non-existent `{username}` in path → `404`.
  - New email already taken → `409`.
  - New username already taken → `409`.
  - Missing / invalid token → `401`.
  - Invalid field (pattern mismatch) → `422`.

- **Outside-in test** — `tests/features/users/0006_update_user/update_user_outside_in_test.py`.
  Full HTTP stack, real adapter, test Postgres. Acceptance gate for the slice.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Password update — separate use case with its own security concerns.
- Superuser ability to update any user's profile.
- Returning the updated user record in the response — current contract returns only a confirmation message.
- Moving `check_owner` to `domain/policies.py` for cross-feature use — deferred until a second feature (e.g. posts) needs it.
- Rate limiting on `PATCH /user/{username}`.
- Cache invalidation — the slice does not implement caching on this endpoint.
- Migrating any other `use_cases/` files to the hexagonal structure.

## 8. Open questions

None. All design decisions were resolved in the grill-me session preceding this plan.
