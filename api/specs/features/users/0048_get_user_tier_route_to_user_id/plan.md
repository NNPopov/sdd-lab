# 0048 · get_user_tier_route_to_user_id — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0048_get_user_tier_route_to_user_id
- **PRD:** ./prd.md
- **Reference slice:** `../0047_revoke_moderator_route_to_user_id/plan.md` — closest structural match (a sibling `{username}` → `{user_id}` route migration that modifies an existing slice in place). The slice being modified is `0005_get_user_tier` (`src/app/features/users/get_user_tier/`).
- **HTTP path:** `GET /api/v1/user/{user_id}/tier` (note: singular `/user/`, kept from the existing route).
- **STABLE files touched:** none. `bootstrap/container.py` already wires `get_user_tier_adapter` / `get_user_tier_use_case`, `features/users/router.py` already includes `get_user_tier_router`, `Container.wiring_config` already lists the router module, and `.importlinter` already has the `get_user_tier.presentation.router -> app.bootstrap.container` entry. No new providers, registrations, or `.importlinter` entries are needed.

## 2. Context summary

Slice 0048 migrates the existing `GET /user/{username}/tier` route to
`GET /user/{user_id}/tier`. No new slice folder is created; the existing
`features/users/get_user_tier/` slice is modified in place. The domain query's
identifier field changes from `username: str` to `user_id: int`; the adapter's
user lookup changes from `WHERE User.username == query.username` to
`WHERE User.id == query.user_id` (the `is_deleted == False` soft-delete filter is
kept); the router changes the path param from `str` to `int` and builds
`GetUserTierQuery(user_id=user_id)`. The port method signature
(`get(query) -> FoundUserTier | None | UserNotFound | TierNotFound`), the
use-case branch logic, the `UserNotFound`/`TierNotFound`/`FoundUserTier`
entities, and the response body are all unchanged.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the account whose tier is requested |

**Request body:** none.

**Query/header params:** none. There is no auth dependency on this route in the
existing slice 0005; that is unchanged here (see Open questions).

**Response body** (`GetUserTierResponse` — unchanged):

| Field | Type | Notes |
|---|---|---|
| `tier_id` | `int` | |
| `tier_name` | `str` | |
| `tier_created_at` | `datetime` | |

When the user exists but has no tier assigned (`tier_id is None`), the use-case
returns `None` and the endpoint returns `200` with a `null` body. This is the
existing slice-0005 behaviour and is preserved unchanged (PRD user story 3
explicitly defers to existing domain behaviour).

**Status codes:**

- `200 OK` — user found with a valid tier (tier body returned), **or** user
  found with no tier assigned (`null` body — unchanged behaviour).
- `404 Not Found` — `NotFoundDomainError`; `user_id` matches no active user
  (`UserNotFound`), or the user has a `tier_id` but the tier row is absent
  (`TierNotFound`).
- `422 Unprocessable Entity` — FastAPI/Pydantic rejects a non-integer path param.
- `5xx` — not enumerated; the global catch-all handler covers infrastructure
  failures.

## 4. File structure

No new files. Modified files only:

```
src/app/features/users/get_user_tier/
├── domain/
│   ├── commands.py                  # GetUserTierQuery: username:str → user_id:int
│   ├── entities.py                  # docstrings: "username" → "user_id" (cosmetic)
│   └── ports/
│       └── get_user_tier_port.py    # docstring: "username query" → "user_id query" (cosmetic)
├── data/
│   └── adapter.py                   # lookup WHERE User.username → WHERE User.id
└── presentation/
    └── router.py                    # /user/{user_id}/tier, int param, GetUserTierQuery(user_id=user_id)
```

`domain/use_case.py` and `presentation/schemas.py` are unchanged.

## 5. Implementation steps

### Step 1 — Domain: Query command

**File:** `src/app/features/users/get_user_tier/domain/commands.py`

Replace the `str` identifier field with an `int`:

```python
class GetUserTierQuery(BaseModel):
    user_id: int
```

### Step 2 — Domain: Port (docstring only)

**File:** `src/app/features/users/get_user_tier/domain/ports/get_user_tier_port.py`

The method signature `get(self, query: GetUserTierQuery) -> FoundUserTier | None | UserNotFound | TierNotFound`
is unchanged because the port takes the query object, not the raw identifier.
Update the docstring wording from "for the given username query" to "for the
given user_id query" and "no active user row for the given username" to
"...for the given user_id" for accuracy. The `@runtime_checkable` decorator and
`Protocol` base remain mandatory (per `agent_docs/architecture.md` § Terminology:
port and adapter).

### Step 3 — Domain: Entities (docstring only)

**File:** `src/app/features/users/get_user_tier/domain/entities.py`

Cosmetic: update the `UserNotFound` docstring from "no active user row for the
given username" to "...for the given user_id". `TierNotFound` and `FoundUserTier`
are unchanged. No structural change.

### Step 4 — Domain: Use case (no change)

**File:** `src/app/features/users/get_user_tier/domain/use_case.py`

Unchanged. The use-case calls `self._port.get(query)` and branches on the
returned port state (`UserNotFound` → `NotFoundDomainError("User not found")`,
`TierNotFound` → `NotFoundDomainError("Tier not found")`, `None`/`FoundUserTier`
pass through). None of this depends on the identifier type. Listed here for
completeness; do not edit.

### Step 5 — Data: Adapter

**File:** `src/app/features/users/get_user_tier/data/adapter.py`

Change the user lookup from username to integer primary key. Keep the
soft-delete filter:

```python
async def get(self, query: GetUserTierQuery) -> FoundUserTier | None | UserNotFound | TierNotFound:
    async with self._session_factory() as session:
        result = await session.execute(
            select(User).where(
                User.id == query.user_id,
                User.is_deleted == False,  # noqa: E712
            )
        )
        user_row = result.scalar_one_or_none()

    if user_row is None:
        return UserNotFound()
    if user_row.tier_id is None:
        return None

    async with self._session_factory() as session:
        result = await session.execute(select(Tier).where(Tier.id == user_row.tier_id))
        tier_row = result.scalar_one_or_none()

    if tier_row is None:
        return TierNotFound()
    return FoundUserTier(
        tier_id=tier_row.id,
        tier_name=tier_row.name,
        tier_created_at=tier_row.created_at,
    )
```

Only the first `WHERE` clause changes (`User.username == query.username` →
`User.id == query.user_id`). The tier lookup is unchanged. No `try/except` is
added: these are read-only `SELECT`s with no business-meaningful infrastructure
exception to translate; any DB error propagates to the global handler (per
`agent_docs/error_handling.md` § read-only query, no catch). The existing
five-dot imports (`from .....adapters.db.models.user import User`,
`from .....adapters.db.models.tier import Tier`) are unchanged.

### Step 6 — Presentation: Router

**File:** `src/app/features/users/get_user_tier/presentation/router.py`

Change the path param name/type and the query construction. The response
conversion and the `response_model=GetUserTierResponse | None` are unchanged:

```python
@router.get(
    "/user/{user_id}/tier",
    response_model=GetUserTierResponse | None,
    status_code=200,
)
@inject
async def get_user_tier(
    user_id: int,
    use_case: Annotated[GetUserTierUseCase, Depends(Provide[Container.get_user_tier_use_case])],
) -> GetUserTierResponse | None:
    query = GetUserTierQuery(user_id=user_id)
    entity = await use_case(query)
    if entity is None:
        return None
    return GetUserTierResponse(
        tier_id=entity.tier_id,
        tier_name=entity.tier_name,
        tier_created_at=entity.tier_created_at,
    )
```

Keep the singular `/user/` segment (the existing route uses it). All import
paths are unchanged.

### Step 7 — Tests: update all four levels

Update each test file under `tests/features/users/0005_get_user_tier/` to use an
integer `user_id` instead of a username string. No test file is deleted; all
four levels stay in place with updated fixtures and assertions. See § 6.

### Step 8 — Verify

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

The slice is not done until all checks pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

Four levels, per `agent_docs/testing.md`. All four already exist under
`tests/features/users/0005_get_user_tier/` and are modified in place:

- **Use-case unit test** — `tests/features/users/0005_get_user_tier/domain/test_use_case.py` (modified).
  Mock `GetUserTierPort`. Build `GetUserTierQuery(user_id=<int>)`. Assert:
  - `get` returns `UserNotFound()` → raises `NotFoundDomainError` ("User not found").
  - `get` returns `TierNotFound()` → raises `NotFoundDomainError` ("Tier not found").
  - `get` returns `None` (user has no tier) → use-case returns `None`.
  - `get` returns a `FoundUserTier` → that entity is returned unchanged.

- **Adapter unit test** — `tests/features/users/0005_get_user_tier/data/test_adapter.py` (modified).
  Mock the async session factory. Assert:
  - Lookup filters on `User.id == query.user_id` and `is_deleted == False`.
  - Missing/soft-deleted user row → returns `UserNotFound()`.
  - User row with `tier_id is None` → returns `None`.
  - User row with a `tier_id` but no matching tier row → returns `TierNotFound()`.
  - User row with a valid tier → returns a `FoundUserTier` with the tier fields.
  - Any DB exception propagates unchanged (no catch in the adapter).

- **Endpoint integration test** — `tests/features/users/0005_get_user_tier/presentation/test_router.py` (modified).
  `httpx.AsyncClient` against test Postgres. Update the path from
  `/api/v1/user/{username}/tier` to `/api/v1/user/{id}/tier`. Assert:
  - GET on a user with a tier → `200` with the tier body.
  - GET on a user with no tier → `200` with `null` body (unchanged behaviour).
  - Non-existent `user_id` → `404`.
  - Non-integer path param (e.g. `"abc"`) → `422`.

- **Outside-in test** — `tests/features/users/0005_get_user_tier/get_user_tier_outside_in_test.py` (modified).
  Full HTTP stack: real adapter, test Postgres. Create a user with a tier,
  capture its `id`, call `GET /api/v1/user/{id}/tier` asserting `200` and the
  correct tier data, then call with an unknown `id` asserting `404`.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Update-user-tier route (`update_user_tier`) — slice 0050.
- Other routes in the `{username}` → `{user_id}` migration series (0041–0050, 0042).
- Changing the "user has no tier" behaviour from `200`/`null` to `404` — PRD
  defers to existing domain behaviour; not in scope here.
- Adding authentication/authorization to the route — the existing slice 0005
  route has none; this slice does not add any (see Open questions).
- Caching — the existing route is uncached; not added here.
- Rate limiting — not applied.

## 8. Open questions

The existing slice-0005 `get_user_tier` route has **no auth dependency** (the
router does not inject `get_current_user`/`get_current_superuser`). The PRD's
contract table says "Auth: per existing slice", so this plan preserves the
unauthenticated route as-is. If auth should be added as part of the migration,
that is a behaviour change requiring a PRD update — flag before implementing.
Otherwise: None.
