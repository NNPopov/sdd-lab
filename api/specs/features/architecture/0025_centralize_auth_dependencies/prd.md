# PRD 0025 — Centralize Auth Dependencies

**Resource:** architecture  
**Slice:** centralize_auth_dependencies  
**Status:** Planned  

---

## Problem Statement

The FastAPI project enforces a Vertical Slice Architecture (VSA) + Hexagonal layering
where each feature domain (`users`, `posts`, etc.) must be independent. Auth dependency
functions (`get_current_user`, `get_optional_user`, `get_current_superuser`,
`get_current_moderator_or_superuser`) were defined in `features/users/dependencies.py`.

Every other feature that required authentication — posts (7 routers), tiers, rate_limits,
and the application bootstrap — imported directly from the `users` domain, creating
hard cross-domain couplings:

- `features/posts/*/router.py → features/users/dependencies.py`
- `features/tiers/router.py → features/users/dependencies.py`
- `features/rate_limits/router.py → features/users/dependencies.py`
- `bootstrap/factory.py → features/users/dependencies.py`

This violates the VSA independence rule (users ↔ posts must not import each other) and
breaks architecture tests. It also couples auth logic to the users FastCRUD repository,
creating an indirect dependency on `fastcrud` in a cross-cutting concern.

## Solution

Move all auth FastAPI dependency functions to `app/shared_dependencies.py`, the file
explicitly designated in the project layout as *"STABLE — cross-feature dependencies"*.
Replace the internal `crud_users.get()` calls (FastCRUD) with direct SQLAlchemy 2.0
async queries against the `User` ORM model, so `shared_dependencies.py` depends only
on STABLE infrastructure layers (`adapters/`, `core/`) and not on any feature.

Delete `features/users/dependencies.py` after confirming all callers have been updated.

Update all 11 feature files and all tests that imported from `users/dependencies` to
import from `shared_dependencies` instead. Feature files use relative imports
(`from ...shared_dependencies import ...`); tests use absolute imports
(`from app.shared_dependencies import ...`).

## User Stories

1. As a backend developer, I want auth dependency functions to live in a single,
   designated location, so that I know exactly where to find and change authentication
   logic without hunting across feature directories.

2. As a backend developer, I want `features/posts/` routers to have no imports from
   `features/users/`, so that the two VSA domains remain independently deployable and
   testable without coupling.

3. As a backend developer, I want `features/tiers/` and `features/rate_limits/` routers
   to not import from `features/users/`, so that those feature slices can be understood,
   tested, and refactored without knowledge of the users domain.

4. As a backend developer, I want the `bootstrap/factory.py` STABLE file to not import
   from feature-level auth logic, so that the composition root depends only on stable
   infrastructure and not on an individual feature's internals.

5. As a backend developer, I want `shared_dependencies.py` to use direct SQLAlchemy
   queries for user lookups, so that the cross-cutting auth layer has no dependency on
   FastCRUD and remains decoupled from any CRUD abstraction.

6. As a backend developer, I want `get_current_user` to return a plain `dict[str, Any]`
   built from ORM column values, so that the return type contract is unchanged and no
   callers require modification.

7. As a backend developer, I want `get_optional_user` to continue returning `None` when
   no valid token is present, so that public endpoints that allow unauthenticated access
   continue to work correctly.

8. As a backend developer, I want `get_current_superuser` and
   `get_current_moderator_or_superuser` to remain FastAPI `Depends`-composable, so that
   role-guarded endpoints require no router changes beyond the import path.

9. As a backend developer, I want all test files that previously imported from
   `features/users/dependencies` to be updated to import from `app.shared_dependencies`
   directly, and `features/users/dependencies.py` to be deleted, so that no
   backwards-compatibility re-export shim is left in the codebase.

10. As a backend developer, I want the architecture test suite to pass after this change,
    so that the VSA independence contract (users ↔ posts) is formally verified green.

11. As a backend developer, I want lint-imports contracts in `.importlinter` to pass
    after this change, so that the CI arch gate confirms no cross-layer violations.

12. As a security engineer, I want user lookup during token validation to filter by
    `is_deleted = False`, so that soft-deleted users cannot authenticate with a previously
    valid token.

13. As a security engineer, I want user lookup to support both username and email as
    credential identifiers (distinguished by the presence of `@`), so that the auth
    behaviour is identical to what it replaced.

## Implementation Decisions

### Modules modified

- **`app/shared_dependencies.py`** (STABLE): Extended with four auth dependency
  functions and one private `_get_user_by_credential` helper. The rate-limiter
  dependency already in this file remains unchanged. The import of `get_optional_user`
  from `features.users.dependencies` is removed; the function is now defined locally.

- **`app/features/users/dependencies.py`** (FEATURE): Deleted after all callers are
  updated. No re-export shim is left.

- **`app/features/posts/*/presentation/router.py`** (FEATURE, 7 files): Import updated
  from `features.users.dependencies` → `shared_dependencies`.

- **`app/features/posts/router.py`** (FEATURE): Same import update.

- **`app/features/tiers/router.py`** (FEATURE): Same import update.

- **`app/features/rate_limits/router.py`** (FEATURE): Same import update.

- **`app/bootstrap/factory.py`** (STABLE): Import updated from
  `features.users.dependencies` → `shared_dependencies`.

### SQLAlchemy user lookup

`_get_user_by_credential(db, credential)` executes a `SELECT` on the `User` ORM model
with a single `WHERE` clause (`email` or `username` depending on whether `@` is in the
credential, plus `is_deleted IS FALSE`). Returns a plain `dict` containing only the
fields required at the auth boundary (e.g. `id`, `username`, `email`, `is_superuser`,
`is_active`, `tier_id`). Sensitive columns such as `hashed_password` are explicitly
excluded from the returned dict to respect the bounded-context principle
(architecture.md § Bounded contexts). The full `CurrentUser` type projection is a
separate future refactor; for this slice a hand-curated key allowlist is sufficient.

`get_current_user` receives the database session via `Depends(async_get_db)` — a
FastAPI-native dependency, not routed through the `dependency_injector` container.
This is intentional: auth gate functions are FastAPI dependencies, not use-cases, so
container wiring does not apply to them. `async_get_db` must be imported from
`adapters/db/session` (STABLE layer).

### Layer purity of `shared_dependencies.py`

After this change, `shared_dependencies.py` imports from:
- `adapters/db/models/user` — ORM model (STABLE adapter layer)
- `adapters/db/session` — async session factory (STABLE adapter layer)
- `adapters/rate_limit/redis_rate_limiter` — rate limiter (STABLE adapter layer)
- `core/config`, `core/logger`, `core/security` — STABLE core layer
- `features/rate_limits/repository`, `features/tiers/repository` — still imports two
  feature repositories (pre-existing pattern for the rate-limiter logic; not changed
  by this slice)

The `features/users` import is fully removed from `shared_dependencies.py`.

### No interface changes

All four auth functions retain identical signatures and return types. No endpoint
code, use-case code, or test assertion changes are required.

## Testing Decisions

### What makes a good test here

Tests should verify observable behavior (does `get_current_user` return the right dict
for a given token?) not implementation details (does it use SQLAlchemy or FastCRUD
internally?).

### Modules to test

- **`_get_user_by_credential`**: Unit test with a mocked `AsyncSession`. Verify:
  - Returns `None` when no row matches.
  - Returns a dict with only the allowlisted auth-boundary keys when a row matches.
  - Routes by `@` correctly (email vs username branch).
  - Filters `is_deleted = True` rows out.

- **`get_current_user`**: Unit test with mocked `verify_token` and mocked
  `_get_user_by_credential`. Verify: raises `UnauthorizedException` when token is
  invalid; raises `UnauthorizedException` when user not found; returns user dict on
  success.

- **`get_optional_user`**: Unit test. Verify: returns `None` for missing header, bad
  bearer format, expired token; returns user dict for valid token.

- **Architecture test** (`tests/architecture/test_architecture.py`): The existing
  pytestarch VSA independence check (`users ↔ posts`) must pass green.

### Prior art

See `tests/features/users/` for examples of use-case unit tests with mocked async
sessions and `tests/architecture/test_architecture.py` for the independence contract
tests.

## Out of Scope

- Removing the remaining cross-feature imports in `shared_dependencies.py` that
  load `features/rate_limits` and `features/tiers` repositories. That is a separate
  architectural concern.
- Fixing other identified architecture violations (`adapters/rate_limit` importing
  `features/rate_limits/schemas`; `core/security` and `core/token_blacklist_service`
  importing `adapters/db/token_blacklist`).
- Full type-narrowing of `get_current_user` return from `dict[str, Any]` to a proper
  `CurrentUser` domain schema (architecture.md § Bounded contexts). This slice uses a
  hand-curated column allowlist; the named schema is a separate, larger refactor.
- Migration of `features/tiers/router.py` and `features/rate_limits/router.py` to the
  VSA use-case pattern. Those routers still use the flat pre-VSA pattern and are
  excluded from independence checks by project decision.

## Further Notes

The `shared_dependencies.py` file intentionally remains a cross-layer wiring point:
it is STABLE infrastructure that references both STABLE adapters/core and (for the rate
limiter) certain FEATURE repositories. This hybrid nature is an accepted trade-off
documented in `agent_docs/architecture.md` § `_shared/` rules and in the project layout
comment `"STABLE — cross-feature dependencies"`. The auth functions belong here because
authentication is a cross-cutting concern with no natural home in any single feature
domain.
