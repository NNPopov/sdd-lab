# PRD — 0036: Update Tier (`PATCH /tier/{name}`)

## Problem Statement

The `PATCH /tier/{name}` endpoint is implemented as a fat FastAPI handler in
`features/tiers/router.py` that calls a FastCRUD repository directly, performs
a not-found check and an update inline, and has no use-case class, no port, no
command object, and no DI container wiring. The current implementation also has
a concurrency gap: if the `name` column uniqueness constraint is violated on
the UPDATE (because another tier already has the target name), an unhandled
`IntegrityError` propagates rather than returning a clean HTTP 409. This
violates the project's Vertical Slice + Hexagonal architecture.

## Solution

Extract the endpoint into a proper vertical slice at
`features/tiers/update_tier/`. The handler becomes a thin router that converts
the path parameter and request body into an `UpdateTierCommand` and delegates
to `UpdateTierUseCase` via a DI-managed port. The port exposes two methods:
`get` (checks existence) and `update` (performs the rename). The use case owns
the not-found check. The adapter catches `IntegrityError` on the UPDATE
statement and translates it to `DuplicateValueDomainError`, closing the
concurrency gap. The router returns a Pydantic `UpdateTierResponse` with a
confirmation message. The old `patch_tier` handler is deleted after the new
slice is in place.

## User Stories

1. As a superuser, I want to rename an existing tier by providing its current
   name and a new name, so that the tier catalogue stays accurate.
2. As a superuser, I want to receive a confirmation message when the rename
   succeeds, so that I know the operation completed without fetching the tier
   again.
3. As an API consumer, I want to receive HTTP 404 when I attempt to rename a
   tier that does not exist, so that I get a clear error for invalid requests.
4. As an API consumer, I want to receive HTTP 409 when the new name is already
   taken by another tier, so that I can choose a different name.
5. As an API consumer (non-superuser), I want to receive HTTP 403 when I
   attempt to call this endpoint, so that tier management is protected.
6. As an unauthenticated caller, I want to receive HTTP 401 when I call this
   endpoint without a token, so that the auth boundary is enforced.
7. As a developer, I want the not-found check isolated in the use-case, so
   that it can be unit-tested with a mocked port without a database or HTTP
   stack.
8. As a developer, I want the duplicate-name error translated at the adapter
   boundary rather than propagating as an unhandled `IntegrityError`, so that
   the HTTP layer always receives a typed domain error.
9. As a developer, I want the port to separate the read (`get`) and write
   (`update`) operations so that each can be tested independently.
10. As a developer, I want the data adapter injected via a port protocol, so
    that the persistence implementation can be swapped without touching the
    use-case or router.
11. As a developer, I want the slice wired into the DI container, so that
    dependency injection is consistent with all other slices in the project.
12. As a developer, I want the old `patch_tier` handler removed after the new
    slice is live, so that there is exactly one implementation of this
    behaviour.

## Implementation Decisions

### Modules to build

- **Domain command** — `UpdateTierCommand(name: str, new_name: str)`. `name`
  is the current tier name (from the path); `new_name` is the desired rename
  (from the request body). Pure Pydantic model, no framework imports.
- **Port** — `UpdateTierPort`, a `@runtime_checkable` Protocol with two
  methods:
  - `get(name: str) -> TierItem | None` — reads the tier by current name.
    Returns `None` if no tier with that name exists.
  - `update(name: str, new_name: str) -> None` — renames the tier. Raises
    `DuplicateValueDomainError` if the name is already taken.
- **Use case** — `UpdateTierUseCase`, a class with
  `__init__(port: UpdateTierPort)` and
  `async def __call__(command: UpdateTierCommand) -> None`. Steps: (1) call
  `self._port.get(command.name)`; raise `NotFoundDomainError("Tier not
  found")` if the result is `None`. (2) call
  `self._port.update(command.name, command.new_name)`. The use case does not
  catch `DuplicateValueDomainError` — it propagates to the HTTP exception
  handler.
- **Data adapter** — `UpdateTierAdapter(UpdateTierPort)`. Receives an
  `async_sessionmaker`. `get` executes
  `SELECT id, name, created_at FROM tier WHERE name = :name` and returns a
  `TierItem` or `None`. `update` executes
  `UPDATE tier SET name = :new_name, updated_at = now() WHERE name = :name`
  and commits; it catches `sqlalchemy.exc.IntegrityError` and re-raises it as
  `DuplicateValueDomainError("Tier name already exists")`. Other exceptions
  propagate unchanged. No FastCRUD usage.
- **Presentation schemas** — `UpdateTierRequest(new_name: str)` and
  `UpdateTierResponse(message: str = "Tier updated")`. Both with
  `model_config = ConfigDict(from_attributes=True)`. Slice-local; do not
  reuse `tiers/schemas.py`.
- **Presentation router** — single `PATCH /tier/{name}` endpoint. Requires
  superuser auth via `get_current_superuser`. Builds
  `UpdateTierCommand(name=name, new_name=body.new_name)`, calls the use-case,
  returns `UpdateTierResponse()`. Status code 200.

### Modules to modify

- **`features/tiers/router.py`** — the `patch_tier` handler is removed and
  the `update_tier` sub-router is included. The remaining handlers
  (`write_tier`, `read_tiers`, `read_tier`, `erase_tier`) stay in place until
  their respective slices (0033–0035, 0037) are complete.
- **`bootstrap/container.py`** — two new providers: `update_tier_adapter`
  (Factory, receives `session_factory`) and `update_tier_use_case` (Factory,
  receives `update_tier_adapter`). Wiring entry added for
  `features.tiers.update_tier.presentation.router`.

### Architectural decisions

- **Two-method port**: the port exposes `get` and `update` separately. This
  keeps each method narrow and independently testable, and makes the
  check-then-act sequence explicit in the use-case body rather than hidden
  inside the adapter.
- **Use case owns not-found, adapter owns duplicate**: the not-found check
  (`get` returns `None` → raise `NotFoundDomainError`) belongs to the
  use-case because it is a domain invariant — a tier that doesn't exist cannot
  be renamed. The duplicate-name translation (`IntegrityError` →
  `DuplicateValueDomainError`) belongs to the adapter because it is an
  infrastructure concern — the database is the authority on uniqueness under
  concurrency.
- **No SELECT EXISTS before UPDATE**: the adapter issues the UPDATE directly
  and catches `IntegrityError`, consistent with the create-tier adapter
  pattern (slice 0033). This closes the race condition that exists in the
  current `get`-then-`update` FastCRUD approach.
- **`updated_at` set on rename**: the adapter sets `updated_at = now()` on
  the UPDATE statement. This matches the `updated_at` column on the ORM model
  and is the adapter's responsibility — the use case is unaware of it.
- **Use case returns `None`**: the use-case contract is `-> None`. The router
  constructs and returns `UpdateTierResponse(message="Tier updated")` from the
  presentation layer — the message is a transport concern, not a domain one.
- **Endpoint URL unchanged**: the new slice preserves `PATCH /tier/{name}`
  (singular) to maintain backward compatibility with existing API consumers.

## Testing Decisions

Good tests verify observable behavior through the public interface, not
implementation details. They do not assert which internal methods were called
unless the call itself is the observable behavior under test.

### Use-case unit test

- Mock `UpdateTierPort` with `pytest-mock`.
- Not-found path: mock `port.get` to return `None`; call
  `UpdateTierUseCase` with a valid command; assert `NotFoundDomainError` is
  raised and `port.update` is never called.
- Happy path: mock `port.get` to return a `TierItem`; mock `port.update` to
  return `None`; assert the use-case returns `None` without raising.
- Duplicate path: mock `port.get` to return a `TierItem`; mock `port.update`
  to raise `DuplicateValueDomainError`; assert it propagates from the
  use-case unchanged.
- Prior art: `tests/features/users/0006_update_user/` use-case unit test.

### Adapter unit test

- Use a real async session against the test Postgres database (no mocks for
  the session).
- `get` — happy path: seed a tier, call `get(name)`; assert a `TierItem` is
  returned with the correct fields.
- `get` — not-found: call `get` with a name not in the table; assert `None`
  is returned.
- `update` — happy path: seed a tier named "silver", call
  `update("silver", "gold")`; assert the row in the database now has
  `name="gold"` and a non-null `updated_at`.
- `update` — duplicate: seed tiers named "silver" and "gold", call
  `update("silver", "gold")`; assert `DuplicateValueDomainError` is raised.
- `update` — assert that unknown `IntegrityError` variants (not a name
  uniqueness violation) propagate unchanged — the adapter does not swallow
  arbitrary exceptions.
- Prior art: `tests/features/users/0006_update_user/` adapter unit test.

### Endpoint integration test

- Use `httpx.AsyncClient` against the running app with test Postgres.
- Assert HTTP 200 and `{"message": "Tier updated"}` for a valid rename by a
  superuser.
- Assert HTTP 404 when the path name does not match any tier.
- Assert HTTP 409 when the new name is already taken.
- Assert HTTP 403 when the caller is not a superuser.
- Assert HTTP 401 for an unauthenticated request.
- Assert HTTP 422 for a missing `new_name` field in the request body.
- Prior art: `tests/features/users/0006_update_user/` integration test.

### Outside-in test

- Acceptance gate for the slice. Must be RED before implementation, GREEN
  after.
- Covers the full happy path: seed a tier named "silver", authenticate as a
  superuser, call `PATCH /api/v1/tier/silver` with `{"new_name": "gold"}`,
  assert HTTP 200 and `{"message": "Tier updated"}`.

## Out of Scope

- Migrating `create_tier`, `list_tiers`, `get_tier`, or `delete_tier`
  (separate slices 0033–0035, 0037).
- Partial updates beyond renaming — the only mutable field is `name`.
- Returning the updated `TierItem` in the response body — the current API
  contract returns only a confirmation message, which is preserved.
- URL normalisation from `/tier/{name}` (singular) to `/tiers/{name}`.
- Removing `tiers/schemas.py` or `tiers/repository.py` — still referenced by
  `rate_limits/` and `users/` features.

## Further Notes

- The `TierUpdate` schema in `tiers/schemas.py` declares `name: str | None`.
  The new slice's `UpdateTierRequest` makes `new_name: str` required (non-
  optional), which is a stricter and clearer contract. The old schema is not
  removed yet — it is still used by `tiers/repository.py`.
- The adapter's `update` method sets `updated_at` at the SQL level. The ORM
  model exposes this column but `TierItem` (the shared entity) does not
  include `updated_at`, keeping the read surface minimal.
- This slice and `delete_tier` (0037) share the same two-method port pattern
  (`get` + mutation). They are separate slices because their mutation methods
  and error surfaces differ.
