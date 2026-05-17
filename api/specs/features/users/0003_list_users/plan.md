# 0003 · list_users — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0003_list_users
- **PRD:** ./prd.md
- **Reference slice (if any):** `../0001_create_user/plan.md` — closest structural
  match (same domain/data/presentation layout); operation shape differs (query vs command).
- **HTTP path:** `GET /api/v1/users`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `wiring_config`, `list_users_adapter`, and
    `list_users_use_case` providers; approved in grill-me session.

## 2. Context summary

This slice replaces the non-conforming free function `use_cases/user_list.py` with
a fully hexagonal `list_users` slice. A client sends `GET /api/v1/users` with
optional `page` and `items_per_page` query parameters. The presentation router
converts them to a `ListUsersQuery`, passes it to `ListUsersUseCase`, and returns
a flat `ListUsersResponse` containing the page of users and pagination metadata.
The adapter runs two SQLAlchemy ORM queries against the `User` model — one for the
total count, one for the paginated rows — both filtered to `is_deleted=False`. Soft-
deleted users are never visible from this endpoint. The external HTTP contract
(`GET /users`, parameters, field names) is unchanged.

## 3. API contract

**Request body:** none (GET endpoint).

**Query parameters:**

| Param | Type | Default | Validation |
|---|---|---|---|
| `page` | `int` | `1` | `ge=1` |
| `items_per_page` | `int` | `10` | `ge=1`, `le=100` |

**Response body** (`ListUsersResponse`):

| Field | Type |
|---|---|
| `items` | `list[ListedUserSchema]` |
| `total_count` | `int` |
| `page` | `int` |
| `items_per_page` | `int` |

Each `ListedUserSchema` item:

| Field | Type |
|---|---|
| `id` | `int` |
| `name` | `str` |
| `username` | `str` |
| `email` | `str` |
| `profile_image_url` | `str` |
| `tier_id` | `int \| None` |

**Status codes:**

- `200 OK` — page returned (may be empty if `page` exceeds total results).
- `422 Unprocessable Entity` — FastAPI/Pydantic rejects invalid query params
  (e.g. `page=0`).
- `500` — unexpected adapter failure; logged by global `_catch_all` handler.

No `DomainError` subclass is raised by this use case — listing users has no
business-validation branch.

## 4. File structure

New files:

```
src/app/features/users/list_users/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py              # ListUsersQuery
│   ├── entities.py              # ListedUser, UserPage
│   ├── ports/
│   │   ├── __init__.py
│   │   └── list_users_port.py   # ListUsersPort (Protocol)
│   └── use_case.py              # ListUsersUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py               # ListUsersAdapter(ListUsersPort)
└── presentation/
    ├── __init__.py
    ├── router.py                 # GET /users
    └── schemas.py                # ListedUserSchema, ListUsersResponse
```

No new ORM model. No Alembic migration. `adapters/db/models/user.py` (`User`)
is used as-is.

Existing files modified:

```
src/app/bootstrap/container.py              # add wiring_config + list_users providers
src/app/features/users/router.py            # swap inline registration for include_router
```

Deleted:

```
src/app/features/users/use_cases/user_list.py
```

## 5. Implementation steps

### Step 1 — Domain: Query

**File:** `src/app/features/users/list_users/domain/commands.py`

Define `ListUsersQuery` as a Pydantic `BaseModel` with two fields:
- `page: int` — defaults to `1`
- `items_per_page: int` — defaults to `10`

No validation constraints here; the Pydantic constraints (`ge=1`, `le=100`) live
on the HTTP query params in the presentation layer. The domain command assumes
valid input.

File header: `# FEATURE: list_users — domain query.`

### Step 2 — Domain: Entities

**File:** `src/app/features/users/list_users/domain/entities.py`

Define two Pydantic `BaseModel` classes:

`ListedUser`:
- `id: int`
- `name: str`
- `username: str`
- `email: str`
- `profile_image_url: str`
- `tier_id: int | None`

`UserPage`:
- `items: list[ListedUser]`
- `total_count: int`
- `page: int`
- `items_per_page: int`

`domain/` imports only stdlib and pydantic — no SQLAlchemy, no FastAPI.

File header: `# FEATURE: list_users — domain entities.`

### Step 3 — Domain: Port

**File:** `src/app/features/users/list_users/domain/ports/list_users_port.py`

Define `ListUsersPort` as a `@runtime_checkable` `Protocol` with a single method:

```
async def list(self, query: ListUsersQuery) -> UserPage: ...
```

The `@runtime_checkable` decorator is mandatory (per architecture rules). One
method per port (per `agent_docs/architecture.md` § Terminology: port and adapter).

Imports: `typing.Protocol`, `typing.runtime_checkable`, relative imports to
`domain/commands.py` and `domain/entities.py`.

File header: `# FEATURE: list_users — port protocol.`

### Step 4 — Domain: Use case

**File:** `src/app/features/users/list_users/domain/use_case.py`

Define `ListUsersUseCase`:
- `__init__(self, port: ListUsersPort) -> None` — stores port.
- `async __call__(self, query: ListUsersQuery) -> UserPage` — delegates entirely
  to `self._port.list(query)` and returns the result.

This use case has no business logic to branch on (no validation, no authorization).
It is a thin delegation wrapper, which is intentional — it preserves the
testable boundary and DI contract. The adapter's behavior is tested in the
adapter unit test; the use case unit test verifies the call convention.

No `DomainError` is raised. No `try/except`.

File header: `# FEATURE: list_users — use case.`

### Step 5 — Data: Adapter

**File:** `src/app/features/users/list_users/data/adapter.py`

Define `ListUsersAdapter(ListUsersPort)` — explicit inheritance from the port
is mandatory (per `agent_docs/architecture.md` § Terminology: port and adapter).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`async def list(self, query: ListUsersQuery) -> UserPage`:

1. Open a single session via `async with self._session_factory() as session`.
2. First query — total count:
   `SELECT COUNT(*) FROM user WHERE is_deleted = false`
   Using `select(func.count()).select_from(User).where(User.is_deleted == False)`.
   Fetch with `scalar_one()`.
3. Compute offset: `(query.page - 1) * query.items_per_page`.
4. Second query — paginated rows:
   `SELECT * FROM user WHERE is_deleted = false OFFSET ? LIMIT ?`
   Using `select(User).where(User.is_deleted == False).offset(offset).limit(query.items_per_page)`.
   Fetch with `scalars().all()`.
5. Map ORM rows to `ListedUser` instances.
6. Return `UserPage(items=..., total_count=..., page=query.page, items_per_page=query.items_per_page)`.

No `try/except` — read-only queries have no business-meaningful exception path
(per `agent_docs/error_handling.md` § Right shape: read-only query, no catch).
Infrastructure failures propagate to the global `_catch_all` handler.

File header: `# FEATURE: list_users — data adapter.`

### Step 6 — Presentation: Schemas

**File:** `src/app/features/users/list_users/presentation/schemas.py`

Define two Pydantic models with `model_config = ConfigDict(from_attributes=True)`:

`ListedUserSchema`:
- `id: int`
- `name: str`
- `username: str`
- `email: str`
- `profile_image_url: str`
- `tier_id: int | None`

`ListUsersResponse`:
- `items: list[ListedUserSchema]`
- `total_count: int`
- `page: int`
- `items_per_page: int`

`from_attributes=True` is set so `model_validate(orm_instance)` works if needed.
The `ListedUserSchema` mirrors `ListedUser` from domain entities but lives in the
presentation layer as the HTTP contract type.

File header: `# FEATURE: list_users — request/response schemas.`

### Step 7 — Presentation: Router

**File:** `src/app/features/users/list_users/presentation/router.py`

Define `router = APIRouter()`.

Endpoint `GET /users`:
- Query params: `page: int = Query(default=1, ge=1)`,
  `items_per_page: int = Query(default=10, ge=1, le=100)`.
- Dependency: `use_case: Annotated[ListUsersUseCase, Depends(Provide[Container.list_users_use_case])]`.
- Body: construct `ListUsersQuery(page=page, items_per_page=items_per_page)`, await
  `use_case(query)`, convert `UserPage` entity to `ListUsersResponse`:
  `ListUsersResponse(items=[ListedUserSchema.model_validate(u) for u in result.items], ...)`.
- Response model: `ListUsersResponse`, status code: `200`.

The `Provide[Container.list_users_use_case]` pattern requires that this router
module be present in the container's `wiring_config.modules` (Step 8).

Imports use **relative paths** (`from ..domain.commands import ListUsersQuery`, etc.)
per `agent_docs/architecture.md` § Import conventions.

File header: `# FEATURE: list_users — HTTP router.`

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — approved for modification)

Add `wiring_config` to the `Container` class:

```python
wiring_config = containers.WiringConfiguration(
    modules=[
        "app.features.users.create_user.presentation.router",
        "app.features.users.list_users.presentation.router",
    ]
)
```

Add two new providers after `create_user_use_case`:

```python
list_users_adapter = providers.Factory(
    ListUsersAdapter,
    session_factory=session_factory,
)

list_users_use_case = providers.Factory(
    ListUsersUseCase,
    port=list_users_adapter,
)
```

Add the required imports at the top:
- `from ..features.users.list_users.data.adapter import ListUsersAdapter`
- `from ..features.users.list_users.domain.use_case import ListUsersUseCase`

Add `container.wire(modules=container.wiring_config.modules)` at module level,
after `container = Container()`. This executes on first import and registers
`Provide[...]` injection for all wired modules.

Note: adding `create_user.presentation.router` to `wiring_config` does not break
the existing `_get_create_user_use_case()` helper pattern — wiring that module
has no side effect on code that does not use `Provide[...]`.

### Step 9 — Update `features/users/router.py`

Remove:
```python
from .use_cases.user_list import read_users
router.get("/users", response_model=PaginatedListResponse[UserRead])(read_users)
```

Also remove `PaginatedListResponse` import from `fastcrud` if it is no longer
used by any other route in the file (check all remaining routes first).

Add:
```python
from .list_users.presentation.router import router as list_users_router
router.include_router(list_users_router)
```

`bootstrap/router.py` is **not touched** — it already aggregates
`features/users/router.py` and the chain is unchanged.

### Step 10 — Delete old use case

Delete `src/app/features/users/use_cases/user_list.py`.
Verify no other file imports from this module before deleting.

### Step 11 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/users/0003_list_users/list_users_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/users/0003_list_users/domain/test_use_case.py`.
  Construct `ListUsersUseCase` with a mock `ListUsersPort`. Assert that `__call__`
  returns exactly what `port.list()` returns. One happy-path test is sufficient;
  there are no branches or `DomainError` paths in this use case.
  Prior art: `tests/features/users/0001_create_user/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/users/0003_list_users/data/test_adapter.py`.
  Construct `ListUsersAdapter` with a mock `async_sessionmaker`. Seed the mock to
  return controllable data. Assert:
  - Returns the correct `UserPage` shape (items, total_count, page, items_per_page).
  - Soft-deleted rows are excluded (seed 3 active + 2 deleted rows, assert
    `total_count=3` and `items` contains only active rows).
  - Pagination is applied correctly (seed 15 rows, request `page=2 / items_per_page=5`,
    assert 5 items with correct offset).
  No catch path to assert — the adapter has no `try/except`.
  Prior art: `tests/features/users/0002_refactor_create_user_adapter/`.

- **Endpoint integration test** —
  `tests/features/users/0003_list_users/presentation/test_router.py`.
  Use `httpx.AsyncClient` against the full app with test Postgres. Assert:
  - `GET /users` → `200`, response matches `ListUsersResponse` schema.
  - `GET /users?page=2&items_per_page=5` → `200`, correct subset returned.
  - Soft-deleted users absent from response.
  - `GET /users?page=0` → `422` (Pydantic `ge=1` fails).
  Prior art: endpoint integration tests in `tests/features/users/0001_create_user/`.

- **Outside-in test** —
  `tests/features/users/0003_list_users/list_users_outside_in_test.py`.
  Full HTTP stack with real adapter, test Postgres. No mocks. This is the
  acceptance gate; the slice is not done until this test is green.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Caching the list endpoint (follow-up slice if needed).
- Filtering or search (separate use case).
- Sorting.
- Cursor-based pagination.
- Listing soft-deleted users (admin use case).
- Authentication / authorization on `GET /users` (left as-is from the existing
  endpoint).
- Migrating `create_user`'s router from the lazy-import helper to the
  `Provide[...]` pattern — consistent but not required for this slice to work.

## 8. Open questions

None — all decisions were resolved in the grill-me session preceding this plan.
The container modification was explicitly approved. The `Provide[...]` pattern
is used for the new slice; the `create_user` router's lazy-import helper is left
unchanged to avoid scope creep.
