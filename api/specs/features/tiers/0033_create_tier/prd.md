# PRD — 0033: Create Tier (`POST /tier`)

## Problem Statement

The `POST /tier` endpoint is implemented as a fat FastAPI handler in
`features/tiers/router.py` that calls a FastCRUD repository directly, performs
a duplicate-name check inline with a `SELECT EXISTS`, and builds the internal
tier object in the HTTP layer. There is no use-case class, no port, no command
object, and no DI container wiring. This violates the project's Vertical Slice
+ Hexagonal architecture and makes the business logic untestable in isolation.

Additionally, the current `SELECT EXISTS` approach for duplicate detection is
fragile under concurrent inserts. A concurrent request can pass the existence
check and then fail on the database unique constraint, resulting in an unhandled
`IntegrityError` rather than a clean domain error.

## Solution

Extract the endpoint into a proper vertical slice at
`features/tiers/create_tier/` following the same structure as
`features/posts/create_post/` and `features/users/create_user/`. The handler
becomes a thin router that converts the HTTP request into a `CreateTierCommand`
and delegates to `CreateTierUseCase` via a DI-managed port. The adapter does a
direct `INSERT` and catches `IntegrityError` — eliminating the race condition
and centralising the duplicate-name policy. The old `write_tier` handler is
deleted after the new slice is in place.

A new `tiers/_shared/entities.py` module is created alongside this slice to
hold `TierItem` and `TierPage` — shared domain entities reused by all five
tiers slices.

## User Stories

1. As a superuser, I want to create a new tier by providing a name, so that the
   tier becomes available for assignment to users.
2. As a superuser, I want the created tier returned in the response, so that I
   can confirm its id and creation timestamp without a separate fetch.
3. As an API consumer, I want to receive HTTP 409 when I attempt to create a
   tier whose name already exists, so that I get a clear and consistent error
   for duplicate names.
4. As an API consumer, I want the duplicate-name check to be race-condition-safe
   under concurrent inserts, so that two simultaneous requests do not both
   succeed silently.
5. As an API consumer (non-superuser), I want to receive HTTP 403 when I
   attempt to call this endpoint, so that tier management is protected.
6. As an unauthenticated caller, I want to receive HTTP 401 when I call this
   endpoint without a token, so that the auth boundary is enforced.
7. As a developer, I want the tier-creation logic isolated in a use-case class,
   so that it can be unit-tested without a database or HTTP stack.
8. As a developer, I want the data adapter to be injected via a port protocol,
   so that the persistence implementation can be swapped without touching the
   use-case or router.
9. As a developer, I want the slice wired into the DI container, so that
   dependency injection is consistent with all other slices.
10. As a developer, I want `TierItem` and `TierPage` defined once in
    `tiers/_shared/entities.py`, so that all five tier slices share the same
    domain vocabulary without cross-slice imports.
11. As a developer, I want the old `write_tier` handler removed after the new
    slice is live, so that there is exactly one implementation of this behaviour.

## Implementation Decisions

### Shared entities (created alongside this slice)

- **`tiers/_shared/entities.py`** — defines `TierItem(id: int, name: str,
  created_at: datetime)` and `TierPage(items: list[TierItem], total_count: int,
  page: int, items_per_page: int)`. Both are pure Pydantic models (no ORM,
  no framework imports). `TierPage` is defined here but only consumed by the
  `list_tiers` slice.

### Modules to build

- **Domain command** — `CreateTierCommand(name: str)`. Pure dataclass/Pydantic,
  no framework imports.
- **Port** — `CreateTierPort`, a `@runtime_checkable` Protocol with a single
  method: `create(command: CreateTierCommand) -> TierItem`.
- **Use case** — `CreateTierUseCase`, a class with
  `__init__(port: CreateTierPort)` and
  `async def __call__(command: CreateTierCommand) -> TierItem`. The use-case
  delegates entirely to the port; it has no conditional branches — the
  duplicate-name policy is enforced by the adapter via the database unique
  constraint.
- **Data adapter** — `CreateTierAdapter(CreateTierPort)`. Receives an
  `async_sessionmaker`. The `create` method constructs a `Tier` ORM instance,
  adds it to the session, commits, refreshes, and maps the ORM object to
  `TierItem`. It catches `sqlalchemy.exc.IntegrityError` and re-raises it as
  `DuplicateValueDomainError("Tier name already exists")`. No `SELECT EXISTS`
  before the insert.
- **Presentation schemas** — `CreateTierRequest(name: str)` and
  `CreateTierResponse` (fields mirroring `TierItem`: `id`, `name`,
  `created_at`; `model_config = ConfigDict(from_attributes=True)`).
- **Presentation router** — single `POST /tier` endpoint. Requires superuser
  auth. Builds `CreateTierCommand` from `CreateTierRequest`, calls the use-case,
  maps the returned `TierItem` to `CreateTierResponse`. Status code 201.

### Modules to modify

- **`features/tiers/router.py`** — becomes the aggregator for all five tier
  sub-routers. In this slice it includes only the `create_tier` sub-router. The
  old `write_tier` handler is deleted; the `read_tiers`, `read_tier`,
  `patch_tier`, and `erase_tier` handlers remain in place until their
  respective slices are complete.
- **`bootstrap/container.py`** — two new providers: `create_tier_adapter`
  (Factory, receives `session_factory`) and `create_tier_use_case` (Factory,
  receives `create_tier_adapter`). Wiring entry added for
  `features.tiers.create_tier.presentation.router`.

### Architectural decisions

- **No `SELECT EXISTS`**: the adapter issues only the `INSERT`. A unique-
  constraint violation on the `name` column raises `IntegrityError`, which the
  adapter catches and translates to `DuplicateValueDomainError`. This eliminates
  the TOCTOU race that exists in the current implementation.
- **Use-case is trivial**: `CreateTierUseCase.__call__` has no conditional
  logic — it just calls `self._port.create(command)` and returns the result.
  The use-case boundary exists for architectural consistency and testability,
  not for business-logic branching.
- **Endpoint URL unchanged**: the new slice preserves `POST /tier` (singular)
  to maintain backward compatibility with existing API consumers. URL
  normalisation (aligning to plural `/tiers`) is out of scope.
- **ORM model unchanged**: `adapters/db/models/tier.py` is `# STABLE` and
  is not modified. The adapter reads `Tier.id`, `Tier.name`, and
  `Tier.created_at` directly after refresh.

## Testing Decisions

Good tests verify observable behavior through the public interface, not
implementation details. They do not assert which internal methods were called
unless the call itself is the observable behavior under test.

### Use-case unit test

- Mock `CreateTierPort` with `pytest-mock`.
- Call `CreateTierUseCase` with a `CreateTierCommand(name="gold")`.
- Assert the use-case calls `port.create` with the same command.
- Assert the returned `TierItem` matches what the mock port returns.
- No error-path test needed at the use-case level — duplicate detection is
  the adapter's responsibility and is tested at the adapter level.
- Prior art: `tests/features/users/0001_create_user/` use-case unit test.

### Adapter unit test

- Use a real async session against the test Postgres database (no mocks for
  the session).
- Happy path: call `CreateTierAdapter.create()` with a unique name, assert
  the returned `TierItem` has the correct `name` and a non-null `id` and
  `created_at`.
- Duplicate path: insert a tier, then call `create()` again with the same
  name; assert `DuplicateValueDomainError` is raised.
- Assert that other `IntegrityError` variants (e.g., value too long) propagate
  **unchanged** — the adapter does not wrap `except Exception`.
- Prior art: `tests/features/users/0001_create_user/` adapter unit test.

### Endpoint integration test

- Use `httpx.AsyncClient` against the running app with test Postgres.
- Assert HTTP 201 and correct `CreateTierResponse` JSON shape on the happy
  path (authenticated superuser).
- Assert HTTP 409 when the tier name already exists.
- Assert HTTP 403 when the caller is not a superuser.
- Assert HTTP 401 for an unauthenticated request.
- Assert HTTP 422 for a missing `name` field.
- Prior art: `tests/features/users/0001_create_user/` integration test.

### Outside-in test

- Acceptance gate for the slice. Must be RED before implementation, GREEN
  after.
- Covers the full happy path: authenticate as a superuser, `POST /api/v1/tier`
  with `{"name": "gold"}`, assert HTTP 201 and that the response body contains
  `name`, `id`, and `created_at`.

## Out of Scope

- Migrating `list_tiers`, `get_tier`, `update_tier`, or `delete_tier` to the
  vertical slice pattern (separate slices 0034–0037).
- URL normalisation from `/tier` (singular) to `/tiers` (plural).
- Removing `tiers/schemas.py` or `tiers/repository.py` — these files are still
  referenced by `rate_limits/` and `users/` features and must not be touched
  until all dependent slices are migrated.
- Changes to the ORM model or Alembic migrations.
- Cache invalidation (tier creation has no associated cache).

## Further Notes

- `rate_limits/router.py` and `users/` feature files import directly from
  `tiers/repository.py` and `tiers/schemas.py`. These are pre-existing
  architectural violations. They are not introduced by this slice and must not
  be fixed here.
- The `tiers/router.py` aggregator is converted incrementally: each of the
  five slices (0033–0037) removes one handler and adds one sub-router include.
  After all five slices land, `tiers/router.py` contains only `include_router`
  calls and `tiers/schemas.py` / `tiers/repository.py` can be deleted.
- This slice establishes `tiers/_shared/entities.py`. Later slices import from
  it; they must not redefine `TierItem` locally.
