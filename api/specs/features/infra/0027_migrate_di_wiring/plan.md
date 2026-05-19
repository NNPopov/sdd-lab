# 0027 · migrate_di_wiring — Implementation plan

## 1. Header

- **Feature:** infra
- **Slice:** 0027_migrate_di_wiring
- **PRD:** ./prd.md
- **Reference slice:** None — this is an infrastructure-only migration with no domain, port, adapter, or new endpoint layer. No shape-match exists in the roadmap.
- **HTTP path:** N/A — pure refactor; no API surface change.
- **STABLE files touched:**
  - `src/app/bootstrap/container.py` — add `WiringConfiguration`
  - `src/app/shared_dependencies.py` — remove `_get_token_blacklist_adapter`, add `@inject` + `Provide[...]`
  - `agent_docs/entry_points/fastapi.md` — document the three-step slice-addition workflow

## 2. Context summary

Seventeen slice routers and one shared-dependency module currently resolve DI
container providers through private helper functions that suppress the linter
(`# noqa: PLC0415`) and defer the `container` import to call time, working
around a circular-import risk that no longer exists once `dependency_injector`
wiring is enabled. This slice enables wiring by adding a `WiringConfiguration`
to the `Container` class body, then replaces every `_get_<name>()` helper with
the idiomatic `@inject` + `Depends(Provide[Container.<provider>])` pattern
already documented in `agent_docs/entry_points/fastapi.md`. No API behaviour
changes; the acceptance gate is that every existing outside-in test and the
smoke test remain green.

## 3. API contract

**Not applicable.** The migration is behaviour-preserving. All HTTP paths,
request shapes, response shapes, and status codes are unchanged.

## 4. Modified files

No new files are created. The migration modifies the following existing files.

**STABLE files (require explicit approval — granted by the PRD):**

```
src/app/bootstrap/container.py          # add WiringConfiguration
src/app/shared_dependencies.py          # remove helper; add @inject + Provide
```

**FEATURE router files (17 total):**

```
src/app/features/users/create_user/presentation/router.py
src/app/features/users/list_users/presentation/router.py
src/app/features/users/get_user_by_username/presentation/router.py
src/app/features/users/get_user_tier/presentation/router.py
src/app/features/users/update_user/presentation/router.py
src/app/features/users/delete_user/presentation/router.py
src/app/features/users/delete_db_user/presentation/router.py
src/app/features/users/assign_moderator/presentation/router.py
src/app/features/users/revoke_moderator/presentation/router.py
src/app/features/posts/create_post/presentation/router.py
src/app/features/posts/list_posts/presentation/router.py
src/app/features/posts/list_all_posts/presentation/router.py
src/app/features/posts/list_pending_posts/presentation/router.py
src/app/features/posts/get_post/presentation/router.py
src/app/features/posts/moderate_post/presentation/router.py
src/app/features/posts/revise_post/presentation/router.py
src/app/features/posts/get_moderation_log/presentation/router.py
```

**Documentation:**

```
agent_docs/entry_points/fastapi.md
```

## 5. Implementation steps

### Step 1 — `bootstrap/container.py`: add `WiringConfiguration`

Add the `wiring_config` attribute as the first member of the `Container` class
body, before the provider declarations. The list must include all 17 router
modules and `app.shared_dependencies`.

```python
class Container(containers.DeclarativeContainer):
    wiring_config = containers.WiringConfiguration(
        modules=[
            "app.features.users.create_user.presentation.router",
            "app.features.users.list_users.presentation.router",
            "app.features.users.get_user_by_username.presentation.router",
            "app.features.users.get_user_tier.presentation.router",
            "app.features.users.update_user.presentation.router",
            "app.features.users.delete_user.presentation.router",
            "app.features.users.delete_db_user.presentation.router",
            "app.features.users.assign_moderator.presentation.router",
            "app.features.users.revoke_moderator.presentation.router",
            "app.features.posts.create_post.presentation.router",
            "app.features.posts.list_posts.presentation.router",
            "app.features.posts.list_all_posts.presentation.router",
            "app.features.posts.list_pending_posts.presentation.router",
            "app.features.posts.get_post.presentation.router",
            "app.features.posts.moderate_post.presentation.router",
            "app.features.posts.revise_post.presentation.router",
            "app.features.posts.get_moderation_log.presentation.router",
            "app.shared_dependencies",
        ]
    )

    session_factory = providers.Object(local_session)
    # ... all existing provider entries unchanged ...
```

No provider definitions are changed. `container = Container()` at the end of
the file triggers automatic wiring at module-load time via the
`WiringConfiguration` — no call to `container.wire()` in `factory.py` is
needed.

Module paths are dotted absolute names from the `src/` root (matching
`pythonpath = ["src"]` in `pyproject.toml`). They are not Python relative
imports.

**Verify:** `mypy src/app` and `pytest tests/smoke/` pass after this step
alone (the helpers still exist in the routers at this point; that is fine).

### Step 2 — Convert all 17 slice routers to `@inject` + `Provide[...]`

Apply this transformation to every router in the list above.

**Before (current pattern):**
```python
# FEATURE: create_user — HTTP router.
from typing import Annotated
from fastapi import APIRouter, Depends
from ..domain.commands import CreateUserCommand
from ..domain.use_case import CreateUserUseCase
from .schemas import CreateUserRequest, CreateUserResponse

router = APIRouter()

def _get_create_user_use_case() -> CreateUserUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.create_user_use_case()

@router.post("/user", response_model=CreateUserResponse, status_code=201)
async def create_user(
    request: CreateUserRequest,
    use_case: Annotated[CreateUserUseCase, Depends(_get_create_user_use_case)],
) -> CreateUserResponse:
    ...
```

**After (target pattern):**
```python
# FEATURE: create_user — HTTP router.
from typing import Annotated
from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends
from .....bootstrap.container import Container
from ..domain.commands import CreateUserCommand
from ..domain.use_case import CreateUserUseCase
from .schemas import CreateUserRequest, CreateUserResponse

router = APIRouter()

@router.post("/user", response_model=CreateUserResponse, status_code=201)
@inject
async def create_user(
    request: CreateUserRequest,
    use_case: Annotated[CreateUserUseCase, Depends(Provide[Container.create_user_use_case])],
) -> CreateUserResponse:
    ...
```

Three mechanical changes per router:
1. Remove the `def _get_<name>_use_case()` function entirely (including its
   suppressed local import comment and the `# noqa: PLC0415` line).
2. Add two new top-level imports:
   - `from dependency_injector.wiring import Provide, inject`
   - `from .....bootstrap.container import Container` (relative; five dots for
     routers four levels deep under `src/app/`; adjust dot count to match the
     router's actual depth).
3. On every endpoint function:
   - Replace `Depends(_get_<name>_use_case)` with
     `Depends(Provide[Container.<name>_use_case])`.
   - Add `@inject` as the **innermost decorator** — directly above `async def`,
     below `@router.<method>` and `@cache` (if present).

**Decorator order for cached endpoints** (e.g. `list_posts`, `get_post`):
```python
@router.get("/{username}/posts", ...)
@cache(key_prefix="...", ...)
@inject
async def list_posts_endpoint(...): ...
```

**Special case — `delete_user/presentation/router.py`:**
This router has a second helper, `_get_token_blacklist_adapter()`, in addition
to `_get_delete_user_use_case()`. Both helpers are removed. The endpoint gains
two `Provide[...]` parameters:

```python
@router.delete("/user/{username}", response_model=DeleteUserResponse, status_code=200)
@inject
async def delete_user_endpoint(
    username: str,
    current_user: Annotated[dict, Depends(get_current_user)],
    token: Annotated[str, Depends(oauth2_scheme)],
    use_case: Annotated[DeleteUserUseCase, Depends(Provide[Container.delete_user_use_case])],
    blacklist: Annotated[TokenBlacklistPort, Depends(Provide[Container.token_blacklist_adapter])],
) -> DeleteUserResponse: ...
```

**Container provider name mapping** (for reference during implementation):

| Router | Provider name |
|---|---|
| `create_user` | `Container.create_user_use_case` |
| `list_users` | `Container.list_users_use_case` |
| `get_user_by_username` | `Container.get_user_by_username_use_case` |
| `get_user_tier` | `Container.get_user_tier_use_case` |
| `update_user` | `Container.update_user_use_case` |
| `delete_user` | `Container.delete_user_use_case` (+ `Container.token_blacklist_adapter`) |
| `delete_db_user` | `Container.delete_db_user_use_case` |
| `assign_moderator` | `Container.assign_moderator_use_case` |
| `revoke_moderator` | `Container.revoke_moderator_use_case` |
| `create_post` | `Container.create_post_use_case` |
| `list_posts` | `Container.list_posts_use_case` |
| `list_all_posts` | `Container.list_all_posts_use_case` |
| `list_pending_posts` | `Container.list_pending_posts_use_case` |
| `get_post` | `Container.get_post_use_case` |
| `moderate_post` | `Container.moderate_post_use_case` |
| `revise_post` | `Container.revise_post_use_case` |
| `get_moderation_log` | `Container.get_moderation_log_use_case` |

### Step 3 — `shared_dependencies.py`: remove helper, add `@inject` + `Provide[...]`

`shared_dependencies.py` is STABLE. The change is limited to the
`_get_token_blacklist_adapter` function and the two dependency functions that
reference it.

Remove `_get_token_blacklist_adapter` entirely (function + its deferred import).

Add at the top-level imports:
```python
from dependency_injector.wiring import Provide, inject
from .bootstrap.container import Container
```

Update `get_current_user`:
```python
@inject
async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[AsyncSession, Depends(async_get_db)],
    blacklist: Annotated[TokenBlacklistPort, Depends(Provide[Container.token_blacklist_adapter])],
) -> dict[str, Any]:
    ...  # body unchanged
```

Update `get_optional_user`:
```python
@inject
async def get_optional_user(
    request: Request,
    db: AsyncSession = Depends(async_get_db),
    blacklist: TokenBlacklistPort = Depends(Provide[Container.token_blacklist_adapter]),
) -> dict | None:
    ...  # body unchanged
```

Note: `get_optional_user` uses the legacy `= Depends(...)` signature style
(not `Annotated`). Keep that style for the `db` and `blacklist` parameters to
avoid unrelated drift; only replace the callable inside `Depends`.

After this step, `shared_dependencies.py` imports `Container` at module level.
`factory.py` already imports `from ..shared_dependencies import get_current_superuser`,
so `container.py` is now guaranteed to be loaded (and wired) before the first
request, satisfying user story 7.

### Step 4 — `agent_docs/entry_points/fastapi.md`: make `wiring_config.modules` explicit

Locate the "Dependency injection at the endpoint" section that already shows the
`wiring_config` pattern. Add a prominently-worded note that adding a new slice
requires **three** bootstrap-level steps:

1. Add providers to `bootstrap/container.py` — unchanged from before.
2. Add the router to `bootstrap/router.py` — unchanged from before.
3. **Add the router's module path to `Container.wiring_config.modules`** — new
   mandatory step. Without it, `Provide[...]` silently resolves to the sentinel
   object instead of the use-case instance, causing `AttributeError` at request
   time (not at startup).

The anti-pattern entry already present ("❌ A new router whose module is not
added to `Container.wiring_config`") can remain; the new text reinforces it at
the positive-guidance level as well.

### Step 5 — Verify

Run in order:
```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

All outside-in tests and the smoke test (`tests/smoke/test_app_starts.py`) must
pass. The smoke test is the primary safety net for import-level wiring errors;
if it fails, the migration contains a circular-import or missing-wire bug that
unit tests will not surface.

Check that `ruff check` reports zero `PLC0415` suppressions inside
`src/app/features/` and `src/app/shared_dependencies.py` after the migration.

## 6. Tests planned

This migration produces **no new test files**. Observable behaviour is
unchanged; existing tests are the acceptance gate.

- **Outside-in tests (regression gate):** all 17 existing outside-in tests
  (`tests/features/<resource>/<NNNN>_<slice>/<slice>_outside_in_test.py`) must
  remain green. Each exercises a full HTTP round-trip with a real adapter and
  test Postgres; any wiring mistake that silently delivers the wrong object will
  surface as a `TypeError` or `AttributeError` during the request.
- **Smoke test:** `tests/smoke/test_app_starts.py` boots the app in a subprocess
  and pings `/health`. It will catch import-level circular imports or missing
  `WiringConfiguration` entries that produce errors at startup time.
- **Integration tests:** all existing `tests/features/.../presentation/test_router.py`
  files exercise the full endpoint stack and implicitly test override
  compatibility (`container.<provider>.override(mock)` used in test fixtures).

No adapter unit tests or use-case unit tests are added; there is no new
infrastructure logic to test.

## 7. Out of scope for this slice

- Changing any `providers.Factory` or `providers.Object` definition in
  `bootstrap/container.py`.
- Migrating legacy flat `features/` router functions that do not follow VSA
  structure (e.g. `patch_post`, `erase_post` in the old-style `posts/router.py`).
- Introducing `providers.Resource` for DB session or Redis lifecycle management.
- Adding or removing any use-case, adapter, domain, or port logic.
- Changing the `providers.Object(local_session)` pattern for the session factory.
- Upgrading `dependency_injector` or any other package version.

## 8. Open questions

None. All product and implementation decisions are recorded in the PRD.
