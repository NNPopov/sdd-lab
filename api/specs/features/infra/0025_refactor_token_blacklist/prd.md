# PRD — Refactor Token Blacklist: Fix Architecture Violations

## Problem Statement

The token blacklist infrastructure violates two architecture rules enforced by import-linter:

1. **`core/` must not import `adapters/`** — `core/security.py` and `core/token_blacklist_service.py` directly import `crud_token_blacklist` from `adapters/db/token_blacklist/repository.py`, inverting the dependency hierarchy.
2. **FastCRUD is forbidden** — `adapters/db/token_blacklist/repository.py` uses FastCRUD, a generic CRUD wrapper that the project prohibits (adapters must be written by hand with plain SQLAlchemy).
3. **`TokenBlacklistService` lives in the wrong layer** — it is a concrete adapter implementation (backed by PostgreSQL) but resides in `core/`, the layer reserved for pure cross-cutting utilities with no infrastructure dependencies.

These violations cause `check_arch.py` (`python scripts/check_arch.py`) to fail the import-linter step, and they blur the boundary between the business-logic skeleton and the infrastructure layer, making the codebase harder to reason about and test.

## Solution

Introduce a proper `TokenBlacklistAdapter` that implements the existing `TokenBlacklistPort`, live it in `adapters/db/token_blacklist/`, and wire it through the DI container. Refactor `core/security.py` functions to receive the adapter via parameter injection instead of importing the repository directly. Remove FastCRUD from this path entirely. Delete the misplaced `core/token_blacklist_service.py`.

After this slice, `check_arch.py` passes, and the token-blacklist flow respects the project's layering rules end-to-end.

## User Stories

1. As a developer, I want `check_arch.py` to report `Core must not import Adapters` as KEPT, so that the CI architecture gate does not block merges.
2. As a developer, I want `check_arch.py` to pass for all token-blacklist-related contracts, so that I can trust the gate as a real signal.
3. As a developer, I want `TokenBlacklistAdapter` to live in `adapters/`, so that I can find all infrastructure implementations in the expected location.
4. As a developer, I want the token-blacklist adapter to use plain SQLAlchemy, so that it follows the same conventions as every other hand-written adapter in the project.
5. As a developer, I want `core/security.py` to contain only pure JWT/crypto utilities, so that it has no infrastructure dependencies and remains easy to understand.
6. As a developer, I want the DI container to wire `TokenBlacklistAdapter` as a provider, so that callers receive it via `Depends(Provide[Container.token_blacklist_adapter])` without knowing the concrete class.
7. As a developer, I want `TokenBlacklistPort` to expose `is_blacklisted` and `blacklist` methods, so that callers interact with the port, not the adapter directly.
8. As a developer, I want `verify_token`, `blacklist_token`, and `blacklist_tokens` to accept the port as a parameter, so that `security.py` is decoupled from any infrastructure import.
9. As a developer, I want `features/auth/router.py` to inject the adapter via the DI container, so that the logout and refresh endpoints use the port contract, not a direct DB call.
10. As a developer, I want `core/token_blacklist_service.py` deleted, so that there is a single authoritative implementation of the port.
11. As a developer, I want `adapters/db/token_blacklist/repository.py` (FastCRUD) deleted, so that no FastCRUD usage remains in the token-blacklist path.
12. As a developer, I want `session_factory` injected into `TokenBlacklistAdapter` via `__init__`, so that the adapter manages its own sessions and the port interface stays free of SQLAlchemy types.
13. As an API consumer, I want login, logout, and token-refresh behavior to remain identical after the refactor, so that no visible behavior changes.
14. As an API consumer, I want blacklisted tokens to continue being rejected on every authenticated endpoint, so that security guarantees are preserved.

## Implementation Decisions

### Modules to build or modify

- **`ports/token_blacklist.py`** (modify) — Expand `TokenBlacklistPort` to declare two methods: `is_blacklisted(token)` and `blacklist(token, expires_at)`. Both methods carry no `session` parameter; the adapter manages sessions internally via `session_factory`.

- **`adapters/db/token_blacklist/adapter.py`** (create) — `TokenBlacklistAdapter(TokenBlacklistPort)` with `session_factory: async_sessionmaker[AsyncSession]` injected in `__init__`. Uses plain `sqlalchemy.select` with `exists()` for `is_blacklisted` and `session.add` + `session.commit` for `blacklist`. No FastCRUD.

- **`adapters/db/token_blacklist/repository.py`** (delete) — FastCRUD instance removed entirely.

- **`core/token_blacklist_service.py`** (delete) — Superseded by `TokenBlacklistAdapter`.

- **`core/security.py`** (modify) — Remove `crud_token_blacklist` import. Update signatures: `verify_token`, `blacklist_token`, and `blacklist_tokens` each receive a `blacklist: TokenBlacklistPort` parameter instead of using `db: AsyncSession` for the blacklist check. JWT decode and crypto logic remain unchanged.

- **`bootstrap/container.py`** (modify) — Replace `token_blacklist_service` provider (old `TokenBlacklistService`) with `token_blacklist_adapter` provider (`TokenBlacklistAdapter`, `providers.Factory`, `session_factory`).

- **`shared_dependencies.py`** (modify) — `get_current_user` and `get_optional_user` inject `blacklist: TokenBlacklistPort` via `Depends(Provide[Container.token_blacklist_adapter])` and pass it to `verify_token`.

- **`features/auth/router.py`** (modify) — `logout` endpoint injects `blacklist: TokenBlacklistPort` via a local `_get_blacklist_adapter` helper (same lazy-import pattern used by VSA slice routers). `refresh_access_token` endpoint does the same for `verify_token`. Pass the adapter to the affected `security.py` functions.

### Architectural decisions

- `session_factory` in `__init__` (not session-per-call) keeps the port interface free of SQLAlchemy types, consistent with all other adapters in the project.
- `core/security.py` is not moved; it receives the port via parameter injection so its callers can supply any conforming implementation without the module importing infrastructure.
- `TokenBlacklistPort` is not extended with transaction-scoped session passing; the adapter encapsulates transaction boundaries internally, which is sufficient for the simple two-operation contract.

## Testing Decisions

A good test for this slice verifies observable behavior at the HTTP boundary, not internal calls:

- **Adapter unit test** (`tests/adapters/db/token_blacklist/test_adapter.py`) — test against a real async session (in-memory or test Postgres). Verify `is_blacklisted` returns `False` for unknown token and `True` after `blacklist` is called. Verify that infrastructure exceptions propagate unchanged (adapter does not swallow them). See `tests/features/users/create_user/` for a reference adapter unit test.

- **Endpoint integration test** (`tests/features/auth/test_auth.py`) — use `httpx.AsyncClient` against the running app. Verify that a token blacklisted on logout is rejected on a subsequent authenticated request with 401. This is the existing behavior; the test confirms no regression. See existing endpoint integration tests for the pattern.

- **Architecture test** — `python scripts/check_arch.py` must pass with `Core must not import Adapters` reported as KEPT. This is the primary acceptance signal.

The `security.py` free functions (`verify_token`, `blacklist_tokens`) do not need dedicated unit tests for the port-injection change; the behavior is fully covered by the endpoint integration test.

## Out of Scope

- Migrating `features/auth/router.py` to the full VSA slice pattern (`domain/`, `data/`, `presentation/`). The router is updated minimally — only to inject the adapter.
- Fixing the `VSA Feature Domains are Independent` import-linter violation (`posts ↔ users` transitive through `bootstrap/container`). Tracked separately.
- Fixing the `features/posts/router.py` direct import of `features/users/schemas` (`UserRead`). Tracked separately.
- Adding `blacklist` cleanup/expiry for old tokens. Out of scope for this architectural fix.
- Any changes to JWT encoding/decoding logic or token expiry values.

## Further Notes

- `blacklist_token` (singular) in `security.py` is currently defined but never imported outside the module. It should be updated consistently with `blacklist_tokens` but can be removed if deemed dead code.
- The `.importlinter` `ignore_imports` entry added for `adapters/rate_limit/redis_rate_limiter -> features/rate_limits/schemas` is unrelated and remains as-is.
- After this slice, `core/security.py` will have a residual `from sqlalchemy.ext.asyncio import AsyncSession` import only if `AsyncSession` still appears in any function signature — review and remove if no longer needed.
