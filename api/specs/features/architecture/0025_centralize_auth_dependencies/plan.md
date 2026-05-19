# 0025 · centralize_auth_dependencies — Implementation plan

## 1. Header

- **Feature:** architecture
- **Slice:** 0025_centralize_auth_dependencies
- **PRD:** ./prd.md
- **Reference slice:** None — no existing slice shares this operation shape (infrastructure
  refactoring with no HTTP entry point). The nearest read-only pattern in any adapter is
  documented in `agent_docs/error_handling.md` § Right shape: read-only query, no catch.
- **HTTP path:** None. This slice adds no new endpoint. All four auth dependency functions
  retain their existing signatures; only their module location changes.
- **STABLE files touched:**
  - `src/app/shared_dependencies.py` — extend with `_get_user_by_credential` helper and
    four auth dependency functions; remove `from .features.users.dependencies import
    get_optional_user`.
  - `src/app/bootstrap/factory.py` — update one import line from
    `..features.users.dependencies` to `..shared_dependencies`.

## 2. Context summary

Auth dependency functions (`get_current_user`, `get_optional_user`, `get_current_superuser`,
`get_current_moderator_or_superuser`) currently live in
`src/app/features/users/dependencies.py`. Ten feature files plus `bootstrap/factory.py`
and `shared_dependencies.py` import from that location, creating prohibited cross-domain
couplings (`posts → users`, `bootstrap → users feature`) that break both the pytestarch
VSA independence test and the `importlinter` `vsa-feature-independence` contract.

This slice moves all four functions into `src/app/shared_dependencies.py` (the
designated STABLE cross-feature dependencies file), rewrites user-lookup using direct
SQLAlchemy 2.0 async queries against the `User` ORM model (eliminating the FastCRUD
dependency at the auth boundary), and updates every caller and test file.
`features/users/dependencies.py` is deleted at the end. No new HTTP endpoints, no new
use-case classes, no new ports or adapters, no new ORM models, no DI container changes.

## 3. Function contracts

All four functions retain identical signatures and return types. Only their module
location changes. The private helper `_get_user_by_credential` is new.

**`_get_user_by_credential(db: AsyncSession, credential: str) -> dict[str, Any] | None`**
- Private async helper; not exported.
- Branches on `@` in `credential`: uses `User.email` predicate when true,
  `User.username` otherwise.
- Always adds `User.is_deleted.is_(False)` to the WHERE clause so soft-deleted users
  cannot authenticate.
- On match: returns a `dict` with the auth-boundary allowlist only —
  `{"id", "username", "email", "is_superuser", "is_moderator", "tier_id"}`.
  `hashed_password` and all other columns are deliberately excluded.
- On no match: returns `None`.

**`get_current_user(token, db) -> dict[str, Any]`** — unchanged signature.
- Calls `verify_token` then `_get_user_by_credential`.
- Raises `UnauthorizedException` if token invalid or user not found.

**`get_optional_user(request, db) -> dict | None`** — unchanged signature.
- Reads `Authorization` header; returns `None` on any auth failure (missing header,
  bad bearer format, expired/invalid token).
- On valid token: delegates to `get_current_user` internally.

**`get_current_superuser(current_user) -> dict`** — unchanged signature.
- Raises `ForbiddenException` if `current_user["is_superuser"]` is falsy.

**`get_current_moderator_or_superuser(current_user) -> dict`** — unchanged signature.
- Raises `ForbiddenException` if neither `is_moderator` nor `is_superuser` is truthy.

**`rate_limiter_dependency`** — unchanged; uses the now-local `get_optional_user`.

## 4. Files modified, created, deleted

**Modified — STABLE:**
```
src/app/shared_dependencies.py
src/app/bootstrap/factory.py
```

**Modified — FEATURE (import-path replacement only; no logic changes):**
```
src/app/features/rate_limits/router.py
src/app/features/tiers/router.py
src/app/features/posts/router.py
src/app/features/posts/list_all_posts/presentation/router.py
src/app/features/posts/list_posts/presentation/router.py
src/app/features/posts/create_post/presentation/router.py
src/app/features/posts/revise_post/presentation/router.py
src/app/features/posts/list_pending_posts/presentation/router.py
src/app/features/posts/moderate_post/presentation/router.py
src/app/features/posts/get_moderation_log/presentation/router.py
```

**Deleted — FEATURE:**
```
src/app/features/users/dependencies.py
```

**Modified — tests (~30 files; absolute import-path replacement only):**
All test files containing `from app.features.users.dependencies import`. Identified by:
```
grep -r "from app.features.users.dependencies import" tests/
```

## 5. Implementation steps

### Step 1 — Add SQLAlchemy imports to `shared_dependencies.py`

In `src/app/shared_dependencies.py`, add to the import block:

```python
from typing import Any  # if not already present
from sqlalchemy import select
from .adapters.db.models.user import User as UserModel
from .core.security import TokenType, oauth2_scheme, verify_token
from fastcrud.exceptions.http_exceptions import ForbiddenException, UnauthorizedException
```

Remove the existing line:
```python
from .features.users.dependencies import get_optional_user
```

Verify: no import from `features.users` remains in this file.

### Step 2 — Add `_get_user_by_credential` to `shared_dependencies.py`

Add the private helper after the logger initialisation and before
`rate_limiter_dependency`:

```python
async def _get_user_by_credential(db: AsyncSession, credential: str) -> dict[str, Any] | None:
    stmt = select(UserModel)
    if "@" in credential:
        stmt = stmt.where(UserModel.email == credential, UserModel.is_deleted.is_(False))
    else:
        stmt = stmt.where(UserModel.username == credential, UserModel.is_deleted.is_(False))
    result = await db.execute(stmt)
    row = result.scalar_one_or_none()
    if row is None:
        return None
    return {
        "id": row.id,
        "username": row.username,
        "email": row.email,
        "is_superuser": row.is_superuser,
        "is_moderator": row.is_moderator,
        "tier_id": row.tier_id,
    }
```

No `try/except` around the query — per `agent_docs/error_handling.md` § Right shape:
read-only query, no catch.

### Step 3 — Add the four auth dependency functions to `shared_dependencies.py`

Append after `_get_user_by_credential`:

```python
async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[AsyncSession, Depends(async_get_db)],
) -> dict[str, Any]:
    token_data = await verify_token(token, TokenType.ACCESS, db)
    if token_data is None:
        raise UnauthorizedException("User not authenticated.")
    user = await _get_user_by_credential(db, token_data.username_or_email)
    if user is None:
        raise UnauthorizedException("User not authenticated.")
    return user


async def get_optional_user(
    request: Request, db: AsyncSession = Depends(async_get_db)
) -> dict | None:
    token = request.headers.get("Authorization")
    if not token:
        return None
    try:
        token_type, _, token_value = token.partition(" ")
        if token_type.lower() != "bearer" or not token_value:
            return None
        token_data = await verify_token(token_value, TokenType.ACCESS, db)
        if token_data is None:
            return None
        return await get_current_user(token_value, db=db)
    except HTTPException as http_exc:
        if http_exc.status_code != 401:
            logger.error(f"Unexpected HTTPException in get_optional_user: {http_exc.detail}")
        return None
    except Exception as exc:
        logger.error(f"Unexpected error in get_optional_user: {exc}")
        return None


async def get_current_superuser(
    current_user: Annotated[dict, Depends(get_current_user)],
) -> dict:
    if not current_user["is_superuser"]:
        raise ForbiddenException("You do not have enough privileges.")
    return current_user


async def get_current_moderator_or_superuser(
    current_user: Annotated[dict, Depends(get_current_user)],
) -> dict:
    if not (current_user.get("is_moderator") or current_user.get("is_superuser")):
        raise ForbiddenException("You do not have enough privileges.")
    return current_user
```

Also add `from fastapi import HTTPException` to the top-level imports (needed by
`get_optional_user`'s exception handler).

Verify: `rate_limiter_dependency` still references `get_optional_user` which is now
local — no import needed.

### Step 4 — Update `bootstrap/factory.py`

Replace line 38:
```python
# old
from ..features.users.dependencies import get_current_superuser
# new
from ..shared_dependencies import get_current_superuser
```

No other changes to this file.

### Step 5 — Update the 10 FEATURE router files (import-path only)

Apply exactly one import-line replacement per file. Relative dot counts are calculated
from each file's position to `src/app/`:

| File | Old import | New import |
|---|---|---|
| `features/rate_limits/router.py` | `from ...features.users.dependencies import get_current_superuser` | `from ...shared_dependencies import get_current_superuser` |
| `features/tiers/router.py` | `from ..users.dependencies import get_current_superuser` | `from ...shared_dependencies import get_current_superuser` |
| `features/posts/router.py` | `from ..users.dependencies import get_current_superuser, get_current_user` | `from ...shared_dependencies import get_current_superuser, get_current_user` |
| `features/posts/list_all_posts/presentation/router.py` | `from ....users.dependencies import get_optional_user` | `from .....shared_dependencies import get_optional_user` |
| `features/posts/list_posts/presentation/router.py` | `from ....users.dependencies import get_optional_user` | `from .....shared_dependencies import get_optional_user` |
| `features/posts/create_post/presentation/router.py` | `from .....features.users.dependencies import get_current_user` | `from .....shared_dependencies import get_current_user` |
| `features/posts/revise_post/presentation/router.py` | `from ....users.dependencies import get_current_user` | `from .....shared_dependencies import get_current_user` |
| `features/posts/list_pending_posts/presentation/router.py` | `from ....users.dependencies import get_current_moderator_or_superuser` | `from .....shared_dependencies import get_current_moderator_or_superuser` |
| `features/posts/moderate_post/presentation/router.py` | `from ....users.dependencies import get_current_moderator_or_superuser` | `from .....shared_dependencies import get_current_moderator_or_superuser` |
| `features/posts/get_moderation_log/presentation/router.py` | `from ....users.dependencies import get_current_user` | `from .....shared_dependencies import get_current_user` |

Dot-count rationale: each `presentation/` router is 5 levels below `app/`
(`app/features/posts/<slice>/presentation/router.py`), so 5 dots reach `app/`.
`features/tiers/router.py` and `features/posts/router.py` are 3 levels below `app/`, so
3 dots reach `app/`.

### Step 6 — Delete `features/users/dependencies.py`

Confirm via grep that no source file under `src/` still imports from
`features.users.dependencies`. Then delete
`src/app/features/users/dependencies.py`.

No re-export shim is left (per CLAUDE.md § Universal hard rules, backwards-compatibility
hacks like re-exporting removed symbols are forbidden).

### Step 7 — Update all test files (~30 files)

Replace every occurrence of:
```python
from app.features.users.dependencies import <symbol>
```
with:
```python
from app.shared_dependencies import <symbol>
```

The replacement is purely mechanical: symbol names are unchanged. Tests use absolute
imports per `agent_docs/architecture.md` § Import conventions.

The full file list is produced by:
```
grep -r "from app.features.users.dependencies import" tests/
```

### Step 8 — Verify

Run in order:
```bash
ruff format src/app
ruff check src/app
mypy src/app
cd src && lint-imports --config ../.importlinter   # vsa-feature-independence must pass
cd ..
pytest tests/architecture/                          # test_vsa_domains_do_not_import_each_other must pass
pytest                                              # full suite including smoke test
```

Key gates:
- `tests/architecture/test_architecture.py::test_vsa_domains_do_not_import_each_other[posts-users]`
  and `[users-posts]` — previously failing; must now be green.
- `importlinter` contract `vsa-feature-independence` — same.
- `tests/smoke/test_app_starts.py` — boots the full app; must remain green.

## 6. Tests planned

This slice has no HTTP entry point, no new use-case class, and no new adapter. The
standard four-level test pyramid (use-case unit / adapter unit / endpoint integration /
outside-in) does not apply. Test work consists of:

**New unit tests —**
`tests/features/architecture/0025_centralize_auth_dependencies/test_shared_dependencies.py`

Tests for `_get_user_by_credential` (mocked `AsyncSession`):
- `test_returns_none_when_no_row_matches` — `scalar_one_or_none()` returns `None`.
- `test_returns_allowlisted_dict_on_match` — mock returns a row; assert returned dict
  has exactly `{"id", "username", "email", "is_superuser", "is_moderator", "tier_id"}`;
  assert `"hashed_password"` is absent.
- `test_routes_by_at_sign_to_email_branch` — credential contains `@`; assert the
  executed SQL uses the email column (inspect `call_args` on the mock execute).
- `test_routes_without_at_sign_to_username_branch` — inverse.
- `test_filters_out_is_deleted_true_rows` — row mock has `is_deleted=True`; because the
  WHERE predicate filters it out, `scalar_one_or_none()` returns `None`; function
  returns `None`.

Tests for `get_current_user` (mock `verify_token`, mock `_get_user_by_credential`):
- `test_raises_unauthorized_when_token_invalid` — `verify_token` returns `None`.
- `test_raises_unauthorized_when_user_not_found` — `verify_token` returns valid
  `TokenData`, `_get_user_by_credential` returns `None`.
- `test_returns_user_dict_on_success` — happy path.

Tests for `get_optional_user` (mock `verify_token`):
- `test_returns_none_for_missing_authorization_header`.
- `test_returns_none_for_non_bearer_format`.
- `test_returns_none_when_verify_token_returns_none`.

**Existing test updates (import-path only):** ~30 files listed by the grep in step 7.
Symbol names are unchanged; only `app.features.users.dependencies` → `app.shared_dependencies`.

**Architecture test gate:** `tests/architecture/test_architecture.py` — must be entirely
green after step 8.

**Opt-outs:**
- No adapter unit test — no new `*Adapter` class.
- No endpoint integration test — no new HTTP endpoint.
- No outside-in test — no new HTTP surface, no new acceptance contract.

## 7. Out of scope for this slice

- Removing the remaining cross-feature imports in `shared_dependencies.py` that load
  `features/rate_limits/repository` and `features/tiers/repository`.
- Fixing other identified architecture violations (`adapters/rate_limit` importing
  `features/rate_limits/schemas`; `core/security` importing `adapters/db/token_blacklist`).
- Full type-narrowing of `get_current_user` return from `dict[str, Any]` to a proper
  `CurrentUser` named schema (architecture.md § Bounded contexts).
- Migration of `features/tiers/router.py` and `features/rate_limits/router.py` to the
  VSA use-case pattern.

## 8. Open questions

None. The PRD documents all implementation decisions: the auth-boundary allowlist, the
`is_deleted` filter, the `@`-based credential branching, the deliberate exclusion of
`hashed_password`, and the layer-purity trade-off of `shared_dependencies.py` importing
from STABLE adapters.
