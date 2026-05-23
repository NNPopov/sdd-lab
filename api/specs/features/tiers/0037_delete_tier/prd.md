# PRD — 0037: Delete Tier (`DELETE /tier/{name}`)

## Problem Statement

The `DELETE /tier/{name}` endpoint is implemented as a fat FastAPI handler in
`features/tiers/router.py` that calls a FastCRUD repository directly, performs
a not-found check inline, and has no use-case class, no port, no command
object, and no DI container wiring. This violates the project's Vertical Slice
+ Hexagonal architecture and makes the endpoint untestable in isolation.

This is the fifth and final handler in `tiers/router.py`. After this slice
lands, the flat router file becomes a pure aggregator of five sub-routers, and
`tiers/schemas.py` and `tiers/repository.py` become candidates for removal.

## Solution

Extract the endpoint into a proper vertical slice at
`features/tiers/delete_tier/`. The handler becomes a thin router that converts
the path parameter into a `DeleteTierCommand` and delegates to
`DeleteTierUseCase` via a DI-managed port. The port exposes two methods: `get`
(checks existence) and `delete` (performs the hard delete). The use case owns
the not-found check. The adapter issues a plain `DELETE` statement — no soft
delete, no `IntegrityError` handling. The router returns a Pydantic
`DeleteTierResponse` with a confirmation message. The old `erase_tier` handler
is deleted, completing the tiers migration.

## User Stories

1. As a superuser, I want to permanently delete a tier by name, so that
   obsolete tiers are removed from the catalogue.
2. As a superuser, I want to receive a confirmation message when the deletion
   succeeds, so that I know the operation completed without fetching the tier
   again.
3. As an API consumer, I want to receive HTTP 404 when I attempt to delete a
   tier that does not exist, so that I get a clear error for invalid requests.
4. As an API consumer (non-superuser), I want to receive HTTP 403 when I
   attempt to call this endpoint, so that tier management is protected.
5. As an unauthenticated caller, I want to receive HTTP 401 when I call this
   endpoint without a token, so that the auth boundary is enforced.
6. As a developer, I want the not-found check isolated in the use-case, so
   that it can be unit-tested with a mocked port without a database or HTTP
   stack.
7. As a developer, I want the data adapter injected via a port protocol, so
   that the persistence implementation can be swapped without touching the
   use-case or router.
8. As a developer, I want the adapter to use raw SQLAlchemy rather than
   FastCRUD, so that the query is explicit and the result is fully controlled.
9. As a developer, I want the slice wired into the DI container, so that
   dependency injection is consistent with all other slices in the project.
10. As a developer, I want the old `erase_tier` handler removed after the new
    slice is live, so that there is exactly one implementation of this
    behaviour.
11. As a developer, I want `tiers/router.py` to become a pure aggregator after
    this slice lands, so that the tiers feature fully conforms to the VSA +
    Hexagonal architecture.
12. As a developer, I want `TierItem` imported from the shared tier entities
    module for the port's `get` method, so that the domain vocabulary is
    consistent across all tier slices.

## Implementation Decisions

### Modules to build

- **Domain command** — `DeleteTierCommand(name: str)`. Pure Pydantic model, no
  framework imports.
- **Port** — `DeleteTierPort`, a `@runtime_checkable` Protocol with two
  methods:
  - `get(name: str) -> TierItem | None` — reads the tier by name. Returns
    `None` if no tier with that name exists.
  - `delete(name: str) -> None` — permanently removes the tier row.
- **Use case** — `DeleteTierUseCase`, a class with
  `__init__(port: DeleteTierPort)` and
  `async def __call__(command: DeleteTierCommand) -> None`. Steps: (1) call
  `self._port.get(command.name)`; raise `NotFoundDomainError("Tier not
  found")` if the result is `None`. (2) call `self._port.delete(command.name)`.
  The use case has no other conditional logic.
- **Data adapter** — `DeleteTierAdapter(DeleteTierPort)`. Receives an
  `async_sessionmaker`. `get` executes
  `SELECT id, name, created_at FROM tier WHERE name = :name` and returns a
  `TierItem` or `None`. `delete` executes
  `DELETE FROM tier WHERE name = :name` and commits. No FastCRUD usage. No
  `IntegrityError` handling — a DELETE statement does not violate unique
  constraints. Other infrastructure exceptions propagate unchanged to the
  global handler.
- **Presentation schemas** — `DeleteTierResponse(message: str = "Tier
  deleted")` with `model_config = ConfigDict(from_attributes=True)`. No
  request body schema is needed (the tier name comes from the path parameter).
  Slice-local; does not reuse `tiers/schemas.py`.
- **Presentation router** — single `DELETE /tier/{name}` endpoint. Requires
  superuser auth via `get_current_superuser`. Builds
  `DeleteTierCommand(name=name)`, calls the use-case, returns
  `DeleteTierResponse()`. Status code 200.

### Modules to modify

- **`features/tiers/router.py`** — the `erase_tier` handler is removed and
  the `delete_tier` sub-router is included. This is the last of the five
  handlers to migrate; after this change the file contains only five
  `include_router` calls and any now-unused imports are removed. The
  `crud_tiers`, `TierCreate`, `TierCreateInternal`, `TierRead`, `TierUpdate`,
  `compute_offset`, `paginated_response`, and `PaginatedListResponse` imports
  are deleted along with the last handler.
- **`bootstrap/container.py`** — two new providers: `delete_tier_adapter`
  (Factory, receives `session_factory`) and `delete_tier_use_case` (Factory,
  receives `delete_tier_adapter`). Wiring entry added for
  `features.tiers.delete_tier.presentation.router`.

### Architectural decisions

- **Two-method port**: the port exposes `get` and `delete` separately,
  mirroring the `update_tier` port pattern. This keeps each method narrow and
  independently testable, and makes the check-then-act sequence explicit in
  the use-case body.
- **Use case owns not-found**: the not-found check (`get` returns `None` →
  raise `NotFoundDomainError`) belongs to the use-case because it is a domain
  invariant — a tier that doesn't exist cannot be deleted. The adapter returns
  `None` neutrally; it does not raise.
- **Hard delete**: the adapter issues a plain `DELETE FROM tier WHERE
  name = :name`. The `Tier` ORM model has no `is_deleted` field; soft delete
  is not applicable here.
- **No `IntegrityError` handling**: deleting a row cannot violate a unique
  constraint. The adapter wraps no exceptions. If referential-integrity
  violations were possible (e.g., a foreign key from another table pointing to
  `tier`), that would be a separate architectural concern — no such constraint
  exists in the current schema.
- **Use case returns `None`**: the router constructs and returns
  `DeleteTierResponse(message="Tier deleted")` from the presentation layer —
  the message is a transport concern, not a domain one.
- **Endpoint URL unchanged**: the new slice preserves `DELETE /tier/{name}`
  (singular) to maintain backward compatibility with existing API consumers.
- **`tiers/router.py` becomes a pure aggregator**: after this slice, the file
  has no inline handlers. All FastCRUD and session imports are removed from it.

### Post-migration cleanup (out of scope for this slice)

After all five tiers slices (0033–0037) land:
- `tiers/schemas.py` and `tiers/repository.py` remain because `rate_limits/`
  and `users/` features import from them. Removing those files requires
  migrating those cross-slice imports, which is a separate task.

## Testing Decisions

Good tests verify observable behavior through the public interface, not
implementation details. They do not assert which internal methods were called
unless the call itself is the observable behavior under test.

### Use-case unit test

- Mock `DeleteTierPort` with `pytest-mock`.
- Not-found path: mock `port.get` to return `None`; call
  `DeleteTierUseCase` with a `DeleteTierCommand(name="gold")`; assert
  `NotFoundDomainError` is raised and `port.delete` is never called.
- Happy path: mock `port.get` to return a `TierItem`; mock `port.delete` to
  return `None`; call the use-case; assert it returns `None` without raising.
- Prior art: `tests/features/users/0007_delete_user/` use-case unit test.

### Adapter unit test

- Use a real async session against the test Postgres database (no mocks for
  the session).
- `get` — happy path: seed a tier, call `get(name)`; assert a `TierItem` is
  returned with the correct fields.
- `get` — not-found: call `get` with a name not in the table; assert `None`
  is returned.
- `delete` — happy path: seed a tier, call `delete(name)`; assert the row no
  longer exists in the database.
- `delete` — assert that calling `delete` with a name that does not exist
  completes without error (the DELETE WHERE matches zero rows; this is not an
  error at the SQL level — the use-case prevents reaching the adapter in the
  not-found case anyway).
- Prior art: `tests/features/users/0007_delete_user/` adapter unit test.

### Endpoint integration test

- Use `httpx.AsyncClient` against the running app with test Postgres.
- Assert HTTP 200 and `{"message": "Tier deleted"}` for a valid delete by a
  superuser.
- Assert HTTP 404 when the path name does not match any tier.
- Assert HTTP 403 when the caller is not a superuser.
- Assert HTTP 401 for an unauthenticated request.
- Prior art: `tests/features/users/0007_delete_user/` integration test.

### Outside-in test

- Acceptance gate for the slice. Must be RED before implementation, GREEN
  after.
- Covers the full happy path: seed a tier named "silver", authenticate as a
  superuser, call `DELETE /api/v1/tier/silver`, assert HTTP 200 and
  `{"message": "Tier deleted"}`, and verify the row is gone from the database.

## Out of Scope

- Migrating `create_tier`, `list_tiers`, `get_tier`, or `update_tier`
  (separate slices 0033–0036).
- Soft delete — the `Tier` ORM model has no deleted flag and the decision is
  hard delete.
- Cascade deletion of users assigned to the deleted tier — no such constraint
  exists in the current schema; users have a `tier_id` FK but it is not
  enforced as a hard constraint that would block deletion.
- Removing `tiers/schemas.py` or `tiers/repository.py` — still referenced by
  `rate_limits/` and `users/` features; cleanup is a separate task.
- URL normalisation from `/tier/{name}` (singular) to `/tiers/{name}`.

## Further Notes

- This is the fifth and final slice of the tiers migration. Once implemented
  and green, `tiers/router.py` will be a pure five-line aggregator. The
  FastCRUD dependency is completely removed from the tiers feature.
- The `delete_tier` and `update_tier` (0036) slices share the same two-method
  port pattern (`get` + mutation). The `get` implementations in both adapters
  are structurally identical — a SELECT WHERE name. They are kept separate
  because sharing an adapter would couple two unrelated use cases and violate
  the one-use-case-per-slice rule.
- After this slice, the remaining architectural violation in the tiers area is
  the cross-feature import of `tiers/repository.py` and `tiers/schemas.py`
  by `rate_limits/` and `users/`. That cleanup is tracked separately and is
  unrelated to this migration.
