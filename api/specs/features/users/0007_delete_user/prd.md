# PRD — 0007 delete_user

## Problem Statement

The existing soft-delete operation for a user account is implemented as a flat
async function that mixes database access, ownership enforcement, and JWT token
blacklisting in a single file. It does not follow the vertical-slice + hexagonal
architecture that all other user operations in the codebase use. This makes the
operation harder to test in isolation, inconsistent with the surrounding
codebase, and impossible to wire through the DI container.

Additionally, token blacklisting — a cross-cutting auth side-effect required
whenever a session must be terminated — has no injectable abstraction. It is
called as a raw utility function, making it impossible to mock in tests or swap
implementations without modifying call sites.

## Solution

Refactor the delete-user operation into a proper vertical slice (`delete_user`)
following the same structure as `update_user`: a domain layer with a command,
entities, port protocol, and use-case class; a data layer with a concrete
adapter; and a presentation layer with a router and response schema.

Simultaneously, introduce a typed port interface and a concrete service class for
token blacklisting. The service is registered in the DI container and injected
into the delete-user router. The use-case itself remains free of any JWT or
transport concerns.

The existing endpoint path and HTTP verb (`DELETE /user/{username}`) are
preserved unchanged.

## User Stories

1. As an authenticated user, I want to delete my own account by username, so
   that my data is removed from the system.
2. As an authenticated user, I want my access token to be invalidated immediately
   when I delete my account, so that no further authenticated requests can be
   made with that token.
3. As an authenticated user, I want to receive a clear confirmation message when
   my account has been successfully deleted.
4. As an authenticated user, I want the system to reject my delete request with a
   not-found error if the username does not exist, so that I get meaningful
   feedback.
5. As an authenticated user, I want the system to reject my delete request with a
   forbidden error if I attempt to delete a different user's account, so that
   accounts are protected from unauthorized deletion.
6. As a developer, I want the delete-user business logic in a use-case class with
   a single `__call__` method, so that it is consistent with every other
   use-case in the codebase.
7. As a developer, I want the delete-user use-case to depend only on a port
   protocol and a domain command, so that the business logic can be unit-tested
   with a mock port and no HTTP context.
8. As a developer, I want token blacklisting behind a typed port interface, so
   that the dependency is explicitly declared, statically checkable, and
   mockable in tests.
9. As a developer, I want the token-blacklist service registered in the DI
   container, so that it is injected at the router level rather than imported
   as a raw utility.
10. As a developer, I want the old flat async function removed once the slice is
    live, so that there is no dead code with a duplicate implementation.
11. As a developer, I want the delete-user adapter to translate
    `IntegrityError`-class infrastructure exceptions into domain errors where
    meaningful, and propagate all other infrastructure exceptions unchanged to
    the global handler.
12. As a developer, I want the `DELETE /user/{username}` endpoint to return HTTP
    200 with `{"message": "User deleted"}` on success, preserving the existing
    API contract.

## Implementation Decisions

### Modules to build

**`TokenBlacklistPort` (new, infrastructure port layer)**
- A `@runtime_checkable` Protocol with a single async method: `blacklist(token)`.
- Lives in the global ports layer alongside the existing cache and queue ports.
- Stable; changes only if the blacklisting contract changes.

**`TokenBlacklistService` (new, core layer)**
- Concrete implementation of `TokenBlacklistPort`.
- Takes a session factory in `__init__`; opens its own session per call.
- Replicates the logic currently in `security.blacklist_token`: decode JWT,
  extract expiry, write to the token-blacklist table.
- `security.py` is not modified.

**`DeleteUserPort` (new, slice domain layer)**
- `@runtime_checkable` Protocol scoped to the delete_user slice.
- Two methods: `get_by_username(username) -> DeleteUserTarget | None` and
  `soft_delete(username) -> None`.

**`DeleteUserUseCase` (new, slice domain layer)**
- Class with `__init__(port)` and `async __call__(command)`.
- Sequence: fetch user → raise `NotFoundDomainError` if missing → call
  `check_owner` policy → call `port.soft_delete`.
- Raises only `DomainError` subclasses; has no knowledge of JWT or HTTP.

**`DeleteUserAdapter` (new, slice data layer)**
- Implements `DeleteUserPort`.
- `get_by_username`: selects the user row filtering `is_deleted == False`.
- `soft_delete`: issues an UPDATE setting `is_deleted = True` and
  `deleted_at = now(UTC)`.

**`delete_user` presentation layer (new)**
- Router registers `DELETE /user/{username}`.
- Converts HTTP inputs to `DeleteUserCommand(target_username, requester_username)`.
- Awaits the use-case.
- Injects `TokenBlacklistService` (via `TokenBlacklistPort`) and calls
  `await token_blacklist.blacklist(token)` after the use-case succeeds.
- Returns `DeleteUserResponse(message="User deleted")`.

**Container (modified)**
- Registers `token_blacklist_service`, `delete_user_adapter`, and
  `delete_user_use_case` as `Factory` providers.

**`users/router.py` (modified)**
- Replaces the inline `router.delete("/user/{username}")(erase_user)` wiring
  with `router.include_router(delete_user_router)`.

**`use_cases/user_delete.py` (deleted)**
- Dead code once the slice is live.

### Domain entities

- `DeleteUserTarget(username: str)` — minimal fetch result; only username is
  needed for ownership check.
- `DeleteUserResult(message: str = "User deleted")` — use-case return value.
- `DeleteUserCommand(target_username: str, requester_username: str)` — input to
  the use-case.

### Ownership policy

Reuses the existing `check_owner(requester_username, owner_username)` function
from `users/_shared/policies.py`. No change to that file.

### Token blacklisting sequence

1. Use-case completes (user is soft-deleted).
2. Router calls `await token_blacklist.blacklist(access_token)`.
3. If blacklisting fails (e.g. JWT decode error), the exception propagates to
   the global handler. The user is already deleted; this is acceptable.

### Soft-delete mechanics

Sets `is_deleted = True` and `deleted_at = datetime.now(UTC)` on the user row.
No hard delete. Consistent with the existing ORM model.

## Testing Decisions

A good test verifies observable behavior through the public interface of the
module under test. It does not assert on internal method calls or internal state
beyond what is returned or raised.

**Use-case unit test**
- Instantiate `DeleteUserUseCase` with a mock implementing `DeleteUserPort`.
- Assert `NotFoundDomainError` is raised when `get_by_username` returns `None`.
- Assert `ForbiddenDomainError` is raised when requester differs from target.
- Assert `port.soft_delete` is called when ownership passes.
- Prior art: `tests/features/users/update_user/` use-case unit test.

**Adapter unit test**
- Instantiate `DeleteUserAdapter` with a mock async session factory.
- Assert `get_by_username` returns `None` for a missing or soft-deleted user.
- Assert `soft_delete` issues the correct UPDATE (sets `is_deleted`, `deleted_at`).
- Prior art: `tests/features/users/update_user/` adapter unit test.

**`TokenBlacklistService` unit test**
- Instantiate with a mock session factory.
- Assert that a valid JWT results in a write to the token-blacklist table with
  the correct `expires_at`.

**Endpoint integration test**
- Use `httpx.AsyncClient` against the running app with the test Postgres.
- Happy path: authenticated DELETE returns 200 `{"message": "User deleted"}`.
- Not found: returns 404.
- Forbidden (wrong user): returns 403.
- Prior art: `tests/features/users/get_user_by_username/` integration test.

**Outside-in test**
- Single test that exercises the full stack: HTTP request → router → use-case →
  adapter → real Postgres. Asserts the user row has `is_deleted = True` after
  the request and that the token appears in the blacklist table.

## Out of Scope

- Hard (permanent) deletion of the user row — that is handled by the separate
  `db_user` endpoint and is not part of this slice.
- Refresh-token blacklisting on account deletion — the existing `erase_user`
  only blacklisted the access token; this slice preserves that behavior.
- Refactoring `auth/router.py` logout to use `TokenBlacklistService` — that is
  a future improvement once the service exists.
- Modifying `core/security.py` — the existing `blacklist_token` function is left
  in place.
- Moving `ExistingUser` from `update_user` to `users/_shared/` — premature
  abstraction; revisit when a third slice needs the same shape.

## Further Notes

- The `TokenBlacklistPort` + `TokenBlacklistService` pair, once introduced, can
  be reused by the `logout` operation in a future refactor of `auth/router.py`.
- The `check_owner` policy in `users/_shared/policies.py` is already the correct
  shared home for ownership enforcement; no change needed there.
- The container entry for `token_blacklist_service` takes `session_factory` as
  its only constructor argument, identical to every existing adapter registration.
