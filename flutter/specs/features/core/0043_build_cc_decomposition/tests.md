# 0043 · build_cc_decomposition — Outside-in test spec

## Goal

Prove that `CreateUserCubit.submit()` correctly routes a server HTTP 422 response
to `CreateUserValidationError` (not `CreateUserFailure`) by driving the full
`CreateUserAdapter → CreateUserUseCase → CreateUserCubit` chain with a real
network boundary mock.

## Entry point

`cubit.submit(NewUserData(name: 'New User', username: 'newuser', email: 'new@example.com', password: 'Password1!'))`

## Wired real (production code in the test)

- `CreateUserAdapter` (the adapter; implements `CreateUserPort`)
- `CreateUserUseCase` (wired to the adapter above)
- `CreateUserCubit` (system under test; wired to the use-case above)

## Mocked (system boundaries only)

- **Dio**: intercepted per scenario below; the `UsersApiClient` is constructed with
  this mock Dio instance.
- **AppLogger**: no-op stub; `error(...)` must be verified in Scenario 3 only.

## Test scenarios

### Scenario 1: Server returns 200 — cubit emits success

**Setup:**
- Dio returns HTTP 200 for `POST /user` with body
  `{"id": 1, "name": "New User", "username": "newuser", "email": "new@example.com", "is_moderator": false}`.

**Act:**
- `cubit.submit(NewUserData(name: 'New User', username: 'newuser', email: 'new@example.com', password: 'Password1!'))`

**Expect:**
- States emitted: `[CreateUserSubmitting, CreateUserSuccess(User(id: 1, name: 'New User', username: 'newuser', email: 'new@example.com', isModerator: false))]`
- Side effects: none.
- Mocks verified: Dio called once for `POST /user`; `AppLogger.error` never called.

### Scenario 2: Server returns 422 with string detail — cubit emits CreateUserValidationError

**Setup:**
- Dio returns HTTP 422 for `POST /user` with body
  `{"detail": "That username is taken"}`.

**Act:**
- `cubit.submit(NewUserData(name: 'New User', username: 'newuser', email: 'new@example.com', password: 'Password1!'))`

**Expect:**
- States emitted: `[CreateUserSubmitting, CreateUserValidationError(message: 'That username is taken')]`
- The emitted state is `CreateUserValidationError`, **not** `CreateUserFailure`; the
  message is the raw string from the `detail` field, not a key-guessed map value.
- Side effects: none.
- Mocks verified: `AppLogger.error` never called (422 is a handled path).

### Scenario 3: Dio throws an unexpected exception — cubit emits failure and logger is called

**Setup:**
- Dio throws a non-DioException (e.g. `StateError('unexpected')`) when `POST /user`
  is called.

**Act:**
- `cubit.submit(NewUserData(name: 'New User', username: 'newuser', email: 'new@example.com', password: 'Password1!'))`

**Expect:**
- States emitted: `[CreateUserSubmitting, CreateUserFailure(UnknownFailure())]`
- Side effects: `AppLogger.error` called once with a non-null `error:` argument and
  a non-null `stackTrace:` argument.
- Mocks verified: `AppLogger.error` called exactly once.

## Out of scope for this test

- Widget rendering (Create User screen UI, snackbar display, TextFormField validation).
- Route navigation (pop on success).
- `CreateTierCubit` / `CreateTierAdapter` chain (same pattern; covered by create_tier adapter unit test).
- `UpdateUserAdapter` `FieldValidationFailure` path (covered by update_user adapter unit test).
- `UserActionVisibility.from(...)` logic (pure function; covered by unit test in
  `test/features/users/user_details/presentation/user_action_visibility_test.dart`).
- `_PostDetailsActions` and `_PostDetailsBody` widget layout (covered by widget tests).
- Manual UX scenarios from `validation.md` that do not change observable Cubit state.
