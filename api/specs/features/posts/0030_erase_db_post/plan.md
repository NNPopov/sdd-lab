# 0030 · erase_db_post — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0030_erase_db_post
- **PRD:** ./prd.md
- **Reference slice:** `../../posts/0029_erase_post/plan.md` — same resource,
  same three-method port shape (`get_user_by_username` / `find_post` /
  terminal-action). The most recently completed post-deletion slice.
- **HTTP path:** `DELETE /api/v1/{username}/db_post/{id}`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `erase_db_post_adapter` and
    `erase_db_post_use_case` providers, imports, and wiring module entry
    (permitted modification per `agent_docs/stable_vs_feature.md` § The one
    exception).
  - `.importlinter` — add one `ignore_imports` entry for the new router
    (required per `agent_docs/entry_points/fastapi.md` § Dependency injection
    at the endpoint).

## 2. Context summary

A superuser sends `DELETE /api/v1/{username}/db_post/{id}` to permanently
remove a post row from the database. The request is currently handled by a
flat function `erase_db_post` in `features/posts/router.py` that calls
`crud_users` and `crud_posts` (FastCRUD) directly, has no use-case class, no
port, and no adapter. This slice extracts that function into a proper vertical
slice, closes an ownership gap (the flat function never verified that `{id}`
belongs to `{username}`), and preserves the exact HTTP contract: same path,
same `get_current_superuser` requirement, same
`{"message": "Post deleted from the database"}` response, same status code
200, same cache-invalidation keys.

## 3. API contract

**Request body:** none (DELETE carries no body; all inputs come from path
params and the auth token).

**Path parameters:**

| Param | Type | Notes |
|---|---|---|
| `username` | `str` | Identifies the resource owner namespace |
| `id` | `int` | Post primary key |

**Response body** (`EraseDbPostResponse`):

| Field | Type | Notes |
|---|---|---|
| `message` | `str` | Always `"Post deleted from the database"` on success |

**Status codes:**

- `200 OK` — post permanently deleted; `{"message": "Post deleted from the database"}`.
- `401 Unauthorized` — missing or invalid token; raised by `get_current_user`
  (called inside `get_current_superuser`) before the use case runs.
- `403 Forbidden` — `ForbiddenDomainError`; caller is authenticated but is not
  a superuser; raised by `get_current_superuser` before the use case runs.
- `404 Not Found` — `NotFoundDomainError("User not found")` when `username`
  resolves to no active user; `NotFoundDomainError("Post not found")` when
  `id` resolves to no non-soft-deleted post owned by `username`.
- `500 Internal Server Error` — any unexpected infrastructure failure caught by
  the global `_catch_all` handler.

## 4. File structure

New files:

```
src/app/features/posts/erase_db_post/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                    # EraseDbPostCommand
│   ├── entities.py                    # EraseDbPostRecord
│   ├── ports/
│   │   ├── __init__.py
│   │   └── erase_db_post_port.py      # EraseDbPostPort
│   └── use_case.py                    # EraseDbPostUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                     # EraseDbPostAdapter(EraseDbPostPort)
└── presentation/
    ├── __init__.py
    ├── router.py                      # DELETE /{username}/db_post/{id}
    └── schemas.py                     # EraseDbPostResponse
```

Existing files modified:

```
src/app/features/posts/router.py    # remove flat erase_db_post; add include_router(erase_db_post_router)
src/app/bootstrap/container.py      # add erase_db_post_adapter, erase_db_post_use_case providers
.importlinter                       # add ignore_imports entry for erase_db_post router
```

No new ORM model. No Alembic migration (no schema change — hard-delete uses the
existing `Post` table).

## 5. Implementation steps

### Step 1 — Domain: Command

**File:** `src/app/features/posts/erase_db_post/domain/commands.py`

Header: `# FEATURE: erase_db_post — domain command.`

```python
from pydantic import BaseModel


class EraseDbPostCommand(BaseModel):
    username: str
    post_id: int
```

Two fields: `username` (path param identifying the resource owner namespace)
and `post_id` (path param identifying the post). No `requester_username` —
superuser authorization is enforced at the router layer via
`get_current_superuser` before the use case runs. The use case has no
caller-identity policy to enforce.

### Step 2 — Domain: Entities

**File:** `src/app/features/posts/erase_db_post/domain/entities.py`

Header: `# FEATURE: erase_db_post — domain entities.`

```python
from pydantic import BaseModel


class EraseDbPostRecord(BaseModel):
    id: int
```

Minimal entity returned by `find_post`. Defined independently from
`ErasePostRecord` in `erase_post` — the two slices must not share types across
slice boundaries (per `agent_docs/architecture.md` § Cross-slice imports).

### Step 3 — Domain: Port

**File:** `src/app/features/posts/erase_db_post/domain/ports/erase_db_post_port.py`

Header: `# FEATURE: erase_db_post — port protocol.`

```python
from typing import Protocol, runtime_checkable

from ...._shared.entities import PostAuthor
from ..entities import EraseDbPostRecord


@runtime_checkable
class EraseDbPostPort(Protocol):
    async def get_user_by_username(self, username: str) -> PostAuthor | None: ...
    async def find_post(self, post_id: int, owner_id: int) -> EraseDbPostRecord | None: ...
    async def hard_delete(self, post_id: int) -> None: ...
```

Three methods, each one port responsibility (per `agent_docs/architecture.md`
§ Terminology: port and adapter). `@runtime_checkable` is mandatory. `PostAuthor`
is reused from `posts/_shared/entities.py` (provides `id` + `username`).
`EraseDbPostRecord` is this slice's own minimal existence-check return type.

### Step 4 — Domain: Use case

**File:** `src/app/features/posts/erase_db_post/domain/use_case.py`

Header: `# FEATURE: erase_db_post — use case.`

```python
from .....domain.errors import NotFoundDomainError
from .commands import EraseDbPostCommand
from .ports.erase_db_post_port import EraseDbPostPort


class EraseDbPostUseCase:
    def __init__(self, port: EraseDbPostPort) -> None:
        self._port = port

    async def __call__(self, command: EraseDbPostCommand) -> None:
        user = await self._port.get_user_by_username(command.username)
        if user is None:
            raise NotFoundDomainError("User not found")
        post = await self._port.find_post(command.post_id, owner_id=user.id)
        if post is None:
            raise NotFoundDomainError("Post not found")
        await self._port.hard_delete(command.post_id)
```

Three-step sequence per PRD § Use case. No `check_post_owner` — superuser
gate is at the router layer. A superuser who uses the wrong username namespace
gets 404 ("Post not found") because `find_post` filters by `owner_id` and
returns `None`. Returns `None`; the router synthesizes the response. Never
raises `HTTPException`; never catches (per
`agent_docs/error_handling.md` § Use-case: raises, does not catch).

### Step 5 — Data: Adapter

**File:** `src/app/features/posts/erase_db_post/data/adapter.py`

Header: `# FEATURE: erase_db_post — data adapter.`

`class EraseDbPostAdapter(EraseDbPostPort)` — explicit inheritance from the
port is mandatory (per `agent_docs/architecture.md` § Adapter pattern).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`get_user_by_username(username)`:

```python
async with self._session_factory() as session:
    result = await session.execute(
        select(User).where(User.username == username, User.is_deleted.is_(False))
    )
    user = result.scalar_one_or_none()
    if user is None:
        return None
    return PostAuthor.model_validate(user)
```

No `try/except` (per `agent_docs/error_handling.md` § Right shape: read-only
query, no catch).

`find_post(post_id, owner_id)`:

```python
async with self._session_factory() as session:
    result = await session.execute(
        select(Post).where(
            Post.id == post_id,
            Post.created_by_user_id == owner_id,
            Post.is_deleted.is_(False),
        )
    )
    post = result.scalar_one_or_none()
    if post is None:
        return None
    return EraseDbPostRecord(id=post.id)
```

`created_by_user_id == owner_id` is the ownership-gap fix. `is_deleted.is_(False)`
excludes soft-deleted posts — hard-delete is only for live posts. No
`try/except`.

`hard_delete(post_id)`:

```python
async with self._session_factory() as session:
    await session.execute(delete(Post).where(Post.id == post_id))
    await session.commit()
```

Issues a permanent `DELETE FROM post WHERE id=:id`. No `try/except` — there
are no business-meaningful infrastructure exceptions to translate for a
hard-delete (per PRD § Adapter). Unknown failures propagate to the global
handler.

Imports: `sqlalchemy.select`, `sqlalchemy.delete`, ORM models `Post` and
`User`, `PostAuthor` from `_shared/entities.py`, `EraseDbPostRecord` from
`..domain.entities`. All relative.

### Step 6 — Presentation: Schemas

**File:** `src/app/features/posts/erase_db_post/presentation/schemas.py`

Header: `# FEATURE: erase_db_post — request/response schemas.`

```python
from pydantic import BaseModel


class EraseDbPostResponse(BaseModel):
    message: str
```

No `EraseDbPostRequest` — DELETE carries no body. The distinct message text
`"Post deleted from the database"` (vs. `erase_post`'s `"Post deleted"`) is
preserved deliberately: it is the only observable signal that a hard delete
occurred.

### Step 7 — Presentation: Router

**File:** `src/app/features/posts/erase_db_post/presentation/router.py`

Header: `# FEATURE: erase_db_post — HTTP router.`

```python
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, Request

from .....adapters.cache.redis_cache import cache
from .....bootstrap.container import Container
from .....shared_dependencies import get_current_superuser
from ..domain.commands import EraseDbPostCommand
from ..domain.use_case import EraseDbPostUseCase
from .schemas import EraseDbPostResponse

router = APIRouter(tags=["posts"])


@router.delete("/{username}/db_post/{id}", response_model=EraseDbPostResponse, status_code=200)
@cache(
    "{username}_post_cache",
    resource_id_name="id",
    to_invalidate_extra={"{username}_posts": "{username}"},
)
@inject
async def erase_db_post_endpoint(
    request: Request,
    username: str,
    id: int,
    _: Annotated[dict, Depends(get_current_superuser)],
    use_case: Annotated[EraseDbPostUseCase, Depends(Provide[Container.erase_db_post_use_case])],
) -> EraseDbPostResponse:
    command = EraseDbPostCommand(username=username, post_id=id)
    await use_case(command)
    return EraseDbPostResponse(message="Post deleted from the database")
```

`get_current_superuser` is injected as `_` because the superuser identity is
not passed into the command — its only purpose is authorization enforcement
before the use case runs. `to_invalidate_extra` preserves the exact
cache-invalidation contract from the current flat function. `request: Request`
is the first parameter because the `@cache` decorator requires it (per
`agent_docs/entry_points/fastapi.md` § Common mistakes). No `try/except`; no
business logic.

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — permitted modification)

Add two imports alongside the other posts-slice imports at the top:

```python
from ..features.posts.erase_db_post.data.adapter import EraseDbPostAdapter
from ..features.posts.erase_db_post.domain.use_case import EraseDbPostUseCase
```

Add two providers after the existing `erase_post_use_case` entry:

```python
erase_db_post_adapter = providers.Factory(
    EraseDbPostAdapter,
    session_factory=session_factory,
)

erase_db_post_use_case = providers.Factory(
    EraseDbPostUseCase,
    port=erase_db_post_adapter,
)
```

Add one wiring module entry in `wiring_config.modules`:

```python
f"{_app_pkg}.features.posts.erase_db_post.presentation.router",
```

All three sub-steps are mandatory (per `agent_docs/entry_points/fastapi.md`
§ Dependency injection at the endpoint).

### Step 9 — Import linter

**File:** `.importlinter` (project root)

Add one line to the `ignore_imports` list of the `[importlinter:contract:vsa-feature-independence]`
section, after the `erase_post` entry:

```
app.features.posts.erase_db_post.presentation.router -> app.bootstrap.container
```

Required per `agent_docs/entry_points/fastapi.md` § Dependency injection at
the endpoint — without it the architecture gate test fails.

### Step 10 — Flat router cleanup

**File:** `src/app/features/posts/router.py` (FEATURE file)

Remove the `erase_db_post` endpoint function and its two decorators
(`@router.delete` and `@cache`).

After removal, audit which imports are no longer needed. With `erase_post`
already removed in slice 0029, `erase_db_post` is the last flat post-deletion
function. Check whether `crud_users`, `crud_posts`, `UserRead`, `PostRead`,
`get_current_superuser` and any `DomainError` imports are still required by
any remaining flat function. Remove those that are solely referenced by
`erase_db_post`.

Add alongside the other slice-router imports:

```python
from .erase_db_post.presentation.router import router as erase_db_post_router
```

Add after the last `include_router` call:

```python
router.include_router(erase_db_post_router)
```

`bootstrap/router.py` is **not touched** — it already aggregates
`features/posts/router.py` and the chain is unchanged.

### Step 11 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/posts/0030_erase_db_post/erase_db_post_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test at
`tests/smoke/test_app_starts.py`.

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/posts/0030_erase_db_post/domain/test_use_case.py`.
  Mock `EraseDbPostPort`. Assert all branches:
  - `get_user_by_username` returns `None` → `NotFoundDomainError("User not found")`.
  - User found, `find_post` returns `None` → `NotFoundDomainError("Post not found")`.
  - Both checks pass → `port.hard_delete` called, no exception raised.
  Prior art: `tests/features/posts/0029_erase_post/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/posts/0030_erase_db_post/data/test_adapter.py`.
  Run against test Postgres (real database). Seed rows and assert:
  - `get_user_by_username`: active user exists → `PostAuthor` returned; user
    missing → `None`; user is soft-deleted → `None`.
  - `find_post`: post exists, owned by user, not soft-deleted →
    `EraseDbPostRecord` returned; post missing → `None`; post belongs to a
    different user → `None`; post is soft-deleted → `None`.
  - `hard_delete`: after call, the row no longer exists in the database (not
    soft-deleted — gone).
  No `try/except` in the adapter → no catch path to assert.
  Prior art: `tests/features/posts/0029_erase_post/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/posts/0030_erase_db_post/presentation/test_router.py`.
  `httpx.AsyncClient` against the running app with test Postgres. Assert:
  - Authenticated as superuser, correct user and post → HTTP 200,
    `{"message": "Post deleted from the database"}`.
  - Authenticated as superuser, unknown username → HTTP 404.
  - Authenticated as superuser, post does not exist → HTTP 404.
  - Authenticated as superuser, post belongs to a different user (wrong
    namespace) → HTTP 404.
  - Authenticated as superuser, post is soft-deleted → HTTP 404.
  - Authenticated as non-superuser → HTTP 403.
  - Unauthenticated → HTTP 401.
  Prior art: `tests/features/posts/0029_erase_post/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/posts/0030_erase_db_post/erase_db_post_outside_in_test.py`.
  Full HTTP stack with real adapter and test Postgres, no mocks. Covers the
  scenario from PRD § Testing Decisions:
  1. Seed `alice` (regular user) and `admin` (superuser).
  2. Alice creates a post.
  3. Admin attempts `DELETE /api/v1/bob/db_post/{alice_post_id}` (wrong
     username namespace) → HTTP 404.
  4. Non-superuser attempts `DELETE /api/v1/alice/db_post/{alice_post_id}`
     → HTTP 403.
  5. Admin hard-deletes: `DELETE /api/v1/alice/db_post/{alice_post_id}`
     → HTTP 200, `{"message": "Post deleted from the database"}`.
  6. DB assertion: the post row no longer exists (not soft-deleted — gone).
  7. Subsequent `GET /api/v1/alice/post/{alice_post_id}` → HTTP 404.
  This test is the acceptance gate; the slice is not done until it is green and
  all pre-existing outside-in tests remain green.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Soft-delete of posts (`erase_post`, slice 0029) — separate completed slice.
- Hard-deletion of already-soft-deleted posts — a future data-purge slice if
  needed.
- Adoption of `posts/_shared/policies.py::check_post_owner` — `erase_db_post`
  performs no caller-identity check in the use case; the policy is not needed.
- Cache key rotation or invalidation strategy changes — the existing contract is
  preserved deliberately.
- Rate-limit configuration — handled cross-cuttingly by existing middleware.
- Moderation-status-based deletion gates — out of scope.

## 8. Open questions

None. All design decisions are resolved in the PRD.
