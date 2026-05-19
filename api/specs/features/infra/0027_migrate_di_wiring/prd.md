# PRD — Slice 0027: migrate_di_wiring

## Problem Statement

Seventeen slice routers and one shared dependency module currently contain private
helper functions whose sole purpose is to pull an instance from the DI container:

```python
def _get_create_user_use_case() -> CreateUserUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.create_user_use_case()
```

This pattern exists because `dependency-injector`'s wiring mechanism is not
enabled. Without wiring, a module-level import of `container` inside
`features/` would cause a circular import at startup (features import bootstrap,
bootstrap imports features), so each file defers the import to call time and
suppresses the linter with `# noqa: PLC0415`.

The boilerplate has three concrete costs:

1. Every new slice must reproduce the helper manually — it is copy-paste, not
   derived from the architecture.
2. The `# noqa: PLC0415` suppressions accumulate, masking the linter's ability to
   catch legitimate late imports elsewhere.
3. The container's own wiring API (`Provide[Container.x]` inside `Depends`) — the
   idiomatic pattern documented in `agent_docs/entry_points/fastapi.md` and
   `agent_docs/architecture.md` — is completely unused. The project's own
   documentation already describes the target state; the codebase has not caught
   up to it.

## Solution

Enable `dependency-injector`'s wiring mechanism so that slice routers and shared
dependency functions declare their injected objects directly in FastAPI `Depends`,
matching the pattern already documented in `agent_docs/entry_points/fastapi.md`:

```python
@router.post("/user", response_model=CreateUserResponse, status_code=201)
async def create_user(
    request: CreateUserRequest,
    use_case: Annotated[CreateUserUseCase, Depends(Provide[Container.create_user_use_case])],
) -> CreateUserResponse:
```

This removes all 18 helper functions, eliminates all `# noqa: PLC0415`
suppressions, and aligns the codebase with the project's own documented
conventions.

## User Stories

1. As a developer adding a new slice, I want to declare the use-case dependency
   directly in the endpoint signature using `Depends(Provide[Container.x])`, so
   that I do not have to write a helper function or a suppressed local import.
2. As a developer adding a new slice, I want to know that the only two wiring
   steps are adding the router to `bootstrap/router.py` and adding the module
   path to `Container.wiring_config`, so that the process is consistent and
   documented.
3. As a developer reading a slice router, I want to see the use-case dependency
   inline in the function signature, so that the full dependency graph is visible
   at a glance without scrolling to a separate helper function.
4. As a developer running the linter, I want no `# noqa: PLC0415` suppressions
   in the feature codebase, so that the linter's late-import rule is enforced
   without exceptions.
5. As a developer writing tests, I want the `container.<provider>.override(mock)`
   API to continue working without changes, so that existing test overrides are
   unaffected by the wiring migration.
6. As a developer extending the container with a new provider, I want it to be
   accessible via `Provide[Container.x]` in any wired module after adding the
   module to `wiring_config`, without any additional plumbing.
7. As a developer, I want the DI wiring to be complete before the first request
   is handled, so that there is no race condition between wiring and request
   dispatch.
8. As a developer, I want the smoke test (`test_app_starts.py`) to continue
   passing after the migration, so that import-level errors are caught immediately.
9. As a developer, I want all existing outside-in tests to remain green after the
   migration, so that the migration is confirmed to be behaviour-preserving.

## Implementation Decisions

### Wiring configuration

`WiringConfiguration` is added to the `Container` class body using an explicit
`modules` list — one dotted-path string per router module and per shared
dependency module that uses `Provide`:

```python
wiring_config = containers.WiringConfiguration(
    modules=[
        "app.features.users.create_user.presentation.router",
        "app.features.users.list_users.presentation.router",
        # ... one entry per module
        "app.shared_dependencies",
    ]
)
```

This is the approach documented in `agent_docs/entry_points/fastapi.md` and
`agent_docs/architecture.md`. It is explicit by design: a module not listed here
will not have `Provide` resolved, which is a visible and auditable boundary.

The `packages=` alternative (auto-scan) was not chosen because it would silently
wire modules that should not be wired, and because the project's documented
convention uses explicit `modules=`.

### Scope of affected modules

Two categories of files use the lazy import pattern:

**17 slice routers** (all `presentation/router.py` files under `features/`):
users — `create_user`, `list_users`, `get_user_by_username`, `get_user_tier`,
`update_user`, `delete_user`, `delete_db_user`, `assign_moderator`,
`revoke_moderator`; posts — `create_post`, `list_posts`, `list_all_posts`,
`list_pending_posts`, `get_post`, `moderate_post`, `revise_post`,
`get_moderation_log`.

**1 shared dependency module**: `shared_dependencies.py` — contains
`_get_token_blacklist_adapter()`, which follows the same lazy import pattern and
injects `token_blacklist_adapter` from the container.

All 18 modules must be listed in `wiring_config.modules` and have their helper
function removed.

### Removal of helper functions

Each of the 18 affected files has its `_get_<name>()` helper function removed
entirely. The suppressed local import (`from ... import container  # noqa: PLC0415`)
disappears with it.

### Updated endpoint and dependency signatures

Each endpoint or dependency function:

- Receives `Depends(Provide[Container.<provider>])` directly in its `Annotated`
  type for the injected parameter.
- Imports `Provide` and `inject` from `dependency_injector.wiring`.
- Imports `Container` from the bootstrap module — this becomes a standard
  module-level import, not a suppressed local import.
- Has `@inject` as the **innermost decorator** — directly above `async def`,
  below `@router.*` and `@cache` (when present). This ordering is required by
  the library; placing `@inject` above `@cache` or `@router.*` causes silent
  injection failure.

### No changes to provider definitions

All existing `providers.Factory` and `providers.Object` entries in
`bootstrap/container.py` are unchanged. Wiring affects only how providers are
resolved at the endpoint boundary, not how they are defined.

### No changes to adapter, use-case, domain, port, or factory files

The migration touches `bootstrap/container.py` (wiring config + import
changes) and the 18 presentation/dependency modules (signature update). No
other layers are modified.

### Workflow change for new slices

After this migration, adding a new slice requires three bootstrap-level steps
instead of two:

1. Add the use-case and adapter providers to `bootstrap/container.py` — unchanged.
2. Add the new router to `bootstrap/router.py` — unchanged.
3. **Add the new router's module path to `Container.wiring_config.modules`** — new
   step. Without it, `Provide[...]` in the new router silently returns the
   provider sentinel object instead of the resolved instance. This anti-pattern
   is documented in `agent_docs/entry_points/fastapi.md`.

`agent_docs/entry_points/fastapi.md` must be updated to make step 3 explicit in
its "Adding a slice" description.

## Testing Decisions

Good tests verify observable behaviour through the public interface — HTTP status
codes, response bodies, and database state — not internal wiring mechanics.

### What the migration does not need new tests for

The migration is a pure structural refactor: observable HTTP behaviour is
identical before and after. No new test cases are required.

### Regression gate

All existing outside-in tests must remain green. The smoke test
(`tests/smoke/test_app_starts.py`) must pass — it catches import-level wiring
errors that unit and integration tests miss because they run under a different
import context than uvicorn. Running the full `pytest` suite is the acceptance
criterion.

### Override compatibility

Existing tests that call `container.<provider>.override(mock)` are the implicit
regression test for override compatibility. Wiring does not change the override
API; if any test that previously passed breaks after the migration, the migration
contains a bug.

Prior art for override usage: any test under `tests/features/` that calls
`container.*.override`.

## Out of Scope

- Changing any `providers.Factory` or `providers.Object` definition in the
  container — provider definitions are not the subject of this slice.
- Migrating legacy flat `features/` router functions that do not follow the VSA
  structure (e.g. `patch_post`, `erase_post` in `posts/router.py`) — those are
  separate slices.
- Introducing `providers.Resource` for the DB session or Redis lifecycle — that
  is a separate concern; the session factory pattern is not changed here.
- Adding or removing any use-case, adapter, or domain logic.
- Changing the `providers.Object(local_session)` pattern for the session factory.

## Further Notes

- `@inject` is required on every endpoint or dependency function that uses
  `Provide[...]`. It must be the innermost decorator — directly above `async def`.
  Without it, `Provide[...]` is not resolved even in a wired module. The order
  `@router.*` → `@cache` → `@inject` → `async def` is mandatory; any other
  ordering causes silent injection failure.
- The circular-import concern that motivated the original lazy-import workaround
  is resolved by wiring. `dependency-injector` patches the listed modules at
  container instantiation time, deferring resolution internally. A module-level
  `from app.bootstrap.container import Container` in a feature router is safe
  after wiring is configured; the library handles the deferred binding.
- The silent-failure mode for a missing wiring entry is the primary risk during
  implementation: if a module is not in the `modules` list, `Provide[...]`
  resolves to the sentinel object, not the use-case instance. The endpoint will
  call the object like a use-case and raise an `AttributeError` at request time,
  not at startup. The smoke test will not catch this; only an integration test
  that exercises the endpoint will. Ensure every affected module is listed in
  `wiring_config.modules` and verify with `pytest` before considering the slice
  done.
- `agent_docs/entry_points/fastapi.md` documents the wiring config and the
  `Depends(Provide[...])` endpoint pattern. That document is authoritative; this
  PRD aligns the codebase with it. After the migration, the "Adding a slice"
  section of that document should be updated to make the `wiring_config.modules`
  step explicit and prominent.
