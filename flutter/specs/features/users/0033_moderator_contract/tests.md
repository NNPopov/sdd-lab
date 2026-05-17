# 0033 · moderator_contract — Outside-in test spec

## Goal

Prove that `AssignModeratorCubit` drives the correct network call through the real
adapter and use-case, and emits the exact state sequence for a successful assign
operation and for a 409-conflict failure.

## Entry point

`cubit.assign('alice')` — triggers `PATCH /user/alice/assign-moderator` and emits
states observable by the UI.

## Wired real (production code in the test)

- `ModeratorManagementAdapter` (the slice's Adapter; implements the port)
- `ModeratorManagementPort` (bound to the adapter — no separate mock)
- `AssignModeratorUseCase` (delegates to the port)
- `RevokeModeratorUseCase` (constructed alongside; same adapter instance)
- `AssignModeratorCubit` (the system under test)

## Mocked (system boundaries only)

- **Dio**: intercepted via `DioAdapter` (or equivalent test interceptor).
  - Scenario 1: `PATCH /user/alice/assign-moderator` → status 200, no body.
  - Scenario 2: `PATCH /user/alice/assign-moderator` → status 409, no body.

No `AppLogger` mock is needed for the happy path. For the conflict path a real or
no-op logger instance is sufficient (409 is a typed mapping, not the outer
catch-all path that calls `logger.error`).

## Test scenarios

### Scenario 1: successful assign

**Setup:**
- Dio is configured to respond to `PATCH /user/alice/assign-moderator` with
  status 200 and an empty body.
- Wire the real `ModeratorManagementAdapter` → `AssignModeratorUseCase` →
  `AssignModeratorCubit`.

**Act:**
- `cubit.assign('alice')`

**Expect:**
- States emitted by the cubit (in order):
  `[AssignModeratorLoading, AssignModeratorSuccess(isModerator: true)]`
- Dio received exactly one request to `PATCH /user/alice/assign-moderator`.
- No error state emitted.

### Scenario 2: conflict (409)

**Setup:**
- Dio is configured to respond to `PATCH /user/alice/assign-moderator` with
  status 409 and an empty body.
- Same real wiring as Scenario 1.

**Act:**
- `cubit.assign('alice')`

**Expect:**
- States emitted by the cubit (in order):
  `[AssignModeratorLoading, AssignModeratorError(ConflictFailure)]`
- No success state emitted.
- Dio received exactly one request to `PATCH /user/alice/assign-moderator`.

## Out of scope for this test

- `cubit.revoke(...)` happy path and failure path (symmetric to the assign path;
  covered by the `AssignModeratorCubit` bloc_test unit test written after green).
- 403 and 404 adapter failure mappings (covered by `ModeratorManagementAdapter`
  unit tests written after green).
- `PermissionCubit` moderator branch (covered by the existing
  `permission_cubit_test.dart` extension written after green).
- Widget rendering: badge visibility, button label toggling, snackbar on error
  (covered by `AssignModeratorButton` widget tests written after green).
- Route navigation (no routing change in this slice).
