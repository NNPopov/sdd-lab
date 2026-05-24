# 0038 · get_tier_by_id — Implementation plan

## 1. Header

- **Feature:** tiers
- **Slice:** 0038_get_tier_by_id
- **PRD:** ./prd.md
- **Reference slice:** `specs/features/tiers/0035_get_tier/plan.md` — this slice is a
  **modification** of the already-green `get_tier` (0035) slice. The response shape, port
  contract, use-case logic, DI wiring, and router registration are all unchanged. Only three
  files in `get_tier/` are edited: `domain/commands.py`, `data/adapter.py`, and
  `presentation/router.py`.
- **HTTP path:** `GET /api/v1/tier/{tier_id}` (replaces `GET /api/v1/tier/{name}`)
- **STABLE files touched:** none. The `get_tier` slice is already wired in
  `bootstrap/container.py` and registered in `features/tiers/router.py`. No new providers or
  router entries are required.

## 2. Context summary

An API consumer sends `GET /api/v1/tier/{tier_id}` with the tier's integer primary key as the
path parameter. The presentation router converts it into a `GetTierQuery(id=tier_id)` and
delegates to `GetTierUseCase`. The use-case calls its port; if the adapter returns `None`, the
use-case raises `NotFoundDomainError("Tier not found")`, which the global exception handler
converts to HTTP 404. If the row is found, the use-case returns a `TierItem`; the router
converts it to `GetTierResponse` (identical shape to before) and returns HTTP 200.

The change is entirely internal to the three files listed above. The `GetTierPort` protocol
signature (`async def get(self, query: GetTierQuery) -> TierItem | None`) is unchanged — the
port carries `GetTierQuery`, which now holds `id: int` instead of `name: str`. All other
layers (use-case, schemas, DI wiring, router aggregator, bootstrap wiring) remain untouched.

## 3. API contract

**Request body:** none (GET endpoint).

**Path parameters:**

| Param | Type | Validation |
|---|---|---|
| `tier_id` | `int` | required; FastAPI validates automatically and returns 422 for non-integer values (user story 5 in PRD) |

**Response body** (`GetTierResponse` — unchanged from 0035):

| Field | Type |
|---|---|
| `id` | `int` |
| `name` | `str` |
| `created_at` | `datetime` |

**Status codes:**

- `200 OK` — tier found; response body matches `GetTierResponse`.
- `404 Not Found` — no tier with that id; `NotFoundDomainError("Tier not found")` translated by
  the global `DomainError` handler to `{"error": {"code": "notfound", "message": "Tier not found"}}`.
- `422 Unprocessable Entity` — non-integer path param; returned automatically by FastAPI/Pydantic.
- `500 Internal Server Error` — unexpected infrastructure failure; global catch-all handler.

## 4. File structure

No new files are created in `src/`. Three existing `get_tier/` files are modified:

```
src/app/features/tiers/get_tier/
├── domain/
│   └── commands.py          ← MODIFIED: name: str → id: int
├── data/
│   └── adapter.py           ← MODIFIED: Tier.name == query.name → Tier.id == query.id
└── presentation/
    └── router.py            ← MODIFIED: path /tier/{name} → /tier/{tier_id}; param type change
```

All other files under `get_tier/` are untouched:

```
get_tier/domain/ports/get_tier_port.py   — unchanged (port contract carries GetTierQuery)
get_tier/domain/use_case.py              — unchanged
get_tier/presentation/schemas.py         — unchanged (response shape identical)
```

New test files (acceptance gate):

```
tests/features/tiers/0038_get_tier_by_id/
├── __init__.py
├── conftest.py                              # same savepoint-fixture pattern as 0035
└── get_tier_by_id_outside_in_test.py        # acceptance gate for this slice
```

Existing test files that must be updated to match the new behavior (per the
"Modifying an existing slice" workflow in CLAUDE.md):

```
tests/features/tiers/0035_get_tier/domain/test_use_case.py
tests/features/tiers/0035_get_tier/data/test_adapter.py
tests/features/tiers/0035_get_tier/presentation/test_router.py
tests/features/tiers/0035_get_tier/get_tier_outside_in_test.py
```

## 5. Implementation steps

Per CLAUDE.md § Modifying an existing slice: update tests first (go RED), then implement (go
GREEN), then update remaining unit tests.

### Step 1 — Create new outside-in test (RED gate)

**File:** `tests/features/tiers/0038_get_tier_by_id/conftest.py`

Copy the savepoint-fixture pattern from
`tests/features/tiers/0035_get_tier/conftest.py` verbatim. The `async_client`
fixture is identical; only the module header changes.

**File:** `tests/features/tiers/0038_get_tier_by_id/get_tier_by_id_outside_in_test.py`

Two scenarios:

1. **Happy path** — seed a tier row, capture its `id` via `INSERT ... RETURNING id` (or a
   subsequent `SELECT id FROM "tier" WHERE name = :name`), call `GET /api/v1/tier/{id}`,
   assert HTTP 200 and that `body["id"]`, `body["name"]`, and `body["created_at"]` are
   present and correct.
2. **Not-found** — call `GET /api/v1/tier/999999`, assert HTTP 404 with
   `{"error": {"code": "notfound", "message": "Tier not found"}}`.

Run this test **before** making any source changes; it must be RED because the current router
still serves `/tier/{name}` — a request like `GET /tier/1` would match a name of `"1"` rather
than resolving by integer id, so the happy path assertion on `body["id"]` will fail unless a
tier named `"1"` coincidentally exists.

### Step 2 — Domain: Update `GetTierQuery`

**File:** `src/app/features/tiers/get_tier/domain/commands.py`

Change the single field from `name: str` to `id: int`:

```python
# FEATURE: get_tier — domain query.
from pydantic import BaseModel


class GetTierQuery(BaseModel):
    id: int
```

No validation constraints — the path parameter is already validated as `int` by FastAPI before
the command is constructed. No framework imports (`domain/` imports only stdlib and pydantic per
CLAUDE.md rule 2).

### Step 3 — Data: Update adapter query predicate

**File:** `src/app/features/tiers/get_tier/data/adapter.py`

Change the single `WHERE` clause from `Tier.name == query.name` to `Tier.id == query.id`:

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
                select(Tier).where(Tier.id == query.id)
            )
            row = result.scalar_one_or_none()
            if row is None:
                return None
            return TierItem.model_validate(row)
```

No `try/except` — this is a read-only query with no business-meaningful exception to translate
(per `agent_docs/error_handling.md` § Right shape: read-only query, no catch). All five
relative import paths are unchanged.

### Step 4 — Presentation: Update router path and parameter

**File:** `src/app/features/tiers/get_tier/presentation/router.py`

Three changes: route path, path-parameter name and type, `GetTierQuery` construction:

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
    "/tier/{tier_id}",
    response_model=GetTierResponse,
    status_code=status.HTTP_200_OK,
)
@inject
async def get_tier_endpoint(
    tier_id: int,
    use_case: Annotated[
        GetTierUseCase,
        Depends(Provide[Container.get_tier_use_case]),
    ],
) -> GetTierResponse:
    query = GetTierQuery(id=tier_id)
    tier_item = await use_case(query)
    return GetTierResponse.model_validate(tier_item)
```

`tier_id` is used as the parameter name (not `id`) to avoid shadowing the Python built-in.
FastAPI declares it as `int`; non-integer path segments automatically produce 422 without any
use-case involvement (user story 5 in PRD). All five relative import paths are unchanged.

### Step 5 — Verify implementation is GREEN

Run the new outside-in test:

```
pytest tests/features/tiers/0038_get_tier_by_id/get_tier_by_id_outside_in_test.py -v
```

It must pass before proceeding.

### Step 6 — Update existing 0035 tests

With the implementation green, update the existing 0035 tests to replace all `name`-based
references with `id`-based ones. These tests must also pass after the update.

**`tests/features/tiers/0035_get_tier/domain/test_use_case.py`**

- `_QUERY = GetTierQuery(name="gold")` → `_QUERY = GetTierQuery(id=1)`
- No other changes; test logic is identical.

**`tests/features/tiers/0035_get_tier/data/test_adapter.py`**

- `GetTierQuery(name=_TIER_NAME)` → `GetTierQuery(id=42)` (both call sites).
- The `_TIER_NAME` constant and the `row.name` assertion remain — they test the mapped
  `TierItem` field value, not the query input.

**`tests/features/tiers/0035_get_tier/presentation/test_router.py`**

- Seed the tier row, then capture its `id` with `SELECT id FROM "tier" WHERE name = :name`.
- Change endpoint calls from `GET /api/v1/tier/{_TIER_NAME}` to `GET /api/v1/tier/{row.id}`.
- 404 scenario: call `GET /api/v1/tier/999999` (non-existent integer id) instead of
  `GET /api/v1/tier/__nonexistent_name__`.

**`tests/features/tiers/0035_get_tier/get_tier_outside_in_test.py`**

Same changes as the router integration test: capture `id` after seeding, call
`GET /api/v1/tier/{id}`, update the 404 scenario to use a non-existent integer id.

### Step 7 — Full verification

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

The smoke test at `tests/smoke/test_app_starts.py` must pass. The slice is not done until all
of the above pass.

## 6. Tests planned

- **Use-case unit test** — `tests/features/tiers/0035_get_tier/domain/test_use_case.py`
  (updated in Step 6). Two branches: port returns `TierItem` → use-case returns it; port
  returns `None` → use-case raises `NotFoundDomainError`. Query uses `GetTierQuery(id=1)`.

- **Adapter unit test** — `tests/features/tiers/0035_get_tier/data/test_adapter.py`
  (updated in Step 6). Mocked session factory. Three cases: row found → mapped `TierItem`;
  row absent → `None`; infrastructure exception propagates unchanged. Query uses
  `GetTierQuery(id=42)`.

- **Endpoint integration test** — `tests/features/tiers/0035_get_tier/presentation/test_router.py`
  (updated in Step 6). `httpx.AsyncClient` against test Postgres. Seed tier, capture `id`,
  `GET /tier/{id}` → 200 with correct body; non-existent id → 404 with domain error body;
  unauthenticated → 200 (public endpoint).

- **Outside-in test** — `tests/features/tiers/0038_get_tier_by_id/get_tier_by_id_outside_in_test.py`
  (created in Step 1). Full HTTP stack with real adapter and test Postgres. Acceptance gate —
  the slice is not done until this test is green.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Adding authentication to the endpoint.
- Changing the response schema.
- Caching.
- URL normalisation from singular `/tier/{id}` to plural `/tiers/{id}`.
- Any change to `update_tier` (0036) or `delete_tier` (0037) — those still use their own
  path-param conventions.
- Lookup by name — the name-based endpoint is replaced by this slice.

## 8. Open questions

None. The PRD resolves all decisions: `id`-based path param, no auth, response shape unchanged,
`GetTierPort` contract unchanged, no new `DomainError` subclasses needed.
