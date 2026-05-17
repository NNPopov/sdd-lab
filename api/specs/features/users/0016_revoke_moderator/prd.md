# PRD — Revoke Moderator (slice 0016)

**Parent PRD:** `specs/features/moderation/0012_moderation/prd.md`
**Depends on:** slice 0013 (`moderation_db_foundation`) — `User.is_moderator` and
`User.moderator_granted_by_user_id` columns must exist; slice 0014
(`expose_moderator_flag`) — `is_moderator` must already appear in user response
schemas so the revocation response is consistent; slice 0015 (`assign_moderator`) —
moderator assignment must exist before revocation is meaningful.
**Slice:** `0016_revoke_moderator`
**Resource:** users
**Endpoint introduced:** `PATCH /users/{username}/revoke-moderator`

---

## Problem Statement

The `assign_moderator` endpoint (slice 0015) allows superusers to grant the
moderator role to users. However, there is no endpoint to revoke that role. A
superuser who needs to demote a moderator — due to a role change, trust issue,
or administrative correction — must currently modify the database row directly.
This bypasses the intended audit trail, is error-prone, and requires privileged
database access that should not be routine. Without a revocation endpoint, the
moderator role assignment is effectively permanent through the API surface.

## Solution

Introduce a `PATCH /users/{username}/revoke-moderator` endpoint accessible only
to superusers. The endpoint demotes the target user from moderator by setting
`is_moderator = False` and clearing `moderator_granted_by_user_id` (set to
`None`). If the target user does not exist or is not currently a moderator, the
use-case raises deterministic domain errors that translate to HTTP 404 and 409
respectively. On success the endpoint returns the full updated user profile with
`is_moderator: false`, confirming the revocation without requiring a separate GET
request.

## User Stories

1. As a superuser, I want to revoke the moderator role from a user by their
   username, so that they can no longer review and approve posts.
2. As a superuser, I want the system to clear the `moderator_granted_by_user_id`
   field when I revoke moderator status, so that the revoked user no longer has
   a recorded grantor.
3. As a superuser, I want the response to include the updated user profile with
   `is_moderator: false`, so that I can confirm the revocation was applied
   without making a separate `GET` request.
4. As a superuser, I want to receive HTTP 404 when I try to revoke moderator
   status from a username that does not exist, so that I get clear feedback on
   invalid requests.
5. As a superuser, I want to receive HTTP 409 when I try to revoke moderator
   status from a user who is not currently a moderator, so that invalid
   revocations are surfaced immediately rather than silently ignored.
6. As a non-superuser authenticated user, I want to receive HTTP 403 when I call
   the revoke-moderator endpoint, so that moderator role management is restricted
   to superusers only.
7. As an unauthenticated client, I want to receive HTTP 401 when I call the
   revoke-moderator endpoint without a valid token, so that the endpoint is not
   publicly accessible.
8. As a superuser, I want the revocation to be idempotent in its intent — if a
   user is not a moderator I receive a clear conflict error rather than a silent
   no-op — so that accidental double-revocations are surfaced immediately.

## Implementation Decisions

### New modules (all new files; no existing files modified)

**Domain command — `RevokeModeratorCommand`:**

Input to the use-case. Carries two fields: the target `username` (from the URL
path) and `requester_is_superuser: bool` (extracted from the auth dependency and
passed in so the use-case can enforce the privilege check without depending on
the HTTP layer). Unlike `AssignModeratorCommand`, no `requester_id` is needed
because the revoke operation clears the grantor field rather than populating it.

**Domain entity — `RevokedUser`:**

Output of the use-case. Represents the user row after revocation has been
applied. Fields: `id`, `name`, `username`, `email`, `profile_image_url`,
`tier_id: int | None`, `is_moderator: bool`. The entity is always returned with
`is_moderator = False` after a successful revocation.

`RevokedUser` is defined fresh in the `revoke_moderator` slice's `domain/`
layer. It must not be imported from the `assign_moderator` slice — cross-slice
domain imports are forbidden. The two entities share the same shape by
coincidence; they remain separate by design.

**Port — `RevokeModeratorPort`:**

`@runtime_checkable` Protocol with two methods:

- `get_by_username(username: str) → RevokedUser | None` — reads the user row
  for existence and moderator-status checks.
- `revoke(target_username: str) → RevokedUser` — writes `is_moderator = False`
  and `moderator_granted_by_user_id = None` to the target user row and returns
  the updated entity.

**Use-case — `RevokeModeratorUseCase`:**

Sequence:
1. If `command.requester_is_superuser` is `False` → raise `ForbiddenDomainError`.
2. Call `port.get_by_username(command.target_username)`.
3. If result is `None` → raise `NotFoundDomainError("User not found")`.
4. If `result.is_moderator` is `False` → raise
   `DuplicateValueDomainError("User is not a moderator")`.
5. Call `port.revoke(command.target_username)`.
6. Return the resulting `RevokedUser` entity.

The use-case never raises `HTTPException` or imports anything from `adapters/`,
`core/`, or `presentation/`.

Note on error type: `DuplicateValueDomainError` is reused for the "not a
moderator" conflict case because it is the only existing `DomainError` subclass
that maps to HTTP 409 in `exception_handlers.py`. The name is semantically
imperfect but the HTTP semantics (409 Conflict) are correct. Introducing a new
subclass (e.g. `InvalidStateDomainError`) would require modifying
`exception_handlers.py`, a STABLE file, which is out of scope for this slice.

**Adapter — `RevokeModeratorAdapter(RevokeModeratorPort)`:**

Concrete SQLAlchemy 2.0 async implementation of the port. The `revoke()` method
executes an `UPDATE` on the `User` row, setting `is_moderator = False` and
`moderator_granted_by_user_id = None`, then returns a mapped `RevokedUser`. The
adapter catches no infrastructure exceptions — there are no unique constraints on
`is_moderator` that would produce an `IntegrityError` in the normal revoke flow.
Unknown failures propagate to the global exception handler.

**Presentation schema — `RevokeModeratorResponse`:**

Pydantic response model with `model_config = ConfigDict(from_attributes=True)`.
Fields: `id`, `name`, `username`, `email`, `profile_image_url`,
`tier_id: int | None`, `is_moderator: bool`. The shape is deliberately identical
to `AssignModeratorResponse`; they are separate classes because cross-slice
presentation imports are forbidden.

**Presentation router:**

`PATCH /users/{username}/revoke-moderator`. Depends on `get_current_superuser`
(from `features/users/dependencies.py`). Converts the HTTP request into a
`RevokeModeratorCommand` (passing `current_superuser["is_superuser"]` as
`requester_is_superuser`). Returns `RevokeModeratorResponse` constructed from
the use-case entity result.

**DI container:**

A new provider binding in the project's `dependency_injector` container wires
`RevokeModeratorUseCase` with `RevokeModeratorAdapter` injected as the port.

### API contract

**`PATCH /api/v1/users/{username}/revoke-moderator`**

| Concern | Value |
|---|---|
| Authentication | Bearer JWT required |
| Authorization | `is_superuser` must be `true` |
| Path param | `username: str` |
| Request body | none |

**Response (HTTP 200):**

| Field | Type | Notes |
|---|---|---|
| `id` | `int` | user primary key |
| `name` | `str` | display name |
| `username` | `str` | unique handle |
| `email` | `str` | |
| `profile_image_url` | `str` | |
| `tier_id` | `int \| null` | |
| `is_moderator` | `bool` | always `false` after successful revocation |

**Error responses:**

| Status | Condition |
|---|---|
| 401 | Missing or invalid Bearer token |
| 403 | Authenticated user is not a superuser |
| 404 | `username` not found |
| 409 | Target user is not currently a moderator |

### Superuser privilege check placement

The privilege check (`requester_is_superuser`) is performed inside the use-case
(step 1 of the use-case sequence above), not only at the router level. The
router depends on `get_current_superuser`, which raises `ForbiddenException`
before the use-case is ever called. The in-use-case check is a second-layer
defence: it ensures the invariant holds even if the use-case is called from a
non-HTTP context (e.g. a CLI script or a Celery task) in the future.

### `moderator_granted_by_user_id` is cleared on revocation

When `revoke()` is called, `moderator_granted_by_user_id` is set to `None`. If
the user is later re-assigned moderator status (via `assign_moderator`), the
column will be written with the new grantor's ID. This is the intended behaviour
per the parent PRD.

### No changes to existing slices

This slice introduces entirely new files. No existing Python files are modified.

## Testing Decisions

Good tests verify observable behaviour through the public interface. They do not
assert internal method invocations unless the call itself is the observable
behaviour.

### Use-case unit tests

Mock the port. Four cases:

- **Superuser check** — pass `requester_is_superuser=False`; assert
  `ForbiddenDomainError` is raised; assert `port.get_by_username` is never
  called.
- **Not found** — pass a superuser command; mock `port.get_by_username()` to
  return `None`; assert `NotFoundDomainError` is raised; assert `port.revoke`
  is never called.
- **Not a moderator** — mock `port.get_by_username()` to return a user with
  `is_moderator=False`; assert `DuplicateValueDomainError` is raised; assert
  `port.revoke` is never called.
- **Happy path** — mock both port methods to succeed; assert the use-case
  returns the `RevokedUser` entity from `port.revoke()` without modification.

Prior art: `tests/features/users/0015_assign_moderator/` use-case unit test
(mirror slice).

### Adapter unit tests

Uses a real async session against the test Postgres database.

- **Happy path** — create a user row with `is_moderator=True` and
  `moderator_granted_by_user_id` set, call `adapter.revoke(username)`, assert
  the returned entity has `is_moderator=False`, fetch the row directly and
  assert both `is_moderator=False` and `moderator_granted_by_user_id=None`.
- **`get_by_username` — user not found** — call with a non-existent username,
  assert `None` is returned.
- **`get_by_username` — user found** — create a user, call `get_by_username`,
  assert the returned entity fields match the row.

Prior art: `tests/features/users/0015_assign_moderator/` adapter unit test.

### Endpoint integration tests

`httpx.AsyncClient` against the running app with test Postgres.

- **401** — call without Authorization header; assert HTTP 401.
- **403** — authenticate as a non-superuser; assert HTTP 403.
- **404** — authenticate as a superuser, call with a username that does not
  exist; assert HTTP 404.
- **409** — authenticate as a superuser, create a non-moderator user, call
  `PATCH /users/{username}/revoke-moderator`; assert HTTP 409.
- **200 happy path** — authenticate as a superuser, create a user, promote them
  to moderator (via the assign-moderator endpoint), call
  `PATCH /users/{username}/revoke-moderator`, assert HTTP 200, assert
  `is_moderator: false` in response body, assert other fields match the created
  user.

Prior art: `tests/features/users/0015_assign_moderator/` endpoint integration
test.

### Outside-in test (acceptance gate)

One end-to-end test covering the primary happy path with no mocks:

1. Create a regular user.
2. Use an existing superuser fixture or create a superuser account.
3. Authenticate as the superuser and call
   `PATCH /users/{username}/assign-moderator` to promote the user.
4. Call `PATCH /users/{username}/revoke-moderator` — assert HTTP 200 and
   `is_moderator: false` in the response.
5. Call `GET /users/user/{username}` (unauthenticated) — assert `is_moderator:
   false` to confirm the revocation is persisted and visible through the read
   path.

The slice is not done until this test is green.

**Opt-outs:** none — all four test levels apply.

## Out of Scope

- Assigning moderator status — that is slice 0015 (`assign_moderator`).
- A full moderator revocation history log — the column stores only the last
  state; a dedicated audit table is out of scope.
- Preventing a superuser from revoking their own moderator status if they are
  also a moderator — the parent PRD does not require this guard.
- Cascading side effects on existing moderation decisions when a moderator is
  revoked (posts they approved remain approved).
- Email or in-app notifications on moderator revocation.
- Admin UI (CRUDAdmin) wiring for the field change.
- A `get_current_moderator` auth dependency — introduced in slices 0017 and
  0019.

## Further Notes

- The outside-in test for slice 0015 (`assign_moderator`) must remain green
  throughout. This slice adds no interaction that affects the assign path.
- A superuser who is also a moderator can have their `is_moderator` flag revoked
  by another superuser. The `is_superuser` flag is not affected. The two flags
  are independent.
- The adapter's `revoke()` method performs an `UPDATE` that always sets
  `moderator_granted_by_user_id` to `None`. The use-case guard (step 4) prevents
  the call when `is_moderator` is already `False`, so the adapter always
  receives a row that is currently `True`.
- Unlike `assign_moderator`, the `revoke()` port method does not need the
  requester's ID as a parameter because revocation clears the grantor field
  rather than populating it.
