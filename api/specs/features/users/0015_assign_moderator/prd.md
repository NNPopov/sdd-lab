# PRD — Assign Moderator (slice 0015)

**Parent PRD:** `specs/features/moderation/0012_moderation/prd.md`
**Depends on:** slice 0013 (`moderation_db_foundation`) — `User.is_moderator` and
`User.moderator_granted_by_user_id` columns must exist; slice 0014
(`expose_moderator_flag`) — `is_moderator` must already appear in user response
schemas so the assignment response is consistent.
**Slice:** `0015_assign_moderator`
**Resource:** users
**Endpoint introduced:** `PATCH /users/{username}/assign-moderator`

---

## Problem Statement

The `User.is_moderator` column exists in the database and is visible through API
responses (slice 0014), but there is no endpoint to set it. Superusers who need
to promote a regular user to moderator must currently modify the database row
directly. This bypasses the intended audit trail (`moderator_granted_by_user_id`
records which superuser granted the role), is error-prone, and requires
privileged database access that should not be routine. Without an endpoint,
moderator role management cannot be delegated to other superusers through the
normal API surface.

## Solution

Introduce a `PATCH /users/{username}/assign-moderator` endpoint accessible only
to superusers. The endpoint promotes the target user to moderator by setting
`is_moderator = True` and recording the requesting superuser's `id` in
`moderator_granted_by_user_id`. If the target user does not exist or is already
a moderator, the use-case raises deterministic domain errors that translate to
HTTP 404 and 409 respectively. On success the endpoint returns the full updated
user profile, confirming the new moderator status through the `is_moderator:
true` field.

## User Stories

1. As a superuser, I want to assign the moderator role to a user by their
   username, so that they can review and approve posts.
2. As a superuser, I want the system to record my user ID as the grantor when I
   assign moderator status, so that there is an audit trail of who made the
   assignment.
3. As a superuser, I want the response to include the updated user profile with
   `is_moderator: true`, so that I can confirm the assignment was applied
   without making a separate `GET` request.
4. As a superuser, I want to receive HTTP 404 when I try to assign moderator
   status to a username that does not exist, so that I get clear feedback on
   invalid requests.
5. As a superuser, I want to receive HTTP 409 when I try to assign moderator
   status to a user who is already a moderator, so that duplicate assignments
   are prevented and the intent of the error is unambiguous.
6. As a non-superuser authenticated user, I want to receive HTTP 403 when I call
   the assign-moderator endpoint, so that moderator role management is
   restricted to superusers only.
7. As an unauthenticated client, I want to receive HTTP 401 when I call the
   assign-moderator endpoint without a valid token, so that the endpoint is not
   publicly accessible.
8. As a superuser, I want the assignment to be idempotent in its intent — if a
   user is already a moderator I receive a clear conflict error rather than a
   silent no-op — so that accidental double-assignments are surfaced immediately.

## Implementation Decisions

### New modules (all new files; no existing files modified)

**Domain command — `AssignModeratorCommand`:**

Input to the use-case. Carries three fields: the target `username` (from the
URL path), the `requester_id` (the integer PK of the superuser, for writing into
`moderator_granted_by_user_id`), and `requester_is_superuser: bool` (extracted
from the auth dependency and passed in so the use-case can enforce the privilege
check without depending on the HTTP layer).

**Domain entity — `AssignedUser`:**

Output of the use-case. Represents the user row after the assignment has been
applied. Fields: `id`, `name`, `username`, `email`, `profile_image_url`,
`tier_id: int | None`, `is_moderator: bool`. The entity is always returned with
`is_moderator = True` after a successful assignment.

`AssignedUser` is defined fresh in the `assign_moderator` slice's `domain/`
layer. It must not be imported from the `get_user_by_username` slice — this
would be a cross-slice domain import, which is forbidden. The two entities
happen to have the same shape; they remain separate by design.

**Port — `AssignModeratorPort`:**

`@runtime_checkable` Protocol with two methods:

- `get_by_username(username: str) → AssignedUser | None` — reads the user row
  for existence and moderator-status checks.
- `assign(target_username: str, granted_by_user_id: int) → AssignedUser` — writes
  `is_moderator = True` and `moderator_granted_by_user_id = granted_by_user_id`
  to the target user row and returns the updated entity.

**Use-case — `AssignModeratorUseCase`:**

Sequence:
1. If `command.requester_is_superuser` is `False` → raise `ForbiddenDomainError`.
2. Call `port.get_by_username(command.target_username)`.
3. If result is `None` → raise `NotFoundDomainError("User not found")`.
4. If `result.is_moderator` is `True` → raise
   `DuplicateValueDomainError("User is already a moderator")`.
5. Call `port.assign(command.target_username, command.requester_id)`.
6. Return the resulting `AssignedUser` entity.

The use-case never raises `HTTPException` or imports anything from `adapters/`,
`core/`, or `presentation/`.

**Adapter — `AssignModeratorAdapter(AssignModeratorPort)`:**

Concrete SQLAlchemy 2.0 async implementation of the port. The `assign()` method
executes an `UPDATE` on the `User` row, setting `is_moderator = True` and
`moderator_granted_by_user_id = granted_by_user_id`, then returns a mapped
`AssignedUser`. The adapter catches no infrastructure exceptions — only the
business-meaningful path requires special handling, and there are no unique
constraints on the `is_moderator` column that would produce an `IntegrityError`
in the normal flow. Unknown failures propagate to the global exception handler.

**Presentation schema — `AssignModeratorResponse`:**

Pydantic response model with `model_config = ConfigDict(from_attributes=True)`.
Fields: `id`, `name`, `username`, `email`, `profile_image_url`,
`tier_id: int | None`, `is_moderator: bool`. The shape is deliberately identical
to `GetUserByUsernameResponse`; they are separate classes because cross-slice
presentation imports are forbidden.

**Presentation router:**

`PATCH /users/{username}/assign-moderator`. Depends on `get_current_superuser`
(from `features/users/dependencies.py`). Converts the HTTP request into an
`AssignModeratorCommand` (passing `current_superuser["id"]` as `requester_id`
and `current_superuser["is_superuser"]` as `requester_is_superuser`). Returns
`AssignModeratorResponse` constructed from the use-case entity result.

**DI container:**

A new provider binding in the project's `dependency_injector` container wires
`AssignModeratorUseCase` with `AssignModeratorAdapter` injected as the port.

### API contract

**`PATCH /api/v1/users/{username}/assign-moderator`**

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
| `is_moderator` | `bool` | always `true` after successful assignment |

**Error responses:**

| Status | Condition |
|---|---|
| 401 | Missing or invalid Bearer token |
| 403 | Authenticated user is not a superuser |
| 404 | `username` not found |
| 409 | Target user is already a moderator |

### Superuser privilege check placement

The privilege check (`requester_is_superuser`) is performed inside the use-case
(step 1 of the use-case sequence above), not only at the router level. The
router depends on `get_current_superuser`, which raises `ForbiddenException`
before the use-case is ever called. The in-use-case check is a second-layer
defence: it ensures the invariant holds even if the use-case is called from a
non-HTTP context (e.g. a CLI script or a Celery task) in the future.

### `moderator_granted_by_user_id` stores only the last grantor

If moderator status is revoked (slice 0016) and later re-assigned, the column
is overwritten with the new grantor's ID. Only the most recent grantor is
retained. A full grant history would require a separate audit table; this is
explicitly out of scope for the current system.

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
  return `None`; assert `NotFoundDomainError` is raised; assert `port.assign`
  is never called.
- **Already a moderator** — mock `port.get_by_username()` to return a user with
  `is_moderator=True`; assert `DuplicateValueDomainError` is raised.
- **Happy path** — mock both port methods to succeed; assert the use-case
  returns the `AssignedUser` entity from `port.assign()` without modification.

Prior art: `tests/features/users/0007_delete_user/` use-case unit test.

### Adapter unit tests

Uses a real async session against the test Postgres database.

- **Happy path** — create a user row with `is_moderator=False`, call
  `adapter.assign(username, grantor_id)`, assert the returned entity has
  `is_moderator=True`, fetch the row directly and assert both `is_moderator`
  and `moderator_granted_by_user_id` are set correctly.
- **`get_by_username` — user not found** — call with a non-existent username,
  assert `None` is returned.
- **`get_by_username` — user found** — create a user, call `get_by_username`,
  assert the returned entity fields match the row.

Prior art: `tests/features/users/0001_create_user/` adapter unit test.

### Endpoint integration tests

`httpx.AsyncClient` against the running app with test Postgres.

- **401** — call without Authorization header; assert HTTP 401.
- **403** — authenticate as a non-superuser; assert HTTP 403.
- **404** — authenticate as a superuser, call with a username that does not
  exist; assert HTTP 404.
- **409** — authenticate as a superuser, create a user, assign moderator,
  call assign-moderator again on the same user; assert HTTP 409.
- **200 happy path** — authenticate as a superuser, create a non-moderator
  user, call `PATCH /users/{username}/assign-moderator`, assert HTTP 200,
  assert `is_moderator: true` in response body, assert other fields match the
  created user.

Prior art: `tests/features/users/0007_delete_user/presentation/`.

### Outside-in test (acceptance gate)

One end-to-end test covering the primary happy path with no mocks:

1. Create a regular user (non-moderator).
2. Create a superuser account (or use an existing fixture).
3. Authenticate as the superuser.
4. Call `PATCH /users/{username}/assign-moderator` — assert HTTP 200 and
   `is_moderator: true` in the response.
5. Call `GET /users/user/{username}` (unauthenticated) — assert `is_moderator:
   true` to confirm the assignment is persisted and visible through the read path.

The slice is not done until this test is green.

**Opt-outs:** none — all four test levels apply.

## Out of Scope

- Revoking moderator status — that is slice 0016 (`revoke_moderator`).
- A `get_current_moderator` auth dependency — introduced in slices 0017 and 0019.
- Exposing `moderator_granted_by_user_id` in any response schema.
- A full moderator assignment history log — the column stores only the last
  grantor; a dedicated audit table is out of scope.
- Moderator self-assignment restrictions — the parent PRD does not forbid a
  superuser from granting themselves moderator rights; this slice does not add
  such a restriction.
- Email or in-app notifications on moderator assignment.
- List-moderators endpoint.
- Admin UI (CRUDAdmin) wiring for the new field.

## Further Notes

- The outside-in test for slice 0014 (`expose_moderator_flag`) must remain
  green throughout. That test manually sets `is_moderator=True` in the DB to
  simulate what this slice does; once 0015 is implemented, the fixture approach
  used in that test could optionally be replaced with the real endpoint, but
  updating it is not required.
- A superuser who is not themselves marked `is_moderator` can still assign
  moderator rights. The two flags are independent. The `get_current_superuser`
  dependency only checks `is_superuser`.
- The adapter's `assign()` method performs an `UPDATE` that always sets
  `moderator_granted_by_user_id` to the current requester's ID, even if the
  target user had a previous grantor recorded. This overwrites the prior value.
  This is the intended behaviour per the parent PRD's "stores only the last
  grantor" note.
