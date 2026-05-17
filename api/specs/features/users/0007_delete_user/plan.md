# 0007 · delete_user — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0007_delete_user
- **PRD:** ./prd.md
- **Reference slice:** `../0006_update_user/plan.md` — same ownership-check + write shape; closest operation match in the roadmap.
- **HTTP path:** `DELETE /api/v1/user/{username}`
- **STABLE files touched:**
  - `ports/token_blacklist.py` — new file in the STABLE `ports/` layer (approved in the design session; analogous to adding a new port alongside `cache.py` / `queue.py`).
  - `core/token_blacklist_service.py` — new file in the STABLE `core/` layer (approved in the design session).
  - `bootstrap/container.py` — add `token_blacklist_service`, `delete_user_adapter`, `delete_user_use_case` providers.
  - `features/users/router.py` — swap the inline `erase_user` wiring for `include_router(delete_user_router)`.

## 2. Context summary

An authenticated user sends `DELETE /api/v1/user/{username}` to soft-delete their own account. The router resolves the caller's identity via `get_current_user`, extracts the raw access token via `oauth2_scheme`, and builds a `DeleteUserCommand` carrying both the target username (path param) and the requester's username (from the token). It delegates to `DeleteUserUseCase`, which enforces existence and ownership before calling `port.soft_delete`. After the use-case returns, the router calls the injected `TokenBlacklistService` to invalidate the access token. The response is `{"message": "User deleted"}` with HTTP 200. The old flat function in `use_cases/user_delete.py` is deleted once the new slice is live. Two cross-cutting infrastructure pieces are introduced alongside the slice: `TokenBlacklistPort` (global port interface) and `TokenBlacklistService` (core implementation).

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `username` | `str` | Username of the account to delete |

**Request body:** none.

**Response body** (`DeleteUserResponse`):

| Field | Type | Notes |
|---|---|---|
| `message` | `str` | Always `"User deleted"` on success |

**Status codes:**

- `200 OK` — soft-delete applied and token blacklisted.
- `401 Unauthorized` — token missing, invalid, or already blacklisted (`UnauthorizedException` from `get_current_user`).
- `403 Forbidden` — `ForbiddenDomainError`; requester does not own the target account.
- `404 Not Found` — `NotFoundDomainError`; `username` does not exist or is already soft-deleted.
- `500 Internal Server Error` — any infrastructure failure (DB, JWT decode on blacklist write) propagates to the global catch-all handler.

## 4. File structure

New files:

```
src/app/ports/
└── token_blacklist.py          # TokenBlacklistPort  [STABLE addition]

src/app/core/
└── token_blacklist_service.py  # TokenBlacklistService  [STABLE addition]

src/app/features/users/delete_user/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py             # DeleteUserCommand
│   ├── entities.py             # DeleteUserTarget, DeleteUserResult
│   ├── ports/
│   │   ├── __init__.py
│   │   └── delete_user_port.py # DeleteUserPort
│   └── use_case.py             # DeleteUserUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py              # DeleteUserAdapter
└── presentation/
    ├── __init__.py
    ├── router.py
    └── schemas.py              # DeleteUserResponse
```

Files modified:

```
src/app/bootstrap/container.py           # add three new providers
src/app/features/users/router.py         # swap inline erase_user for include_router
```

Files deleted:

```
src/app/features/users/use_cases/user_delete.py
```

No new ORM model. No Alembic migration (no schema change).

## 5. Implementation steps

### Step 1 — STABLE additions: port interface + service class

**File:** `src/app/ports/token_blacklist.py`

Header: `# STABLE: Port protocol for token blacklisting.`

```python
from typing import Protocol, runtime_checkable

@runtime_checkable
class TokenBlacklistPort(Protocol):
    async def blacklist(self, token: str) -> None: ...
```

`@runtime_checkable` is mandatory (per `agent_docs/architecture.md` § Terminology). One method, matching the single responsibility of the service.

---

**File:** `src/app/core/token_blacklist_service.py`

Header: `# STABLE: Concrete token-blacklist service.`

`class TokenBlacklistService(TokenBlacklistPort)` — explicit inheritance from the port is mandatory (per `agent_docs/architecture.md` § Adapter pattern).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`async def blacklist(self, token: str) -> None`: decode the JWT (using `SECRET_KEY` and `ALGORITHM` from `core/security.py`), extract `exp` timestamp, write a `TokenBlacklistCreate` record via `crud_token_blacklist.create`. Uses its own session opened from `self._session_factory`. No `try/except` — JWT decode errors and DB errors propagate to the global handler. `security.py` is not modified.

Imports allowed: `stdlib`, `third-party` (`jose`, `sqlalchemy`), `core/security.py` constants, and the token-blacklist repository from `adapters/db/token_blacklist/repository.py`. Never imports from `features/`.

### Step 2 — Domain: Command and Entities

**File:** `src/app/features/users/delete_user/domain/commands.py`

Header: `# FEATURE: delete_user — domain command.`

```python
class DeleteUserCommand(BaseModel):
    target_username: str
    requester_username: str
```

No optional fields. The use-case needs only identities to enforce ownership and locate the row.

---

**File:** `src/app/features/users/delete_user/domain/entities.py`

Header: `# FEATURE: delete_user — domain entities.`

Two classes:

- `DeleteUserTarget(BaseModel)`: `username: str` — minimal fetch result; only `username` is needed for the ownership check.
- `DeleteUserResult(BaseModel)`: `message: str = "User deleted"` — use-case return value.

`BaseModel` only. No framework imports. No field from `update_user/domain/entities.py` is shared; they are independent.

### Step 3 — Domain: Port

**File:** `src/app/features/users/delete_user/domain/ports/delete_user_port.py`

Header: `# FEATURE: delete_user — port protocol.`

```python
@runtime_checkable
class DeleteUserPort(Protocol):
    async def get_by_username(self, username: str) -> DeleteUserTarget | None: ...
    async def soft_delete(self, username: str) -> None: ...
```

Two methods: one for the existence/ownership check, one for the write. Per `agent_docs/architecture.md`, `@runtime_checkable` is mandatory.

### Step 4 — Domain: Use case

**File:** `src/app/features/users/delete_user/domain/use_case.py`

Header: `# FEATURE: delete_user — use case.`

`class DeleteUserUseCase`:
- `__init__(self, port: DeleteUserPort)`.
- `async def __call__(self, command: DeleteUserCommand) -> DeleteUserResult`:
  1. `target = await self._port.get_by_username(command.target_username)` — if `None`, raise `NotFoundDomainError("User not found")`.
  2. `check_owner(command.requester_username, target.username)` — raises `ForbiddenDomainError` if mismatch.
  3. `await self._port.soft_delete(command.target_username)`.
  4. Return `DeleteUserResult()`.

Import `check_owner` from `..._shared.policies` (relative, within the `users` feature). Never raises `HTTPException`. Never catches.

### Step 5 — Data: Adapter

**File:** `src/app/features/users/delete_user/data/adapter.py`

Header: `# FEATURE: delete_user — data adapter.`

`class DeleteUserAdapter(DeleteUserPort)` — explicit inheritance required (per `agent_docs/architecture.md` § Terminology).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`get_by_username(username)`: `SELECT` from `User` where `User.username == username AND User.is_deleted == False`. Return `DeleteUserTarget(username=row.username)` if found, else `None`. No `try/except` (per `agent_docs/error_handling.md` § Right shape: read-only query, no catch).

`soft_delete(username)`: execute `UPDATE User SET is_deleted = True, deleted_at = datetime.now(UTC) WHERE User.username == username`. No narrow `try/except` — a soft-delete UPDATE has no unique-constraint path to catch; any DB error propagates to the global handler.

### Step 6 — Presentation: Schemas

**File:** `src/app/features/users/delete_user/presentation/schemas.py`

Header: `# FEATURE: delete_user — request/response schemas.`

Only a response schema is needed (no request body):

```python
class DeleteUserResponse(BaseModel):
    message: str
```

No `DeleteUserRequest` — DELETE carries no body; all inputs come from the path param and the auth token.

### Step 7 — Presentation: Router

**File:** `src/app/features/users/delete_user/presentation/router.py`

Header: `# FEATURE: delete_user — HTTP router.`

Follow the lazy-container-import pattern used by every existing router in this feature:

```python
def _get_delete_user_use_case() -> DeleteUserUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.delete_user_use_case()

def _get_token_blacklist_service() -> TokenBlacklistService:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.token_blacklist_service()
```

Endpoint signature:

```python
@router.delete("/user/{username}", response_model=DeleteUserResponse, status_code=200)
async def delete_user_endpoint(
    username: str,
    current_user: Annotated[dict, Depends(get_current_user)],
    token: Annotated[str, Depends(oauth2_scheme)],
    use_case: Annotated[DeleteUserUseCase, Depends(_get_delete_user_use_case)],
    token_blacklist: Annotated[TokenBlacklistService, Depends(_get_token_blacklist_service)],
) -> DeleteUserResponse:
```

Body:
1. Build `DeleteUserCommand(target_username=username, requester_username=current_user["username"])`.
2. `await use_case(command)`.
3. `await token_blacklist.blacklist(token)`.
4. Return `DeleteUserResponse(message="User deleted")`.

Import `get_current_user` from `...dependencies` and `oauth2_scheme` from `....core.security` (relative). No `try/except`. No business logic. No direct DB access.

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — minimal addition only)

Add three providers after the last existing use-case provider:

```python
token_blacklist_service = providers.Factory(
    TokenBlacklistService,
    session_factory=session_factory,
)

delete_user_adapter = providers.Factory(
    DeleteUserAdapter,
    session_factory=session_factory,
)

delete_user_use_case = providers.Factory(
    DeleteUserUseCase,
    port=delete_user_adapter,
)
```

Add the three corresponding imports at the top of the file.

### Step 9 — Router registration

**File:** `src/app/features/users/router.py`

Remove:
```python
from .use_cases.user_delete import erase_user
router.delete("/user/{username}")(erase_user)
```

Add:
```python
from .delete_user.presentation.router import router as delete_user_router
router.include_router(delete_user_router)
```

`bootstrap/router.py` is **not touched** — it already aggregates `users_router` and `users_router` already aggregates all sub-routers.

### Step 10 — Delete old implementation

Delete `src/app/features/users/use_cases/user_delete.py`. Verify no other file imports from it before deletion by grepping for `user_delete` and `erase_user` across `src/`.

### Step 11 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/users/0007_delete_user/delete_user_outside_in_test.py -v
```

The slice is not done until all four pass, including the smoke test (`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** — `tests/features/users/0007_delete_user/domain/test_use_case.py`.
  Mock `DeleteUserPort`. Assert:
  - `get_by_username` returns `None` → raises `NotFoundDomainError`.
  - `get_by_username` returns a target whose `username` differs from `requester_username` → raises `ForbiddenDomainError`.
  - Both checks pass → `port.soft_delete` is called and `DeleteUserResult(message="User deleted")` is returned.

- **Adapter unit test** — `tests/features/users/0007_delete_user/data/test_adapter.py`.
  Mock async session factory. Assert:
  - `get_by_username` returns `DeleteUserTarget` when row found with `is_deleted == False`.
  - `get_by_username` returns `None` when row is missing or `is_deleted == True`.
  - `soft_delete` executes an UPDATE setting `is_deleted = True` and `deleted_at` to a non-null datetime.
  - Any DB exception from `soft_delete` propagates unchanged (no catch to assert against).

- **`TokenBlacklistService` unit test** — `tests/core/test_token_blacklist_service.py`.
  Mock session factory and `crud_token_blacklist`. Assert that a valid JWT results in a `create` call with the correct `expires_at`. Assert that an invalid JWT (decode error) propagates the `JWTError`.

- **Endpoint integration test** — `tests/features/users/0007_delete_user/presentation/test_router.py`.
  `httpx.AsyncClient` against test Postgres. Assert:
  - Authenticated DELETE, owns the account → `200 {"message": "User deleted"}`.
  - User row has `is_deleted == True` after the request.
  - Non-existent `{username}` → `404`.
  - Valid token but wrong user → `403`.
  - Missing / invalid token → `401`.
  Prior art: `tests/features/users/0006_update_user/presentation/test_router.py`.

- **Outside-in test** — `tests/features/users/0007_delete_user/delete_user_outside_in_test.py`.
  Full HTTP stack: real adapter, real `TokenBlacklistService`, test Postgres. Asserts the user row has `is_deleted == True` after the call and the access token appears in the `token_blacklist` table. Acceptance gate for the slice.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Hard (permanent) deletion — handled separately by the `db_user` endpoint.
- Refresh-token blacklisting on account deletion — the existing behavior only blacklisted the access token; this slice preserves that contract.
- Refactoring `auth/router.py` logout to use `TokenBlacklistService` — deferred; the service exists after this slice and can be adopted in a future refactor.
- Modifying `core/security.py` — the existing `blacklist_token` function is left in place.
- Moving `ExistingUser` from `update_user` to `users/_shared/` — premature abstraction.
- Cache invalidation — no caching is applied to this endpoint.
- Rate limiting — not applied; the endpoint is behind auth.

## 8. Open questions

None. All design decisions were resolved in the grill-me session preceding this plan.
