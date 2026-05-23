# PRD — 0034: List Tiers (`GET /tiers`)

## Problem Statement

The `GET /tiers` endpoint is implemented as a fat FastAPI handler in
`features/tiers/router.py` that calls FastCRUD's `get_multi` and
`paginated_response` helpers directly, with no use-case class, no port, no
query object, and no DI container wiring. The response shape is dictated by
FastCRUD's `PaginatedListResponse`, which includes a `data` key and a
`has_more` flag — both inconsistent with the pagination shape used by all
migrated post and user slices. This violates the project's Vertical Slice +
Hexagonal architecture and makes the endpoint untestable in isolation.

## Solution

Extract the endpoint into a proper vertical slice at
`features/tiers/list_tiers/`. The handler becomes a thin router that converts
query parameters into a `ListTiersQuery` and delegates to `ListTiersUseCase`
via a DI-managed port. The data adapter performs manual SQLAlchemy COUNT +
SELECT with offset/limit, eliminating the FastCRUD dependency. The response
shape aligns with the rest of the project: `items`, `total_count`, `page`,
`items_per_page` — no `data` key, no `has_more` flag.

## User Stories

1. As an API consumer, I want to retrieve a paginated list of all tiers, so
   that I can display available subscription tiers to users.
2. As an API consumer, I want each tier in the list to include its id, name,
   and creation timestamp, so that I can render the full tier details.
3. As an API consumer, I want to control page size via `page` and
   `items_per_page` query parameters, so that I can adapt the response volume
   to the client's needs.
4. As an API consumer, I want the response to include a `total_count` field,
   so that I can build pagination controls without a separate count request.
5. As an API consumer, I want to call this endpoint without authentication, so
   that public-facing UIs can list tiers without requiring a user session.
6. As an API consumer, I want an empty `items` list when no tiers exist rather
   than an error, so that I receive a consistent 200 response for all valid
   pagination requests.
7. As a developer, I want the pagination logic isolated in a use-case class,
   so that it can be unit-tested with a mocked port without a database.
8. As a developer, I want the data adapter injected via a port protocol, so
   that the persistence implementation can be swapped without touching the
   use-case or router.
9. As a developer, I want the adapter to use raw SQLAlchemy COUNT + SELECT
   rather than FastCRUD helpers, so that the query is explicit and the result
   shape is fully under our control.
10. As a developer, I want the response shape (`items`, `total_count`, `page`,
    `items_per_page`) to match the post and user list endpoints, so that API
    consumers have a consistent pagination contract across resources.
11. As a developer, I want the slice wired into the DI container, so that
    dependency injection is consistent with all other slices in the project.
12. As a developer, I want the old `read_tiers` handler removed after the new
    slice is live, so that there is exactly one implementation of this
    behaviour.

## Implementation Decisions

### Modules to build

- **Domain query** — `ListTiersQuery(page: int, items_per_page: int)`. Pure
  Pydantic model, no framework imports. Default values (`page=1`,
  `items_per_page=10`) are applied in the router, not in the query class.
- **Port** — `ListTiersPort`, a `@runtime_checkable` Protocol with a single
  method: `list(query: ListTiersQuery) -> TierPage`.
- **Use case** — `ListTiersUseCase`, a class with `__init__(port: ListTiersPort)`
  and `async def __call__(query: ListTiersQuery) -> TierPage`. Delegates
  entirely to the port — no conditional logic in the use-case body. The
  use-case boundary exists for architectural consistency and DI testability.
- **Data adapter** — `ListTiersAdapter(ListTiersPort)`. Receives an
  `async_sessionmaker`. The `list` method issues two SQLAlchemy statements
  in the same session: `SELECT COUNT(*) FROM tier` for the total, then
  `SELECT id, name, created_at FROM tier ORDER BY id LIMIT :limit OFFSET
  :offset` for the page. Maps each row to a `TierItem` and returns a
  `TierPage`. No FastCRUD usage. No error cases — an empty table returns
  `TierPage(items=[], total_count=0, page=query.page,
  items_per_page=query.items_per_page)`.
- **Presentation schemas** — `ListTiersResponse` mirroring `TierPage` fields
  (`items: list[TierItemSchema]`, `total_count: int`, `page: int`,
  `items_per_page: int`; `model_config = ConfigDict(from_attributes=True)`).
  `TierItemSchema` mirrors `TierItem` (`id`, `name`, `created_at`). These are
  slice-local schemas; they do not reuse `tiers/schemas.py`.
- **Presentation router** — single `GET /tiers` endpoint. No auth dependency.
  Reads `page` and `items_per_page` from query params with defaults. Builds
  `ListTiersQuery`, calls the use-case, maps the returned `TierPage` to
  `ListTiersResponse`. Status code 200.

### Modules to modify

- **`features/tiers/router.py`** — the `read_tiers` handler is removed and
  the `list_tiers` sub-router is included. The remaining handlers
  (`write_tier`, `read_tier`, `patch_tier`, `erase_tier`) stay in place until
  their respective slices (0033, 0035–0037) are complete.
- **`bootstrap/container.py`** — two new providers: `list_tiers_adapter`
  (Factory, receives `session_factory`) and `list_tiers_use_case` (Factory,
  receives `list_tiers_adapter`). Wiring entry added for
  `features.tiers.list_tiers.presentation.router`.

### Architectural decisions

- **No FastCRUD**: the adapter issues two explicit SQLAlchemy statements.
  This makes the COUNT and SELECT queries transparent, matches the pattern
  established by `list_posts` and `list_users`, and removes the dependency
  on FastCRUD's opaque `paginated_response` helper.
- **Response shape change**: the current endpoint returns FastCRUD's
  `PaginatedListResponse` shape (`data`, `total_count`, `has_more`,
  `page`, `items_per_page`). The new slice changes the shape to
  (`items`, `total_count`, `page`, `items_per_page`), aligning with the
  project standard. This is a breaking API change; it is acceptable because
  this migration is the intended moment to standardise.
- **No auth**: `GET /tiers` is a public read-only endpoint. No superuser or
  authentication check is added.
- **No error cases**: a missing or empty tier table returns an empty paginated
  response (HTTP 200). `NotFoundDomainError` is never raised in this slice.
- **Shared entities from `_shared/`**: `TierItem` and `TierPage` are imported
  from `tiers/_shared/entities.py` (created in slice 0033). They must not be
  redefined locally.
- **ORDER BY id**: results are sorted by primary key to produce a stable,
  reproducible page order. No sort parameter is exposed in this slice.

## Testing Decisions

Good tests verify observable behavior through the public interface, not
implementation details. They do not assert which internal methods were called
unless the call itself is the observable behavior under test.

### Use-case unit test

- Mock `ListTiersPort` with `pytest-mock`.
- Call `ListTiersUseCase` with a `ListTiersQuery(page=1, items_per_page=10)`.
- Assert the use-case returns whatever the mock port's `list` method returns,
  unchanged.
- No error-path test needed — the use-case has no conditional logic.
- Prior art: `tests/features/posts/0009_list_posts/` use-case unit test.

### Adapter unit test

- Use a real async session against the test Postgres database (no mocks).
- Happy path: seed two tiers, call `ListTiersAdapter.list()` with
  `page=1, items_per_page=10`; assert `total_count=2` and `items` contains
  both tiers with correct `id`, `name`, `created_at`.
- Pagination: seed three tiers, call with `page=1, items_per_page=2`; assert
  `total_count=3` and `items` has two entries. Call again with `page=2`;
  assert `items` has one entry.
- Empty table: call with no seeded tiers; assert `total_count=0` and
  `items=[]`.
- Prior art: `tests/features/posts/0009_list_posts/` adapter unit test.

### Endpoint integration test

- Use `httpx.AsyncClient` against the running app with test Postgres.
- Assert HTTP 200 and correct JSON shape (`items`, `total_count`, `page`,
  `items_per_page`) for a database with seeded tiers.
- Assert HTTP 200 with `items=[]` and `total_count=0` when no tiers exist.
- Assert correct `items_per_page` truncation when the page size is smaller
  than the total count.
- Assert no authentication is required (unauthenticated request returns 200).
- Prior art: `tests/features/posts/0009_list_posts/` integration test.

### Outside-in test

- Acceptance gate for the slice. Must be RED before implementation, GREEN
  after.
- Covers the full happy path: seed two tiers, call `GET /api/v1/tiers`,
  assert HTTP 200 and that the response body matches the expected pagination
  shape with `total_count=2` and both tiers in `items`.

## Out of Scope

- Migrating `create_tier`, `get_tier`, `update_tier`, or `delete_tier`
  (separate slices 0033, 0035–0037).
- Filtering, sorting by name, or full-text search on the list endpoint.
- Adding authentication or authorisation checks to `GET /tiers`.
- Exposing an `updated_at` field — the current `TierItem` entity does not
  include it and the ORM model's `updated_at` column is not surfaced here.
- Removing `tiers/schemas.py` or `tiers/repository.py` — still referenced
  by `rate_limits/` and `users/` features.

## Further Notes

- The `PaginatedListResponse[TierRead]` type from FastCRUD is dropped entirely.
  No FastCRUD import remains in the new presentation layer.
- The response shape change (`data` → `items`, removal of `has_more`) is a
  breaking change for any client relying on the current `GET /tiers` shape.
  The migration window is the appropriate moment to make this correction; no
  backwards-compatibility shim is added.
- This slice establishes the pattern for the remaining tiers slices. All five
  slices (0033–0037) must land before `tiers/schemas.py` and
  `tiers/repository.py` can be safely deleted.
