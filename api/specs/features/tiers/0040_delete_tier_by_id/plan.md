# 0040 · delete_tier_by_id — Implementation plan

## 1. Header

- **Feature:** tiers
- **Slice:** 0040_delete_tier_by_id
- **PRD:** ./prd.md
- **Reference slice:** `../0037_delete_tier/plan.md` — same use-case structure; this plan modifies
  the files created there.
- **HTTP path:** `DELETE /api/v1/tier/{id}`
- **STABLE files touched:** none. The DI container, `.importlinter`, and feature router were all
  wired in slice 0037. This change modifies only FEATURE files within the `delete_tier` slice.

## 2. Context summary

Slice 0040 is a **modification** of the already-green `delete_tier` slice (0037). The existing
`DELETE /api/v1/tier/{name}` endpoint is repointed to `DELETE /api/v1/tier/{id}` where `{id}` is
the integer primary key. Because `id` is immutable, this removes the race condition where a tier
rename between fetch and delete could target the wrong tier or yield a spurious 404. The `Tier`
ORM model already exposes `id: Mapped[int]`, and `TierItem` already carries `id: int`, so no ORM
or entity change is needed. All six source files in the `delete_tier` slice are updated; DI wiring,
router registration, and import-linter entries are untouched.

Per the project workflow for modifying an existing slice (CLAUDE.md § Modifying an existing slice):
tests are updated first to go RED, then the implementation is changed until the outside-in test
returns GREEN.

## 3. API contract

**Path parameters:**

| Param | Type | Notes |
|---|---|---|
| `id` | `int` | Integer primary key of the tier to permanently delete. FastAPI returns 422 automatically if the value is not a valid integer. |

**Request body:** none.

**Response body** (`DeleteTierResponse`):

| Field | Type | Default |
|---|---|---|
| `message` | `str` | `"Tier deleted"` |

**Status codes:**

- `200 OK` — tier deleted; `{"message": "Tier deleted"}`.
- `404 Not Found` — `NotFoundDomainError("Tier not found")` — no tier with the given `id` exists.
- `422 Unprocessable Entity` — FastAPI rejects a non-integer `{id}`; never reaches the use case.
- `403 Forbidden` — caller is authenticated but not a superuser.
- `401 Unauthorized` — no valid bearer token.

## 4. File structure

No new files. The following existing FEATURE files are modified in-place:

```
src/app/features/tiers/delete_tier/
├── domain/
│   ├── commands.py              # name: str  →  id: int
│   ├── ports/
│   │   └── delete_tier_port.py  # get/delete signatures: name: str  →  tier_id: int
│   └── use_case.py              # command.name  →  command.id
├── data/
│   └── adapter.py               # Tier.name == name  →  Tier.id == tier_id
└── presentation/
    └── router.py                # path /tier/{name}  →  /tier/{id}; param type str → int
```

`presentation/schemas.py` is unchanged — the response shape is identical.

The following existing test files are updated to reflect the new signatures:

```
tests/features/tiers/0037_delete_tier/
├── conftest.py                          # _seed_tier returns id via RETURNING id
├── domain/test_use_case.py              # DeleteTierCommand(id=1); port calls with int
├── data/test_adapter.py                 # adapter.get/delete called with tier_id (int)
├── presentation/test_router.py          # seeds with RETURNING id; calls DELETE /tier/{id}
└── delete_tier_outside_in_test.py       # seeds with RETURNING id; calls DELETE /tier/{id}
```

## 5. Implementation steps

Per CLAUDE.md: update tests first (going RED), then change implementation until GREEN.

### Step 1 — Update tests: outside-in test

**File:** `tests/features/tiers/0037_delete_tier/delete_tier_outside_in_test.py`

Change the seed query from `INSERT INTO tier (name) VALUES (:name)` (no id capture) to
`INSERT INTO tier (name) VALUES (:name) RETURNING id` and bind the returned id. Change the
request path from `DELETE /api/v1/tier/{name}` to `DELETE /api/v1/tier/{id}`.

Run the outside-in test and confirm it is **RED** against the unchanged implementation (the path
still routes to `{name}`, so FastAPI will either 404 or route-mismatch).

### Step 2 — Update tests: conftest

**File:** `tests/features/tiers/0037_delete_tier/conftest.py`

If `_seed_tier` is a shared fixture that returns the tier name, change it to return the tier `id`
via `RETURNING id` on the `INSERT`. Tests that previously used the name to call endpoints or
adapters will now use the `id`.

### Step 3 — Update tests: adapter unit test

**File:** `tests/features/tiers/0037_delete_tier/data/test_adapter.py`

Change every call from `adapter.get(name)` / `adapter.delete(name)` to
`adapter.get(tier_id)` / `adapter.delete(tier_id)`. Seed via `RETURNING id`; use the captured
`id` as the argument.

### Step 4 — Update tests: use-case unit test

**File:** `tests/features/tiers/0037_delete_tier/domain/test_use_case.py`

Change `DeleteTierCommand(name="gold")` to `DeleteTierCommand(id=1)`. Change mock port call
assertions from `port.get("gold")` / `port.delete("gold")` to `port.get(1)` / `port.delete(1)`.

### Step 5 — Update tests: router integration test

**File:** `tests/features/tiers/0037_delete_tier/presentation/test_router.py`

Change seed queries to capture `id` via `RETURNING id`. Change endpoint calls from
`DELETE /api/v1/tier/{name}` to `DELETE /api/v1/tier/{id}`.

### Step 6 — Implementation: Command

**File:** `src/app/features/tiers/delete_tier/domain/commands.py`

```python
# FEATURE: delete_tier — domain command.
from pydantic import BaseModel


class DeleteTierCommand(BaseModel):
    id: int
```

Single field change: `name: str` → `id: int`. No validation constraints needed — the presentation
layer supplies a validated integer from the path parameter.

### Step 7 — Implementation: Port

**File:** `src/app/features/tiers/delete_tier/domain/ports/delete_tier_port.py`

```python
# FEATURE: delete_tier — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import TierItem


@runtime_checkable
class DeleteTierPort(Protocol):
    async def get(self, tier_id: int) -> TierItem | None: ...
    async def delete(self, tier_id: int) -> None: ...
```

Both method signatures change from `name: str` to `tier_id: int`. The `@runtime_checkable`
decorator and `Protocol` base are unchanged. Import depth: `....` (4 dots from
`domain/ports/`) → `tiers._shared.entities`.

### Step 8 — Implementation: Use case

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
        result = await self._port.get(command.id)
        if result is None:
            raise NotFoundDomainError("Tier not found")
        await self._port.delete(command.id)
```

`command.name` → `command.id` in both port calls. Domain logic (not-found check) is unchanged.
The use-case never raises `HTTPException`; never catches. Import depths unchanged.

### Step 9 — Implementation: Adapter

**File:** `src/app/features/tiers/delete_tier/data/adapter.py`

```python
# FEATURE: delete_tier — data adapter.
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.tier import Tier
from ..._shared.entities import TierItem
from ..domain.ports.delete_tier_port import DeleteTierPort


class DeleteTierAdapter(DeleteTierPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get(self, tier_id: int) -> TierItem | None:
        async with self._session_factory() as session:
            result = await session.execute(select(Tier).where(Tier.id == tier_id))
            row = result.scalar_one_or_none()
            if row is None:
                return None
            return TierItem.model_validate(row)

    async def delete(self, tier_id: int) -> None:
        async with self._session_factory() as session:
            await session.execute(delete(Tier).where(Tier.id == tier_id))
            await session.commit()
```

Filter column changes from `Tier.name == name` to `Tier.id == tier_id` in both methods.
No `try/except` in either method — a DELETE cannot violate a unique constraint; unknown
infrastructure exceptions propagate unchanged to the global handler (per
`agent_docs/error_handling.md` § Right shape: read-only query, no catch).

### Step 10 — Implementation: Router

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
    "/tier/{id}",
    response_model=DeleteTierResponse,
    status_code=status.HTTP_200_OK,
    dependencies=[Depends(get_current_superuser)],
)
@inject
async def delete_tier_endpoint(
    id: int,
    use_case: Annotated[
        DeleteTierUseCase,
        Depends(Provide[Container.delete_tier_use_case]),
    ],
) -> DeleteTierResponse:
    command = DeleteTierCommand(id=id)
    await use_case(command)
    return DeleteTierResponse()
```

Path changes from `/tier/{name}` to `/tier/{id}`. Parameter `name: str` → `id: int`. FastAPI
automatically validates that `{id}` is an integer and returns 422 if not. The command is
constructed with `id=id`. All other aspects (auth, response schema, DI wiring) are unchanged.

### Step 11 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test (must go from RED to GREEN after steps 6–10):

```
pytest tests/features/tiers/0037_delete_tier/delete_tier_outside_in_test.py -v
```

The smoke test at `tests/smoke/test_app_starts.py` must also pass.

## 6. Tests planned

All four levels are updated in-place under `tests/features/tiers/0037_delete_tier/`. No new test
files are created — the existing test suite is modified to reflect the new `id`-based contract.

- **Use-case unit test** — `tests/features/tiers/0037_delete_tier/domain/test_use_case.py`.
  Uses `DeleteTierCommand(id=1)`. Asserts `port.get(1)` is called; asserts `NotFoundDomainError`
  when `port.get` returns `None` with `port.delete` never called; asserts happy path calls
  `port.delete(1)` and returns `None`.

- **Adapter unit test** — `tests/features/tiers/0037_delete_tier/data/test_adapter.py`.
  Seeds a tier via `INSERT ... RETURNING id`. Calls `adapter.get(tier_id)` and
  `adapter.delete(tier_id)` using the seeded integer id. Asserts not-found returns `None`;
  asserts row is absent after delete.

- **Endpoint integration test** — `tests/features/tiers/0037_delete_tier/presentation/test_router.py`.
  Seeds tier and captures `id` via `RETURNING id`. Calls `DELETE /api/v1/tier/{id}`. Asserts 200
  and `{"message": "Tier deleted"}`; asserts 404 for a nonexistent id; asserts 403 for
  non-superuser; asserts 401 for unauthenticated.

- **Outside-in test** — `tests/features/tiers/0037_delete_tier/delete_tier_outside_in_test.py`.
  Acceptance gate. Seeds tier via `RETURNING id`; authenticates as superuser; calls
  `DELETE /api/v1/tier/{id}`; asserts 200 and `{"message": "Tier deleted"}`; verifies row is
  absent from the database. Must be RED before step 6, GREEN after step 10.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Soft-deleting tiers.
- Cascading deletes to users assigned to the deleted tier.
- Changing the response body shape.
- Allowing non-superusers to delete tiers.
- URL normalisation from `/tier/{id}` (singular) to `/tiers/{id}` (plural).
- `IntegrityError` handling in the adapter — a DELETE cannot violate a unique constraint.

## 8. Open questions

None. All design decisions are resolved in the PRD: use integer `id`, port method names
unchanged (only parameter type changes), use-case owns the not-found check, hard delete, response
body unchanged, superuser auth unchanged.
