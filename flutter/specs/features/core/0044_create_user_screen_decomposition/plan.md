# Plan 0044 — CreateUserScreen Widget Decomposition

## Overview

A pure presentation refactor of a single file. Extracts two private `StatelessWidget`
classes from `create_user_screen.dart` to reduce `_CreateUserScreenState.build()` CC
from 16 to 5. No new Cubit, no new port, no new adapter, no new route, no i18n changes.

The structural pattern being applied is identical to what slice 0043 did for
`PostDetailsScreen` (`_PostDetailsActions`, `_PostDetailsBody`) and `UserDetailsScreen`
(`_UserDetailsAppBarActions`): when `build()` owns two or more structurally independent
responsibilities, each becomes its own private `StatelessWidget`.

---

## READ before implementing

- `@CLAUDE.md` — hard rules, stack, verification steps
- `@lib/features/users/create_user/presentation/create_user_screen.dart` — the only file being modified
- `@test/features/users/create_user/presentation/create_user_screen_test.dart` — existing tests that must stay green
- `@lib/features/users/create_user/application/create_user_state.dart` — for `CreateUserSubmitting`, `CreateUserValidationError`
- `@lib/features/posts/post_details/presentation/post_details_screen.dart` — reference: `_PostDetailsBody` internal `BlocBuilder` pattern

DO NOT READ other slices, core/, or any file not listed above.

---

## Step 1 — Extract `_CreateUserForm`

**File:** `lib/features/users/create_user/presentation/create_user_screen.dart`

Add a new private `StatelessWidget` at the bottom of the file:

```dart
class _CreateUserForm extends StatelessWidget {
  const _CreateUserForm({
    required this.nameController,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(labelText: t.users.create.name),
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return t.users.create.errors.required;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: usernameController,
          decoration: InputDecoration(labelText: t.users.create.username),
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return t.users.create.errors.required;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          decoration: InputDecoration(labelText: t.users.create.email),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return t.users.create.errors.required;
            }
            if (!_emailRegex.hasMatch(v.trim())) {
              return t.users.create.errors.emailInvalid;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          decoration: InputDecoration(labelText: t.users.create.password),
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onFieldSubmitted: (_) {
            if (!isSubmitting) onSubmit();
          },
          validator: (v) {
            if (v == null || v.isEmpty) {
              return t.users.create.errors.required;
            }
            if (v.length < 8) {
              return t.users.create.errors.passwordTooShort;
            }
            return null;
          },
        ),
      ],
    );
  }
}
```

Key decisions:
- `_emailRegex` moves from `_CreateUserScreenState` into `_CreateUserForm`.
- `build()` returns a `Column`, not a `Form` — the `Form` widget and `_formKey` stay in `_CreateUserScreenState`.
- No Cubit import or reference in this class.

---

## Step 2 — Extract `_SubmitSection`

Add a second private `StatelessWidget` at the bottom of the file:

```dart
class _SubmitSection extends StatelessWidget {
  const _SubmitSection({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocBuilder<CreateUserCubit, CreateUserState>(
      builder: (context, state) {
        final isSubmitting = state is CreateUserSubmitting;
        final validationMessage =
            state is CreateUserValidationError ? state.message : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.users.create.submit),
            ),
            if (validationMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  validationMessage,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
```

Key decisions:
- Internal `BlocBuilder` is the only Cubit dependency — mirrors `_PostDetailsBody` from 0043.
- Constructor receives only `onSubmit`; all Cubit-derived values are read internally.
- Uses `Column` with `crossAxisAlignment: CrossAxisAlignment.stretch` so `FilledButton`
  fills the available width (same visual result as placing it directly in the `ListView`).

---

## Step 3 — Simplify `_CreateUserScreenState.build()`

Replace the current `builder` closure of `BlocConsumer` with:

```dart
builder: (context, state) {
  final isSubmitting = state is CreateUserSubmitting;
  return Scaffold(
    appBar: AppBar(title: Text(t.users.create.title)),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CreateUserForm(
            nameController: _nameController,
            usernameController: _usernameController,
            emailController: _emailController,
            passwordController: _passwordController,
            isSubmitting: isSubmitting,
            onSubmit: () => _submit(context),
          ),
          const SizedBox(height: 32),
          _SubmitSection(onSubmit: () => _submit(context)),
        ],
      ),
    ),
  );
},
```

Remove the `_emailRegex` static field from `_CreateUserScreenState` (it moved to
`_CreateUserForm`). The `_submit` method, four controllers, and `_formKey` remain in
`_CreateUserScreenState` unchanged. The `listener` switch is unchanged.

Resulting CC of `_CreateUserScreenState.build()`:
- Base: 1
- `isSubmitting` bool derivation: 0 (assignment, not branch)
- Listener switch: Success, Conflict, Failure, default = 4 branches counted at listener, not builder
- Builder: 0 branches
- **Total CC of build(): 5**

---

## Step 4 — Tests

**Location:** `test/features/users/create_user/presentation/`

### 4a. Existing: `create_user_screen_test.dart` — must stay green

Run existing tests after the refactor with no modifications. They verify end-to-end
rendering and are the primary regression guard.

### 4b. New: `_CreateUserForm` validator tests (via `CreateUserScreen`)

Pump `CreateUserScreen` with a `MockCreateUserCubit` in `CreateUserIdle` state.

Cover:
- Empty name field + tap submit → `t.users.create.errors.required` error text on name field.
- Invalid email (no @) + tap submit → `t.users.create.errors.emailInvalid` error text on email field.
- Password shorter than 8 chars + tap submit → `t.users.create.errors.passwordTooShort` error text.
- All fields valid + tap submit → no error text on any field; verify `cubit.submit` called.
- Password `Done` keyboard action (not submitting) → `cubit.submit` called.

### 4c. New: `_SubmitSection` state rendering tests (via `CreateUserScreen`)

Pump `CreateUserScreen` with a `MockCreateUserCubit` that emits each relevant state.

Cover:
- `CreateUserSubmitting` → `FilledButton.onPressed` is null (button disabled);
  `CircularProgressIndicator` present; no validation error text.
- `CreateUserValidationError(message: 'Username taken')` → `FilledButton.onPressed`
  is not null (button enabled); `Text('Username taken')` present.
- Transition from `CreateUserValidationError` back to `CreateUserIdle` →
  validation error text is gone.

---

## Files changed (summary)

| File | Change type |
|---|---|
| `lib/features/users/create_user/presentation/create_user_screen.dart` | Modify — extract `_CreateUserForm` and `_SubmitSection`; simplify `build()` |
| `test/features/users/create_user/presentation/create_user_screen_test.dart` | Modify — add validator and state-rendering tests; existing tests unchanged |

No other files change. No codegen step needed (no `@freezed`, `@injectable`, or `@RestApi`
annotations in the modified file).

---

## DO NOT

- Add a new route, screen, Cubit, port, or adapter.
- Move the `Form` widget or `_formKey` into `_CreateUserForm`.
- Add a Cubit dependency to `_CreateUserForm`.
- Pass `CreateUserState` as a parameter to `_SubmitSection` — it reads state internally.
- Modify `CreateUserCubit`, `CreateUserState`, `CreateUserUseCase`, or `CreateUserAdapter`.
- Modify any file outside `create_user/presentation/`.
- Run `build_runner` — no codegen-annotated files are touched.

---

## Verification

```
dart format . --set-exit-if-changed
dart analyze --fatal-infos
flutter test test/features/users/create_user/presentation/
```

All tests green. `dart analyze` zero warnings. `dart format` no diff.
