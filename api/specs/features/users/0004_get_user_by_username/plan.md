# 0004 · get_user_by_username — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0004_get_user_by_username
- **PRD:** ./prd.md
- **Reference slice:** `../0003_list_users/plan.md` — same read-only query shape;
  differs in that it fetches a single entity by key rather than a paginated collection.
- **HTTP path:** `GET /api/v1/user/{username}`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `get_user_by_username_adapter` and
    `get_user_by_username_use_case` providers.

## 2. Context summary

This slice replaces the non-conforming flat free function
`use_cases/user_get_by_username.py` with a fully hexagonal
`get_user_by_username` slice. A client sends `GET /api/v1/user/{username}`.
The presentation router converts the path parameter to a
`GetUserByUsernameQuery`, passes it to `GetUserByUsernameUseCase`, and returns
a `GetUserByUsernameResponse` with six user fields. The adapter runs one
SQLAlchemy ORM `SELECT` filtered to `username = ? AND is_deleted = false`.
If no row is found the use case raises `NotFoundDomainError`, which the global
exception handler converts to HTTP 404. The endpoint is public (no auth). The
external HTTP contract (`GET /user/{username}`, path shape, response fields)
is unchanged.

## 3. API contract

**Request body:** none (GET endpoint).

**Path parameters:**

| Param | Type | Validation |
|---|---|---|
| `username` | `str` | required; provided in URL path |

**Response body** (`GetUserByUsernameResponse`):

| Field | Type |
|---|---|
| `id` | `int` |
| `name` | `str` |
| `username` | `str` |
| `email` | `str` |
| `profile_image_url` | `str` |
| `tier_id` | `int \| None` |

**Status codes:**

- `200 OK` — user found and returned.
- `404 Not Found` — no active (non-deleted) user with that username; raised as
  `NotFoundDomainError("User not found")`, translated by the global
  `DomainError` handler.
- `500 Internal Server Error` — unexpected adapter or infrastructure failure;
  logged and returned by the global `_catch_all` handler.

## 4. File structure

New files:

```
src/app/features/users/get_user_by_username/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                         # GetUserByUsernameQuery
│   ├── entities.py                         # FoundUser
│   ├── ports/
│   │   ├── __init__.py
│   │   └── get_user_by_username_port.py    # GetUserByUsernamePort (Protocol)
│   └── use_case.py                         # GetUserByUsernameUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                          # GetUserByUsernameAdapter
└── presentation/
    ├── __init__.py
    ├── router.py                           # GET /user/{username}
    └── schemas.py                          # GetUserByUsernameResponse
```

No new ORM model. No Alembic migration. `adapters/db/models/user.py` (`User`)
is used as-is.

Existing files modified:

```
src/app/bootstrap/container.py              # add two new providers
src/app/features/users/router.py           # swap direct registration for include_router
```

Deleted:

```
src/app/features/users/use_cases/user_get_by_username.py
```

## 5. Implementation steps

### Step 1 — Domain: Query

**File:** `src/app/features/users/get_user_by_username/domain/commands.py`

Define `GetUserByUsernameQuery` as a Pydantic `BaseModel`:

- `username: str`

No validation constraints — the presentation layer supplies a plain path
parameter string; the domain command assumes it is non-empty.

File header: `# FEATURE: get_user_by_username — domain query.`

### Step 2 — Domain: Entity

**File:** `src/app/features/users/get_user_by_username/domain/entities.py`

Define `FoundUser` as a Pydantic `BaseModel` with six fields:

- `id: int`
- `name: str`
- `username: str`
- `email: str`
- `profile_image_url: str`
- `tier_id: int | None`

`domain/` imports only stdlib and pydantic — no SQLAlchemy, no FastAPI.

File header: `# FEATURE: get_user_by_username — domain entity.`

### Step 3 — Domain: Port

**File:**
`src/app/features/users/get_user_by_username/domain/ports/get_user_by_username_port.py`

Define `GetUserByUsernamePort` as a `@runtime_checkable` `Protocol` with one
method:

```
async def get(self, query: GetUserByUsernameQuery) -> FoundUser | None: ...
```

`@runtime_checkable` is mandatory (per `agent_docs/architecture.md` §
Terminology: port and adapter). One method per port. The `None` return signals
"not found"; the use case decides what to do with it.

Relative imports to `domain/commands.py` and `domain/entities.py`.

File header: `# FEATURE: get_user_by_username — port protocol.`

### Step 4 — Domain: Use case

**File:** `src/app/features/users/get_user_by_username/domain/use_case.py`

Define `GetUserByUsernameUseCase`:

- `__init__(self, port: GetUserByUsernamePort) -> None` — stores port.
- `async __call__(self, query: GetUserByUsernameQuery) -> FoundUser`:
  - Calls `result = await self._port.get(query)`.
  - If `result is None`: raises `NotFoundDomainError("User not found")`.
  - Returns `result`.

No other branches. No `try/except`. Raise happens in the use case, not the
adapter, per `agent_docs/error_handling.md` § Use-case: raises, does not catch.

Relative import to `domain/errors.py` via `......domain.errors`.

File header: `# FEATURE: get_user_by_username — use case.`

### Step 5 — Data: Adapter

**File:** `src/app/features/users/get_user_by_username/data/adapter.py`

Define `GetUserByUsernameAdapter(GetUserByUsernamePort)` — explicit inheritance
from the port is mandatory (per `agent_docs/architecture.md`).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`async def get(self, query: GetUserByUsernameQuery) -> FoundUser | None`:

1. Open session via `async with self._session_factory() as session`.
2. Execute:
   `SELECT * FROM user WHERE username = ? AND is_deleted = false`
   using
   `select(User).where(User.username == query.username, User.is_deleted == False)`.
3. Fetch with `scalar_one_or_none()`.
4. If `None`, return `None` — the use case handles the missing-entity semantic.
5. Map ORM row to `FoundUser(id=..., name=..., username=..., email=...,
   profile_image_url=..., tier_id=...)`.
6. Return `FoundUser`.

No `try/except` — read-only query has no business-meaningful exception to
translate (per `agent_docs/error_handling.md` § Right shape: read-only query,
no catch). Infrastructure failures propagate to the global `_catch_all` handler.

File header: `# FEATURE: get_user_by_username — data adapter.`

### Step 6 — Presentation: Schemas

**File:** `src/app/features/users/get_user_by_username/presentation/schemas.py`

Define `GetUserByUsernameResponse` as a Pydantic `BaseModel` with
`model_config = ConfigDict(from_attributes=True)`:

- `id: int`
- `name: str`
- `username: str`
- `email: str`
- `profile_image_url: str`
- `tier_id: int | None`

No request schema — the only input is a path parameter, handled directly in the
router.

File header: `# FEATURE: get_user_by_username — request/response schemas.`

### Step 7 — Presentation: Router

**File:** `src/app/features/users/get_user_by_username/presentation/router.py`

Define `router = APIRouter()`.

Define a local helper for container access (matching the pattern established by
`create_user` and `list_users`):

```python
def _get_get_user_by_username_use_case() -> GetUserByUsernameUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.get_user_by_username_use_case()
```

Endpoint `GET /user/{username}`:

- Path param: `username: str`.
- Dependency: `use_case: Annotated[GetUserByUsernameUseCase, Depends(_get_get_user_by_username_use_case)]`.
- Body: construct `GetUserByUsernameQuery(username=username)`, await
  `use_case(query)`, return
  `GetUserByUsernameResponse(id=entity.id, name=entity.name, ...)`.
- `response_model=GetUserByUsernameResponse`, `status_code=200`.
- No auth dependency (public endpoint, per PRD).

All imports are **relative** per `agent_docs/architecture.md` § Import
conventions.

File header: `# FEATURE: get_user_by_username — HTTP router.`

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — permitted modification)

Add two imports at the top:

```python
from ..features.users.get_user_by_username.data.adapter import GetUserByUsernameAdapter
from ..features.users.get_user_by_username.domain.use_case import GetUserByUsernameUseCase
```

Add two providers after the `list_users_use_case` provider:

```python
get_user_by_username_adapter = providers.Factory(
    GetUserByUsernameAdapter,
    session_factory=session_factory,
)

get_user_by_username_use_case = providers.Factory(
    GetUserByUsernameUseCase,
    port=get_user_by_username_adapter,
)
```

### Step 9 — Update `features/users/router.py`

Remove:

```python
from .use_cases.user_get_by_username import read_user
...
router.get("/user/{username}", response_model=UserRead)(read_user)
```

Also remove the `UserRead` import if it is no longer used by any other route
in this file (check all remaining route registrations before removing).

Add:

```python
from .get_user_by_username.presentation.router import router as get_user_by_username_router
...
router.include_router(get_user_by_username_router)
```

`bootstrap/router.py` is **not touched** — it already aggregates
`features/users/router.py` and the chain is unchanged.

### Step 10 — Delete old flat file

Delete `src/app/features/users/use_cases/user_get_by_username.py`.

Confirm no other file imports from this module before deleting (check
`features/users/router.py` imports after Step 9 is complete).

### Step 11 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/users/0004_get_user_by_username/get_user_by_username_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/users/0004_get_user_by_username/domain/test_use_case.py`.
  Construct `GetUserByUsernameUseCase` with a mock `GetUserByUsernamePort`.
  Assert:
  - When port returns a `FoundUser`, the use case returns it unchanged.
  - When port returns `None`, the use case raises `NotFoundDomainError`.
  Two branches, no other paths.
  Prior art: `tests/features/users/0003_list_users/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/users/0004_get_user_by_username/data/test_adapter.py`.
  Construct `GetUserByUsernameAdapter` with a mock `async_sessionmaker`. Assert:
  - Returns a correctly-constructed `FoundUser` when the mock session yields a
    matching non-deleted row.
  - Returns `None` when the mock session yields no row.
  - The soft-delete filter is applied (mock session verifies `is_deleted=False`
    in the query predicate via the mock's call args).
  No catch path to assert — the adapter has no `try/except`.
  Prior art: `tests/features/users/0003_list_users/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/users/0004_get_user_by_username/presentation/test_router.py`.
  Use `httpx.AsyncClient` against the full app with test Postgres. Assert:
  - `GET /user/{username}` for an existing active user → `200`, response body
    matches all six fields of `GetUserByUsernameResponse`.
  - `GET /user/{username}` for an unknown username → `404`, body contains
    `{"message": "User not found"}`.
  - `GET /user/{username}` for a soft-deleted user → `404`.
  Prior art: `tests/features/users/0001_create_user/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/users/0004_get_user_by_username/get_user_by_username_outside_in_test.py`.
  Full HTTP stack with real adapter, test Postgres. No mocks. Seed a user via
  the database or the create-user endpoint, call `GET /user/{username}`, assert
  `200` and all six response fields match. This is the acceptance gate — the
  slice is not done until this test is green.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Auth / access control — endpoint stays public.
- Exposing soft-deleted users (separate admin slice if needed).
- Caching (`@cache` decorator) — not present on the current endpoint, not added
  here.
- Any other `use_cases/` flat files — each is its own future slice.
- `get_user_by_id` or any other lookup key (separate slice).

## 8. Open questions

None — all decisions resolved in the grill-me session preceding this plan.
