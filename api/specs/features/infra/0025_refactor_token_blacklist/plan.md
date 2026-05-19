# 0025 · refactor_token_blacklist — Implementation plan

## 1. Header

- **Feature:** infra
- **Slice:** 0025_refactor_token_blacklist
- **PRD:** ./prd.md
- **Reference slice:** ../../users/0002_refactor_create_user_adapter/plan.md (pure refactor, no API change)
- **HTTP path:** none — refactor only; the auth endpoints (`POST /api/v1/logout`, `POST /api/v1/refresh`) keep their existing HTTP contract
- **STABLE files touched:**
  - `src/app/ports/token_blacklist.py` — add `is_blacklisted`, update `blacklist` signature
  - `src/app/adapters/db/token_blacklist/adapter.py` — new STABLE file (hand-written adapter)
  - `src/app/core/security.py` — remove infra import, accept port by parameter
  - `src/app/bootstrap/container.py` — swap provider, add modules to wiring
  - `src/app/shared_dependencies.py` — inject adapter via DI, pass to `verify_token`

## 2. Context summary

Three architecture violations corrupt the token-blacklist path: `core/security.py`
imports a concrete adapter from `adapters/` (inverted dependency), the adapter is
built on FastCRUD (forbidden), and the concrete service lives in `core/` instead
of `adapters/`. This slice eliminates all three: a new `TokenBlacklistAdapter`
(plain SQLAlchemy) replaces both the FastCRUD repository and the misplaced service,
the port is expanded with `is_blacklisted`, and `core/security.py` is refactored to
receive the port by parameter injection. After this slice `python scripts/check_arch.py`
reports `Core must not import Adapters` as KEPT. No HTTP contract changes; login,
logout, and refresh behavior remain identical from the consumer's perspective.

## 3. API contract

No new HTTP contract. The three existing endpoints are unchanged from the consumer's
perspective:

| Endpoint | Change |
|---|---|
| `POST /api/v1/login` | none — no blacklist involvement |
| `POST /api/v1/logout` | internal wiring only; request/response/status codes unchanged |
| `POST /api/v1/refresh` | internal wiring only; request/response/status codes unchanged |
| Any authenticated endpoint | `get_current_user` uses port for blacklist check; behavior identical |

Acceptance signal: `python scripts/check_arch.py` must pass with
`Core must not import Adapters` reported as **KEPT**.

## 4. File structure

No new feature folder. Modifications and one new adapter file:

```
src/app/
├── ports/
│   └── token_blacklist.py           ← STABLE, modify: add is_blacklisted, update blacklist sig
├── adapters/db/token_blacklist/
│   ├── adapter.py                   ← STABLE, create: TokenBlacklistAdapter
│   ├── repository.py                ← DELETE (FastCRUD)
│   └── model.py                     ← unchanged
├── core/
│   ├── security.py                  ← STABLE, modify: remove infra import, accept port param
│   └── token_blacklist_service.py   ← DELETE (superseded by adapter)
├── bootstrap/
│   └── container.py                 ← STABLE, modify: swap provider, add wiring
└── shared_dependencies.py           ← STABLE, modify: inject adapter, pass to verify_token

src/app/features/auth/
└── router.py                        ← FEATURE, modify: inject adapter for logout and refresh
```

## 5. Implementation steps

### Step 1 — Port: expand `TokenBlacklistPort`

File: `src/app/ports/token_blacklist.py`

Change the port to declare two methods. Add `datetime` import from stdlib.
`expires_at` is passed in by the caller (security.py already decodes the JWT
there); the adapter does not need to re-decode.

```python
# STABLE: Port protocol for token blacklisting.
from datetime import datetime
from typing import Protocol, runtime_checkable


@runtime_checkable
class TokenBlacklistPort(Protocol):
    async def is_blacklisted(self, token: str) -> bool: ...
    async def blacklist(self, token: str, expires_at: datetime) -> None: ...
```

Verify: `mypy src/app` passes (Protocol structural check). The existing
`TokenBlacklistService.blacklist(token)` now has a mismatched signature — that
class is deleted in Step 4.

### Step 2 — Adapter: create `TokenBlacklistAdapter`

File: `src/app/adapters/db/token_blacklist/adapter.py` (new, STABLE)

```python
# STABLE: Hand-written adapter for token blacklisting.
from datetime import datetime

from sqlalchemy import exists, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from ...ports.token_blacklist import TokenBlacklistPort
from .model import TokenBlacklist


class TokenBlacklistAdapter(TokenBlacklistPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def is_blacklisted(self, token: str) -> bool:
        async with self._session_factory() as session:
            result = await session.execute(
                select(exists().where(TokenBlacklist.token == token))
            )
            return bool(result.scalar())

    async def blacklist(self, token: str, expires_at: datetime) -> None:
        async with self._session_factory() as session:
            session.add(TokenBlacklist(token=token, expires_at=expires_at))
            await session.commit()
```

No `try/except`. A unique-constraint violation on `token` could raise
`IntegrityError`, but double-blacklisting the same token is not a meaningful
domain event — propagate it to the global handler. Per
`agent_docs/error_handling.md`, catch only when there is business meaning to
translate.

Verify: `mypy src/app` confirms `TokenBlacklistAdapter` structurally satisfies
`TokenBlacklistPort`. `isinstance(TokenBlacklistAdapter(...), TokenBlacklistPort)`
returns `True` (enabled by `@runtime_checkable`).

### Step 3 — Core: refactor `security.py`

File: `src/app/core/security.py`

Remove:
```python
from ..adapters.db.token_blacklist.repository import crud_token_blacklist
```

Add:
```python
from ..ports.token_blacklist import TokenBlacklistPort
```

Update the three affected functions to accept `blacklist: TokenBlacklistPort`
instead of `db: AsyncSession`:

**`verify_token`** — replace blacklist check:
```python
async def verify_token(
    token: str,
    expected_token_type: TokenType,
    blacklist: TokenBlacklistPort,
) -> TokenData | None:
    if await blacklist.is_blacklisted(token):
        return None
    ...  # JWT decode logic unchanged
```

**`blacklist_tokens`** — replace CRUD call:
```python
async def blacklist_tokens(
    access_token: str,
    refresh_token: str,
    blacklist: TokenBlacklistPort,
) -> None:
    for token in [access_token, refresh_token]:
        payload = jwt.decode(token, SECRET_KEY.get_secret_value(), algorithms=[ALGORITHM])
        exp_timestamp = payload.get("exp")
        if exp_timestamp is not None:
            expires_at = datetime.fromtimestamp(exp_timestamp)
            await blacklist.blacklist(token, expires_at)
```

**`blacklist_token`** (singular) — same treatment:
```python
async def blacklist_token(token: str, blacklist: TokenBlacklistPort) -> None:
    payload = jwt.decode(token, SECRET_KEY.get_secret_value(), algorithms=[ALGORITHM])
    exp_timestamp = payload.get("exp")
    if exp_timestamp is not None:
        expires_at = datetime.fromtimestamp(exp_timestamp)
        await blacklist.blacklist(token, expires_at)
```

Remove `from sqlalchemy.ext.asyncio import AsyncSession` if `AsyncSession` no
longer appears anywhere else in the file after this change.

Remove `TokenBlacklistCreate` from the `from .schemas import ...` line if it is
no longer used.

Verify: `ruff check src/app` — no unused imports. `mypy src/app` — passes.

### Step 4 — Delete superseded files

Delete `src/app/core/token_blacklist_service.py` (concrete adapter in wrong layer).
Delete `src/app/adapters/db/token_blacklist/repository.py` (FastCRUD, forbidden).

Verify: `ruff check src/app` — no dangling references. `mypy src/app` — passes.

### Step 5 — Bootstrap: update `container.py`

File: `src/app/bootstrap/container.py`

Remove:
```python
from ..core.token_blacklist_service import TokenBlacklistService
```

Add:
```python
from ..adapters.db.token_blacklist.adapter import TokenBlacklistAdapter
```

Replace provider:
```python
# before:
token_blacklist_service = providers.Factory(
    TokenBlacklistService,
    session_factory=session_factory,
)

# after:
token_blacklist_adapter = providers.Factory(
    TokenBlacklistAdapter,
    session_factory=session_factory,
)
```

Add the two modules that will use `Provide[Container.token_blacklist_adapter]`
to the wiring configuration (or to the `container.wire(modules=[...])` call in
`bootstrap/factory.py`, whichever form the project uses):

- `"app.shared_dependencies"`
- `"app.features.auth.router"`

Verify: `mypy src/app` — passes.

### Step 6 — Shared dependencies: inject adapter

File: `src/app/shared_dependencies.py`

Add imports:
```python
from dependency_injector.wiring import Provide
from .bootstrap.container import Container
from .ports.token_blacklist import TokenBlacklistPort
```

Update `get_current_user`:
```python
async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[AsyncSession, Depends(async_get_db)],
    blacklist: Annotated[TokenBlacklistPort, Depends(Provide[Container.token_blacklist_adapter])],
) -> dict[str, Any]:
    token_data = await verify_token(token, TokenType.ACCESS, blacklist)
    ...  # user lookup via db unchanged
```

Update `get_optional_user` to extract the token and pass `blacklist` to
`verify_token`. The `db` parameter is retained for the user lookup that follows
the blacklist check.

Verify: `mypy src/app` — passes. No change to public behavior.

### Step 7 — Auth router: inject adapter

File: `src/app/features/auth/router.py`

Add imports:
```python
from typing import Annotated
from dependency_injector.wiring import Provide
from ...bootstrap.container import Container
from ...ports.token_blacklist import TokenBlacklistPort
```

Update `refresh_access_token` — replace `db: AsyncSession` with `blacklist`:
```python
@router.post("/refresh")
async def refresh_access_token(
    request: Request,
    blacklist: Annotated[TokenBlacklistPort, Depends(Provide[Container.token_blacklist_adapter])],
) -> dict[str, str]:
    refresh_token = request.cookies.get("refresh_token")
    if not refresh_token:
        raise UnauthorizedException("Refresh token missing.")
    user_data = await verify_token(refresh_token, TokenType.REFRESH, blacklist)
    ...
```

Update `logout` — replace `db: AsyncSession` with `blacklist`:
```python
@router.post("/logout")
async def logout(
    response: Response,
    access_token: str = Depends(oauth2_scheme),
    refresh_token: Optional[str] = Cookie(None, alias="refresh_token"),
    blacklist: Annotated[TokenBlacklistPort, Depends(Provide[Container.token_blacklist_adapter])] = ...,
) -> dict[str, str]:
    ...
    await blacklist_tokens(access_token=access_token, refresh_token=refresh_token, blacklist=blacklist)
    ...
```

Remove `from ...adapters.db.session import async_get_db` and the `db` parameter
from both endpoints if no longer used.

Verify: `mypy src/app` — passes.

### Step 8 — Architecture gate

Run `python scripts/check_arch.py`. The `Core must not import Adapters` contract
must report **KEPT**. If any other contract regresses, investigate before
proceeding.

### Step 9 — Full verification

Run in order:
```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

All four must pass. The smoke test (`tests/smoke/test_app_starts.py`) is the
final gate — it boots the app under uvicorn and catches import issues that pytest
with `pythonpath = ["src"]` would mask.

## 6. Tests planned

**Use-case unit test** — **opted out.** This slice introduces no use-case class.
There is no business logic to unit-test in isolation.

**Adapter unit test** — `tests/adapters/db/token_blacklist/test_adapter.py`

Mock the `async_sessionmaker` and the `AsyncSession` context manager. Assert:
- `is_blacklisted` returns `False` when the EXISTS query returns falsy.
- `is_blacklisted` returns `True` when the EXISTS query returns truthy.
- `blacklist` adds a row and commits (verify `session.add` and `session.commit`
  are called with the right arguments).
- An `OperationalError` from `session.execute` propagates unchanged through
  `is_blacklisted` (no catch, adapter is transparent).
- An `OperationalError` from `session.commit` propagates unchanged through
  `blacklist` (same reasoning).

**Endpoint integration test** — `tests/features/auth/test_auth.py`

Use `httpx.AsyncClient` against the running app with the test Postgres. Seed a
user. Verify:
- Login (`POST /login`) returns an access token and sets a refresh cookie.
- Logout (`POST /logout`) returns 200 and succeeds.
- A subsequent authenticated request using the blacklisted access token returns
  401.
- A subsequent token refresh using the blacklisted refresh cookie returns 401
  (or fails with missing/invalid token).

This is the regression guard; behavior must be identical to pre-refactor.

**Outside-in test** — `tests/features/infra/0025_refactor_token_blacklist/refactor_token_blacklist_outside_in_test.py`

Full stack through `httpx.AsyncClient` with the test Postgres and the real
`TokenBlacklistAdapter`. No mocks except at external system boundaries (Redis
is not involved in this path).

Scenarios:
1. **Blacklisted access token rejected** — login → logout → use the old token
   on any authenticated endpoint → expect 401.
2. **Valid token accepted** — login → use the fresh token → expect 200.
3. **Architecture gate** — `subprocess.run(["python", "scripts/check_arch.py"])`
   exits with code 0 and its stdout contains `"KEPT"` for the
   `Core must not import Adapters` contract. This is the primary acceptance
   signal and must be in the outside-in test.

## 7. Out of scope for this slice

- Migrating `features/auth/router.py` to the full VSA slice pattern.
- Fixing the `VSA Feature Domains are Independent` import-linter violation
  (`posts ↔ users` transitive through `bootstrap/container`).
- Fixing the `features/posts/router.py` direct import of `features/users/schemas`.
- Token expiry cleanup (deleting old rows from `token_blacklist` table).
- Any change to JWT encoding/decoding logic or token expiry values.
- Rate limiting on auth endpoints (unchanged).
- `TokenBlacklistCreate` schema in `core/schemas.py` — leave in place until a
  separate cleanup slice removes it (it may still be referenced elsewhere).

## 8. Open questions

None. All decisions are stated in the PRD.
