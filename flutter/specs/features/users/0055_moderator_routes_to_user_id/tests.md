# 0055 · moderator_routes_to_user_id — Outside-in test spec

## Goal

Prove that the moderator vertical drives the network with the **viewed user's integer
id** for *both* directions: `assign(7)` calls `assignModerator(7)` and `revoke(7)` calls
`revokeModerator(7)` — observed at the mocked `UsersApiClient` boundary, no live backend.
(The singular-assign / plural-revoke path-string asymmetry is **not** assertable at this
boundary — that is enforced by `validation.md` and a manual network-log step.)

## Entry point

One public surface (a single cubit serves both directions), driven with `userId: 7`:

- Assign: `cubit.assign(7)`
- Revoke: `cubit.revoke(7)`

## Wired real (production code in the test)

- `ModeratorManagementAdapter` (the slice's Adapter) bound to `ModeratorManagementPort`
- `AssignModeratorUseCase`
- `RevokeModeratorUseCase`
- `AssignModeratorCubit` (the system under test, serving both `assign` and `revoke`)

## Mocked (system boundaries only)

- **UsersApiClient** (the HTTP boundary, wraps Dio):
  - `assignModerator(7)` completes normally (assign success), or throws a `DioException`
    with the configured status code (failure).
  - `revokeModerator(7)` completes normally (revoke success).
- **AppLogger**: a mock, to allow `logger.error` on the unexpected-exception path
  (covered by adapter unit tests; not asserted here).

No `AuthCubit` is needed — the moderator use-cases perform no identity comparison and no
guard, so the slice has no dependency on the current user.

## Test scenarios

### Scenario 1: assign calls assignModerator with the integer id (happy path)

**Setup:**
- `usersApiClient.assignModerator(7)` completes normally.

**Act:**
- `cubit.assign(7)`

**Expect:**
- States emitted by `AssignModeratorCubit`:
  `[AssignModeratorLoading, AssignModeratorSuccess(isModerator: true)]`
- Mocks verified: `assignModerator(7)` called exactly once with the integer id `7`.

### Scenario 2: revoke calls revokeModerator with the integer id (happy path)

**Setup:**
- `usersApiClient.revokeModerator(7)` completes normally.

**Act:**
- `cubit.revoke(7)`

**Expect:**
- States emitted by `AssignModeratorCubit`:
  `[AssignModeratorLoading, AssignModeratorSuccess(isModerator: false)]`
- Mocks verified: `revokeModerator(7)` called exactly once with the integer id `7`.

### Scenario 3: assign maps a 409 to ConflictFailure (most important failure path)

**Setup:**
- `usersApiClient.assignModerator(7)` throws `DioException` with `statusCode: 409`.

**Act:**
- `cubit.assign(7)`

**Expect:**
- States emitted by `AssignModeratorCubit`:
  `[AssignModeratorLoading, AssignModeratorError(ConflictFailure)]`
- Mocks verified: `assignModerator(7)` called exactly once with the integer id `7`.

## Out of scope for this test

- Widget rendering (the moderator button label toggle, spinner, snackbar) — covered by
  the widget test separately.
- The cross-slice `user_details_screen` wiring (button construction with the id, the
  removed `username` local) — covered by widget/routing tests separately.
- The singular-assign / plural-revoke URL path strings — not observable at the mocked
  `UsersApiClient` method boundary; enforced by `validation.md` + manual network log.
- The full HTTP failure matrix (403/404/default, unexpected → `logger.error`) — covered
  by adapter unit tests written from `plan.md` after green.
- The handle behavior (app-bar title, post navigation) — unchanged and not observable
  through this cubit.
