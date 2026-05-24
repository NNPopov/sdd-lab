# PRD — Migrate `delete_user` Route from `{username}` to `{user_id}` (slice 0044)

**Slice:** `0044_delete_user_route_to_user_id`
**Resource:** users
**Depends on:** slice 0007 (`delete_user`) must be complete.
**Part of:** `{username}` → `{user_id}` migration (slices 0041–0050, 0042).

---

## Problem Statement

`DELETE /user/{username}` uses a mutable string as the target identifier. If a
user renames themselves, any client holding the old URL cannot safely retry the
delete. The ownership check inside the use case also compares username strings,
which is inconsistent with an integer-ID-based API surface.

## Solution

Change the route to `DELETE /user/{user_id}`. The command fields
`target_username` and `requester_username` become integer IDs. The port and
adapter look up the user by `User.id`. The ownership check compares integer
IDs. The `soft_delete` operation targets the integer primary key. The response
body is unchanged.

## User Stories

1. As an authenticated user, I want to delete my own account by my integer ID
   (`DELETE /user/{user_id}`), so that the URL is stable even after a username
   rename.
2. As an authenticated user, I want to receive HTTP 403 when I try to delete
   another user's account via a mismatched `user_id`, so that the ownership
   check works by immutable ID.
3. As an authenticated user, I want to receive HTTP 404 when calling
   `DELETE /user/{user_id}` with a non-existent ID, so that invalid targets are
   clearly rejected.
4. As an authenticated user, I want my JWT to be blacklisted after a successful
   delete, so that my session is invalidated immediately (existing behaviour,
   unchanged).
5. As an API client, I want HTTP 422 for a non-integer `user_id`, so that
   type errors surface immediately.

## Implementation Decisions

### Domain command

`DeleteUserCommand`:
- `target_username: str` → `target_user_id: int`
- `requester_username: str` → `requester_user_id: int`

### Shared ownership policy

`check_owner` in `users/_shared/policies.py` must accept integers (shared with
slice 0043). If 0043 and 0044 land together, the policy file is updated once.

### Port

`DeleteUserPort.get_by_username(username: str)` → `get_by_id(user_id: int)`.
`soft_delete` parameter changes from `target_username: str` to
`target_user_id: int`.

### Use case

- `self._port.get_by_id(command.target_user_id)` replaces `get_by_username`.
- `check_owner(command.requester_user_id, target.id)` replaces username comparison.
- `self._port.soft_delete(command.target_user_id)` replaces username-based call.

### Adapter

`get_by_id(user_id: int)` replaces `get_by_username`. `soft_delete` executes
`UPDATE ... WHERE User.id == target_user_id`.

### Presentation router

Route: `DELETE /user/{username}` → `DELETE /user/{user_id}`.
Path param type: `str` → `int`.
Command uses `target_user_id=user_id` and `requester_user_id=current_user["id"]`.

### API contract

| Concern | Value |
|---|---|
| Method | `DELETE` |
| Old path | `/user/{username}` |
| New path | `/user/{user_id}` |
| Path param | `user_id: int` |
| Auth | Bearer JWT required (own account) |
| Response body | unchanged (`{"message": "User deleted"}`) |

**Error responses:** 401, 403, 404, 422.

## Testing Decisions

### Use-case unit test

Mock port. Cases: happy path (verify soft_delete called with integer ID), not
found → 404, non-owner → 403.

Prior art: `tests/features/users/0007_delete_user/` use-case unit test.

### Adapter unit test

Verify `get_by_id` returns entity by integer PK. Verify `soft_delete` marks
user as deleted without removing the row.

### Endpoint integration test

200 happy path (token blacklisted), 401, 403, 404, 422.

### Outside-in test

1. Create a user; capture `id`.
2. Authenticate; call `DELETE /user/{id}`; assert 200.
3. Call `GET /user/{id}` (via slice 0041); assert 404 (soft-deleted).

**Opt-outs:** none.

## Out of Scope

- Hard delete (`DELETE /db_user/{user_id}`) — slice 0045.
- Other routes in the migration.

## Further Notes

- Token blacklisting after delete is existing behaviour and is unchanged.
- `check_owner` migration must be coordinated with slice 0043 if both land
  in the same PR.
