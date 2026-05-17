# Validation: permission_gated_buttons

## Static checks

- [ ] `dart analyze` — zero errors and warnings in all modified files
- [ ] `dart format --set-exit-if-changed lib/ test/` — zero changes

## Architectural invariants

- [ ] `DeleteUserPort` and `EraseDbUserPort` contain only `call(String username)` — named parameters did not appear
- [ ] `DeleteUserAdapter` and `EraseDbUserAdapter` are not modified
- [ ] `kRolePolicy` is not modified
- [ ] `PermissionCubit` is not modified
- [ ] `Permission.eraseUsers` is present in the enum
- [ ] In `user_details_screen.dart` Delete is shown via `if (showDelete)` (only `isMe`)
- [ ] In `user_details_screen.dart` Erase is shown via `if (showErase)` (`permissions.contains(Permission.eraseUsers)`)
- [ ] Use-case `DeleteUserUseCase.call` returns `Left(PermissionDenied)` without calling the port when usernames don't match
- [ ] Use-case `EraseDbUserUseCase.call` returns `Left(PermissionDenied)` without calling the port when `!isSuperuser`

## Tests

- [ ] `delete_user_usecase_test.dart` exists and contains ≥ 2 test cases (success + permissionDenied)
- [ ] `erase_db_user_usecase_test.dart` exists and contains ≥ 2 test cases
- [ ] `delete_user_cubit_test.dart` contains a test case for `PermissionDenied`
- [ ] `erase_db_user_cubit_test.dart` contains a test case for `PermissionDenied`
- [ ] `flutter test test/features/users/delete_user/` — all green
- [ ] `flutter test test/features/users/erase_db_user/` — all green
- [ ] In use-case tests: verified that the port is **not called** on `PermissionDenied`

## UX scenarios (manual check)

### Scenario 1: Regular user — own profile

1. Log in as a regular user (isSuperuser == false)
2. Open own profile (`user_details_screen`)
3. Should be displayed: Edit button, Delete button
4. Erase button should **not** be displayed

### Scenario 2: Regular user with editUsers permission — another user's profile

1. Log in as a user with the manager role (has `editUsers`, isSuperuser == false)
2. Open another user's profile
3. Should be displayed: Edit button
4. Delete and Erase buttons should **not** be displayed

### Scenario 3: Superuser — another user's profile

1. Log in as a superuser (isSuperuser == true)
2. Open another user's profile
3. Should be displayed: Edit button (via canEdit), Erase button
4. Delete button should **not** be displayed (not the owner)

### Scenario 4: Superuser — own profile

1. Log in as a superuser
2. Open own profile
3. Should be displayed: Edit button, Delete button, Erase button

### Scenario 5: Guest or unauthenticated user

1. Open any user's profile without authentication
2. None of the Edit / Delete / Erase buttons are displayed

### Scenario 6: Attempt to delete another user's account via delete (use-case guard)

1. Direct call to `DeleteUserCubit.confirmAndDelete('other_user')`
   with `currentUser.username == 'me'`
2. Use-case returns `PermissionDenied`
3. State transitions to `DeleteUserFailure(PermissionDenied)`
4. Port (API) is **not called** — no HTTP request

### Scenario 7: Attempt to erase by a regular user (use-case guard)

1. Direct call to `EraseDbUserCubit.confirmAndDelete('any_user')`
   with `currentUser.isSuperuser == false`
2. Use-case returns `PermissionDenied`
3. State transitions to `EraseDbUserFailure(PermissionDenied)`
4. Port (API) is **not called**

## Regression

- [ ] `delete_user` happy path works without changes (isMe + confirmAndDelete)
- [ ] `erase_db_user` happy path works without changes (isSuperuser + confirmAndDelete)
- [ ] `edit_user` is not affected
- [ ] `list_users`, `create_user` are not affected
- [ ] `flutter test` (all project tests) — green
