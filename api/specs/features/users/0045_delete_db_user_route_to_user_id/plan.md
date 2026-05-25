# 0045 · delete_db_user_route_to_user_id — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0045_delete_db_user_route_to_user_id
- **PRD:** ./prd.md
- **Reference slice:** `../0044_delete_user_route_to_user_id/plan.md` — the most recent slice with the same operation shape (a `{username}` → `{user_id}` route migration on a delete endpoint). The slice being modified in place is `delete_db_user` (slice 0008); its source under `src/app/features/users/delete_db_user/` is the second reference.
- **HTTP path:** `DELETE /api/v1/db_user/{user_id}`
- **STABLE files touched:** none. `bootstrap/container.py` already wires `delete_db_user_adapter` / `delete_db_user_use_case`, and `bootstrap/router.py` already registers the users router. No new providers or registrations are needed; only the path string and param type on the existing route change.

## 2. Context summary

Slice 0045 migrates the existing `DELETE /db_user/{username}` route to
`DELETE /db_user/{user_id}`. No new slice folder is created; the existing
`features/users/delete_db_user/` slice is modified in place. This is a
superuser-only **hard delete**: there is no ownership check and no token
blacklisting. Every layer below the auth boundary is touched: the command's
single identifier field changes from `target_username: str` to
`target_user_id: int`, the lookup entity changes from `username: str` to
`id: int`, the port replaces `get_by_username` with `get_by_id` and changes the
`db_delete` parameter type, the adapter queries and deletes by primary key, the
use-case calls `get_by_id` / `db_delete` with the integer ID, and the router
changes the path param type from `str` to `int`. The adapter keeps its existing
`IntegrityError → DuplicateValueDomainError` translation (a hard delete can hit
a foreign-key dependent-records constraint). The `{"message": "User deleted from
the database"}` response body is unchanged.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the account to hard-delete |

**Request body:** none.

**Response body** (`DeleteDbUserResponse` — unchanged):

| Field | Type | Notes |
|---|---|---|
| `message` | `str` | Always `"User deleted from the database"` on success |

**Status codes:**

- `200 OK` — row hard-deleted.
- `401 Unauthorized` — missing or invalid token (from `get_current_superuser`).
- `403 Forbidden` — authenticated but not a superuser (from `get_current_superuser`; not raised by the use-case).
- `404 Not Found` — `NotFoundDomainError`; `user_id` not found.
- `409 Conflict` — `DuplicateValueDomainError`; the row has dependent records and cannot be hard-deleted (`IntegrityError` translated in the adapter).
- `422 Unprocessable Entity` — FastAPI/Pydantic rejects a non-integer path param.

## 4. File structure

No new files. Modified files only:

```
src/app/features/users/delete_db_user/
├── domain/
│   ├── commands.py             # target_username: str → target_user_id: int
│   ├── entities.py             # DbDeleteUserTarget.username: str → .id: int
│   ├── ports/
│   │   └── delete_db_user_port.py  # get_by_username → get_by_id; db_delete param str → int
│   └── use_case.py             # use get_by_id / db_delete with the integer ID
├── data/
│   └── adapter.py              # get_by_id queries User.id; db_delete by User.id (keep IntegrityError catch)
└── presentation/
    └── router.py               # /db_user/{user_id}, int param, target_user_id=user_id
```

No `_shared/` change: this endpoint is superuser-only and performs no ownership
comparison, so `_shared/policies.py` is not involved.

## 5. Implementation steps

### Step 1 — Domain: Command

**File:** `src/app/features/users/delete_db_user/domain/commands.py`

Replace the single `str` field with `int`:

```python
class DeleteDbUserCommand(BaseModel):
    target_user_id: int
```

### Step 2 — Domain: Entity

**File:** `src/app/features/users/delete_db_user/domain/entities.py`

The lookup target no longer needs `username`. Change the field:

```python
class DbDeleteUserTarget(BaseModel):
    id: int
```

`DeleteDbUserResult` is unchanged
(`message: str = "User deleted from the database"`).

### Step 3 — Domain: Port

**File:** `src/app/features/users/delete_db_user/domain/ports/delete_db_user_port.py`

Replace both method signatures:

```python
@runtime_checkable
class DeleteDbUserPort(Protocol):
    async def get_by_id(self, user_id: int) -> DbDeleteUserTarget | None: ...
    async def db_delete(self, target_user_id: int) -> None: ...
```

The `@runtime_checkable` decorator and `Protocol` base remain mandatory (per
`agent_docs/architecture.md` § Terminology: port and adapter).

### Step 4 — Domain: Use case

**File:** `src/app/features/users/delete_db_user/domain/use_case.py`

Two call sites change; the `NotFoundDomainError` branch is unchanged:

```python
async def __call__(self, command: DeleteDbUserCommand) -> DeleteDbUserResult:
    target = await self._port.get_by_id(command.target_user_id)
    if target is None:
        raise NotFoundDomainError("User not found")
    await self._port.db_delete(command.target_user_id)
    return DeleteDbUserResult()
```

No new imports. The existing `from .....domain.errors import NotFoundDomainError`
import path is unchanged.

### Step 5 — Data: Adapter

**File:** `src/app/features/users/delete_db_user/data/adapter.py`

Replace `get_by_username` with `get_by_id` and update `db_delete` to target the
primary key. Keep the existing `IntegrityError → DuplicateValueDomainError`
translation around the delete + commit:

```python
async def get_by_id(self, user_id: int) -> DbDeleteUserTarget | None:
    async with self._session_factory() as session:
        result = await session.execute(select(User).where(User.id == user_id))
        row = result.scalar_one_or_none()
        if row is None:
            return None
        return DbDeleteUserTarget(id=row.id)

async def db_delete(self, target_user_id: int) -> None:
    async with self._session_factory() as session:
        try:
            await session.execute(delete(User).where(User.id == target_user_id))
            await session.commit()
        except IntegrityError as exc:
            raise DuplicateValueDomainError("User has dependent records") from exc
```

The `IntegrityError` catch is business-meaningful (a foreign-key dependent
prevents the hard delete) and is retained per `agent_docs/error_handling.md`
§ Adapter: catch only when there is business meaning to translate. No
`try/except Exception` is added; any other DB error propagates to the global
handler.

### Step 6 — Presentation: Router

**File:** `src/app/features/users/delete_db_user/presentation/router.py`

Change the path string, the path-param name/type, and the command construction.
The `get_current_superuser` dependency is unchanged:

```python
@router.delete("/db_user/{user_id}", response_model=DeleteDbUserResponse, status_code=200)
@inject
async def delete_db_user_endpoint(
    user_id: int,
    use_case: Annotated[DeleteDbUserUseCase, Depends(Provide[Container.delete_db_user_use_case])],
    _: Annotated[dict, Depends(get_current_superuser)],
) -> DeleteDbUserResponse:
    command = DeleteDbUserCommand(target_user_id=user_id)
    result = await use_case(command)
    return DeleteDbUserResponse(message=result.message)
```

All import paths are unchanged (they already resolve correctly via relative
imports from `presentation/router.py`).

### Step 7 — Tests: update all four levels

Update each test file under `tests/features/users/0008_delete_db_user/` to use
an integer ID instead of a username string. No test file is deleted; all four
levels stay in place with updated fixtures and assertions.

- **`domain/test_use_case.py`**: change the mock port methods from
  `get_by_username` / `db_delete(str)` to `get_by_id` / `db_delete(int)`;
  update the `DeleteDbUserCommand` field to `target_user_id` and the
  `DbDeleteUserTarget` field to `id`.
- **`data/test_adapter.py`**: update method calls to `get_by_id(int)` and
  `db_delete(int)`; update the return-value assertion on `DbDeleteUserTarget`;
  keep the `IntegrityError → DuplicateValueDomainError` test case.
- **`presentation/test_router.py`**: change the endpoint path from
  `/api/v1/db_user/{username}` to `/api/v1/db_user/{id}`; add a 422 case for a
  non-integer `user_id`.
- **`delete_db_user_outside_in_test.py`**: capture the created user's `id`;
  replace the username-formatted URL with the `user_id`-formatted URL.

### Step 8 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/users/0008_delete_db_user/delete_db_user_outside_in_test.py -v
```

The slice is not done until all checks pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** — `tests/features/users/0008_delete_db_user/domain/test_use_case.py` (modified).
  Mock `DeleteDbUserPort`. Assert:
  - `get_by_id` returns `None` → raises `NotFoundDomainError`; `db_delete` is not called.
  - `get_by_id` returns a `DbDeleteUserTarget` → `port.db_delete(target_user_id)`
    is called with the integer ID and `DeleteDbUserResult(message="User deleted
    from the database")` is returned.

- **Adapter unit test** — `tests/features/users/0008_delete_db_user/data/test_adapter.py` (modified).
  Mock async session factory. Assert:
  - `get_by_id` returns `DbDeleteUserTarget(id=...)` when a row is found.
  - `get_by_id` returns `None` when the row is missing.
  - `db_delete` executes a DELETE by `User.id`.
  - `IntegrityError` raised during `db_delete` is translated to
    `DuplicateValueDomainError`.
  - Any other DB exception from `db_delete` propagates unchanged.

- **Endpoint integration test** — `tests/features/users/0008_delete_db_user/presentation/test_router.py` (modified).
  `httpx.AsyncClient` against test Postgres. Assert:
  - Superuser DELETE to `/api/v1/db_user/{id}` → `200 {"message": "User deleted
    from the database"}`; the row is gone afterwards.
  - Non-existent `user_id` → `404`.
  - Authenticated non-superuser → `403`.
  - Missing/invalid token → `401`.
  - Non-integer path param (e.g. `"abc"`) → `422`.

- **Outside-in test** — `tests/features/users/0008_delete_db_user/delete_db_user_outside_in_test.py` (modified).
  Full HTTP stack: real adapter, test Postgres. Create a user and capture `id`;
  as superuser call `DELETE /db_user/{id}` and assert `200`; then `GET
  /user/{id}` and assert `404` (the row is gone).

**Opt-outs:** none.

## 7. Out of scope for this slice

- Soft delete (`DELETE /user/{user_id}`) — slice 0044.
- Other routes in the `{username}` → `{user_id}` migration series (slices 0041–0043, 0046–0050).
- Cache invalidation — not applicable; this is an authenticated write endpoint.
- Rate limiting — not applied; the endpoint is behind superuser auth.
- Any change to `_shared/policies.py` — this endpoint performs no ownership check.

## 8. Open questions

None. The `403` path is enforced by the `get_current_superuser` dependency at
the transport boundary, not by the use-case, so no `DomainError` or domain
change is required for it.
