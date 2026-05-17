# 0001 · create_user — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

### Presentation layer

**F1.** `POST /api/v1/user` accepts a `CreateUserRequest` body with fields `name`, `username`,
`email`, and `password`, and returns `201 Created` with a `CreateUserResponse` body containing
`id`, `name`, `username`, `email`, `profile_image_url`, and `tier_id` on success.

**F2.** `POST /api/v1/user` returns `422 Unprocessable Entity` when any required field is absent
or fails Pydantic field-level validation (e.g. password below minimum length, invalid email
format, username fails pattern).

**F3.** The endpoint function converts `CreateUserRequest` into `CreateUserCommand` before
invoking the use case; the use case never receives an HTTP schema type.

**F4.** The endpoint function converts the `UserRead` entity returned by the use case into
`CreateUserResponse` before returning; the domain entity is never returned directly as the HTTP
response body.

**F5.** `POST /api/v1/user` returns `409 Conflict` with a body containing
`{"error": {"code": "duplicatevalue", "message": "Email is already registered"}}` when the
submitted email is already registered.

**F6.** `POST /api/v1/user` returns `409 Conflict` with a body containing
`{"error": {"code": "duplicatevalue", "message": "Username not available"}}` when the submitted
username is already taken (and the email is unique).

### Domain layer (use case)

**F7.** `CreateUserUseCase.__call__` raises `DuplicateValueDomainError("Email is already
registered")` when `port.email_exists` returns `True` for the submitted email.

**F8.** `CreateUserUseCase.__call__` raises `DuplicateValueDomainError("Username not available")`
when `port.username_exists` returns `True` for the submitted username (email must be unique for
this branch to be reached).

**F9.** `CreateUserUseCase.__call__` checks email uniqueness before username uniqueness; a
duplicate email is always reported as the email error regardless of whether the username is also
duplicate.

**F10.** `CreateUserUseCase.__call__` hashes the plain-text password before constructing
`CreateUserInternalCommand`; `CreateUserInternalCommand.hashed_password` is not equal to
`CreateUserCommand.password`.

**F11.** `CreateUserUseCase.__call__` passes a `CreateUserInternalCommand` (not
`CreateUserCommand`) to `port.create`, so the plain-text password never reaches the adapter.

**F12.** The return value of `CreateUserUseCase.__call__` is the `UserRead` entity returned
by `port.create`, unmodified.

### Data layer (adapter)

**F13.** `CreateUserAdapter.email_exists` returns `True` when a `User` row with the given email
exists in the database, and `False` otherwise.

**F14.** `CreateUserAdapter.username_exists` returns `True` when a `User` row with the given
username exists in the database, and `False` otherwise.

**F15.** `CreateUserAdapter.create` persists a `User` ORM row built from `CreateUserInternalCommand`
and returns a `UserRead` entity constructed via `UserRead.model_validate(model)` after
`session.refresh(model)`.

**F16.** `CreateUserAdapter.create` maps `sqlalchemy.exc.IntegrityError` (raised by a unique
constraint violation) to `DuplicateValueDomainError` in the inner catch of the double
try/except.

**F17.** `CreateUserAdapter.create` (and every other adapter method) wraps any unexpected
exception in the outer catch as `UnknownDomainError`, calling `logger.error` with
`exc_info=True` before re-raising; `DomainError` subclasses that escape the inner block are
re-raised unchanged.

## Non-functional requirements

**N1.** `CreateUserUseCase` is a class with a single public method `__call__(command:
CreateUserCommand) -> UserRead`; it is called as `await use_case(command)`. Per
`agent_docs/architecture.md` — Use-case shape.

**N2.** `CreateUserAdapter` wraps every infrastructure call in a double try/except: the inner
block maps known SQLAlchemy exceptions to `DomainError` subclasses; the outer block catches
everything else, logs with `exc_info=True`, and raises `UnknownDomainError`. Per
`agent_docs/error_handling.md` — Adapter double try/except: mandatory pattern.

**N3.** `CreateUserResponse` and any Pydantic schema that is constructed from an ORM object
declares `model_config = ConfigDict(from_attributes=True)`. Per `agent_docs/architecture.md` —
Command vs Request, Entity vs Response.

**N4.** Every new file under `features/users/create_user/` starts with
`# FEATURE: create_user — <purpose>` on line 1; the new `bootstrap/container.py` starts with
`# STABLE:` on line 1. Per `agent_docs/stable_vs_feature.md`.

**N5.** `CreateUserUseCase` raises only `DomainError` subclasses; it never raises
`HTTPException`. Per `CLAUDE.md` — Universal hard rules, rule 1.

**N6.** Files in `features/users/create_user/domain/` import only from stdlib, pydantic, and
`app.domain.errors`; they do not import from `adapters/`, `core/`, or any other slice. Per
`CLAUDE.md` — Universal hard rules, rule 2.

**N7.** All database calls in `CreateUserAdapter` are `async def` with `await`; no synchronous
SQLAlchemy calls are used. Per `CLAUDE.md` — Locked technology stack.

**N8.** All new `.py` files pass `mypy` strict mode when run against `src/app/**`. Per
`CLAUDE.md` — Verifying changes.

**N9.** All new `.py` files pass `ruff format` and `ruff check` with no errors. Per
`CLAUDE.md` — Verifying changes.

## Out of scope

- Migrating other user use cases (`list`, `get`, `update`, `delete`, etc.) to the hexagonal
  structure.
- Email verification or any post-registration flow.
- Rate limiting on `POST /api/v1/user`.
- Superuser creation path.
- Adding or renaming `features/users/_shared/` — `features/users/schemas.py` continues as the
  shared entity file.
- Alembic migrations — the `User` ORM model is unchanged.
- Authentication dependency on `POST /api/v1/user` — registration is a public endpoint.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2 | endpoint integration test |
| F3 | use-case unit test (command type assertion); code review |
| F4 | endpoint integration test (response schema match); code review |
| F5 | endpoint integration test (duplicate email → 409); outside-in test |
| F6 | endpoint integration test (duplicate username → 409); outside-in test |
| F7 | use-case unit test (email_exists=True branch) |
| F8 | use-case unit test (username_exists=True branch, email unique) |
| F9 | use-case unit test (both duplicate: error message is email message) |
| F10 | use-case unit test (hashed_password ≠ plain password assertion) |
| F11 | use-case unit test (port.create called with CreateUserInternalCommand) |
| F12 | use-case unit test (return value equals port.create return value) |
| F13 | adapter unit test (email_exists True/False cases) |
| F14 | adapter unit test (username_exists True/False cases) |
| F15 | adapter unit test (create success — UserRead fields match model) |
| F16 | adapter unit test (IntegrityError → DuplicateValueDomainError) |
| F17 | adapter unit test (unexpected exception → UnknownDomainError + logger.error) |
| N1–N9 | code review checklist in validation.md |
