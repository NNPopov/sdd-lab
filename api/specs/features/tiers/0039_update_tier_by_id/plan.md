# 0039 · update_tier_by_id — Implementation plan

## 1. Header

- **Feature:** tiers
- **Slice:** 0039_update_tier_by_id (modification of existing `update_tier` slice)
- **PRD:** ./prd.md
- **Reference slice:** `specs/features/tiers/0036_update_tier/plan.md` — the slice being modified; all naming, DI wiring, and auth patterns are inherited from it.
- **HTTP path:** `PATCH /api/v1/tier/{id}` (was `PATCH /api/v1/tier/{name}`)
- **STABLE files touched:** none. The existing `update_tier_adapter` and `update_tier_use_case` providers in `bootstrap/container.py` are unchanged — only the implementations they wrap change.

## 2. Context summary

This is a **behaviour-changing modification** of the already-green `0036_update_tier` slice, not a new slice. The existing endpoint `PATCH /tier/{name}` is changed to `PATCH /tier/{id}` where `{id}` is the integer primary key. Identifying by a mutable name is error-prone after renames; the primary key is stable. The request body field `new_name` is renamed to `name` for clarity. The response body (`{"message": "Tier updated"}`), authorization (superuser required), and error semantics (404 for not-found, 409 for duplicate) are unchanged.

Per the CLAUDE.md modification workflow: tests are updated first (going RED against the current implementation), then the implementation is changed until the tests go GREEN.

## 3. API contract

**Path parameter:**

| Param | Type | Notes |
|---|---|---|
| `id` | `int` | Integer primary key of the tier to rename |

**Request body** (`UpdateTierRequest`):

| Field | Type | Validation | Change |
|---|---|---|---|
| `name` | `str` | `min_length=1` | Renamed from `new_name` |

**Response body** (`UpdateTierResponse`) — unchanged:

| Field | Type | Default |
|---|---|---|
| `message` | `str` | `"Tier updated"` |

**Status codes** — unchanged:

- `200 OK` — rename succeeded.
- `404 Not Found` — `NotFoundDomainError("Tier not found")` — no tier with that `id`.
- `409 Conflict` — `DuplicateValueDomainError("Tier name already exists")` — `name` already taken.
- `403 Forbidden` — authenticated but not superuser.
- `401 Unauthorized` — no valid bearer token.
- `422 Unprocessable Entity` — `name` missing, empty, or `id` is not an integer.

## 4. File structure

No new files. No new ORM model. No Alembic migration (`Tier.id` already exists as the primary key).

**Files modified** (all within the existing `update_tier` slice and its tests):

```
src/app/features/tiers/update_tier/
├── domain/
│   ├── commands.py                    # UpdateTierCommand: id: int, name: str
│   ├── ports/
│   │   └── update_tier_port.py        # get(tier_id: int), update(tier_id: int, name: str)
│   └── use_case.py                    # use command.id / command.name
├── data/
│   └── adapter.py                     # query/update by Tier.id
└── presentation/
    ├── schemas.py                     # UpdateTierRequest.name (was new_name)
    └── router.py                      # path /tier/{id}, id: int, command args

tests/features/tiers/0036_update_tier/
├── conftest.py                        # _seed_tier returns id via RETURNING id (if it exists there)
├── domain/
│   └── test_use_case.py               # _CMD uses id=1, name="gold"; assert port.update(1, "gold")
├── data/
│   └── test_adapter.py                # _seed_tier returns id; adapter.get/update use tier_id
├── presentation/
│   └── test_router.py                 # endpoint /tier/{id}; body uses "name" not "new_name"
└── update_tier_outside_in_test.py     # seed via RETURNING id; call /tier/{id}; body uses "name"
```

## 5. Implementation steps

### Step 1 — Update tests (RED phase)

Update all four test files so they exercise the new contract. After this step, run
`pytest tests/features/tiers/0036_update_tier/ -v` and confirm every test fails (or the
suite raises import/signature errors), because the implementation still uses the old signatures.

#### 1a — `tests/features/tiers/0036_update_tier/domain/test_use_case.py`

- Change `_CMD` from `UpdateTierCommand(name="silver", new_name="gold")` to
  `UpdateTierCommand(id=1, name="gold")`.
- In `test_happy_path_calls_port_update_and_returns_none`:
  change `port.update.assert_called_once_with("silver", "gold")` to
  `port.update.assert_called_once_with(1, "gold")`.
- No other changes needed; the not-found and duplicate propagation tests are
  unaffected by the signature change.

#### 1b — `tests/features/tiers/0036_update_tier/data/test_adapter.py`

Update `_seed_tier` to use `RETURNING id` and return the inserted `id`:

```python
async def _seed_tier(name: str) -> int:
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text("INSERT INTO tier (name, created_at) VALUES (:name, NOW()) RETURNING id"),
            {"name": name},
        )
        await session.commit()
        return result.scalar_one()
```

Update each test to capture and use the returned id:

- `test_get_returns_tier_item_when_found`: capture `tier_id = await _seed_tier(...)`;
  call `adapter.get(tier_id)`; assert `result.id == tier_id`.
- `test_get_returns_none_when_tier_absent`: call `adapter.get(99999)` (a non-existent integer).
- `test_update_renames_tier_and_sets_updated_at`: capture `tier_id = await _seed_tier("adapter_silver_upd")`;
  call `adapter.update(tier_id, "adapter_gold_upd")`; DB assertion is unchanged (still checks by name).
- `test_update_duplicate_name_raises_duplicate_value_domain_error`: capture both ids;
  call `adapter.update(silver_id, "adapter_gold_dup")`.
- `test_update_non_integrity_error_propagates_unchanged`: call `adapter.update(1, "gold")` (id, not name).

#### 1c — `tests/features/tiers/0036_update_tier/presentation/test_router.py`

- Change `_ENDPOINT` from `"/api/v1/tier/{name}"` to `"/api/v1/tier/{id}"`.
- Wherever tiers are seeded with a raw `INSERT`, add `RETURNING id` and capture the id.
  Use the captured id to format the endpoint URL: `_ENDPOINT.format(id=tier_id)`.
- Change all JSON bodies from `{"new_name": "..."}` to `{"name": "..."}`.
- For tests that do not seed a real tier (404, 403, 401, 422 tests): use any integer,
  e.g. `_ENDPOINT.format(id=99999)` for 404, `_ENDPOINT.format(id=1)` for 403/401/422.
- Rename `test_update_tier_missing_new_name_returns_422` to
  `test_update_tier_missing_name_returns_422`; body becomes `{}`.
- Rename `test_update_tier_empty_new_name_returns_422` to
  `test_update_tier_empty_name_returns_422`; body becomes `{"name": ""}`.

#### 1d — `tests/features/tiers/0036_update_tier/update_tier_outside_in_test.py`

- Add `RETURNING id` to both `INSERT INTO tier` statements; capture `tier_id` for each.
- Build endpoint URLs as `f"{_ENDPOINT}/{tier_id}"` (Scenario 1) and
  `f"{_ENDPOINT}/{silver_id}"` (Scenario 2).
- Change JSON bodies from `{"new_name": "..."}` to `{"name": "..."}`.
- DB assertions remain unchanged (still checking by name and `updated_at`).

**After step 1:** run `pytest tests/features/tiers/0036_update_tier/ -v` and confirm failures.
The tests must be RED before proceeding to step 2.

### Step 2 — Domain: Command

**File:** `src/app/features/tiers/update_tier/domain/commands.py`

```python
# FEATURE: update_tier — domain command.
from pydantic import BaseModel


class UpdateTierCommand(BaseModel):
    id: int
    name: str
```

`id` is the tier's integer primary key (from the path parameter); `name` is the desired new name
(from the request body).

### Step 3 — Domain: Port

**File:** `src/app/features/tiers/update_tier/domain/ports/update_tier_port.py`

```python
# FEATURE: update_tier — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import TierItem


@runtime_checkable
class UpdateTierPort(Protocol):
    async def get(self, tier_id: int) -> TierItem | None: ...
    async def update(self, tier_id: int, name: str) -> None: ...
```

Import depth: `....` (4 dots) from `domain/ports/` reaches `tiers/`, then `._shared.entities`.
`@runtime_checkable` is mandatory per CLAUDE.md.

### Step 4 — Domain: Use case

**File:** `src/app/features/tiers/update_tier/domain/use_case.py`

```python
# FEATURE: update_tier — use case.
from .....domain.errors import NotFoundDomainError
from .commands import UpdateTierCommand
from .ports.update_tier_port import UpdateTierPort


class UpdateTierUseCase:
    def __init__(self, port: UpdateTierPort) -> None:
        self._port = port

    async def __call__(self, command: UpdateTierCommand) -> None:
        result = await self._port.get(command.id)
        if result is None:
            raise NotFoundDomainError("Tier not found")
        await self._port.update(command.id, command.name)
```

`command.id` is the lookup key; `command.name` is the new name. Import depth: `.....` (5 dots)
from `domain/` reaches `app/`.

### Step 5 — Data: Adapter

**File:** `src/app/features/tiers/update_tier/data/adapter.py`

```python
# FEATURE: update_tier — data adapter.
from sqlalchemy import func, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.tier import Tier
from .....domain.errors import DuplicateValueDomainError
from ...._shared.entities import TierItem
from ..domain.ports.update_tier_port import UpdateTierPort


class UpdateTierAdapter(UpdateTierPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get(self, tier_id: int) -> TierItem | None:
        async with self._session_factory() as session:
            result = await session.execute(select(Tier).where(Tier.id == tier_id))
            row = result.scalar_one_or_none()
            if row is None:
                return None
            return TierItem.model_validate(row)

    async def update(self, tier_id: int, name: str) -> None:
        async with self._session_factory() as session:
            try:
                await session.execute(
                    update(Tier)
                    .where(Tier.id == tier_id)
                    .values(name=name, updated_at=func.now())
                )
                await session.commit()
            except IntegrityError as exc:
                raise DuplicateValueDomainError("Tier name already exists") from exc
```

`get` filters by `Tier.id`; no `try/except` on the read path (per `agent_docs/error_handling.md`).
`update` filters by `Tier.id` and sets `Tier.name`. The `try` block wraps both `execute` and
`commit` because asyncpg raises `IntegrityError` at `execute()` time for `UPDATE`, not at
`commit()` (per project memory on asyncpg IntegrityError timing for UPDATE). Import depths
are unchanged from the 0036 adapter.

### Step 6 — Presentation: Schemas

**File:** `src/app/features/tiers/update_tier/presentation/schemas.py`

```python
# FEATURE: update_tier — request/response schemas.
from pydantic import BaseModel, ConfigDict, Field


class UpdateTierRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    name: str = Field(min_length=1)


class UpdateTierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    message: str = "Tier updated"
```

`new_name` is renamed to `name`. `UpdateTierResponse` is unchanged.

### Step 7 — Presentation: Router

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
    "/tier/{id}",
    response_model=UpdateTierResponse,
    status_code=status.HTTP_200_OK,
    dependencies=[Depends(get_current_superuser)],
)
@inject
async def update_tier_endpoint(
    id: int,
    body: UpdateTierRequest,
    use_case: Annotated[
        UpdateTierUseCase,
        Depends(Provide[Container.update_tier_use_case]),
    ],
) -> UpdateTierResponse:
    command = UpdateTierCommand(id=id, name=body.name)
    await use_case(command)
    return UpdateTierResponse()
```

Path parameter changes from `name: str` to `id: int`. FastAPI validates that `id` is an integer;
a non-integer path segment returns 422 automatically. No `try/except` — domain errors propagate
to the global exception handler.

### Step 8 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest tests/features/tiers/0036_update_tier/ -v
pytest
```

The smoke test at `tests/smoke/test_app_starts.py` must also pass. The slice is not done until
all of the above pass.

## 6. Tests planned

All four levels already exist under `tests/features/tiers/0036_update_tier/` and are updated
in place (step 1 above). No new test files are created.

- **Use-case unit test** — `tests/features/tiers/0036_update_tier/domain/test_use_case.py`.
  Mocked port. Key changes: `_CMD = UpdateTierCommand(id=1, name="gold")`; happy-path
  assertion becomes `port.update.assert_called_once_with(1, "gold")`.

- **Adapter unit test** — `tests/features/tiers/0036_update_tier/data/test_adapter.py`.
  Real test Postgres. Key change: `_seed_tier` returns the inserted `id` via `RETURNING id`;
  all `adapter.get` and `adapter.update` calls use `tier_id` (int) instead of a name string.

- **Endpoint integration test** — `tests/features/tiers/0036_update_tier/presentation/test_router.py`.
  `httpx.AsyncClient` against test Postgres. Key changes: endpoint URL uses `{id}` captured
  from `RETURNING id`; JSON body uses `"name"` instead of `"new_name"`.

- **Outside-in test** — `tests/features/tiers/0036_update_tier/update_tier_outside_in_test.py`.
  Full HTTP stack. Key changes: same as endpoint integration test above.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Changing the response body (still `{"message": "Tier updated"}`).
- Migrating `delete_tier` to id-based lookup — separate slice 0040.
- Renaming the `name` column in the database.
- Returning the updated `TierItem` in the response.
- URL normalisation to plural `/tiers/{id}`.
- Converting `get_current_superuser` auth errors to `DomainError` subclasses.
- Cache invalidation — no caching applied to tier endpoints.

## 8. Open questions

None. All design decisions are resolved in the PRD: lookup by `Tier.id`, rename `new_name`→`name`
in the request body, response unchanged, same auth and error semantics as 0036.
