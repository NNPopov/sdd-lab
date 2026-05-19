# 0025 · refactor_token_blacklist — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `TokenBlacklistPort` in `src/app/ports/token_blacklist.py` declares exactly two methods: `async def is_blacklisted(self, token: str) -> bool` and `async def blacklist(self, token: str, expires_at: datetime) -> None`.
- **F2.** `TokenBlacklistAdapter` in `src/app/adapters/db/token_blacklist/adapter.py` explicitly inherits from `TokenBlacklistPort` in its class declaration (`class TokenBlacklistAdapter(TokenBlacklistPort):`).
- **F3.** `TokenBlacklistAdapter.__init__` accepts `session_factory: async_sessionmaker[AsyncSession]` as its only parameter and stores it as `self._session_factory`; the port interface exposes no `session` parameter.
- **F4.** `TokenBlacklistAdapter.is_blacklisted` returns `False` when no row with the given `token` value exists in the `token_blacklist` table.
- **F5.** `TokenBlacklistAdapter.is_blacklisted` returns `True` when a row with the given `token` value exists in the `token_blacklist` table.
- **F6.** `TokenBlacklistAdapter.blacklist` inserts a `TokenBlacklist` row with the provided `token` and `expires_at` values and commits the session.
- **F7.** `TokenBlacklistAdapter` contains no `try/except` block; all infrastructure exceptions from `is_blacklisted` (e.g., `OperationalError`) propagate unchanged to the caller.
- **F8.** All infrastructure exceptions from `TokenBlacklistAdapter.blacklist` (e.g., `OperationalError`) propagate unchanged to the caller.
- **F9.** `verify_token` in `src/app/core/security.py` accepts `blacklist: TokenBlacklistPort` as its third parameter (replacing `db: AsyncSession`) and delegates the blacklist check to `await blacklist.is_blacklisted(token)`.
- **F10.** `blacklist_tokens` in `src/app/core/security.py` accepts `blacklist: TokenBlacklistPort` as its third parameter (replacing `db: AsyncSession`) and calls `await blacklist.blacklist(token, expires_at)` for each token.
- **F11.** `blacklist_token` in `src/app/core/security.py` accepts `blacklist: TokenBlacklistPort` as its second parameter (replacing `db: AsyncSession`) and calls `await blacklist.blacklist(token, expires_at)`.
- **F12.** `src/app/core/security.py` contains no import from `src/app/adapters/` after the refactor.
- **F13.** `bootstrap/container.py` declares `token_blacklist_adapter = providers.Factory(TokenBlacklistAdapter, session_factory=session_factory)` and no longer references `TokenBlacklistService`.
- **F14.** `bootstrap/container.py` wiring configuration includes `"app.shared_dependencies"` and `"app.features.auth.router"` so that `Provide[Container.token_blacklist_adapter]` resolves correctly in those modules.
- **F15.** `get_current_user` in `src/app/shared_dependencies.py` injects `blacklist: TokenBlacklistPort` via `Depends(Provide[Container.token_blacklist_adapter])` and passes it as the third argument to `verify_token`.
- **F16.** `get_optional_user` in `src/app/shared_dependencies.py` injects `blacklist: TokenBlacklistPort` via `Depends(Provide[Container.token_blacklist_adapter])` and passes it to `verify_token`.
- **F17.** The `logout` endpoint in `src/app/features/auth/router.py` injects `blacklist: TokenBlacklistPort` via the DI container and passes it to `blacklist_tokens`; the `db: AsyncSession` parameter is removed from this endpoint.
- **F18.** The `refresh_access_token` endpoint in `src/app/features/auth/router.py` injects `blacklist: TokenBlacklistPort` via the DI container and passes it to `verify_token`; the `db: AsyncSession` parameter is removed from this endpoint.
- **F19.** `src/app/core/token_blacklist_service.py` is deleted from the codebase.
- **F20.** `src/app/adapters/db/token_blacklist/repository.py` (FastCRUD instance) is deleted from the codebase.
- **F21.** A token blacklisted via `POST /api/v1/logout` is rejected with HTTP 401 on any subsequent request to an authenticated endpoint that uses `get_current_user`.
- **F22.** `python scripts/check_arch.py` exits with code 0 and its output contains `KEPT` for the contract `Core must not import Adapters`.

## Non-functional requirements

- **N1.** `TokenBlacklistAdapter` uses only plain SQLAlchemy (`select`, `exists`, `session.add`, `session.commit`); FastCRUD is not used anywhere in the token-blacklist path. Per CLAUDE.md § Forbidden.
- **N2.** `TokenBlacklistAdapter` catches only business-meaningful infrastructure exceptions; since no such exception exists for this adapter's two operations, it contains no `try/except` block. Per `agent_docs/error_handling.md`.
- **N3.** `src/app/adapters/db/token_blacklist/adapter.py` starts with `# STABLE:` on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N4.** All imports inside `src/app/` are relative; absolute `app.*` imports are used only in `tests/`. Per `agent_docs/architecture.md` § Import conventions.
- **N5.** `core/` imports no module from `adapters/` or `features/` after the refactor. Per `agent_docs/architecture.md` layer rules.
- **N6.** `adapters/db/token_blacklist/adapter.py` imports no module from `features/`. Per `agent_docs/architecture.md` layer rules.
- **N7.** `TokenBlacklistPort` carries the `@runtime_checkable` decorator so that `isinstance(adapter, TokenBlacklistPort)` works at runtime. Per `agent_docs/architecture.md` § Port pattern.
- **N8.** All I/O in `TokenBlacklistAdapter` is `async def` + `await`; no synchronous database calls. Per CLAUDE.md § Locked technology stack.
- **N9.** `mypy src/app` passes with strict settings after all changes are applied.
- **N10.** `ruff format src/app` and `ruff check src/app` produce no errors or warnings after all changes are applied.

## Out of scope

- Migrating `features/auth/router.py` to the full VSA slice pattern (`domain/`, `data/`, `presentation/`).
- Fixing the `VSA Feature Domains are Independent` import-linter violation (`posts ↔ users` transitive through `bootstrap/container`).
- Fixing `features/posts/router.py` direct import of `features/users/schemas`.
- Token expiry cleanup (deleting old rows from the `token_blacklist` table).
- Any change to JWT encoding/decoding logic or token expiry values.
- Removing `TokenBlacklistCreate` from `core/schemas.py` (may still be referenced elsewhere; deferred to a separate cleanup slice).

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | code review checklist (validation.md) |
| F2 | adapter unit test + code review checklist |
| F3 | adapter unit test + code review checklist |
| F4 | adapter unit test |
| F5 | adapter unit test |
| F6 | adapter unit test |
| F7 | adapter unit test |
| F8 | adapter unit test |
| F9 | endpoint integration test |
| F10 | endpoint integration test |
| F11 | code review checklist |
| F12 | outside-in test (architecture gate) + code review checklist |
| F13 | endpoint integration test + code review checklist |
| F14 | endpoint integration test (Provide resolves correctly) |
| F15 | endpoint integration test |
| F16 | endpoint integration test |
| F17 | endpoint integration test |
| F18 | endpoint integration test |
| F19 | code review checklist |
| F20 | code review checklist |
| F21 | endpoint integration test + outside-in test |
| F22 | outside-in test |
| N1–N10 | code review checklist in validation.md |
