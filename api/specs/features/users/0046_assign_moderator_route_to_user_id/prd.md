# PRD — Migrate `assign_moderator` Route from `{username}` to `{user_id}` (slice 0046)

**Slice:** `0046_assign_moderator_route_to_user_id`
**Resource:** users
**Depends on:** slice 0015 (`assign_moderator`) must be complete.
**Part of:** `{username}` → `{user_id}` migration (slices 0041–0050, 0042).

---

## Problem Statement

`PATCH /user/{username}/assign-moderator` identifies the target user by a mutable
username string. The use case and adapter also locate and update the user by
username internally. If the target renames themselves after the superuser copies
their URL, the operation would hit the wrong user (or return 404). A permanent
identifier is essential for a privileged operation like granting moderator status.

## Solution

Change the route to `PATCH /user/{user_id}/assign-moderator`. The command field
`target_username: str` becomes `target_user_id: int`. Port methods are renamed
from `get_by_username` / `assign(target_username, ...)` to `get_by_id` /
`assign(target_user_id, ...)`. The adapter looks up and updates by `User.id`.
The response body is unchanged.

## User Stories

1. As a superuser, I want to assign the moderator role to a user by their integer
   ID (`PATCH /user/{user_id}/assign-moderator`), so that the assignment targets
   an immutable identifier and cannot be misdirected by a username rename.
2. As a superuser, I want HTTP 404 when calling with a non-existent `user_id`,
   so that invalid targets are clearly rejected.
3. As a superuser, I want HTTP 409 when the target user is already a moderator,
   so that duplicate assignments are prevented (existing behaviour, unchanged).
4. As a non-superuser, I want HTTP 403, so that moderator assignment remains
   superuser-only.
5. As an unauthenticated client, I want HTTP 401.
6. As a superuser, I want the response to return the updated user profile with
   `is_moderator: true`, so that I can confirm the assignment without a separate
   GET (response body unchanged).
7. As an API client, I want HTTP 422 for a non-integer `user_id`.

## Implementation Decisions

### Domain command

`AssignModeratorCommand.target_username: str` → `target_user_id: int`.
`requester_id: int` and `requester_is_superuser: bool` are unchanged.

### Port

`AssignModeratorPort` method names updated:
- `get_by_username(username: str)` → `get_by_id(user_id: int)`
- `assign(target_username: str, granted_by_user_id: int)` →
  `assign(target_user_id: int, granted_by_user_id: int)`

### Use case

- `self._port.get_by_id(command.target_user_id)` replaces `get_by_username`.
- `self._port.assign(command.target_user_id, command.requester_id)` replaces
  the username-based call.
- Superuser check and already-moderator check logic are unchanged.

### Adapter

`AssignModeratorAdapter.get_by_id(user_id: int)` replaces `get_by_username`.
`assign(target_user_id: int, ...)` executes `UPDATE ... WHERE User.id == target_user_id`.

### Presentation router

Route: `PATCH /user/{username}/assign-moderator` →
`PATCH /user/{user_id}/assign-moderator`.
Path param type: `str` → `int`.
Command uses `target_user_id=user_id`.

### API contract

| Concern | Value |
|---|---|
| Method | `PATCH` |
| Old path | `/user/{username}/assign-moderator` |
| New path | `/user/{user_id}/assign-moderator` |
| Path param | `user_id: int` |
| Auth | Superuser JWT required |
| Response body | unchanged (`id`, `name`, `username`, `email`, `profile_image_url`, `tier_id`, `is_moderator: true`) |

**Error responses:** 401, 403, 404, 409, 422.

## Testing Decisions

### Use-case unit test

Mock port. Cases: happy path, not found → 404, already moderator → 409,
non-superuser → 403. Commands carry integer `target_user_id`.

Prior art: `tests/features/users/0015_assign_moderator/` use-case unit test.

### Adapter unit test

Verify `get_by_id` returns entity by integer PK. Verify `assign` sets
`is_moderator=True` and records `moderator_granted_by_user_id`.

### Endpoint integration test

200 happy path, 401, 403, 404, 409, 422.

### Outside-in test

1. Create a non-moderator user; capture `id`.
2. As superuser: call `PATCH /user/{id}/assign-moderator`; assert 200 and
   `is_moderator: true`.
3. Call again; assert 409.

**Opt-outs:** none.

## Out of Scope

- Revoke moderator — slice 0047.
- Other routes in the migration.

## Further Notes

- The outside-in test for slice 0015 (`assign_moderator`) must have its URL
  updated once this slice lands.
