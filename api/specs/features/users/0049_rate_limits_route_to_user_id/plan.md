# 0049 · rate_limits_route_to_user_id — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0049_rate_limits_route_to_user_id
- **PRD:** ./prd.md
- **Reference slice (if any):** No exact shape-match exists. Every prior
  `{username}` → `{user_id}` migration slice (0043–0048) modified a **hexagonal**
  slice (`domain/` + `data/` + `presentation/`). This endpoint is a **shallow
  aggregator free function** (`read_user_rate_limits` in
  `src/app/features/users/use_cases/user_rate_limits_get.py`), registered
  directly on the users feature router. The closest migration sibling for
  spec/test conventions is `../0048_get_user_tier_route_to_user_id/plan.md`, but
  its hexagonal structure (port/adapter/use-case/command) **does not apply
  here** — there is no port, no adapter, no use-case class, no domain command,
  and no DI provider for this route.
- **HTTP path:** `GET /api/v1/user/{user_id}/rate_limits` (singular `/user/`,
  kept from the existing route).
- **STABLE files touched:** none. The route is registered inside
  `features/users/router.py` (a FEATURE file), not in `bootstrap/router.py`.
  No `bootstrap/container.py` provider (the function is plain `Depends`-wired,
  not DI-container-wired) and no `.importlinter` entry are needed.

## 2. Context summary

Slice 0049 migrates the existing `GET /user/{username}/rate_limits` route to
`GET /user/{user_id}/rate_limits`. This endpoint is a "shallow" aggregator: a
free async function that looks up the user, resolves their tier, fetches the
tier's rate-limit rows via the shared FastCRUD repositories
(`crud_users`, `crud_tiers`, `crud_rate_limits`), and returns a `dict` combining
the user fields with a `tier_rate_limits` list. The only change is the lookup
key: the function parameter `username: str` becomes `user_id: int`, and the
`crud_users.get(..., username=username, ...)` call becomes
`crud_users.get(..., id=user_id, ...)`. All downstream logic (tier resolution,
rate-limit fetch, the `tier_id is None` empty-list branch, the two
`NotFoundDomainError` branches) and the response body are unchanged. The route's
existing superuser auth dependency is preserved.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the account whose rate limits are requested |

**Request body:** none.

**Query/header params:** Bearer JWT required (superuser). Auth is enforced by the
existing route-level `dependencies=[Depends(get_current_superuser)]` in
`features/users/router.py` — unchanged by this slice.

**Response body** (unchanged — a `dict[str, Any]`, no declared `response_model`):

The serialized `UserRead` fields plus an added `tier_rate_limits` key:

| Field | Type | Notes |
|---|---|---|
| `id` | `int` | |
| `name` | `str` | |
| `username` | `str` | |
| `email` | `str` (email) | |
| `profile_image_url` | `str` | |
| `tier_id` | `int \| null` | |
| `tier_rate_limits` | `list` | Rate-limit rows for the user's tier; `[]` when the user has no tier (`tier_id is None`) |

**Status codes:**

- `200 OK` — user found. Body is the user data plus `tier_rate_limits`
  (populated when the user has a tier, `[]` when `tier_id is None`).
- `401 Unauthorized` — no/invalid credentials (from `get_current_superuser`).
- `403 Forbidden` — authenticated non-superuser (from `get_current_superuser`).
- `404 Not Found` — `NotFoundDomainError`; `user_id` matches no user
  (`"User not found"`), or the user has a `tier_id` but the tier row is absent
  (`"Tier not found"`).
- `422 Unprocessable Entity` — FastAPI/Pydantic rejects a non-integer path param.
- `5xx` — not enumerated; the global catch-all handler covers infrastructure
  failures.

## 4. File structure

No new source files, no new folders, no hexagonal layers. Two modified files:

```
src/app/features/users/
├── use_cases/
│   └── user_rate_limits_get.py   # param username:str → user_id:int; crud_users.get(id=user_id)
└── router.py                     # route string "{username}" → "{user_id}"
```

`features/users/schemas.py`, the shared repositories, the tiers/rate_limits
features, and `bootstrap/` are all unchanged.

## 5. Implementation steps

### Step 1 — Free function: identifier parameter and lookup

**File:** `src/app/features/users/use_cases/user_rate_limits_get.py`

Change the parameter type and the user lookup key. Keep everything else
verbatim:

```python
async def read_user_rate_limits(
    request: Request, user_id: int, db: Annotated[AsyncSession, Depends(async_get_db)]
) -> dict[str, Any]:
    db_user = await crud_users.get(db=db, id=user_id, schema_to_select=UserRead)
    if db_user is None:
        raise NotFoundDomainError("User not found")

    user_dict = dict(db_user)
    if db_user["tier_id"] is None:
        user_dict["tier_rate_limits"] = []
        return user_dict

    db_tier = await crud_tiers.get(db=db, id=db_user["tier_id"], schema_to_select=TierRead)
    if db_tier is None:
        raise NotFoundDomainError("Tier not found")

    db_rate_limits = await crud_rate_limits.get_multi(db=db, tier_id=db_tier["id"])
    user_dict["tier_rate_limits"] = db_rate_limits["data"]

    return user_dict
```

Exactly two edits: the parameter `username: str` → `user_id: int`, and
`crud_users.get(db=db, username=username, ...)` →
`crud_users.get(db=db, id=user_id, ...)`. The `# FEATURE:` header on line 1, the
imports (all already at the correct depth — `from ....adapters.db.session ...`,
`from ..repository import crud_users`, etc.), the tier lookup, the empty-list
branch, both `NotFoundDomainError` raises, and the `dict` return are unchanged.
No `try/except` is added: these are read-only reads with no business-meaningful
infrastructure exception to translate; any DB error propagates to the global
handler (per `agent_docs/error_handling.md`).

### Step 2 — Router: path string

**File:** `src/app/features/users/router.py`

Change only the path segment on the rate-limits registration line (currently
line 31). The auth dependency and the registration mechanism are unchanged:

```python
router.get("/user/{user_id}/rate_limits", dependencies=[Depends(get_current_superuser)])(read_user_rate_limits)
```

(`"/user/{username}/rate_limits"` → `"/user/{user_id}/rate_limits"`.) Do not
touch the other registrations on this router (`read_users_me`, `patch_user_tier`,
the `include_router` lines). `patch_user_tier`'s `{username}` route is slice 0050,
out of scope here.

### Step 3 — Tests: create the slice test folder

Create `tests/features/users/0049_rate_limits_route_to_user_id/` with the test
levels described in § 6. These tests are **new** — this endpoint predates the
spec workflow and has no existing test folder.

### Step 4 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/users/0049_rate_limits_route_to_user_id/rate_limits_route_to_user_id_outside_in_test.py -v
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
  `tests/features/users/0049_rate_limits_route_to_user_id/test_function.py` (new).
  Call `read_user_rate_limits` directly with a mocked `db` session and patched
  repository calls (`crud_users.get`, `crud_tiers.get`, `crud_rate_limits.get_multi`).
  Assert:
  - `crud_users.get` is invoked with `id=user_id` (not `username=...`) — this is
    the core regression guard for the migration.
  - `crud_users.get` returns `None` → raises `NotFoundDomainError("User not found")`.
  - User with `tier_id is None` → returns a dict with `tier_rate_limits == []`,
    and `crud_tiers.get` / `crud_rate_limits.get_multi` are not called.
  - User with a `tier_id` but `crud_tiers.get` returns `None` → raises
    `NotFoundDomainError("Tier not found")`.
  - User with a valid tier → `tier_rate_limits` equals the repository's
    `["data"]` payload.

- **Endpoint integration test** —
  `tests/features/users/0049_rate_limits_route_to_user_id/presentation/test_router.py` (new).
  `httpx.AsyncClient` against test Postgres, authenticated as a superuser. Assert:
  - User with a tier and rate-limit rows → `200` with the user body and a
    populated `tier_rate_limits` list.
  - User with no tier (`tier_id is None`) → `200` with `tier_rate_limits == []`.
  - No credentials → `401`.
  - Authenticated non-superuser → `403`.
  - Non-existent `user_id` → `404`.
  - Non-integer path param (e.g. `"abc"`) → `422`.

- **Outside-in test** —
  `tests/features/users/0049_rate_limits_route_to_user_id/rate_limits_route_to_user_id_outside_in_test.py` (new).
  Acceptance gate. Full HTTP stack, real repositories, test Postgres. Create a
  user with a tier and a rate-limit configuration, capture the user `id`; as a
  superuser call `GET /api/v1/user/{id}/rate_limits` asserting `200` and the
  correct `tier_rate_limits`; then call with an unknown `id` asserting `404`.

**Opt-outs:**

- **Use-case unit test (mocked port)** — no use-case class or port exists for
  this shallow aggregator endpoint (per PRD). Covered instead by the
  function-level unit test above.
- **Adapter unit test** — no per-slice adapter exists; the function uses the
  shared FastCRUD repositories. There is no business-meaningful infrastructure
  exception mapping to test (read-only reads, no `try/except`).

## 7. Out of scope for this slice

- `patch_user_tier` / `update_user_tier` route (`PATCH /user/{username}/tier`) —
  slice 0050.
- The `{tier_name}` routes in the `rate_limits` feature
  (`GET /tier/{tier_name}/rate_limits`) — separate task, not part of this
  migration.
- Other routes in the `{username}` → `{user_id}` migration series (0041–0050, 0042).
- Refactoring the endpoint into a hexagonal slice (port/adapter/use-case) — the
  PRD intentionally keeps it a shallow aggregator function.
- Changing the response shape, adding a `response_model`, caching, or rate
  limiting — none are added here.

## 8. Open questions

None. The route already enforces superuser auth via
`dependencies=[Depends(get_current_superuser)]`, the response body is preserved
verbatim, and the only behavioural change is the lookup key (`username` string →
`id` integer), matching the migration series.
