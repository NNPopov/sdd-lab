# Entry point: FastAPI

This document is the reference for the **FastAPI presentation layer** — routers,
endpoints, request/response schemas, exception handlers, dependencies. Read it
whenever you write or modify code in any slice's `presentation/` folder.

For business logic (use-case), see `agent_docs/architecture.md`. For error
mapping rules, see `agent_docs/error_handling.md`.

Other entry points (Celery, Langgraph) will be documented in sibling files
when the first real task or node lands. Until then, the patterns in this file
are the only entry-point patterns in use.

## Where the FastAPI layer lives

Each slice's HTTP surface is in `features/<resource>/<use_case>/presentation/`:

```
features/users/create_user/presentation/
├── __init__.py
├── router.py            # APIRouter + endpoint function
└── schemas.py           # CreateUserRequest, CreateUserResponse
```

Routers are aggregated in `bootstrap/router.py` under the `/api/v1` prefix.

## Endpoint shape

An endpoint is a **thin function**. Its job is to convert HTTP types to domain
types, invoke the use-case, and convert the result back. Nothing else.

```python
# FEATURE: create_user — router.
from typing import Annotated

from dependency_injector.wiring import Provide
from fastapi import APIRouter, Depends, status

from app.bootstrap.container import Container
from app.features.users.create_user.domain.commands import CreateUserCommand
from app.features.users.create_user.domain.use_case import CreateUserUseCase
from app.features.users.create_user.presentation.schemas import (
    CreateUserRequest,
    CreateUserResponse,
)

router = APIRouter(tags=["users"])


@router.post(
    "/users",
    response_model=CreateUserResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_user_endpoint(
    request: CreateUserRequest,
    use_case: Annotated[
        CreateUserUseCase,
        Depends(Provide[Container.create_user_use_case]),
    ],
) -> CreateUserResponse:
    command = CreateUserCommand(**request.model_dump())
    user = await use_case(command)
    return CreateUserResponse.model_validate(user)
```

What the endpoint does:

1. Accepts the validated `CreateUserRequest` (FastAPI does the Pydantic
   validation automatically).
2. Receives the use-case from the DI container.
3. Converts the request into a domain `CreateUserCommand` (one line).
4. Awaits the use-case.
5. Converts the returned domain entity into a `CreateUserResponse`.

What the endpoint **does not** do:

- No business logic.
- No `try/except`. Domain errors propagate to the exception handler.
- No direct database access. No `Session = Depends(get_db)`.
- No conditional logic that depends on user state — that belongs in the
  use-case.

## Request and Response schemas

Per-slice in `presentation/schemas.py`:

```python
# FEATURE: create_user — request/response schemas.
from pydantic import BaseModel, ConfigDict, EmailStr, Field


class CreateUserRequest(BaseModel):
    """HTTP body for POST /users."""
    model_config = ConfigDict(from_attributes=True)

    username: str = Field(min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(min_length=8)


class CreateUserResponse(BaseModel):
    """HTTP body returned by POST /users."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str
    email: EmailStr
    is_superuser: bool
```

Naming:

- Request schemas end in `Request`.
- Response schemas end in `Response`.
- Field-level Pydantic validation (min_length, regex, EmailStr) is used here,
  not in the domain command. The command assumes valid input.

The Request and the Command may have identical fields for trivial slices. The
duplication is the cost of keeping `domain/` independent of HTTP. The cost is
one extra class and one conversion line.

## Path conventions

REST-style, plural resource names:

- `POST /users` — create
- `GET /users` — list
- `GET /users/{username}` — get one
- `PATCH /users/{username}` — update
- `DELETE /users/{username}` — delete

All endpoints live under `/api/v1`. Versioning happens at this prefix level,
not per-endpoint.

Nested resources reflect ownership in the URL:

- `GET /users/{username}/posts` — posts of a user
- `POST /users/{username}/posts` — create a post
- `DELETE /users/{username}/posts/{post_id}` — delete a post

## Dependency injection at the endpoint

Use the `dependency_injector` pattern with `Annotated` and `Provide`:

```python
from typing import Annotated
from dependency_injector.wiring import Provide
from fastapi import Depends

from app.bootstrap.container import Container

async def endpoint(
    use_case: Annotated[SomeUseCase, Depends(Provide[Container.some_use_case])],
) -> ...: ...
```

The container module must be **wired** for this to work:

```python
# bootstrap/container.py
class Container(containers.DeclarativeContainer):
    wiring_config = containers.WiringConfiguration(
        modules=[
            "app.features.users.create_user.presentation.router",
            "app.features.users.list_users.presentation.router",
            # ... one entry per router module
        ]
    )
```

Adding a slice means adding its router module to the wiring list. This is
permitted as part of normal feature work (the same way adding a router to
`bootstrap/router.py` is permitted).

## Auth dependencies

Standard auth dependencies live in `features/auth/_shared/dependencies.py` or
`features/users/_shared/dependencies.py` (depending on where session is
managed):

```python
# features/users/_shared/dependencies.py
async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    session: Annotated[AsyncSession, Depends(Provide[Container.db_session])],
) -> CurrentUser: ...

async def get_current_superuser(
    user: Annotated[CurrentUser, Depends(get_current_user)],
) -> CurrentUser:
    if not user.is_superuser:
        raise ForbiddenDomainError("Superuser required")
    return user
```

Endpoints that require an authenticated user inject one of these:

```python
async def delete_post_endpoint(
    post_id: int,
    actor: Annotated[CurrentUser, Depends(get_current_user)],
    use_case: Annotated[DeletePostUseCase, Depends(Provide[Container.delete_post_use_case])],
) -> None:
    command = DeletePostCommand(post_id=post_id, acting_user=actor)
    await use_case(command)
```

The `acting_user` travels into the use-case as part of the command. The
use-case uses it for authorization (`if post.author != command.acting_user`).

## Exception handlers

Registered once in `bootstrap/factory.py`. See `agent_docs/error_handling.md`
for the full pattern. The summary:

- `ValidationDomainError` → 422 with `field_errors` payload.
- All other `DomainError` subclasses → status from `exc.http_status`, with
  `{"message": ...}` payload.
- Anything else escaping → 500, logged at ERROR level. Reaching this case
  indicates an adapter let a non-`DomainError` exception escape — a bug.

Endpoints do **not** wrap calls in try/except. Domain errors propagate
naturally; the handler converts them.

## Caching

The project's `@cache` decorator (`adapters/cache/redis_cache.py`) is applied
at the endpoint level for read paths:

```python
from app.adapters.cache.redis_cache import cache


@router.get("/users/{username}/posts")
@cache(
    key_prefix="user_posts:{username}:page_{page}:per_{items_per_page}",
    resource_id_name="username",
    expiration=60,
)
async def list_user_posts_endpoint(
    request: Request,  # required by the decorator
    username: str,
    page: int = 1,
    items_per_page: int = 20,
    use_case: Annotated[ListUserPostsUseCase, Depends(Provide[Container.list_user_posts_use_case])],
) -> ListUserPostsResponse: ...
```

Invalidation on writes:

```python
@router.delete("/users/{username}/posts/{post_id}")
@cache(
    key_prefix="user_post:{post_id}",
    resource_id_name="post_id",
    pattern_to_invalidate_extra=["user_posts:{username}:*"],
)
async def delete_post_endpoint(...): ...
```

When to use cache:

- Read endpoints with high traffic and stable data.
- Read endpoints where freshness within ~minute is acceptable.

When not:

- Write endpoints (decorated only for invalidation, not caching).
- User-specific endpoints where the cache key explosion is impractical.
- Endpoints serving security-sensitive data (audit logs, etc.).

## Rate limiting

`shared_dependencies.rate_limiter_dependency` is attached at the router level
for paths that need it:

```python
from app.shared_dependencies import rate_limiter_dependency

router = APIRouter(
    tags=["auth"],
    dependencies=[Depends(rate_limiter_dependency)],
)
```

Apply rate limiting to login, registration, password reset, and any expensive
public endpoint. Internal endpoints behind auth do not need it by default.

## Anti-patterns

- ❌ Business logic in the endpoint function. Move to the use-case.
- ❌ Direct database access in the endpoint (`session: AsyncSession =
  Depends(...)`). The use-case receives a port; the adapter behind the port has
  the session. The endpoint never touches `AsyncSession`.
- ❌ `try/except DomainError` in the endpoint. The exception handler does it.
- ❌ Endpoint returns a domain entity directly without converting to the
  Response schema. The response schema is the API contract; without it,
  internal fields leak.
- ❌ Endpoint returns `dict` instead of a Pydantic Response model. Loses the
  contract and OpenAPI docs.
- ❌ Endpoint signature mixes path params, query params, and the request body
  in an order FastAPI infers wrong. Use explicit `Body(...)` if needed, but
  prefer a clean signature with one `Request` body.
- ❌ Reading from `request.state` inside the endpoint to get the current user.
  Use the auth dependency.
- ❌ Hardcoding the `/api/v1` prefix on individual routers. Routers declare
  their own paths starting with `/`; the prefix is added once in
  `bootstrap/router.py`.
- ❌ A new router that is not registered in `bootstrap/router.py`. Without
  registration, the endpoints exist in source but not at runtime.
- ❌ A new router whose module is not added to `Container.wiring_config`. The
  `Provide[...]` injection silently returns the provider object instead of the
  resolved instance.

## Common mistakes

- ❌ Forgetting `request: Request` as the first parameter when using
  `@cache(...)`. The decorator requires it.
- ❌ Status code mismatch — `@router.post("/")` with no `status_code=201`
  returns 200 for creation, against REST convention.
- ❌ Response model includes private fields (`hashed_password`,
  `created_by_user_id`). Use a Response schema that whitelists fields.
- ❌ `OAuth2PasswordRequestForm` accepted in the endpoint function but the
  command expects domain fields. Convert before calling the use-case.
- ❌ Putting endpoint-level dependencies (auth, rate limit) on a sub-router
  expecting them to inherit from the parent. FastAPI inheritance for
  `dependencies=[...]` works only when the parent is `include_router`'d with
  them; otherwise declare on the sub-router explicitly.
