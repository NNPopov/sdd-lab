# PRD 0044 — CreateUserScreen Widget Decomposition

## Problem Statement

After slice 0043, `_CreateUserScreenState.build()` remains the sole ALARM-level method
in the `dart_code_linter:metrics` report (CC 16, SLOC 127). The sealed-state and
flat-listener work from 0043 was complete and correct, but 0043 applied widget
decomposition only to `PostDetailsScreen` and `UserDetailsScreen` — not to
`CreateUserScreen`. The omission was an oversight in 0043's scope, not a property of
the problem.

The CC 16 is not fictional lint noise: it traces to two structurally distinct
responsibilities that live inside a single `build()` method:

1. **Four `TextFormField` validators** — six decision points for empty/format/length
   checks that are pure functions of the field value and have no dependency on Cubit
   state or widget lifecycle.
2. **Submit button and server-error display** — five decision points for loading
   indicator, disabled state, and `CreateUserValidationError` text rendered below the
   button — all driven by `CreateUserCubit` state.

Both groups are currently inlined inside the `BlocConsumer.builder` closure, which
makes `build()` the unit of CC measurement for all of them. Extracting them to
separate `StatelessWidget` subclasses shifts each group's CC to its own `build()`
method — the same structural move 0043 made for `_PostDetailsActions` and
`_PostDetailsBody`.

## Solution

Extract two private `StatelessWidget` classes from `create_user_screen.dart`:

- **`_CreateUserForm`** — owns the `Form`'s four `TextFormField` children (name,
  username, email, password) with their validators and `onFieldSubmitted` callbacks.
  Receives controllers, a loading flag, and a submit callback as constructor
  parameters. Contains no Cubit dependency.

- **`_SubmitSection`** — owns the `FilledButton` with its loading indicator and the
  `CreateUserValidationError` text block. Reads `CreateUserCubit` state via an
  internal `BlocBuilder` to derive `isSubmitting` and `validationMessage`. Receives a
  submit callback as a constructor parameter.

After extraction, `_CreateUserScreenState.build()` becomes a skeleton: `Scaffold` →
`Form` → `ListView` → `[_CreateUserForm, _SubmitSection]`, with `BlocConsumer`
handling only the listener switch (Success / Conflict / Failure / default). Its CC
drops from 16 to 5.

No state, no Cubit, no use-case, no adapter, no route, and no i18n key is changed.
This is a pure structural refactor of a single presentation file.

## User Stories

1. As an engineer reading `create_user_screen.dart`, I want `_CreateUserScreenState.build()`
   to contain only the screen skeleton (Scaffold, Form, BlocConsumer listener), so that I
   can understand the screen's event-handling contract in one pass without scrolling through
   field definitions.

2. As an engineer extending `CreateUserScreen` with a new field, I want to find all four
   `TextFormField` declarations inside `_CreateUserForm.build()`, so that field addition is
   a localised change in one widget class.

3. As an engineer reading the submit logic, I want `_SubmitSection.build()` to own the
   `FilledButton` state and the validation-error display, so that loading and error rendering
   are collocated and readable in isolation.

4. As an engineer running `dart_code_linter:metrics`, I want `_CreateUserScreenState.build()`
   to have CC ≤ 5 after this refactor, so that the ALARM is eliminated and the report
   reflects genuine structural debt rather than incidental colocation.

5. As an engineer writing a widget test for `_CreateUserForm`, I want the widget to accept
   its controllers, loading flag, and submit callback as constructor parameters, so that
   I can test validators without rendering the full screen or providing a Cubit.

6. As an engineer writing a widget test for `_SubmitSection`, I want the widget to read
   Cubit state internally via `BlocBuilder`, so that I can inject a mock Cubit and verify
   loading/error states in isolation, following the same pattern as `_PostDetailsActions`
   in slice 0043.

7. As an engineer reviewing the refactor, I want the `Form` widget and its `GlobalKey` to
   remain in `_CreateUserScreenState` (not inside `_CreateUserForm`), so that the form key
   is owned by the state that calls `_formKey.currentState!.validate()` on submit, and the
   widget tree structure is unambiguous.

8. As an engineer verifying correctness, I want the existing widget test for `CreateUserScreen`
   to pass without modification after this refactor, so that externally-observable behaviour
   is confirmed unchanged.

9. As an engineer running the full test suite, I want no regressions in any `create_user`
   unit or widget tests, so that the structural decomposition does not silently break
   behaviour verified by existing tests.

## Implementation Decisions

### _CreateUserForm

A private `StatelessWidget` placed at the bottom of `create_user_screen.dart`.

Constructor parameters:
- four `TextEditingController` instances (name, username, email, password)
- `isSubmitting: bool` — disables `onFieldSubmitted` on the password field when true
- `onSubmit: VoidCallback` — called by `onFieldSubmitted` when not submitting

`build()` returns a `Column` of four `TextFormField` widgets with the same validators,
decorations, `textInputAction`, `keyboardType`, `autofillHints`, and `obscureText`
settings as the current implementation. The `_emailRegex` static field moves into
`_CreateUserForm`.

The widget does **not** wrap its children in a `Form` widget — the `Form` stays in
`_CreateUserScreenState.build()`, as the form key is owned by the state.

### _SubmitSection

A private `StatelessWidget` placed at the bottom of `create_user_screen.dart`.

Constructor parameters:
- `onSubmit: VoidCallback` — passed through to `FilledButton.onPressed`

`build()` contains a single `BlocBuilder<CreateUserCubit, CreateUserState>` that
derives `isSubmitting` and `validationMessage` from the current state and renders:
- `FilledButton` — disabled when `isSubmitting`; child switches between
  `CircularProgressIndicator` and the submit label text
- Conditional `Padding(child: Text(validationMessage))` when state is
  `CreateUserValidationError`; nothing otherwise

The internal `BlocBuilder` is the only Cubit dependency in this widget.

### _CreateUserScreenState.build() after extraction

The `BlocConsumer.listener` is unchanged (flat switch: Success / Conflict / Failure /
default). The `BlocConsumer.builder` derives `isSubmitting` as a plain bool (not a
branch) and delegates to:

```
Scaffold → AppBar
         → Form(key: _formKey)
             → ListView
                 → _CreateUserForm(controllers…, isSubmitting, onSubmit)
                 → SizedBox(height: 32)
                 → _SubmitSection(onSubmit)
```

No ternaries remain in the builder closure. Resulting CC of `_CreateUserScreenState.build()`:
- Base: 1
- Listener switch cases (Success, Conflict, Failure, default): 4
- Builder: 0 (no branches)
- **Total: 5**

### Files changed

| File | Change |
|---|---|
| `lib/features/users/create_user/presentation/create_user_screen.dart` | Extract `_CreateUserForm` and `_SubmitSection`; simplify `_CreateUserScreenState.build()` |

No other files change.

## Testing Decisions

**What makes a good test here:** tests verify observable output — what renders in the
widget tree — not implementation details like which private class owns which field. Tests
must not depend on the internal class structure (`_CreateUserForm`, `_SubmitSection`) to
remain stable through future refactors.

### Existing tests — must stay green

The existing `CreateUserScreen` widget test (if present) drives the full screen with a
mock Cubit and verifies end-to-end rendering. It must pass without modification, confirming
the refactor did not change any externally-observable behaviour.

Prior art: `test/features/users/create_user/presentation/create_user_screen_test.dart`
(established in 0043).

### New: `_CreateUserForm` widget test

Because `_CreateUserForm` is a private class, it is tested through the public screen.
Drive `CreateUserScreen` with a mock `CreateUserCubit` in the idle state and verify:

- Tapping submit with an empty name field shows the required-field error on that field.
- Tapping submit with an invalid email shows the email-format error.
- Tapping submit with a password shorter than 8 characters shows the too-short error.
- Tapping submit with all fields valid does not show any field-level error text.
- Submitting with the password keyboard action (Done) while not submitting calls the
  Cubit's `submit` method.

These tests verify validator behaviour from the outside, not validator implementation.

### New: `_SubmitSection` widget test

Because `_SubmitSection` is a private class, it is tested through the public screen.
Drive `CreateUserScreen` with a mock Cubit that emits each relevant state:

- `CreateUserSubmitting` → submit button is disabled; `CircularProgressIndicator`
  is present; no error text.
- `CreateUserValidationError(message: 'Username taken')` → submit button is enabled;
  error text 'Username taken' appears below the button.
- `CreateUserIdle` after `CreateUserValidationError` → error text is gone.

Prior art: `_PostDetailsActions` and `_PostDetailsBody` widget tests from slice 0043.

## Out of Scope

- Changes to `CreateUserCubit`, `CreateUserState`, `CreateUserUseCase`, or
  `CreateUserAdapter` — this slice is presentation-only.
- Changes to any other screen, adapter, or Cubit.
- Extracting the `BlocConsumer.listener` to a named method — doing so would reduce CC
  by an additional 4 points but is a separate micro-decision with diminishing returns
  once CC is already at 5.
- Raising the `dart_code_linter` CC threshold — the threshold is 10 and the post-refactor
  CC of 5 is well inside it.
- `_CreateUserScreenState` SLOC reduction beyond what falls naturally from the extraction.

## Further Notes

- This slice applies exactly the same structural tool that 0043 applied to
  `PostDetailsScreen` (extracting `_PostDetailsActions` and `_PostDetailsBody`) and to
  `UserDetailsScreen` (extracting `_UserDetailsAppBarActions`). The pattern is now
  established in this codebase: when `build()` contains two or more structurally
  independent responsibilities, each becomes its own private `StatelessWidget`.
- The `Form` widget stays in `_CreateUserScreenState` — not in `_CreateUserForm` — for
  the same reason `_PostDetailsScreenState` kept its `initState` load call rather than
  pushing it into the extracted body widget: the lifecycle owner stays with the
  `State` class.
- `_CreateUserForm` has no Cubit dependency. This makes its validators fully testable as
  pure functions of field values, with no mock setup required for the Cubit layer.
- `_SubmitSection` has a Cubit dependency via `BlocBuilder`. This mirrors `_PostDetailsBody`
  from 0043, which also had an internal `BlocBuilder` for `PostDetailsCubit`. Both follow
  the rule that a widget with a single reactive dependency reads it internally rather than
  receiving raw state as a parameter.
