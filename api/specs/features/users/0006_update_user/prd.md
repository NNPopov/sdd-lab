# PRD — 0006 update_user

## Problem Statement

The existing `PATCH /user/{username}` endpoint is implemented as a free async function that directly injects a database session and a FastCRUD repository instance. This bypasses the port/adapter boundary, mixes authentication and authorization logic into the business function, and cannot be tested in isolation. The slice does not conform to the Vertical Slice + Hexagonal architecture that every other user slice follows, making it inconsistent and harder to reason about.

## Solution

Refactor the `update_user` operation into a proper vertical slice under `features/users/update_user/`, following the exact same structure as `create_user`. The slice introduces a use-case class, a port protocol, a data adapter, and presentation schemas. A new shared ownership-policy helper (`_shared/policies.py`) centralises the "requester must be resource owner" rule for reuse by future slices.

## User Stories

1. As an authenticated user, I want to update my own profile fields (name, username, email, profile image URL), so that my account information stays current.
2. As an authenticated user, I want to receive a clear confirmation message when my profile is updated successfully, so that I know the operation completed.
3. As an authenticated user, I want to be prevented from updating another user's profile, so that my account data is protected.
4. As an authenticated user, I want to receive a 403 Forbidden response when I attempt to update a profile I do not own, so that the API communicates the authorization failure clearly.
5. As an authenticated user, I want to receive a 404 Not Found response when I attempt to update a username that does not exist, so that I know the target user is absent.
6. As an authenticated user, I want to be told when my requested new username is already taken, so that I can choose a different one.
7. As an authenticated user, I want to be told when my requested new email is already registered, so that I can use a different address.
8. As an authenticated user, I want to send only the fields I wish to change (partial update), so that I do not have to repeat unchanged values.
9. As a developer, I want the ownership check extracted into a shared policy helper, so that future slices (delete, posts) can enforce the same rule without duplicating code.
10. As a developer, I want the use-case class to be testable with a mock port, so that I can verify business rules without a real database.
11. As a developer, I want the adapter to be testable with a mock async session, so that I can verify that `IntegrityError` is translated to `DuplicateValueDomainError`.
12. As a developer, I want the endpoint wired through the DI container, so that the use case receives its adapter without manual construction at call time.
13. As a developer, I want the old free-function implementation deleted once the new slice is in place, so that there is only one code path for user updates.

## Implementation Decisions

### Modules to build

- **`_shared/policies.py`** — `check_owner(requester_username, owner_username) -> None`. Raises `ForbiddenDomainError` if they differ. Pure Python; no DB. Shared across all user slices that need ownership enforcement.
- **`update_user/domain/commands.py`** — `UpdateUserCommand` carrying `target_username`, `requester_username`, and all optional update fields (`name`, `username`, `email`, `profile_image_url`).
- **`update_user/domain/entities.py`** — `UpdatedUserResult(message: str = "User updated")`. Minimal confirmation entity; no user fields returned (matches current API contract).
- **`update_user/domain/ports/update_user_port.py`** — `@runtime_checkable UpdateUserPort(Protocol)` with four methods: `get_by_username`, `email_exists`, `username_exists`, `update`.
- **`update_user/domain/use_case.py`** — `UpdateUserUseCase.__call__(command) -> UpdatedUserResult`. Calls `check_owner`, performs duplicate checks, delegates write to port.
- **`update_user/data/adapter.py`** — `UpdateUserAdapter(UpdateUserPort)`. Uses `async_sessionmaker`. Catches `IntegrityError` from `update` and re-raises as `DuplicateValueDomainError`; all other exceptions propagate unchanged.
- **`update_user/presentation/schemas.py`** — `UpdateUserRequest` (all fields optional, independent of shared schemas), `UpdateUserResponse`.
- **`update_user/presentation/router.py`** — `PATCH /user/{username}`. Resolves `current_user` via `Depends(get_current_user)`. Builds `UpdateUserCommand`. Returns `UpdateUserResponse`.

### Modules to modify

- **`bootstrap/container.py`** — Add `update_user_adapter` and `update_user_use_case` providers.
- **`features/users/router.py`** — Replace the old `patch_user` function registration with `include_router(update_user_router)`.

### Modules to delete

- **`features/users/use_cases/user_update.py`** — Replaced entirely by the new slice.

### Architecture decisions

- Permission check (`check_owner`) lives in the use case, not the router. The use case receives `requester_username` via the command.
- The adapter does **not** wrap operations in a blanket `try/except Exception`. Only `IntegrityError` is caught.
- `UpdatedUserResult` returns a message string only; no user fields. This preserves the current response contract.
- `UpdateUserRequest` defines its own field constraints independently; it does not inherit from the old `UserUpdate` schema.
- `_shared/` is scoped to the `users` feature for now. If posts or other features need owner checks, `check_owner` moves to `domain/policies.py`.

### API contract

- Method: `PATCH`
- Path: `/api/v1/user/{username}`
- Auth: Bearer token (existing `get_current_user` dependency)
- Request body: JSON object, all fields optional — `name`, `username`, `email`, `profile_image_url`
- Success: `200 OK` — `{"message": "User updated"}`
- Errors: `401` (unauthenticated), `403` (not owner), `404` (user not found), `409` (duplicate email or username)

## Testing Decisions

Good tests verify external behaviour through the public interface, not internal method calls. They use real types (commands, entities, domain errors) and assert on what the caller observes — not on how the implementation achieves it.

### Use-case unit tests (`update_user` use case)

Mock the port. Assert that:
- Ownership mismatch raises `ForbiddenDomainError`.
- Missing target user raises `NotFoundDomainError`.
- Duplicate email raises `DuplicateValueDomainError`.
- Duplicate username raises `DuplicateValueDomainError`.
- A valid command returns `UpdatedUserResult` with the confirmation message.

Prior art: `tests/` unit tests for `CreateUserUseCase`.

### Adapter unit tests (`UpdateUserAdapter`)

Mock the async session. Assert that:
- `IntegrityError` from `session.commit()` is re-raised as `DuplicateValueDomainError`.
- Any other exception from the session propagates unchanged.

Prior art: existing adapter tests in the project.

### Endpoint integration tests

Use `httpx.AsyncClient` against the running app with the test PostgreSQL database. Assert:
- `PATCH /api/v1/user/{username}` with a valid token and valid body → `200 {"message": "User updated"}`.
- Wrong owner token → `403`.
- Non-existent username → `404`.
- Duplicate email → `409`.
- Duplicate username → `409`.
- Unauthenticated request → `401`.

Prior art: `create_user` endpoint integration tests.

### Policy unit tests (`check_owner`)

Pure function — no mocking needed. Assert that matching usernames return `None` and mismatched usernames raise `ForbiddenDomainError`.

## Out of Scope

- Password update — separate use case with its own security concerns.
- Superuser ability to update any user's profile — separate privileged slice.
- Returning the updated user record in the response body — current contract returns only a confirmation message.
- Moving `check_owner` to `domain/policies.py` for cross-feature use — deferred until a second feature needs it.
- Soft-delete or restore logic.

## Further Notes

The `UserUpdate` schema in `features/users/schemas.py` may become unused once `user_update.py` is deleted. Review whether any other use case still references it; if not, remove it as part of this slice to avoid dead code.
