# 0034 · list_tiers — Implementation plan

## 1. Header

- **Feature:** tiers
- **Slice:** 0034_list_tiers
- **PRD:** ./prd.md
- **Reference slice:** `../../posts/0009_list_posts/plan.md` — same operation shape (paginated GET, Query → port → Page entity, COUNT + SELECT, no auth).
- **HTTP path:** `GET /api/v1/tiers`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `list_tiers_adapter` and `list_tiers_use_case` providers; add router module to `wiring_config`.
- **Prerequisite:** Slice 0033 (`create_tier`) must be complete before implementing this slice. Slice 0033 creates `tiers/_shared/entities.py` (with `TierItem` and `TierPage`) and converts `features/tiers/router.py` to an aggregator.

## 2. Context summary

A client sends `GET /api/v1/tiers` with optional `page` and `items_per_page` query
parameters. The presentation router converts the query parameters into a
`ListTiersQuery`, delegates to `ListTiersUseCase`, and returns a
`ListTiersResponse` containing a page of tier items with pagination metadata.
Each item includes the tier's `id`, `name`, and `created_at`. The adapter issues
two explicit SQLAlchemy statements — `COUNT(*)` for the total and
`SELECT … ORDER BY id LIMIT/OFFSET` for the page — with no FastCRUD dependency.
An empty or missing tier table returns HTTP 200 with an empty `items` list; no
`DomainError` is raised. The endpoint is public (no auth). This slice replaces
the `read_tiers` handler in `features/tiers/router.py` and aligns the response
shape (`items`, `total_count`, `page`, `items_per_page`) with the project-standard
pagination contract used by `list_posts` and `list_users`.

## 3. API contract

**Request body:** none (GET endpoint).

**Query parameters:**

| Param | Type | Default | Validation |
|---|---|---|---|
| `page` | `int` | `1` | `ge=1` |
| `items_per_page` | `int` | `10` | `ge=1`, `le=100` |

**Response body** (`ListTiersResponse`):

| Field | Type |
|---|---|
| `items` | `list[TierItemSchema]` |
| `total_count` | `int` |
| `page` | `int` |
| `items_per_page` | `int` |

Each `TierItemSchema`:

| Field | Type | Source |
|---|---|---|
| `id` | `int` | `tier.id` |
| `name` | `str` | `tier.name` |
| `created_at` | `datetime` | `tier.created_at` |

**Status codes:**

- `200 OK` — paginated response returned; `items` is empty when no tiers exist.
- `422 Unprocessable Entity` — FastAPI/Pydantic rejects invalid query params (e.g. `page=0`).
- `500` — unexpected infrastructure failure; logged by global `_catch_all` handler.

No `DomainError` subclass is raised by this use case.

## 4. File structure

New files:

```
src/app/features/tiers/list_tiers/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                    # ListTiersQuery
│   ├── ports/
│   │   ├── __init__.py
│   │   └── list_tiers_port.py         # ListTiersPort (Protocol)
│   └── use_case.py                    # ListTiersUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                     # ListTiersAdapter(ListTiersPort)
└── presentation/
    ├── __init__.py
    ├── router.py                      # GET /tiers
    └── schemas.py                     # TierItemSchema, ListTiersResponse
```

No new ORM model. No Alembic migration. `adapters/db/models/tier.py` (`Tier`) is
used as-is by the adapter.

Files modified:

```
src/app/features/tiers/router.py   # remove read_tiers handler; include list_tiers sub-router
src/app/bootstrap/container.py     # add list_tiers_adapter, list_tiers_use_case providers
.importlinter                      # add ignore_imports entry for list_tiers router (if needed)
```

`bootstrap/router.py` is **not touched** — it already registers `tiers_router`
from `features/tiers/router.py`.

`tiers/_shared/entities.py` (`TierItem`, `TierPage`) is created by slice 0033 and
imported here; it must not be redefined locally.

## 5. Implementation steps

### Step 1 — Domain: Query

**File:** `src/app/features/tiers/list_tiers/domain/commands.py`

Define `ListTiersQuery` as a Pydantic `BaseModel`:

```python
class ListTiersQuery(BaseModel):
    page: int = 1
    items_per_page: int = 10
```

No validation constraints here; constraints (`ge=1`, `le=100`) live in the
presentation layer. The domain query assumes valid input.

File header: `# FEATURE: list_tiers — domain query.`

### Step 2 — Domain: Port

**File:** `src/app/features/tiers/list_tiers/domain/ports/list_tiers_port.py`

Define `ListTiersPort` as a `@runtime_checkable` `Protocol` with one method:

```python
@runtime_checkable
class ListTiersPort(Protocol):
    async def list(self, query: ListTiersQuery) -> TierPage: ...
```

`@runtime_checkable` is mandatory (per `agent_docs/architecture.md` §
Terminology: port and adapter). One method per port. Import `TierPage` from
`...._shared.entities` (relative import, four dots up: ports → domain → list_tiers → tiers).

File header: `# FEATURE: list_tiers — port protocol.`

### Step 3 — Domain: Use case

**File:** `src/app/features/tiers/list_tiers/domain/use_case.py`

Define `ListTiersUseCase`:

```python
class ListTiersUseCase:
    def __init__(self, port: ListTiersPort) -> None:
        self._port = port

    async def __call__(self, query: ListTiersQuery) -> TierPage:
        return await self._port.list(query)
```

No conditional logic, no `DomainError` raised, no `try/except`. The delegation
wrapper preserves the DI-testable boundary between presentation and data.

File header: `# FEATURE: list_tiers — use case.`

### Step 4 — Data: Adapter

**File:** `src/app/features/tiers/list_tiers/data/adapter.py`

Define `ListTiersAdapter(ListTiersPort)` — explicit inheritance is mandatory
(per `agent_docs/architecture.md` § Terminology: port and adapter).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`async def list(self, query: ListTiersQuery) -> TierPage`:

1. Open a single async session via `async with self._session_factory() as session`.
2. **Count query** — `select(func.count()).select_from(Tier)`. Fetch with `scalar_one()`.
3. Compute offset: `(query.page - 1) * query.items_per_page`.
4. **Row query** — `select(Tier).order_by(Tier.id).offset(offset).limit(query.items_per_page)`.
   Fetch with `scalars().all()`.
5. Map each ORM row to `TierItem(id=row.id, name=row.name, created_at=row.created_at)`.
6. Return `TierPage(items=items, total_count=total_count, page=query.page, items_per_page=query.items_per_page)`.

No `try/except` — this is a read-only query with no business-meaningful exception
path (per `agent_docs/error_handling.md` § Right shape: read-only query, no catch).
Infrastructure failures propagate to the global `_catch_all` handler.

Import `Tier` from `....adapters.db.models.tier`. Import `TierItem`, `TierPage`
from `..._shared.entities` (three dots: data → list_tiers → tiers). All imports
use relative paths (per `agent_docs/architecture.md` § Import conventions).

File header: `# FEATURE: list_tiers — data adapter.`

### Step 5 — Presentation: Schemas

**File:** `src/app/features/tiers/list_tiers/presentation/schemas.py`

Define two Pydantic models with `model_config = ConfigDict(from_attributes=True)`:

```python
class TierItemSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    created_at: datetime

class ListTiersResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    items: list[TierItemSchema]
    total_count: int
    page: int
    items_per_page: int
```

`TierItemSchema` mirrors the domain `TierItem` but lives in the presentation layer
as the HTTP contract. `from_attributes=True` enables `model_validate` from domain
entity instances.

File header: `# FEATURE: list_tiers — request/response schemas.`

### Step 6 — Presentation: Router

**File:** `src/app/features/tiers/list_tiers/presentation/router.py`

Define `router = APIRouter(tags=["tiers"])`.

Endpoint `GET /tiers`:

```python
@router.get("/tiers", response_model=ListTiersResponse, status_code=status.HTTP_200_OK)
@inject
async def list_tiers_endpoint(
    page: int = Query(default=1, ge=1),
    items_per_page: int = Query(default=10, ge=1, le=100),
    use_case: Annotated[
        ListTiersUseCase,
        Depends(Provide[Container.list_tiers_use_case]),
    ] = ...,
) -> ListTiersResponse:
    query = ListTiersQuery(page=page, items_per_page=items_per_page)
    result = await use_case(query)
    return ListTiersResponse(
        items=[TierItemSchema.model_validate(item) for item in result.items],
        total_count=result.total_count,
        page=result.page,
        items_per_page=result.items_per_page,
    )
```

No `request: Request` parameter (no `@cache` decorator on this slice). No auth
dependency. All imports use relative paths.

File header: `# FEATURE: list_tiers — HTTP router.`

### Step 7 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — approved for modification)

Add two imports at the top of the file:

```python
from ..features.tiers.list_tiers.data.adapter import ListTiersAdapter
from ..features.tiers.list_tiers.domain.use_case import ListTiersUseCase
```

Add two new providers inside `Container`:

```python
list_tiers_adapter = providers.Factory(
    ListTiersAdapter,
    session_factory=session_factory,
)

list_tiers_use_case = providers.Factory(
    ListTiersUseCase,
    port=list_tiers_adapter,
)
```

Add the router module to `wiring_config.modules`:

```python
f"{_app_pkg}.features.tiers.list_tiers.presentation.router",
```

### Step 8 — Convert `features/tiers/router.py` to aggregator

**File:** `src/app/features/tiers/router.py` (FEATURE file)

**Prerequisite:** Step 8 of slice 0033 must already have run, removing `write_tier`
and adding the `create_tier` sub-router. If 0033 is not yet done, complete it first.

Remove the `read_tiers` handler and any FastCRUD imports that are no longer used
after the removal (`compute_offset`, `paginated_response`, `PaginatedListResponse`,
`async_get_db` — check each against remaining handlers before removing).

Add alongside the other sub-router imports:

```python
from .list_tiers.presentation.router import router as list_tiers_router
```

Add the include after existing sub-router includes:

```python
router.include_router(list_tiers_router)
```

The remaining handlers (`read_tier`, `patch_tier`, `erase_tier`) stay in place
until slices 0035–0037 are complete.

### Step 9 — `.importlinter` update

**File:** `.importlinter`

The `vsa-feature-independence` contract currently covers only `app.features.users`
and `app.features.posts`. The `tiers` feature is excluded, so the
`list_tiers.presentation.router → bootstrap.container` import does not violate
the current contract.

No change to `.importlinter` is required for this slice. If `tiers` is later
added to the independence contract, add:

```
app.features.tiers.list_tiers.presentation.router -> app.bootstrap.container
```

to the `ignore_imports` list under `[importlinter:contract:vsa-feature-independence]`.

### Step 10 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/tiers/0034_list_tiers/list_tiers_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test at
`tests/smoke/test_app_starts.py`.

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/tiers/0034_list_tiers/domain/test_use_case.py`.
  Construct `ListTiersUseCase` with a mock `ListTiersPort` (pytest-mock). Call
  `__call__` with `ListTiersQuery(page=1, items_per_page=10)`. Assert that the
  use-case returns exactly what `port.list()` returns, unchanged. One happy-path
  test is sufficient — there are no branches or `DomainError` paths.
  Prior art: `tests/features/posts/0009_list_posts/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/tiers/0034_list_tiers/data/test_adapter.py`.
  Run against test Postgres (real database, no mocks for the session).
  - Happy path: seed two tiers, call `ListTiersAdapter.list(page=1, items_per_page=10)`;
    assert `total_count=2` and `items` contains both tiers with correct `id`, `name`,
    `created_at`.
  - Pagination: seed three tiers, call with `page=1, items_per_page=2`; assert
    `total_count=3`, `len(items)==2`. Call with `page=2`; assert `len(items)==1`.
  - Empty table: call with no seeded tiers; assert `total_count=0`, `items==[]`.
  - No catch path to assert — the adapter has no `try/except`.
  Prior art: `tests/features/posts/0009_list_posts/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/tiers/0034_list_tiers/presentation/test_router.py`.
  Use `httpx.AsyncClient` against the running app with test Postgres.
  - Assert HTTP 200 and correct `ListTiersResponse` JSON shape (`items`,
    `total_count`, `page`, `items_per_page`) for a database with seeded tiers.
  - Assert HTTP 200 with `items=[]` and `total_count=0` when no tiers exist.
  - Assert correct truncation when `items_per_page` is smaller than the total
    tier count.
  - Assert no authentication is required (unauthenticated request returns 200).
  - Assert HTTP 422 for `page=0` (Pydantic `ge=1` fails).
  Prior art: `tests/features/posts/0009_list_posts/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/tiers/0034_list_tiers/list_tiers_outside_in_test.py`.
  Full HTTP stack with real adapter, test Postgres, no mocks. Covers the happy
  path: seed two tiers, call `GET /api/v1/tiers`, assert HTTP 200 and that the
  response body matches the expected pagination shape with `total_count=2` and
  both tiers in `items`. This is the acceptance gate; the slice is not done until
  this test is green.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Migrating `create_tier`, `get_tier`, `update_tier`, or `delete_tier` (slices
  0033, 0035–0037).
- Filtering or sorting by name.
- Cursor-based pagination.
- Adding authentication or authorisation checks to `GET /tiers`.
- Exposing `updated_at` — the `TierItem` entity does not include it.
- Removing `tiers/schemas.py` or `tiers/repository.py` — still referenced by
  `rate_limits/` and `users/` features.
- Caching the response.

## 8. Open questions

- **Dependency on slice 0033**: `tiers/_shared/entities.py` (`TierItem`,
  `TierPage`) is created by slice 0033. If 0033 is planned but not yet
  implemented when 0034 starts, `_shared/entities.py` must be created as part of
  0033 before any 0034 code is written. Confirm 0033 is complete before starting
  implementation.
