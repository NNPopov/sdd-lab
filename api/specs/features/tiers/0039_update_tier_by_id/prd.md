# PRD — 0039: Update Tier by ID (`PATCH /tier/{id}`)

## Problem Statement

The existing `PATCH /tier/{name}` endpoint has two issues. First, it identifies
the tier by its mutable `name` path parameter — a stale URL after a rename leads
to a 404 or, worse, an accidental rename of the wrong tier. Second, the request
body uses the field `new_name` to carry the desired name, which is redundant
phrasing once the path parameter is no longer a name.

## Solution

Change the endpoint path from `PATCH /tier/{name}` to `PATCH /tier/{id}` where
`{id}` is the integer primary key. Rename the request body field from `new_name`
to `name`. The response body is unchanged.

## User Stories

1. As a superuser, I want to rename a tier by its integer id, so that I always
   target the correct tier regardless of any renames that occurred since I last
   fetched it.
2. As a superuser, I want to send the new name as `name` in the request body,
   so that the API contract is clear and consistent with the field name in the
   response.
3. As a superuser, I want the endpoint to return 404 when no tier with the given
   id exists, so that I can distinguish a missing tier from other errors.
4. As a superuser, I want the endpoint to return 409 when the new name is already
   taken by another tier, so that I can handle naming conflicts.
5. As a superuser, I want the endpoint to return 200 with a confirmation message
   on success, so that I know the rename was applied.
6. As an API client, I want the endpoint to return 401 for unauthenticated
   requests and 403 for non-superuser requests, so that tier renaming is
   properly protected.
7. As a developer, I want FastAPI to return 422 when `name` is missing or empty,
   so that invalid requests never reach the use case.

## Implementation Decisions

- Path changes from `/tier/{name}` to `/tier/{id}`.
- `UpdateTierCommand` changes from `(name: str, new_name: str)` to
  `(id: int, name: str)`.
- Port methods change: `get(name: str)` → `get(tier_id: int)`,
  `update(name: str, new_name: str)` → `update(tier_id: int, name: str)`.
- Adapter looks up and updates rows by `Tier.id` instead of `Tier.name`.
- `UpdateTierRequest.new_name` is renamed to `UpdateTierRequest.name`.
- Response shape (`{"message": "Tier updated"}`) is unchanged.
- `updated_at` continues to be set via `func.now()` on every successful rename.
- `DuplicateValueDomainError` is still raised on `IntegrityError` from the DB.
- Authorization (superuser required) is unchanged.

## Testing Decisions

- Good tests verify observable behavior: status codes, response body, and DB
  state — not internal query construction.
- **Use-case unit test**: mock the port; use `UpdateTierCommand(id=1, name="gold")`;
  verify `NotFoundDomainError` when `port.get` returns `None`; verify
  `port.update` is called with `(1, "gold")` on the happy path; verify
  `DuplicateValueDomainError` propagates from `port.update`.
- **Adapter unit test** (real Postgres): `_seed_tier` is updated to return the
  inserted `id` via `RETURNING id`. Tests call `adapter.get(tier_id)` and
  `adapter.update(tier_id, new_name)` using the seeded id.
- **Router integration test**: seed a tier, capture its `id` via
  `INSERT ... RETURNING id`, call `PATCH /tier/{id}` with `{"name": "new_name"}`,
  assert 200 and DB change. Also assert 404 and 409.
- **Outside-in test**: same pattern — seed, capture id via `RETURNING id`, call
  endpoint, assert response and DB state.
- Prior art: `0036_update_tier` existing tests — same session-factory override
  and DI-container patterns.

## Out of Scope

- Changing the response body.
- Allowing non-superusers to rename tiers.
- Renaming the `name` column in the database.

## Further Notes

This is a modification of the already-green `update_tier` slice (0036). Per
project workflow: tests are updated first (going RED), then the implementation
is changed until tests go GREEN again.
