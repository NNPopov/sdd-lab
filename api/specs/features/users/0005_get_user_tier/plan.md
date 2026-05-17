# 0005 · get_user_tier — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0005_get_user_tier
- **PRD:** ./prd.md
- **Reference slice:** `../0004_get_user_by_username/plan.md` — same read-only,
  get-by-username shape; differs in that this slice performs two sequential
  queries (user then tier) and has four distinct port return states instead of two.
- **HTTP path:** `GET /api/v1/user/{username}/tier`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `get_user_tier_adapter` and
    `get_user_tier_use_case` providers.

## 2. Context summary

A client sends `GET /api/v1/user/{username}/tier`. The presentation router
converts the path parameter to a `GetUserTierQuery`, passes it to
`GetUserTierUseCase`, and returns a `GetUserTierResponse` with three
`tier_`-prefixed fields. The adapter issues two sequential SQLAlchemy queries:
first the `User` row (soft-delete filter applied), then the `Tier` row. Four
distinct outcomes are possible: user not found (→ 404), user has no tier (→ 200
`null`), tier record missing despite a valid `tier_id` (→ 404), or tier found
(→ 200 with tier data). The endpoint is public (no auth dependency). The
external HTTP contract — `GET /user/{username}/tier`, response field names,
status codes — is identical to the current free-function implementation.

## 3. API contract

**Request body:** none (GET endpoint).

**Path parameters:**

| Param | Type | Validation |
|---|---|---|
| `username` | `str` | required; provided in URL path |

**Response body** (`GetUserTierResponse`):

| Field | Type |
|---|---|
| `tier_id` | `int` |
| `tier_name` | `str` |
| `tier_created_at` | `datetime` |

**Status codes:**

- `200 OK` — user found with a tier; body contains the three tier fields.
- `200 OK` with `null` body — user found but has no tier assigned.
- `404 Not Found` — no active (non-deleted) user with that username; use case
  raises `NotFoundDomainError("User not found")`.
- `404 Not Found` — user has a `tier_id` but the tier row does not exist; use
  case raises `NotFoundDomainError("Tier not found")`.
- `500 Internal Server Error` — unexpected infrastructure failure; caught and
  logged by the global `_catch_all` handler.

## 4. File structure

New files:

```
src/app/features/users/get_user_tier/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                 # GetUserTierQuery
│   ├── entities.py                 # UserNotFound, TierNotFound, FoundUserTier
│   ├── ports/
│   │   ├── __init__.py
│   │   └── get_user_tier_port.py   # GetUserTierPort (Protocol)
│   └── use_case.py                 # GetUserTierUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                  # GetUserTierAdapter
└── presentation/
    ├── __init__.py
    ├── router.py                   # GET /user/{username}/tier
    └── schemas.py                  # GetUserTierResponse
```

No new ORM model. No Alembic migration. `adapters/db/models/user.py` (`User`)
and `adapters/db/models/tier.py` (`Tier`) are used as-is.

Existing files modified:

```
src/app/bootstrap/container.py          # add two new providers
src/app/features/users/router.py        # swap inline registration for include_router
```

Deleted:

```
src/app/features/users/use_cases/user_tier_get.py
```

## 5. Implementation steps

### Step 1 — Domain: Query

**File:** `domain/commands.py`

Define `GetUserTierQuery` as a Pydantic `BaseModel` with one field:

- `username: str`

No validation constraints — the path parameter is a plain string; the domain
command assumes it is non-empty.

File header: `# FEATURE: get_user_tier — domain query.`

### Step 2 — Domain: Sentinel classes + Entity

**File:** `domain/entities.py`

Define three types, all pure Python (stdlib + pydantic only, per
`agent_docs/architecture.md` layer rules):

```
class UserNotFound:
    """Adapter signals: no active user row for the given username."""

class TierNotFound:
    """Adapter signals: user has tier_id but the tier row is absent."""

class FoundUserTier(BaseModel):
    tier_id: int
    tier_name: str
    tier_created_at: datetime
```

`UserNotFound` and `TierNotFound` are plain Python classes (no Pydantic, no
dataclass required — they carry no data). They are the discriminated-union
sentinels that let the port communicate four states through a single method
without ambiguous `None` returns and without using forbidden `Result[T, E]`
types.

`FoundUserTier` carries the three tier fields with the `tier_` prefix preserved
for backward compatibility (see PRD §Further Notes).

File header: `# FEATURE: get_user_tier — domain entities.`

### Step 3 — Domain: Port

**File:** `domain/ports/get_user_tier_port.py`

Define `GetUserTierPort` as a `@runtime_checkable Protocol` with one method:

```
async def get(
    self, query: GetUserTierQuery
) -> FoundUserTier | None | UserNotFound | TierNotFound: ...
```

Return-type semantics (documented here; must also appear as a docstring on the
method):

| Return value | Meaning |
|---|---|
| `FoundUserTier` | User exists and has a valid tier. |
| `None` | User exists but `tier_id` is `None`. |
| `UserNotFound()` | No active user row for the given username. |
| `TierNotFound()` | User has a `tier_id` but the tier row is absent. |

`@runtime_checkable` is mandatory (per `agent_docs/architecture.md` §
Terminology: port and adapter). One method per port. All imports are relative.

File header: `# FEATURE: get_user_tier — port protocol.`

### Step 4 — Domain: Use case

**File:** `domain/use_case.py`

Define `GetUserTierUseCase`:

- `__init__(self, port: GetUserTierPort) -> None` — stores port.
- `async __call__(self, query: GetUserTierQuery) -> FoundUserTier | None`:
  1. `result = await self._port.get(query)`
  2. `if isinstance(result, UserNotFound)` → raise `NotFoundDomainError("User not found")`
  3. `if isinstance(result, TierNotFound)` → raise `NotFoundDomainError("Tier not found")`
  4. `return result` — at this point `result` is `FoundUserTier | None`; the
     caller receives `None` when the user has no tier assigned.

No `try/except`. Both `NotFoundDomainError` raises happen in the use case, not
the adapter, consistent with `agent_docs/error_handling.md` § Use-case: raises,
does not catch. The `isinstance` checks replace the need for a multi-method port.

File header: `# FEATURE: get_user_tier — use case.`

### Step 5 — Data: Adapter

**File:** `data/adapter.py`

Define `GetUserTierAdapter(GetUserTierPort)` — explicit inheritance from the
port is mandatory (per `agent_docs/architecture.md` § Terminology: port and
adapter).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`async def get(self, query: GetUserTierQuery) -> FoundUserTier | None | UserNotFound | TierNotFound`:

**Query 1 — User:**

```python
async with self._session_factory() as session:
    result = await session.execute(
        select(User).where(
            User.username == query.username,
            User.is_deleted == False,  # noqa: E712
        )
    )
    user_row = result.scalar_one_or_none()
```

- If `user_row is None`: return `UserNotFound()`.
- If `user_row.tier_id is None`: return `None`.

**Query 2 — Tier** (only reached when `tier_id` is set):

```python
async with self._session_factory() as session:
    result = await session.execute(
        select(Tier).where(Tier.id == user_row.tier_id)
    )
    tier_row = result.scalar_one_or_none()
```

- If `tier_row is None`: return `TierNotFound()`.
- Otherwise build and return `FoundUserTier(tier_id=tier_row.id, tier_name=tier_row.name, tier_created_at=tier_row.created_at)`.

No `try/except` — both queries are read-only; there are no business-meaningful
infrastructure exceptions to translate (per `agent_docs/error_handling.md` §
Right shape: read-only query, no catch).

Note: the two queries use separate `async with self._session_factory()` blocks
to match the two-query decision from the grill-me session. This is intentional
and keeps each query atomic.

File header: `# FEATURE: get_user_tier — data adapter.`

### Step 6 — Presentation: Schemas

**File:** `presentation/schemas.py`

Define `GetUserTierResponse` as a Pydantic `BaseModel` with
`model_config = ConfigDict(from_attributes=True)`:

- `tier_id: int`
- `tier_name: str`
- `tier_created_at: datetime`

No request schema — the only input is the `username` path parameter, handled
directly in the router.

File header: `# FEATURE: get_user_tier — request/response schemas.`

### Step 7 — Presentation: Router

**File:** `presentation/router.py`

Define `router = APIRouter()`.

Define a local helper for container access, following the pattern established by
`get_user_by_username`:

```python
def _get_get_user_tier_use_case() -> GetUserTierUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.get_user_tier_use_case()
```

Endpoint `GET /user/{username}/tier`:

- Path param: `username: str`.
- Use case dependency via `Annotated[GetUserTierUseCase, Depends(_get_get_user_tier_use_case)]`.
- Construct `GetUserTierQuery(username=username)`, await `use_case(query)`.
- If entity is `None`, return `None` directly (FastAPI serializes to `null` with
  200 OK given `response_model=GetUserTierResponse | None`).
- Otherwise return `GetUserTierResponse(tier_id=entity.tier_id, tier_name=entity.tier_name, tier_created_at=entity.tier_created_at)`.
- `response_model=GetUserTierResponse | None`, `status_code=200`.
- No auth dependency (public endpoint, per PRD).

All imports are **relative** per `agent_docs/architecture.md` § Import
conventions.

File header: `# FEATURE: get_user_tier — HTTP router.`

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — permitted modification)

Add two imports at the top (after existing slice imports):

```python
from ..features.users.get_user_tier.data.adapter import GetUserTierAdapter
from ..features.users.get_user_tier.domain.use_case import GetUserTierUseCase
```

Add two providers after the `get_user_by_username_use_case` provider:

```python
get_user_tier_adapter = providers.Factory(
    GetUserTierAdapter,
    session_factory=session_factory,
)

get_user_tier_use_case = providers.Factory(
    GetUserTierUseCase,
    port=get_user_tier_adapter,
)
```

### Step 9 — Update `features/users/router.py`

Remove:

```python
from .use_cases.user_tier_get import read_user_tier
...
router.get("/user/{username}/tier")(read_user_tier)
```

Add:

```python
from .get_user_tier.presentation.router import router as get_user_tier_router
...
router.include_router(get_user_tier_router)
```

`bootstrap/router.py` is **not touched** — it already aggregates
`features/users/router.py` and the chain is unchanged.

### Step 10 — Delete old flat file

Delete `src/app/features/users/use_cases/user_tier_get.py`.

Before deleting, confirm that no file other than `features/users/router.py`
imports from this module (check with `grep -r "user_tier_get"` after Step 9 is
complete and the router import is already removed).

### Step 11 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/users/0005_get_user_tier/get_user_tier_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/users/0005_get_user_tier/domain/test_use_case.py`.
  Construct `GetUserTierUseCase` with a mock `GetUserTierPort`. Assert:
  - Port returns `FoundUserTier` → use case returns it unchanged.
  - Port returns `None` → use case returns `None`.
  - Port returns `UserNotFound()` → use case raises `NotFoundDomainError("User not found")`.
  - Port returns `TierNotFound()` → use case raises `NotFoundDomainError("Tier not found")`.
  Four branches; no other paths.
  Prior art: `tests/features/users/0004_get_user_by_username/`.

- **Adapter unit test** —
  `tests/features/users/0005_get_user_tier/data/test_adapter.py`.
  Construct `GetUserTierAdapter` with a mock `async_sessionmaker`. Assert:
  - User row not found → adapter returns `UserNotFound()`.
  - User row found, `tier_id` is `None` → adapter returns `None`.
  - User row found, tier row found → adapter returns correctly-constructed `FoundUserTier`.
  - User row found, `tier_id` set, tier row not found → adapter returns `TierNotFound()`.
  No catch path to assert — the adapter has no `try/except`.
  Prior art: `tests/features/users/0004_get_user_by_username/`.

- **Endpoint integration test** —
  `tests/features/users/0005_get_user_tier/presentation/test_router.py`.
  Use `httpx.AsyncClient` against the full app with test Postgres. Assert:
  - `GET /user/{username}/tier` for a user with a tier → `200`, body contains
    `tier_id`, `tier_name`, `tier_created_at`.
  - `GET /user/{username}/tier` for a user with `tier_id = None` → `200`, body is `null`.
  - `GET /user/{username}/tier` for an unknown username → `404`,
    `{"message": "User not found"}`.
  - `GET /user/{username}/tier` for a user whose `tier_id` references a missing
    tier row → `404`, `{"message": "Tier not found"}`.
  Prior art: `tests/features/users/0004_get_user_by_username/`.

- **Outside-in test** —
  `tests/features/users/0005_get_user_tier/get_user_tier_outside_in_test.py`.
  Full HTTP stack with real adapter, test Postgres. Seed a user with a tier via
  the database, call `GET /user/{username}/tier`, assert `200` and the three
  contracted response fields match. This is the acceptance gate — the slice is
  not done until this test is green.
  Prior art: `tests/features/users/0004_get_user_by_username/get_user_by_username_outside_in_test.py`.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Auth / access control — endpoint stays public (no change from current).
- Caching (`@cache` decorator) — not present on the current endpoint; not added.
- Pagination or query parameters beyond `username`.
- Refactoring any other old-style `use_cases/` free functions.
- Optimizing to a single JOIN query — intentionally deferred (see PRD §Further Notes).
- Any change to `User` or `Tier` ORM models or Alembic migrations.

## 8. Open questions

None — all decisions resolved in the grill-me session preceding this plan.
The sentinel approach (`UserNotFound`, `TierNotFound`) was chosen to express
the four port states without ambiguous `None` returns, without a
multi-method port, and without forbidden `Result[T, E]` types.
