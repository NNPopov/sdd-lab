# 0049 · delete_user_route_to_user_id — Outside-in test spec

## Goal

Prove that the delete-user vertical, wired end to end, calls the API with the
**integer user id** for a matching-id self-delete and refuses a non-matching id in
the domain-layer ownership guard before any request is made.

## Entry point

`cubit.confirmAndDelete(1)` — the only public mutating method on `DeleteUserCubit`
(positional `int userId`).

## Wired real (production code in the test)

- `DeleteUserAdapter` (the slice's adapter, constructed with the mocked
  `UsersApiClient` and a mocked `AppLogger`).
- `DeleteUserPort` (bound to `DeleteUserAdapter`).
- `DeleteUserUseCase` (constructed with the real adapter — carries the ownership guard).
- `DeleteUserCubit` (the system under test, constructed with the real use-case and the
  mocked `AuthCubit`).

## Mocked (system boundaries only)

- **`UsersApiClient`**: `deleteUser(<int>)` either completes normally (success) or is
  never reached (guard-denied). No live backend.
- **`AuthCubit`**: `currentUser` returns
  `CurrentUser(id: 1, username: 'admin', email: 'admin@example.com', name: 'Admin', isSuperuser: true, isModerator: false)`.
  `forceLogout(notifyUser: false)` is stubbed and verified.
- **`AppLogger`**: stubbed; not exercised in these two scenarios.

## Test scenarios

### Scenario 1: matching id — self-delete succeeds via the id route

**Setup:**
- `authCubit.currentUser` returns `CurrentUser(id: 1, …)`.
- `apiClient.deleteUser(1)` completes normally (server 200).
- `authCubit.forceLogout(notifyUser: false)` completes normally.

**Act:**
- `cubit.confirmAndDelete(1)`

**Expect:**
- States emitted by the Cubit: `[DeleteUserDeleting, DeleteUserSuccess]`
- Side effects observed: `authCubit.forceLogout(notifyUser: false)` called once.
- Mocks verified: `apiClient.deleteUser(1)` called exactly once with the **integer** `1`.

### Scenario 2: non-matching id — ownership guard refuses before any request

**Setup:**
- `authCubit.currentUser` returns `CurrentUser(id: 1, …)`.
- `apiClient.deleteUser` is left unstubbed (it must never be invoked).

**Act:**
- `cubit.confirmAndDelete(2)`

**Expect:**
- States emitted by the Cubit: `[DeleteUserDeleting, DeleteUserFailure(PermissionDenied)]`
- Side effects observed: `authCubit.forceLogout` is **never** called.
- Mocks verified: `apiClient.deleteUser(any())` is **never** called.

## Out of scope for this test

- Widget rendering, the confirmation dialog, the success snackbar, and the
  `replaceAll([UsersRoute()])` navigation (covered by widget tests separately).
- The 401/403/404/default → `Failure` mapping and the unexpected-exception →
  `UnknownFailure` + `logger.error` path (covered by adapter unit tests).
- The unauthenticated sentinel (`currentUser == null → -1`) branch (covered by cubit
  unit tests).
- Manual UX scenarios from `validation.md` that do not change observable state
  through this Cubit.
