# 0006 · update_user — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

### Endpoint behaviour

- **F1.** `PATCH /api/v1/user/{username}` accepts `UpdateUserRequest` with optional fields `name`, `username`, `email`, and `profile_image_url`, and returns `UpdateUserResponse` with `{"message": "User updated"}` and HTTP `200 OK` on success.
- **F2.** The endpoint returns `401 Unauthorized` when the request carries no valid Bearer token (enforced by `get_current_user` dependency).
- **F3.** The endpoint returns `403 Forbidden` when the use case raises `ForbiddenDomainError`.
- **F4.** The endpoint returns `404 Not Found` when the use case raises `NotFoundDomainError`.
- **F5.** The endpoint returns `409 Conflict` when the use case raises `DuplicateValueDomainError`.
- **F6.** The endpoint returns `422 Unprocessable Entity` when Pydantic field-level validation fails on the request body (e.g. pattern mismatch, length violation).

### Use-case logic

- **F7.** `UpdateUserUseCase` raises `NotFoundDomainError("User not found")` when `port.get_by_username(command.target_username)` returns `None`.
- **F8.** `UpdateUserUseCase` raises `ForbiddenDomainError` when `command.requester_username` does not equal the existing user's `username` (via `check_owner`).
- **F9.** `UpdateUserUseCase` raises `DuplicateValueDomainError("Email is already registered")` when `command.email` is not `None`, differs from the existing user's email, and `port.email_exists(command.email)` returns `True`.
- **F10.** `UpdateUserUseCase` raises `DuplicateValueDomainError("Username not available")` when `command.username` is not `None`, differs from the existing user's username, and `port.username_exists(command.username)` returns `True`.
- **F11.** `UpdateUserUseCase` does **not** call `port.email_exists` when `command.email` is `None` or equals the existing user's email.
- **F12.** `UpdateUserUseCase` does **not** call `port.username_exists` when `command.username` is `None` or equals the existing user's username.
- **F13.** `UpdateUserUseCase` returns `UpdatedUserResult(message="User updated")` when all checks pass and the write succeeds.

### Shared ownership policy

- **F14.** `check_owner(requester_username, owner_username)` raises `ForbiddenDomainError` when `requester_username != owner_username`.
- **F15.** `check_owner(requester_username, owner_username)` returns `None` (no error) when `requester_username == owner_username`.

### Adapter behaviour

- **F16.** `UpdateUserAdapter.get_by_username(username)` returns an `ExistingUser` with `username` and `email` fields when the user exists and is not soft-deleted (`is_deleted == False`).
- **F17.** `UpdateUserAdapter.get_by_username(username)` returns `None` when no matching non-deleted user is found.
- **F18.** `UpdateUserAdapter.email_exists(email)` returns `True` when a row with that email exists, `False` otherwise.
- **F19.** `UpdateUserAdapter.username_exists(username)` returns `True` when a row with that username exists, `False` otherwise.
- **F20.** `UpdateUserAdapter.update(command)` maps `IntegrityError` raised by `session.commit()` to `DuplicateValueDomainError("Email or username already taken")`, preserving the original exception as cause (`from exc`).
- **F21.** `UpdateUserAdapter.update(command)` sets `updated_at` to the current UTC timestamp in the update payload.
- **F22.** `UpdateUserAdapter.update(command)` writes only the non-`None` fields from the command (excluding `target_username` and `requester_username`).

## Non-functional requirements

- **N1.** `UpdateUserUseCase` is a class with a single `__call__(command: UpdateUserCommand) -> UpdatedUserResult` method; it is invoked as `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `UpdateUserAdapter` catches only business-meaningful infrastructure exceptions: `IntegrityError` on `session.commit()` → `DuplicateValueDomainError`. All other infrastructure exceptions propagate unchanged to the global handler. The adapter does not log. Per `agent_docs/error_handling.md` § Adapter: catch only when there is business meaning to translate.
- **N3.** `UpdateUserRequest` uses `model_config = ConfigDict(extra="forbid")`. Response and entity models use `model_config = ConfigDict(from_attributes=True)` where they receive ORM-originated data.
- **N4.** Every new `.py` file in `src/app/features/users/update_user/` starts with `# FEATURE: update_user — <purpose>`. The shared file `_shared/policies.py` starts with `# FEATURE: users._shared — ownership policy.`. Per `agent_docs/stable_vs_feature.md`.
- **N5.** `UpdateUserUseCase` never raises `HTTPException`. It raises only `DomainError` subclasses defined in `app/domain/errors.py`. Per CLAUDE.md § Universal hard rules, rule 1.
- **N6.** No file in `update_user/` imports from another slice's `domain/`, `data/`, or `presentation/` layer. Cross-slice access is limited to `features/users/_shared/`. Per `agent_docs/architecture.md` § Layer rules.
- **N7.** All database operations in `UpdateUserAdapter` are `async def` with `await`; no synchronous I/O. Per CLAUDE.md § Locked technology stack.
- **N8.** `UpdateUserAdapter` explicitly inherits from `UpdateUserPort` in its class definition (`class UpdateUserAdapter(UpdateUserPort):`). Per `agent_docs/architecture.md` § Terminology: port and adapter.
- **N9.** `UpdateUserPort` is decorated with `@runtime_checkable`. Per CLAUDE.md § Forbidden without explicit user approval.
- **N10.** All imports inside `src/app/` are relative. Imports in `tests/` are absolute through `app.*`. Per `agent_docs/architecture.md` § Import conventions.
- **N11.** `mypy` strict mode passes for all new code under `src/app/`. Per CLAUDE.md § Verifying changes.
- **N12.** `ruff format` and `ruff check` pass for all new code. Per CLAUDE.md § Verifying changes.

## Out of scope

- Password update — separate use case with its own security concerns.
- Superuser ability to update any user's profile.
- Returning the updated user record in the response — current contract returns only a confirmation message.
- Moving `check_owner` to `domain/policies.py` for cross-feature use — deferred until a second feature needs it.
- Rate limiting on `PATCH /user/{username}`.
- Cache invalidation on update.
- Migrating any other `use_cases/` free functions to the hexagonal structure.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | Endpoint integration test (happy path); outside-in test |
| F2 | Endpoint integration test (unauthenticated request → 401) |
| F3 | Endpoint integration test (wrong owner → 403) |
| F4 | Endpoint integration test (unknown username → 404) |
| F5 | Endpoint integration test (duplicate email/username → 409) |
| F6 | Endpoint integration test (invalid field → 422) |
| F7 | Use-case unit test (port returns None) |
| F8 | Use-case unit test (requester_username mismatch) |
| F9 | Use-case unit test (duplicate email check) |
| F10 | Use-case unit test (duplicate username check) |
| F11 | Use-case unit test (email skip when None or unchanged) |
| F12 | Use-case unit test (username skip when None or unchanged) |
| F13 | Use-case unit test (happy path returns UpdatedUserResult) |
| F14 | Policy unit test (mismatched usernames) |
| F15 | Policy unit test (matching usernames) |
| F16 | Adapter unit test (found user) |
| F17 | Adapter unit test (user not found) |
| F18 | Adapter unit test (email_exists True/False) |
| F19 | Adapter unit test (username_exists True/False) |
| F20 | Adapter unit test (IntegrityError → DuplicateValueDomainError) |
| F21 | Adapter unit test (updated_at set) |
| F22 | Adapter unit test (only non-None fields written) |
| N1–N12 | Code review checklist in validation.md |
