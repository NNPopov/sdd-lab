# 0050 · update_user_tier_route_to_user_id — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0050_update_user_tier_route_to_user_id
- **PRD:** ./prd.md
- **Reference slice (if any):** `../0049_rate_limits_route_to_user_id/plan.md` —
  the exact shape-match. Like 0049, this endpoint is a **shallow aggregator free
  function** (`patch_user_tier` in
  `src/app/features/users/use_cases/user_tier_patch.py`), registered directly on
  the users feature router. The hexagonal `{username}` → `{user_id}` migration
  slices (0043–0048) **do not apply** here — there is no port, no adapter, no
  use-case class, no domain command, and no DI provider for this route. The one
  difference from 0049: this is a `PATCH` carrying a request body, and the
  migration touches **two** lookup keys (the `get` and the `update`), not one.
- **HTTP path:** `PATCH /api/v1/user/{user_id}/tier` (singular `/user/`, kept
  from the existing route).
- **STABLE files touched:** none. The route is registered inside
  `features/users/router.py` (a FEATURE file), not in `bootstrap/router.py`.
  No `bootstrap/container.py` provider (the function is plain `Depends`-wired,
  not DI-container-wired) and no `.importlinter` entry are needed.

## 2. Context summary

Slice 0050 migrates the existing `PATCH /user/{username}/tier` route to
`PATCH /user/{user_id}/tier`. This endpoint is a shallow aggregator: a free
async function that looks up the user, validates the requested tier exists, then
updates the user's `tier_id` via the shared FastCRUD repositories
(`crud_users`, `crud_tiers`), and returns a `{"message": ...}` dict. The only
change is the lookup key: the function parameter `username: str` becomes
`user_id: int`; the `crud_users.get(..., username=username, ...)` call becomes
`crud_users.get(..., id=user_id, ...)`; and the `crud_users.update(..., username=username)`
filter becomes `crud_users.update(..., id=user_id)`. All other logic (the tier
lookup by `values.tier_id`, both `NotFoundDomainError` branches, the success
message body) and the request/response shapes are unchanged. The route's
existing superuser auth dependency is preserved.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the account whose tier is being updated |

**Request body** (`UserTierUpdate` — unchanged):

| Field | Type | Notes |
|---|---|---|
| `tier_id` | `int` | ID of the tier to assign to the user |

**Query/header params:** Bearer JWT required (superuser). Auth is enforced by the
existing route-level `dependencies=[Depends(get_current_superuser)]` in
`features/users/router.py` — unchanged by this slice.

**Response body** (unchanged — a `dict[str, str]`, no declared `response_model`):

| Field | Type | Notes |
|---|---|---|
| `message` | `str` | `"User <name> Tier updated"` where `<name>` is the user's `name` |

**Status codes:**

- `200 OK` — user and tier found; the user's tier was updated. Body is the
  success message.
- `401 Unauthorized` — no/invalid credentials (from `get_current_superuser`).
- `403 Forbidden` — authenticated non-superuser (from `get_current_superuser`).
- `404 Not Found` — `NotFoundDomainError`; `user_id` matches no user
  (`"User not found"`), or `values.tier_id` matches no tier (`"Tier not found"`).
- `422 Unprocessable Entity` — FastAPI/Pydantic rejects a non-integer `user_id`
  path param or a malformed request body.
- `5xx` — not enumerated; the global catch-all handler covers infrastructure
  failures.

## 4. File structure

No new source files, no new folders, no hexagonal layers. Two modified files:

```
src/app/features/users/
├── use_cases/
│   └── user_tier_patch.py   # param username:str → user_id:int;
│                            #   crud_users.get(id=user_id); crud_users.update(id=user_id)
└── router.py                # route string "{username}" → "{user_id}"
```

`features/users/schemas.py`, the shared repositories, the tiers feature, and
`bootstrap/` are all unchanged.

## 5. Implementation steps

### Step 1 — Free function: identifier parameter and both lookup keys

**File:** `src/app/features/users/use_cases/user_tier_patch.py`

Change the parameter type and **both** user lookup keys (the `get` and the
`update`). Keep everything else verbatim:

```python
async def patch_user_tier(
    request: Request, user_id: int, values: UserTierUpdate, db: Annotated[AsyncSession, Depends(async_get_db)]
) -> dict[str, str]:
    db_user = await crud_users.get(db=db, id=user_id, schema_to_select=UserRead)
    if db_user is None:
        raise NotFoundDomainError("User not found")

    db_tier = await crud_tiers.get(db=db, id=values.tier_id, schema_to_select=TierRead)
    if db_tier is None:
        raise NotFoundDomainError("Tier not found")

    await crud_users.update(db=db, object=values.model_dump(), id=user_id)
    return {"message": f"User {db_user['name']} Tier updated"}
```

Exactly three edits: the parameter `username: str` → `user_id: int`,
`crud_users.get(db=db, username=username, ...)` → `crud_users.get(db=db, id=user_id, ...)`,
and `crud_users.update(db=db, object=..., username=username)` →
`crud_users.update(db=db, object=..., id=user_id)`. The `# FEATURE:` header on
line 1, the imports (all already at the correct depth — `from ....adapters.db.session ...`,
`from ..repository import crud_users`, etc.), the tier lookup by
`values.tier_id`, both `NotFoundDomainError` raises, and the success-message
return are unchanged. No `try/except` is added: any DB error propagates to the
global handler (per `agent_docs/error_handling.md`).

### Step 2 — Router: path string

**File:** `src/app/features/users/router.py`

Change only the path segment on the tier-patch registration line (currently
line 32). The auth dependency and the registration mechanism are unchanged:

```python
router.patch("/user/{user_id}/tier", dependencies=[Depends(get_current_superuser)])(patch_user_tier)
```

(`"/user/{username}/tier"` → `"/user/{user_id}/tier"`.) Do not touch the other
registrations on this router (`read_users_me`, `read_user_rate_limits`, the
`include_router` lines). The rate-limits route was already migrated in slice 0049.

### Step 3 — Tests: create the slice test folder

Create `tests/features/users/0050_update_user_tier_route_to_user_id/` with the
test levels described in § 6. These tests are **new** — this endpoint predates
the spec workflow and has no existing test folder.

### Step 4 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/users/0050_update_user_tier_route_to_user_id/update_user_tier_route_to_user_id_outside_in_test.py -v
```

The slice is not done until all checks pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

This endpoint has no port/adapter/use-case class, so the standard hexagonal
four-level pyramid is adapted. Levels that target hexagonal artifacts are opted
out (see below) and replaced by a function-level unit test.

- **Use-case unit test (hexagonal, mocked port)** — **opted out.** There is no
  use-case class or port to mock. See Opt-outs.

- **Adapter unit test** — **opted out.** There is no per-slice adapter; the
  function calls the shared FastCRUD repositories directly. See Opt-outs.

- **Function-level unit test** —
  `tests/features/users/0050_update_user_tier_route_to_user_id/test_function.py` (new).
  Call `patch_user_tier` directly with a mocked `db` session and patched
  repository calls (`crud_users.get`, `crud_tiers.get`, `crud_users.update`).
  Assert:
  - `crud_users.get` is invoked with `id=user_id` (not `username=...`) — core
    regression guard for the migration.
  - `crud_users.update` is invoked with `id=user_id` (not `username=...`) —
    second regression guard; the UPDATE WHERE clause must target the id.
  - `crud_users.get` returns `None` → raises `NotFoundDomainError("User not found")`,
    and `crud_users.update` is not called.
  - User found but `crud_tiers.get` returns `None` → raises
    `NotFoundDomainError("Tier not found")`, and `crud_users.update` is not called.
  - Happy path → returns `{"message": "User <name> Tier updated"}` with the
    user's `name`.

- **Endpoint integration test** —
  `tests/features/users/0050_update_user_tier_route_to_user_id/presentation/test_router.py` (new).
  `httpx.AsyncClient` against test Postgres, authenticated as a superuser. Assert:
  - Valid `user_id` + valid `tier_id` → `200` with the success message.
  - Non-existent `user_id` → `404`.
  - Existing user + non-existent `tier_id` → `404`.
  - No credentials → `401`.
  - Authenticated non-superuser → `403`.
  - Non-integer path param (e.g. `"abc"`) → `422`.

- **Outside-in test** —
  `tests/features/users/0050_update_user_tier_route_to_user_id/update_user_tier_route_to_user_id_outside_in_test.py` (new).
  Acceptance gate. Full HTTP stack, real repositories, test Postgres. Create a
  user and (at least one) tier, capture the user `id` and tier `id`; as a
  superuser call `PATCH /api/v1/user/{id}/tier` with `{"tier_id": <id>}` asserting
  `200` and the success message; then call `GET /api/v1/user/{id}/tier`
  (slice 0048) asserting the updated tier; finally call with an unknown `id`
  asserting `404`.

**Opt-outs:**

- **Use-case unit test (mocked port)** — no use-case class or port exists for
  this shallow aggregator endpoint (per PRD). Covered instead by the
  function-level unit test above.
- **Adapter unit test** — no per-slice adapter exists; the function uses the
  shared FastCRUD repositories. There is no business-meaningful infrastructure
  exception mapping to test.

## 7. Out of scope for this slice

- `get_user_tier` route (`GET /user/{user_id}/tier`) — slice 0048 (already done).
- `read_user_rate_limits` route — slice 0049 (already done).
- The `{tier_name}` routes in the `rate_limits` feature — separate task, not
  part of this migration.
- Other routes in the `{username}` → `{user_id}` migration series.
- Refactoring the endpoint into a hexagonal slice (port/adapter/use-case) — the
  PRD intentionally keeps it a shallow aggregator function.
- Changing the request/response shape, adding a `response_model`, caching, or
  rate limiting — none are added here.

## 8. Open questions

None. The route already enforces superuser auth via
`dependencies=[Depends(get_current_superuser)]`, the request and response bodies
are preserved verbatim, and the only behavioural change is the lookup key
(`username` string → `id` integer) on both the `get` and the `update`, matching
the migration series.
