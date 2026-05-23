# 0033 · create_tier — Implementation plan

## 1. Header

- **Feature:** tiers
- **Slice:** 0033_create_tier
- **PRD:** ./prd.md
- **Reference slice:** `specs/features/posts/0011_create_post/plan.md` — same create-operation shape
- **HTTP path:** `POST /api/v1/tier`
- **STABLE files touched:**
  - `bootstrap/container.py` — two new providers appended (`create_tier_adapter`, `create_tier_use_case`) and one wiring module entry added. Permitted for DI wiring of new features.
  - `.importlinter` — one `ignore_imports` line added for the new router module. Permitted per `agent_docs/entry_points/fastapi.md`.

## 2. Context summary

An authenticated superuser sends a tier name to `POST /api/v1/tier`. This slice extracts the
existing fat `write_tier` handler from `features/tiers/router.py` into a fully conformant
hexagonal slice at `features/tiers/create_tier/`. The use-case is intentionally trivial — it
delegates entirely to the port with no conditional logic of its own. Duplicate-name enforcement
is handled by the adapter, which issues a bare `INSERT` and catches `IntegrityError`, eliminating
the TOCTOU race that exists in the current `SELECT EXISTS` approach. The response is HTTP 201
with the created tier's `id`, `name`, and `created_at`. This slice also creates
`tiers/_shared/entities.py` with `TierItem` and `TierPage`, shared domain entities reused by all
five tiers slices (0033–0037).

## 3. API contract

**Request body** (`CreateTierRequest`):

| Field | Type | Validation |
|---|---|---|
| `name` | `str` | `min_length=1` |

**Path/query params:** none.

**Auth:** `get_current_superuser` from `shared_dependencies.py`, applied as a route-level
`dependencies=[...]`. Returns `dict[str, Any]`. Raises FastCRUD's `ForbiddenException` (→ 403)
and `UnauthorizedException` (→ 401) — this is a pre-existing pattern; both are out of scope to
convert to `DomainError` in this slice.

**Response body** (`CreateTierResponse`):

| Field | Type |
|---|---|
| `id` | `int` |
| `name` | `str` |
| `created_at` | `datetime` |

**Status codes:**

- `201 Created` — tier created successfully.
- `409 Conflict` — `DuplicateValueDomainError("Tier name already exists")`: the `name` unique
  constraint was violated.
- `403 Forbidden` — caller is authenticated but is not a superuser (raised by
  `get_current_superuser`).
- `401 Unauthorized` — no valid bearer token (raised by `get_current_user` via
  `get_current_superuser`).
- `422 Unprocessable Entity` — Pydantic field-level validation failure (e.g., missing `name`).

## 4. File structure

New files created:

```
src/app/features/tiers/
├── _shared/
│   ├── __init__.py
│   └── entities.py          # TierItem, TierPage

src/app/features/tiers/create_tier/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py          # CreateTierCommand
│   ├── ports/
│   │   ├── __init__.py
│   │   └── create_tier_port.py  # CreateTierPort (Protocol)
│   └── use_case.py          # CreateTierUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py           # CreateTierAdapter(CreateTierPort)
└── presentation/
    ├── __init__.py
    ├── router.py             # POST /tier
    └── schemas.py            # CreateTierRequest, CreateTierResponse
```

No new ORM model. `adapters/db/models/tier.py` (`Tier`) is used as-is: columns `id`, `name`,
`created_at`. No Alembic migration required.

Existing files modified:

```
src/app/features/tiers/router.py   # remove write_tier; include create_tier sub-router
src/app/bootstrap/container.py     # two new providers + one wiring_config entry
.importlinter                      # one ignore_imports line for the new router
```

## 5. Implementation steps

### Step 1 — Shared entities: `tiers/_shared/`

**File:** `src/app/features/tiers/_shared/__init__.py` — empty.

**File:** `src/app/features/tiers/_shared/entities.py`

```python
# FEATURE: tiers._shared — domain entities.
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class TierItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    created_at: datetime


class TierPage(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    items: list[TierItem]
    total_count: int
    page: int
    items_per_page: int
```

`TierItem` and `TierPage` are pure Pydantic models — no ORM, no framework imports. `TierPage` is
defined here for future slices (0034 `list_tiers`); this slice does not use it.

Verify: the file imports cleanly with only `datetime` and `pydantic`.

### Step 2 — Domain: Command

**File:** `src/app/features/tiers/create_tier/domain/commands.py`

```python
# FEATURE: create_tier — domain command.
from pydantic import BaseModel


class CreateTierCommand(BaseModel):
    name: str
```

Verify: no imports from `adapters/`, `core/`, or any framework.

### Step 3 — Domain: Port

**File:** `src/app/features/tiers/create_tier/domain/ports/create_tier_port.py`

```python
# FEATURE: create_tier — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import TierItem
from ..commands import CreateTierCommand


@runtime_checkable
class CreateTierPort(Protocol):
    async def create(self, command: CreateTierCommand) -> TierItem: ...
```

`@runtime_checkable` is mandatory per CLAUDE.md. One method — no wide repository surface.

Import path from `ports/` to `_shared/entities.py`:
- `ports/` → `domain/` → `create_tier/` → `tiers/` = 4 dots → `_shared.entities`

### Step 4 — Domain: Use case

**File:** `src/app/features/tiers/create_tier/domain/use_case.py`

```python
# FEATURE: create_tier — use case.
from ....._shared.entities import TierItem
from .commands import CreateTierCommand
from .ports.create_tier_port import CreateTierPort


class CreateTierUseCase:
    def __init__(self, port: CreateTierPort) -> None:
        self._port = port

    async def __call__(self, command: CreateTierCommand) -> TierItem:
        return await self._port.create(command)
```

The use-case is deliberately trivial: no conditional logic, no error raises. All domain enforcement
(duplicate name) is the adapter's responsibility via the DB unique constraint. The use-case
boundary exists for architectural consistency and testability, per the PRD's architectural
decisions.

Import path from `domain/` to `_shared/entities.py`:
- `domain/` → `create_tier/` → `tiers/` → `features/` = but `_shared` is at `tiers/_shared/`, so 3 dots → `_shared.entities`

Wait — correct path from `domain/use_case.py` (in `app.features.tiers.create_tier.domain`):
- `...` = `app.features.tiers` → `...._shared.entities` (4 dots) = `app.features.tiers._shared.entities`

No `DomainError` imports needed here. Per `agent_docs/error_handling.md`, the use-case raises
only when it has business logic to enforce; this use-case has none.

### Step 5 — Data: Adapter

**File:** `src/app/features/tiers/create_tier/data/adapter.py`

```python
# FEATURE: create_tier — data adapter.
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.tier import Tier
from .....domain.errors import DuplicateValueDomainError
from ...._shared.entities import TierItem
from ..domain.commands import CreateTierCommand
from ..domain.ports.create_tier_port import CreateTierPort


class CreateTierAdapter(CreateTierPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def create(self, command: CreateTierCommand) -> TierItem:
        async with self._session_factory() as session:
            tier = Tier(name=command.name)
            session.add(tier)
            try:
                await session.commit()
            except IntegrityError as exc:
                raise DuplicateValueDomainError("Tier name already exists") from exc
            await session.refresh(tier)
            return TierItem.model_validate(tier)
```

Explicit `class CreateTierAdapter(CreateTierPort):` inheritance is mandatory per
`agent_docs/architecture.md`. Narrow `try/except` covers only `session.commit()`. Catches
`IntegrityError` only — per `agent_docs/error_handling.md`, any other infrastructure
exception propagates unchanged to the global handler. `raise ... from exc` preserves the
original stack trace.

Import paths from `data/adapter.py` (in `app.features.tiers.create_tier.data`):
- 5 dots → `app` → `app.adapters.db.models.tier`, `app.domain.errors`
- 4 dots → `app.features.tiers` → `app.features.tiers._shared.entities`
- 2 dots → `app.features.tiers.create_tier` → `domain.*`

### Step 6 — Presentation: Schemas

**File:** `src/app/features/tiers/create_tier/presentation/schemas.py`

```python
# FEATURE: create_tier — request/response schemas.
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CreateTierRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    name: str = Field(min_length=1)


class CreateTierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    created_at: datetime
```

`CreateTierResponse` mirrors `TierItem`; `model_config = ConfigDict(from_attributes=True)`
enables `.model_validate(tier_item)` in the router.

### Step 7 — Presentation: Router

**File:** `src/app/features/tiers/create_tier/presentation/router.py`

```python
# FEATURE: create_tier — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, status

from .....bootstrap.container import Container
from .....shared_dependencies import get_current_superuser
from ..domain.commands import CreateTierCommand
from ..domain.use_case import CreateTierUseCase
from .schemas import CreateTierRequest, CreateTierResponse

router = APIRouter(tags=["tiers"])


@router.post(
    "/tier",
    response_model=CreateTierResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(get_current_superuser)],
)
@inject
async def create_tier_endpoint(
    request: CreateTierRequest,
    use_case: Annotated[
        CreateTierUseCase,
        Depends(Provide[Container.create_tier_use_case]),
    ],
) -> CreateTierResponse:
    command = CreateTierCommand(name=request.name)
    tier_item = await use_case(command)
    return CreateTierResponse.model_validate(tier_item)
```

`get_current_superuser` is applied as a route-level `dependencies=[...]` rather than as a
parameter, consistent with `write_tier`. It enforces auth and superuser role before the endpoint
body runs. No `try/except` — domain errors propagate to `adapters/http/exception_handlers.py`
per `agent_docs/error_handling.md`.

The endpoint URL is `/tier` (singular), preserving backward compatibility per PRD.

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` — three additions.

**Add to the import block:**

```python
from ..features.tiers.create_tier.data.adapter import CreateTierAdapter
from ..features.tiers.create_tier.domain.use_case import CreateTierUseCase
```

**Add to `wiring_config.modules` list:**

```python
f"{_app_pkg}.features.tiers.create_tier.presentation.router",
```

**Add to the `Container` class body (after existing providers):**

```python
create_tier_adapter = providers.Factory(
    CreateTierAdapter,
    session_factory=session_factory,
)

create_tier_use_case = providers.Factory(
    CreateTierUseCase,
    port=create_tier_adapter,
)
```

`bootstrap/container.py` is STABLE; this addition is the permitted form (new providers for a new
feature slice). Per `agent_docs/entry_points/fastapi.md`, adding the router module to
`wiring_config.modules` is mandatory — without it, `Provide[Container.create_tier_use_case]`
silently resolves to the provider sentinel instead of the use-case instance.

### Step 9 — Router integration: `tiers/router.py`

**File:** `src/app/features/tiers/router.py`

1. **Add** import of the new sub-router:
   ```python
   from .create_tier.presentation.router import router as create_tier_router
   ```
2. **Add** `router.include_router(create_tier_router)` before the remaining handler functions.
3. **Delete** the entire `write_tier` function (lines 17–32), including its `@router.post`
   decorator.
4. **Remove** unused imports from `write_tier`:
   - `DuplicateValueDomainError` (if no other handler uses it) — check remaining handlers.
   - `TierCreate`, `TierCreateInternal` from `.schemas` import — only if unused by remaining handlers.
   - Do not remove `TierRead`, `TierUpdate` — still used by `read_tier`, `patch_tier`, `erase_tier`.
   - Do not remove `crud_tiers` — still used by remaining handlers.
   - Do not remove `get_current_superuser` — still used by `patch_tier` and `erase_tier`.

`bootstrap/router.py` is **not touched** — it already registers `tiers_router` under `/api/v1`.

### Step 10 — Import linter

**File:** `.importlinter`

Add one line to the `ignore_imports` section of the `VSA Feature Domains are Independent`
contract:

```
app.features.tiers.create_tier.presentation.router -> app.bootstrap.container
```

Per `agent_docs/entry_points/fastapi.md`: the presentation router imports `bootstrap.container`
for `Provide[Container.xxx]`; the import-linter correctly flags it as a cross-domain dependency.
Adding this exemption is mandatory to keep the architecture gate test green.

### Step 11 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test for this slice:

```
pytest tests/features/tiers/0033_create_tier/create_tier_outside_in_test.py -v
```

The smoke test at `tests/smoke/test_app_starts.py` must also pass. A slice is not done until
all of the above pass.

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/tiers/0033_create_tier/domain/test_use_case.py`.
  Mocks `CreateTierPort` with `pytest-mock`. Asserts:
  - `use_case(CreateTierCommand(name="gold"))` calls `port.create` with the same command.
  - Return value of `__call__` equals the `TierItem` returned by the mocked port.
  - No error-path test at this level — the use-case has no conditional branches.

- **Adapter unit test** —
  `tests/features/tiers/0033_create_tier/data/test_adapter.py`.
  Uses a real async session against the test Postgres database (no session mocks). Asserts:
  - Happy path: `create()` with a unique name returns a `TierItem` with correct `name`, non-null
    `id`, and non-null `created_at`.
  - Duplicate path: insert a tier, then call `create()` again with the same name; assert
    `DuplicateValueDomainError` is raised.
  - Other `IntegrityError` variants (e.g., value too long for column) propagate **unchanged** —
    the adapter does not catch them with a broad `except Exception`.

- **Endpoint integration test** —
  `tests/features/tiers/0033_create_tier/presentation/test_router.py`.
  Uses `httpx.AsyncClient` against the running app with test Postgres. Asserts:
  - Valid payload + superuser token → HTTP 201, response body matches `CreateTierResponse` schema.
  - Duplicate name → HTTP 409.
  - Non-superuser authenticated token → HTTP 403.
  - Unauthenticated request → HTTP 401.
  - Missing `name` field → HTTP 422.

- **Outside-in test** —
  `tests/features/tiers/0033_create_tier/create_tier_outside_in_test.py`.
  Acceptance gate. Full HTTP stack, real adapter, test Postgres. Authenticate as a superuser,
  `POST /api/v1/tier` with `{"name": "gold"}`, assert HTTP 201 and response body contains `id`,
  `name`, `created_at`. Must be RED before implementation, GREEN after.

**Opt-outs:** none. All four levels are required.

## 7. Out of scope for this slice

- Migrating `read_tiers` (`GET /tiers`), `read_tier` (`GET /tier/{name}`),
  `patch_tier` (`PATCH /tier/{name}`), or `erase_tier` (`DELETE /tier/{name}`) — those are
  slices 0034–0037.
- URL normalisation from `/tier` (singular) to `/tiers` (plural).
- Removing `tiers/schemas.py` or `tiers/repository.py` — still referenced by `rate_limits/` and
  `users/` features.
- Converting `get_current_superuser` 403/401 to `DomainError` subclasses — pre-existing pattern,
  out of scope.
- Cache invalidation — tier creation has no associated cached read.
- Changes to the ORM model or Alembic migrations.

## 8. Open questions

None. The PRD prescribes all architectural decisions — the trivial use-case, the direct-INSERT
adapter pattern, the backward-compatible URL, and the incremental aggregator migration of
`tiers/router.py`.
