# 0036 · update_tier — Implementation plan

## 1. Header

- **Feature:** tiers
- **Slice:** 0036_update_tier
- **PRD:** ./prd.md
- **Reference slices:**
  - `specs/features/users/0006_update_user/plan.md` — same update-operation shape (get-then-mutate, not-found owned by use-case, IntegrityError caught by adapter).
  - `specs/features/tiers/0033_create_tier/plan.md` — tiers-specific DI wiring pattern, `.importlinter` entry, `get_current_superuser` placement.
  - `specs/features/tiers/0035_get_tier/plan.md` — tiers-specific relative import depths and `Provide`/`@inject` router pattern.
- **HTTP path:** `PATCH /api/v1/tier/{name}`
- **STABLE files touched:**
  - `bootstrap/container.py` — two new providers (`update_tier_adapter`, `update_tier_use_case`) and one `wiring_config` module entry. Permitted for DI wiring of new slices.
  - `.importlinter` — one `ignore_imports` line for the new router module. Permitted per `agent_docs/entry_points/fastapi.md`.

## 2. Context summary

An authenticated superuser sends `PATCH /api/v1/tier/{name}` with a JSON body containing `new_name`
to rename an existing tier. The router converts the path parameter and request body into an
`UpdateTierCommand` and delegates to `UpdateTierUseCase` via a DI-managed `UpdateTierPort`. The
use-case performs the not-found check: it calls `port.get(name)` and raises `NotFoundDomainError`
if the result is `None`. It then calls `port.update(name, new_name)`. The adapter executes the
`UPDATE` statement (setting `updated_at = now()`), catches `IntegrityError` from the commit, and
re-raises it as `DuplicateValueDomainError`. The router returns `UpdateTierResponse(message="Tier
updated")` with HTTP 200. The old `patch_tier` fat handler is removed once the new slice is wired
in, leaving exactly one implementation of this behaviour.

## 3. API contract

**Path parameters:**

| Param | Type | Notes |
|---|---|---|
| `name` | `str` | Current name of the tier to rename |

**Request body** (`UpdateTierRequest`):

| Field | Type | Validation |
|---|---|---|
| `new_name` | `str` | required; `min_length=1` |

**Response body** (`UpdateTierResponse`):

| Field | Type | Default |
|---|---|---|
| `message` | `str` | `"Tier updated"` |

**Status codes:**

- `200 OK` — rename succeeded; `{"message": "Tier updated"}`.
- `404 Not Found` — `NotFoundDomainError("Tier not found")` — no tier with `name` exists.
- `409 Conflict` — `DuplicateValueDomainError("Tier name already exists")` — `new_name` is already
  taken by another tier.
- `403 Forbidden` — caller is authenticated but is not a superuser (raised by `get_current_superuser`).
- `401 Unauthorized` — no valid bearer token.
- `422 Unprocessable Entity` — Pydantic field-level validation failure (e.g., missing `new_name`).

## 4. File structure

New files:

```
src/app/features/tiers/update_tier/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                      # UpdateTierCommand
│   ├── ports/
│   │   ├── __init__.py
│   │   └── update_tier_port.py          # UpdateTierPort (Protocol, two methods)
│   └── use_case.py                      # UpdateTierUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                       # UpdateTierAdapter(UpdateTierPort)
└── presentation/
    ├── __init__.py
    ├── router.py                        # PATCH /tier/{name}
    └── schemas.py                       # UpdateTierRequest, UpdateTierResponse
```

No new ORM model. No Alembic migration. `adapters/db/models/tier.py` (`Tier`) is used as-is;
its `updated_at` column is set by the adapter's `UPDATE` statement. `tiers/_shared/entities.py`
(`TierItem`) was created by slice 0033; this slice imports it from there and must not redefine it.

Files modified:

```
src/app/features/tiers/router.py     # remove patch_tier; include update_tier sub-router
src/app/bootstrap/container.py       # two new providers + one wiring_config entry
.importlinter                        # one ignore_imports line for the new router
```

`bootstrap/router.py` is **not touched** — it already registers `tiers_router` from
`features/tiers/router.py`.

## 5. Implementation steps

### Step 1 — Domain: Command

**File:** `src/app/features/tiers/update_tier/domain/commands.py`

```python
# FEATURE: update_tier — domain command.
from pydantic import BaseModel


class UpdateTierCommand(BaseModel):
    name: str
    new_name: str
```

`name` is the current tier name (from the path parameter); `new_name` is the desired rename (from
the request body). Pure `BaseModel` — no framework imports. No validation constraints; the
presentation layer supplies validated strings.

### Step 2 — Domain: Port

**File:** `src/app/features/tiers/update_tier/domain/ports/update_tier_port.py`

```python
# FEATURE: update_tier — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import TierItem


@runtime_checkable
class UpdateTierPort(Protocol):
    async def get(self, name: str) -> TierItem | None: ...
    async def update(self, name: str, new_name: str) -> None: ...
```

`@runtime_checkable` is mandatory per CLAUDE.md. Two methods because the not-found check
(`get`) and the rename (`update`) are separate use-case responsibilities — keeping them narrow and
independently testable (per PRD § Two-method port). Import depth: `....` (4 dots) from
`app.features.tiers.update_tier.domain.ports` → `app.features.tiers._shared.entities`.

### Step 3 — Domain: Use case

**File:** `src/app/features/tiers/update_tier/domain/use_case.py`

```python
# FEATURE: update_tier — use case.
from .....domain.errors import NotFoundDomainError
from ..._shared.entities import TierItem
from .commands import UpdateTierCommand
from .ports.update_tier_port import UpdateTierPort


class UpdateTierUseCase:
    def __init__(self, port: UpdateTierPort) -> None:
        self._port = port

    async def __call__(self, command: UpdateTierCommand) -> None:
        result = await self._port.get(command.name)
        if result is None:
            raise NotFoundDomainError("Tier not found")
        await self._port.update(command.name, command.new_name)
```

The use-case owns the not-found check — it is a domain invariant (a tier that does not exist cannot
be renamed). `DuplicateValueDomainError` is not caught here; it propagates from `port.update()` to
the global exception handler unchanged (per PRD § Use case owns not-found, adapter owns duplicate).
The use-case returns `None`; the router constructs the response. Import depths: `.....` (5 dots) →
`app`; `...` (3 dots) → `app.features.tiers`.

### Step 4 — Data: Adapter

**File:** `src/app/features/tiers/update_tier/data/adapter.py`

```python
# FEATURE: update_tier — data adapter.
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.tier import Tier
from .....domain.errors import DuplicateValueDomainError
from ...._shared.entities import TierItem
from ..domain.ports.update_tier_port import UpdateTierPort


class UpdateTierAdapter(UpdateTierPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get(self, name: str) -> TierItem | None:
        async with self._session_factory() as session:
            result = await session.execute(
                select(Tier).where(Tier.name == name)
            )
            row = result.scalar_one_or_none()
            if row is None:
                return None
            return TierItem.model_validate(row)

    async def update(self, name: str, new_name: str) -> None:
        async with self._session_factory() as session:
            await session.execute(
                update(Tier)
                .where(Tier.name == name)
                .values(name=new_name, updated_at=func.now())
            )
            try:
                await session.commit()
            except IntegrityError as exc:
                raise DuplicateValueDomainError("Tier name already exists") from exc
```

Note: `func` is `sqlalchemy.sql.func`. Add `from sqlalchemy import func` to the imports. Explicit
`class UpdateTierAdapter(UpdateTierPort):` inheritance is mandatory per `agent_docs/architecture.md`
§ Terminology. `get` has no `try/except` — read-only query, no business-meaningful exception to
translate (per `agent_docs/error_handling.md` § Right shape: read-only query, no catch). `update`
catches `IntegrityError` only — unknown exceptions propagate unchanged. `raise ... from exc`
preserves the original stack trace. Import depths: `....` (5 dots) → `app`; `....` (4 dots) →
`app.features.tiers`; `..` (2 dots) → `app.features.tiers.update_tier`.

### Step 5 — Presentation: Schemas

**File:** `src/app/features/tiers/update_tier/presentation/schemas.py`

```python
# FEATURE: update_tier — request/response schemas.
from pydantic import BaseModel, ConfigDict, Field


class UpdateTierRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    new_name: str = Field(min_length=1)


class UpdateTierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    message: str = "Tier updated"
```

Slice-local; does not reuse `tiers/schemas.py`. `new_name` is required (non-optional) — a stricter
and clearer contract than the old `TierUpdate.name: str | None` (per PRD § Further Notes).

### Step 6 — Presentation: Router

**File:** `src/app/features/tiers/update_tier/presentation/router.py`

```python
# FEATURE: update_tier — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, status

from .....bootstrap.container import Container
from .....shared_dependencies import get_current_superuser
from ..domain.commands import UpdateTierCommand
from ..domain.use_case import UpdateTierUseCase
from .schemas import UpdateTierRequest, UpdateTierResponse

router = APIRouter(tags=["tiers"])


@router.patch(
    "/tier/{name}",
    response_model=UpdateTierResponse,
    status_code=status.HTTP_200_OK,
    dependencies=[Depends(get_current_superuser)],
)
@inject
async def update_tier_endpoint(
    name: str,
    body: UpdateTierRequest,
    use_case: Annotated[
        UpdateTierUseCase,
        Depends(Provide[Container.update_tier_use_case]),
    ],
) -> UpdateTierResponse:
    command = UpdateTierCommand(name=name, new_name=body.new_name)
    await use_case(command)
    return UpdateTierResponse()
```

`get_current_superuser` is applied as a route-level `dependencies=[...]`, consistent with
`create_tier` (slice 0033). No `try/except` — domain errors propagate to the global exception
handler. URL `/tier/{name}` is singular, preserving backward compatibility (per PRD § Endpoint URL
unchanged). Import depths: `.....` (5 dots) → `app`; `..` (2 dots) → `app.features.tiers.update_tier`.

### Step 7 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — permitted modification)

Add to the import block (alongside existing tier imports):

```python
from ..features.tiers.update_tier.data.adapter import UpdateTierAdapter
from ..features.tiers.update_tier.domain.use_case import UpdateTierUseCase
```

Add to `wiring_config.modules` list:

```python
f"{_app_pkg}.features.tiers.update_tier.presentation.router",
```

Add to the `Container` class body (after `get_tier_use_case`):

```python
update_tier_adapter = providers.Factory(
    UpdateTierAdapter,
    session_factory=session_factory,
)

update_tier_use_case = providers.Factory(
    UpdateTierUseCase,
    port=update_tier_adapter,
)
```

Per `agent_docs/entry_points/fastapi.md`: omitting the `wiring_config` entry causes
`Provide[Container.update_tier_use_case]` to silently resolve to the provider sentinel instead of
the use-case instance, producing `AttributeError` at request time with no startup warning.

### Step 8 — Router integration: `tiers/router.py`

**File:** `src/app/features/tiers/router.py`

**Prerequisite:** Slices 0033, 0034, and 0035 must have already converted this file to an
aggregator (removing `write_tier`, `read_tiers`, `read_tier` and adding their sub-routers).
Verify their completion before modifying.

1. Add the sub-router import alongside existing sub-router imports:
   ```python
   from .update_tier.presentation.router import router as update_tier_router
   ```
2. Add `router.include_router(update_tier_router)` after the existing `include_router` calls.
3. Delete the entire `patch_tier` handler function and its `@router.patch("/tier/{name}", ...)`
   decorator.
4. Remove any imports that become unused after deleting `patch_tier`. Verify each candidate
   against the remaining handler (`erase_tier`) before removing. Do not remove `crud_tiers`,
   `TierRead`, `TierUpdate`, or `get_current_superuser` if they are still used by `erase_tier`.

### Step 9 — Import linter

**File:** `.importlinter`

Add one line to the `ignore_imports` section of the `VSA Feature Domains are Independent` contract:

```
app.features.tiers.update_tier.presentation.router -> app.bootstrap.container
```

Per `agent_docs/entry_points/fastapi.md`: the presentation router imports `bootstrap.container` for
`Provide[Container.update_tier_use_case]`; the import-linter flags this as a cross-domain
dependency. The exemption is mandatory to keep the architecture gate test green.

### Step 10 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test for this slice:

```
pytest tests/features/tiers/0036_update_tier/update_tier_outside_in_test.py -v
```

The smoke test at `tests/smoke/test_app_starts.py` must also pass. The slice is not done until all
of the above pass.

## 6. Tests planned

- **Use-case unit test** — `tests/features/tiers/0036_update_tier/domain/test_use_case.py`.
  Construct `UpdateTierUseCase` with a mock `UpdateTierPort` (pytest-mock). Assert:
  - Not-found path: `port.get` returns `None` → `NotFoundDomainError("Tier not found")` is raised;
    `port.update` is **never called**.
  - Happy path: `port.get` returns a `TierItem`; `port.update` returns `None` → use-case returns
    `None` without raising.
  - Duplicate path: `port.get` returns a `TierItem`; `port.update` raises `DuplicateValueDomainError`
    → error propagates unchanged from the use-case.
  Prior art: `tests/features/users/0006_update_user/domain/test_use_case.py`.

- **Adapter unit test** — `tests/features/tiers/0036_update_tier/data/test_adapter.py`.
  Uses a real async session against the test Postgres database (no session mocks). Assert:
  - `get` happy path: seed a tier, call `get(name)`; assert a `TierItem` is returned with correct
    `id`, `name`, and `created_at`.
  - `get` not-found: call `get` with a name absent from the table; assert `None` is returned.
  - `update` happy path: seed a tier named `"silver"`, call `update("silver", "gold")`; assert the
    row now has `name="gold"` and a non-null `updated_at`.
  - `update` duplicate: seed tiers named `"silver"` and `"gold"`, call `update("silver", "gold")`
    → `DuplicateValueDomainError` is raised.
  - `update` unknown exception propagation: assert that an `IntegrityError` variant that is not a
    uniqueness violation propagates unchanged — the adapter does not swallow arbitrary exceptions.
  Prior art: `tests/features/users/0006_update_user/data/test_adapter.py`.

- **Endpoint integration test** — `tests/features/tiers/0036_update_tier/presentation/test_router.py`.
  Use `httpx.AsyncClient` against the running app with test Postgres. Assert:
  - Valid payload + superuser token → HTTP 200, `{"message": "Tier updated"}`.
  - Path name does not match any tier → HTTP 404.
  - `new_name` already taken → HTTP 409.
  - Authenticated but not superuser → HTTP 403.
  - Unauthenticated request → HTTP 401.
  - Missing `new_name` field → HTTP 422.
  Prior art: `tests/features/users/0006_update_user/presentation/test_router.py`.

- **Outside-in test** — `tests/features/tiers/0036_update_tier/update_tier_outside_in_test.py`.
  Acceptance gate. Full HTTP stack, real adapter, test Postgres. Seed a tier named `"silver"`,
  authenticate as a superuser, call `PATCH /api/v1/tier/silver` with `{"new_name": "gold"}`,
  assert HTTP 200 and `{"message": "Tier updated"}`. Must be RED before implementation, GREEN after.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Migrating `erase_tier` (`DELETE /tier/{name}`) — separate slice 0037.
- Partial updates beyond renaming — the only mutable field is `name`.
- Returning the updated `TierItem` in the response body — current API contract is a confirmation
  message only.
- URL normalisation from `/tier/{name}` (singular) to `/tiers/{name}` (plural).
- Removing `tiers/schemas.py` or `tiers/repository.py` — still referenced by `rate_limits/` and
  `users/` features.
- Converting `get_current_superuser` 403/401 exceptions to `DomainError` subclasses — pre-existing
  pattern, out of scope.
- Cache invalidation — no caching is applied to tier read endpoints.

## 8. Open questions

None. All design decisions are resolved in the PRD: two-method port, use-case owns not-found,
adapter owns duplicate, direct-UPDATE (no SELECT-EXISTS before UPDATE), `updated_at` set at SQL
level, `None` return from use-case, URL unchanged, superuser auth via `dependencies=[...]`.
