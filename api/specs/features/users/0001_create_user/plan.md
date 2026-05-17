# 0001 · create_user — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0001_create_user
- **PRD:** ./prd.md
- **Reference slice (if any):** None — this is the first slice in the project; no shape-match exists in the roadmap.
- **HTTP path:** `POST /api/v1/user`
- **STABLE files touched:**
  - `bootstrap/container.py` — new file; becomes STABLE once written (per `agent_docs/stable_vs_feature.md`).
  - `features/users/router.py` — FEATURE file; one import removed, one `include_router` call added.

## 2. Context summary

This slice replaces the free-function use case `features/users/use_cases/user_create.py` with a
fully conformant hexagonal slice. A client `POST`s `name`, `username`, `email`, and `password` to
`/api/v1/user`. The presentation router validates the request, converts it to a
`CreateUserCommand`, and delegates to `CreateUserUseCase`. The use case checks email uniqueness,
then username uniqueness (preserving the existing check order), hashes the password, builds a
`CreateUserInternalCommand`, and delegates persistence to `CreateUserPort`. The adapter implements
the port using SQLAlchemy against the existing `User` ORM model and returns a `UserRead` entity.
The response is `201 Created` with the user's public fields. Duplicate email or username yields
`409 Conflict`.

## 3. API contract

**Request body** (`CreateUserRequest`):

| Field | Type | Validation |
|---|---|---|
| `name` | `str` | `min_length=2`, `max_length=30` |
| `username` | `str` | `min_length=2`, `max_length=20`, `pattern=r"^[a-z0-9]+$"` |
| `email` | `EmailStr` | valid e-mail |
| `password` | `str` | `pattern=r"^.{8,}|[0-9]+|[A-Z]+|[a-z]+|[^a-zA-Z0-9]+$"` |

**Path/query params:** none.

**Response body** (`CreateUserResponse`):

| Field | Type |
|---|---|
| `id` | `int` |
| `name` | `str` |
| `username` | `str` |
| `email` | `EmailStr` |
| `profile_image_url` | `str` |
| `tier_id` | `int \| None` |

**Status codes:**

- `201 Created` — user created successfully.
- `409 Conflict` — `DuplicateValueDomainError` raised by the use case (email already registered,
  or username not available). The exception handler returns
  `{"error": {"code": "duplicatevalue", "message": "<specific message>"}}`.
- `422 Unprocessable Entity` — FastAPI/Pydantic field-level validation failure (missing field,
  wrong type, pattern mismatch).
- `500` — unexpected adapter failure; logged at ERROR level via the outer catch.

## 4. File structure

New files created:

```
src/app/features/users/create_user/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py              # CreateUserCommand, CreateUserInternalCommand
│   ├── ports/
│   │   ├── __init__.py
│   │   └── create_user_port.py  # CreateUserPort (Protocol)
│   └── use_case.py              # CreateUserUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py               # CreateUserAdapter
└── presentation/
    ├── __init__.py
    ├── router.py
    └── schemas.py               # CreateUserRequest, CreateUserResponse
```

New bootstrap file:

```
src/app/bootstrap/container.py   # Container (dependency_injector)
```

Existing files modified:

```
src/app/features/users/router.py          # remove write_user; add include_router
src/app/features/users/use_cases/user_create.py   # deleted
```

No new ORM model. No Alembic migration. The existing `adapters/db/models/user.py` (`User`) is
used unchanged. `features/users/schemas.py` continues as the shared entity file — `UserRead` is
imported from there.

## 5. Implementation steps

### Step 1 — Domain: Commands

**File:** `src/app/features/users/create_user/domain/commands.py`

```python
# FEATURE: create_user — domain commands.
from pydantic import BaseModel


class CreateUserCommand(BaseModel):
    name: str
    username: str
    email: str
    password: str  # plain text; hashing happens in the use case


class CreateUserInternalCommand(BaseModel):
    name: str
    username: str
    email: str
    hashed_password: str  # plain password replaced before this is constructed
```

Verify: `from app.features.users.create_user.domain.commands import CreateUserCommand` imports
cleanly with no framework dependencies.

### Step 2 — Domain: Port

**File:** `src/app/features/users/create_user/domain/ports/create_user_port.py`

```python
# FEATURE: create_user — port protocol.
from typing import Protocol

from app.features.users.create_user.domain.commands import CreateUserInternalCommand
from app.features.users.schemas import UserRead


class CreateUserPort(Protocol):
    async def email_exists(self, email: str) -> bool: ...
    async def username_exists(self, username: str) -> bool: ...
    async def create(self, command: CreateUserInternalCommand) -> UserRead: ...
```

`Protocol` from `typing` — no framework imports. `UserRead` comes from
`features/users/schemas.py` (the feature's shared entity file), which is permitted per the
cross-slice rules.

### Step 3 — Domain: Use case

**File:** `src/app/features/users/create_user/domain/use_case.py`

```python
# FEATURE: create_user — use case.
from app.core.security import get_password_hash
from app.domain.errors import DuplicateValueDomainError
from app.features.users.create_user.domain.commands import (
    CreateUserCommand,
    CreateUserInternalCommand,
)
from app.features.users.create_user.domain.ports.create_user_port import CreateUserPort
from app.features.users.schemas import UserRead


class CreateUserUseCase:
    def __init__(self, port: CreateUserPort) -> None:
        self._port = port

    async def __call__(self, command: CreateUserCommand) -> UserRead:
        if await self._port.email_exists(command.email):
            raise DuplicateValueDomainError("Email is already registered")
        if await self._port.username_exists(command.username):
            raise DuplicateValueDomainError("Username not available")
        hashed = get_password_hash(command.password)
        internal = CreateUserInternalCommand(
            name=command.name,
            username=command.username,
            email=command.email,
            hashed_password=hashed,
        )
        return await self._port.create(internal)
```

Note: `get_password_hash` lives in `core/security.py`. Importing from `core/` inside a feature's
`domain/` layer is a borderline concern — `core/` is technically not stdlib/pydantic. This is
flagged as an open question (see Section 8). The alternative is to perform hashing in the
presentation layer or pass hashing as an injected dependency.

The check order (email first, username second) is intentional — it matches the existing
implementation and must not be reversed.

### Step 4 — Data: Adapter

**File:** `src/app/features/users/create_user/data/adapter.py`

```python
# FEATURE: create_user — data adapter.
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.adapters.db.models.user import User
from app.core.logger import logger
from app.domain.errors import DuplicateValueDomainError, DomainError, UnknownDomainError
from app.features.users.create_user.domain.commands import CreateUserInternalCommand
from app.features.users.schemas import UserRead


class CreateUserAdapter:
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def email_exists(self, email: str) -> bool:
        try:
            try:
                async with self._session_factory() as session:
                    result = await session.execute(
                        select(User).where(User.email == email).limit(1)
                    )
                    return result.scalar_one_or_none() is not None
            except Exception:
                raise
        except Exception as exc:
            if isinstance(exc, DomainError):
                raise
            logger.error("CreateUserAdapter.email_exists failed unexpectedly", exc_info=True)
            raise UnknownDomainError("create_user adapter failed") from exc

    async def username_exists(self, username: str) -> bool:
        try:
            try:
                async with self._session_factory() as session:
                    result = await session.execute(
                        select(User).where(User.username == username).limit(1)
                    )
                    return result.scalar_one_or_none() is not None
            except Exception:
                raise
        except Exception as exc:
            if isinstance(exc, DomainError):
                raise
            logger.error("CreateUserAdapter.username_exists failed unexpectedly", exc_info=True)
            raise UnknownDomainError("create_user adapter failed") from exc

    async def create(self, command: CreateUserInternalCommand) -> UserRead:
        try:
            try:
                async with self._session_factory() as session:
                    model = User(
                        name=command.name,
                        username=command.username,
                        email=command.email,
                        hashed_password=command.hashed_password,
                    )
                    session.add(model)
                    await session.commit()
                    await session.refresh(model)
                    return UserRead.model_validate(model)
            except IntegrityError as exc:
                raise DuplicateValueDomainError(
                    "Username or email already taken"
                ) from exc
        except Exception as exc:
            if isinstance(exc, DomainError):
                raise
            logger.error("CreateUserAdapter.create failed unexpectedly", exc_info=True)
            raise UnknownDomainError("create_user adapter failed") from exc
```

Double try/except applied per `agent_docs/error_handling.md`. For `email_exists` and
`username_exists`, the inner block has no specific exception mapping (SELECT has no `IntegrityError`
path); the outer catch is the safety net. For `create`, the inner block maps `IntegrityError` →
`DuplicateValueDomainError`.

**Dependency on `UnknownDomainError`**: see Open Questions (Section 8).

The session factory injected is `local_session` from `adapters/db/session.py` — an already-
instantiated `async_sessionmaker[AsyncSession]`. Each method opens its own short-lived session via
`async with self._session_factory() as session`.

### Step 5 — Presentation: Schemas

**File:** `src/app/features/users/create_user/presentation/schemas.py`

```python
# FEATURE: create_user — request/response schemas.
from pydantic import BaseModel, ConfigDict, EmailStr, Field


class CreateUserRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    name: str = Field(min_length=2, max_length=30)
    username: str = Field(min_length=2, max_length=20, pattern=r"^[a-z0-9]+$")
    email: EmailStr
    password: str = Field(pattern=r"^.{8,}|[0-9]+|[A-Z]+|[a-z]+|[^a-zA-Z0-9]+$")


class CreateUserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    username: str
    email: EmailStr
    profile_image_url: str
    tier_id: int | None
```

Field constraints mirror those in `features/users/schemas.py::UserCreate` and `UserRead` to
maintain consistent validation across the existing and new implementation.

### Step 6 — Presentation: Router

**File:** `src/app/features/users/create_user/presentation/router.py`

```python
# FEATURE: create_user — router.
from typing import Annotated

from dependency_injector.wiring import Provide
from fastapi import APIRouter, Depends, status

from app.bootstrap.container import Container
from app.features.users.create_user.domain.commands import CreateUserCommand
from app.features.users.create_user.domain.use_case import CreateUserUseCase
from app.features.users.create_user.presentation.schemas import (
    CreateUserRequest,
    CreateUserResponse,
)

router = APIRouter(tags=["users"])


@router.post(
    "/user",
    response_model=CreateUserResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_user_endpoint(
    request: CreateUserRequest,
    use_case: Annotated[
        CreateUserUseCase,
        Depends(Provide[Container.create_user_use_case]),
    ],
) -> CreateUserResponse:
    command = CreateUserCommand(**request.model_dump())
    user = await use_case(command)
    return CreateUserResponse.model_validate(user)
```

The endpoint path `/user` (singular) matches the existing API to avoid a breaking change. The
`/api/v1` prefix is applied once in `bootstrap/router.py`.

### Step 7 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (new; `# STABLE:` once written)

```python
# STABLE: dependency_injector container. Add providers when wiring new slices.
from dependency_injector import containers, providers

from app.adapters.db.session import local_session
from app.features.users.create_user.data.adapter import CreateUserAdapter
from app.features.users.create_user.domain.use_case import CreateUserUseCase


class Container(containers.DeclarativeContainer):
    wiring_config = containers.WiringConfiguration(
        modules=[
            "app.features.users.create_user.presentation.router",
        ]
    )

    session_factory = providers.Object(local_session)

    create_user_adapter = providers.Factory(
        CreateUserAdapter,
        session_factory=session_factory,
    )

    create_user_use_case = providers.Factory(
        CreateUserUseCase,
        port=create_user_adapter,
    )


container = Container()
container.wire(modules=container.wiring_config.modules)
```

`providers.Object(local_session)` wraps the already-instantiated `async_sessionmaker` from
`adapters/db/session.py`. This avoids `providers.Resource` (which requires async `init_resources`)
and does not require modifying `bootstrap/factory.py`.

The module-level `container.wire(...)` call executes on first import of this module. The router
imports `Container` from here, triggering wiring before the first request.

### Step 8 — Modify `features/users/router.py`

Remove the `write_user` import and direct `router.post("/user", ...)` registration. Add
`include_router` for the new slice router.

```python
# Lines to remove:
from .use_cases.user_create import write_user
router.post("/user", response_model=UserRead, status_code=201)(write_user)

# Lines to add:
from .create_user.presentation.router import router as create_user_router
router.include_router(create_user_router)
```

Also remove the `UserRead` import from the top of `router.py` if it is no longer used by any
other route in that file (check all remaining routes first).

`bootstrap/router.py` is **not touched** — it already imports `users_router` from
`features/users/router.py`; the aggregation chain is unchanged.

### Step 9 — Delete old use case

Delete `src/app/features/users/use_cases/user_create.py`. Verify that no other file imports
`write_user` from this module before deleting.

### Step 10 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

For the outside-in test specifically:

```
pytest tests/features/users/0001_create_user/create_user_outside_in_test.py -v
```

## 6. Tests planned

- **Use-case unit test** — `tests/features/users/0001_create_user/domain/test_use_case.py`.
  Mocks `CreateUserPort` entirely. Asserts:
  - `email_exists` returns `True` → raises `DuplicateValueDomainError("Email is already registered")`.
  - `username_exists` returns `True` (email OK) → raises `DuplicateValueDomainError("Username not available")`.
  - Both checks pass → `port.create` is called with a `CreateUserInternalCommand` whose `hashed_password ≠ command.password`.
  - Return value of `__call__` equals the value returned by `port.create`.

- **Adapter unit test** — `tests/features/users/0001_create_user/data/test_adapter.py`.
  Mocks the `async_sessionmaker` / `AsyncSession`. Asserts:
  - `email_exists` returns `True` when the SELECT finds a row, `False` otherwise.
  - `username_exists` returns `True` when the SELECT finds a row, `False` otherwise.
  - `create` returns a `UserRead` matching the fields of the ORM model on success.
  - `create` maps `IntegrityError` → `DuplicateValueDomainError`.
  - `create` wraps any unexpected exception as `UnknownDomainError` and calls
    `logger.error` with `exc_info=True`.

- **Endpoint integration test** — `tests/features/users/0001_create_user/presentation/test_router.py`.
  Uses `httpx.AsyncClient` against the full running app with test Postgres. Asserts:
  - Valid payload → `201`, body matches `CreateUserResponse` schema.
  - Duplicate email → `409`, body has `error.message` field.
  - Duplicate username → `409`, body has `error.message` field.
  - Missing required field → `422`.

- **Outside-in test** — `tests/features/users/0001_create_user/create_user_outside_in_test.py`.
  Full HTTP stack, real adapter, test Postgres, no mocks except at external boundaries. This is
  the acceptance gate for the slice.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Migrating any other user use cases (`list`, `get`, `update`, `delete`, etc.) to the hexagonal
  structure. Only `create_user` is in scope.
- Email verification or any post-registration flow.
- Rate limiting on the `POST /user` endpoint.
- Superuser creation path.
- Adding or renaming `features/users/_shared/` subfolder — `features/users/schemas.py` continues
  to serve as the shared entity file unchanged.
- Alembic migrations — the ORM model (`adapters/db/models/user.py`) is unchanged.
- Auth dependency on `POST /user` — registration is a public endpoint.

## 8. Open questions

1. **`UnknownDomainError` does not exist in `app/domain/errors.py`.**
   The adapter's outer catch is designed to raise `UnknownDomainError`, but `domain/errors.py`
   (STABLE) currently defines only `DomainError`, `NotFoundDomainError`,
   `DuplicateValueDomainError`, and `ForbiddenDomainError`. Adding `UnknownDomainError` requires
   an explicit STABLE-file change with user approval. Additionally, the existing
   `exception_handlers.py` uses a `STATUS_MAP` dict (not `exc.http_status`) — `UnknownDomainError`
   would fall through to the `500` default, which is correct behavior. **User decision needed
   before implementing the adapter.**

2. **`get_password_hash` import inside `domain/`.**
   `CreateUserUseCase` imports `get_password_hash` from `core/security.py`. Strictly, `domain/`
   files should import only stdlib and pydantic. Two alternatives exist:
   a. Accept the `core/` import (pragmatic; `core/security.py` has no framework dependency other
      than `bcrypt` and `jose`).
   b. Inject hashing as a callable dependency (`Callable[[str], str]`) into `CreateUserUseCase`
      so `domain/` stays framework-free. The container binds `get_password_hash` at wiring time.
   **User decision needed before implementing the use case.**

3. **`session_factory` naming in `adapters/db/session.py`.**
   The PRD references `async_session_factory` as an import from `adapters/db/session`, but the
   actual module exports `local_session` (an `async_sessionmaker[AsyncSession]` instance) and
   `async_get_db` (an async generator). The plan uses `providers.Object(local_session)` as the
   correct approach. No code change to `session.py` is needed. Flagged here for awareness.
