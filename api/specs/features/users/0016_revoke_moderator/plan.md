# 0016 · revoke_moderator — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0016_revoke_moderator
- **PRD:** ./prd.md
- **Reference slice:** `../0015_assign_moderator/plan.md` — mirror operation:
  superuser-gated mutation on a user row that checks existence and current role
  state before writing, then returns the updated user profile.
- **HTTP path:** `PATCH /api/v1/users/{username}/revoke-moderator`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `revoke_moderator_adapter` and
    `revoke_moderator_use_case` providers plus their imports.

> **Path note:** the reference slice 0015 used the singular `/user/{username}/…`
> prefix inside `features/users/router.py`. This slice follows the PRD and the
> REST convention in `agent_docs/entry_points/fastapi.md` and uses the plural
> `/users/{username}/…`. The two sub-paths coexist under the same feature router.

## 2. Context summary

A superuser calls `PATCH /users/{username}/revoke-moderator` to demote a target
user from moderator. The router resolves the caller via `get_current_superuser`,
builds a `RevokeModeratorCommand` carrying the target username and the
`requester_is_superuser` flag. `RevokeModeratorUseCase` enforces the superuser
check, verifies the target exists, guards against revoking a user who is not
currently a moderator, then delegates to the port to write `is_moderator = False`
and `moderator_granted_by_user_id = None` to the `User` row. The use-case
returns a `RevokedUser` entity; the router converts it to
`RevokeModeratorResponse` (HTTP 200). No new columns and no migration are
needed — both columns exist since slice 0013.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `username` | `str` | Username of the user to demote |

**Request body:** none.

**Response body** (`RevokeModeratorResponse`):

| Field | Type | Notes |
|---|---|---|
| `id` | `int` | user primary key |
| `name` | `str` | display name |
| `username` | `str` | unique handle |
| `email` | `str` | |
| `profile_image_url` | `str` | |
| `tier_id` | `int \| None` | |
| `is_moderator` | `bool` | always `false` after successful revocation |

**Status codes:**

- `200 OK` — moderator role revoked; response body confirmed.
- `401 Unauthorized` — missing or invalid Bearer token (`UnauthorizedException`
  from `get_current_superuser` → `get_current_user`).
- `403 Forbidden` — authenticated user is not a superuser (`ForbiddenException`
  from `get_current_superuser`; also `ForbiddenDomainError` from the use-case
  second-layer check, translated to 403 by the global handler).
- `404 Not Found` — `NotFoundDomainError`; `username` does not exist or is
  soft-deleted.
- `409 Conflict` — `DuplicateValueDomainError`; target is not currently a
  moderator. (Reusing this subclass for the 409 case per PRD § Implementation
  Decisions — a new subclass would require a STABLE change to `domain/errors.py`.)

## 4. File structure

All new files; no existing files deleted. One STABLE file and one FEATURE file
receive one-line additions each.

```
src/app/features/users/revoke_moderator/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                        # RevokeModeratorCommand
│   ├── entities.py                        # RevokedUser
│   ├── ports/
│   │   ├── __init__.py
│   │   └── revoke_moderator_port.py       # RevokeModeratorPort
│   └── use_case.py                        # RevokeModeratorUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                         # RevokeModeratorAdapter
└── presentation/
    ├── __init__.py
    ├── router.py
    └── schemas.py                         # RevokeModeratorResponse
```

FEATURE file modified (not STABLE):

```
src/app/features/users/router.py           # include_router(revoke_moderator_router)
```

STABLE file modified (minimal addition only):

```
src/app/bootstrap/container.py             # two providers + two imports
```

No new ORM model. No Alembic migration.

## 5. Implementation steps

### Step 1 — Domain: Command

**File:** `src/app/features/users/revoke_moderator/domain/commands.py`

Header: `# FEATURE: revoke_moderator — domain command.`

```python
class RevokeModeratorCommand(BaseModel):
    target_username: str
    requester_is_superuser: bool
```

No `requester_id` field — the revoke operation clears `moderator_granted_by_user_id`
rather than populating it, so the requester's PK is not needed. Both fields are
always required; no optional fields.

### Step 2 — Domain: Entity

**File:** `src/app/features/users/revoke_moderator/domain/entities.py`

Header: `# FEATURE: revoke_moderator — domain entity.`

```python
class RevokedUser(BaseModel):
    id: int
    name: str
    username: str
    email: str
    profile_image_url: str
    tier_id: int | None
    is_moderator: bool
```

`RevokedUser` is defined fresh in this slice's `domain/` layer. It must not be
imported from `assign_moderator` — that would be a cross-slice domain import,
forbidden per `agent_docs/architecture.md` § Layer rules. The identical shape
with `AssignedUser` is coincidental; the two entities are independent.

### Step 3 — Domain: Port

**File:** `src/app/features/users/revoke_moderator/domain/ports/revoke_moderator_port.py`

Header: `# FEATURE: revoke_moderator — port protocol.`

```python
@runtime_checkable
class RevokeModeratorPort(Protocol):
    async def get_by_username(self, username: str) -> RevokedUser | None: ...
    async def revoke(self, target_username: str) -> RevokedUser: ...
```

`@runtime_checkable` is mandatory per `agent_docs/architecture.md` §
Terminology: port and adapter. Two methods: one narrow read (existence +
current moderator status), one narrow write (clear role, return updated state).
Unlike `AssignModeratorPort.assign()`, `revoke()` does not accept a
`granted_by_user_id` parameter because revocation always sets that column to
`None`.

### Step 4 — Domain: Use case

**File:** `src/app/features/users/revoke_moderator/domain/use_case.py`

Header: `# FEATURE: revoke_moderator — use case.`

`class RevokeModeratorUseCase`:
- `__init__(self, port: RevokeModeratorPort)`.
- `async def __call__(self, command: RevokeModeratorCommand) -> RevokedUser`:
  1. If `command.requester_is_superuser` is `False` → raise
     `ForbiddenDomainError("Superuser privilege required")`.
  2. `target = await self._port.get_by_username(command.target_username)`.
  3. If `target is None` → raise `NotFoundDomainError("User not found")`.
  4. If `target.is_moderator` is `False` → raise
     `DuplicateValueDomainError("User is not a moderator")`.
  5. Return `await self._port.revoke(command.target_username)`.

Imports: `ForbiddenDomainError`, `NotFoundDomainError`, `DuplicateValueDomainError`
from `domain/errors.py` via relative path `from .....domain.errors import …`
(five dots: `domain` → `revoke_moderator` → `users` → `features` → `app`).
Never raises `HTTPException`. Never catches.

### Step 5 — Data: Adapter

**File:** `src/app/features/users/revoke_moderator/data/adapter.py`

Header: `# FEATURE: revoke_moderator — data adapter.`

`class RevokeModeratorAdapter(RevokeModeratorPort)` — explicit inheritance
mandatory per `agent_docs/architecture.md` § Adapter pattern (canonical).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

**`get_by_username(username)`** — `SELECT` from `User` where
`User.username == username AND User.is_deleted == False`. Return a mapped
`RevokedUser` if found, else `None`. No `try/except` per
`agent_docs/error_handling.md` § Right shape: read-only query, no catch.

**`revoke(target_username)`** — within a single session context: (a) execute
`UPDATE User SET is_moderator = False, moderator_granted_by_user_id = None
WHERE username == target_username`, then commit; (b) `SELECT` the updated row
and map to `RevokedUser`. Return the entity. No `try/except` — an `UPDATE` on
`is_moderator` (no unique constraint) produces no business-meaningful
`IntegrityError`; any infrastructure failure propagates to the global handler
per `agent_docs/error_handling.md`.

Import the `User` ORM model using relative imports:
`from .....adapters.db.models.user import User`
(five dots: `data` → `revoke_moderator` → `users` → `features` → `app`).

### Step 6 — Presentation: Schemas

**File:** `src/app/features/users/revoke_moderator/presentation/schemas.py`

Header: `# FEATURE: revoke_moderator — request/response schemas.`

```python
class RevokeModeratorResponse(BaseModel):
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

**File:** `src/app/features/users/revoke_moderator/presentation/router.py`

Header: `# FEATURE: revoke_moderator — HTTP router.`

Use the lazy-container-import pattern established in the reference slice:

```python
def _get_revoke_moderator_use_case() -> RevokeModeratorUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.revoke_moderator_use_case()
```

Endpoint:

```python
@router.patch(
    "/users/{username}/revoke-moderator",
    response_model=RevokeModeratorResponse,
    status_code=200,
)
async def revoke_moderator_endpoint(
    username: str,
    use_case: Annotated[RevokeModeratorUseCase, Depends(_get_revoke_moderator_use_case)],
    current_superuser: Annotated[dict, Depends(get_current_superuser)],
) -> RevokeModeratorResponse:
    command = RevokeModeratorCommand(
        target_username=username,
        requester_is_superuser=current_superuser["is_superuser"],
    )
    entity = await use_case(command)
    return RevokeModeratorResponse(
        id=entity.id,
        name=entity.name,
        username=entity.username,
        email=entity.email,
        profile_image_url=entity.profile_image_url,
        tier_id=entity.tier_id,
        is_moderator=entity.is_moderator,
    )
```

Import `get_current_superuser` from `..._shared.dependencies` (three dots: 
`presentation` → `revoke_moderator` → `users`, then `_shared.dependencies`).
No business logic. No `try/except`. No direct DB access.

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — two-provider addition)

Add after the last existing use-case provider:

```python
revoke_moderator_adapter = providers.Factory(
    RevokeModeratorAdapter,
    session_factory=session_factory,
)

revoke_moderator_use_case = providers.Factory(
    RevokeModeratorUseCase,
    port=revoke_moderator_adapter,
)
```

Add the two corresponding imports at the top of the file (alongside the
existing feature imports).

### Step 9 — Router registration

**File:** `src/app/features/users/router.py` (FEATURE file)

Add one import and one `include_router` call, following the existing pattern:

```python
from .revoke_moderator.presentation.router import router as revoke_moderator_router
# ...
router.include_router(revoke_moderator_router)
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
pytest tests/features/users/0016_revoke_moderator/revoke_moderator_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/users/0016_revoke_moderator/domain/test_use_case.py`.
  Mock `RevokeModeratorPort` (a `MagicMock` satisfying the protocol).
  Four cases:
  - `requester_is_superuser=False` → `ForbiddenDomainError` raised; assert
    `port.get_by_username` is never called.
  - `requester_is_superuser=True`, `port.get_by_username` returns `None` →
    `NotFoundDomainError` raised; assert `port.revoke` is never called.
  - `port.get_by_username` returns a `RevokedUser` with `is_moderator=False` →
    `DuplicateValueDomainError` raised; assert `port.revoke` is never called.
  - Happy path: `port.get_by_username` returns `is_moderator=True`,
    `port.revoke` returns a `RevokedUser`; assert the use-case returns it
    unchanged.
  Prior art: `tests/features/users/0015_assign_moderator/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/users/0016_revoke_moderator/data/test_adapter.py`.
  Uses a real async session against the test Postgres database.
  Three cases:
  - `get_by_username` — user not found: assert `None` returned.
  - `get_by_username` — active user found: create a row, assert the returned
    `RevokedUser` fields match; assert soft-deleted users are excluded.
  - `revoke` happy path: create a user with `is_moderator=True` and
    `moderator_granted_by_user_id` set, call `adapter.revoke(username)`, assert
    returned entity has `is_moderator=False`, fetch the row directly and assert
    both `is_moderator=False` and `moderator_granted_by_user_id=None`.
  Prior art: `tests/features/users/0015_assign_moderator/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/users/0016_revoke_moderator/presentation/test_router.py`.
  `httpx.AsyncClient` against the running app with test Postgres.
  Five cases:
  - No Authorization header → 401.
  - Valid token, non-superuser → 403.
  - Superuser token, non-existent username → 404.
  - Superuser token, existing non-moderator user → 409.
  - Superuser token, existing moderator user → 200, `is_moderator: false` in
    body, other fields match the created user.
  Prior art: `tests/features/users/0015_assign_moderator/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/users/0016_revoke_moderator/revoke_moderator_outside_in_test.py`.
  Full HTTP stack with real adapters, test Postgres, no mocks.
  Five-step scenario:
  1. Create a regular user (non-moderator) via `POST /users`.
  2. Authenticate as a superuser (fixture or created + promoted in DB).
  3. Call `PATCH /users/{username}/assign-moderator` to promote the user.
  4. Call `PATCH /users/{username}/revoke-moderator` — assert HTTP 200 and
     `is_moderator: false` in the response body.
  5. Call `GET /users/user/{username}` (unauthenticated) — assert `is_moderator:
     false`, confirming the revocation persisted and is visible through the read
     path.
  Acceptance gate: the slice is not done until this test is green.

**Opt-outs:** none — all four test levels apply.

## 7. Out of scope for this slice

- Assigning moderator status — slice 0015.
- `get_current_moderator` auth dependency — slices 0017 and 0019.
- Exposing `moderator_granted_by_user_id` in any response.
- Full revocation history audit log.
- Cache invalidation for user profile responses (no caching on
  `get_user_by_username` currently).
- Rate limiting — endpoint is behind superuser auth.
- Preventing a superuser from revoking their own moderator flag (out of scope
  per PRD).
- Cascading effects on existing moderation decisions when a moderator is
  revoked.

## 8. Open questions

None — all decisions resolved in the PRD.
