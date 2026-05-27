# PRD — 0054 user_tier_routes_to_user_id

**Feature:** users
**Status:** 📋 needs-triage
**Part of:** `{username}` → `{user_id}` API migration (closes a gap deferred by 0049's "Out of Scope")
**Depends on:** nothing. Unlike 0049, neither tier use-case compares identity, so
`CurrentUser.id` (slice 0048) is **not** required. The update guard is `isSuperuser`,
sourced from `AuthCubit`, and the read path has no guard at all.

## Problem Statement

The backend's `{username}` → `{user_id}` migration shipped, but two Flutter user-tier
routes were never migrated and still send the `username` string into an `int user_id`
path. The reported failure is `PATCH /api/v1/user/userson20/tier → 422`: the client puts
the handle where the backend now expects an integer id, so FastAPI rejects the request
before it reaches the handler. The same defect exists on the read side
(`GET /user/{username}/tier`). Both routes target `int user_id` on the backend.

This is a roadmap gap, not a one-off bug: the 0049 PRD explicitly deferred these routes
"until their own slices", and that slice was never created. Until it is, a superuser
cannot change another user's tier, and the tier panel on the user-details screen relies
on a route that the backend has already moved off `username`.

## Solution

Migrate the two user-tier verticals — `get_user_tier` (read) and `update_user_tier`
(write) — from username-as-identity to `user_id: int`, end to end and without behavior
change. For each vertical the API method, port, adapter, use-case, and cubit switch their
target identifier from `String username` to `int userId`. The `update_user_tier` button
and bottom sheet switch the same way. The `isSuperuser` guard in the update use-case, the
tier dropdown, the submit/success/error flow, the snackbars, and the read-path failure
mapping are all unchanged.

Per `CONTEXT.md`, the value passed into `getUserTier(...)` / `patchUserTier(...)` is
**path-identity** — it names *which* user the tier request targets — so it migrates to
`user_id: int`. No **handle** is touched: the `@username` shown in the user-details title,
the post-navigation `username`, and the `AssignModeratorButton`'s identifier all stay as
they are. The target id is the viewed `User.id`, already present in `UserDetailsCubit`
state and at `UserDetailsScreen.userId`.

## User Stories

1. As a superuser, I want to change another user's tier via the new id-based route, so
   that the tier update works against the migrated backend and no longer returns 422.
2. As any viewer of a user-details screen, I want that user's current tier to load via the
   new id-based route, so that the tier panel shows real data instead of a load error.
3. As a superuser, I want the tier bottom sheet — open, fetch tiers, pick a tier, confirm,
   see the success snackbar, see the panel refresh — to behave exactly as before, so that
   only the underlying identifier changed.
4. As a non-superuser, I want a tier-change attempt to still be refused by the use-case
   with the same permission-denied message, so that the `isSuperuser` rule is unchanged by
   the migration.
5. As a viewer, I want the tier-read failures (401/403/404/unexpected) to map to the same
   messages and the "Tier not assigned" not-found case to behave as before, so that error
   handling is preserved.
6. As a developer, I want the `getUserTier` and `patchUserTier` retrofit methods to declare
   `/user/{user_id}/tier` with an integer path parameter, so that the generated requests
   hit the correct routes.
7. As a developer, I want `GetUserTierPort` and `UpdateUserTierPort` to accept `int userId`,
   so that the id-based contract is enforced at the layer boundary.
8. As a developer, I want both adapters to pass the integer id to the API client while
   keeping their existing failure mapping (including the catch-all `logger.error`),
   so that only the identifier type changes.
9. As a developer, I want `GetUserTierUseCase` and `UpdateUserTierUseCase` to take
   `int userId`, with the update use-case's `isSuperuser` guard left exactly as it is, so
   that the domain-layer permission rule is not weakened by the migration.
10. As a developer, I want `GetUserTierCubit.load(...)` and `UpdateUserTierCubit.submit(...)`
    to take `int userId`, so that the application layer threads the id through.
11. As a developer, I want `UpdateUserTierButton` and `UpdateUserTierSheet` to take
    `int userId`, so that the presentation layer no longer carries the handle as identity.
12. As a developer, I want the user-details screen to load the tier with `state.user.id` at
    both call sites (initial load and post-update refresh) and to construct the tier button
    with the viewed user's id, so that the tier panel and action use the integer route.
13. As a developer, I want the tier button's visibility to gate on permission only (drop
    the `username != null` clause), mirroring the migrated delete button, so that the action
    no longer depends on a handle being present.
14. As a maintainer, I want the tier tests migrated to the id contract on all four layers
    plus a slice outside-in test that verifies the API client is called with the integer id,
    so that the migration is provably correct without a live backend.

## Implementation Decisions

- **Module: Users API client (`getUserTier`, `patchUserTier`).**
  `GET /user/{username}/tier` with `@Path('username') String username` →
  `GET /user/{user_id}/tier` with `@Path('user_id') int userId`; and
  `PATCH /user/{username}/tier` with `@Path('username') String username` →
  `PATCH /user/{user_id}/tier` with `@Path('user_id') int userId` (body unchanged).
  Both routes are singular `/user/` — there is **no** plural asymmetry here; that concern
  belongs only to the moderator routes (slice 0055). **Requires `build_runner`** to
  regenerate the retrofit client.
- **Module: `GetUserTierPort`.** `call(String username)` → `call(int userId)`.
- **Module: `UpdateUserTierPort`.** `call({String username, int tierId})` →
  `call({int userId, int tierId})`.
- **Module: get-user-tier adapter.** Parameter and API call switch to `int userId`;
  the existing failure mapping (401/403/404="Tier not assigned"/default + catch-all
  `logger.error`) is preserved unchanged.
- **Module: update-user-tier adapter.** Parameter and API call switch to `int userId`;
  the existing failure mapping (401/403/404/default-server + catch-all `logger.error`) is
  preserved unchanged.
- **Module: `GetUserTierUseCase`.** `call(String username)` → `call(int userId)`. No guard
  — pure delegation to the port.
- **Module: `UpdateUserTierUseCase` (guard stays here).** `call({String username, int tierId,
  bool isSuperuser})` → `call({int userId, int tierId, bool isSuperuser})`. The guard
  `if (!isSuperuser) → Left(PermissionDenied)` is **unchanged** and stays in the use-case
  (CLAUDE.md forbids UI-only permission checks). This guard does **not** compare ids, so the
  slice has no dependency on 0048.
- **Module: `GetUserTierCubit`.** `load(String username)` → `load(int userId)`.
- **Module: `UpdateUserTierCubit`.** `submit(String username)` → `submit(int userId)`;
  `isSuperuser` continues to come from `_auth.currentUser?.isSuperuser ?? false`. The state
  machine (loadingTiers / tiersLoaded / submitting / success / error) is otherwise unchanged.
- **Module: tier button + sheet (presentation).** `UpdateUserTierButton` and
  `UpdateUserTierSheet` take `int userId` instead of `String username`, threaded through to
  `submit`.
- **Cross-slice edit (in scope, surgical): user-details screen.**
  - Both `GetUserTierCubit.load(...)` call sites — the initial load on `UserDetailsLoaded`
    and the refresh on `UpdateUserTierSuccess` — switch from `state.user.username` to
    `state.user.id`.
  - The tier button is constructed with the viewed user's id (available as the screen's
    `userId`), and its visibility gate drops the `username != null` clause, gating on
    `visibility.canEditTier` only — mirroring the already-migrated delete button.
  - The `username` local in the actions row **stays**, because `AssignModeratorButton` still
    consumes it (moderator routes are slice 0055). This leaves the actions row in the same
    accepted **mixed-key** state established by 0049 — not a regression.
- **Behavior unchanged.** Same tier panel, same bottom-sheet flow, same `isSuperuser` rule,
  same messages and snackbars, same not-found handling. The migration is a pure identifier
  change (username → id) across both verticals.

## Testing Decisions

A good test asserts external behavior: that each tier vertical calls the API with the
correct **integer id**, that the update guard still refuses a non-superuser, and that the
read path maps failures as before — not how the widgets are wired internally.

- **Use-case (unit).**
  - `GetUserTierUseCase`: delegates to the port with the given `int userId` and returns the
    port's result (Right/Left passthrough).
  - `UpdateUserTierUseCase`: with `isSuperuser == true`, delegates to the port with
    `userId` + `tierId` and returns its result; with `isSuperuser == false`, returns
    `Left(PermissionDenied)` and never calls the port. (Direct migration of the existing
    tests from username to id.)
- **Adapter (unit), both adapters.** Success path calls the API method with the `int` id;
  401/403/404/default map to the correct `Failure` (get: 404 → "Tier not assigned";
  update: default → server failure); an unexpected exception maps to the unknown failure
  and calls `logger.error`.
- **Cubit (`bloc_test`).**
  - `GetUserTierCubit`: `load(<int>)` emits loading → loaded on success, loading → error on
    failure.
  - `UpdateUserTierCubit`: `loadTiers` → tiersLoaded; `selectTier`; `submit(<int>)` →
    submitting → success; submit with non-superuser → error(PermissionDenied); driven with
    `int userId` and a stubbed `currentUser.isSuperuser`.
- **Widget.** `UpdateUserTierButton`/`UpdateUserTierSheet` with a mocked cubit: opening the
  sheet triggers `loadTiers`; confirming triggers `submit(<int>)`; success closes the sheet.
- **Slice outside-in (acceptance gate).** Wires real adapter + use-case + cubit for both the
  read and the write path, mocks the `UsersApiClient` (and `AuthCubit` for `isSuperuser`),
  and `verify`s that `getUserTier(<int>)` and `patchUserTier(<int>, ...)` are called with the
  integer id — mirroring `0049`'s outside-in test. Mocked at the API-client boundary; no
  live backend.
- **Prior art:**
  `test/features/users/0049_delete_user_route_to_user_id/delete_user_route_to_user_id_outside_in_test.dart`
  (id-contract outside-in shape, mocked API client);
  the existing `get_user_tier` and `update_user_tier` unit/cubit/widget tests, migrated in
  place from the username contract to the id contract.

## Out of Scope

- The moderator routes (`assignModerator` / `revokeModerator`) — slice 0055, including the
  intentional plural `/users/{user_id}/revoke-moderator` asymmetry. The `username` local in
  the user-details actions row stays for `AssignModeratorButton` until then.
- Any change to the `username` **handle**: the `@username` title on the user-details screen,
  the `username` passed to `UserPostsRoute` for post navigation, the create/edit-user form,
  login, and any displayed `@username` label.
- All Posts route migrations and any other route, port, or adapter outside the two tier
  verticals.
- The `tierId` value itself (already an integer; unrelated to the user-identity migration).
- Backend changes of any kind.
- Roadmap status cleanup for stale `📋` rows (0049/0050) — separate bookkeeping.

## Further Notes

- This slice closes the specific gap behind the reported `422` and becomes the verified
  template for the near-identical moderator slice (0055), which reuses the same per-layer
  edit inventory.
- **Difference vs. 0049:** 0049 is a self-delete with a use-case ownership guard that
  compares ids, so it depends on 0048. The tier routes do not compare identity — the update
  guard is `isSuperuser` and the read has no guard — so 0054 has **no** 0048 dependency and
  can land independently.
- Two verticals are bundled into one slice because they share the same screen surface, the
  same `_shared/users_api_client.dart`, and the same identity-migration rationale; splitting
  them would duplicate the cross-slice presentation edit for no benefit.
- The mixed-key actions row persists after this slice (tier + delete by id, moderator by
  handle) and resolves fully when 0055 lands.
