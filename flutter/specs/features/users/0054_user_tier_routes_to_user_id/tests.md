# 0054 · user_tier_routes_to_user_id — Outside-in test spec

## Goal

Prove that both user-tier verticals drive the network with the **viewed user's integer
id**: the read path calls `getUserTier(<int>)` and the write path calls
`patchUserTier(<int>, …)`, while the `isSuperuser` guard still refuses a non-superuser
before any HTTP call — all observed at the mocked `UsersApiClient` boundary, no live
backend.

## Entry point

Two public surfaces (the slice bundles two verticals), both driven with `userId: 7`:

- Read: `getUserTierCubit.load(7)`
- Write: `updateUserTierCubit.loadTiers()` → `updateUserTierCubit.selectTier(<tierId>)`
  → `updateUserTierCubit.submit(7)`

## Wired real (production code in the test)

- `GetUserTierAdapter` (read Adapter) bound to `GetUserTierPort`
- `GetUserTierUseCase`
- `GetUserTierCubit` (read system under test)
- `UpdateUserTierAdapter` (write Adapter) bound to `UpdateUserTierPort`
- `UpdateUserTierUseCase` (carries the `isSuperuser` guard)
- `FetchTiersAdapter` + `FetchTiersUseCase` — wired real only so `loadTiers` can reach
  `tiersLoaded`; not under migration, exercised via `getTiersForSelection`
- `UpdateUserTierCubit` (write system under test)
- `UserTier` / `TierOption` domain entities

## Mocked (system boundaries only)

- **UsersApiClient** (the HTTP boundary, wraps Dio):
  - `getUserTier(7)` returns a `UserTierDto` fixture (read success), or throws a
    `DioException` with the configured status code (read failure).
  - `getTiersForSelection(...)` returns a small `PaginatedTierOptionsDto` with at least
    one `TierOption(id: 3, …)` so a tier can be selected.
  - `patchUserTier(7, any)` completes normally (write success).
- **AuthCubit**: `currentUser` returns a fixture whose `isSuperuser` is `true`
  (superuser scenarios) or `false` (guard scenario).
- **AppLogger**: a mock, to allow `logger.error` verification on the unexpected path
  (covered by adapter unit tests; not asserted here).

## Test scenarios

### Scenario 1: read path calls getUserTier with the integer id (happy path)

**Setup:**
- `usersApiClient.getUserTier(7)` returns a `UserTierDto` fixture (e.g. tierName
  "Gold").

**Act:**
- `getUserTierCubit.load(7)`

**Expect:**
- States emitted by `GetUserTierCubit`: `[GetUserTierLoading, GetUserTierLoaded]`
- Mocks verified: `getUserTier(7)` called exactly once with the integer id `7`.

### Scenario 2: read path maps 404 to "Tier not assigned"

**Setup:**
- `usersApiClient.getUserTier(7)` throws `DioException` with `statusCode: 404`.

**Act:**
- `getUserTierCubit.load(7)`

**Expect:**
- States emitted by `GetUserTierCubit`:
  `[GetUserTierLoading, GetUserTierError(NotFoundFailure)]` with the
  "Tier not assigned" message.
- Mocks verified: `getUserTier(7)` called exactly once.

### Scenario 3: superuser write calls patchUserTier with the integer id (happy path)

**Setup:**
- `authCubit.currentUser` returns a fixture with `isSuperuser: true`.
- `usersApiClient.getTiersForSelection(...)` returns a list containing
  `TierOption(id: 3, …)`.
- `usersApiClient.patchUserTier(7, any)` completes normally.

**Act:**
- `updateUserTierCubit.loadTiers()`, then `updateUserTierCubit.selectTier(3)`, then
  `updateUserTierCubit.submit(7)`

**Expect:**
- Final states emitted by `UpdateUserTierCubit` include
  `UpdateUserTierSubmitting` then `UpdateUserTierSuccess`.
- Mocks verified: `patchUserTier(7, <UpdateUserTierRequestDto with tierId 3>)` called
  exactly once with the integer id `7`.

### Scenario 4: non-superuser write is refused by the guard, no HTTP call

**Setup:**
- `authCubit.currentUser` returns a fixture with `isSuperuser: false`.
- `usersApiClient.getTiersForSelection(...)` returns a list containing
  `TierOption(id: 3, …)`.

**Act:**
- `updateUserTierCubit.loadTiers()`, then `updateUserTierCubit.selectTier(3)`, then
  `updateUserTierCubit.submit(7)`

**Expect:**
- States emitted by `UpdateUserTierCubit` end in
  `UpdateUserTierError(PermissionDenied)`.
- Mocks verified: `verifyNever(() => patchUserTier(any(), any()))` — the guard refuses
  before the adapter is reached, so no PATCH is sent.

## Out of scope for this test

- Widget rendering (the tier button/sheet, panel display) — covered by widget tests
  separately.
- Route navigation and the cross-slice `user_details_screen` wiring — covered by
  widget/routing tests separately.
- The full HTTP failure matrix (401/403/default, unexpected → `logger.error`) — covered
  by adapter unit tests written from `plan.md` after green.
- The handle behavior (title, post navigation, moderator button) — unchanged and not
  observable through these cubits.
