# 0025 · centralize_auth_dependencies — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `_get_user_by_credential(db, credential)` returns `None` when no row matching the credential exists in the database.
- **F2.** `_get_user_by_credential` returns a `dict` with exactly the keys `{"id", "username", "email", "is_superuser", "is_moderator", "tier_id"}` — and no others, specifically excluding `hashed_password` — when a matching non-deleted row is found.
- **F3.** `_get_user_by_credential` uses `User.email` as the lookup column when `@` is present in `credential`.
- **F4.** `_get_user_by_credential` uses `User.username` as the lookup column when `@` is absent from `credential`.
- **F5.** `_get_user_by_credential` always adds `User.is_deleted IS FALSE` to the WHERE clause; a user row with `is_deleted=True` is treated as not found and the function returns `None`.
- **F6.** `get_current_user` raises `UnauthorizedException` when `verify_token` returns `None` (invalid or expired token).
- **F7.** `get_current_user` raises `UnauthorizedException` when `_get_user_by_credential` returns `None` (no matching active user).
- **F8.** `get_current_user` returns the user dict produced by `_get_user_by_credential` on the happy path.
- **F9.** `get_optional_user` returns `None` when the `Authorization` header is absent from the request.
- **F10.** `get_optional_user` returns `None` when the `Authorization` header is present but not in `Bearer <token>` format.
- **F11.** `get_optional_user` returns `None` when `verify_token` returns `None` (expired or invalid token).
- **F12.** `get_optional_user` returns the user dict from `get_current_user` when a valid `Bearer` token is presented.
- **F13.** `get_current_superuser` raises `ForbiddenException` when `current_user["is_superuser"]` is falsy.
- **F14.** `get_current_moderator_or_superuser` raises `ForbiddenException` when both `current_user["is_moderator"]` and `current_user["is_superuser"]` are falsy.
- **F15.** All four auth functions (`get_current_user`, `get_optional_user`, `get_current_superuser`, `get_current_moderator_or_superuser`) are defined in `src/app/shared_dependencies.py` and are no longer present in `src/app/features/users/dependencies.py`.
- **F16.** `src/app/features/users/dependencies.py` is deleted; no re-export shim remains that forwards symbols to `shared_dependencies`.
- **F17.** All 10 FEATURE router files listed in plan.md § 4 update their import from `features.users.dependencies` to `shared_dependencies` using the correct relative import depth for each file's location.
- **F18.** `src/app/bootstrap/factory.py` imports `get_current_superuser` from `..shared_dependencies` instead of `..features.users.dependencies`.
- **F19.** All test files that previously imported from `app.features.users.dependencies` are updated to import from `app.shared_dependencies` using absolute imports; symbol names are unchanged.
- **F20.** `src/app/shared_dependencies.py` contains no import from `features.users` after this change.
- **F21.** The pytestarch tests `test_vsa_domains_do_not_import_each_other[posts-users]` and `test_vsa_domains_do_not_import_each_other[users-posts]` pass green.
- **F22.** The `importlinter` contract `vsa-feature-independence` passes green when executed via `lint-imports --config .importlinter` from `src/`.

## Non-functional requirements

- **N1.** `_get_user_by_credential` has no `try/except` block wrapping the SQLAlchemy query; infrastructure exceptions propagate unchanged to the global handler. Per `agent_docs/error_handling.md` § Right shape: read-only query, no catch.
- **N2.** After this change, `src/app/shared_dependencies.py` imports only from `adapters/`, `core/`, and the pre-existing `features/rate_limits` and `features/tiers` repositories (accepted pre-existing pattern); no import from `features/users` remains. Per `agent_docs/architecture.md`.
- **N3.** The new test file `tests/features/architecture/0025_centralize_auth_dependencies/test_shared_dependencies.py` starts with the `# FEATURE:` header on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N4.** All DB calls in `_get_user_by_credential` and `get_current_user` use `async def` with `await`; no synchronous database calls are introduced.
- **N5.** No backwards-compatibility re-export shim is left in the deleted `features/users/dependencies.py`. Per CLAUDE.md § Universal hard rules.
- **N6.** Feature router files use relative imports (`from ...shared_dependencies import …`); test files use absolute imports (`from app.shared_dependencies import …`). Per `agent_docs/architecture.md` § Import conventions.
- **N7.** mypy strict passes with no new errors for all modified and new files under `src/app/`.
- **N8.** Ruff format and lint pass with no new violations for all modified and new files under `src/app/`.

## Out of scope

- Removing the remaining cross-feature imports in `shared_dependencies.py` that load `features/rate_limits/repository` and `features/tiers/repository`.
- Fixing other identified architecture violations (`adapters/rate_limit` importing `features/rate_limits/schemas`; `core/security` and `core/token_blacklist_service` importing `adapters/db/token_blacklist`).
- Full type-narrowing of `get_current_user` return type from `dict[str, Any]` to a proper `CurrentUser` named domain schema.
- Migration of `features/tiers/router.py` and `features/rate_limits/router.py` to the VSA use-case pattern.

## Traceability

| Requirement | Verified by |
|---|---|
| F1, F2, F3, F4, F5 | `_get_user_by_credential` unit tests in `test_shared_dependencies.py` |
| F6, F7, F8 | `get_current_user` unit tests in `test_shared_dependencies.py` |
| F9, F10, F11, F12 | `get_optional_user` unit tests in `test_shared_dependencies.py` |
| F13 | `get_current_superuser` unit test in `test_shared_dependencies.py` |
| F14 | `get_current_moderator_or_superuser` unit test in `test_shared_dependencies.py` |
| F15, F16, F17, F18, F19, F20 | code review |
| F21 | `tests/architecture/test_architecture.py` |
| F22 | `importlinter` contract (`lint-imports --config .importlinter` from `src/`) |
| N1–N8 | code review checklist in `validation.md` |
