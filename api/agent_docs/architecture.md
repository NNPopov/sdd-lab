# Architecture

This document is the reference for the project's structural conventions. Read it
before designing a new slice, splitting a feature, or making any decision about
file placement.

For procedures (how to generate specs, how to run tests), see
`agent_docs/spec_workflow.md` and `agent_docs/testing.md`. For error handling
specifics, see `agent_docs/error_handling.md`.

## Project layout

```
src/app/
├── main.py                        # STABLE — entry point, imports bootstrap only
├── bootstrap/                     # STABLE — composition root
│   ├── factory.py                 # create_app(), lifespan, container wiring
│   ├── router.py                  # aggregates feature routers under /api/v1
│   └── container.py               # dependency_injector.Container definition
├── domain/                        # STABLE — pure Python; no framework imports
│   ├── errors.py                  # DomainError + subclasses
│   └── shared/
│       └── base_schemas.py        # UUIDSchema, TimestampSchema, etc.
├── ports/                         # STABLE — @runtime_checkable Protocol interfaces
├── adapters/                      # STABLE — concrete infrastructure
│   ├── db/
│   │   ├── base.py
│   │   ├── session.py
│   │   ├── mixins.py
│   │   └── models/                # ORM models (infrastructure, not domain)
│   ├── cache/
│   ├── queue/
│   └── http/
│       ├── exception_handlers.py  # DomainError → HTTP mapping
│       └── middleware/
├── core/                          # STABLE — config, security, logging
│   ├── config.py
│   ├── security.py
│   └── logger.py
├── features/                      # FEATURE — slices live here
│   └── <resource>/
│       ├── _shared/               # shared inside the feature only
│       │   ├── schemas.py         # e.g. User domain entity
│       │   ├── dependencies.py    # e.g. get_current_user
│       │   └── repository.py      # shared port + adapter, if any
│       └── <use_case>/
│           ├── domain/
│           │   ├── commands.py    # e.g. CreateUserCommand
│           │   ├── entities.py    # e.g. User if not in _shared/
│           │   ├── ports/
│           │   │   └── create_user_port.py
│           │   └── use_case.py
│           ├── data/
│           │   └── adapter.py     # implements the port
│           └── presentation/
│               ├── router.py      # FastAPI endpoint (current entry point)
│               └── schemas.py     # CreateUserRequest, CreateUserResponse
└── shared_dependencies.py         # STABLE — cross-feature dependencies
```

A use-case is the **unit of work**. One use-case folder contains its full
hexagonal stack. Two use-cases never share files outside `_shared/`.

## Layer rules

These are absolute. Violations break the architecture and the test pyramid.

| Layer | May import | Must never import |
|---|---|---|
| `domain/` | stdlib, pydantic | anything from `app/` other than `domain/` |
| `ports/` | `domain/` | `adapters/`, `core/`, `features/` |
| `adapters/` | `domain/`, `ports/`, `core/` | `features/` |
| `core/` | stdlib, third-party | `features/`, `adapters/` |
| `features/<X>/<Y>/` | `domain/`, `ports/`, `adapters/`, `core/`, own feature `_shared/` | another feature; another slice's `domain/`, `data/`, or `presentation/` |
| `bootstrap/` | everything except `main.py` | nothing imports from `bootstrap/` except `main.py` |
| `main.py` | `bootstrap/` only | everything else |

Cross-slice import allowed:

```python
# features/users/update_user/domain/use_case.py
from ..._shared.schemas import User  # OK — own feature's _shared
```

Cross-slice import forbidden:

```python
# features/users/update_user/domain/use_case.py
from ..create_user.domain.commands import CreateUserCommand  # ❌
from ...tiers.list_tiers.presentation.schemas import TierResponse  # ❌
```

If two slices genuinely need the same type, lift it into `_shared/` of the
common feature, or into `domain/shared/` if it crosses features.

## Import conventions

**Inside `src/app/`: relative imports only.** Inside `tests/`: absolute
imports through `app.*`. This asymmetry is deliberate and matches the
configuration of all entry points in the project.

```python
# Inside src/app/features/users/create_user/presentation/router.py
from ..domain.commands import CreateUserCommand               # ✅ relative
from ..domain.use_case import CreateUserUseCase               # ✅ relative
from ...._shared.schemas import User                          # ✅ relative across slices

# Forbidden:
from app.features.users.create_user.domain.commands import CreateUserCommand   # ❌
from src.app.features.users.create_user.domain.commands import CreateUserCommand   # ❌
```

```python
# Inside tests/features/users/0001_create_user/domain/test_use_case.py
from app.features.users.create_user.domain.commands import CreateUserCommand   # ✅ absolute
from app.features.users.create_user.domain.use_case import CreateUserUseCase   # ✅ absolute

# Forbidden:
from src.app.features...   # ❌
from ....src.app...        # ❌ no relative reaches from tests/ into src/
```

For absolute imports in tests to work, `pyproject.toml` must declare the
`src/` directory in pytest's pythonpath:

```toml
[tool.pytest.ini_options]
pythonpath = ["src"]
```

Why this asymmetry:

- **`uvicorn`, `pytest`, `alembic`, `celery`, `ipython`** all configure
  PYTHONPATH differently. Relative imports inside `src/app/` work uniformly
  across all of them. Absolute imports via `app.*` would require each entry
  point to be configured to see `src/` as a path root; misconfiguration of
  any one breaks the build.
- **Copy-paste of a slice** to another project works without renaming a
  package prefix.
- **Future Celery and Langgraph entry points** in the same monorepo can
  reuse the same code without per-entry-point PYTHONPATH gymnastics.
- **Tests live outside `src/app/`**, so they cannot use relative imports to
  reach it. Absolute imports there are the only practical option, and the
  `pythonpath = ["src"]` setting makes them work.

The relative-imports-in-source rule applies to every layer: `domain/`,
`ports/`, `data/`, `presentation/`, and feature `_shared/`. There are no
exceptions inside `src/app/`.

## Bounded contexts

The same business noun in different contexts is **different types**. The most
common example:

- `features/users/_shared/schemas.py::User` — the catalog object. Has all fields
  visible in user management views. May be incomplete (no password hash).
- `core/auth/schemas.py::CurrentUser` — the session identity. Has only what
  matters for authorization: `user_id`, `username`, `is_superuser`. Stripped of
  PII not needed at the auth boundary.

Use the right type at the right layer. Do not pass `CurrentUser` where a `User`
is expected, even if the fields overlap.

## Terminology: port and adapter

- **Port** — an interface declared in `domain/ports/`. Uses
  `@runtime_checkable` + `typing.Protocol`. Names by capability:
  `CreateUserPort`, `ListUsersPort`. **One port per use-case.** Wide
  multi-method "repositories" are not used.
- **Adapter** — concrete implementation of a port, in `data/`. **The adapter
  class explicitly inherits from its Port.** Bound to the port in the DI
  container. The adapter is the only place where SQLAlchemy, Redis, HTTP
  libraries, or other I/O code is allowed.

### Port pattern (canonical)

```python
# FEATURE: create_user — port.
from typing import Protocol, runtime_checkable

from ..commands import CreateUserInternalCommand
from ..entities import CreatedUser


@runtime_checkable
class CreateUserPort(Protocol):
    async def create(self, command: CreateUserInternalCommand) -> CreatedUser: ...
```

Three things matter and all three are mandatory:

1. **`@runtime_checkable` decorator.** Enables `isinstance(adapter, Port)`
   checks at runtime — useful for diagnostics, DI verification, and
   occasional defensive code. Zero cost when unused.
2. **`Protocol` base class.** Structural typing; mypy checks adapter
   compatibility statically.
3. **One method per port (typical).** Multi-method ports are a smell.

### Adapter pattern (canonical)

```python
# FEATURE: create_user — adapter.
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from ..domain.commands import CreateUserInternalCommand
from ..domain.entities import CreatedUser
from ..domain.ports.create_user_port import CreateUserPort


class CreateUserAdapter(CreateUserPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def create(self, command: CreateUserInternalCommand) -> CreatedUser:
        ...
```

**The `class CreateUserAdapter(CreateUserPort):` line is mandatory.**

Why explicit inheritance, even though Protocol does not require it:

- **Discoverability.** Grepping `class.*Adapter.*Port` finds every adapter
  for a given port instantly. Without inheritance, the link is invisible to
  text search, and reviewers waste time hunting for implementations.
- **Reader intent.** The class header documents that this adapter
  implements this port. A bare `class CreateUserAdapter:` leaves the reader
  guessing what contract it satisfies.
- **AI agents.** When generating, editing, or auditing code, an AI agent
  uses the inheritance line as the primary signal of port→adapter binding.
  A missing inheritance leaves the agent unable to determine which port the
  adapter belongs to.

The cost is one keyword. The protection is permanent.

### Why Protocol + `@runtime_checkable` instead of ABC

Both work. The project chose Protocol for two reasons:

- It is the modern Python idiom (PEP 544).
- Structural typing means a port can be satisfied by external code that does
  not inherit from it, useful for occasional test doubles and adapters
  defined outside the project.

The trade-off is that Protocol does **not** check completeness at
instantiation time. If an adapter is missing a method, the failure happens
when that method is called, not when the object is created. **mypy strict is
the safety net** — it catches missing methods at type-check time. The
project's `mypy src/app` step in `Verifying changes` (see CLAUDE.md) is
therefore non-negotiable; without it, the Protocol pattern loses its safety.

The word **Repository** is reserved for `_shared/repository.py` when a feature
genuinely needs one cross-use-case repository (e.g. shared read paths). It is
not used for the standard adapter of an individual use-case.

## Use-case shape

A use-case is a class with dependencies injected through `__init__` and a single
`__call__()` method.

```python
# FEATURE: create_user — use case.
from app.features.users.create_user.domain.commands import CreateUserCommand
from app.features.users.create_user.domain.ports.create_user_port import CreateUserPort
from app.features.users._shared.schemas import User
from app.domain.errors import DuplicateValueDomainError


class CreateUserUseCase:
    def __init__(self, port: CreateUserPort) -> None:
        self._port = port

    async def __call__(self, command: CreateUserCommand) -> User:
        if await self._port.username_exists(command.username):
            raise DuplicateValueDomainError("Username already taken")
        return await self._port.create(command)
```

Rules:

- One use-case = one class. Two use-cases means two classes in two folders.
- `__call__()` is the only public method.
- Input is a domain `*Command` (or `*Query`), not an HTTP `*Request`. The router
  converts at the boundary.
- Output is a domain entity, not an HTTP `*Response`. The router converts back.
- The use-case raises `DomainError` subclasses on failure. Never `HTTPException`,
  never bare `Exception`.
- The use-case orchestrates ports; it does not contain I/O code itself.

## Command vs Request, Entity vs Response

Two concepts, two pairs of types:

| Concept | Domain type | Presentation type | Lives in |
|---|---|---|---|
| Input to use-case | `CreateUserCommand` | `CreateUserRequest` | `domain/commands.py` vs `presentation/schemas.py` |
| Output of use-case | `User` | `CreateUserResponse` | `_shared/schemas.py` (entity) vs `presentation/schemas.py` |

The router does the conversion:

```python
# FEATURE: create_user — router.
@router.post("/users", response_model=CreateUserResponse, status_code=201)
async def create_user_endpoint(
    request: CreateUserRequest,
    use_case: Annotated[CreateUserUseCase, Depends(Provide[Container.create_user_use_case])],
) -> CreateUserResponse:
    command = CreateUserCommand(**request.model_dump())
    user = await use_case(command)
    return CreateUserResponse.model_validate(user)
```

Why this discipline:

- A use-case must be callable from a Celery task or a Langgraph node without
  importing the HTTP layer. If the use-case accepted a `CreateUserRequest`, any
  non-HTTP entry point would have to construct an HTTP-shaped object.
- HTTP-specific fields (CSRF tokens, idempotency keys, client metadata) live on
  `*Request` and never leak into the domain.

The conversion is usually one line; for trivial slices, `CreateUserCommand` and
`CreateUserRequest` have the same shape. The duplication is the price for keeping
the boundary explicit.

## Dependency injection

The project uses **`dependency_injector`** as the source of truth for object
construction. FastAPI `Depends` is the **delivery mechanism** at the endpoint
boundary.

### Container

A single container in `bootstrap/container.py` declares all providers:

```python
# STABLE: dependency_injector container.
from dependency_injector import containers, providers

from app.adapters.db.session import async_session_factory
from app.features.users.create_user.data.adapter import CreateUserAdapter
from app.features.users.create_user.domain.use_case import CreateUserUseCase


class Container(containers.DeclarativeContainer):
    wiring_config = containers.WiringConfiguration(
        modules=[
            "app.features.users.create_user.presentation.router",
            # ... one entry per router module
        ]
    )

    # Infrastructure
    session_factory = providers.Resource(async_session_factory)

    # Adapters
    create_user_adapter = providers.Factory(
        CreateUserAdapter,
        session_factory=session_factory,
    )

    # Use cases
    create_user_use_case = providers.Factory(
        CreateUserUseCase,
        port=create_user_adapter,
    )
```

### Endpoint wiring

Endpoints receive use-cases through `Annotated[X, Depends(Provide[Container.x])]`:

```python
from typing import Annotated
from fastapi import Depends
from dependency_injector.wiring import Provide

from app.bootstrap.container import Container

@router.post("/users")
async def create_user_endpoint(
    request: CreateUserRequest,
    use_case: Annotated[
        CreateUserUseCase, Depends(Provide[Container.create_user_use_case])
    ],
) -> CreateUserResponse: ...
```

### Why this layering

- `dependency_injector` is reusable: when the same use-case is later invoked from
  a Celery task or a Langgraph node, the container resolves dependencies the same
  way. FastAPI `Depends` is HTTP-specific and would not work there.
- Test overrides work uniformly. In tests, `container.create_user_adapter.override(mock)`
  swaps the adapter for the entire app, including endpoints.

## `_shared/` rules

Inside a feature folder, `_shared/` holds what multiple slices of that feature
genuinely use:

- `schemas.py` — the feature's domain entity (e.g. `User`).
- `dependencies.py` — feature-wide FastAPI dependencies (e.g. `get_current_user`).
- `repository.py` — only when multiple use-cases need the same multi-method read
  surface. Most features will not have this.

What does **not** belong in `_shared/`:

- Ports. Each use-case declares its own narrow port. Sharing ports across
  use-cases couples them; keep them separate even if the signature looks
  identical at first.
- Use-case classes.
- Adapters.
- HTTP request/response schemas (those are per-slice).

Cross-feature sharing goes one level higher into `domain/shared/` (for pure
domain types) or `core/` (for cross-cutting infrastructure).

## Slice anatomy worked example: `create_user`

```
features/users/create_user/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py        # class CreateUserCommand(BaseModel): username, email, password
│   ├── ports/
│   │   ├── __init__.py
│   │   └── create_user_port.py  # class CreateUserPort(Protocol): create(), username_exists()
│   └── use_case.py        # class CreateUserUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py         # class CreateUserAdapter implements CreateUserPort
└── presentation/
    ├── __init__.py
    ├── router.py          # @router.post("/users")
    └── schemas.py         # CreateUserRequest, CreateUserResponse
```

Plus the feature-wide pieces in `features/users/_shared/`:

```
features/users/_shared/
├── __init__.py
└── schemas.py             # class User(BaseModel): id, username, email, is_superuser
```

When `create_user` is followed by `list_users`, `get_user`, `update_user`,
`delete_user`, each becomes a sibling folder with the same internal shape. None
of them share files except through `_shared/`.

## Slicing decisions

The unit of decomposition is the **use-case**, not the resource. A REST
`POST /users` and `GET /users/{id}` are **two slices**, not one.

Indicators that justify two separate slices:

- Different ports (one writes, one reads).
- Different authorization (anyone can register; only admin can delete).
- Different cache policies.
- Different failure modes worth modeling.

Indicators that two operations might collapse into one slice:

- They share the same port verbatim with no authorization difference (rare).
- One is a strict subset of the other (e.g. dry-run mode) — but even then, two
  slices is usually cleaner.

When in doubt, two slices. Merging slices later is cheaper than splitting one
overgrown slice.

For deeper splitting heuristics, see skill `slice-decomposition`.
