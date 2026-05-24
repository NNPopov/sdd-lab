# PRD — Migrate `update_user_tier` Route from `{username}` to `{user_id}` (slice 0050)

**Slice:** `0050_update_user_tier_route_to_user_id`
**Resource:** users
**Depends on:** tiers feature must be complete; `update_user_tier` aggregator must be in place.
**Part of:** `{username}` → `{user_id}` migration (slices 0041–0050, 0042).

---

## Problem Statement

`PATCH /user/{username}/tier` uses a mutable username string to identify the
user whose tier is being updated. A superuser who stores the URL for a billing
or admin workflow will have it break after the user renames themselves. Like the
rate limits aggregator (slice 0049), this is a free async function registered
directly on the users router, so the fix is entirely within that function.

## Solution

Change the route to `PATCH /user/{user_id}/tier`. The function parameter
`username: str` becomes `user_id: int`. The internal CRUD lookup changes from
`crud_users.get(username=username, ...)` to `crud_users.get(id=user_id, ...)`.
The tier-patch logic and response body are unchanged.

## User Stories

1. As a superuser, I want to update the tier for a user by their integer ID
   (`PATCH /user/{user_id}/tier`), so that the URL is stable after a username
   rename.
2. As a superuser, I want HTTP 404 when calling with a non-existent `user_id`,
   so that invalid targets are clearly rejected.
3. As a superuser, I want HTTP 404 when the requested `tier_id` does not exist,
   so that invalid tier assignments are rejected (existing behaviour, unchanged).
4. As a non-superuser, I want HTTP 403.
5. As an unauthenticated client, I want HTTP 401.
6. As an API client, I want HTTP 422 for a non-integer `user_id`.
7. As an API client, I want the success response to remain unchanged.

## Implementation Decisions

### Free function in `use_cases/user_tier_patch.py`

- Function parameter: `username: str` → `user_id: int`.
- `crud_users.get(db=db, username=username, ...)` →
  `crud_users.get(db=db, id=user_id, ...)`.
- `crud_users.update(db=db, object=..., username=username)` →
  `crud_users.update(db=db, object=..., id=user_id)`.
- Tier lookup and all other logic unchanged.

### Router registration in `users/router.py`

Route string: `"/user/{username}/tier"` → `"/user/{user_id}/tier"`.

### API contract

| Concern | Value |
|---|---|
| Method | `PATCH` |
| Old path | `/user/{username}/tier` |
| New path | `/user/{user_id}/tier` |
| Path param | `user_id: int` |
| Request body | unchanged (`{"tier_id": int}`) |
| Auth | Superuser JWT required |
| Response body | unchanged (`{"message": "User <name> Tier updated"}`) |

**Error responses:** 401, 403, 404 (user or tier not found), 422.

## Testing Decisions

### Unit test

Target the free function with a mocked async session. Verify `crud_users.get`
is called with `id=user_id` and `crud_users.update` uses `id=user_id`.

### Endpoint integration test

200 happy path, 404 unknown user, 404 unknown tier, 401, 403, 422.

Prior art: existing `update_user_tier` integration tests.

### Outside-in test

1. Create a user and two tiers; capture user `id` and tier IDs.
2. As superuser: call `PATCH /user/{id}/tier` with `{"tier_id": <id>}`;
   assert 200 and success message.
3. Call `GET /user/{id}/tier` (slice 0048); assert updated tier.
4. Call with unknown user ID; assert 404.

**Opt-outs:** use-case unit test (no use-case class exists for this endpoint).

## Out of Scope

- `get_user_tier` route — slice 0048.
- `{tier_name}` routes in `rate_limits` feature.
- Other routes in the users migration.

## Further Notes

- Like slice 0049, this is a shallow aggregator function with no hexagonal
  port/adapter structure. The change is a one-line lookup key swap.
- The `crud_users.update` call also needs the filter updated from
  `username=username` to `id=user_id` so the UPDATE WHERE clause is correct.
