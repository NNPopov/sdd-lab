# PRD — Create User (Slice 0001)

## Problem Statement

The existing user creation logic is implemented as a single free function that
directly injects a database session and a FastCRUD repository instance. This
violates the project's Vertical Slice + Hexagonal Architecture in several ways:

- The use case is not a class and therefore cannot be wired through the
  dependency injection container or called from non-HTTP entry points (Celery,
  Langgraph).
- The data access layer (FastCRUD) is used directly inside the use case,
  bypassing the port/adapter contract.
- FastCRUD is explicitly forbidden per project conventions.
- Password hashing, existence checks, and persistence are interleaved with no
  clear layer separation.
- No port interface exists, making the use case impossible to unit-test without
  a live database.
- No DI container exists for the users feature, so test overrides require
  monkey-patching.

## Solution

Replace the free-function use case with a fully conformant hexagonal slice for
the "create user" use case. The slice contains:

- A **domain layer** with a command (input contract), an internal command
  (post-hashing contract), a port protocol, and a use case class.
- A **data layer** with a concrete adapter that implements the port using
  SQLAlchemy, protected by the mandatory double try/except error-mapping pattern.
- A **presentation layer** with dedicated request/response schemas and a FastAPI
  router that translates HTTP → Command → use case → Response.
- A **DI container** in `bootstrap/` that wires the adapter and use case as
  `dependency_injector` providers, making the use case resolvable from the
  container rather than from raw FastAPI `Depends`.

The existing `features/users/router.py` aggregator is updated to include the
new slice router, keeping all other user routes unaffected.

## User Stories

1. As a developer, I want the create-user use case to be a class so that I can
   wire it through the DI container and call it from Celery tasks or Langgraph
   nodes without importing the HTTP layer.
2. As a developer, I want the use case to accept a domain command (not an HTTP
   request schema) so that the domain layer remains independent of the transport.
3. As a developer, I want the use case to raise `DuplicateValueDomainError` with
   a specific message ("Email is already registered" vs "Username not available")
   so that callers receive actionable error information.
4. As a developer, I want password hashing to happen in the use case so that the
   adapter only ever stores already-hashed passwords.
5. As a developer, I want the port interface to expose narrow methods
   (`username_exists`, `email_exists`, `create`) so that the use case can be
   unit-tested by providing a mock port without a live database.
6. As a developer, I want the adapter to wrap every DB call in a double
   try/except so that infrastructure exceptions are always mapped to
   `DomainError` subclasses and never escape to the HTTP layer as bare
   exceptions.
7. As a developer, I want the adapter to log unexpected failures with
   `exc_info=True` and re-raise as `UnknownDomainError` so that every
   production incident is captured in the structured logs.
8. As a developer, I want the presentation layer to own `CreateUserRequest` and
   `CreateUserResponse` schemas so that HTTP-specific fields never leak into the
   domain.
9. As a developer, I want the router to convert `CreateUserRequest` →
   `CreateUserCommand` at the FastAPI boundary so that the use case is not aware
   of the HTTP transport.
10. As a developer, I want the DI container to declare `CreateUserAdapter` and
    `CreateUserUseCase` as `providers.Factory` so that test suites can override
    the adapter without touching the HTTP layer.
11. As an API client, I want `POST /api/v1/user` to return `201 Created` with
    the created user's public fields so that I can confirm the registration
    succeeded.
12. As an API client, I want `POST /api/v1/user` to return `409 Conflict` when
    the email is already taken so that I can prompt the user to use a different
    email.
13. As an API client, I want `POST /api/v1/user` to return `409 Conflict` when
    the username is already taken so that I can prompt the user to choose a
    different username.
14. As an API client, I want the endpoint to accept `name`, `username`, `email`,
    and `password` fields so that all required registration data is collected in
    one request.
15. As a developer, I want the old flat `use_cases/user_create.py` removed after
    the new slice is wired so that the codebase has a single, authoritative
    implementation.

## Implementation Decisions

### Modules to build

- **Domain commands** — two Pydantic models: `CreateUserCommand` (plain
  password, input to use case) and `CreateUserInternalCommand` (hashed password,
  input to port's `create` method).
- **Port interface** — `CreateUserPort` Protocol with three async methods:
  `username_exists(username) -> bool`, `email_exists(email) -> bool`,
  `create(command: CreateUserInternalCommand) -> UserRead`.
- **Use case class** — `CreateUserUseCase` with a single `port` dependency
  injected at construction. `__call__` checks email uniqueness first, then
  username uniqueness (matching the order in the existing implementation), then
  hashes the password, builds `CreateUserInternalCommand`, and delegates to the
  port.
- **Data adapter** — `CreateUserAdapter` implementing `CreateUserPort`. Each
  method wraps its SQLAlchemy call in a double try/except: inner catch maps
  `IntegrityError` to `DuplicateValueDomainError`; outer catch logs and re-raises
  as `UnknownDomainError`. The adapter holds an `async_sessionmaker` injected at
  construction (not `AsyncSession`), so each method opens its own short-lived
  session.
- **Presentation schemas** — `CreateUserRequest` (input, mirrors `UserCreate`
  fields) and `CreateUserResponse` (output, mirrors `UserRead` fields).
- **Presentation router** — single `POST /user` endpoint. Validates via
  `CreateUserRequest`, builds command, calls use case, returns
  `CreateUserResponse`.
- **DI container** — `bootstrap/container.py` declaring `session_factory`,
  `create_user_adapter`, and `create_user_use_case` as `providers.Resource` /
  `providers.Factory`. The container's `wiring_config` targets the presentation
  router module.

### Modules to modify

- **`features/users/router.py`** — remove the `write_user` import and
  `router.post("/user", ...)` line; replace with `router.include_router` of the
  new presentation router.
- **`features/users/use_cases/user_create.py`** — deleted; superseded by the
  new slice.

### Key architectural constraints

- Use case raises only `DomainError` subclasses, never `HTTPException`.
- `domain/` files import only from stdlib, pydantic, `app.domain.errors`, and
  the own feature's shared schemas.
- `data/adapter.py` imports `app.adapters.db.models.user.User` (ORM) and
  `app.adapters.db.session.async_session_factory`.
- `presentation/router.py` imports the use case via
  `Depends(Provide[Container.create_user_use_case])`.
- Every new `.py` file begins with a `# FEATURE:` header.

## Testing Decisions

Good tests for this slice verify **external behavior**, not implementation
details. A test should not assert that a specific private method was called; it
should assert that the observable outcome (return value, exception type, HTTP
status, DB state) is correct.

### Use case unit tests

Mock the port entirely. Assert:
- When `email_exists` returns `True`, `__call__` raises
  `DuplicateValueDomainError` with the email message.
- When `username_exists` returns `True`, `__call__` raises
  `DuplicateValueDomainError` with the username message.
- On success, `create` is called with a `CreateUserInternalCommand` whose
  `hashed_password` is not equal to the plain password (hashing occurred).
- The return value of `__call__` equals the value returned by `port.create`.

### Adapter unit tests

Mock the `async_sessionmaker` / `AsyncSession`. Assert:
- `username_exists` returns `True` when the query finds a matching row.
- `email_exists` returns `True` when the query finds a matching row.
- `create` returns a `UserRead` built from the ORM model on success.
- `create` maps `IntegrityError` to `DuplicateValueDomainError`.
- `create` wraps any unexpected exception as `UnknownDomainError` and calls
  `logger.error` with `exc_info=True`.

### Endpoint integration tests

Use `httpx.AsyncClient` against the full running app with the test Postgres
instance. Assert:
- `POST /api/v1/user` with valid payload returns `201` and a body matching
  `CreateUserResponse`.
- Duplicate email returns `409` with a message field.
- Duplicate username returns `409` with a message field.
- Missing required field returns `422`.

## Out of Scope

- Migrating any other user use cases (`list`, `get`, `update`, `delete`, etc.)
  to the full hexagonal slice structure. Only `create_user` is in scope.
- Email verification or any post-registration flow.
- Rate limiting on the create-user endpoint.
- Superuser creation path (handled by a separate script).
- Adding `_shared/` subfolder renaming — `features/users/schemas.py` continues
  to serve as the shared entity definitions for all user slices.
- Alembic migrations — no schema changes are required; the ORM model is
  unchanged.

## Further Notes

- The check order (email first, then username) matches the current
  implementation and should be preserved to avoid changing existing API behavior.
- The ORM model (`adapters/db/models/user.py`) is `# STABLE` and must not be
  modified during this work.
- `bootstrap/container.py` is a new file; it does not exist yet. It is
  `# STABLE` once written, per the STABLE/FEATURE convention for `bootstrap/`
  files.
- The `features/users/router.py` aggregator is updated minimally: one line
  removed, one `include_router` call added.
