# 0015 · assign_moderator — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0015_assign_moderator
- **PRD:** ./prd.md
- **Reference slice:** `../0007_delete_user/plan.md` — closest operation shape: a
  superuser-gated mutation on a user row that checks existence first and returns
  a success payload. The lazy-container-import router pattern comes from
  `delete_db_user` (pure superuser, no ownership variant).
- **HTTP path:** `PATCH /api/v1/user/{username}/assign-moderator`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `assign_moderator_adapter` and
    `assign_moderator_use_case` providers plus their imports.

## 2. Context summary

A superuser calls `PATCH /user/{username}/assign-moderator` to promote a target
user to moderator. The router resolves the caller via `get_current_superuser`,
builds an `AssignModeratorCommand` carrying the target username (path param), the
superuser's integer PK (`requester_id`), and the `requester_is_superuser` flag
(second-layer use-case defence). `AssignModeratorUseCase` enforces the superuser
check, verifies the target exists, guards against duplicate assignment, then
delegates to the port to write `is_moderator = True` and
`moderator_granted_by_user_id = requester_id` to the `User` row. The use-case
returns an `AssignedUser` entity; the router converts it to
`AssignModeratorResponse` (HTTP 200). No migrations are needed — both columns
were added by slice 0013.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `username` | `str` | Username of the user to promote |

**Request body:** none.

**Response body** (`AssignModeratorResponse`):

| Field | Type | Notes |
|---|---|---|
| `id` | `int` | user primary key |
| `name` | `str` | display name |
| `username` | `str` | unique handle |
| `email` | `str` | |
| `profile_image_url` | `str` | |
| `tier_id` | `int \| None` | |
| `is_moderator` | `bool` | always `true` after successful assignment |

**Status codes:**

- `200 OK` — moderator role assigned; response body confirmed.
- `401 Unauthorized` — missing or invalid Bearer token (`UnauthorizedException`
  from `get_current_superuser` → `get_current_user`).
- `403 Forbidden` — authenticated user is not a superuser (`ForbiddenException`
  from `get_current_superuser`; also `ForbiddenDomainError` from the use-case
  second-layer check, translated to 403 by the global handler).
- `404 Not Found` — `NotFoundDomainError`; `username` does not exist or is
  soft-deleted.
- `409 Conflict` — `DuplicateValueDomainError`; target is already a moderator.

## 4. File structure

All new files; no existing files deleted. Two STABLE files receive one-line
additions each.

```
src/app/features/users/assign_moderator/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                       # AssignModeratorCommand
│   ├── entities.py                       # AssignedUser
│   ├── ports/
│   │   ├── __init__.py
│   │   └── assign_moderator_port.py      # AssignModeratorPort
│   └── use_case.py                       # AssignModeratorUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                        # AssignModeratorAdapter
└── presentation/
    ├── __init__.py
    ├── router.py
    └── schemas.py                        # AssignModeratorResponse
```

FEATURE file modified (not STABLE):

```
src/app/features/users/router.py          # include_router(assign_moderator_router)
```

STABLE files modified (minimal additions only):

```
src/app/bootstrap/container.py            # two providers + two imports
```

No new ORM model. No Alembic migration.

## 5. Implementation steps

### Step 1 — Domain: Command

**File:** `src/app/features/users/assign_moderator/domain/commands.py`

Header: `# FEATURE: assign_moderator — domain command.`

```python
class AssignModeratorCommand(BaseModel):
    target_username: str
    requester_id: int
    requester_is_superuser: bool
```

`requester_id` is the integer PK of the requesting superuser; it is written into
`moderator_granted_by_user_id`. `requester_is_superuser` is the second-layer
defence flag (see PRD § Superuser privilege check placement). Both come from the
`get_current_superuser` dependency in the router. No optional fields; all three
are always required.

### Step 2 — Domain: Entity

**File:** `src/app/features/users/assign_moderator/domain/entities.py`

Header: `# FEATURE: assign_moderator — domain entity.`

```python
class AssignedUser(BaseModel):
    id: int
    name: str
    username: str
    email: str
    profile_image_url: str
    tier_id: int | None
    is_moderator: bool
```

`AssignedUser` is defined fresh in this slice's `domain/` layer. It must not be
imported from `get_user_by_username`; that would be a cross-slice domain import,
forbidden per `agent_docs/architecture.md` § Layer rules. The identical shape is
coincidental; the two entities are independent.

### Step 3 — Domain: Port

**File:** `src/app/features/users/assign_moderator/domain/ports/assign_moderator_port.py`

Header: `# FEATURE: assign_moderator — port protocol.`

```python
@runtime_checkable
class AssignModeratorPort(Protocol):
    async def get_by_username(self, username: str) -> AssignedUser | None: ...
    async def assign(
        self, target_username: str, granted_by_user_id: int
    ) -> AssignedUser: ...
```

`@runtime_checkable` is mandatory per `agent_docs/architecture.md` §
Terminology: port and adapter. Two methods: one narrow read (existence +
current moderator status), one narrow write (assign role, return updated state).

### Step 4 — Domain: Use case

**File:** `src/app/features/users/assign_moderator/domain/use_case.py`

Header: `# FEATURE: assign_moderator — use case.`

`class AssignModeratorUseCase`:
- `__init__(self, port: AssignModeratorPort)`.
- `async def __call__(self, command: AssignModeratorCommand) -> AssignedUser`:
  1. If `command.requester_is_superuser` is `False` → raise
     `ForbiddenDomainError("Superuser privilege required")`.
  2. `target = await self._port.get_by_username(command.target_username)`.
  3. If `target is None` → raise `NotFoundDomainError("User not found")`.
  4. If `target.is_moderator` is `True` → raise
     `DuplicateValueDomainError("User is already a moderator")`.
  5. Return `await self._port.assign(command.target_username, command.requester_id)`.

Imports: `ForbiddenDomainError`, `NotFoundDomainError`, `DuplicateValueDomainError`
from `domain/errors.py` (relative path `....domain.errors` — five dots). Never
raises `HTTPException`. Never catches.

### Step 5 — Data: Adapter

**File:** `src/app/features/users/assign_moderator/data/adapter.py`

Header: `# FEATURE: assign_moderator — data adapter.`

`class AssignModeratorAdapter(AssignModeratorPort)` — explicit inheritance
mandatory per `agent_docs/architecture.md` § Adapter pattern (canonical).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

**`get_by_username(username)`** — `SELECT` from `User` where
`User.username == username AND User.is_deleted == False`. Return a mapped
`AssignedUser` if found, else `None`. No `try/except` per
`agent_docs/error_handling.md` § Right shape: read-only query, no catch.

**`assign(target_username, granted_by_user_id)`** — within a single session
context: (a) execute `UPDATE User SET is_moderator = True,
moderator_granted_by_user_id = granted_by_user_id WHERE username == target_username`,
then commit; (b) `SELECT` the updated row and map to `AssignedUser`. Return the
entity. No `try/except` — an UPDATE on `is_moderator` (no unique constraint)
produces no business-meaningful `IntegrityError`; any infrastructure failure
propagates to the global handler per `agent_docs/error_handling.md`.

Import the `User` ORM model from `adapters/db/models/user.py` using relative
imports (`from .....adapters.db.models.user import User`).

### Step 6 — Presentation: Schemas

**File:** `src/app/features/users/assign_moderator/presentation/schemas.py`

Header: `# FEATURE: assign_moderator — request/response schemas.`

```python
class AssignModeratorResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    username: str
    email: str
    profile_image_url: str
    tier_id: int | None
    is_moderator: bool
```

No request schema — the endpoint carries no body; all inputs come from the path
param and the auth dependency.

### Step 7 — Presentation: Router

**File:** `src/app/features/users/assign_moderator/presentation/router.py`

Header: `# FEATURE: assign_moderator — HTTP router.`

Use the lazy-container-import pattern established in `delete_db_user`:

```python
def _get_assign_moderator_use_case() -> AssignModeratorUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.assign_moderator_use_case()
```

Endpoint:

```python
@router.patch(
    "/user/{username}/assign-moderator",
    response_model=AssignModeratorResponse,
    status_code=200,
)
async def assign_moderator_endpoint(
    username: str,
    use_case: Annotated[AssignModeratorUseCase, Depends(_get_assign_moderator_use_case)],
    current_superuser: Annotated[dict, Depends(get_current_superuser)],
) -> AssignModeratorResponse:
    command = AssignModeratorCommand(
        target_username=username,
        requester_id=current_superuser["id"],
        requester_is_superuser=current_superuser["is_superuser"],
    )
    entity = await use_case(command)
    return AssignModeratorResponse(
        id=entity.id,
        name=entity.name,
        username=entity.username,
        email=entity.email,
        profile_image_url=entity.profile_image_url,
        tier_id=entity.tier_id,
        is_moderator=entity.is_moderator,
    )
```

Import `get_current_superuser` from `...dependencies` (relative). No business
logic. No `try/except`. No direct DB access.

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — two-line addition)

Add after the last existing use-case provider:

```python
assign_moderator_adapter = providers.Factory(
    AssignModeratorAdapter,
    session_factory=session_factory,
)

assign_moderator_use_case = providers.Factory(
    AssignModeratorUseCase,
    port=assign_moderator_adapter,
)
```

Add the two corresponding imports at the top of the file (alongside the existing
feature imports).

### Step 9 — Router registration

**File:** `src/app/features/users/router.py` (FEATURE file)

Add one import and one `include_router` call, following the existing pattern:

```python
from .assign_moderator.presentation.router import router as assign_moderator_router
# ...
router.include_router(assign_moderator_router)
```

`bootstrap/router.py` is **not touched** — it already aggregates `users_router`,
which in turn aggregates all slice sub-routers.

### Step 10 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/users/0015_assign_moderator/assign_moderator_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/users/0015_assign_moderator/domain/test_use_case.py`.
  Mock `AssignModeratorPort` (a `MagicMock` satisfying the protocol).
  Four cases:
  - `requester_is_superuser=False` → `ForbiddenDomainError` raised; assert
    `port.get_by_username` is never called.
  - `requester_is_superuser=True`, `port.get_by_username` returns `None` →
    `NotFoundDomainError` raised; assert `port.assign` is never called.
  - `port.get_by_username` returns an `AssignedUser` with `is_moderator=True` →
    `DuplicateValueDomainError` raised.
  - Happy path: `port.get_by_username` returns `is_moderator=False`,
    `port.assign` returns an `AssignedUser`; assert the use-case returns it
    unchanged.
  Prior art: `tests/features/users/0007_delete_user/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/users/0015_assign_moderator/data/test_adapter.py`.
  Uses a real async session against the test Postgres database.
  Three cases:
  - `get_by_username` — user not found: assert `None` returned.
  - `get_by_username` — active user found: create a row, assert the returned
    `AssignedUser` fields match; assert soft-deleted users are excluded.
  - `assign` happy path: create a user with `is_moderator=False`, call
    `adapter.assign(username, grantor_id)`, assert returned entity has
    `is_moderator=True`, fetch the row directly and assert both `is_moderator`
    and `moderator_granted_by_user_id` are written correctly.
  Prior art: `tests/features/users/0001_create_user/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/users/0015_assign_moderator/presentation/test_router.py`.
  `httpx.AsyncClient` against the running app with test Postgres.
  Five cases:
  - No Authorization header → 401.
  - Valid token, non-superuser → 403.
  - Superuser token, non-existent username → 404.
  - Superuser token, existing user already a moderator → 409.
  - Superuser token, non-moderator user → 200, `is_moderator: true` in body,
    other fields match the created user.
  Prior art: `tests/features/users/0007_delete_user/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/users/0015_assign_moderator/assign_moderator_outside_in_test.py`.
  Full HTTP stack with real adapters, test Postgres, no mocks.
  Five-step scenario:
  1. Create a regular user (non-moderator) via `POST /users`.
  2. Create a superuser via `POST /users` + directly set `is_superuser=True`
     in the DB, or use the test fixture.
  3. Authenticate the superuser, obtain a Bearer token.
  4. `PATCH /user/{username}/assign-moderator` — assert HTTP 200 and
     `is_moderator: true` in the response body.
  5. `GET /user/{username}` (unauthenticated) — assert `is_moderator: true`,
     confirming the assignment persisted and is visible through the read path.
  Acceptance gate: the slice is not done until this test is green.

**Opt-outs:** none — all four test levels apply.

## 7. Out of scope for this slice

- Revoking moderator status — slice 0016.
- `get_current_moderator` auth dependency — introduced in slices 0017 and 0019.
- Exposing `moderator_granted_by_user_id` in any response.
- Full grant history audit log.
- Cache invalidation for user profile responses (no caching on `get_user_by_username`
  currently).
- Rate limiting — endpoint is behind superuser auth.

## 8. Open questions

None — all decisions resolved in the PRD.
