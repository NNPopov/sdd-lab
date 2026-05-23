# 0037 · delete_tier — Implementation plan

## 1. Header

- **Feature:** tiers
- **Slice:** 0037_delete_tier
- **PRD:** ./prd.md
- **Reference slice:** `../0036_update_tier/plan.md` — identical two-method port pattern (get + mutation), same superuser auth placement, same tiers DI wiring pattern, same `tiers/router.py` modification pattern.
- **HTTP path:** `DELETE /api/v1/tier/{name}`
- **STABLE files touched:**
  - `bootstrap/container.py` — two new providers (`delete_tier_adapter`, `delete_tier_use_case`) and one `wiring_config` module entry. Permitted for DI wiring of new slices.
  - `.importlinter` — one `ignore_imports` line for the new router module. Permitted per `agent_docs/entry_points/fastapi.md`.

## 2. Context summary

An authenticated superuser sends `DELETE /api/v1/tier/{name}` to permanently remove a tier from
the catalogue. The router converts the path parameter into a `DeleteTierCommand` and delegates to
`DeleteTierUseCase` via a DI-managed `DeleteTierPort`. The use-case performs the existence check:
it calls `port.get(name)` and raises `NotFoundDomainError("Tier not found")` if the result is
`None`. It then calls `port.delete(name)`. The adapter executes a plain
`DELETE FROM tier WHERE name = :name` — no `IntegrityError` handling, since a DELETE cannot
violate a unique constraint. The router returns `DeleteTierResponse(message="Tier deleted")` with
HTTP 200. The old `erase_tier` handler is removed from `tiers/router.py`, completing the tiers
migration: after this slice, that file becomes a pure five-line aggregator of sub-routers.

## 3. API contract

**Path parameters:**

| Param | Type | Notes |
|---|---|---|
| `name` | `str` | Name of the tier to permanently delete |

**Request body:** none.

**Response body** (`DeleteTierResponse`):

| Field | Type | Default |
|---|---|---|
| `message` | `str` | `"Tier deleted"` |

**Status codes:**

- `200 OK` — tier deleted; `{"message": "Tier deleted"}`.
- `404 Not Found` — `NotFoundDomainError("Tier not found")` — no tier with `name` exists.
- `403 Forbidden` — caller is authenticated but is not a superuser (raised by `get_current_superuser`).
- `401 Unauthorized` — no valid bearer token.

## 4. File structure

New files:

```
src/app/features/tiers/delete_tier/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                      # DeleteTierCommand
│   ├── ports/
│   │   ├── __init__.py
│   │   └── delete_tier_port.py          # DeleteTierPort (Protocol, two methods)
│   └── use_case.py                      # DeleteTierUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                       # DeleteTierAdapter(DeleteTierPort)
└── presentation/
    ├── __init__.py
    ├── router.py                        # DELETE /tier/{name}
    └── schemas.py                       # DeleteTierResponse
```

No new ORM model. No Alembic migration. `adapters/db/models/tier.py` (`Tier`) is used as-is.
`tiers/_shared/entities.py` (`TierItem`) was created by slice 0033; this slice imports it and
must not redefine it.

Files modified:

```
src/app/features/tiers/router.py     # remove erase_tier; include delete_tier sub-router
src/app/bootstrap/container.py       # two new providers + one wiring_config entry
.importlinter                        # one ignore_imports line for the new router
```

`bootstrap/router.py` is **not touched** — it already registers `tiers_router` from
`features/tiers/router.py`.

## 5. Implementation steps

### Step 1 — Domain: Command

**File:** `src/app/features/tiers/delete_tier/domain/commands.py`

```python
# FEATURE: delete_tier — domain command.
from pydantic import BaseModel


class DeleteTierCommand(BaseModel):
    name: str
```

Pure `BaseModel`. No framework imports. No validation constraints — the presentation layer
supplies a validated string from the path parameter.

### Step 2 — Domain: Port

**File:** `src/app/features/tiers/delete_tier/domain/ports/delete_tier_port.py`

```python
# FEATURE: delete_tier — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import TierItem


@runtime_checkable
class DeleteTierPort(Protocol):
    async def get(self, name: str) -> TierItem | None: ...
    async def delete(self, name: str) -> None: ...
```

`@runtime_checkable` is mandatory per CLAUDE.md. Two methods because the not-found check (`get`)
and the deletion (`delete`) are separate responsibilities — keeping them narrow and independently
testable (per PRD § Two-method port). Import depth: `....` (4 dots) from
`app.features.tiers.delete_tier.domain.ports` → `app.features.tiers._shared.entities`.

### Step 3 — Domain: Use case

**File:** `src/app/features/tiers/delete_tier/domain/use_case.py`

```python
# FEATURE: delete_tier — use case.
from .....domain.errors import NotFoundDomainError
from .commands import DeleteTierCommand
from .ports.delete_tier_port import DeleteTierPort


class DeleteTierUseCase:
    def __init__(self, port: DeleteTierPort) -> None:
        self._port = port

    async def __call__(self, command: DeleteTierCommand) -> None:
        result = await self._port.get(command.name)
        if result is None:
            raise NotFoundDomainError("Tier not found")
        await self._port.delete(command.name)
```

The use-case owns the not-found check — it is a domain invariant (a tier that does not exist
cannot be deleted). The use-case returns `None`; the router constructs the response. Import
depths: `.....` (5 dots) → `app`; `.` (1 dot) → same `domain/` package. Never raises
`HTTPException`. Never catches.

### Step 4 — Data: Adapter

**File:** `src/app/features/tiers/delete_tier/data/adapter.py`

```python
# FEATURE: delete_tier — data adapter.
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.tier import Tier
from ...._shared.entities import TierItem
from ..domain.ports.delete_tier_port import DeleteTierPort


class DeleteTierAdapter(DeleteTierPort):
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

    async def delete(self, name: str) -> None:
        async with self._session_factory() as session:
            await session.execute(
                delete(Tier).where(Tier.name == name)
            )
            await session.commit()
```

Explicit `class DeleteTierAdapter(DeleteTierPort):` inheritance is mandatory per
`agent_docs/architecture.md` § Terminology. `get` has no `try/except` — read-only query, no
business-meaningful exception to translate (per `agent_docs/error_handling.md` § Right shape:
read-only query, no catch). `delete` has no `try/except` — a DELETE statement cannot violate a
unique constraint; unknown infrastructure exceptions propagate unchanged to the global handler
(per PRD § No IntegrityError handling). Import depths: `.....` (5 dots) → `app`; `....` (4 dots)
→ `app.features.tiers`; `..` (2 dots) → `app.features.tiers.delete_tier`.

### Step 5 — Presentation: Schemas

**File:** `src/app/features/tiers/delete_tier/presentation/schemas.py`

```python
# FEATURE: delete_tier — request/response schemas.
from pydantic import BaseModel, ConfigDict


class DeleteTierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    message: str = "Tier deleted"
```

No request body schema — DELETE carries no body; the tier name comes from the path parameter.
Slice-local; does not reuse `tiers/schemas.py`.

### Step 6 — Presentation: Router

**File:** `src/app/features/tiers/delete_tier/presentation/router.py`

```python
# FEATURE: delete_tier — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, status

from .....bootstrap.container import Container
from .....shared_dependencies import get_current_superuser
from ..domain.commands import DeleteTierCommand
from ..domain.use_case import DeleteTierUseCase
from .schemas import DeleteTierResponse

router = APIRouter(tags=["tiers"])


@router.delete(
    "/tier/{name}",
    response_model=DeleteTierResponse,
    status_code=status.HTTP_200_OK,
    dependencies=[Depends(get_current_superuser)],
)
@inject
async def delete_tier_endpoint(
    name: str,
    use_case: Annotated[
        DeleteTierUseCase,
        Depends(Provide[Container.delete_tier_use_case]),
    ],
) -> DeleteTierResponse:
    command = DeleteTierCommand(name=name)
    await use_case(command)
    return DeleteTierResponse()
```

`get_current_superuser` is applied as a route-level `dependencies=[...]`, consistent with
`create_tier` (slice 0033) and `update_tier` (slice 0036). No `try/except`. URL `/tier/{name}`
is singular, preserving backward compatibility (per PRD § Endpoint URL unchanged). Import depths:
`.....` (5 dots) → `app`; `..` (2 dots) → `app.features.tiers.delete_tier`.

### Step 7 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — permitted modification)

Add to the import block (alongside existing tier imports, after `update_tier` imports once 0036
lands):

```python
from ..features.tiers.delete_tier.data.adapter import DeleteTierAdapter
from ..features.tiers.delete_tier.domain.use_case import DeleteTierUseCase
```

Add to `wiring_config.modules` list:

```python
f"{_app_pkg}.features.tiers.delete_tier.presentation.router",
```

Add to the `Container` class body (after `update_tier_use_case` once 0036 lands):

```python
delete_tier_adapter = providers.Factory(
    DeleteTierAdapter,
    session_factory=session_factory,
)

delete_tier_use_case = providers.Factory(
    DeleteTierUseCase,
    port=delete_tier_adapter,
)
```

Per `agent_docs/entry_points/fastapi.md`: omitting the `wiring_config` entry causes
`Provide[Container.delete_tier_use_case]` to silently resolve to the provider sentinel instead of
the use-case instance, producing `AttributeError` at request time with no startup warning.

### Step 8 — Router integration: `tiers/router.py`

**File:** `src/app/features/tiers/router.py`

**Prerequisite:** Slices 0033–0036 must have already converted this file to an aggregator
(removing `write_tier`, `read_tiers`, `read_tier`, `patch_tier` and adding their sub-routers).
Verify their completion before modifying.

1. Add the sub-router import alongside existing sub-router imports:
   ```python
   from .delete_tier.presentation.router import router as delete_tier_router
   ```
2. Add `router.include_router(delete_tier_router)` after the existing `include_router` calls.
3. Delete the entire `erase_tier` handler function and its
   `@router.delete("/tier/{name}", ...)` decorator.
4. Remove all remaining imports that become unused after deleting `erase_tier`. After this
   change, `tiers/router.py` should contain only five `include_router` calls and their
   sub-router imports — no direct DB access, no FastCRUD, no session injection.

### Step 9 — Import linter

**File:** `.importlinter`

Add one line to the `ignore_imports` section of the `VSA Feature Domains are Independent`
contract:

```
app.features.tiers.delete_tier.presentation.router -> app.bootstrap.container
```

Per `agent_docs/entry_points/fastapi.md`: the presentation router imports `bootstrap.container`
for `Provide[Container.delete_tier_use_case]`; the import-linter may flag this as a cross-domain
dependency. The exemption prevents false positives in the architecture gate test.

### Step 10 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test for this slice:

```
pytest tests/features/tiers/0037_delete_tier/delete_tier_outside_in_test.py -v
```

The smoke test at `tests/smoke/test_app_starts.py` must also pass. The slice is not done until
all of the above pass.

## 6. Tests planned

- **Use-case unit test** — `tests/features/tiers/0037_delete_tier/domain/test_use_case.py`.
  Construct `DeleteTierUseCase` with a mock `DeleteTierPort` (pytest-mock). Assert:
  - Not-found path: `port.get` returns `None` → `NotFoundDomainError("Tier not found")` is
    raised; `port.delete` is **never called**.
  - Happy path: `port.get` returns a `TierItem`; `port.delete` returns `None` → use-case
    returns `None` without raising.
  Prior art: `tests/features/users/0007_delete_user/domain/test_use_case.py`.

- **Adapter unit test** — `tests/features/tiers/0037_delete_tier/data/test_adapter.py`.
  Uses a real async session against the test Postgres database (no session mocks). Assert:
  - `get` happy path: seed a tier, call `get(name)`; assert a `TierItem` is returned with
    correct `id`, `name`, and `created_at`.
  - `get` not-found: call `get` with a name absent from the table; assert `None` is returned.
  - `delete` happy path: seed a tier named `"silver"`, call `delete("silver")`; assert the row
    no longer exists in the database.
  - `delete` no-op: call `delete` with a name not in the table; assert it completes without
    error (zero rows matched — SQL-level non-error; the use-case prevents reaching the adapter
    in the not-found case anyway).
  Prior art: `tests/features/users/0007_delete_user/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/tiers/0037_delete_tier/presentation/test_router.py`.
  Use `httpx.AsyncClient` against the running app with test Postgres. Assert:
  - Valid superuser token + existing tier → HTTP 200, `{"message": "Tier deleted"}`.
  - Path name does not match any tier → HTTP 404.
  - Authenticated but not superuser → HTTP 403.
  - Unauthenticated request → HTTP 401.
  Prior art: `tests/features/users/0007_delete_user/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/tiers/0037_delete_tier/delete_tier_outside_in_test.py`.
  Acceptance gate. Full HTTP stack, real adapter, test Postgres. Seed a tier named `"silver"`,
  authenticate as a superuser, call `DELETE /api/v1/tier/silver`, assert HTTP 200 and
  `{"message": "Tier deleted"}`, verify the row is gone from the database. Must be RED before
  implementation, GREEN after.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Migrating `create_tier`, `list_tiers`, `get_tier`, or `update_tier` — separate slices 0033–0036.
- Soft delete — the `Tier` ORM model has no deleted flag; this is a hard delete (per PRD § Hard delete).
- Cascade deletion of users assigned to the deleted tier — no enforced FK constraint blocks
  deletion (per PRD § Out of Scope).
- Removing `tiers/schemas.py` or `tiers/repository.py` — still referenced by `rate_limits/` and
  `users/` features; cleanup is a separate task (per PRD § Post-migration cleanup).
- URL normalisation from `/tier/{name}` (singular) to `/tiers/{name}` (plural).
- `IntegrityError` handling in the adapter — a DELETE statement cannot violate a unique
  constraint (per PRD § No IntegrityError handling).

## 8. Open questions

None. All design decisions are resolved in the PRD: two-method port, use-case owns not-found,
no `IntegrityError` handling in adapter, hard delete, `None` return from use-case, URL
unchanged, superuser auth via `dependencies=[...]`.
