# PRD — 0038: Get Tier by ID (`GET /tier/{id}`)

## Problem Statement

The existing `GET /tier/{name}` endpoint identifies a tier by its mutable `name`
field. If a tier is renamed, any client that cached the URL breaks immediately.
Tier names change as part of normal administration; the integer primary key `id`
never changes.

## Solution

Change the endpoint path from `GET /tier/{name}` to `GET /tier/{id}` where
`{id}` is the integer primary key. The response body is unchanged: `id`, `name`,
and `created_at` are still returned.

## User Stories

1. As an API client, I want to fetch a tier by its integer id, so that my stored
   URL remains valid even after the tier is renamed.
2. As an API client, I want the endpoint to return 404 when no tier with the
   given id exists, so that I can handle missing tiers correctly.
3. As an API client, I want the response to include `id`, `name`, and
   `created_at`, so that I have full tier information after the lookup.
4. As an API client, I want the endpoint to be publicly accessible without
   authentication, so that unauthenticated requests can resolve tier metadata.
5. As a developer, I want FastAPI to validate that `{id}` is an integer and
   return 422 automatically for non-integer values, so that the use case never
   receives invalid input.

## Implementation Decisions

- Path changes from `/tier/{name}` to `/tier/{id}`.
- `GetTierQuery` command changes from `name: str` to `id: int`.
- The adapter queries by `Tier.id` instead of `Tier.name`.
- `GetTierPort` continues to accept `GetTierQuery` — the change is internal to
  the query object.
- No authentication is added; the endpoint remains public.
- `TierItem` entity and `GetTierResponse` schema are unchanged — response shape
  is identical.
- No other features are affected; `get_user_tier` and `patch_user_tier` use
  FastCRUD directly and do not depend on this slice.

## Testing Decisions

- Good tests verify external behavior: status codes, response body shape, DB
  state — not internal query construction.
- **Use-case unit test**: mock the port; construct `GetTierQuery(id=1)`;
  verify the use case returns the `TierItem` from the port and raises
  `NotFoundDomainError` when the port returns `None`.
- **Adapter unit test**: mock the async session factory; pass `GetTierQuery(id=42)`;
  verify a found row maps to `TierItem` and an absent row returns `None`.
- **Router integration test**: seed a tier, capture its `id` via
  `INSERT ... RETURNING id`, call `GET /tier/{id}`, assert 200 with correct body.
  Also assert 404 for a nonexistent id.
- **Outside-in test**: same acceptance pattern as the router integration test.
- Prior art: `0035_get_tier` tests — same session-factory mock and DI-container
  override patterns apply.

## Out of Scope

- Adding authentication to the GET endpoint.
- Changing the response schema.
- Any change to how users are associated with tiers.
- Database schema changes.

## Further Notes

This is a modification of the already-green `get_tier` slice (0035). Per project
workflow: tests are updated first (going RED), then the implementation is changed
until tests go GREEN again.
