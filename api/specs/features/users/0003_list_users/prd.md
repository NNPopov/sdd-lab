# PRD — 0003 list_users

## Problem Statement

The existing `GET /users` endpoint is implemented as a free function in
`features/users/use_cases/user_list.py`. It violates three hard architectural
rules:

1. It is a free function, not a use-case class.
2. It depends directly on `FastCRUD` (`crud_users.get_multi`,
   `compute_offset`, `paginated_response`), which is forbidden.
3. It couples transport-layer objects (`Request`, `Depends`, `AsyncSession`)
   directly into the use-case, making it untestable in isolation.

As a result, the slice cannot be unit-tested, cannot be wired through the DI
container, and does not participate in the hexagonal architecture that every
other new slice follows.

## Solution

Refactor the `GET /users` endpoint into a proper hexagonal vertical slice
named `list_users`, matching the structure and conventions established by the
`create_user` slice. The external HTTP contract (`GET /users`, query
parameters, response fields) remains unchanged. The internal implementation
is replaced entirely: free function → use-case class, FastCRUD → hand-written
SQLAlchemy ORM queries, direct session injection → port/adapter/DI container
wiring.

## User Stories

1. As an API consumer, I want `GET /users` to continue accepting `page` and
   `items_per_page` query parameters, so that my existing pagination logic
   keeps working.
2. As an API consumer, I want the response to include `items`, `total_count`,
   `page`, and `items_per_page` fields, so that I can render paginated user
   lists with accurate metadata.
3. As an API consumer, I want deleted users (`is_deleted=true`) to be excluded
   from the list automatically, so that I never see soft-deleted accounts in
   normal listing.
4. As a developer, I want the list-users logic encapsulated in a use-case
   class with a `__call__` method, so that I can instantiate it with a mock
   port in unit tests without touching the database.
5. As a developer, I want the data access for listing users defined in an
   adapter that implements a typed Protocol, so that the use case remains
   independent of SQLAlchemy.
6. As a developer, I want the `ListUsersAdapter` to use SQLAlchemy ORM
   queries (not FastCRUD helpers), so that there is no forbidden library
   dependency in the slice.
7. As a developer, I want the list-users use case and adapter wired in the DI
   container, so that the endpoint receives its dependency through
   `dependency_injector` Provides, not through manual construction.
8. As a developer, I want the old `use_cases/user_list.py` file removed, so
   that no code can accidentally import the non-conforming free function.
9. As a developer, I want the `GET /users` router registered via
   `include_router`, matching the `create_user` pattern, so that the users
   router stays consistent.
10. As a developer, I want `ListUsersPort` decorated with `@runtime_checkable`,
    so that `isinstance()` diagnostics work at runtime.
11. As a developer, I want the HTTP response schema owned by the
    `list_users/presentation/` layer, so that it is not coupled to any
    third-party schema class.
12. As a developer, I want pagination offset computed from `page` and
    `items_per_page` inside the adapter, so that the domain layer has no
    knowledge of SQL offsets.

## Implementation Decisions

### New slice structure

A new folder `features/users/list_users/` is created with three sub-layers:

- **`domain/`** — pure Python; no framework or ORM imports.
  - `commands.py` — `ListUsersQuery` Pydantic model (`page`, `items_per_page`).
  - `entities.py` — `ListedUser` (id, name, username, email,
    profile_image_url, tier_id) and `UserPage` (items, total_count, page,
    items_per_page).
  - `ports/list_users_port.py` — `ListUsersPort` runtime-checkable Protocol
    with a single method `list(query) -> UserPage`.
  - `use_case.py` — `ListUsersUseCase` class; `__init__` accepts a
    `ListUsersPort`; `__call__(query: ListUsersQuery) -> UserPage` delegates
    entirely to the port.
- **`data/`** — SQLAlchemy adapter.
  - `adapter.py` — `ListUsersAdapter(ListUsersPort)` takes an
    `async_sessionmaker`; issues two ORM queries (COUNT then paginated SELECT)
    filtered to `is_deleted=False`; maps ORM rows to `ListedUser`; returns
    `UserPage`.
- **`presentation/`** — HTTP boundary.
  - `schemas.py` — `ListUsersResponse` Pydantic model (flat: `items`,
    `total_count`, `page`, `items_per_page`); `ListedUserSchema` for each
    item.
  - `router.py` — `GET /users`; resolves `ListUsersUseCase` from the
    container; converts `UserPage` entity to `ListUsersResponse`.

### DI container changes

`bootstrap/container.py` gains two new providers:

- `list_users_adapter` — `Factory(ListUsersAdapter, session_factory=…)`
- `list_users_use_case` — `Factory(ListUsersUseCase, port=list_users_adapter)`

### Router changes

`features/users/router.py` replaces the inline `router.get("/users", …)(read_users)`
registration with `router.include_router(list_users_router)`.

### Deleted file

`features/users/use_cases/user_list.py` is deleted in full.

### Soft-delete filter

`is_deleted=False` is a fixed predicate inside the adapter. It is not exposed
as a query parameter. Listing deleted users is a separate use case outside
this PRD's scope.

### Response shape

The new `ListUsersResponse` is a clean Pydantic schema with fields:
`items: list[ListedUserSchema]`, `total_count: int`, `page: int`,
`items_per_page: int`. It does not subclass or depend on any fastcrud type.

## Testing Decisions

A good test in this project asserts only externally observable behaviour —
what the use case returns or raises given a particular port state — never
internal implementation details (which SQL was generated, how many times a
method was called, etc.).

### Use-case unit test

- Construct `ListUsersUseCase` with a mock `ListUsersPort`.
- Assert that the use case returns exactly the `UserPage` the port returns.
- This layer has no business logic to branch on, so one happy-path test is
  sufficient; the test exists mainly to confirm DI wiring and the call
  convention.
- Prior art: `tests/features/users/0001_create_user/` use-case unit test.

### Adapter unit test

- Construct `ListUsersAdapter` with a real in-memory SQLite async session (or
  a mock `async_sessionmaker`).
- Assert that it returns the correct `UserPage` shape.
- Assert that soft-deleted rows are excluded.
- Assert that offset and limit are applied correctly (seed 15 rows, request
  page 2 / items_per_page 5, assert 5 items returned with correct offset).
- Prior art: `tests/features/users/0002_refactor_create_user_adapter/`.

### Endpoint integration test

- Spin up the full app via `httpx.AsyncClient` against the test Postgres.
- `GET /users?page=1&items_per_page=5` → assert 200, response schema shape,
  and that soft-deleted users are absent.
- Prior art: endpoint integration tests in `tests/features/users/0001_create_user/`.

### Outside-in test

- The acceptance gate for the slice.
- Calls `GET /users` end-to-end; asserts the full response contract.
- Slice is not done until this test is green.

## Out of Scope

- Listing soft-deleted users (a separate admin use case).
- Search or filtering by name, username, or email.
- Sorting.
- Cursor-based pagination.
- Any change to other use cases in the `users` feature.
- Authentication or authorization on the list endpoint (left as-is).

## Further Notes

- The `create_user` slice (`specs/features/users/0001_create_user/`) and its
  adapter refactor (`0002_refactor_create_user_adapter/`) are the canonical
  reference implementations for this project's hexagonal pattern.
- `bootstrap/container.py` is marked `# STABLE` but has been explicitly
  approved for modification as part of this slice (confirmed during grill-me).
- The external HTTP contract (`GET /users`, parameters, field names) must not
  change — this is a structural refactor only.
