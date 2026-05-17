# PRD — 0008 delete_db_user

## Problem Statement

The existing hard-delete operation for a user account is implemented as a flat
async function that mixes database access and FastAPI dependency injection in a
single file. It does not follow the vertical-slice + hexagonal architecture that
all other user operations in the codebase use. This makes the operation harder
to test in isolation, inconsistent with the surrounding codebase, and impossible
to wire through the DI container.

Additionally, the current implementation accepts a JWT token parameter that is
never used, and a `Request` parameter that is also unused — both are dead code
left over from earlier iterations.

## Solution

Refactor the hard-delete operation into a proper vertical slice (`delete_db_user`)
following the same structure as `delete_user` (0007): a domain layer with a
command, entities, port protocol, and use-case class; a data layer with a
concrete adapter; and a presentation layer with a router and response schema.

The adapter translates `IntegrityError` (raised when the user has dependent
records such as posts) into `DuplicateValueDomainError`, giving the caller a
409 Conflict instead of an opaque 500.

The existing endpoint path and HTTP verb (`DELETE /db_user/{username}`) are
preserved unchanged. Superuser authorisation remains a router-level dependency.

## User Stories

1. As a superuser, I want to permanently delete a user account by username, so
   that the user row is completely removed from the database.
2. As a superuser, I want to receive a clear confirmation message when a user
   account has been successfully hard-deleted.
3. As a superuser, I want the system to reject my request with a not-found error
   if the username does not exist, so that I get meaningful feedback.
4. As a superuser, I want hard deletion to work on already soft-deleted accounts,
   so that I can permanently erase accounts regardless of their current state.
5. As a superuser, I want to receive a conflict error if the user has dependent
   records (e.g. posts) that prevent deletion, rather than an opaque server
   error, so that I understand why the operation failed.
6. As a non-superuser, I want the system to reject my hard-delete request with
   a forbidden error, so that regular users cannot erase accounts from the
   database.
7. As a developer, I want the hard-delete business logic in a use-case class
   with a single `__call__` method, so that it is consistent with every other
   use-case in the codebase.
8. As a developer, I want the hard-delete use-case to depend only on a port
   protocol and a domain command, so that it can be unit-tested with a mock
   port and no HTTP context.
9. As a developer, I want the old flat async function removed once the slice is
   live, so that there is no dead code with a duplicate implementation.
10. As a developer, I want the `DELETE /db_user/{username}` endpoint to return
    HTTP 200 with `{"message": "User deleted from the database"}` on success,
    preserving the existing API contract.
11. As a developer, I want the adapter to catch `IntegrityError` and translate
    it to `DuplicateValueDomainError`, and to propagate all other infrastructure
    exceptions unchanged to the global handler.

## Implementation Decisions

### Modules to build

**`DeleteDbUserPort` (new, slice domain layer)**
- `@runtime_checkable` Protocol scoped to the `delete_db_user` slice.
- Two methods: `get_by_username(username) -> DbDeleteUserTarget | None` and
  `db_delete(username) -> None`.
- `get_by_username` does not filter by `is_deleted` — hard delete must work on
  both active and soft-deleted accounts.

**`DeleteDbUserUseCase` (new, slice domain layer)**
- Class with `__init__(port)` and `async __call__(command)`.
- Sequence: fetch user → raise `NotFoundDomainError` if missing → call
  `port.db_delete`.
- No ownership check — superuser authorisation is enforced at the router level.
- Raises only `DomainError` subclasses; has no knowledge of JWT or HTTP.

**`DeleteDbUserAdapter` (new, slice data layer)**
- Implements `DeleteDbUserPort` with explicit inheritance.
- `get_by_username`: SELECT from the user table WHERE username matches, with no
  `is_deleted` filter. Returns `DbDeleteUserTarget` or `None`.
- `db_delete`: issues a raw SQLAlchemy DELETE statement. Catches `IntegrityError`
  and raises `DuplicateValueDomainError("User has dependent records")`. All
  other exceptions propagate unchanged to the global handler.

**`delete_db_user` presentation layer (new)**
- Router registers `DELETE /db_user/{username}` with
  `dependencies=[Depends(get_current_superuser)]`.
- Converts the path param to `DeleteDbUserCommand(target_username=username)`.
- Awaits the use-case.
- Returns `DeleteDbUserResponse(message="User deleted from the database")`.
- No `token` or `Request` parameters — neither is needed.

**Container (modified)**
- Registers `delete_db_user_adapter` and `delete_db_user_use_case` as
  `Factory` providers.

**`users/router.py` (modified)**
- Replaces the inline `router.delete("/db_user/{username}")(erase_db_user)`
  wiring with `router.include_router(delete_db_user_router)`.

**`use_cases/user_db_delete.py` (deleted)**
- Dead code once the slice is live.

### Domain entities

- `DbDeleteUserTarget(username: str)` — minimal existence check result; no
  data beyond username is needed because there is no ownership check.
- `DeleteDbUserResult(message: str = "User deleted from the database")` —
  use-case return value.
- `DeleteDbUserCommand(target_username: str)` — input to the use-case; no
  requester field because auth is a router-level concern.

### Authorisation

Superuser check is enforced entirely through `get_current_superuser` as a
router-level `dependencies=[...]` parameter. The use-case receives no
requester information and performs no auth checks.

### Hard-delete mechanics

Issues a direct `DELETE FROM user WHERE username = :username` via raw
SQLAlchemy. `IntegrityError` (FK violation from dependent posts or other
records) is caught by the adapter and translated to `DuplicateValueDomainError`.
No cascade behaviour is introduced in this slice.

### Token handling

No token blacklisting. The deleted account's tokens will eventually expire
naturally. The `oauth2_scheme` dependency and `Request` parameter present in
the old function are removed.

### API contract

**Path params:** `username` (str) — username of the account to hard-delete.

**Request body:** none.

**Response body** (`DeleteDbUserResponse`):

| Field | Type | Notes |
|---|---|---|
| `message` | `str` | Always `"User deleted from the database"` on success |

**Status codes:**

- `200 OK` — user row permanently deleted.
- `401 Unauthorized` — token missing or invalid.
- `403 Forbidden` — caller is not a superuser.
- `404 Not Found` — `NotFoundDomainError`; username does not exist.
- `409 Conflict` — `DuplicateValueDomainError`; user has dependent records.
- `500 Internal Server Error` — any other infrastructure failure.

## Testing Decisions

A good test verifies observable behaviour through the public interface of the
module under test. It does not assert on internal method calls or internal
state beyond what is returned or raised.

**Use-case unit test**
- Instantiate `DeleteDbUserUseCase` with a mock implementing `DeleteDbUserPort`.
- Assert `NotFoundDomainError` is raised when `get_by_username` returns `None`.
- Assert `port.db_delete` is called and `DeleteDbUserResult` is returned when
  the user exists.
- Prior art: `tests/features/users/0007_delete_user/domain/test_use_case.py`.

**Adapter unit test**
- Instantiate `DeleteDbUserAdapter` with a mock async session factory.
- Assert `get_by_username` returns `DbDeleteUserTarget` when a matching row
  exists (regardless of `is_deleted` value).
- Assert `get_by_username` returns `None` when no matching row exists.
- Assert `db_delete` raises `DuplicateValueDomainError` when `IntegrityError`
  is raised by the session.
- Assert that other DB exceptions from `db_delete` propagate unchanged.
- Prior art: `tests/features/users/0007_delete_user/data/test_adapter.py`.

**Endpoint integration test**
- Use `httpx.AsyncClient` against the running app with the test Postgres.
- Happy path: superuser DELETE returns `200 {"message": "User deleted from
  the database"}` and the row is gone.
- Soft-deleted user: superuser DELETE still returns 200 and the row is gone.
- Non-existent username: returns 404.
- User with dependent records: returns 409.
- Regular user (non-superuser): returns 403.
- Missing / invalid token: returns 401.
- Prior art: `tests/features/users/0007_delete_user/presentation/test_router.py`.

**Outside-in test**
- Full HTTP stack: real adapter, test Postgres.
- Happy path: asserts the user row no longer exists in the database after the
  request.
- Conflict case: seeds a user with a post, asserts 409 is returned and the
  user row is unchanged.
- Acceptance gate for the slice.

## Out of Scope

- Soft deletion — that is handled by the `delete_user` (0007) slice.
- Token blacklisting on hard delete — the caller is the superuser; the deleted
  user's tokens will expire naturally.
- Cascade deletion of dependent records (posts, etc.) — this slice only
  surface the conflict; schema-level cascade is a separate infrastructure
  change.
- Refactoring `auth/router.py` or any other slice to use a new pattern
  introduced here.
- Rate limiting — the endpoint is behind superuser auth.

## Further Notes

- `DeleteDbUserAdapter.get_by_username` intentionally omits the `is_deleted`
  filter, unlike `DeleteUserAdapter.get_by_username` in 0007. This is the only
  meaningful behavioural difference between the two adapters.
- The reference slice for structure and test patterns is `delete_user` (0007).
- No new ORM model and no Alembic migration are needed — this slice operates
  on the existing `User` table.
- Once this slice is live, `use_cases/user_db_delete.py` becomes dead code and
  must be deleted.
