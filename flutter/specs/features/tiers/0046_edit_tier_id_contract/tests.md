# 0046 · edit_tier_id_contract — Outside-in test spec

## Goal

Verify that calling `EditTierCubit.submit` with an integer `tierId` sends
`PATCH /tier/{id}` with body `{"name": "..."}` (not `new_name`) and drives the
cubit through the correct state sequence.

## Entry point

`cubit.submit(data: EditTierData(tierId: 1, name: 'premium'), isSuperuser: true)`

## Wired real (production code in the test)

- `EditTierAdapter` (port implementation)
- `EditTierPort` (abstract boundary — bound to `EditTierAdapter`)
- `EditTierUseCase`
- `EditTierCubit` (system under test)

## Mocked (system boundaries only)

- **Dio**: configured via `MockAdapter` (from `dio/src/adapters/mock_adapter.dart`
  or equivalent) to intercept requests by method + path.
  - Scenario 1: returns status 204 for `PATCH /tier/1`.
  - Scenario 2: returns status 404 for `PATCH /tier/1`.

No `AuthCubit` mock is needed — `isSuperuser` is passed directly as a parameter
to `submit`, so there is no dependency on the auth state at runtime.

## Test scenarios

### Scenario 1: successful edit — sends integer id and returns success state

**Setup:**
- Mock Dio to return HTTP 204 (no body) for `PATCH /tier/1`.

**Act:**
- `cubit.submit(data: EditTierData(tierId: 1, name: 'premium'), isSuperuser: true)`

**Expect:**
- States emitted: `[EditTierSubmitting, EditTierSuccess(newName: 'premium')]`
- Dio received exactly one `PATCH` request to the path `/tier/1` (integer segment,
  not a string name in the path).
- The request body serialised to `{"name": "premium"}` — the key is `name`, not
  `new_name`.

### Scenario 2: tier not found — adapter maps 404 to failure state

**Setup:**
- Mock Dio to return HTTP 404 for `PATCH /tier/1`.

**Act:**
- `cubit.submit(data: EditTierData(tierId: 1, name: 'premium'), isSuperuser: true)`

**Expect:**
- States emitted: `[EditTierSubmitting, EditTierFailure(NotFoundFailure)]`
- No success side effects.

## Out of scope for this test

- Widget rendering and snackbar display (covered by widget tests in
  `test/features/tiers/edit_tier/presentation/edit_tier_screen_test.dart`).
- Route navigation and pop-with-value behaviour (covered by widget tests).
- The 403 / `ForbiddenFailure` path (covered by `edit_tier_adapter_test.dart`).
- The permission gate (`isSuperuser: false` short-circuit) (covered by
  `edit_tier_usecase_test.dart`).
- Unexpected-exception / `UnknownFailure` path (covered by adapter unit test).
