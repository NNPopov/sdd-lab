# 0008 · delete_db_user — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `DELETE /api/v1/db_user/{username}` accepts no request body, requires a valid Bearer token with superuser privileges, and returns `DeleteDbUserResponse` with `{"message": "User deleted from the database"}` and HTTP 200 on success.
- **F2.** The use-case raises `NotFoundDomainError("User not found")` when `port.get_by_username` returns `None`; the query matches on `username` only, with no filter on `is_deleted`, so the error is raised whether the username never existed or the row is absent for any other reason.
- **F3.** When `port.get_by_username` returns a `DbDeleteUserTarget`, the use-case calls `port.db_delete(command.target_username)` and returns `DeleteDbUserResult(message="User deleted from the database")`.
- **F4.** The adapter's `get_by_username` returns `DbDeleteUserTarget(username=row.username)` when a row with the matching `username` exists regardless of its `is_deleted` value; returns `None` when no row matches.
- **F5.** The adapter's `db_delete` executes a raw SQLAlchemy `DELETE` statement targeting the `User` row whose `username` matches `command.target_username`.
- **F6.** The adapter's `db_delete` wraps `session.commit()` in a narrow `try/except IntegrityError` and re-raises as `DuplicateValueDomainError("User has dependent records") from exc`; all other exceptions propagate unchanged to the global handler.
- **F7.** The endpoint returns HTTP 401 when the Bearer token is missing, expired, or invalid (raised by `get_current_superuser` before the use-case is invoked).
- **F8.** The endpoint returns HTTP 403 when the authenticated user is not a superuser (raised by `get_current_superuser` before the use-case is invoked).
- **F9.** The endpoint returns HTTP 404 when `NotFoundDomainError` is raised by the use-case.
- **F10.** The endpoint returns HTTP 409 when `DuplicateValueDomainError` is raised by the adapter (FK violation from dependent records).
- **F11.** `DeleteDbUserCommand` contains only `target_username: str`; no requester identity is passed to the use-case because superuser authorisation is enforced at the router level via `get_current_superuser`.
- **F12.** `DeleteDbUserAdapter` explicitly inherits from `DeleteDbUserPort` so that the port→adapter binding is greppable and mypy-checkable.

## Non-functional requirements

- **N1.** `DeleteDbUserUseCase` is a class with `__init__(self, port: DeleteDbUserPort)` and `async def __call__(self, command: DeleteDbUserCommand) -> DeleteDbUserResult`; called as `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `DeleteDbUserAdapter.get_by_username` contains no `try/except` (read-only query; no business-meaningful exception to translate); `db_delete` catches only `IntegrityError` from `session.commit()` and raises `DuplicateValueDomainError`; all other exceptions propagate unchanged. Per `agent_docs/error_handling.md` § Adapter: catch only when there is business meaning to translate.
- **N3.** `DeleteDbUserCommand`, `DbDeleteUserTarget`, and `DeleteDbUserResult` are `BaseModel` subclasses whose modules import only `stdlib` and `pydantic`; no framework, adapter, or core imports allowed. Per `agent_docs/architecture.md` § Layer rules.
- **N4.** All new files in `src/app/features/users/delete_db_user/` start with `# FEATURE: delete_db_user — <purpose>`. Per `agent_docs/stable_vs_feature.md`.
- **N5.** `DeleteDbUserUseCase` never raises `HTTPException`; it raises only `NotFoundDomainError`. Per `CLAUDE.md` rule 1 and `agent_docs/error_handling.md`.
- **N6.** The slice imports from no other slice's `domain/`, `data/`, or `presentation/`; within the `users` feature, only `users/dependencies.py` (for `get_current_superuser`) is imported by the router. Per `CLAUDE.md` rule 7 and `agent_docs/architecture.md` § Layer rules.
- **N7.** All adapter methods are `async def` and use `await` for every I/O call. Per `CLAUDE.md` locked technology stack.
- **N8.** `mypy src/app` passes in strict mode with no new errors introduced by this slice. Per `CLAUDE.md` § Verifying changes.
- **N9.** `ruff format src/app` and `ruff check src/app` pass with no violations introduced by this slice. Per `CLAUDE.md` § Verifying changes.

## Out of scope

- Soft deletion — handled by `delete_user` (0007).
- Token blacklisting on hard delete — deleted user's tokens expire naturally; superuser's token is not invalidated.
- Cascade deletion of dependent records (posts, etc.) — FK constraint surfaced as 409; schema-level cascade is a separate infrastructure change.
- Rate limiting — endpoint is behind superuser auth.
- Caching — no read path; nothing to cache or invalidate.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test, outside-in test |
| F2 | use-case unit test (not-found case), endpoint integration test (404 case) |
| F3 | use-case unit test (happy path), outside-in test (DB state assertion) |
| F4 | adapter unit test (active row, soft-deleted row, missing row) |
| F5 | adapter unit test, outside-in test (row absent from DB after request) |
| F6 | adapter unit test (IntegrityError case), endpoint integration test (409 case) |
| F7 | endpoint integration test (401 case) |
| F8 | endpoint integration test (403 case) |
| F9 | endpoint integration test (404 case) |
| F10 | endpoint integration test (409 case) |
| F11 | code review checklist in validation.md |
| F12 | code review checklist in validation.md |
| N1–N9 | code review checklist in validation.md |
