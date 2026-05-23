# PRD — 0035: Get Tier (`GET /tier/{name}`)

## Problem Statement

The `GET /tier/{name}` endpoint is implemented as a fat FastAPI handler in
`features/tiers/router.py` that calls a FastCRUD repository directly, performs
a None-check inline, and returns a raw `dict[str, Any]`. There is no use-case
class, no port, no query object, and no DI container wiring. This violates the
project's Vertical Slice + Hexagonal architecture and makes the endpoint
untestable in isolation.

## Solution

Extract the endpoint into a proper vertical slice at
`features/tiers/get_tier/` following the same structure as
`features/users/get_user_by_username/`. The handler becomes a thin router that
converts the path parameter into a `GetTierQuery` and delegates to
`GetTierUseCase` via a DI-managed port. The adapter executes a single
SQLAlchemy SELECT filtered by name and maps the result to a `TierItem`. The
use case owns the not-found check and raises `NotFoundDomainError` when the
adapter returns `None`. The old `read_tier` handler is deleted after the new
slice is in place.

## User Stories

1. As an API consumer, I want to fetch a tier by its name, so that I can
   display the details of a specific subscription tier.
2. As an API consumer, I want the response to include the tier's id, name, and
   creation timestamp, so that I have all relevant details in a single call.
3. As an API consumer, I want to receive HTTP 404 when the requested tier name
   does not exist, so that I can handle the missing-resource case gracefully.
4. As an API consumer (unauthenticated), I want to call this endpoint without
   a token, so that public-facing UIs can display tier information without
   requiring a user session.
5. As a developer, I want the not-found logic isolated in the use-case, so
   that it can be unit-tested with a mocked port without a database or HTTP
   stack.
6. As a developer, I want the data adapter injected via a port protocol, so
   that the persistence implementation can be swapped without touching the
   use-case or router.
7. As a developer, I want the adapter to use raw SQLAlchemy rather than
   FastCRUD, so that the query is explicit and the result type is fully
   controlled.
8. As a developer, I want the slice wired into the DI container, so that
   dependency injection is consistent with all other slices in the project.
9. As a developer, I want the old `read_tier` handler removed after the new
   slice is live, so that there is exactly one implementation of this
   behaviour.
10. As a developer, I want `TierItem` imported from the shared tier entities
    module, so that the domain vocabulary is consistent across all tier slices.

## Implementation Decisions

### Modules to build

- **Domain query** — `GetTierQuery(name: str)`. Pure Pydantic model, no
  framework imports.
- **Port** — `GetTierPort`, a `@runtime_checkable` Protocol with a single
  method: `get(query: GetTierQuery) -> TierItem | None`. Returning `None`
  (rather than raising) keeps the port neutral — the use-case owns the
  not-found semantics.
- **Use case** — `GetTierUseCase`, a class with `__init__(port: GetTierPort)`
  and `async def __call__(query: GetTierQuery) -> TierItem`. Calls
  `self._port.get(query)`; raises `NotFoundDomainError("Tier not found")` if
  the result is `None`; otherwise returns the `TierItem`.
- **Data adapter** — `GetTierAdapter(GetTierPort)`. Receives an
  `async_sessionmaker`. The `get` method executes
  `SELECT id, name, created_at FROM tier WHERE name = :name` and maps the
  row to `TierItem`, or returns `None` if no row is found. No FastCRUD usage.
  The adapter does not catch any exceptions — there are no
  business-meaningful infrastructure errors on a plain SELECT.
- **Presentation schemas** — `GetTierResponse` mirroring `TierItem` fields
  (`id: int`, `name: str`, `created_at: datetime`;
  `model_config = ConfigDict(from_attributes=True)`). Slice-local; does not
  reuse `tiers/schemas.py`.
- **Presentation router** — single `GET /tier/{name}` endpoint. No auth
  dependency. Builds `GetTierQuery(name=name)`, calls the use-case, maps the
  returned `TierItem` to `GetTierResponse`. Status code 200.

### Modules to modify

- **`features/tiers/router.py`** — the `read_tier` handler is removed and
  the `get_tier` sub-router is included. The remaining handlers
  (`write_tier`, `read_tiers`, `patch_tier`, `erase_tier`) stay in place until
  their respective slices (0033, 0034, 0036, 0037) are complete.
- **`bootstrap/container.py`** — two new providers: `get_tier_adapter`
  (Factory, receives `session_factory`) and `get_tier_use_case` (Factory,
  receives `get_tier_adapter`). Wiring entry added for
  `features.tiers.get_tier.presentation.router`.

### Architectural decisions

- **Port returns `None`, use case raises**: the adapter signals absence by
  returning `None`; the use case translates that into `NotFoundDomainError`.
  This pattern is identical to `get_user_by_username` and keeps the port free
  of domain error knowledge.
- **No soft delete**: the `Tier` ORM model has no `is_deleted` field. The
  SELECT has no deleted-row filter — every row in the table is a live tier.
- **No auth**: `GET /tier/{name}` is a public read-only endpoint. No superuser
  or authentication check is added.
- **Endpoint URL unchanged**: the new slice preserves `GET /tier/{name}`
  (singular) to maintain backward compatibility with existing API consumers.
- **ORM model unchanged**: `adapters/db/models/tier.py` is `# STABLE` and
  is not modified.

## Testing Decisions

Good tests verify observable behavior through the public interface, not
implementation details. They do not assert which internal methods were called
unless the call itself is the observable behavior under test.

### Use-case unit test

- Mock `GetTierPort` with `pytest-mock`.
- Happy path: mock `port.get` to return a `TierItem`; call
  `GetTierUseCase` with a `GetTierQuery(name="gold")`; assert the returned
  `TierItem` matches the mock's return value.
- Not-found path: mock `port.get` to return `None`; assert
  `NotFoundDomainError` is raised.
- Prior art: `tests/features/users/0004_get_user_by_username/` use-case unit
  test.

### Adapter unit test

- Use a real async session against the test Postgres database (no mocks).
- Happy path: seed a tier row, call `GetTierAdapter.get()` with the matching
  name; assert the returned `TierItem` has the correct `id`, `name`, and
  `created_at`.
- Not-found path: call `get()` with a name that does not exist in the
  database; assert `None` is returned.
- Prior art: `tests/features/users/0004_get_user_by_username/` adapter unit
  test.

### Endpoint integration test

- Use `httpx.AsyncClient` against the running app with test Postgres.
- Assert HTTP 200 and correct `GetTierResponse` JSON shape for an existing
  tier.
- Assert HTTP 404 when the name does not match any tier.
- Assert no authentication is required (unauthenticated request returns 200
  for an existing tier).
- Prior art: `tests/features/users/0004_get_user_by_username/` integration
  test.

### Outside-in test

- Acceptance gate for the slice. Must be RED before implementation, GREEN
  after.
- Covers the full happy path: seed a tier, call `GET /api/v1/tier/{name}`,
  assert HTTP 200 and that the response body contains the correct `id`,
  `name`, and `created_at`.

## Out of Scope

- Migrating `create_tier`, `list_tiers`, `update_tier`, or `delete_tier`
  (separate slices 0033, 0034, 0036, 0037).
- Lookup by id — only name-based lookup is implemented.
- Caching — not present on the current endpoint and not added here.
- Returning soft-deleted tiers — the ORM model has no soft-delete field.
- Removing `tiers/schemas.py` or `tiers/repository.py` — still referenced by
  `rate_limits/` and `users/` features.

## Further Notes

- The `request: Request` parameter present in the old flat handler is dropped;
  it is not needed without a cache decorator.
- The HTTP path `GET /tier/{name}` (singular) is preserved for backward
  compatibility. URL normalisation to plural `/tiers/{name}` is deferred.
- This is the simplest of the five tier slices: single SELECT, one error
  case, no write side-effects, no auth. It serves as a clean reference for
  the more complex `update_tier` and `delete_tier` slices that follow.
