# PRD — Migrate `rate_limits` Route from `{username}` to `{user_id}` (slice 0049)

**Slice:** `0049_rate_limits_route_to_user_id`
**Resource:** users
**Depends on:** slice 0005 (`get_user_tier`) and rate_limits feature must be complete.
**Part of:** `{username}` → `{user_id}` migration (slices 0041–0050, 0042).

---

## Problem Statement

`GET /user/{username}/rate_limits` uses a mutable username string to look up the
user, then fetches their tier and rate limit configuration. The endpoint is
registered directly on the users aggregator router as a free async function (not
a hexagonal use-case class), and its internal `crud_users.get(username=username)`
call ties the lookup to a mutable column.

## Solution

Change the route to `GET /user/{user_id}/rate_limits`. The function parameter
`username: str` becomes `user_id: int`. The internal CRUD lookup changes from
`crud_users.get(username=username, ...)` to `crud_users.get(id=user_id, ...)`.
The response body is unchanged.

## User Stories

1. As a superuser, I want to retrieve the rate limits for a user by their
   integer ID (`GET /user/{user_id}/rate_limits`), so that the URL is stable
   after a username rename.
2. As a superuser, I want HTTP 404 when calling with a non-existent `user_id`.
3. As a non-superuser, I want HTTP 403, so that rate limit data remains
   superuser-only.
4. As an unauthenticated client, I want HTTP 401.
5. As an API client, I want HTTP 422 for a non-integer `user_id`.
6. As a superuser, I want the response body (user data plus `tier_rate_limits`
   list) to remain unchanged.

## Implementation Decisions

### Free function in `use_cases/user_rate_limits_get.py`

This endpoint is not a hexagonal slice (no port/use-case class). The change is
entirely within the free async function:

- Function parameter: `username: str` → `user_id: int`.
- `crud_users.get(db=db, username=username, ...)` →
  `crud_users.get(db=db, id=user_id, ...)`.
- All downstream logic (tier lookup, rate limit fetch) is unchanged.

### Router registration in `users/router.py`

Route string: `"/user/{username}/rate_limits"` → `"/user/{user_id}/rate_limits"`.

### API contract

| Concern | Value |
|---|---|
| Method | `GET` |
| Old path | `/user/{username}/rate_limits` |
| New path | `/user/{user_id}/rate_limits` |
| Path param | `user_id: int` |
| Auth | Superuser JWT required |
| Response body | unchanged (user fields + `tier_rate_limits` list) |

**Error responses:** 401, 403, 404, 422.

## Testing Decisions

### Unit test

Because there is no port/use-case class, the unit test targets the function
directly with a mocked async session. Verify `crud_users.get` is called with
`id=user_id` (not `username=username`).

### Endpoint integration test

200 happy path (user with tier and rate limits), 200 with empty rate limits (no
tier), 401, 403, 404, 422.

Prior art: existing `rate_limits` integration tests (check
`tests/features/users/` for the closest coverage).

### Outside-in test

1. Create a user with a tier and rate limit configuration; capture `id`.
2. As superuser: call `GET /user/{id}/rate_limits`; assert 200 and correct
   `tier_rate_limits`.
3. Call with unknown `id`; assert 404.

**Opt-outs:** use-case unit test (no use-case class exists for this endpoint).

## Out of Scope

- `{tier_name}` routes in `rate_limits` feature — separate task, not part of
  this migration.
- Other routes in the users migration.

## Further Notes

- This endpoint is a "shallow" aggregator function registered directly on the
  users router. It intentionally has no port/adapter hexagonal structure.
- The only change is the lookup key: `username` string → `id` integer.
