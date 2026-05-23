# 0035 · get_tier — Implementation plan

## 1. Header

- **Feature:** tiers
- **Slice:** 0035_get_tier
- **PRD:** ./prd.md
- **Reference slice (if any):** `specs/features/users/0004_get_user_by_username/plan.md` — same
  operation shape (GET by path param, single entity returned, port returns `None`, use-case raises
  `NotFoundDomainError`). Also mirrors the DI wiring pattern from `../0033_create_tier/plan.md`
  and the aggregator-router pattern from `../0034_list_tiers/plan.md`.
- **HTTP path:** `GET /api/v1/tier/{name}`
- **STABLE files touched:**
  - `bootstrap/container.py` — two new providers (`get_tier_adapter`, `get_tier_use_case`) and one
    `wiring_config` module entry. Permitted for DI wiring of new slices.

## 2. Context summary

An API consumer sends `GET /api/v1/tier/{name}` with the tier name as a path parameter. The
presentation router converts the path parameter into a `GetTierQuery` and delegates to
`GetTierUseCase`. The use-case calls its port; if the adapter returns `None`, the use-case raises
`NotFoundDomainError("Tier not found")`, which the global exception handler converts to HTTP 404.
If a matching row is found the use-case returns a `TierItem` (from `tiers/_shared/entities.py`);
the router converts it to `GetTierResponse` and returns HTTP 200. The endpoint requires no
authentication. The old `read_tier` handler in `features/tiers/router.py` is deleted once the new
slice is wired in. `TierItem` is already defined by slice 0033; this slice does not redefine it.

## 3. API contract

**Request body:** none (GET endpoint).

**Path parameters:**

| Param | Type | Validation |
|---|---|---|
| `name` | `str` | required; non-empty path segment provided by FastAPI |

**Response body** (`GetTierResponse`):

| Field | Type |
|---|---|
| `id` | `int` |
| `name` | `str` |
| `created_at` | `datetime` |

**Status codes:**

- `200 OK` — tier found; response body matches `GetTierResponse`.
- `404 Not Found` — no tier with that name; `NotFoundDomainError("Tier not found")` translated by
  the global `DomainError` handler to `{"message": "Tier not found"}`.
- `500 Internal Server Error` — unexpected infrastructure failure; logged and returned by the
  global `_catch_all` handler.

## 4. File structure

New files:

```
src/app/features/tiers/get_tier/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                    # GetTierQuery
│   ├── ports/
│   │   ├── __init__.py
│   │   └── get_tier_port.py           # GetTierPort (Protocol)
│   └── use_case.py                    # GetTierUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                     # GetTierAdapter(GetTierPort)
└── presentation/
    ├── __init__.py
    ├── router.py                      # GET /tier/{name}
    └── schemas.py                     # GetTierResponse
```

No new ORM model. No Alembic migration. `adapters/db/models/tier.py` (`Tier`) is used as-is.
`tiers/_shared/entities.py` (`TierItem`) is created by slice 0033 and imported here; it must not
be redefined locally.

Files modified:

```
src/app/features/tiers/router.py   # remove read_tier; include get_tier sub-router
src/app/bootstrap/container.py     # two new providers + one wiring_config entry
```

`bootstrap/router.py` is **not touched** — it already registers `tiers_router` from
`features/tiers/router.py`.

## 5. Implementation steps

### Step 1 — Domain: Query

**File:** `src/app/features/tiers/get_tier/domain/commands.py`

```python
# FEATURE: get_tier — domain query.
from pydantic import BaseModel


class GetTierQuery(BaseModel):
    name: str
```

No validation constraints — the presentation layer supplies a path parameter string; the domain
query assumes it is non-empty. No framework imports (`domain/` imports only stdlib and pydantic per
CLAUDE.md rule 2).

### Step 2 — Domain: Port

**File:** `src/app/features/tiers/get_tier/domain/ports/get_tier_port.py`

```python
# FEATURE: get_tier — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import TierItem
from ..commands import GetTierQuery


@runtime_checkable
class GetTierPort(Protocol):
    async def get(self, query: GetTierQuery) -> TierItem | None: ...
```

`@runtime_checkable` is mandatory per CLAUDE.md. One method per port. Returning `TierItem | None`
keeps the port neutral — the use-case owns the not-found semantics (per PRD § Port returns None,
use case raises). Import paths: `....` (4 dots) reaches `app.features.tiers` from
`app.features.tiers.get_tier.domain.ports`.

### Step 3 — Domain: Use case

**File:** `src/app/features/tiers/get_tier/domain/use_case.py`

```python
# FEATURE: get_tier — use case.
from .....domain.errors import NotFoundDomainError
from ..._shared.entities import TierItem
from .commands import GetTierQuery
from .ports.get_tier_port import GetTierPort


class GetTierUseCase:
    def __init__(self, port: GetTierPort) -> None:
        self._port = port

    async def __call__(self, query: GetTierQuery) -> TierItem:
        result = await self._port.get(query)
        if result is None:
            raise NotFoundDomainError("Tier not found")
        return result
```

No `try/except`. Raises `NotFoundDomainError` when the port returns `None`; the global exception
handler converts this to HTTP 404 (per `agent_docs/error_handling.md` § Use-case: raises, does not
catch). Import paths: `....` (5 dots) reaches `app` from `app.features.tiers.get_tier.domain`;
`...` (3 dots) reaches `app.features.tiers` for `_shared.entities`.

### Step 4 — Data: Adapter

**File:** `src/app/features/tiers/get_tier/data/adapter.py`

```python
# FEATURE: get_tier — data adapter.
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.tier import Tier
from ..._shared.entities import TierItem
from ..domain.commands import GetTierQuery
from ..domain.ports.get_tier_port import GetTierPort


class GetTierAdapter(GetTierPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get(self, query: GetTierQuery) -> TierItem | None:
        async with self._session_factory() as session:
            result = await session.execute(
                select(Tier).where(Tier.name == query.name)
            )
            row = result.scalar_one_or_none()
            if row is None:
                return None
            return TierItem.model_validate(row)
```

Explicit `class GetTierAdapter(GetTierPort):` inheritance is mandatory per `agent_docs/architecture.md`
§ Terminology: port and adapter. No `try/except` — this is a read-only query with no
business-meaningful exception to translate (per `agent_docs/error_handling.md` § Right shape:
read-only query, no catch). Infrastructure failures propagate unchanged to the global handler.
Import paths: 5 dots = `app` from `app.features.tiers.get_tier.data`; 3 dots = `app.features.tiers`
for `_shared.entities`.

### Step 5 — Presentation: Schemas

**File:** `src/app/features/tiers/get_tier/presentation/schemas.py`

```python
# FEATURE: get_tier — request/response schemas.
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class GetTierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    created_at: datetime
```

No request schema — the only input is a path parameter, handled directly in the router.
`GetTierResponse` mirrors `TierItem`; `model_config = ConfigDict(from_attributes=True)` enables
`.model_validate(tier_item)` in the router.

### Step 6 — Presentation: Router

**File:** `src/app/features/tiers/get_tier/presentation/router.py`

```python
# FEATURE: get_tier — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, status

from .....bootstrap.container import Container
from ..domain.commands import GetTierQuery
from ..domain.use_case import GetTierUseCase
from .schemas import GetTierResponse

router = APIRouter(tags=["tiers"])


@router.get(
    "/tier/{name}",
    response_model=GetTierResponse,
    status_code=status.HTTP_200_OK,
)
@inject
async def get_tier_endpoint(
    name: str,
    use_case: Annotated[
        GetTierUseCase,
        Depends(Provide[Container.get_tier_use_case]),
    ],
) -> GetTierResponse:
    query = GetTierQuery(name=name)
    tier_item = await use_case(query)
    return GetTierResponse.model_validate(tier_item)
```

No auth dependency (public endpoint per PRD). No `try/except` — `NotFoundDomainError` propagates to
the global exception handler. URL is `/tier/{name}` (singular) preserving backward compatibility
per PRD § Endpoint URL unchanged. All imports are relative per `agent_docs/architecture.md`
§ Import conventions.

### Step 7 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — permitted modification)

Add two imports at the top of the file alongside existing tier imports:

```python
from ..features.tiers.get_tier.data.adapter import GetTierAdapter
from ..features.tiers.get_tier.domain.use_case import GetTierUseCase
```

Add two providers inside `Container` (after `list_tiers_use_case`):

```python
get_tier_adapter = providers.Factory(
    GetTierAdapter,
    session_factory=session_factory,
)

get_tier_use_case = providers.Factory(
    GetTierUseCase,
    port=get_tier_adapter,
)
```

Add the router module to `wiring_config.modules`:

```python
f"{_app_pkg}.features.tiers.get_tier.presentation.router",
```

Per `agent_docs/entry_points/fastapi.md`: omitting the wiring entry causes `Provide[Container.get_tier_use_case]` to silently resolve to the provider sentinel rather than the use-case instance, producing `AttributeError` at request time with no startup warning.

### Step 8 — Router integration: `tiers/router.py`

**File:** `src/app/features/tiers/router.py` (FEATURE file)

**Prerequisite:** Slices 0033 and 0034 must already have converted this file to an aggregator
(removing `write_tier` and `read_tiers`, adding `create_tier_router` and `list_tiers_router`).
Confirm their completion before modifying.

1. **Add** the sub-router import alongside existing sub-router imports:
   ```python
   from .get_tier.presentation.router import router as get_tier_router
   ```
2. **Add** `router.include_router(get_tier_router)` after the existing `include_router` calls.
3. **Delete** the entire `read_tier` handler function and its `@router.get("/tier/{name}", ...)`
   decorator.
4. **Remove** unused imports left by `read_tier` removal — verify each against the remaining
   handlers (`patch_tier`, `erase_tier`) before removing. Do not remove `crud_tiers`,
   `TierRead`, `TierUpdate`, or `get_current_superuser` — still used by remaining handlers.

`bootstrap/router.py` is **not touched** — it already registers `tiers_router` under `/api/v1`.

### Step 9 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/tiers/0035_get_tier/get_tier_outside_in_test.py -v
```

The smoke test at `tests/smoke/test_app_starts.py` must also pass. The slice is not done until all
of the above pass.

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/tiers/0035_get_tier/domain/test_use_case.py`.
  Construct `GetTierUseCase` with a mock `GetTierPort` (pytest-mock). Assert:
  - When `port.get()` returns a `TierItem`, the use-case returns it unchanged (happy path).
  - When `port.get()` returns `None`, the use-case raises `NotFoundDomainError`.
  Two branches, no other paths.
  Prior art: `tests/features/users/0004_get_user_by_username/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/tiers/0035_get_tier/data/test_adapter.py`.
  Run against test Postgres (real database, no session mocks). Assert:
  - Happy path: seed a tier row, call `GetTierAdapter.get(GetTierQuery(name="gold"))`, assert
    returned `TierItem` has matching `id`, `name`, and `created_at`.
  - Not-found path: call `get()` with a name absent from the database; assert `None` is returned.
  - No catch path to assert — the adapter has no `try/except`.
  Prior art: `tests/features/users/0004_get_user_by_username/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/tiers/0035_get_tier/presentation/test_router.py`.
  Use `httpx.AsyncClient` against the running app with test Postgres. Assert:
  - `GET /api/v1/tier/{name}` for a seeded tier → HTTP 200, response body matches all three fields
    of `GetTierResponse` (`id`, `name`, `created_at`).
  - `GET /api/v1/tier/{name}` for an unknown name → HTTP 404, body is
    `{"message": "Tier not found"}`.
  - No authentication required — unauthenticated request returns 200 for an existing tier.
  Prior art: `tests/features/users/0004_get_user_by_username/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/tiers/0035_get_tier/get_tier_outside_in_test.py`.
  Full HTTP stack with real adapter, test Postgres, no mocks. Seed a tier row directly, call
  `GET /api/v1/tier/{name}`, assert HTTP 200 and that the response body contains the correct `id`,
  `name`, and `created_at`. Acceptance gate — the slice is not done until this test is green.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Migrating `patch_tier` or `erase_tier` (slices 0036, 0037).
- Lookup by `id` — only name-based lookup is implemented per PRD.
- Caching — not present on the current endpoint; not added here per PRD.
- Returning soft-deleted tiers — the `Tier` ORM model has no soft-delete field.
- Removing `tiers/schemas.py` or `tiers/repository.py` — still referenced by `rate_limits/` and
  `users/` features.
- URL normalisation from `/tier/{name}` (singular) to `/tiers/{name}` (plural) — deferred per PRD.
- Dropping the `request: Request` parameter from the old handler — it was already present and this
  slice's new router does not use it (no `@cache` decorator).

## 8. Open questions

None. The PRD resolves all architectural decisions: port returns `None` / use-case raises, no auth,
no soft delete, URL unchanged, `TierItem` from `_shared/entities.py`.
