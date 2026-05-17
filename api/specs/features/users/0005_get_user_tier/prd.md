# PRD — 0005 get_user_tier

## Problem Statement

The `read_user_tier` function in `use_cases/user_tier_get.py` retrieves the tier
assigned to a user by username. It is implemented as a free async function that
directly injects a database session and two FastCRUD repository instances via
FastAPI `Depends`. This bypasses the hexagonal port/adapter boundary, making the
business logic untestable in isolation and inconsistent with every other slice in
the `users` feature.

An API caller navigating to `GET /user/{username}/tier` receives correct data
today, but the code cannot be unit-tested without a live database, cannot be
wired through the DI container, and does not follow the vertical-slice structure
that every other use case in this feature already uses.

## Solution

Refactor `read_user_tier` into a proper vertical slice named `get_user_tier/`
inside `features/users/`, following the same structure established by
`get_user_by_username/`. The HTTP contract (`GET /user/{username}/tier`,
response shape, status codes) must remain unchanged so that existing callers are
not affected.

The old free-function file is deleted once the slice is wired.

## User Stories

1. As an API consumer, I want `GET /user/{username}/tier` to return the same JSON
   payload as today, so that my client code does not need to change.
2. As an API consumer, I want a 404 response when the requested username does not
   exist, so that I can distinguish "user not found" from other errors.
3. As an API consumer, I want a 200 response with a `null` body when the user
   exists but has no tier assigned, so that I can handle the "no tier" case
   without treating it as an error.
4. As an API consumer, I want a 404 response when the user has a `tier_id` but
   the tier record no longer exists, so that I receive a meaningful error rather
   than a 500.
5. As a backend developer, I want the tier-retrieval logic to live in a use-case
   class with a port interface, so that I can unit-test it with a mocked port
   without a database.
6. As a backend developer, I want the database queries to be encapsulated in an
   adapter that implements the port, so that the adapter can be swapped or tested
   independently.
7. As a backend developer, I want the slice registered in the DI container, so
   that it participates in the same wiring as `create_user`, `list_users`, and
   `get_user_by_username`.
8. As a backend developer, I want the HTTP router to be self-contained inside the
   slice's `presentation/` layer, so that `features/users/router.py` only needs
   to include it, not define it.
9. As a backend developer, I want the old `use_cases/user_tier_get.py` free
   function removed once the slice is live, so that there is no dead code.
10. As a backend developer, I want the response entity to carry tier fields
    prefixed with `tier_` (e.g. `tier_id`, `tier_name`, `tier_created_at`), so
    that the JSON shape is identical to the current implementation.

## Implementation Decisions

### Modules to build

- **Domain query** — `GetUserTierQuery` with a single `username: str` field.
  Input to the use case; keeps the domain free of HTTP concerns.

- **Domain entity** — `FoundUserTier` with fields `tier_id: int`,
  `tier_name: str`, `tier_created_at: datetime`. Field names keep the `tier_`
  prefix to match the existing JSON contract.

- **Port** — `GetUserTierPort`, a `@runtime_checkable Protocol` with a single
  `async def get(query) -> FoundUserTier | None` method. Returns `None` when the
  user exists but has no tier.

- **Use case** — `GetUserTierUseCase` class with `__call__(query) -> FoundUserTier | None`.
  Raises `NotFoundDomainError("User not found")` when the port returns a
  sentinel indicating user absence. Returns `None` when user has no tier. Raises
  `NotFoundDomainError("Tier not found")` when the user has a `tier_id` but the
  tier record is missing.

- **Adapter** — `GetUserTierAdapter(GetUserTierPort)`. Issues two separate async
  SQLAlchemy queries: first fetches the `User` row by username (soft-delete
  filter applied), then fetches the `Tier` row by the user's `tier_id`. Returns
  `None` sentinel for "user not found", `None` for "no tier assigned", or a
  populated `FoundUserTier`.

- **Presentation schema** — `GetUserTierResponse` (Pydantic, `from_attributes=True`)
  with the same three `tier_*` fields as the entity, plus `None` as a valid
  response body.

- **HTTP router** — `GET /user/{username}/tier` returning
  `response_model=GetUserTierResponse | None` with status 200. Constructs
  `GetUserTierQuery`, calls the use case, maps the entity to the response schema.
  No `Request` parameter.

### DI container changes

Two new providers added to `Container`: one `Factory` for
`GetUserTierAdapter` (receives `session_factory`) and one `Factory` for
`GetUserTierUseCase` (receives the adapter as its port).

### Router changes

`features/users/router.py` replaces the inline `read_user_tier` registration
with `router.include_router(get_user_tier_router)`.

### Deleted file

`features/users/use_cases/user_tier_get.py` is removed.

### Behavioral invariants (must not change)

- HTTP route and verb: `GET /user/{username}/tier`
- Response when user not found: 404
- Response when user has no tier: 200 with `null` body
- Response when tier record missing: 404
- Response field names: `tier_id`, `tier_name`, `tier_created_at`
- No `Request` object in the use case or adapter

## Testing Decisions

A good test asserts externally observable behavior — what the use case returns or
raises given a port's response — not how the adapter executes its queries.

### Use-case unit test

Mock `GetUserTierPort`. Cover:
- Port returns a populated `FoundUserTier` → use case returns it unchanged.
- Port returns `None` for "no tier" → use case returns `None`.
- Port returns the "user not found" sentinel → use case raises `NotFoundDomainError`.
- Port signals "tier missing" → use case raises `NotFoundDomainError`.

Prior art: `tests/features/users/0004_get_user_by_username/` use-case unit test.

### Adapter unit test

Mock `async_sessionmaker` / `AsyncSession`. Cover:
- User row not found → adapter returns user-not-found sentinel.
- User found, `tier_id` is `None` → adapter returns no-tier `None`.
- User found, tier row found → adapter returns populated `FoundUserTier`.
- User found, `tier_id` set, tier row missing → adapter signals tier missing.

Prior art: `tests/features/users/0004_get_user_by_username/` adapter unit test.

### Endpoint integration test

`httpx.AsyncClient` against the running app with test Postgres. Cover:
- Username exists with tier → 200, correct JSON fields.
- Username exists, no tier → 200, `null`.
- Username not found → 404.
- Username exists, tier_id dangling → 404.

Prior art: `tests/features/users/0004_get_user_by_username/` endpoint integration test.

### Outside-in test

Single test that exercises the full stack from HTTP through the real database.
Acts as the acceptance gate; the slice is not done until this test is green.

## Out of Scope

- Changes to the `Tier` or `User` ORM models or migrations.
- Caching (`@cache` decorator) on this endpoint — not present today and not
  requested.
- Pagination, filtering, or any query parameters beyond `username`.
- Refactoring any other old-style use-case free functions (those are separate
  slices).
- Changes to `GET /user/{username}/tier` auth/authorization rules — the endpoint
  is currently unprotected and remains so.

## Further Notes

The adapter issues two sequential database queries rather than a JOIN. This
matches the current behavior and keeps the adapter logic straightforward. A JOIN
optimization is a separate, future concern.

The `tier_` prefix on response fields is kept deliberately for backward
compatibility even though it is redundant given the `/tier` path segment. A
naming cleanup would be a breaking change and is out of scope.
