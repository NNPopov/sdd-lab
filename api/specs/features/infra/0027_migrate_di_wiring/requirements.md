# 0027 · migrate_di_wiring — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `bootstrap/container.py` defines `wiring_config = containers.WiringConfiguration(modules=[...])` as the first attribute of the `Container` class body, with one dotted-path string entry for each of the 17 router modules and one entry for `"app.shared_dependencies"` (18 entries total).
- **F2.** Each of the 17 `presentation/router.py` files has its `_get_<name>_use_case()` private helper function and its deferred `from ... import container  # noqa: PLC0415` local import removed entirely.
- **F3.** `shared_dependencies.py` has its `_get_token_blacklist_adapter()` helper function and its deferred `from ... import container  # noqa: PLC0415` local import removed entirely.
- **F4.** Each of the 17 `presentation/router.py` files declares `from dependency_injector.wiring import Provide, inject` and a relative import of `Container` from the bootstrap module at module level (not deferred to call time).
- **F5.** `shared_dependencies.py` declares `from dependency_injector.wiring import Provide, inject` and imports `Container` from `bootstrap.container` via a relative module-level import.
- **F6.** Every endpoint function in the 17 routers that previously used `Depends(_get_<name>_use_case)` now uses `Depends(Provide[Container.<name>_use_case])` in the corresponding `Annotated` type, per the provider name mapping in `plan.md` § 5 Step 2.
- **F7.** `delete_user/presentation/router.py`'s endpoint function carries two `Provide[...]` parameters: `Depends(Provide[Container.delete_user_use_case])` and `Depends(Provide[Container.token_blacklist_adapter])`, replacing both removed helpers.
- **F8.** `shared_dependencies.get_current_user` receives `blacklist: Annotated[TokenBlacklistPort, Depends(Provide[Container.token_blacklist_adapter])]` and is decorated with `@inject`.
- **F9.** `shared_dependencies.get_optional_user` receives `blacklist: TokenBlacklistPort = Depends(Provide[Container.token_blacklist_adapter])` (retaining the existing legacy `= Depends(...)` style for its parameters) and is decorated with `@inject`.
- **F10.** Every endpoint and dependency function that uses `Provide[...]` carries `@inject` as the **innermost** decorator — placed directly above `async def`, below `@router.*` and below `@cache` when both are present; any other ordering causes silent injection failure.
- **F11.** After the migration, `ruff check src/app` reports zero `PLC0415` (late import) suppressions in `src/app/features/` and `src/app/shared_dependencies.py`.
- **F12.** `agent_docs/entry_points/fastapi.md` documents the three mandatory bootstrap steps for a new slice — (1) add providers to `container.py`, (2) add the router to `router.py`, (3) add the router module path to `Container.wiring_config.modules` — and states that omitting step 3 causes `Provide[...]` to silently resolve to the sentinel object, producing an `AttributeError` at request time rather than at startup.
- **F13.** All existing outside-in tests in `tests/features/` remain green after the migration; observable HTTP behaviour (paths, status codes, request and response shapes) is identical before and after.
- **F14.** `tests/smoke/test_app_starts.py` passes after the migration, confirming no import-level circular imports or startup errors were introduced.

## Non-functional requirements

- **N1.** The migration modifies only `bootstrap/container.py`, `shared_dependencies.py`, the 17 `presentation/router.py` files, and `agent_docs/entry_points/fastapi.md`; no domain, port, adapter, or use-case logic is added or modified. Per `agent_docs/architecture.md`.
- **N2.** Feature router modules import `Container` using relative imports (e.g. `from .....bootstrap.container import Container`); absolute imports inside `src/app/` are forbidden. Per `agent_docs/architecture.md` § Import conventions.
- **N3.** No `HTTPException` is raised inside any use-case or adapter file. Per `CLAUDE.md` rule 1 and `agent_docs/error_handling.md`.
- **N4.** No cross-slice imports are introduced by the migration. Per `CLAUDE.md` rule 7.
- **N5.** All modified `.py` files retain their existing `# STABLE:` or `# FEATURE:` file header on line 1; no new `.py` files are created. Per `CLAUDE.md` rule 9.
- **N6.** No synchronous I/O is introduced; all endpoint and dependency functions remain `async def`. Per `CLAUDE.md` locked technology stack.
- **N7.** mypy strict passes for `src/app/` after the migration. Per `CLAUDE.md` § Verifying changes.
- **N8.** `ruff format` and `ruff check` pass for `src/app/` after the migration. Per `CLAUDE.md` § Verifying changes.

## Out of scope

- Changing any `providers.Factory` or `providers.Object` definition in `bootstrap/container.py`.
- Migrating legacy flat `features/` router functions that do not follow the VSA structure (e.g. `patch_post`, `erase_post`).
- Introducing `providers.Resource` for DB session or Redis lifecycle management.
- Adding or removing any use-case, adapter, domain, or port logic.
- Changing the `providers.Object(local_session)` pattern for the session factory.
- Upgrading `dependency_injector` or any other package version.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | code review — `container.py` class body |
| F2, F3 | code review + `ruff check` zero PLC0415 suppressions (F11) |
| F4, F5 | code review — module-level imports in each affected file |
| F6, F7 | code review — endpoint signatures match provider name mapping in plan.md |
| F8, F9 | code review — `shared_dependencies.py` function signatures |
| F10 | code review — decorator order on every `@inject`-decorated function |
| F11 | `ruff check src/app` output after migration |
| F12 | documentation review — `agent_docs/entry_points/fastapi.md` |
| F13 | full `pytest` suite — all existing outside-in tests |
| F14 | `pytest tests/smoke/test_app_starts.py` |
| N1–N8 | code review checklist in validation.md |
