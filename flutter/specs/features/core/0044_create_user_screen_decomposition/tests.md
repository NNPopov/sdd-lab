# 0044 · create_user_screen_decomposition — Outside-in test spec

## Goal

Prove that extracting `_CreateUserForm` and `_SubmitSection` from `_CreateUserScreenState`
does not change any externally-observable behaviour: field validators still fire correctly,
the submit button still reflects Cubit state, and the existing `CreateUserScreen` public
surface is unchanged.

## Entry point

Because this slice is a pure presentation refactor with no Cubit, port, or adapter
changes, the public surface is the widget itself. The outside-in test pumps
`CreateUserScreen` and drives it through its two observable responsibilities:
field validation (owned by `_CreateUserForm`) and submit state rendering (owned by
`_SubmitSection`).

Test invocations:
- `tester.tap(find.byType(FilledButton))` — triggers form validation (submit attempt)
- Mock cubit state emission via `StreamController.broadcast()` — drives `_SubmitSection`

## Wired real (production code in the test)

- `CreateUserScreen` (the StatefulWidget, the system under test)
- `_CreateUserForm` (private class inside `create_user_screen.dart`; wired real via the screen)
- `_SubmitSection` (private class inside `create_user_screen.dart`; wired real via the screen)

No use-case, adapter, or port is exercised — this slice does not change those layers.

## Mocked (system boundaries only)

- **`CreateUserCubit`**: mock via `MockCubit<CreateUserState>` (mocktail + bloc_test).
  State stream is driven by a `StreamController.broadcast()`.
  Initial state is `CreateUserIdle`.
- **`StackRouter`**: mock via `StackRouterScope` to satisfy `context.router` calls in
  the `BlocConsumer.listener` (listener executes `context.router.maybePop()` on success).

`TranslationProvider` must wrap the test tree with `LocaleSettings.setLocale(AppLocale.en)`
called in `setUpAll`, because `_CreateUserForm` and `_SubmitSection` both use `context.t`.

## Test scenarios

### Scenario 1: All fields valid — validators pass and cubit.submit is called

**Setup:**
- Mock Cubit initial state: `CreateUserIdle`.
- `StackRouter` mock: no expectations needed (pop is not reached in this scenario).

**Act:**
- Pump `CreateUserScreen` with the mock Cubit.
- Enter `'Alice Example'` in the name field.
- Enter `'alice'` in the username field.
- Enter `'alice@example.com'` in the email field.
- Enter `'Password1!'` in the password field.
- Tap the submit (`FilledButton`) button.
- Pump the widget tree.

**Expect:**
- No `TextFormField` error text is visible (no `errorText` widget found anywhere in the tree).
- `CreateUserCubit.submit` is called exactly once with
  `NewUserData(name: 'Alice Example', username: 'alice', email: 'alice@example.com', password: 'Password1!')`.
- Side effects: none (Cubit state remains `CreateUserIdle` — listener fires no navigation).

### Scenario 2: Cubit emits CreateUserSubmitting — button is disabled and spinner is shown

**Setup:**
- Mock Cubit emits `CreateUserSubmitting` via the broadcast stream after initial pump.

**Act:**
- Pump `CreateUserScreen` with the mock Cubit in initial `CreateUserIdle` state.
- Push `CreateUserSubmitting` onto the broadcast stream.
- Pump the widget tree to process the state change.

**Expect:**
- The `FilledButton` has `onPressed == null` (the button is disabled).
- A `CircularProgressIndicator` is present in the widget tree.
- No validation error text is present below the button.
- The four `TextFormField` widgets are still rendered (the form did not disappear).

## Out of scope for this test

- Server responses and HTTP status codes (not part of this refactor; already covered
  by 0043's outside-in test and the `create_user_adapter` unit tests).
- Route navigation on success (covered by existing `create_user_screen_test.dart`
  which must stay green without modification — see F12 / M13).
- Individual validator failure paths for each field (covered by the widget tests
  added alongside this refactor, per the plan — M1 through M6 in validation.md).
- `CreateUserValidationError` rendering (covered by widget tests — M11, M12).
- `_CreateUserForm` and `_SubmitSection` as private classes (they are not directly
  instantiable from tests; all assertions go through `CreateUserScreen`).
