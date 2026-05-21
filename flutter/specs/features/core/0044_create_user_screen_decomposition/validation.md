# 0044 · create_user_screen_decomposition — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Open the Create User screen. Tap Submit without filling any field. | The required-field error text appears on the name field only; no other field shows an error. |
| M2 | Fill the name field, leave all others empty. Tap Submit. | The required-field error text appears on the username field. |
| M3 | Fill name and username, leave email and password empty. Tap Submit. | The required-field error text appears on the email field. |
| M4 | Fill name, username, and `notvalid` in the email field. Tap Submit. | The email-format error text appears on the email field; no error on name or username. |
| M5 | Fill name, username, a valid email. Leave password empty. Tap Submit. | The required-field error text appears on the password field. |
| M6 | Fill all fields; enter `abc1234` (7 characters) as the password. Tap Submit. | The password-too-short error text appears on the password field. |
| M7 | Fill all fields correctly. Tap Submit. | No field-level error text is visible; `CreateUserCubit.submit` is called with the entered values. |
| M8 | Fill all fields correctly. Press the Done keyboard action on the password field. | `CreateUserCubit.submit` is called (same outcome as M7). |
| M9 | In a widget test, provide a mock `CreateUserCubit` that emits `CreateUserSubmitting`. Pump the screen. | The submit button has `onPressed == null`; a `CircularProgressIndicator` is visible inside the button; no validation error text is present. |
| M10 | In a widget test, mock Cubit emits `CreateUserSubmitting`; press Done on password field. | `CreateUserCubit.submit` is not called during the submitting state. |
| M11 | In a widget test, mock Cubit emits `CreateUserValidationError(message: 'Username taken')`. | The submit button has a non-null `onPressed`; the text `Username taken` is rendered below the button. |
| M12 | In a widget test, mock Cubit emits `CreateUserValidationError(message: 'Username taken')`, then emits `CreateUserIdle`. | `Username taken` is no longer present in the widget tree. |
| M13 | Run the existing `create_user_screen_test.dart` without modifying the test file. | All existing assertions pass without changes. |
| M14 | Run `dart_code_linter:metrics` (or inspect the CC report) on `create_user_screen.dart`. | `_CreateUserScreenState.build()` reports CC ≤ 5; no ALARM-level method remains. |

## Code review

- [ ] Only `lib/features/users/create_user/presentation/create_user_screen.dart` appears in the diff — no other source file is modified.
- [ ] `_CreateUserForm` class file section contains no import of `CreateUserCubit`, `CreateUserState`, or `flutter_bloc`.
- [ ] `_SubmitSection.build()` contains a `BlocBuilder<CreateUserCubit, CreateUserState>` internally; the `_SubmitSection` constructor has no `CreateUserState` or `bool isSubmitting` parameter.
- [ ] `Form(key: _formKey, ...)` is declared in `_CreateUserScreenState.build()`, not inside `_CreateUserForm.build()`.
- [ ] `_emailRegex` is a `static final` field on `_CreateUserForm`, not on `_CreateUserScreenState`.
- [ ] `_CreateUserScreenState.build()` contains no ternary or `if/else` branches inside the `BlocConsumer.builder` closure (the `isSubmitting` bool derivation is a plain assignment, not a branch).
- [ ] No new route, Cubit, port, or adapter class is added anywhere.
- [ ] No file under `lib/core/i18n/` is modified.
- [ ] No `@freezed`, `@injectable`, or `@RestApi` annotation is present in the modified file (confirms build_runner is not needed for the change itself).
- [ ] No hardcoded UI string in `_CreateUserForm` or `_SubmitSection` — all text is accessed via `context.t.*`.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
