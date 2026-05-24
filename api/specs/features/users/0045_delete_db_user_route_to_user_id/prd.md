# PRD — Migrate `delete_db_user` Route from `{username}` to `{user_id}` (slice 0045)

**Slice:** `0045_delete_db_user_route_to_user_id`
**Resource:** users
**Depends on:** slice 0008 (`delete_db_user`) must be complete.
**Part of:** `{username}` → `{user_id}` migration (slices 0041–0050, 0042).

---

## Problem Statement

`DELETE /db_user/{username}` hard-deletes a user row by username string. As with
the soft-delete route, the username identifier is mutable and creates the same
fragility. For a destructive, superuser-only operation it is especially important
that the target identifier is immutable and unambiguous.

## Solution

Change the route to `DELETE /db_user/{user_id}`. The command field
`target_username: str` becomes `target_user_id: int`. The adapter deletes the
row by primary key. No ownership check is involved (superuser-only endpoint).
The response body is unchanged.

## User Stories

1. As a superuser, I want to hard-delete a user by their integer ID
   (`DELETE /db_user/{user_id}`), so that the deletion target is identified by
   an immutable primary key rather than a mutable username.
2. As a superuser, I want to receive HTTP 404 when calling
   `DELETE /db_user/{user_id}` with a non-existent ID, so that accidental
   deletions against unknown IDs are rejected early.
3. As a non-superuser authenticated user, I want to receive HTTP 403 when
   calling `DELETE /db_user/{user_id}`, so that hard-delete remains
   superuser-only.
4. As an unauthenticated client, I want to receive HTTP 401 for this endpoint,
   so that it is not publicly accessible.
5. As an API client, I want HTTP 422 for a non-integer `user_id`.

## Implementation Decisions

### Domain command

`DeleteDbUserCommand.target_username: str` → `target_user_id: int`.

### Port

`DeleteDbUserPort` method `get_by_username(username: str)` →
`get_by_id(user_id: int)`. Hard-delete method parameter changes from
`target_username: str` to `target_user_id: int`.

### Use case

- Lookup: `self._port.get_by_id(command.target_user_id)`.
- Hard delete: call with `command.target_user_id`.
- `NotFoundDomainError` raised when entity is absent (unchanged).

### Adapter

`get_by_id(user_id: int)` replaces `get_by_username`. Hard-delete executes
`DELETE FROM user WHERE user.id == target_user_id`.

### Presentation router

Route: `DELETE /db_user/{username}` → `DELETE /db_user/{user_id}`.
Path param type: `str` → `int`.
Command: `target_user_id=user_id`.

### API contract

| Concern | Value |
|---|---|
| Method | `DELETE` |
| Old path | `/db_user/{username}` |
| New path | `/db_user/{user_id}` |
| Path param | `user_id: int` |
| Auth | Superuser JWT required |
| Response body | unchanged |

**Error responses:** 401, 403, 404, 422.

## Testing Decisions

### Use-case unit test

Mock port. Cases: happy path, not found → 404.

Prior art: `tests/features/users/0008_delete_db_user/` use-case unit test.

### Adapter unit test

Verify hard-delete removes the row; verify `get_by_id` returns `None` for
unknown ID.

### Endpoint integration test

200 happy path (as superuser), 401, 403, 404, 422.

### Outside-in test

1. Create a user; capture `id`.
2. As superuser: call `DELETE /db_user/{id}`; assert 200.
3. Call `GET /user/{id}`; assert 404 (row is gone).

**Opt-outs:** none.

## Out of Scope

- Soft delete — slice 0044.
- Other routes in the migration.
