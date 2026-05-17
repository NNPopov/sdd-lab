# 0014 · expose_moderator_flag — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0014_expose_moderator_flag
- **PRD:** ./prd.md
- **Reference slice:** `../0004_get_user_by_username/plan.md` — primary slice whose
  files are modified here; provides naming conventions and the adapter mapping pattern.
- **HTTP paths modified:**
  - `GET /api/v1/user/{username}` — `GetUserByUsernameResponse` gains `is_moderator`.
  - `GET /api/v1/user/me/` — `UserMeRead` gains `is_moderator`.
- **STABLE files touched:** none. All five modified files carry `# FEATURE:` headers.

## 2. Context summary

Slice 0013 added `is_moderator: bool` (non-nullable, `default=False`) to the
`User` ORM model and its Alembic migration. This slice surfaces that column through
the two user-identity endpoints. A client calling `GET /user/{username}` or
`GET /user/me/` will now receive `is_moderator` in the response body; it is always
a plain boolean, never `null`. No new endpoints, no new use-cases, no migration,
and no DI container changes are introduced. The change is additive — existing
consumers who ignore unknown fields are unaffected.

## 3. API contract

### `GET /api/v1/user/{username}` (modified)

**Path parameters:**

| Param | Type | Validation |
|---|---|---|
| `username` | `str` | required; provided in URL path |

**Response body** (`GetUserByUsernameResponse`) — new field added:

| Field | Type | Notes |
|---|---|---|
| `id` | `int` | unchanged |
| `name` | `str` | unchanged |
| `username` | `str` | unchanged |
| `email` | `str` | unchanged |
| `profile_image_url` | `str` | unchanged |
| `tier_id` | `int \| None` | unchanged |
| `is_moderator` | `bool` | **new** — always present, never `null` |

**Status codes:** unchanged (`200`, `404`, `500`).

### `GET /api/v1/user/me/` (modified)

**Response body** (`UserMeRead`) — new field added:

| Field | Type | Notes |
|---|---|---|
| `id` | `int` | unchanged |
| `name` | `str` | unchanged |
| `username` | `str` | unchanged |
| `email` | `str` | unchanged |
| `profile_image_url` | `str` | unchanged |
| `tier_id` | `int \| None` | unchanged |
| `is_superuser` | `bool` | unchanged |
| `is_moderator` | `bool` | **new** — always present, never `null` |

**Status codes:** unchanged (`200`, `401`, `500`).

## 4. File structure

No new files. Five existing FEATURE files are modified:

```
src/app/features/users/
├── schemas.py                                      # UserMeRead — add is_moderator: bool
└── get_user_by_username/
    ├── domain/
    │   └── entities.py                             # FoundUser — add is_moderator: bool
    ├── data/
    │   └── adapter.py                              # map row.is_moderator → FoundUser
    └── presentation/
        ├── schemas.py                              # GetUserByUsernameResponse — add is_moderator: bool
        └── router.py                               # pass is_moderator=entity.is_moderator
```

## 5. Implementation steps

### Step 1 — Domain entity: `FoundUser`

**File:** `src/app/features/users/get_user_by_username/domain/entities.py`

Add `is_moderator: bool` as a new field:

```python
class FoundUser(BaseModel):
    id: int
    name: str
    username: str
    email: str
    profile_image_url: str
    tier_id: int | None
    is_moderator: bool          # new
```

No imports change — `bool` is a stdlib type; `domain/` already imports only stdlib
and pydantic per `agent_docs/architecture.md` § Layer rules.

### Step 2 — Data adapter: `GetUserByUsernameAdapter.get()`

**File:** `src/app/features/users/get_user_by_username/data/adapter.py`

Add `is_moderator=row.is_moderator` to the `FoundUser(...)` constructor:

```python
return FoundUser(
    id=row.id,
    name=row.name,
    username=row.username,
    email=row.email,
    profile_image_url=row.profile_image_url,
    tier_id=row.tier_id,
    is_moderator=row.is_moderator,   # new
)
```

The adapter already fetches the full `User` row; `row.is_moderator` is available
with no query change. No `try/except` is added — read-only query, no catch per
`agent_docs/error_handling.md` § Right shape: read-only query, no catch.

### Step 3 — Presentation schema: `GetUserByUsernameResponse`

**File:** `src/app/features/users/get_user_by_username/presentation/schemas.py`

Add `is_moderator: bool` to `GetUserByUsernameResponse`:

```python
class GetUserByUsernameResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    username: str
    email: str
    profile_image_url: str
    tier_id: int | None
    is_moderator: bool          # new
```

### Step 4 — Presentation router: explicit field mapping

**File:** `src/app/features/users/get_user_by_username/presentation/router.py`

The router constructs `GetUserByUsernameResponse` with explicit keyword arguments.
Add `is_moderator=entity.is_moderator`:

```python
return GetUserByUsernameResponse(
    id=entity.id,
    name=entity.name,
    username=entity.username,
    email=entity.email,
    profile_image_url=entity.profile_image_url,
    tier_id=entity.tier_id,
    is_moderator=entity.is_moderator,   # new
)
```

No other change to the router.

### Step 5 — Shared schema: `UserMeRead`

**File:** `src/app/features/users/schemas.py`

`UserMeRead` inherits from `UserRead` and carries fields specific to the
authenticated-user view. Add `is_moderator: bool` alongside the existing
`is_superuser`:

```python
class UserMeRead(UserRead):
    is_superuser: bool
    is_moderator: bool   # new
```

`get_current_user` returns a `dict` built by FastCRUD from the `User` ORM row.
Because `User.is_moderator` already exists on the model (slice 0013), the dict
already carries `is_moderator`. FastAPI serializes the dict through `UserMeRead`
automatically — no change to `user_get_me.py` or `dependencies.py` is needed.

`UserRead` (the base class used by `list_users`) is left unchanged, preserving the
parent PRD's requirement that `list_users` does not expose `is_moderator`.

### Step 6 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/users/0014_expose_moderator_flag/expose_moderator_flag_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** — **opted out**. `GetUserByUsernameUseCase` is unchanged;
  it calls `self._port.get(query)` and raises `NotFoundDomainError` if the result
  is `None`. No new branch is introduced. The existing test in
  `tests/features/users/0004_get_user_by_username/domain/test_use_case.py` covers
  all branches and does not need to change. Opt-out is valid per
  `agent_docs/testing.md` (no new behavior).

- **Adapter unit test** —
  `tests/features/users/0014_expose_moderator_flag/data/test_adapter.py`.
  Uses a real async session against the test Postgres database (pattern from
  `tests/features/users/0001_create_user/`). Two cases:
  - User with `is_moderator=False` (the default): assert `FoundUser.is_moderator is False`.
  - User with `is_moderator=True`: assert `FoundUser.is_moderator is True`.

- **Endpoint integration tests** —
  `tests/features/users/0014_expose_moderator_flag/presentation/test_router.py`.
  Uses `httpx.AsyncClient` against the running app with test Postgres.

  `GET /user/{username}`:
  - Non-moderator user: assert `is_moderator: false` in response body.
  - Moderator user (set `is_moderator=True` directly in DB): assert `is_moderator: true`.

  `GET /user/me/`:
  - Non-moderator authenticated user: assert `is_moderator: false` in response body.
  - Moderator authenticated user: assert `is_moderator: true`.

  Prior art: `tests/features/users/0004_get_user_by_username/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/users/0014_expose_moderator_flag/expose_moderator_flag_outside_in_test.py`.
  Full HTTP stack with real adapter and test Postgres. No mocks. Seven-step scenario:
  1. Create a user (non-moderator).
  2. Authenticate as that user.
  3. `GET /user/{username}` — assert `is_moderator: false`.
  4. `GET /user/me/` — assert `is_moderator: false`.
  5. Set `is_moderator=True` directly on the user row in the test DB.
  6. `GET /user/{username}` — assert `is_moderator: true`.
  7. `GET /user/me/` — assert `is_moderator: true`.
  This is the acceptance gate; the slice is not done until this test is green.

**Opt-outs:** use-case unit test only (documented above).

## 7. Out of scope for this slice

- Assigning or revoking the moderator role — slices 0015 and 0016.
- Exposing `is_moderator` on `GET /users` (list users) — parent PRD explicitly excludes it.
- Exposing `moderator_granted_by_user_id` in any response schema.
- A `get_current_moderator` auth dependency — introduced in slices that require it (0017, 0019).
- Caching changes — `get_user_by_username` is not cached; no invalidation logic is needed.
- Any change to `UserRead` base class or any other schema besides `UserMeRead`.

## 8. Open questions

None — all decisions resolved in the PRD.
