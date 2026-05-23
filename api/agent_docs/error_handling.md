# Error handling

This document is the reference for how errors flow through the system. Read
it before writing or reviewing any adapter, use-case, or exception handler.

For overall architecture, see `agent_docs/architecture.md`. For testing of
error paths, see `agent_docs/testing.md`.

## The model in one sentence

**A single global exception handler catches everything; adapters and
use-cases only ever raise — they almost never catch.**

This is the same model used in idiomatic ASP.NET Core, Spring, and Express:
one place at the application boundary translates exceptions to responses,
and the rest of the code stays clean of error-handling noise.

The exceptions to "almost never catch" are narrow and specific: when an
infrastructure exception carries **business meaning** that the rest of the
system should react to (e.g. a unique-constraint violation is a domain
duplicate), the adapter catches that one exception and re-raises it as a
`DomainError`. Everything else propagates.

## Three layers, three responsibilities

| Layer | What it does with errors |
|---|---|
| Domain (use-case) | **Raises** `DomainError` subclasses. Never catches. |
| Data (adapter) | **Raises** `DomainError` for business-meaningful infrastructure failures (very few). Never catches anything else. |
| Transport (FastAPI exception handlers) | **Catches** `DomainError` and `Exception` globally. Converts to HTTP responses. |

A use-case never raises `HTTPException`. An adapter never wraps code in
`try: ... except Exception:`. A router never wraps a use-case call in
`try/except`.

## DomainError hierarchy

Defined once in `app/domain/errors.py`:

```python
# STABLE: DomainError hierarchy.

class DomainError(Exception):
    """Base class for all expected domain failures."""

    def __init__(self, message: str = "", code: str | None = None) -> None:
        self.message = message
        # Derive code from class name if not provided:
        # "NotFoundDomainError" → "notfound"
        if code is None:
            class_name = self.__class__.__name__
            if class_name.endswith("DomainError"):
                self.code = class_name[:-11].lower()
            else:
                self.code = class_name.lower()
        else:
            self.code = code
        super().__init__(message)


class NotFoundDomainError(DomainError):
    """Resource not found."""


class DuplicateValueDomainError(DomainError):
    """A duplicate value would be created."""


class ForbiddenDomainError(DomainError):
    """Caller does not have permission."""


class UnknownDomainError(DomainError):
    """Adapter encountered an unexpected failure it cannot classify."""
```

Adding a new subclass is a STABLE change (`domain/errors.py`) and requires
explicit user approval. Most slices need only the first three subclasses.

The `code` field is derived automatically from the class name (suffix
`DomainError` stripped, lowercased). It appears in every error response body
(see § Global exception handler below). Pass an explicit `code=` only when
the derived name would be misleading.

## Global exception handler (the only place that catches)

Registered once in `bootstrap/factory.py` via
`application.add_exception_handler(DomainError, domain_error_handler)`.
The handler lives in `adapters/http/exception_handlers.py`:

```python
# STABLE: Maps domain errors to HTTP responses.

from fastapi import Request
from fastapi.responses import JSONResponse

from ...domain.errors import (
    DomainError,
    DuplicateValueDomainError,
    ForbiddenDomainError,
    NotFoundDomainError,
)

STATUS_MAP: dict[type[DomainError], int] = {
    NotFoundDomainError: 404,
    DuplicateValueDomainError: 409,
    ForbiddenDomainError: 403,
}


async def domain_error_handler(request: Request, exc: Exception) -> JSONResponse:
    assert isinstance(exc, DomainError)
    status_code = STATUS_MAP.get(type(exc), 500)
    return JSONResponse(
        status_code=status_code,
        content={
            "error": {
                "code": exc.code,
                "message": exc.message,
            }
        },
    )
```

**Response body for every `DomainError`:**

```json
{
  "error": {
    "code": "notfound",
    "message": "Tier not found"
  }
}
```

The `code` value is the auto-derived lowercase name (e.g. `"notfound"`,
`"duplicatevalue"`, `"forbidden"`, `"unknown"`).

**Status codes come from `STATUS_MAP`**, not from an attribute on the
exception class. Any `DomainError` subclass not in the map returns 500.
Unknown infrastructure exceptions that are not `DomainError` subclasses are
handled by FastAPI/Starlette's default 500 handler — they are not caught by
`domain_error_handler`.

## Adapter: catch only when there is business meaning to translate

The adapter is the one place where you may legitimately catch — but only
when catching converts an **infrastructure exception** into a
**domain concept** that the rest of the system needs to know about.

Worth catching:

| Infrastructure exception | Domain meaning |
|---|---|
| `IntegrityError` (unique-constraint violation) | `DuplicateValueDomainError` |
| `IntegrityError` (FK violation) | `DomainError("references missing entity")` (or a custom subclass if the FK violation has specific domain meaning) |
| `NoResultFound` (only when the adapter must distinguish "missing" from "failed") | `NotFoundDomainError` |

Not worth catching (let them propagate):

- `OperationalError` (connection lost, statement timeout)
- `ProgrammingError` (bad SQL, schema mismatch)
- `DataError` (Pydantic-level constraints already caught upstream)
- `asyncio.TimeoutError`
- `redis.ConnectionError`
- Any other low-level infrastructure exception

These are not domain concepts. They are system failures. The global
catch-all handler logs them and returns 500. Catching them in the adapter
would only duplicate work and obscure the stack trace.

### Right shape: create with one specific catch

```python
# FEATURE: create_user — adapter.
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from ...._shared.schemas import User
from ....adapters.db.models.user import UserModel
from ....domain.errors import DuplicateValueDomainError
from ..domain.commands import CreateUserInternalCommand
from ..domain.ports.create_user_port import CreateUserPort


class CreateUserAdapter(CreateUserPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def create(self, command: CreateUserInternalCommand) -> User:
        async with self._session_factory() as session:
            model = UserModel(
                username=command.username,
                email=command.email,
                hashed_password=command.hashed_password,
            )
            session.add(model)
            try:
                await session.commit()
            except IntegrityError as exc:
                # Unique violation is a domain concept; translate it.
                raise DuplicateValueDomainError(
                    "Username or email already taken"
                ) from exc
            await session.refresh(model)
            return User.model_validate(model)
```

Things to note:

- One `try/except`, narrow scope (just around `session.commit()`).
- Catches one specific exception type, not `Exception`.
- `raise ... from exc` preserves the cause for the stack trace.
- No outer broad catch. No logging. The global handler does both if needed.

### Right shape: read-only query, no catch

```python
# FEATURE: create_user — adapter (continued).

async def email_exists(self, email: str) -> bool:
    async with self._session_factory() as session:
        result = await session.execute(select(UserModel).where(UserModel.email == email))
        return result.scalar_one_or_none() is not None
```

No `try/except`. If the DB is unreachable, `OperationalError` propagates up
through the use-case (which does not catch it either), then through the
endpoint. Because the registered handler only catches `DomainError`,
infrastructure exceptions propagate to FastAPI/Starlette's built-in 500
handler, which returns HTTP 500. That is correct: a dead DB is not a domain
concept and should be reported as a service failure, not as a custom "domain"
error.

## Anti-pattern: the broad outer catch

This is the pattern that was incorrectly recommended in earlier versions of
this document. **Do not use it.**

```python
# ❌ ANTI-PATTERN — do not write code like this.
async def email_exists(self, email: str) -> bool:
    try:
        try:
            async with self._session_factory() as session:
                result = await session.execute(select(User).where(User.email == email))
                return result.scalar_one_or_none() is not None
        except Exception as exc:
            if isinstance(exc, DomainError):
                raise
            raise exc
    except DomainError:
        raise
    except Exception as exc:
        logger.error("CreateUserAdapter.email_exists failed unexpectedly", exc_info=True)
        raise UnknownDomainError("email_exists adapter failed") from exc
```

Problems with this code:

1. The inner block catches `Exception` only to immediately re-raise — pure
   dead code.
2. The outer block duplicates exactly what the global `_catch_all` handler
   already does (log with `exc_info=True`, surface as 500).
3. `UnknownDomainError` is a fake domain concept; "the database is down" is
   not a domain failure mode, it is an infrastructure failure.
4. The stack trace shown to the operator is one frame deeper than necessary
   because of the wrapping `raise UnknownDomainError(...) from exc`.
5. Anyone reading the adapter has to mentally parse the nested blocks to
   confirm they do nothing useful — wasted attention.

The correct version is **no try/except at all** (see "read-only query"
example above). Less code, more readable, identical behavior at runtime.

## Use-case: raises, does not catch

Business validation (state-dependent rules) and authorization happen in the
use-case. The use-case raises `DomainError` subclasses and never catches.

```python
# FEATURE: create_user — use case.

class CreateUserUseCase:
    def __init__(self, port: CreateUserPort) -> None:
        self._port = port

    async def __call__(self, command: CreateUserCommand) -> User:
        if await self._port.username_exists(command.username):
            raise DuplicateValueDomainError("Username already taken")
        if await self._port.email_exists(command.email):
            raise DuplicateValueDomainError("Email already taken")
        internal = command.to_internal(hashed_password=hash_password(command.password))
        return await self._port.create(internal)
```

Note: the use-case anticipates the duplicate by checking first. The adapter
**also** catches `IntegrityError` from `create()`. This is intentional
defense in depth — the check-then-act is racy across concurrent requests,
and the adapter's catch ensures the final commit cannot silently corrupt
state. Both checks coexist; only one will fire in any given request.

## Authorization with `ForbiddenDomainError`

When a use-case enforces ownership or role rules:

```python
async def __call__(self, command: DeletePostCommand) -> None:
    post = await self._port.get(command.post_id)
    if post.author_username != command.acting_user.username:
        raise ForbiddenDomainError("You can only delete your own posts")
    await self._port.delete(command.post_id)
```

The acting user identity is part of the command. The use-case does not read
`request.state` or any FastAPI-specific object.

## Validation in the use-case

Pydantic catches shape errors at the FastAPI boundary. Validation that
depends on state lives in the use-case and raises a `DomainError` subclass:

```python
async def __call__(self, command: TransferFundsCommand) -> Transfer:
    if command.amount <= 0:
        raise DomainError("Amount must be positive")
    if await self._port.balance(command.source) < command.amount:
        raise DomainError("Insufficient funds")
    ...
```

Field-level Pydantic constraints in `*Request` schemas remain the first
line of defense. The use-case raises `DomainError` only for what Pydantic
cannot check (state, business invariants). If the project needs a dedicated
`ValidationDomainError` subclass with a different HTTP status or `code`,
add it to `domain/errors.py` with explicit user approval.

## Logging policy

Adapters and use-cases do **not** log exceptions. Infrastructure exceptions
propagate to FastAPI/Starlette's built-in handler (HTTP 500), which logs the
traceback via its own middleware. Logging in two places produces duplicated
entries that confuse on-call engineers.

The only exception is **observability-level logging** unrelated to errors:
counts, durations, debug traces. Those use `logger.info` / `logger.debug`
and have nothing to do with error handling.

## Forbidden patterns

- ❌ `try: ... except Exception: ...` in an adapter, **except** when the
  block immediately re-raises a specific `DomainError`. There is no broad
  catch-all in adapters; the global handler covers that case.
- ❌ `raise HTTPException(...)` anywhere except inside FastAPI exception
  handlers themselves. Use a `DomainError` subclass.
- ❌ `try: ... except: pass`. Silent except is forbidden in all layers.
- ❌ Logging an exception inside the adapter or use-case. Logging is the
  global handler's job.
- ❌ Returning `None` from the adapter when the entity is not found. Either
  return `Optional[T]` with explicit semantics for the use-case to check, or
  raise `NotFoundDomainError`. Avoid implicit `None` returns that mean
  "missing" — they produce `AttributeError` upstream.
- ❌ Catching `BaseException`. Use `Exception`.
- ❌ A new `DomainError` subclass added inside a feature folder. All
  subclasses live in `app/domain/errors.py` (STABLE) and need explicit
  approval.
- ❌ Using `UnknownDomainError` to wrap infrastructure exceptions that have
  no domain meaning ("the DB is down"). `UnknownDomainError` exists for the
  rare case where an adapter truly cannot classify a failure. It must not be
  used as a catch-all wrapper that swallows infrastructure noise.

## Common mistakes

- ❌ Catching `IntegrityError` for `email_exists`-style queries. A read-only
  query cannot violate constraints; there is nothing to catch.
- ❌ Wrapping every `session.execute` in `try/except`. The session does not
  fail in business-meaningful ways during reads.
- ❌ Forgetting `from exc` on `raise DomainError(...) from exc`. Without it,
  the original `IntegrityError` stack trace is lost.
- ❌ Catching `IntegrityError` so widely that it covers both unique
  violations and FK violations. Inspect `exc.orig.sqlstate` (PostgreSQL):
  `23505` is unique, `23503` is foreign key. Different domain meanings.
- ❌ Adding business validation in the adapter. Business validation belongs
  in the use-case. The adapter is mechanical.
- ❌ Adapter that catches `Exception` and "translates" it. There is no
  translation to make for unknown exceptions; let them propagate.
