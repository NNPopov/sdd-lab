# PRD — 0049 · users · user_details_route_to_user_id

> **Status:** 📋 Planned
> **Feature:** users
> **Slice:** user_details_route_to_user_id
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 (CurrentUser.id).

## Problem Statement

The backend removed the username-based user-detail route. `GET /user/{username}` now
returns 422/404; the route is `GET /user/{user_id}` keyed by the integer id. The user
detail screen still fetches by username, so it breaks against the new contract.

## Solution

Migrate the user-detail read path to address users by their integer `id`. The port,
adapter, and API-client method for fetching a single user all take `int userId` and call
`GET /user/{user_id}`. The detail screen already has the target user's numeric `id`
(the `User` entity carries `id: int`), so no username lookup is needed.

## User Stories

1. As a user browsing the directory, I want to open a user's detail screen and see their profile, so that I can review their information.
2. As a user, I want the detail screen to load reliably against the new API, so that I don't see a 404/422 error where data used to appear.
3. As a developer, I want the get-user port to accept `int userId`, so that callers pass the same identifier the backend now requires.
4. As a developer, I want the adapter to map HTTP failures (401/403/404/server/unknown) to domain `Failure`s, so that the screen shows correct error states.
5. As a maintainer, I want this slice to depend only on `CurrentUser.id`/`User.id`, so that ownership and navigation never reconstruct a username.

## Implementation Decisions

- **Modules modified:** the get-user **port** (`String username` → `int userId`), its **adapter** (param + API call), and the shared **Users API client** method `getUser` (`@Path('username')`/`/user/{username}` → `@Path('user_id') int userId` / `/user/{user_id}`).
- The detail screen receives the target user's `id` via navigation; this slice does not change navigation (deferred to 0062) but assumes the id is available to the cubit/use-case.
- Adapter retains the mandatory catch-all `catch (e, st)` with `logger.error` per `agent_docs/error_handling.md`.

## Testing Decisions

- **Good test = external behavior:** assert that fetching a user by id yields the expected `User`, and that each HTTP status maps to the documented `Failure`; do not assert on Dio internals.
- **Modules tested (default four-layer policy):**
  - **Adapter** — success path + 401/403/404/server failure mapping + unexpected exception with `logger.error` verified. Prior art: existing user adapter tests under `test/features/users/`.
  - **Use-case** — delegates to the port and propagates `Either`.
  - **Cubit** — loading → loaded(user) and loading → error transitions via `bloc_test`.
  - **Widget** — detail screen renders loaded, loading, and error states with a mocked cubit.

## Out of Scope

- Route path/`@PathParam` changes (`:username` → `:user_id`) — slice 0062.
- Any other user route (delete, erase, tier, moderator, edit) — their own slices.

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decisions 3, 4). Route: `GET /user/{user_id}`.
