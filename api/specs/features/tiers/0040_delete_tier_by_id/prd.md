# PRD — 0040: Delete Tier by ID (`DELETE /tier/{id}`)

## Problem Statement

The existing `DELETE /tier/{name}` endpoint identifies the tier to delete by its
mutable `name`. If the tier was renamed between the client fetching the name and
issuing the delete, the wrong tier could be targeted — or the request could
return 404 unexpectedly. The integer primary key `id` is immutable and uniquely
identifies a tier for its entire lifetime.

## Solution

Change the endpoint path from `DELETE /tier/{name}` to `DELETE /tier/{id}` where
`{id}` is the integer primary key. The response body is unchanged.

## User Stories

1. As a superuser, I want to delete a tier by its integer id, so that I always
   target the correct tier regardless of any renames that occurred since I last
   fetched it.
2. As a superuser, I want the endpoint to return 404 when no tier with the given
   id exists, so that I know the tier is already gone or never existed.
3. As a superuser, I want the endpoint to return 200 with a confirmation message
   on success, so that I know the deletion was applied.
4. As an API client, I want the endpoint to return 401 for unauthenticated
   requests and 403 for non-superuser requests, so that tier deletion is
   properly protected.
5. As a developer, I want FastAPI to return 422 automatically when `{id}` is not
   an integer, so that invalid path values never reach the use case.

## Implementation Decisions

- Path changes from `/tier/{name}` to `/tier/{id}`.
- `DeleteTierCommand` changes from `name: str` to `id: int`.
- Port methods change: `get(name: str)` → `get(tier_id: int)`,
  `delete(name: str)` → `delete(tier_id: int)`.
- Adapter looks up and deletes rows by `Tier.id` instead of `Tier.name`.
- Response shape (`{"message": "Tier deleted"}`) is unchanged.
- Authorization (superuser required) is unchanged.

## Testing Decisions

- Good tests verify observable behavior: status codes, response body, and DB
  state — not internal query construction.
- **Use-case unit test**: mock the port; use `DeleteTierCommand(id=1)`;
  verify `NotFoundDomainError` when `port.get` returns `None`; verify
  `port.delete` is called with `1` on the happy path.
- **Adapter unit test** (real Postgres): `_seed_tier` is updated to return the
  inserted `id` via `RETURNING id`. Tests call `adapter.get(tier_id)` and
  `adapter.delete(tier_id)` using the seeded id.
- **Router integration test**: seed a tier, capture its `id` via
  `INSERT ... RETURNING id`, call `DELETE /tier/{id}`, assert 200 and that the
  row is gone. Also assert 404 for a nonexistent id.
- **Outside-in test**: same pattern — seed via `RETURNING id`, call endpoint,
  assert response and DB state.
- Prior art: `0037_delete_tier` existing tests — same session-factory override
  and DI-container patterns.

## Out of Scope

- Soft-deleting tiers.
- Cascading deletes to users assigned to the deleted tier.
- Changing the response body.
- Allowing non-superusers to delete tiers.

## Further Notes

This is a modification of the already-green `delete_tier` slice (0037). Per
project workflow: tests are updated first (going RED), then the implementation
is changed until tests go GREEN again.
