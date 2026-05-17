# 0007 · delete_user — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `DELETE /api/v1/user/{username}` accepts no request body, requires a valid Bearer token, and returns `DeleteUserResponse` with `{"message": "User deleted"}` and HTTP 200 on success.
- **F2.** The use-case raises `NotFoundDomainError("User not found")` when `port.get_by_username` returns `None` (username does not exist or the row has `is_deleted == True`).
- **F3.** The use-case raises `ForbiddenDomainError` when `command.requester_username` differs from `target.username`, enforced via the `check_owner` policy in `users/_shared/policies.py`.
- **F4.** When existence and ownership checks pass, the use-case calls `port.soft_delete(command.target_username)` and returns `DeleteUserResult(message="User deleted")`.
- **F5.** The adapter's `get_by_username` returns `DeleteUserTarget(username=row.username)` when a row with the matching `username` exists and `is_deleted == False`; returns `None` otherwise.
- **F6.** The adapter's `soft_delete` issues an UPDATE that sets `is_deleted = True` and `deleted_at = datetime.now(UTC)` on the matching row; it contains no `try/except` because a soft-delete UPDATE has no unique-constraint path to catch.
- **F7.** After `await use_case(command)` returns, the router calls `await token_blacklist.blacklist(token)` with the raw Bearer token extracted via `oauth2_scheme`, invalidating the caller's session.
- **F8.** The endpoint returns HTTP 401 when the Bearer token is missing, expired, or already blacklisted (raised by `get_current_user` before the use-case is invoked).
- **F9.** The endpoint returns HTTP 403 when `ForbiddenDomainError` is raised by the use-case.
- **F10.** The endpoint returns HTTP 404 when `NotFoundDomainError` is raised by the use-case.
- **F11.** `TokenBlacklistService.blacklist(token)` decodes the JWT, extracts the `exp` claim, and writes a `TokenBlacklistCreate` record with the corresponding `expires_at` to the token-blacklist table using its own session from `session_factory`.
- **F12.** `TokenBlacklistPort` declares a single async method `blacklist(self, token: str) -> None` and carries the `@runtime_checkable` decorator.
- **F13.** `TokenBlacklistService` explicitly inherits from `TokenBlacklistPort` so that the port→implementation binding is greppable and mypy-checkable.
- **F14.** `DeleteUserAdapter` explicitly inherits from `DeleteUserPort` so that the port→adapter binding is greppable and mypy-checkable.

## Non-functional requirements

- **N1.** `DeleteUserUseCase` is a class with `__init__(self, port: DeleteUserPort)` and `async def __call__(self, command: DeleteUserCommand) -> DeleteUserResult`; called as `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** Adapter methods contain no broad `try/except`; only business-meaningful infrastructure exceptions warrant a catch, and neither `get_by_username` (read query) nor `soft_delete` (UPDATE with no unique constraint) produces any such exception in this slice. Per `agent_docs/error_handling.md` § Adapter: catch only when there is business meaning to translate.
- **N3.** `DeleteUserCommand`, `DeleteUserTarget`, and `DeleteUserResult` are `BaseModel` subclasses whose modules import only `stdlib` and `pydantic`; no framework, adapter, or core imports. Per `agent_docs/architecture.md` § Layer rules.
- **N4.** All new files in `src/app/features/users/delete_user/` start with `# FEATURE: delete_user — <purpose>`; new files in `src/app/ports/` and `src/app/core/` start with `# STABLE: <description>`. Per `agent_docs/stable_vs_feature.md`.
- **N5.** `DeleteUserUseCase` never raises `HTTPException`; it raises only `NotFoundDomainError` or `ForbiddenDomainError`. Per `CLAUDE.md` rule 1 and `agent_docs/error_handling.md`.
- **N6.** The slice imports from `users/_shared/` for the `check_owner` policy and from no other slice's `domain/`, `data/`, or `presentation/`. Per `CLAUDE.md` rule 7 and `agent_docs/architecture.md` § Layer rules.
- **N7.** All adapter methods and the `TokenBlacklistService.blacklist` method are `async def` and use `await` for every I/O call. Per `CLAUDE.md` locked technology stack.
- **N8.** `mypy src/app` passes in strict mode with no new errors introduced by this slice. Per `CLAUDE.md` § Verifying changes.
- **N9.** `ruff format src/app` and `ruff check src/app` pass with no violations introduced by this slice. Per `CLAUDE.md` § Verifying changes.
- **N10.** `TokenBlacklistService` (in `core/`) imports only `stdlib`, `third-party` libraries, `core/security.py` constants, and `adapters/db/token_blacklist/repository.py`; it never imports from `features/`. Per `agent_docs/architecture.md` § Layer rules (`core/` must never import `features/`).

## Out of scope

- Hard (permanent) deletion of the user row.
- Refresh-token blacklisting on account deletion.
- Refactoring `auth/router.py` logout to use `TokenBlacklistService`.
- Modifying `core/security.py`.
- Moving `ExistingUser` from `update_user` to `users/_shared/`.
- Cache invalidation on the delete endpoint.
- Rate limiting on the delete endpoint.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test, outside-in test |
| F2 | use-case unit test, endpoint integration test (404 case) |
| F3 | use-case unit test, endpoint integration test (403 case) |
| F4 | use-case unit test (happy path) |
| F5 | adapter unit test |
| F6 | adapter unit test, outside-in test (DB state assertion) |
| F7 | endpoint integration test (happy path), outside-in test (blacklist table assertion) |
| F8 | endpoint integration test (401 case) |
| F9 | endpoint integration test (403 case) |
| F10 | endpoint integration test (404 case) |
| F11 | `TokenBlacklistService` unit test, outside-in test |
| F12 | code review checklist in validation.md |
| F13 | code review checklist in validation.md |
| F14 | code review checklist in validation.md |
| N1–N10 | code review checklist in validation.md |
