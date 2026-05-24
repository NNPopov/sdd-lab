# PRD — Migrate `get_user_tier` Route from `{username}` to `{user_id}` (slice 0048)

**Slice:** `0048_get_user_tier_route_to_user_id`
**Resource:** users
**Depends on:** slice 0005 (`get_user_tier`) must be complete.
**Part of:** `{username}` → `{user_id}` migration (slices 0041–0050, 0042).

---

## Problem Statement

`GET /user/{username}/tier` identifies the user by a mutable username string.
Clients that store this URL (e.g. for polling a user's tier during a billing
flow) will receive 404 after the user renames themselves. The adapter also joins
or filters by `username` instead of the integer primary key.

## Solution

Change the route to `GET /user/{user_id}/tier`. The query field `username: str`
becomes `user_id: int`. The adapter looks up the user by `User.id`. The response
body (tier information) is unchanged.

## User Stories

1. As an API client, I want to retrieve the tier of a user by their integer ID
   (`GET /user/{user_id}/tier`), so that the URL is stable after a username rename.
2. As an API client, I want HTTP 404 when calling with a non-existent `user_id`.
3. As an authenticated user, I want HTTP 404 when the target user has no tier
   assigned (or the existing domain behaviour for that case, unchanged).
4. As an API client, I want HTTP 422 for a non-integer `user_id`.
5. As an API client, I want the response body to remain unchanged.

## Implementation Decisions

### Domain query

`GetUserTierQuery.username: str` → `user_id: int`.

### Port

`GetUserTierPort` lookup method signature changes from `username: str` to
`user_id: int`.

### Use case

`self._port.get_by_id(command.user_id)` replaces `get_by_username`. Logic for
`NotFoundDomainError` is unchanged.

### Adapter

`GetUserTierAdapter` lookup changes from `WHERE User.username == query.username`
to `WHERE User.id == query.user_id`.

### Presentation router

Route: `GET /user/{username}/tier` → `GET /user/{user_id}/tier`.
Path param type: `str` → `int`.
Query: `GetUserTierQuery(user_id=user_id)`.

### API contract

| Concern | Value |
|---|---|
| Method | `GET` |
| Old path | `/user/{username}/tier` |
| New path | `/user/{user_id}/tier` |
| Path param | `user_id: int` |
| Auth | per existing slice (check slice 0005 for auth requirements) |
| Response body | unchanged |

**Error responses:** 404, 422 (plus any auth errors from existing slice).

## Testing Decisions

### Use-case unit test

Mock port. Happy path and not found → 404. Query carries `user_id: int`.

Prior art: `tests/features/users/0005_get_user_tier/` use-case unit test.

### Adapter unit test

Verify lookup by integer PK returns correct tier entity.

### Endpoint integration test

200 happy path, 404, 422.

### Outside-in test

1. Create a user with a tier; capture `id`.
2. Call `GET /user/{id}/tier`; assert 200 and correct tier data.
3. Call with unknown ID; assert 404.

**Opt-outs:** none.

## Out of Scope

- Update user tier route — slice 0050.
- Other routes in the migration.
