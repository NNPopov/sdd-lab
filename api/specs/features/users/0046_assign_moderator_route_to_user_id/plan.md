# 0046 · assign_moderator_route_to_user_id — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0046_assign_moderator_route_to_user_id
- **PRD:** ./prd.md
- **Reference slice:** `../0044_delete_user_route_to_user_id/plan.md` — closest structural match (same `{username}` → `{user_id}` migration shape). The slice being modified is `0015_assign_moderator` (`src/app/features/users/assign_moderator/`).
- **HTTP path:** `PATCH /api/v1/user/{user_id}/assign-moderator`
- **STABLE files touched:** none. `bootstrap/container.py` already wires `assign_moderator_use_case` / `assign_moderator_adapter`, the users router already registers the route, and `Container.wiring_config` already lists the router module. No new providers, registrations, or `.importlinter` entries are needed.

## 2. Context summary

Slice 0046 migrates the existing `PATCH /user/{username}/assign-moderator` route to
`PATCH /user/{user_id}/assign-moderator`. No new slice folder is created; the
existing `features/users/assign_moderator/` slice is modified in place. The
command's identifier field changes from `target_username: str` to
`target_user_id: int` (`requester_id` and `requester_is_superuser` are
unchanged); the port replaces `get_by_username` with `get_by_id` and changes
`assign`'s first parameter to `target_user_id: int`; the adapter looks up and
updates by `User.id`; the router changes the path param type from `str` to `int`
and passes `target_user_id=user_id`. Superuser-only authorization, the
already-moderator 409 check, the `AssignedUser` entity, and the response body are
all unchanged.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the account being granted moderator status |

**Request body:** none.

**Response body** (`AssignModeratorResponse` — unchanged):

| Field | Type | Notes |
|---|---|---|
| `id` | `int` | Target user's primary key |
| `name` | `str` | |
| `username` | `str` | |
| `email` | `str` | |
| `profile_image_url` | `str` | |
| `tier_id` | `int \| None` | |
| `is_moderator` | `bool` | `true` after a successful assignment |

**Status codes:**

- `200 OK` — moderator role granted; updated profile returned.
- `401 Unauthorized` — missing or invalid token.
- `403 Forbidden` — `ForbiddenDomainError`; requester is not a superuser.
- `404 Not Found` — `NotFoundDomainError`; `user_id` not found (or soft-deleted).
- `409 Conflict` — `DuplicateValueDomainError`; target user is already a moderator.
- `422 Unprocessable Entity` — FastAPI/Pydantic rejects a non-integer path param.

## 4. File structure

No new files. Modified files only:

```
src/app/features/users/assign_moderator/
├── domain/
│   ├── commands.py             # target_username:str → target_user_id:int
│   ├── ports/
│   │   └── assign_moderator_port.py  # get_by_username→get_by_id; assign(target_user_id:int, ...)
│   └── use_case.py             # get_by_id(target_user_id); assign(target_user_id, requester_id)
├── data/
│   └── adapter.py              # get_by_id queries User.id; assign by User.id
└── presentation/
    └── router.py               # /user/{user_id}/assign-moderator, int param, target_user_id=user_id
```

`domain/entities.py` (`AssignedUser`) and `presentation/schemas.py`
(`AssignModeratorResponse`) are unchanged.

## 5. Implementation steps

### Step 1 — Domain: Command

**File:** `src/app/features/users/assign_moderator/domain/commands.py`

Replace the `str` identifier field with an `int`. The two requester fields are
unchanged:

```python
class AssignModeratorCommand(BaseModel):
    target_user_id: int
    requester_id: int
    requester_is_superuser: bool
```

### Step 2 — Domain: Port

**File:** `src/app/features/users/assign_moderator/domain/ports/assign_moderator_port.py`

Rename `get_by_username` → `get_by_id` and change `assign`'s first parameter:

```python
@runtime_checkable
class AssignModeratorPort(Protocol):
    async def get_by_id(self, user_id: int) -> AssignedUser | None: ...

    async def assign(self, target_user_id: int, granted_by_user_id: int) -> AssignedUser: ...
```

The `@runtime_checkable` decorator and `Protocol` base remain mandatory (per
`agent_docs/architecture.md` § Terminology: port and adapter).

### Step 3 — Domain: Use case

**File:** `src/app/features/users/assign_moderator/domain/use_case.py`

Two call sites change; the superuser check and the already-moderator check are
unchanged. Branch order is preserved (superuser → not-found → already-moderator):

```python
async def __call__(self, command: AssignModeratorCommand) -> AssignedUser:
    if not command.requester_is_superuser:
        raise ForbiddenDomainError("Superuser privilege required")
    target = await self._port.get_by_id(command.target_user_id)
    if target is None:
        raise NotFoundDomainError("User not found")
    if target.is_moderator:
        raise DuplicateValueDomainError("User is already a moderator")
    return await self._port.assign(command.target_user_id, command.requester_id)
```

No import changes.

### Step 4 — Data: Adapter

**File:** `src/app/features/users/assign_moderator/data/adapter.py`

Replace `get_by_username` with `get_by_id` (query by `User.id`), and update
`assign` to filter on `User.id`:

```python
async def get_by_id(self, user_id: int) -> AssignedUser | None:
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
    return AssignedUser(
        id=row.id,
        name=row.name,
        username=row.username,
        email=row.email,
        profile_image_url=row.profile_image_url,
        tier_id=row.tier_id,
        is_moderator=row.is_moderator,
    )

async def assign(self, target_user_id: int, granted_by_user_id: int) -> AssignedUser:
    async with self._session_factory() as session:
        await session.execute(
            sa_update(User)
            .where(User.id == target_user_id)
            .values(is_moderator=True, moderator_granted_by_user_id=granted_by_user_id)
        )
        await session.commit()
        result = await session.execute(select(User).where(User.id == target_user_id))
        row = result.scalar_one()
    return AssignedUser(
        id=row.id,
        name=row.name,
        username=row.username,
        email=row.email,
        profile_image_url=row.profile_image_url,
        tier_id=row.tier_id,
        is_moderator=row.is_moderator,
    )
```

No `try/except` is added. The UPDATE sets `is_moderator` and an FK
(`moderator_granted_by_user_id`) that always references the authenticated
superuser, so there is no unique-constraint or business-meaningful FK path to
translate; any DB error propagates to the global handler (per
`agent_docs/error_handling.md` § Adapter: catch only when there is business
meaning to translate). This matches the existing implementation, which has no
catch.

### Step 5 — Presentation: Router

**File:** `src/app/features/users/assign_moderator/presentation/router.py`

Two changes: path param name/type, and the command's identifier field. The
superuser dependency and the response conversion are unchanged:

```python
@router.patch(
    "/user/{user_id}/assign-moderator",
    response_model=AssignModeratorResponse,
    status_code=200,
)
@inject
async def assign_moderator_endpoint(
    user_id: int,
    use_case: Annotated[AssignModeratorUseCase, Depends(Provide[Container.assign_moderator_use_case])],
    current_superuser: Annotated[dict, Depends(get_current_superuser)],
) -> AssignModeratorResponse:
    command = AssignModeratorCommand(
        target_user_id=user_id,
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

All import paths are unchanged.

### Step 6 — Tests: update all four levels

Update each test file under `tests/features/users/0015_assign_moderator/` to use
integer IDs instead of username strings. No test file is deleted; all four
levels stay in place with updated fixtures and assertions.

- **`domain/test_use_case.py`**: change the mock port methods from
  `get_by_username` / `assign(target_username, ...)` to `get_by_id` /
  `assign(target_user_id, ...)`; update `AssignModeratorCommand` to use
  `target_user_id=<int>`.
- **`data/test_adapter.py`**: update method calls to `get_by_id(int)` and
  `assign(int, int)`; assert the UPDATE filters on `User.id`.
- **`presentation/test_router.py`**: update the endpoint path from
  `/api/v1/user/{username}/assign-moderator` to
  `/api/v1/user/{id}/assign-moderator`; add a 422 case for a non-integer
  `user_id`.
- **`assign_moderator_outside_in_test.py`**: capture the created user's `id` and
  build the URL with it instead of the username.

### Step 7 — Verify

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

The slice is not done until all checks pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

Four levels, per `agent_docs/testing.md`:

- **Use-case unit test** — `tests/features/users/0015_assign_moderator/domain/test_use_case.py` (modified).
  Mock `AssignModeratorPort`. Assert:
  - `requester_is_superuser=False` → raises `ForbiddenDomainError`; `get_by_id`
    is never called.
  - `get_by_id` returns `None` → raises `NotFoundDomainError`.
  - `get_by_id` returns an `AssignedUser` with `is_moderator=True` → raises
    `DuplicateValueDomainError`.
  - Happy path → `port.assign(target_user_id, requester_id)` is called and the
    returned `AssignedUser` is propagated.

- **Adapter unit test** — `tests/features/users/0015_assign_moderator/data/test_adapter.py` (modified).
  Mock async session factory. Assert:
  - `get_by_id` returns an `AssignedUser` when a non-deleted row is found.
  - `get_by_id` returns `None` when the row is missing or `is_deleted == True`.
  - `assign` executes an UPDATE by `User.id` setting `is_moderator = True` and
    `moderator_granted_by_user_id`, then returns the refreshed `AssignedUser`.
  - Any DB exception propagates unchanged.

- **Endpoint integration test** — `tests/features/users/0015_assign_moderator/presentation/test_router.py` (modified).
  `httpx.AsyncClient` against test Postgres. Assert:
  - Superuser PATCH to `/api/v1/user/{id}/assign-moderator` → `200` with
    `is_moderator: true`.
  - Second call on the same user → `409`.
  - Non-existent `user_id` → `404`.
  - Authenticated non-superuser → `403`.
  - Missing/invalid token → `401`.
  - Non-integer path param (e.g. `"abc"`) → `422`.

- **Outside-in test** — `tests/features/users/0015_assign_moderator/assign_moderator_outside_in_test.py` (modified).
  Full HTTP stack: real adapter, test Postgres. Creates a non-moderator user,
  captures its `id`, calls the endpoint as superuser asserting `200` and
  `is_moderator: true`, then calls again asserting `409`.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Revoke moderator (`remove_moderator`) — slice 0047.
- Other routes in the `{username}` → `{user_id}` migration series.
- The slice 0015 outside-in test URL update for any other slice — only the 0015
  test files are updated here.
- Cache invalidation — not applicable; this is an authenticated write endpoint.
- Rate limiting — not applied; the endpoint is behind superuser auth.

## 8. Open questions

None.
