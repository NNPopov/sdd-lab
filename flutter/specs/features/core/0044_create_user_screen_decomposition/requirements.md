# 0044 · create_user_screen_decomposition — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | Tapping the submit button when the name field is empty shows the required-field error text on the name field. |
| F2 | Tapping the submit button when the username field is empty shows the required-field error text on the username field. |
| F3 | Tapping the submit button when the email field is empty shows the required-field error text on the email field. |
| F4 | Tapping the submit button when the email field contains an invalid address shows the email-format error text on the email field. |
| F5 | Tapping the submit button when the password field is empty shows the required-field error text on the password field. |
| F6 | Tapping the submit button when the password field contains fewer than 8 characters shows the password-too-short error text on the password field. |
| F7 | Activating the password field's keyboard Done action while not submitting invokes the submit callback. |
| F8 | Activating the password field's keyboard Done action while the Cubit state is `CreateUserSubmitting` does not invoke the submit callback. |
| F9 | When the Cubit state is `CreateUserSubmitting`, the submit button has no `onPressed` handler and a `CircularProgressIndicator` is rendered inside it. |
| F10 | When the Cubit state is `CreateUserValidationError`, the submit button is enabled and the error message text is rendered below the button. |
| F11 | When the Cubit state transitions from `CreateUserValidationError` to `CreateUserIdle`, the validation error text is no longer present in the widget tree. |
| F12 | All existing `CreateUserScreen` widget tests pass without modification after the refactor. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | Only `lib/features/users/create_user/presentation/create_user_screen.dart` is modified; no other source file changes. |
| N2 | `_CreateUserForm` has no import or dependency on `CreateUserCubit` or any Cubit. |
| N3 | `_SubmitSection` reads Cubit state exclusively via an internal `BlocBuilder`; no `CreateUserState` value is passed as a constructor parameter. |
| N4 | The `Form` widget and `GlobalKey<FormState>` remain owned by `_CreateUserScreenState`, not moved into `_CreateUserForm`. |
| N5 | `_emailRegex` is a static field of `_CreateUserForm`, not of `_CreateUserScreenState`. |
| N6 | CC of `_CreateUserScreenState.build()` is ≤ 5 after extraction. |
| N7 | No new routes, screens, Cubits, ports, adapters, or DI modules are added. |
| N8 | No `slang` i18n JSON files are added or changed. |
| N9 | `dart run build_runner` is not required because no `@freezed`, `@injectable`, or `@RestApi` annotations are present in the modified file. |
| N10 | All UI strings are accessed via `context.t` (slang); no hardcoded strings are introduced. |
| N11 | `dart format . --set-exit-if-changed` produces no diff and `dart analyze --fatal-infos` produces zero warnings. |

## Out of scope

- Changes to `CreateUserCubit`, `CreateUserState`, `CreateUserUseCase`, or `CreateUserAdapter`.
- Changes to any other screen, widget, adapter, or Cubit outside `create_user/presentation/`.
- Extracting the `BlocConsumer.listener` switch to a named method.
- Raising or modifying the `dart_code_linter` CC threshold.
- SLOC reduction in `_CreateUserScreenState` beyond what falls naturally from the extraction.
