# 0041 · get_user_by_id — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0041_get_user_by_id
- **PRD:** ./prd.md
- **Reference slice:** `../0004_get_user_by_username/plan.md` — same read-only
  single-entity query shape; this slice is a direct rename of 0004.
- **HTTP path:** `GET /api/v1/user/{user_id}`
- **STABLE files touched:**
  - `bootstrap/container.py` — replace `get_user_by_username_*` providers with
    `get_user_by_id_*`; update `wiring_config.modules`.
  - `.importlinter` — replace `get_user_by_username.presentation.router` entry
    with `get_user_by_id.presentation.router`.

## 2. Context summary

This slice retires the `get_user_by_username` slice (0004) and replaces it with
`get_user_by_id`. A client sends `GET /api/v1/user/{user_id}` where `user_id` is
the integer primary key of `User`. The presentation router converts the path
parameter to a `GetUserByIdQuery`, passes it to `GetUserByIdUseCase`, and returns
a `GetUserByIdResponse` with seven user fields. The adapter runs one SQLAlchemy
`SELECT` filtered to `User.id == query.user_id AND is_deleted = false`. If no row
is found the use case raises `NotFoundDomainError`, which the global exception
handler converts to HTTP 404. The endpoint is public (no auth). The old
`GET /user/{username}` route is removed without a redirect; the breaking change
is intentional.

## 3. API contract

**Request body:** none (GET endpoint).

**Path parameters:**

| Param | Type | Validation |
|---|---|---|
| `user_id` | `int` | required; FastAPI coerces path string to `int`; non-integer → 422 |

**Response body** (`GetUserByIdResponse`):

| Field | Type |
|---|---|
| `id` | `int` |
| `name` | `str` |
| `username` | `str` |
| `email` | `str` |
| `profile_image_url` | `str` |
| `tier_id` | `int \| None` |
| `is_moderator` | `bool` |

**Status codes:**

- `200 OK` — user found and returned.
- `404 Not Found` — no active (non-deleted) user with that `user_id`; raised as
  `NotFoundDomainError("User not found")`, translated by the global
  `DomainError` handler.
- `422 Unprocessable Entity` — non-integer path value; handled automatically by
  FastAPI's Pydantic coercion.
- `500 Internal Server Error` — unexpected infrastructure failure; logged and
  returned by the global `_catch_all` handler.

## 4. File structure

New files (created):

```
src/app/features/users/get_user_by_id/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                     # GetUserByIdQuery
│   ├── entities.py                     # FoundUser
│   ├── ports/
│   │   ├── __init__.py
│   │   └── get_user_by_id_port.py      # GetUserByIdPort (Protocol)
│   └── use_case.py                     # GetUserByIdUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                      # GetUserByIdAdapter
└── presentation/
    ├── __init__.py
    ├── router.py                       # GET /user/{user_id}
    └── schemas.py                      # GetUserByIdResponse
```

No new ORM model. No Alembic migration. `adapters/db/models/user.py` (`User`)
is used as-is.

Existing files modified:

```
src/app/bootstrap/container.py          # replace get_user_by_username_* providers
src/app/features/users/router.py        # swap import alias
.importlinter                           # swap router ignore_imports entry
```

Deleted:

```
src/app/features/users/get_user_by_username/  (entire folder)
```

## 5. Implementation steps

### Step 1 — Domain: Query

**File:** `src/app/features/users/get_user_by_id/domain/commands.py`

Define `GetUserByIdQuery` as a Pydantic `BaseModel`:

- `user_id: int`

No validation constraints — FastAPI coerces the path parameter before the query
is constructed; the domain command assumes a valid integer.

File header: `# FEATURE: get_user_by_id — domain query.`

### Step 2 — Domain: Entity

**File:** `src/app/features/users/get_user_by_id/domain/entities.py`

Define `FoundUser` as a Pydantic `BaseModel` with seven fields:

- `id: int`
- `name: str`
- `username: str`
- `email: str`
- `profile_image_url: str`
- `tier_id: int | None`
- `is_moderator: bool`

`domain/` imports only stdlib and pydantic — no SQLAlchemy, no FastAPI.

File header: `# FEATURE: get_user_by_id — domain entity.`

### Step 3 — Domain: Port

**File:**
`src/app/features/users/get_user_by_id/domain/ports/get_user_by_id_port.py`

Define `GetUserByIdPort` as a `@runtime_checkable` `Protocol` with one method:

```
async def get(self, query: GetUserByIdQuery) -> FoundUser | None: ...
```

`@runtime_checkable` is mandatory (per `agent_docs/architecture.md` §
Terminology: port and adapter). The `None` return signals "not found"; the use
case decides what to do with it.

Relative imports to `../commands.py` and `../entities.py`.

File header: `# FEATURE: get_user_by_id — port protocol.`

### Step 4 — Domain: Use case

**File:** `src/app/features/users/get_user_by_id/domain/use_case.py`

Define `GetUserByIdUseCase`:

- `__init__(self, port: GetUserByIdPort) -> None` — stores port.
- `async __call__(self, query: GetUserByIdQuery) -> FoundUser`:
  - Calls `result = await self._port.get(query)`.
  - If `result is None`: raises `NotFoundDomainError("User not found")`.
  - Returns `result`.

No other branches. No `try/except`. Raise happens in the use case, not the
adapter, per `agent_docs/error_handling.md` § Use-case: raises, does not catch.

Import `NotFoundDomainError` via `from .....domain.errors import NotFoundDomainError`
(5 dots: `domain/` → `get_user_by_id/` → `users/` → `features/` → `app/`).

File header: `# FEATURE: get_user_by_id — use case.`

### Step 5 — Data: Adapter

**File:** `src/app/features/users/get_user_by_id/data/adapter.py`

Define `GetUserByIdAdapter(GetUserByIdPort)` — explicit inheritance from the
port is mandatory (per `agent_docs/architecture.md`).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`async def get(self, query: GetUserByIdQuery) -> FoundUser | None`:

1. Open session via `async with self._session_factory() as session`.
2. Execute:
   `select(User).where(User.id == query.user_id, User.is_deleted == False)`
   using `scalar_one_or_none()`.
3. If `None`, return `None` — the use case handles the missing-entity semantic.
4. Map ORM row to `FoundUser(id=..., name=..., username=..., email=...,
   profile_image_url=..., tier_id=..., is_moderator=...)`.
5. Return `FoundUser`.

No `try/except` — read-only query has no business-meaningful exception to
translate (per `agent_docs/error_handling.md` § Right shape: read-only query,
no catch).

Import `User` from `.....adapters.db.models.user` (5 dots).

File header: `# FEATURE: get_user_by_id — data adapter.`

### Step 6 — Presentation: Schemas

**File:** `src/app/features/users/get_user_by_id/presentation/schemas.py`

Define `GetUserByIdResponse` as a Pydantic `BaseModel` with
`model_config = ConfigDict(from_attributes=True)`:

- `id: int`
- `name: str`
- `username: str`
- `email: str`
- `profile_image_url: str`
- `tier_id: int | None`
- `is_moderator: bool`

No request schema — the only input is a path parameter, handled directly in the
router.

File header: `# FEATURE: get_user_by_id — request/response schemas.`

### Step 7 — Presentation: Router

**File:** `src/app/features/users/get_user_by_id/presentation/router.py`

Define `router = APIRouter()`.

Endpoint `GET /user/{user_id}`:

- Path param: `user_id: int`.
- Dependency: `use_case: Annotated[GetUserByIdUseCase, Depends(Provide[Container.get_user_by_id_use_case])]`.
- Body: construct `GetUserByIdQuery(user_id=user_id)`, await `use_case(query)`,
  return `GetUserByIdResponse(id=entity.id, name=entity.name, ...)`.
- `response_model=GetUserByIdResponse`, `status_code=200`.
- Decorated with `@inject`.
- No auth dependency (public endpoint, per PRD).

Import `Container` from `.....bootstrap.container` (5 dots from
`presentation/` → `get_user_by_id/` → `users/` → `features/` → `app/`).

All imports are **relative** per `agent_docs/architecture.md` § Import
conventions.

File header: `# FEATURE: get_user_by_id — HTTP router.`

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — permitted modification)

Replace the import lines:

```python
from ..features.users.get_user_by_username.data.adapter import GetUserByUsernameAdapter
from ..features.users.get_user_by_username.domain.use_case import GetUserByUsernameUseCase
```

with:

```python
from ..features.users.get_user_by_id.data.adapter import GetUserByIdAdapter
from ..features.users.get_user_by_id.domain.use_case import GetUserByIdUseCase
```

Replace providers:

```python
get_user_by_id_adapter = providers.Factory(
    GetUserByIdAdapter,
    session_factory=session_factory,
)

get_user_by_id_use_case = providers.Factory(
    GetUserByIdUseCase,
    port=get_user_by_id_adapter,
)
```

In `wiring_config.modules`, replace:

```python
f"{_app_pkg}.features.users.get_user_by_username.presentation.router",
```

with:

```python
f"{_app_pkg}.features.users.get_user_by_id.presentation.router",
```

### Step 9 — Update `features/users/router.py`

Replace:

```python
from .get_user_by_username.presentation.router import router as get_user_by_username_router
...
router.include_router(get_user_by_username_router)
```

with:

```python
from .get_user_by_id.presentation.router import router as get_user_by_id_router
...
router.include_router(get_user_by_id_router)
```

`bootstrap/router.py` is **not touched** — it already aggregates
`features/users/router.py` and the chain is unchanged.

### Step 10 — Update `.importlinter`

In the `[importlinter:contract:vsa-feature-independence]` section, replace:

```
app.features.users.get_user_by_username.presentation.router -> app.bootstrap.container
```

with:

```
app.features.users.get_user_by_id.presentation.router -> app.bootstrap.container
```

### Step 11 — Delete old slice

Delete the entire `src/app/features/users/get_user_by_username/` folder and all
files within it.

Verify no remaining imports of any `get_user_by_username` symbol survive in
`src/`: a grep for `get_user_by_username` should return zero results after
deletion.

### Step 12 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/users/0041_get_user_by_id/get_user_by_id_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/users/0041_get_user_by_id/domain/test_use_case.py`.
  Construct `GetUserByIdUseCase` with a mock `GetUserByIdPort`. Assert:
  - When port returns a `FoundUser`, the use case returns it unchanged.
  - When port returns `None`, the use case raises `NotFoundDomainError`.
  Two branches, no other paths.
  Prior art: `tests/features/users/0004_get_user_by_username/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/users/0041_get_user_by_id/data/test_adapter.py`.
  Real async session against test Postgres. Assert:
  - Returns a correctly-constructed `FoundUser` when a matching non-deleted row
    exists with the given `id`.
  - Returns `None` when no user with that `id` exists.
  - Returns `None` when the user exists but `is_deleted=True`.
  No catch path to assert — the adapter has no `try/except`.
  Prior art: `tests/features/users/0004_get_user_by_username/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/users/0041_get_user_by_id/presentation/test_router.py`.
  Use `httpx.AsyncClient` against the full app with test Postgres. Assert:
  - `GET /user/{id}` for an existing active user → `200`, response body matches
    all seven fields of `GetUserByIdResponse`.
  - `GET /user/{id}` for a non-existent `id` → `404`.
  - `GET /user/not-an-int` → `422`.
  Prior art: `tests/features/users/0004_get_user_by_username/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/users/0041_get_user_by_id/get_user_by_id_outside_in_test.py`.
  Full HTTP stack with real adapter, test Postgres. No mocks. Steps:
  1. Create a user via `POST /users/`; capture `id`.
  2. Call `GET /user/{id}` — assert `200` and all seven response fields correct.
  3. Call `GET /user/{username}` (old route, string value) — assert `422` (FastAPI
     cannot coerce a string to `int`).
  This is the acceptance gate — the slice is not done until this test is green.

**Opt-outs:** none.

## 7. Out of scope for this slice

- All other users routes (`update_user`, `delete_user`, `delete_db_user`,
  `assign_moderator`, `revoke_moderator`, `get_user_tier`) — each covered by
  slices 0043–0050.
- `list_posts` route migration — covered by slice 0042.
- Username-based lookup for internal post author resolution (`UserLookupPort`)
  inside the posts feature.
- Caching (`@cache` decorator) — not present on the current endpoint, not added
  here.
- Updating the existing outside-in test for slice 0004 — noted in the PRD
  Further Notes; that test is in the 0004 test folder and is updated separately
  after this slice lands.

## 8. Open questions

None — all decisions resolved in the PRD.
