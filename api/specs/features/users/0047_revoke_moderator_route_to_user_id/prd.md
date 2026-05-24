# PRD — Migrate `revoke_moderator` Route from `{username}` to `{user_id}` (slice 0047)

**Slice:** `0047_revoke_moderator_route_to_user_id`
**Resource:** users
**Depends on:** slice 0016 (`revoke_moderator`) must be complete.
**Part of:** `{username}` → `{user_id}` migration (slices 0041–0050, 0042).

---

## Problem Statement

`PATCH /users/{username}/revoke-moderator` uses a mutable username string. A
superuser who copies the URL for a targeted revocation could accidentally
misdirect the operation if the user renames themselves in the interim. The same
inconsistency that motivated the `assign_moderator` migration (slice 0046)
applies here.

## Solution

Change the route to `PATCH /users/{user_id}/revoke-moderator`. The command field
`target_username: str` becomes `target_user_id: int`. Port methods are renamed
to use integer IDs. The adapter looks up and updates by `User.id`. The response
body is unchanged.

## User Stories

1. As a superuser, I want to revoke moderator status from a user by their
   integer ID (`PATCH /users/{user_id}/revoke-moderator`), so that the operation
   targets an immutable identifier.
2. As a superuser, I want HTTP 404 when calling with a non-existent `user_id`.
3. As a superuser, I want HTTP 409 when the target user is not currently a
   moderator, so that invalid revocations are rejected (existing behaviour,
   unchanged).
4. As a non-superuser, I want HTTP 403.
5. As an unauthenticated client, I want HTTP 401.
6. As an API client, I want HTTP 422 for a non-integer `user_id`.

## Implementation Decisions

### Domain command

`RevokeModeratorCommand.target_username: str` → `target_user_id: int`.
`requester_is_superuser: bool` is unchanged.

### Port

`RevokeModeratorPort` method names updated:
- `get_by_username(username: str)` → `get_by_id(user_id: int)`
- `revoke(target_username: str)` → `revoke(target_user_id: int)`

### Use case

- `self._port.get_by_id(command.target_user_id)` replaces `get_by_username`.
- `self._port.revoke(command.target_user_id)`.
- Superuser check and not-a-moderator check logic unchanged.

### Adapter

`get_by_id(user_id: int)` replaces `get_by_username`. `revoke` executes
`UPDATE ... WHERE User.id == target_user_id`.

### Presentation router

Route: `PATCH /users/{username}/revoke-moderator` →
`PATCH /users/{user_id}/revoke-moderator`.
Path param type: `str` → `int`.
Command uses `target_user_id=user_id`.

### API contract

| Concern | Value |
|---|---|
| Method | `PATCH` |
| Old path | `/users/{username}/revoke-moderator` |
| New path | `/users/{user_id}/revoke-moderator` |
| Path param | `user_id: int` |
| Auth | Superuser JWT required |
| Response body | unchanged |

**Error responses:** 401, 403, 404, 409, 422.

## Testing Decisions

### Use-case unit test

Mock port. Cases: happy path, not found → 404, not a moderator → 409,
non-superuser → 403. Commands carry `target_user_id: int`.

Prior art: `tests/features/users/0016_revoke_moderator/` use-case unit test.

### Adapter unit test

Verify `get_by_id` returns entity by integer PK. Verify `revoke` sets
`is_moderator=False`.

### Endpoint integration test

200 happy path, 401, 403, 404, 409, 422.

### Outside-in test

1. Create a moderator user (assign via slice 0046 endpoint); capture `id`.
2. As superuser: call `PATCH /users/{id}/revoke-moderator`; assert 200.
3. Call `GET /user/{id}` (slice 0041); assert `is_moderator: false`.

**Opt-outs:** none.

## Out of Scope

- Assign moderator — slice 0046.
- Other routes in the migration.

## Further Notes

- The outside-in test for slice 0016 must have its URL updated once this slice lands.
