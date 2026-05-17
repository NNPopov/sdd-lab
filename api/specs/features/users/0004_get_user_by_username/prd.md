# PRD — 0004: get_user_by_username

## Problem Statement

The `GET /user/{username}` endpoint is implemented as a flat free function that
injects an `AsyncSession` directly via FastAPI `Depends`, calls FastCRUD's
`crud_users.get()`, and returns a raw `dict[str, Any]`. This structure violates
the project's Vertical Slice + Hexagonal architecture: there is no domain query
object, no port protocol, no use-case class, and no adapter. It is also
forbidden by CLAUDE.md, which explicitly bans FastCRUD and requires use cases
to be classes with `__call__()`. The endpoint cannot be tested in isolation,
cannot be reused from non-HTTP entry points (Celery, Langgraph), and cannot be
type-checked end-to-end.

## Solution

Refactor the `GET /user/{username}` endpoint into a proper vertical slice at
`features/users/get_user_by_username/`, following the same hexagonal shape as
the already-refactored `create_user` and `list_users` slices. The slice
contains a domain query object, a `FoundUser` entity, a narrow `Protocol` port,
a use-case class, a SQLAlchemy adapter, and a presentation layer with
request/response schemas and a FastAPI router. The flat `use_cases/user_get_by_username.py`
file is deleted. The feature router is updated to include the new slice router.
The DI container gains two new providers.

## User Stories

1. As a developer, I want `GET /user/{username}` to return user details so that
   clients can look up a user profile by username.
2. As a developer, I want the endpoint to return HTTP 404 with a domain error
   when the username does not exist, so that clients can handle missing users
   gracefully.
3. As a developer, I want deleted users (`is_deleted = true`) to be excluded
   from the result, so that soft-deleted accounts are not exposed.
4. As a developer, I want the use case to be a class with `__call__()` so that
   it can be invoked from Celery tasks or Langgraph nodes without importing the
   HTTP layer.
5. As a developer, I want a narrow `Protocol` port so that the use case can be
   unit-tested with a mock adapter without touching the database.
6. As a developer, I want the adapter to explicitly inherit from the port so
   that the port→adapter binding is discoverable by text search and AI agents.
7. As a developer, I want the DI container to wire the adapter and use case so
   that FastAPI endpoints receive fully-constructed use cases without manual
   construction.
8. As a developer, I want the presentation layer to define its own
   `GetUserByUsernameResponse` schema so that the slice has no dependency on
   legacy flat schemas.
9. As a developer, I want all imports inside `src/app/` to be relative so that
   the slice is portable across entry points.
10. As a developer, I want every new `.py` file to carry a `# FEATURE:` header
    so that changeability is immediately visible to humans and AI tools.

## Implementation Decisions

- **Slice folder:** `features/users/get_user_by_username/` with the canonical
  `domain/`, `data/`, `presentation/` sub-structure and `__init__.py` at every
  level.
- **Domain query:** `GetUserByUsernameQuery(username: str)` — a Pydantic
  `BaseModel` in `domain/commands.py`. Single field; no pagination.
- **Domain entity:** `FoundUser` in `domain/entities.py` — fields: `id`,
  `name`, `username`, `email`, `profile_image_url`, `tier_id`.
- **Port:** `GetUserByUsernamePort` (`@runtime_checkable Protocol`) with one
  method: `async def get(self, query: GetUserByUsernameQuery) -> FoundUser | None`.
- **Use case:** `GetUserByUsernameUseCase` — calls `self._port.get(query)`,
  raises `NotFoundDomainError` if `None`, returns `FoundUser`.
- **Adapter:** `GetUserByUsernameAdapter(GetUserByUsernamePort)` — uses
  `async_sessionmaker`, queries `User` ORM model with
  `WHERE username = ? AND is_deleted = False`. Soft-delete filter is hardcoded
  (not exposed via query). Maps ORM row to `FoundUser`.
- **Presentation schemas:** `GetUserByUsernameResponse` in
  `presentation/schemas.py` — same 6 fields as `FoundUser`, with
  `ConfigDict(from_attributes=True)`.
- **Router:** `GET /user/{username}`, public (no auth dependency), returns
  `GetUserByUsernameResponse`. Uses local-import pattern for container access
  (same as `create_user` and `list_users`).
- **Container:** Two new `providers.Factory` entries —
  `get_user_by_username_adapter` and `get_user_by_username_use_case`.
- **Feature router:** Replaces direct `read_user` registration with
  `router.include_router(get_user_by_username_router)`. Removes `UserRead`
  import for this route.
- **Deleted file:** `features/users/use_cases/user_get_by_username.py` is
  removed once the new slice is wired and tested.

## Testing Decisions

A good test verifies observable behavior through public interfaces only — never
internal implementation details. Tests call the use case or endpoint as a
consumer would; they do not assert on ORM queries or private methods.

- **Use-case unit test:** instantiate `GetUserByUsernameUseCase` with a mock
  port; verify it returns `FoundUser` on success and raises
  `NotFoundDomainError` when the port returns `None`. Prior art:
  `tests/features/users/0003_list_users/` use-case unit tests.
- **Adapter unit test:** mock `async_sessionmaker`; verify the adapter returns
  a correctly-constructed `FoundUser` when a matching non-deleted row exists,
  and returns `None` when no row is found. Prior art: `0003_list_users` adapter
  tests.
- **Endpoint integration test:** `httpx.AsyncClient` against the running app
  with the test Postgres; `GET /user/{username}` returns 200 + correct body for
  an existing user, 404 for an unknown username. Prior art: `0001_create_user`
  endpoint integration tests.
- **Outside-in test:** single acceptance test through the HTTP endpoint against
  a real database; seed a user, call `GET /user/{username}`, assert 200 and all
  6 response fields. This is the acceptance gate — slice is not done until it
  is green.

## Out of Scope

- Auth / access control on `GET /user/{username}` — the endpoint stays public.
- Exposing soft-deleted users via a query parameter or separate endpoint.
- Refactoring any other flat use-case files in `use_cases/` (those are separate
  slices).
- Caching (`@cache` decorator) — not present on the current endpoint; not added
  here.
- `get_user_by_id` or any other lookup strategy — separate slice if ever
  needed.

## Further Notes

- The `request: Request` parameter present in the old flat function is dropped;
  it served no purpose (likely a FastCRUD/cache artefact).
- The `use_cases/` directory is not deleted — other flat files remain until
  their own refactor slices land.
- The HTTP path `/user/{username}` is unchanged; this refactor is
  non-breaking to API consumers.
