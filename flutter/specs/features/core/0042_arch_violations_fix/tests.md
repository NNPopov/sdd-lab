# 0042 · arch_violations_fix — Outside-in test spec

## Goal

Prove that when the server returns a 422 ValidationFailure on tier creation, the
error lands in `CreateTierCubit` state — not in widget-local `setState` — and that
the full production chain from Cubit to network adapter emits the correct state
sequence.

## Entry point

`cubit.submit(NewTierData(name: 'Gold'))`

## Wired real (production code in the test)

- `TiersApiClient` (Retrofit client wrapping the mocked Dio instance)
- `CreateTierAdapter` (implements `CreateTierPort`, wired to `TiersApiClient`)
- `CreateTierUseCase` (wired to `CreateTierAdapter` and mocked `PermissionCubit`)
- `CreateTierCubit` (system under test, wired to `CreateTierUseCase`)

## Mocked (system boundaries only)

- **Dio**: configured per scenario (see below).
- **PermissionCubit**: `has(Permission.manageTiers)` returns `true` in both scenarios.
- **AppLogger**: no-op stub; required by `CreateTierAdapter`'s constructor.

## Test scenarios

### Scenario 1: successful tier creation

**Setup:**
- Dio returns HTTP 200 for `POST /tier` with body:
  `{"id": 1, "name": "Gold", "created_at": "2025-01-15T10:00:00"}`

**Act:**
- `cubit.submit(NewTierData(name: 'Gold'))`

**Expect:**
- States emitted by the Cubit: `[CreateTierSubmitting, CreateTierSuccess(Tier(id: 1, name: 'Gold'))]`
- Mocks verified: Dio received exactly one `POST` to the tier creation endpoint.

### Scenario 2: server returns 422 ValidationFailure

**Setup:**
- Dio returns HTTP 422 for `POST /tier` with body:
  ```
  {
    "detail": [
      { "loc": ["body", "name"], "msg": "Name already taken", "type": "value_error" }
    ]
  }
  ```

**Act:**
- `cubit.submit(NewTierData(name: 'Gold'))`

**Expect:**
- States emitted by the Cubit:
  `[CreateTierSubmitting, CreateTierFailure(ValidationFailure(fieldErrors: {'name': 'Name already taken'}))]`
- No exception is thrown or propagated; the adapter's outer catch-all does not fire.
- Mocks verified: Dio received exactly one `POST` to the tier creation endpoint.

## Out of scope for this test

- Widget rendering, snackbars, and navigation (covered by widget tests).
- `clearError()` state transition (trivial Cubit unit test: emits `[CreateTierIdle]`).
- The general-error fallback path where `detail` is a plain string instead of a list
  (covered by `CreateTierAdapter` unit test).
- `CreateUserCubit` ValidationFailure path (identical pattern to scenario 2; covered
  by a mirrored Cubit unit test under `create_user`).
- `AssignModeratorCubit.assign/revoke` outside-in path (simpler chain with no
  per-field mapping; covered by `AssignModeratorAdapter` unit test + `UserDetailsCubit`
  unit test for `updateIsModerator`).
- AppRouter route tree and domain entity import changes (no runtime behavior;
  verified by `dart analyze` and the linter metrics run).
