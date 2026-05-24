# 0044 · delete_user_route_to_user_id — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0044_delete_user_route_to_user_id
- **PRD:** ./prd.md
- **Reference slice:** `../0007_delete_user/plan.md` — the slice being modified; also the closest structural match for the same operation type.
- **HTTP path:** `DELETE /api/v1/user/{user_id}`
- **STABLE files touched:** none. `bootstrap/container.py` and `bootstrap/router.py` already wire `delete_user_use_case` / `delete_user_adapter` and register the users router. No new providers or registrations are needed.

## 2. Context summary

Slice 0044 migrates the existing `DELETE /user/{username}` route to
`DELETE /user/{user_id}`. No new slice folder is created; the existing
`features/users/delete_user/` slice is modified in place. Every layer is
touched: the command's identifier fields change from `str` to `int`, the port
replaces `get_by_username` with `get_by_id`, the adapter queries by primary key,
the use-case calls `check_owner` with integer IDs, and the router changes the
path param type from `str` to `int` and reads `current_user["id"]` instead of
`current_user["username"]`. The `_shared/policies.py` ownership check is updated
to compare integers; this change also serves slice 0043, which shares
`check_owner`. Token blacklisting and the `{"message": "User deleted"}` response
body are unchanged.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the account to delete |

**Request body:** none.

**Response body** (`DeleteUserResponse` — unchanged):

| Field | Type | Notes |
|---|---|---|
| `message` | `str` | Always `"User deleted"` on success |

**Status codes:**

- `200 OK` — soft-delete applied and JWT blacklisted.
- `401 Unauthorized` — missing, invalid, or blacklisted token.
- `403 Forbidden` — `ForbiddenDomainError`; requester's ID does not match target's ID.
- `404 Not Found` — `NotFoundDomainError`; `user_id` not found or already soft-deleted.
- `422 Unprocessable Entity` — FastAPI/Pydantic rejects a non-integer path param.

## 4. File structure

No new files. Modified files only:

```
src/app/features/users/delete_user/
├── domain/
│   ├── commands.py             # target_username→target_user_id, requester_username→requester_user_id
│   ├── entities.py             # DeleteUserTarget.username:str → .id:int
│   ├── ports/
│   │   └── delete_user_port.py # get_by_username→get_by_id, soft_delete param type
│   └── use_case.py             # use get_by_id, check_owner with int IDs
├── data/
│   └── adapter.py              # get_by_id queries User.id; soft_delete by User.id
└── presentation/
    └── router.py               # /user/{user_id}, int param, current_user["id"]

src/app/features/users/
└── _shared/
    └── policies.py             # check_owner(str,str) → check_owner(int,int)
```

## 5. Implementation steps

### Step 1 — Domain: Command

**File:** `src/app/features/users/delete_user/domain/commands.py`

Replace both `str` fields with `int`:

```python
class DeleteUserCommand(BaseModel):
    target_user_id: int
    requester_user_id: int
```

### Step 2 — Domain: Entity

**File:** `src/app/features/users/delete_user/domain/entities.py`

`DeleteUserTarget` no longer needs `username`; the ownership check now compares
integer IDs. Change the field:

```python
class DeleteUserTarget(BaseModel):
    id: int
```

`DeleteUserResult` is unchanged (`message: str = "User deleted"`).

### Step 3 — Domain: Port

**File:** `src/app/features/users/delete_user/domain/ports/delete_user_port.py`

Replace both method signatures:

```python
@runtime_checkable
class DeleteUserPort(Protocol):
    async def get_by_id(self, user_id: int) -> DeleteUserTarget | None: ...
    async def soft_delete(self, target_user_id: int) -> None: ...
```

The `@runtime_checkable` decorator and `Protocol` base remain mandatory (per
`agent_docs/architecture.md` § Terminology: port and adapter).

### Step 4 — Domain: Use case

**File:** `src/app/features/users/delete_user/domain/use_case.py`

Three call sites change:

```python
async def __call__(self, command: DeleteUserCommand) -> DeleteUserResult:
    target = await self._port.get_by_id(command.target_user_id)
    if target is None:
        raise NotFoundDomainError("User not found")

    check_owner(command.requester_user_id, target.id)

    await self._port.soft_delete(command.target_user_id)
    return DeleteUserResult()
```

No new imports. The `check_owner` import path stays the same:
`from ..._shared.policies import check_owner` (three dots: `domain/` → `delete_user/` → `users/`).

### Step 5 — Data: Adapter

**File:** `src/app/features/users/delete_user/data/adapter.py`

Replace `get_by_username` with `get_by_id` and update `soft_delete`:

```python
async def get_by_id(self, user_id: int) -> DeleteUserTarget | None:
    async with self._session_factory() as session:
        result = await session.execute(
            select(User).where(User.id == user_id, User.is_deleted == False)  # noqa: E712
        )
        row = result.scalar_one_or_none()
        if row is None:
            return None
        return DeleteUserTarget(id=row.id)

async def soft_delete(self, target_user_id: int) -> None:
    async with self._session_factory() as session:
        await session.execute(
            update(User)
            .where(User.id == target_user_id)
            .values(is_deleted=True, deleted_at=datetime.now(UTC))
        )
        await session.commit()
```

No new `try/except`. A soft-delete UPDATE has no unique-constraint path to catch;
any DB error propagates to the global handler (per `agent_docs/error_handling.md`
§ Adapter: catch only when there is business meaning to translate).

### Step 6 — Presentation: Router

**File:** `src/app/features/users/delete_user/presentation/router.py`

Three changes: path param name/type, and command construction:

```python
@router.delete("/user/{user_id}", response_model=DeleteUserResponse, status_code=200)
@inject
async def delete_user_endpoint(
    user_id: int,
    current_user: Annotated[dict, Depends(get_current_user)],
    token: Annotated[str, Depends(oauth2_scheme)],
    use_case: Annotated[DeleteUserUseCase, Depends(Provide[Container.delete_user_use_case])],
    blacklist: Annotated[TokenBlacklistPort, Depends(Provide[Container.token_blacklist_adapter])],
) -> DeleteUserResponse:
    command = DeleteUserCommand(
        target_user_id=user_id,
        requester_user_id=current_user["id"],
    )
    await use_case(command)
    await blacklist_token(token, blacklist)
    return DeleteUserResponse(message="User deleted")
```

All import paths are unchanged (they already resolve correctly via relative
imports from `presentation/router.py`).

### Step 7 — Shared: policies.py

**File:** `src/app/features/users/_shared/policies.py`

Update `check_owner` to compare integer IDs:

```python
def check_owner(requester_id: int, owner_id: int) -> None:
    if requester_id != owner_id:
        raise ForbiddenDomainError()
```

This is a FEATURE file (`# FEATURE: users._shared — ownership policy.`).
Slice 0043 (`update_user_route_to_user_id`) also calls `check_owner`; whichever
of 0043 / 0044 lands first applies this change. The other slice inherits it
without further modification to `policies.py`.

### Step 8 — Tests: update all four levels

Update each test file under `tests/features/users/0007_delete_user/` to use
integer IDs instead of username strings. No test file is deleted; all four
levels stay in place with updated fixtures and assertions.

- **`domain/test_use_case.py`**: change mock port methods from
  `get_by_username` / `soft_delete(str)` to `get_by_id` / `soft_delete(int)`;
  update `DeleteUserCommand` field names and `DeleteUserTarget` field.
- **`data/test_adapter.py`**: update method calls to `get_by_id(int)` and
  `soft_delete(int)`; update return-value assertions on `DeleteUserTarget`.
- **`presentation/test_router.py`**: update endpoint path from
  `/api/v1/user/{username}` to `/api/v1/user/{id}`; update command field
  names in any direct assertions; add a 422 case for non-integer `user_id`.
- **`delete_user_outside_in_test.py`**: capture `seeded_alice["id"]` and
  `seeded_bob["id"]`; replace `_ENDPOINT.format(username=...)` with
  `_ENDPOINT.format(user_id=...)`; update the raw-SQL assertions (they already
  query by username, so no SQL change is needed — only the URL changes).

### Step 9 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/users/0007_delete_user/delete_user_outside_in_test.py -v
```

The slice is not done until all checks pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** — `tests/features/users/0007_delete_user/domain/test_use_case.py` (modified).
  Mock `DeleteUserPort`. Assert:
  - `get_by_id` returns `None` → raises `NotFoundDomainError`.
  - `get_by_id` returns a `DeleteUserTarget` whose `id` differs from
    `requester_user_id` → raises `ForbiddenDomainError`.
  - Both checks pass → `port.soft_delete(target_user_id)` is called and
    `DeleteUserResult(message="User deleted")` is returned.

- **Adapter unit test** — `tests/features/users/0007_delete_user/data/test_adapter.py` (modified).
  Mock async session factory. Assert:
  - `get_by_id` returns `DeleteUserTarget(id=...)` when row found with
    `is_deleted == False`.
  - `get_by_id` returns `None` when row is missing or `is_deleted == True`.
  - `soft_delete` executes an UPDATE by `User.id` setting `is_deleted = True`
    and `deleted_at` to a non-null datetime.
  - Any DB exception from `soft_delete` propagates unchanged.

- **Endpoint integration test** — `tests/features/users/0007_delete_user/presentation/test_router.py` (modified).
  `httpx.AsyncClient` against test Postgres. Assert:
  - Authenticated DELETE to `/api/v1/user/{id}`, owner → `200 {"message": "User deleted"}`.
  - User row has `is_deleted == True` after the request.
  - Non-existent `user_id` → `404`.
  - Valid token but wrong user → `403`.
  - Missing/invalid token → `401`.
  - Non-integer path param (e.g. `"abc"`) → `422`.

- **Outside-in test** — `tests/features/users/0007_delete_user/delete_user_outside_in_test.py` (modified).
  Full HTTP stack: real adapter, real `TokenBlacklistService`, test Postgres.
  Uses `seeded_alice["id"]` and `seeded_bob["id"]` in the URL. DB assertions
  (query by `username` in raw SQL) are unchanged. Token blacklist assertion is
  unchanged.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Hard delete (`DELETE /db_user/{user_id}`) — slice 0045.
- Other routes in the `{username}` → `{user_id}` migration series (slices 0043, 0045–0050).
- Updating any existing test fixtures shared across slices — only the 0007
  test files are updated here.
- Cache invalidation — not applicable; this is an authenticated write endpoint.
- Rate limiting — not applied; the endpoint is behind auth.

## 8. Open questions

- **`check_owner` coordination with 0043.** Both slices require the integer
  signature. If they land in the same PR, `policies.py` is updated once and
  both slices inherit the change. If they land separately, whichever lands
  first owns the `policies.py` change; the other slice's test suite must be
  green on the already-updated signature. No action needed at planning time;
  this is a sequencing concern for the PR author.
