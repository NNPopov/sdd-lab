# Project Architecture — t_automation FastAPI Boilerplate

## Overview

Async FastAPI service using **Hybrid VSA + Hexagonal + Skeleton** architecture.

| Concern | Technology |
|---|---|
| Framework | FastAPI · Python 3.11+ |
| Database | PostgreSQL via SQLAlchemy 2.0 async + asyncpg |
| Migrations | Alembic |
| CRUD | FastCRUD (duck-typed, no wrappers needed) |
| Schemas | Pydantic v2 |
| Cache | Redis via `@cache` decorator (`adapters/cache/redis_cache.py`) |
| Queue | ARQ (async Redis queue) |
| Admin UI | CRUDAdmin (optional, toggled by `CRUD_ADMIN_ENABLED`) |
| Code quality | Ruff · mypy (strict, `src/app/**`) |

---

## Architecture Layers

```
┌────────────────────────────────────────────────────────┐
│  main.py  →  bootstrap/  (wiring only)                 │
├────────────────────────────────────────────────────────┤
│  features/  (FEATURE — vertical slices, AI-changeable) │
├────────────────────────────────────────────────────────┤
│  adapters/  (STABLE — concrete infra implementations)  │
│  core/      (STABLE — config, security, logger)        │
├────────────────────────────────────────────────────────┤
│  ports/     (STABLE — Protocol interfaces)             │
│  domain/    (STABLE — errors, base schemas)            │
└────────────────────────────────────────────────────────┘
```

**VSA** — every business feature is a self-contained directory under `features/` with its own schemas, repository, use cases, and router.

**Hexagonal** — business logic in `features/use_cases/` only ever raises `DomainError` subclasses. HTTP translation happens exclusively in `adapters/http/exception_handlers.py`.

**Skeleton** — files marked `# STABLE` form the infrastructure skeleton. Files marked `# FEATURE:` are the AI-changeable surface.

---

## Directory Map

```
src/
├── app/
│   ├── main.py                         # STABLE — entry point; imports bootstrap/ only
│   │
│   ├── bootstrap/                      # STABLE — app wiring (factory + root router)
│   │   ├── factory.py                  # create_application(), lifespan (DB/Redis pools)
│   │   └── router.py                   # aggregates all feature routers under /api/v1
│   │
│   ├── domain/                         # STABLE — pure Python; zero framework imports
│   │   ├── errors.py                   # DomainError base + NotFound/Duplicate/Forbidden
│   │   └── shared/
│   │       └── base_schemas.py         # UUIDSchema, TimestampSchema, PersistentDeletion
│   │
│   ├── ports/                          # STABLE — structural Protocol interfaces
│   │   ├── repository.py               # IRepository (satisfied structurally by FastCRUD)
│   │   ├── cache.py                    # ICacheClient
│   │   └── queue.py                    # IQueueClient
│   │
│   ├── adapters/                       # STABLE — concrete infra; never imports features/
│   │   ├── db/
│   │   │   ├── base.py                 # DeclarativeBase (MappedAsDataclass)
│   │   │   ├── session.py              # async_engine, async_get_db, local_session
│   │   │   ├── mixins.py               # UUIDMixin, TimestampMixin, SoftDeleteMixin
│   │   │   ├── models/                 # SQLAlchemy ORM models (infra, not domain)
│   │   │   │   ├── user.py
│   │   │   │   ├── post.py
│   │   │   │   ├── tier.py
│   │   │   │   └── rate_limit.py
│   │   │   └── token_blacklist/
│   │   │       ├── model.py
│   │   │       └── repository.py
│   │   ├── cache/
│   │   │   └── redis_cache.py          # @cache decorator with key templating + invalidation
│   │   ├── queue/
│   │   │   └── arq_queue.py            # ARQ WorkerSettings, create_pool
│   │   ├── rate_limit/
│   │   │   └── redis_rate_limiter.py   # RateLimiter class
│   │   └── http/
│   │       ├── exception_handlers.py   # DomainError → HTTP status mapping
│   │       └── middleware/
│   │           ├── logger_middleware.py
│   │           └── client_cache_middleware.py
│   │
│   ├── core/                           # STABLE — cross-cutting config; never imports features/
│   │   ├── config.py                   # Settings (pydantic-settings, env-based)
│   │   ├── security.py                 # JWT encode/decode, bcrypt, OAuth2PasswordBearer
│   │   ├── logger.py                   # structlog setup
│   │   ├── health.py                   # DB + Redis ping helpers
│   │   ├── schemas.py                  # Token, TokenBlacklist, HealthCheck schemas
│   │   └── worker/                     # ARQ worker functions + settings
│   │
│   ├── features/                       # FEATURE — one directory per vertical slice
│   │   ├── auth/                       # login, logout, token refresh
│   │   ├── users/                      # user CRUD + auth dependencies
│   │   ├── posts/                      # post CRUD with soft delete + caching
│   │   ├── tiers/                      # subscription tier management
│   │   ├── rate_limits/                # per-path rate limit config
│   │   ├── tasks/                      # background job submission
│   │   └── health/                     # /health and /ready endpoints
│   │
│   ├── shared_dependencies.py          # STABLE — cross-slice FastAPI Depends (rate limiter)
│   └── admin/                          # STABLE — CRUDAdmin wiring
│
├── migrations/                         # Alembic — imports from adapters/db/ only
├── scripts/                            # One-off setup scripts (create superuser / tier)
└── CLAUDE.md                           # this file
```

---

## Dependency Rules

These are absolute. Violations break the architecture.

```
domain/      imports: stdlib, pydantic
             NEVER:   anything from app/

ports/       imports: domain/ only
             NEVER:   adapters/, core/, features/

adapters/    imports: domain/, ports/, core/
             NEVER:   features/

core/        imports: stdlib, third-party
             NEVER:   features/, adapters/

features/    imports: adapters/, domain/, ports/, core/
             cross-slice: may import another slice's repository.py
             NEVER:   another slice's schemas.py or router.py

bootstrap/   imports: features/, adapters/, core/
             NEVER:   imported by anything except main.py

main.py      imports: bootstrap/ only
```

**Cross-slice example that is allowed:**
```python
# features/users/use_cases/user_tier_patch.py
from ...tiers.repository import crud_tiers  # OK — repository only
```

**Cross-slice example that is NOT allowed:**
```python
# features/users/schemas.py
from ..tiers.schemas import TierRead  # VIOLATION — schema cross-import
```

---

## File Header Convention

Every Python file must begin with one of:

```python
# STABLE: <module description>. Change only when infrastructure changes.
```
```python
# FEATURE: <slice-name> — <file purpose>.
```

`STABLE` files form the skeleton. Changing them requires understanding the full impact.
`FEATURE` files are the normal development surface.

---

## Adding a New Feature (Step-by-Step)

1. Create `app/features/<name>/` with:
   - `__init__.py`
   - `schemas.py`
   - `repository.py`
   - `use_cases/__init__.py`
   - `use_cases/<name>_create.py`, `<name>_list.py`, etc.
   - `router.py`

2. If a new ORM model is needed: add it to `adapters/db/models/<name>.py` and ensure it is imported in `adapters/db/models/__init__.py` (Alembic picks it up automatically).

3. Register the router in `bootstrap/router.py` — this is the **only STABLE file** to touch when adding a feature.

4. Run `alembic revision --autogenerate -m "<description>"` to generate a migration.

**Do not touch** `domain/`, `ports/`, `adapters/`, `core/`, or `main.py` when adding a feature.

---

## New Feature File Templates

### `features/<name>/schemas.py`
```python
# FEATURE: <name> — Pydantic schemas.
from pydantic import BaseModel, ConfigDict, Field
from ..domain.shared.base_schemas import UUIDSchema, TimestampSchema

class <Name>Base(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    # shared fields here

class <Name>Create(<Name>Base):
    pass

class <Name>CreateInternal(<Name>Create):
    pass  # server-side fields (e.g. created_by_user_id)

class <Name>Read(<Name>Base, UUIDSchema, TimestampSchema):
    pass

class <Name>Update(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    # only updatable fields

class <Name>Delete(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    is_deleted: bool
```

### `features/<name>/repository.py`
```python
# FEATURE: <name> — FastCRUD repository instance.
from fastcrud import FastCRUD
from ...adapters.db.models.<name> import <Name>
from .schemas import <Name>Create, <Name>CreateInternal, <Name>Read, <Name>Update, <Name>Delete

crud_<name>s = FastCRUD[<Name>, <Name>Create, <Name>CreateInternal, <Name>Update, <Name>Delete](<Name>)
```

### `features/<name>/use_cases/<name>_create.py`
```python
# FEATURE: <name> — use case: create <name>.
from typing import Annotated
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from ....adapters.db.session import async_get_db
from ....domain.errors import DuplicateValueDomainError
from ..repository import crud_<name>s
from ..schemas import <Name>Create, <Name>CreateInternal, <Name>Read

async def create_<name>(
    data: <Name>Create,
    db: Annotated[AsyncSession, Depends(async_get_db)],
) -> <Name>Read:
    existing = await crud_<name>s.exists(db=db, name=data.name)
    if existing:
        raise DuplicateValueDomainError("<Name> already exists")
    internal = <Name>CreateInternal(**data.model_dump())
    return await crud_<name>s.create(db=db, object=internal)
```

### `features/<name>/router.py`
```python
# FEATURE: <name> — API router.
from fastapi import APIRouter
from .use_cases.<name>_create import create_<name>

router = APIRouter(tags=["<name>s"])

router.post("/", response_model=<Name>Read, status_code=201)(create_<name>)
```

### `adapters/db/models/<name>.py`
```python
# STABLE: ORM model for <Name>.
from dataclasses import field
from datetime import UTC, datetime
from sqlalchemy.orm import Mapped, mapped_column
from ..base import Base
from ..mixins import UUIDMixin, TimestampMixin

class <Name>(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "<name>"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True, init=False)
    name: Mapped[str] = mapped_column(String(100))
```

---

## Key Patterns

### Cache decorator
```python
from ...adapters.cache.redis_cache import cache

@router.get("/{username}/posts")
@cache(
    key_prefix="{username}_posts:page_{page}:items_per_page:{items_per_page}",
    resource_id_name="username",
    expiration=60,
)
async def read_posts(request: Request, username: str, ...) -> dict:
    ...

# Invalidation on write:
@cache("{username}_post_cache", resource_id_name="id",
       pattern_to_invalidate_extra=["{username}_posts:*"])
async def patch_post(...):
    ...
```

### Raising domain errors (use cases only)
```python
from ....domain.errors import NotFoundDomainError, ForbiddenDomainError, DuplicateValueDomainError

raise NotFoundDomainError("User not found")      # → 404
raise ForbiddenDomainError()                      # → 403
raise DuplicateValueDomainError("Email taken")   # → 409
# NEVER: raise HTTPException(...) inside use_cases/
```

### Async DB session injection
```python
from typing import Annotated
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from ...adapters.db.session import async_get_db

async def my_endpoint(db: Annotated[AsyncSession, Depends(async_get_db)]) -> ...:
    ...
```

### Rate limiter dependency (cross-cutting)
```python
from fastapi import Depends
from .shared_dependencies import rate_limiter_dependency

router = APIRouter(dependencies=[Depends(rate_limiter_dependency)])
```

### Auth dependencies
```python
from ..users.dependencies import get_current_user, get_current_superuser

current_user: Annotated[dict, Depends(get_current_user)]
```

---

## Common Commands

```bash
# From src/
uvicorn app.main:app --reload           # dev server

alembic revision --autogenerate -m "msg"  # generate migration
alembic upgrade head                    # apply migrations

pytest ../tests/                        # run tests

ruff check app/                         # lint
ruff format app/                        # format
mypy app/                               # type check

python -m scripts.create_first_superuser   # seed admin user
python -m scripts.create_first_tier        # seed default tier
```

---

## What NOT To Do

1. **Do not create `domain/models/`** — ORM models belong in `adapters/db/models/`. `domain/` is framework-free.

2. **Do not raise `HTTPException` inside `use_cases/`** — raise a `DomainError` subclass. `adapters/http/exception_handlers.py` translates it automatically.

3. **Do not import one feature's `schemas.py` into another feature** — only `repository.py` cross-imports are allowed between slices.

4. **Do not add imports from `features/` into `adapters/` or `core/`** — that inverts the dependency graph.

5. **Do not import from `core.db.*`** — that path was removed. Use `adapters.db.session` and `adapters.db.base`.

6. **Do not put business logic in `adapters/`** — adapters are mechanical translations only.

7. **Do not touch `bootstrap/router.py` for anything other than registering a new feature router** — it is the only STABLE file intentionally touched during feature addition.

8. **Do not import from `bootstrap/` anywhere except `main.py`** — bootstrap is the composition root.

9. **Do not create `app/schemas/`** — schemas live inside their feature slice (`features/<name>/schemas.py`).

10. **Do not skip the `# STABLE` / `# FEATURE:` header** on new files — it signals changeability to both humans and AI tools.
