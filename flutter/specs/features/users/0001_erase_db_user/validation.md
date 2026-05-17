# Validation: erase_db_user

## Static checks

- [ ] `dart analyze` — zero errors and warnings in new files
- [ ] `dart format --set-exit-if-changed lib/features/users/erase_db_user/` — zero changes
- [ ] `dart run build_runner build` completed without errors
- [ ] `dart run slang` completed, generated files updated

## Architectural invariants

- [ ] `erase_db_user/domain/` contains no imports of `package:flutter/*`, `package:dio/*`
- [ ] `erase_db_user/application/` contains no direct call to `UsersApiClient`
- [ ] `erase_db_user/` does not import `delete_user/`, `list_users/`, `create_user/`, `edit_user/`
- [ ] `EraseDbUserAdapter` has a two-level catch (inner `on DioException`, outer `catch (e, st)`)
- [ ] `EraseDbUserAdapter` passes `stackTrace` to `_logger.error`
- [ ] No hardcoded strings — all text via `context.t.users.eraseDbUser.*`

## Tests

- [ ] `erase_db_user_cubit_test.dart` exists and contains ≥ 5 test cases
- [ ] `erase_db_user_adapter_test.dart` exists and contains ≥ 6 test cases
- [ ] `flutter test test/features/users/erase_db_user/` — all green
- [ ] Cubit tests verify that `forceLogout(notifyUser: false)` **was called** on success
- [ ] Cubit tests verify that `forceLogout` was **not called** on failure
- [ ] Adapter tests verify that `logger.error` was called on unexpected exception

## UX scenarios (manual check)

### Scenario 1: Happy path
1. Log in as user A
2. Open `user_details_screen` of user A
3. Confirm that `EraseDbUserButton` is visible (icon `delete_forever`)
4. Tap the button → confirmation dialog opened
5. Dialog contains a warning about **irreversibility** (hard delete)
6. Tap "Erase permanently" → button becomes inactive + spinner
7. Received response from server → snackbar "Account erased from the database"
8. Redirect to `/users` (users list)
9. User is logged out — attempting to navigate to a protected route → redirect to `/login`

### Scenario 2: Cancellation
1. Open profile, tap the Erase button
2. In the dialog tap "Cancel"
3. Dialog closed, state returned to `initial`
4. Button is active again

### Scenario 3: Another user's profile
1. Open `user_details_screen` of user B (not the current user)
2. `EraseDbUserButton` is **not displayed**
3. `DeleteAccountButton` is also **not displayed**

### Scenario 4: Network error
1. Disable network / stub the endpoint
2. Tap Erase → confirm
3. Snackbar with generic error
4. User is **not logged out** — session preserved
5. Button is active again

### Scenario 5: Isolation from delete_user
1. Verify that the Delete and Erase buttons are different widgets
2. Tapping Erase does not invoke any logic from `delete_user/`
3. Tapping Delete does not invoke any logic from `erase_db_user/`

## Existing functionality check (regression)

- [ ] `delete_user` works without changes
- [ ] `user_details_screen` correctly renders both widgets side by side
- [ ] `list_users` is not affected
- [ ] `create_user`, `edit_user` are not affected
