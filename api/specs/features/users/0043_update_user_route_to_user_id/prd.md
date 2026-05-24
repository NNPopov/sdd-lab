# PRD — Migrate `update_user` Route from `{username}` to `{user_id}` (slice 0043)

**Slice:** `0043_update_user_route_to_user_id`
**Resource:** users
**Depends on:** slice 0006 (`update_user`) must be complete.
**Part of:** `{username}` → `{user_id}` migration (slices 0041–0050, 0042).

---

## Problem Statement

`PATCH /user/{username}` identifies the update target by a mutable string. A
user who renames themselves immediately invalidates any client URL that pointed
to their profile update endpoint. Additionally, the ownership check inside the
use case compares `requester_username` with the existing user's `username`, which
ties authorization to a value that changes when a user renames themselves.

## Solution

Change the route to `PATCH /user/{user_id}`. The path parameter becomes the
integer primary key. The command fields `target_username` and `requester_username`
become `target_user_id: int` and `requester_user_id: int`. The port and adapter
are updated to look up the user by `User.id`. The ownership check in the use case
compares integer IDs (`requester_user_id == existing.id`). The `_shared/policies.py`
`check_owner` function signature is updated to accept `int` parameters. The
response body is unchanged.

## User Stories

1. As an authenticated user, I want to update my own profile by my integer ID
   (`PATCH /user/{user_id}`), so that the request URL is stable even if I rename
   myself during the session.
2. As an authenticated user, I want to receive HTTP 403 when I try to update
   another user's profile (mismatched `user_id`), so that the ownership check
   enforces my permissions by ID rather than by username.
3. As an authenticated user, I want to receive HTTP 404 when I call
   `PATCH /user/{user_id}` with an ID that does not exist, so that invalid
   targets are clearly rejected.
4. As an authenticated user, I want to receive HTTP 409 when I update my username
   to one already taken, so that uniqueness is still enforced.
5. As an authenticated user, I want to receive HTTP 409 when I update my email
   to one already registered, so that uniqueness is still enforced.
6. As an API client, I want the response body to remain unchanged, so that no
   response parser updates are needed.
7. As an API client, I want HTTP 422 when passing a non-integer `user_id`, so
   that type errors surface immediately.

## Implementation Decisions

### Domain command

`UpdateUserCommand` fields updated:
- `target_username: str` → `target_user_id: int`
- `requester_username: str` → `requester_user_id: int`
- Updatable payload fields (`name`, `username`, `email`, `profile_image_url`)
  are unchanged.

### Shared ownership policy

`check_owner` in `users/_shared/policies.py` signature changes from
`(requester_username: str, owner_username: str)` to
`(requester_user_id: int, owner_user_id: int)`. The equality check is unchanged.
This is a shared file; all callers (update_user, delete_user) must be updated
in the same migration wave.

### Port

`UpdateUserPort` method `get_by_username(username: str)` → `get_by_id(user_id: int)`.
The `update(command: UpdateUserCommand)` and `email_exists` / `username_exists`
method signatures are unchanged (those check for uniqueness by email/username
value, not by the target's ID).

### Use case

`UpdateUserUseCase.__call__` updated:
- Calls `self._port.get_by_id(command.target_user_id)` instead of `get_by_username`.
- Calls `check_owner(command.requester_user_id, existing.id)` instead of username comparison.
- Duplicate-check logic is unchanged.

### Adapter

`UpdateUserAdapter.get_by_id(user_id: int)` replaces `get_by_username(username: str)`.
The SQLAlchemy `WHERE` clause changes to `User.id == user_id`.

### Presentation router

Route: `PATCH /user/{username}` → `PATCH /user/{user_id}`.
Path param type: `str` → `int`.
Command construction:
- `target_user_id=user_id` (from path param)
- `requester_user_id=current_user["id"]` (from auth dict, already available)

### API contract

| Concern | Value |
|---|---|
| Method | `PATCH` |
| Old path | `/user/{username}` |
| New path | `/user/{user_id}` |
| Path param | `user_id: int` |
| Auth | Bearer JWT required (own account) |
| Request body | unchanged |
| Response body | unchanged |

**Error responses:** 401, 403, 404, 409, 422.

## Testing Decisions

### Use-case unit test

Mock port. Cases: happy path, not found → 404, non-owner → 403, duplicate email
→ 409, duplicate username → 409. All commands carry integer `target_user_id` and
`requester_user_id`.

Prior art: `tests/features/users/0006_update_user/` use-case unit test.

### Adapter unit test

Real async session. Verify `get_by_id` returns correct entity by integer PK.
Verify `update` applies field changes.

### Endpoint integration test

200 happy path, 401, 403 (wrong user_id), 404, 409 duplicate email/username, 422.

### Outside-in test

1. Create a user; capture `id`.
2. Authenticate; call `PATCH /user/{id}` with a new `name`; assert 200 and updated name.
3. Call `PATCH /user/{other_id}` as a different user; assert 403.

**Opt-outs:** none.

## Out of Scope

- Other routes in the migration (slices 0041, 0044–0050, 0042).
- Superuser ability to update any profile — not part of this slice.

## Further Notes

- `current_user["id"]` is already present in the auth dict returned by
  `get_current_user` (`shared_dependencies.py`), so the router needs no auth
  layer changes.
- `check_owner` is in `users/_shared/policies.py` and is also called by
  `delete_user` (slice 0044). Both callers must be migrated together.
