# 0043 · update_user_route_to_user_id — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0043_update_user_route_to_user_id
- **PRD:** ./prd.md
- **Reference slice:** `../0006_update_user/plan.md` — this slice modifies the exact files introduced by 0006; used as the structural baseline.
- **HTTP path:** `PATCH /user/{user_id}` (was `/user/{username}`)
- **STABLE files touched:**
  - `bootstrap/container.py` — no new providers; the existing `update_user_adapter` and `update_user_use_case` providers stay; their import paths are unchanged.

## 2. Context summary

Slice 0043 migrates the `PATCH /user/{username}` route to `PATCH /user/{user_id}`. The target user is now identified by integer primary key. The `UpdateUserCommand` fields `target_username` and `requester_username` are replaced with `target_user_id: int` and `requester_user_id: int`. The `UpdateUserPort` method `get_by_username` is replaced with `get_by_id`. The `_shared/policies.py` function `check_owner` signature changes from `(str, str)` to `(int, int)`. The router reads `user_id: int` from the path and `current_user["id"]` from the auth dict. The response body (`{"message": "User updated"}`) and HTTP status codes are unchanged. No ORM model changes; no Alembic migration.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the user to update |

**Request body** (`UpdateUserRequest`) — unchanged:

| Field | Type | Validation |
|---|---|---|
| `name` | `str \| None` | `min_length=2`, `max_length=30`, default `None` |
| `username` | `str \| None` | `min_length=2`, `max_length=20`, `pattern=r"^[a-z0-9_]+$"`, default `None` |
| `email` | `EmailStr \| None` | valid e-mail, default `None` |
| `profile_image_url` | `str \| None` | URL, default `None` |

**Response body** (`UpdateUserResponse`) — unchanged:

| Field | Type |
|---|---|
| `message` | `str` |

**Status codes:**

- `200 OK` — update applied; `{"message": "User updated"}`.
- `401 Unauthorized` — missing or invalid JWT.
- `403 Forbidden` — `ForbiddenDomainError`; `requester_user_id != target_user_id`.
- `404 Not Found` — `NotFoundDomainError`; no non-deleted user with that `id`.
- `409 Conflict` — `DuplicateValueDomainError`; new email or username already taken.
- `422 Unprocessable Entity` — Pydantic validation failure (non-integer `user_id`, field constraints).

## 4. File structure

No new files. All changes are in-place modifications of the existing slice files.

Files modified:

```
src/app/features/users/_shared/policies.py
    check_owner(str, str) → check_owner(int, int)

src/app/features/users/update_user/domain/commands.py
    target_username: str → target_user_id: int
    requester_username: str → requester_user_id: int

src/app/features/users/update_user/domain/entities.py
    ExistingUser: add `id: int`, retain `username: str` and `email: str`

src/app/features/users/update_user/domain/ports/update_user_port.py
    get_by_username(username: str) → get_by_id(user_id: int)

src/app/features/users/update_user/domain/use_case.py
    call get_by_id; compare IDs via check_owner; pass target_user_id to update

src/app/features/users/update_user/data/adapter.py
    get_by_id(user_id: int) replaces get_by_username; WHERE clause uses User.id
    update() WHERE clause changes to User.id == command.target_user_id
    excluded fields in update dict change to ("target_user_id", "requester_user_id")

src/app/features/users/update_user/presentation/router.py
    path param: {username}: str → {user_id}: int
    command construction uses target_user_id and requester_user_id
```

No changes to `bootstrap/container.py`, `bootstrap/router.py`, or `presentation/schemas.py`.

## 5. Implementation steps

### Step 1 — Shared policy: update `check_owner` signature

**File:** `src/app/features/users/_shared/policies.py`

Change signature from `(requester_username: str, owner_username: str)` to `(requester_user_id: int, owner_user_id: int)`. The comparison body `if requester_user_id != owner_user_id` is functionally identical. The `ForbiddenDomainError()` raise is unchanged.

After this step the existing `update_user` use case will be temporarily broken until Step 5 updates it. Per the PRD, any other caller of `check_owner` (e.g. `delete_user`) must be migrated in the same wave.

### Step 2 — Domain: update `UpdateUserCommand`

**File:** `src/app/features/users/update_user/domain/commands.py`

Replace:
- `target_username: str` → `target_user_id: int`
- `requester_username: str` → `requester_user_id: int`

All other fields (`name`, `username`, `email`, `profile_image_url`) are unchanged.

### Step 3 — Domain: update `ExistingUser` entity

**File:** `src/app/features/users/update_user/domain/entities.py`

Add `id: int` to `ExistingUser`. Retain `username: str` and `email: str` — the use case uses `username` to skip the duplicate-username check when the value is unchanged, and `email` for the same skip on the email check.

Final shape:
```python
class ExistingUser(BaseModel):
    id: int
    username: str
    email: str
```

`UpdatedUserResult` is unchanged.

### Step 4 — Domain: update `UpdateUserPort`

**File:** `src/app/features/users/update_user/domain/ports/update_user_port.py`

Replace method:
```python
async def get_by_username(self, username: str) -> ExistingUser | None: ...
```
with:
```python
async def get_by_id(self, user_id: int) -> ExistingUser | None: ...
```

`email_exists`, `username_exists`, and `update` signatures are unchanged.

### Step 5 — Domain: update `UpdateUserUseCase`

**File:** `src/app/features/users/update_user/domain/use_case.py`

`__call__` changes:

1. `existing = await self._port.get_by_id(command.target_user_id)` (was `get_by_username(command.target_username)`).
2. `check_owner(command.requester_user_id, existing.id)` (was `check_owner(command.requester_username, existing.username)`).
3. The `email` and `username` duplicate-check branches are unchanged — they compare `command.email != existing.email` and `command.username != existing.username` respectively.
4. `await self._port.update(command)` is unchanged.
5. Returns `UpdatedUserResult()` unchanged.

### Step 6 — Data: update `UpdateUserAdapter`

**File:** `src/app/features/users/update_user/data/adapter.py`

Replace `get_by_username` with `get_by_id`:

```python
async def get_by_id(self, user_id: int) -> ExistingUser | None:
    async with self._session_factory() as session:
        result = await session.execute(
            select(User).where(User.id == user_id, User.is_deleted == False)  # noqa: E712
        )
        row = result.scalar_one_or_none()
        if row is None:
            return None
        return ExistingUser(id=row.id, username=row.username, email=row.email)
```

Update `update()` method:
- Excluded fields in the dict comprehension: `("target_user_id", "requester_user_id")` (was `("target_username", "requester_username")`).
- WHERE clause: `User.id == command.target_user_id` (was `User.username == command.target_username`).

`email_exists` and `username_exists` are unchanged.

### Step 7 — Presentation: update router

**File:** `src/app/features/users/update_user/presentation/router.py`

Change endpoint signature:
- Path: `"/user/{user_id}"` (was `"/user/{username}"`).
- Path param: `user_id: int` (was `username: str`).
- Command construction:
  ```python
  command = UpdateUserCommand(
      target_user_id=user_id,
      requester_user_id=current_user["id"],
      **request.model_dump(),
  )
  ```

`presentation/schemas.py` is unchanged.

### Step 8 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test:
```
pytest tests/features/users/0043_update_user_route_to_user_id/update_user_route_to_user_id_outside_in_test.py -v
```

The slice is not done until all four checks pass, including the smoke test.

## 6. Tests planned

- **Use-case unit test** — `tests/features/users/0043_update_user_route_to_user_id/domain/test_use_case.py`.
  Mock `UpdateUserPort`. All commands carry `target_user_id: int` and `requester_user_id: int`. Cases:
  - `get_by_id` returns `None` → `NotFoundDomainError`.
  - `get_by_id` returns user with `existing.id != requester_user_id` → `ForbiddenDomainError`.
  - New email differs from `existing.email` and `email_exists` returns `True` → `DuplicateValueDomainError("Email is already registered")`.
  - New username differs from `existing.username` and `username_exists` returns `True` → `DuplicateValueDomainError("Username not available")`.
  - All checks pass → `port.update` called, returns `UpdatedUserResult(message="User updated")`.
  - Email unchanged (same as `existing.email`) → `email_exists` not called.
  - Username unchanged (same as `existing.username`) → `username_exists` not called.

- **Adapter unit test** — `tests/features/users/0043_update_user_route_to_user_id/data/test_adapter.py`.
  Mock async session. Cases:
  - `get_by_id` returns `ExistingUser` (with `id`, `username`, `email`) when row found by integer PK.
  - `get_by_id` returns `None` when row absent.
  - `update` with `IntegrityError` on commit → `DuplicateValueDomainError`.
  - `update` with any other exception → propagates unchanged.

- **Endpoint integration test** — `tests/features/users/0043_update_user_route_to_user_id/presentation/test_router.py`.
  `httpx.AsyncClient` against test Postgres. Cases:
  - `PATCH /user/{id}` with valid token, own ID, valid body → `200 {"message": "User updated"}`.
  - Non-integer `user_id` in path → `422`.
  - Valid token, different user's ID in path → `403`.
  - Non-existent `user_id` → `404`.
  - New email already taken → `409`.
  - New username already taken → `409`.
  - Missing/invalid token → `401`.
  - Invalid field (pattern mismatch in body) → `422`.

- **Outside-in test** — `tests/features/users/0043_update_user_route_to_user_id/update_user_route_to_user_id_outside_in_test.py`.
  Full HTTP stack, real adapter, test Postgres. Acceptance gate.

  Scenario:
  1. Create user A; capture `id_a`.
  2. Authenticate as A; `PATCH /user/{id_a}` with new `name`; assert `200`, updated name in response.
  3. Create user B; authenticate as B; `PATCH /user/{id_a}` (A's ID); assert `403`.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Migrating `delete_user` (0044), `delete_db_user` (0045), `assign_moderator` (0046), `revoke_moderator` (0047), `get_user_tier` (0048), `rate_limits` (0049), `update_user_tier` (0050) — those are separate slices in the same wave.
- Superuser ability to update any profile.
- Cache invalidation on `PATCH /user/{user_id}`.
- Rate limiting on this endpoint.

## 8. Open questions

None. All design decisions are captured in the PRD.
