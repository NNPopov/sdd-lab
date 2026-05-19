# 0029 · erase_post — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0029_erase_post
- **PRD:** ./prd.md
- **Reference slice (primary):** `../../posts/0028_update_post/plan.md` — same
  resource, same ownership-check pattern (get user by username → check
  requester matches → get post → mutate). The most recently completed
  post-mutation slice.
- **Reference slice (secondary shape):** `../../users/0007_delete_user/plan.md`
  — same delete operation type (soft-delete with ownership enforcement).
- **HTTP path:** `DELETE /api/v1/{username}/post/{id}`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `erase_post_adapter` and `erase_post_use_case`
    providers, imports, and wiring module entry (permitted modification per
    `agent_docs/stable_vs_feature.md` § The one exception).
  - `bootstrap/router.py` — **not touched**; the posts aggregator
    (`features/posts/router.py`) is already registered there.

## 2. Context summary

An authenticated client sends `DELETE /api/v1/{username}/post/{id}` to
soft-delete one of their posts. The request is currently handled by a flat
function `erase_post` in `features/posts/router.py` that calls `crud_users`
and `crud_posts` directly, has no use-case class, no port, and no adapter.
This slice extracts that function into a proper vertical slice, fixes an
authorization gap (the flat function did not verify post ownership; the new
adapter filters by `created_by_user_id`), and introduces
`posts/_shared/policies.py::check_post_owner` for reuse by future
post-mutation slices. The HTTP contract is preserved: same path, same auth
requirement, same `{"message": "Post deleted"}` response, same status code
200, same cache-invalidation keys.

## 3. API contract

**Request body:** none (DELETE carries no body; all inputs come from path
params and auth token).

**Path parameters:**

| Param | Type | Notes |
|---|---|---|
| `username` | `str` | Identifies the resource owner |
| `id` | `int` | Post primary key |

**Response body** (`ErasePostResponse`):

| Field | Type | Notes |
|---|---|---|
| `message` | `str` | Always `"Post deleted"` on success |

**Status codes:**

- `200 OK` — post soft-deleted; `{"message": "Post deleted"}`.
- `401 Unauthorized` — missing or invalid token; raised by `get_current_user`
  before the use case is invoked.
- `403 Forbidden` — `ForbiddenDomainError`; `requester_username` does not
  match the path `username`.
- `404 Not Found` — `NotFoundDomainError("User not found")` when `username`
  resolves to no active user; `NotFoundDomainError("Post not found")` when
  `id` resolves to no non-deleted post owned by that user.
- `500 Internal Server Error` — any unexpected infrastructure failure caught
  by the global `_catch_all` handler.

## 4. File structure

New files:

```
src/app/features/posts/_shared/policies.py   # check_post_owner

src/app/features/posts/erase_post/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py               # ErasePostCommand
│   ├── entities.py               # ErasePostRecord
│   ├── ports/
│   │   ├── __init__.py
│   │   └── erase_post_port.py    # ErasePostPort
│   └── use_case.py               # ErasePostUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                # ErasePostAdapter(ErasePostPort)
└── presentation/
    ├── __init__.py
    ├── router.py                 # DELETE /{username}/post/{id}
    └── schemas.py                # ErasePostResponse
```

Existing files modified:

```
src/app/features/posts/router.py    # remove flat erase_post; add include_router(erase_post_router)
src/app/bootstrap/container.py      # add erase_post_adapter, erase_post_use_case providers
```

No new ORM model. No Alembic migration (no schema change — soft-delete uses
the existing `is_deleted` / `deleted_at` columns on the `Post` model).

## 5. Implementation steps

### Step 1 — Shared policy: `posts/_shared/policies.py`

**File:** `src/app/features/posts/_shared/policies.py`

Header: `# FEATURE: posts._shared — ownership policy.`

```python
from .....domain.errors import ForbiddenDomainError


def check_post_owner(requester_username: str, owner_username: str) -> None:
    if requester_username != owner_username:
        raise ForbiddenDomainError()
```

Mirrors `features/users/_shared/policies.py::check_owner` in shape and
naming convention. Named differently (`check_post_owner` vs `check_owner`)
to remain greppable per-feature. Imports `ForbiddenDomainError` via relative
path (per `agent_docs/architecture.md` § Import conventions).

### Step 2 — Domain: Command

**File:** `src/app/features/posts/erase_post/domain/commands.py`

Header: `# FEATURE: erase_post — domain command.`

```python
from pydantic import BaseModel


class ErasePostCommand(BaseModel):
    username: str
    post_id: int
    requester_username: str
```

Three fields: `username` (path param identifying the resource owner),
`post_id` (path param), and `requester_username` (from the auth token,
used for the ownership check). No optional fields.

### Step 3 — Domain: Entities

**File:** `src/app/features/posts/erase_post/domain/entities.py`

Header: `# FEATURE: erase_post — domain entities.`

```python
from pydantic import BaseModel


class ErasePostRecord(BaseModel):
    id: int
```

Minimal entity returned by `find_post`. The use case needs only the post's
`id` to confirm existence before calling `soft_delete`. `BaseModel` only;
no framework imports (per CLAUDE.md rule 2).

### Step 4 — Domain: Port

**File:** `src/app/features/posts/erase_post/domain/ports/erase_post_port.py`

Header: `# FEATURE: erase_post — port protocol.`

```python
from typing import Protocol, runtime_checkable

from ...._shared.entities import PostAuthor
from ..entities import ErasePostRecord


@runtime_checkable
class ErasePostPort(Protocol):
    async def get_user_by_username(self, username: str) -> PostAuthor | None: ...
    async def find_post(self, post_id: int, owner_id: int) -> ErasePostRecord | None: ...
    async def soft_delete(self, post_id: int) -> None: ...
```

Three methods, each representing one port responsibility (per
`agent_docs/architecture.md` § Terminology: port and adapter).
`@runtime_checkable` is mandatory. `PostAuthor` is reused from
`posts/_shared/entities.py` (id + username). `ErasePostRecord` is the
minimal existence-check return type.

### Step 5 — Domain: Use case

**File:** `src/app/features/posts/erase_post/domain/use_case.py`

Header: `# FEATURE: erase_post — use case.`

```python
from .....domain.errors import NotFoundDomainError
from ...._shared.policies import check_post_owner
from .commands import ErasePostCommand
from .ports.erase_post_port import ErasePostPort


class ErasePostUseCase:
    def __init__(self, port: ErasePostPort) -> None:
        self._port = port

    async def __call__(self, command: ErasePostCommand) -> None:
        user = await self._port.get_user_by_username(command.username)
        if user is None:
            raise NotFoundDomainError("User not found")
        check_post_owner(command.requester_username, user.username)
        post = await self._port.find_post(command.post_id, owner_id=user.id)
        if post is None:
            raise NotFoundDomainError("Post not found")
        await self._port.soft_delete(command.post_id)
```

Four-step sequence per PRD § Use case. `check_post_owner` raises
`ForbiddenDomainError` when the requester is not the path user (step 2).
`find_post` filtering by `owner_id` means a post owned by a different user
returns `None`, producing `NotFoundDomainError` (step 3) — this closes the
authorization gap in the flat function. Returns `None`; the router synthesizes
the response. Never raises `HTTPException`; never catches (per
`agent_docs/error_handling.md` § Use-case: raises, does not catch).

### Step 6 — Data: Adapter

**File:** `src/app/features/posts/erase_post/data/adapter.py`

Header: `# FEATURE: erase_post — data adapter.`

`class ErasePostAdapter(ErasePostPort)` — explicit inheritance from the port
is mandatory (per `agent_docs/architecture.md` § Adapter pattern).

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
    return ErasePostRecord(id=post.id)
```

The `created_by_user_id == owner_id` filter is the ownership-gap fix: a post
belonging to a different user returns `None`. No status filter — existence
and ownership are the only criteria. No `try/except`.

`soft_delete(post_id)`:

```python
async with self._session_factory() as session:
    await session.execute(
        update(Post)
        .where(Post.id == post_id)
        .values(is_deleted=True, deleted_at=datetime.now(UTC))
    )
    await session.commit()
```

No `try/except` — a soft-delete UPDATE has no unique-constraint path to catch;
any DB error propagates to the global handler (per
`agent_docs/error_handling.md`).

Imports: `datetime.UTC`, `datetime`, `sqlalchemy.select`, `sqlalchemy.update`,
ORM models `Post` and `User`, `PostAuthor` from `_shared/entities.py`,
`ErasePostRecord` from `..domain.entities`. All relative.

### Step 7 — Presentation: Schemas

**File:** `src/app/features/posts/erase_post/presentation/schemas.py`

Header: `# FEATURE: erase_post — request/response schemas.`

```python
from pydantic import BaseModel


class ErasePostResponse(BaseModel):
    message: str
```

No `ErasePostRequest` — DELETE carries no body; all inputs come from path
params and the auth token. The response matches the current flat function's
`{"message": "Post deleted"}` contract.

### Step 8 — Presentation: Router

**File:** `src/app/features/posts/erase_post/presentation/router.py`

Header: `# FEATURE: erase_post — HTTP router.`

Pattern: `@inject` + `Depends(Provide[Container.erase_post_use_case])`,
identical to the `update_post` and `get_post` sibling routers.

```python
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, Request

from .....adapters.cache.redis_cache import cache
from .....bootstrap.container import Container
from .....shared_dependencies import get_current_user
from ..domain.commands import ErasePostCommand
from ..domain.use_case import ErasePostUseCase
from .schemas import ErasePostResponse

router = APIRouter(tags=["posts"])


@router.delete("/{username}/post/{id}", response_model=ErasePostResponse, status_code=200)
@cache(
    "{username}_post_cache",
    resource_id_name="id",
    to_invalidate_extra={"{username}_posts": "{username}"},
)
@inject
async def erase_post_endpoint(
    request: Request,
    username: str,
    id: int,
    current_user: Annotated[dict, Depends(get_current_user)],
    use_case: Annotated[ErasePostUseCase, Depends(Provide[Container.erase_post_use_case])],
) -> ErasePostResponse:
    command = ErasePostCommand(
        username=username,
        post_id=id,
        requester_username=current_user["username"],
    )
    await use_case(command)
    return ErasePostResponse(message="Post deleted")
```

`to_invalidate_extra` preserves the exact cache-invalidation contract from the
current flat function (not `pattern_to_invalidate_extra` — see the existing
`erase_post` decorator in `features/posts/router.py`). `request: Request` is
the first parameter because the `@cache` decorator requires it (per
`agent_docs/entry_points/fastapi.md` § Common mistakes). No `try/except`; no
business logic.

### Step 9 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — permitted modification)

Add two imports alongside the other posts-slice imports at the top:

```python
from ..features.posts.erase_post.data.adapter import ErasePostAdapter
from ..features.posts.erase_post.domain.use_case import ErasePostUseCase
```

Add two providers after the existing `update_post_use_case` entry:

```python
erase_post_adapter = providers.Factory(
    ErasePostAdapter,
    session_factory=session_factory,
)

erase_post_use_case = providers.Factory(
    ErasePostUseCase,
    port=erase_post_adapter,
)
```

Add one wiring module entry in `wiring_config.modules`:

```python
f"{_app_pkg}.features.posts.erase_post.presentation.router",
```

All three sub-steps are mandatory (per `agent_docs/entry_points/fastapi.md` §
Dependency injection at the endpoint — "Adding a new slice requires three
bootstrap steps — all three are mandatory").

### Step 10 — Flat router cleanup

**File:** `src/app/features/posts/router.py` (FEATURE file)

Remove the `erase_post` endpoint function and its two decorators
(`@router.delete` and `@cache`).

Before removing, verify which imports are used only by `erase_post` and
are not needed by `erase_db_post` or any remaining flat function:

- `from ...domain.errors import ForbiddenDomainError, NotFoundDomainError` —
  check if still needed by `erase_db_post` (it uses `NotFoundDomainError`
  but not `ForbiddenDomainError`; remove `ForbiddenDomainError` from the
  import).
- `from ..users.repository import crud_users` — needed by `erase_db_post`.
- `from ..users.schemas import UserRead` — needed by `erase_db_post`.
- `from .repository import crud_posts` — needed by `erase_db_post`.
- `from .schemas import PostRead` — needed by `erase_db_post`.

Add alongside the other slice-router imports:

```python
from .erase_post.presentation.router import router as erase_post_router
```

Add after the last `include_router` call:

```python
router.include_router(erase_post_router)
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
pytest tests/features/posts/0029_erase_post/erase_post_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test at
`tests/smoke/test_app_starts.py`.

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/posts/0029_erase_post/domain/test_use_case.py`.
  Mock `ErasePostPort`. Assert all branches:
  - `get_user_by_username` returns `None` → `NotFoundDomainError("User not found")`.
  - User found, `requester_username` differs from `user.username` → `ForbiddenDomainError`.
  - User found, requester matches, `find_post` returns `None` → `NotFoundDomainError("Post not found")`.
  - All checks pass → `port.soft_delete` called, no exception raised.
  Prior art: `tests/features/posts/0026_get_post/domain/test_use_case.py`,
  `tests/features/posts/0028_update_post/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/posts/0029_erase_post/data/test_adapter.py`.
  Run against test Postgres (real database). Seed rows and assert:
  - `get_user_by_username`: active user exists → `PostAuthor` returned; user
    missing → `None`; user is soft-deleted → `None`.
  - `find_post`: post exists, owned by user, not deleted → `ErasePostRecord`
    returned; post missing → `None`; post belongs to a different user → `None`;
    post is soft-deleted → `None`.
  - `soft_delete`: after call, row has `is_deleted=True` and `deleted_at` is
    set to a non-null `datetime`.
  No `try/except` in the adapter → no catch path to assert.
  Prior art: `tests/features/posts/0026_get_post/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/posts/0029_erase_post/presentation/test_router.py`.
  `httpx.AsyncClient` against the running app with test Postgres. Assert:
  - Authenticated as owner, post exists → HTTP 200, `{"message": "Post deleted"}`.
  - Authenticated as owner, post not found → HTTP 404.
  - Authenticated as owner, post belongs to a different user → HTTP 404.
  - Authenticated as a different user (path username is someone else) → HTTP 403.
  - Unauthenticated → HTTP 401.
  - Unknown `username` in path → HTTP 404.
  Prior art: `tests/features/posts/0026_get_post/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/posts/0029_erase_post/erase_post_outside_in_test.py`.
  Full HTTP stack with real adapter and test Postgres, no mocks. Covers the
  scenario from PRD § Testing Decisions:
  1. Seed `alice` and `bob`.
  2. Alice creates a post.
  3. Bob attempts `DELETE /api/v1/bob/post/{alice_post_id}` (authenticated as
     Bob; post belongs to Alice) → HTTP 404.
  4. Bob attempts `DELETE /api/v1/alice/post/{alice_post_id}` (authenticated
     as Bob pretending to be Alice) → HTTP 403.
  5. Alice deletes her own post: `DELETE /api/v1/alice/post/{alice_post_id}`
     authenticated as Alice → HTTP 200, `{"message": "Post deleted"}`.
  6. DB assertion: post row has `is_deleted=True`.
  7. Subsequent `GET /api/v1/alice/post/{alice_post_id}` → HTTP 404 (post gone).
  This test is the acceptance gate; the slice is not done until it is green and
  all pre-existing outside-in tests remain green.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Refactoring `erase_db_post` — remains as a flat function in `posts/router.py`
  and is a separate future slice.
- Hard (permanent) deletion — the `erase_db_post` endpoint is untouched.
- Cache key rotation or invalidation strategy changes — the existing key
  contract (`{username}_post_cache` / `to_invalidate_extra`) is preserved
  deliberately.
- Rate-limit configuration — handled cross-cuttingly by the existing middleware.
- Moderation-status-based deletion gates (e.g. preventing deletion of an
  `approved` post) — out of scope; the two-step port design accommodates this
  in a future slice without an interface change.
- Adopting `check_post_owner` in the existing `update_post` slice — that slice
  is already green; a refactor is a separate concern.

## 8. Open questions

None. All design decisions are resolved in the PRD.
