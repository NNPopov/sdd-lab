# 0047 · revoke_moderator_route_to_user_id — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0047_revoke_moderator_route_to_user_id
- **PRD:** ./prd.md
- **Reference slice:** `../0046_assign_moderator_route_to_user_id/plan.md` — exact structural match (the sibling `{username}` → `{user_id}` moderator-role migration). The slice being modified is `0016_revoke_moderator` (`src/app/features/users/revoke_moderator/`).
- **HTTP path:** `PATCH /api/v1/users/{user_id}/revoke-moderator`
- **STABLE files touched:** none. `bootstrap/container.py` already wires `revoke_moderator_use_case` / `revoke_moderator_adapter`, the users router already registers the route, and `Container.wiring_config` already lists the router module. No new providers, registrations, or `.importlinter` entries are needed.

## 2. Context summary

Slice 0047 migrates the existing `PATCH /users/{username}/revoke-moderator` route
to `PATCH /users/{user_id}/revoke-moderator`. No new slice folder is created; the
existing `features/users/revoke_moderator/` slice is modified in place. The
command's identifier field changes from `target_username: str` to
`target_user_id: int` (`requester_is_superuser` is unchanged); the port replaces
`get_by_username` with `get_by_id` and changes `revoke`'s parameter to
`target_user_id: int`; the adapter looks up and updates by `User.id`; the router
changes the path param type from `str` to `int` and passes
`target_user_id=user_id`. Superuser-only authorization, the not-a-moderator 409
check, the `RevokedUser` entity, and the response body are all unchanged. Note
the path keeps the plural `/users/` segment used by the existing route (unlike
the sibling `assign_moderator` route, which uses singular `/user/`).

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the account being stripped of moderator status |

**Request body:** none.

**Response body** (`RevokeModeratorResponse` — unchanged):

| Field | Type | Notes |
|---|---|---|
| `id` | `int` | Target user's primary key |
| `name` | `str` | |
| `username` | `str` | |
| `email` | `str` | |
| `profile_image_url` | `str` | |
| `tier_id` | `int \| None` | |
| `is_moderator` | `bool` | `false` after a successful revocation |

**Status codes:**

- `200 OK` — moderator role revoked; updated profile returned.
- `401 Unauthorized` — missing or invalid token.
- `403 Forbidden` — `ForbiddenDomainError`; requester is not a superuser.
- `404 Not Found` — `NotFoundDomainError`; `user_id` not found (or soft-deleted).
- `409 Conflict` — `DuplicateValueDomainError`; target user is not currently a moderator.
- `422 Unprocessable Entity` — FastAPI/Pydantic rejects a non-integer path param.

## 4. File structure

No new files. Modified files only:

```
src/app/features/users/revoke_moderator/
├── domain/
│   ├── commands.py             # target_username:str → target_user_id:int
│   ├── ports/
│   │   └── revoke_moderator_port.py  # get_by_username→get_by_id; revoke(target_user_id:int)
│   └── use_case.py             # get_by_id(target_user_id); revoke(target_user_id)
├── data/
│   └── adapter.py              # get_by_id queries User.id; revoke by User.id
└── presentation/
    └── router.py               # /users/{user_id}/revoke-moderator, int param, target_user_id=user_id
```

`domain/entities.py` (`RevokedUser`) and `presentation/schemas.py`
(`RevokeModeratorResponse`) are unchanged.

## 5. Implementation steps

### Step 1 — Domain: Command

**File:** `src/app/features/users/revoke_moderator/domain/commands.py`

Replace the `str` identifier field with an `int`. The requester field is
unchanged:

```python
class RevokeModeratorCommand(BaseModel):
    target_user_id: int
    requester_is_superuser: bool
```

### Step 2 — Domain: Port

**File:** `src/app/features/users/revoke_moderator/domain/ports/revoke_moderator_port.py`

Rename `get_by_username` → `get_by_id` and change `revoke`'s parameter:

```python
@runtime_checkable
class RevokeModeratorPort(Protocol):
    async def get_by_id(self, user_id: int) -> RevokedUser | None: ...

    async def revoke(self, target_user_id: int) -> RevokedUser: ...
```

The `@runtime_checkable` decorator and `Protocol` base remain mandatory (per
`agent_docs/architecture.md` § Terminology: port and adapter).

### Step 3 — Domain: Use case

**File:** `src/app/features/users/revoke_moderator/domain/use_case.py`

Two call sites change; the superuser check and the not-a-moderator check are
unchanged. Branch order is preserved (superuser → not-found → not-a-moderator):

```python
async def __call__(self, command: RevokeModeratorCommand) -> RevokedUser:
    if not command.requester_is_superuser:
        raise ForbiddenDomainError("Superuser privilege required")
    target = await self._port.get_by_id(command.target_user_id)
    if target is None:
        raise NotFoundDomainError("User not found")
    if not target.is_moderator:
        raise DuplicateValueDomainError("User is not a moderator")
    return await self._port.revoke(command.target_user_id)
```

No import changes.

### Step 4 — Data: Adapter

**File:** `src/app/features/users/revoke_moderator/data/adapter.py`

Replace `get_by_username` with `get_by_id` (query by `User.id`), and update
`revoke` to filter on `User.id`:

```python
async def get_by_id(self, user_id: int) -> RevokedUser | None:
    async with self._session_factory() as session:
        result = await session.execute(
            select(User).where(
                User.id == user_id,
                User.is_deleted == False,  # noqa: E712
            )
        )
        row = result.scalar_one_or_none()
    if row is None:
        return None
    return RevokedUser(
        id=row.id,
        name=row.name,
        username=row.username,
        email=row.email,
        profile_image_url=row.profile_image_url,
        tier_id=row.tier_id,
        is_moderator=row.is_moderator,
    )

async def revoke(self, target_user_id: int) -> RevokedUser:
    async with self._session_factory() as session:
        await session.execute(
            sa_update(User)
            .where(User.id == target_user_id)
            .values(is_moderator=False, moderator_granted_by_user_id=None)
        )
        await session.commit()
        result = await session.execute(select(User).where(User.id == target_user_id))
        row = result.scalar_one()
    return RevokedUser(
        id=row.id,
        name=row.name,
        username=row.username,
        email=row.email,
        profile_image_url=row.profile_image_url,
        tier_id=row.tier_id,
        is_moderator=row.is_moderator,
    )
```

No `try/except` is added. The UPDATE only sets `is_moderator=False` and clears
the `moderator_granted_by_user_id` FK; there is no unique-constraint or
business-meaningful FK path to translate, so any DB error propagates to the
global handler (per `agent_docs/error_handling.md` § Adapter: catch only when
there is business meaning to translate). This matches the existing
implementation, which has no catch.

The `from .....adapters.db.models.user import User` import (five dots) is
unchanged from the existing adapter.

### Step 5 — Presentation: Router

**File:** `src/app/features/users/revoke_moderator/presentation/router.py`

Two changes: path param name/type, and the command's identifier field. The
superuser dependency, the `/users/` path segment, and the response conversion
are unchanged:

```python
@router.patch(
    "/users/{user_id}/revoke-moderator",
    response_model=RevokeModeratorResponse,
    status_code=200,
)
@inject
async def revoke_moderator_endpoint(
    user_id: int,
    use_case: Annotated[RevokeModeratorUseCase, Depends(Provide[Container.revoke_moderator_use_case])],
    current_superuser: Annotated[dict, Depends(get_current_superuser)],
) -> RevokeModeratorResponse:
    command = RevokeModeratorCommand(
        target_user_id=user_id,
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

All import paths are unchanged.

### Step 6 — Tests: update all four levels

Update each test file under `tests/features/users/0016_revoke_moderator/` to use
integer IDs instead of username strings. No test file is deleted; all four
levels stay in place with updated fixtures and assertions.

- **`domain/test_use_case.py`**: change the mock port methods from
  `get_by_username` / `revoke(target_username)` to `get_by_id` /
  `revoke(target_user_id)`; update `RevokeModeratorCommand` to use
  `target_user_id=<int>`.
- **`data/test_adapter.py`**: update method calls to `get_by_id(int)` and
  `revoke(int)`; assert the lookup and the UPDATE filter on `User.id`.
- **`presentation/test_router.py`**: update the endpoint path from
  `/api/v1/users/{username}/revoke-moderator` to
  `/api/v1/users/{id}/revoke-moderator`; add a 422 case for a non-integer
  `user_id`.
- **`revoke_moderator_outside_in_test.py`**: capture the created (moderator)
  user's `id` and build the URL with it instead of the username.

### Step 7 — Verify

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

The slice is not done until all checks pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

Four levels, per `agent_docs/testing.md`:

- **Use-case unit test** — `tests/features/users/0016_revoke_moderator/domain/test_use_case.py` (modified).
  Mock `RevokeModeratorPort`. Assert:
  - `requester_is_superuser=False` → raises `ForbiddenDomainError`; `get_by_id`
    is never called.
  - `get_by_id` returns `None` → raises `NotFoundDomainError`.
  - `get_by_id` returns a `RevokedUser` with `is_moderator=False` → raises
    `DuplicateValueDomainError`.
  - Happy path (`is_moderator=True`) → `port.revoke(target_user_id)` is called
    and the returned `RevokedUser` is propagated.

- **Adapter unit test** — `tests/features/users/0016_revoke_moderator/data/test_adapter.py` (modified).
  Mock async session factory. Assert:
  - `get_by_id` returns a `RevokedUser` when a non-deleted row is found.
  - `get_by_id` returns `None` when the row is missing or `is_deleted == True`.
  - `revoke` executes an UPDATE by `User.id` setting `is_moderator = False` and
    `moderator_granted_by_user_id = None`, then returns the refreshed
    `RevokedUser`.
  - Any DB exception propagates unchanged.

- **Endpoint integration test** — `tests/features/users/0016_revoke_moderator/presentation/test_router.py` (modified).
  `httpx.AsyncClient` against test Postgres. Assert:
  - Superuser PATCH to `/api/v1/users/{id}/revoke-moderator` on a moderator →
    `200` with `is_moderator: false`.
  - Second call on the same (now non-moderator) user → `409`.
  - Non-existent `user_id` → `404`.
  - Authenticated non-superuser → `403`.
  - Missing/invalid token → `401`.
  - Non-integer path param (e.g. `"abc"`) → `422`.

- **Outside-in test** — `tests/features/users/0016_revoke_moderator/revoke_moderator_outside_in_test.py` (modified).
  Full HTTP stack: real adapter, test Postgres. Creates a user, grants moderator
  (via the slice 0046 `/api/v1/user/{id}/assign-moderator` endpoint), captures
  its `id`, calls the revoke endpoint as superuser asserting `200` and
  `is_moderator: false`, then verifies via `GET` by id that `is_moderator` is
  `false`.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Assign moderator (`assign_moderator`) — slice 0046.
- Other routes in the `{username}` → `{user_id}` migration series (0041–0050, 0042).
- The slice 0016 outside-in test URL update for any other slice — only the 0016
  test files are updated here.
- Cache invalidation — not applicable; this is an authenticated write endpoint.
- Rate limiting — not applied; the endpoint is behind superuser auth.

## 8. Open questions

None.
