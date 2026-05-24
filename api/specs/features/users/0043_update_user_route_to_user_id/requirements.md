# 0043 · update_user_route_to_user_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `PATCH /api/v1/user/{user_id}` accepts a JSON body matching `UpdateUserRequest` (all fields optional: `name`, `username`, `email`, `profile_image_url`) and returns `UpdateUserResponse` (`{"message": "User updated"}`) with HTTP 200 on success.
- **F2.** FastAPI rejects a request where `{user_id}` is not a valid integer with HTTP 422.
- **F3.** The endpoint requires a valid Bearer JWT; a missing or invalid token yields HTTP 401.
- **F4.** `UpdateUserUseCase.__call__` raises `NotFoundDomainError("User not found")` when `UpdateUserPort.get_by_id(command.target_user_id)` returns `None`.
- **F5.** `UpdateUserUseCase.__call__` raises `ForbiddenDomainError` when `command.requester_user_id` does not equal `existing.id`.
- **F6.** `UpdateUserUseCase.__call__` raises `DuplicateValueDomainError("Email is already registered")` when `command.email` is non-`None`, differs from `existing.email`, and `UpdateUserPort.email_exists(command.email)` returns `True`.
- **F7.** `UpdateUserUseCase.__call__` does **not** call `email_exists` when `command.email` equals `existing.email`.
- **F8.** `UpdateUserUseCase.__call__` raises `DuplicateValueDomainError("Username not available")` when `command.username` is non-`None`, differs from `existing.username`, and `UpdateUserPort.username_exists(command.username)` returns `True`.
- **F9.** `UpdateUserUseCase.__call__` does **not** call `username_exists` when `command.username` equals `existing.username`.
- **F10.** `UpdateUserAdapter.get_by_id(user_id)` returns an `ExistingUser` (with `id`, `username`, `email`) for a non-deleted user matching the integer PK, and `None` otherwise.
- **F11.** `UpdateUserAdapter.update(command)` executes a SQL `UPDATE` on the row identified by `User.id == command.target_user_id`, writing only the non-`None` payload fields plus `updated_at`.
- **F12.** `UpdateUserAdapter.update` raises `DuplicateValueDomainError("Email or username already taken")` when `session.commit()` raises `sqlalchemy.exc.IntegrityError`.
- **F13.** `check_owner(requester_user_id: int, owner_user_id: int)` in `users/_shared/policies.py` raises `ForbiddenDomainError` when the two integer arguments differ, and returns `None` when they are equal.
- **F14.** The global exception handler translates `NotFoundDomainError` → HTTP 404, `ForbiddenDomainError` → HTTP 403, and `DuplicateValueDomainError` → HTTP 409.
- **F15.** The router constructs `UpdateUserCommand` with `target_user_id` from the path parameter and `requester_user_id` from `current_user["id"]` (the auth dict).

## Non-functional requirements

- **N1.** `UpdateUserUseCase` is a class with `__call__()`; called as `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `UpdateUserAdapter` catches only business-meaningful infrastructure exceptions (`IntegrityError` on `commit()` → `DuplicateValueDomainError`). All other infrastructure exceptions propagate to the global handler. The adapter does not log. Per `agent_docs/error_handling.md`.
- **N3.** All modified files retain their `# FEATURE:` header on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N4.** No `HTTPException` is raised inside `UpdateUserUseCase`. Per `CLAUDE.md` rule 1.
- **N5.** No cross-slice imports; `update_user` may import only from its own files and `features/users/_shared/`. Per `CLAUDE.md` rule 7 and `agent_docs/architecture.md` § Layer rules.
- **N6.** All I/O in `UpdateUserAdapter` is `async def` + `await`; no synchronous DB calls. Per `CLAUDE.md` locked stack.
- **N7.** `UpdateUserAdapter` inherits explicitly from `UpdateUserPort`: `class UpdateUserAdapter(UpdateUserPort):`. Per `agent_docs/architecture.md` § Terminology: port and adapter.
- **N8.** `UpdateUserPort` carries `@runtime_checkable` decorator. Per `agent_docs/architecture.md` § Port pattern.
- **N9.** All imports inside `src/app/` are relative. Per `agent_docs/architecture.md` § Import conventions.
- **N10.** `mypy src/app` strict passes with no new errors introduced by this slice.
- **N11.** `ruff format` and `ruff check` pass with no new violations.

## Out of scope

- Migrating `delete_user` (0044), `delete_db_user` (0045), `assign_moderator` (0046), `revoke_moderator` (0047), `get_user_tier` (0048), `rate_limits` (0049), `update_user_tier` (0050).
- Superuser ability to update any profile.
- Cache invalidation on `PATCH /user/{user_id}`.
- Rate limiting on this endpoint.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (200 happy path) |
| F2 | endpoint integration test (422 non-integer path param) |
| F3 | endpoint integration test (401 missing/invalid token) |
| F4 | use-case unit test; endpoint integration test (404) |
| F5 | use-case unit test; endpoint integration test (403) |
| F6 | use-case unit test; endpoint integration test (409 duplicate email) |
| F7 | use-case unit test (email-unchanged branch) |
| F8 | use-case unit test; endpoint integration test (409 duplicate username) |
| F9 | use-case unit test (username-unchanged branch) |
| F10 | adapter unit test (get_by_id found / not found) |
| F11 | adapter unit test (update fields and WHERE clause) |
| F12 | adapter unit test (IntegrityError → DuplicateValueDomainError) |
| F13 | use-case unit test (check_owner via policies); outside-in test (403 scenario) |
| F14 | endpoint integration test (404, 403, 409 status codes) |
| F15 | endpoint integration test; outside-in test |
| N1–N11 | code review checklist in validation.md |
