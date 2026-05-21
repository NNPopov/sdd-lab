# Plan 0043 — build() CC/Nesting Decomposition

## Overview

A cross-cutting refactor touching `core/errors/`, three adapters, two Cubits, and four
screens. The changes must land atomically in one commit because the `ValidationFailure`
type change is a breaking change to the `Failure` sealed class.

**No new slice folders. No new routes. No new Cubits.** Every change modifies an
existing file or adds a small supporting file for testability.

---

## READ before implementing

- `@CLAUDE.md` — hard rules, stack, verification steps
- `@lib/core/errors/failure.dart` — the type being restructured
- `@lib/features/users/create_user/application/create_user_state.dart`
- `@lib/features/users/create_user/application/create_user_cubit.dart`
- `@lib/features/users/create_user/presentation/create_user_screen.dart`
- `@lib/features/users/create_user/data/create_user_adapter.dart`
- `@lib/features/tiers/create_tier/data/create_tier_adapter.dart`
- `@lib/features/tiers/create_tier/presentation/create_tier_screen.dart`
- `@lib/features/users/edit_user/data/update_user_adapter.dart`
- `@lib/features/users/edit_user/domain/usecases/update_user_usecase.dart`
- `@lib/features/users/edit_user/presentation/edit_user_screen.dart`
- `@lib/features/users/user_details/presentation/user_details_screen.dart`
- `@lib/features/posts/post_details/presentation/post_details_screen.dart`
- `@lib/core/rbac/permission.dart`
- `@lib/core/auth/application/auth_cubit.dart`
- `@lib/core/auth/application/auth_state.dart`
- `@lib/features/posts/post_details/application/post_details_state.dart`
- `@test/features/users/create_user/application/create_user_cubit_test.dart`

DO NOT READ other slices not listed above.

---

## Step 1 — ValidationFailure sealed hierarchy (breaking, enables everything else)

**File:** `lib/core/errors/failure.dart`

Replace the single `ValidationFailure` factory with a sealed sub-hierarchy.
`ValidationFailure` becomes an abstract sealed class that extends `Failure`;
two concrete subclasses replace it.

**Before:**
```dart
const factory Failure.validation({
  required Map<String, String> fieldErrors,
}) = ValidationFailure;
```

**After:**
```dart
// remove the factory above; add below Failure's closing brace:

sealed class ValidationFailure extends Failure {
  const ValidationFailure();
}

final class FieldValidationFailure extends ValidationFailure {
  const FieldValidationFailure({required this.fields});
  final Map<String, String> fields;
}

final class MessageValidationFailure extends ValidationFailure {
  const MessageValidationFailure({required this.message});
  final String message;
}
```

`ValidationFailure` is declared outside the `@freezed` class so it does not go through
`freezed`. It extends `Failure` directly (Failure is sealed; subclasses in the same
library are allowed). The two concrete classes carry their fields as plain `final`
fields — no `freezed` generation needed, no `copyWith` needed.

After this change, run:
```
dart run build_runner build --delete-conflicting-outputs
```
to regenerate `failure.freezed.dart` (the `Failure.validation` factory will be removed
from generated code).

IMPORTANT: The codebase will not compile until Steps 2–6 also land. Do all steps and
then verify.

---

## Step 2 — Adapter updates

Update every call site that emits `Failure.validation(fieldErrors: {...})`.

### 2a. `lib/features/users/create_user/data/create_user_adapter.dart`

`_parseValidation` now returns `MessageValidationFailure` in all branches:

```dart
// Replace the method body:
MessageValidationFailure _parseValidation(DioException e) {
  final rawDetail = (e.response?.data as Map<String, dynamic>?)?['detail'];
  // create_user server returns a single-string detail; use it directly.
  return MessageValidationFailure(
    message: rawDetail?.toString() ?? 'Validation error',
  );
}
```

Note: the server for `create_user` returns a plain string (not a FastAPI `detail`
list), so the `List` branch is dropped — it was defensive code for a contract that
does not apply here.

### 2b. `lib/features/tiers/create_tier/data/create_tier_adapter.dart`

Same as 2a — `create_tier` server returns a single-string detail:

```dart
MessageValidationFailure _parseValidation(DioException e) {
  final rawDetail = (e.response?.data as Map<String, dynamic>?)?['detail'];
  return MessageValidationFailure(
    message: rawDetail?.toString() ?? 'Validation error',
  );
}
```

### 2c. `lib/features/users/edit_user/data/update_user_adapter.dart`

`update_user` server returns a FastAPI `detail` list (per-field errors).
Keep the existing list-parsing logic, but return `FieldValidationFailure`:

```dart
FieldValidationFailure _parseValidation(DioException e) {
  final rawDetail = (e.response?.data as Map<String, dynamic>?)?['detail'];
  if (rawDetail is List) {
    final fields = <String, String>{};
    for (final item in rawDetail) {
      if (item is Map<String, dynamic>) {
        final loc = item['loc'] as List?;
        final field = loc != null && loc.length > 1
            ? loc.last.toString()
            : 'error';
        fields[field] = item['msg']?.toString() ?? '';
      }
    }
    return FieldValidationFailure(fields: fields);
  }
  // Fallback: treat unparseable response as a form-level error.
  return FieldValidationFailure(
    fields: {'_form': rawDetail?.toString() ?? 'Validation error'},
  );
}
```

### 2d. `lib/features/users/edit_user/domain/usecases/update_user_usecase.dart`

The guard emits a `_form` key error — must remain `FieldValidationFailure` so
`EditUserForm` can route it to the form-level slot:

```dart
// Replace:
return Future.value(
  const Left(
    Failure.validation(fieldErrors: {'_form': 'Nothing to update'}),
  ),
);

// With:
return Future.value(
  const Left(
    FieldValidationFailure(fields: {'_form': 'Nothing to update'}),
  ),
);
```

---

## Step 3 — CreateUserState: add explicit variants

**File:** `lib/features/users/create_user/application/create_user_state.dart`

Add two new factory constructors. Keep `idle`, `submitting`, `success`, and `failure`
unchanged:

```dart
@freezed
sealed class CreateUserState with _$CreateUserState {
  const factory CreateUserState.idle() = CreateUserIdle;
  const factory CreateUserState.submitting() = CreateUserSubmitting;
  const factory CreateUserState.success(User user) = CreateUserSuccess;
  const factory CreateUserState.validationError({required String message}) =
      CreateUserValidationError;
  const factory CreateUserState.conflict({required String message}) =
      CreateUserConflict;
  const factory CreateUserState.failure(Failure failure) = CreateUserFailure;
}
```

Regenerate `create_user_state.freezed.dart`.

---

## Step 4 — CreateUserCubit: flat failure mapping

**File:** `lib/features/users/create_user/application/create_user_cubit.dart`

`submit()` maps failure types directly instead of bundling them into `failure(f)`:

```dart
Future<void> submit(NewUserData data) async {
  emit(const CreateUserState.submitting());
  final result = await _createUser(data);
  result.fold(
    (f) => switch (f) {
      MessageValidationFailure(:final message) =>
        emit(CreateUserState.validationError(message: message)),
      ConflictFailure(:final message) =>
        emit(CreateUserState.conflict(message: message)),
      _ => emit(CreateUserState.failure(f)),
    },
    (u) => emit(CreateUserState.success(u)),
  );
}
```

`clearError()` stays — it is still used on field `onChanged` (see Step 5).

---

## Step 5 — CreateUserScreen rewrite

**File:** `lib/features/users/create_user/presentation/create_user_screen.dart`

### Remove from `_CreateUserScreenState`:
- No local `Map<String, String> _serverErrors` existed here (that was a pre-0042
  pattern), but confirm that no `setState` calls or `_clearServerError` method exist;
  if they do, remove them.
- Remove all `onChanged` callbacks that called `clearError()`. TextFormField validators
  are pure client-side; the form re-validates naturally on submit.

### Listener becomes a flat switch:
```dart
listener: (context, state) {
  switch (state) {
    case CreateUserSuccess():
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.users.create.success)),
      );
      unawaited(context.router.maybePop());
    case CreateUserConflict(:final message):
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    case CreateUserFailure():
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.users.create.errors.generic)),
      );
    default:
      break;
  }
},
```

No nested switch. `CreateUserValidationError` has no listener case — handled in builder.
`CreateUserIdle` and `CreateUserSubmitting` fall through to `default`.

`PermissionDenied` path: the server does not return 403 for create_user (permissions
are checked in the use-case, which never calls the port if the caller lacks rights;
the adapter's 403 path is not wired for create_user). Remove the `PermissionDenied`
snackbar case. If permission-denied can occur server-side in the future, it will be
added then with a proper test.

### Builder: render validation error below button:
```dart
// Replace the BlocBuilder below FilledButton with:
BlocBuilder<CreateUserCubit, CreateUserState>(
  buildWhen: (_, s) => s is CreateUserValidationError || s is CreateUserIdle,
  builder: (context, state) {
    if (state is CreateUserValidationError) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          state.message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    return const SizedBox.shrink();
  },
),
```

### TextFormField validators: no changes needed
The current validators are already pure client-side (empty/trim/regex/length checks).
No Cubit state reads exist in the validators — verify and leave as-is.

---

## Step 6 — CreateTierScreen: update ValidationFailure match

**File:** `lib/features/tiers/create_tier/presentation/create_tier_screen.dart`

The `CreateTierState` does NOT gain new variants — it keeps `failure(Failure failure)`.
Only the match expressions change.

### Listener: replace `ValidationFailure()` with `MessageValidationFailure()`:
```dart
case CreateTierFailure(:final failure):
  switch (failure) {
    case MessageValidationFailure():
      break; // shown in builder below
    case ConflictFailure(:final message):
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    default:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.tiers.createTier.errors.generic)),
      );
  }
```

Also remove the `PermissionDenied` case if present (check current state — may have
been added in 0042; remove if it duplicates a use-case guard).

### Builder: replace `ValidationFailure` cast with `MessageValidationFailure`:
```dart
builder: (context, state) {
  if (state is CreateTierFailure &&
      state.failure is MessageValidationFailure) {
    final msg = (state.failure as MessageValidationFailure).message;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        msg,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
  return const SizedBox.shrink();
},
```

---

## Step 7 — EditUserScreen: update ValidationFailure match

**File:** `lib/features/users/edit_user/presentation/edit_user_screen.dart`

### Listener: update the combined case:
```dart
// Before:
case ValidationFailure() || ConflictFailure():
  break;

// After:
case FieldValidationFailure() || ConflictFailure():
  break;
```

### `_extractServerErrors`: update match:
```dart
Map<String, String> _extractServerErrors(Failure failure) =>
    switch (failure) {
      FieldValidationFailure(:final fields) => fields,
      ConflictFailure(:final message) => {'username': message},
      _ => const {},
    };
```

`EditUserForm` and `_clearServerError` are **unchanged**.

---

## Step 8 — UserActionVisibility value object

**New file:** `lib/features/users/user_details/presentation/user_action_visibility.dart`

```dart
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';

final class UserActionVisibility {
  const UserActionVisibility({
    required this.showEdit,
    required this.showDelete,
    required this.showErase,
    required this.canEditTier,
    required this.canManageModerators,
    required this.isMe,
  });

  final bool showEdit;
  final bool showDelete;
  final bool showErase;
  final bool canEditTier;
  final bool canManageModerators;
  final bool isMe;

  bool get showAny =>
      showEdit || showDelete || showErase || canEditTier || canManageModerators;

  static UserActionVisibility from(
    Set<Permission> permissions,
    AuthState auth,
    String username,
  ) {
    final currentUsername =
        auth is AuthAuthenticated ? auth.currentUser?.username : null;
    final isMe = currentUsername == username;
    return UserActionVisibility(
      isMe: isMe,
      showEdit: isMe,
      showDelete: isMe,
      showErase: permissions.contains(Permission.eraseUsers),
      canEditTier: permissions.contains(Permission.editUserTier),
      canManageModerators: permissions.contains(Permission.manageModerators),
    );
  }
}
```

Non-private name so it is importable from test files.

---

## Step 9 — UserDetailsScreen: extract _UserDetailsAppBarActions

**File:** `lib/features/users/user_details/presentation/user_details_screen.dart`

### Add import:
```dart
import 'package:flutter_application_1/features/users/user_details/presentation/user_action_visibility.dart';
```

### Extract AppBar actions into a private widget added at the bottom of the file:
```dart
class _UserDetailsAppBarActions extends StatelessWidget {
  const _UserDetailsAppBarActions({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final permissions = context.select<PermissionCubit, Set<Permission>>(
      (c) => c.state,
    );
    final authState = context.select<AuthCubit, AuthState>(
      (c) => c.state,
    );
    final visibility = UserActionVisibility.from(permissions, authState, username);
    if (!visibility.showAny) return const SizedBox.shrink();

    final bool? isModerator = context.select<UserDetailsCubit, bool?>(
      (c) {
        final s = c.state;
        return s is UserDetailsLoaded ? s.user.isModerator : null;
      },
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (visibility.canManageModerators && isModerator != null)
          AssignModeratorButton(
            username: username,
            isModerator: isModerator,
            onToggled: (val) =>
                context.read<UserDetailsCubit>().updateIsModerator(val),
          ),
        if (visibility.canEditTier) UpdateUserTierButton(username: username),
        if (visibility.showEdit)
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: context.t.users.edit.title,
            onPressed: () async {
              final cubit = context.read<UserDetailsCubit>();
              final router = context.router;
              final updated = await router.push<User>(
                EditUserRoute(username: username),
              );
              unawaited(cubit.load(updated?.username ?? username));
            },
          ),
        if (visibility.showDelete) DeleteAccountButton(username: username),
        if (visibility.showErase) EraseDbUserButton(username: username),
      ],
    );
  }
}
```

### Replace AppBar actions in UserDetailsScreen:
Replace the `BlocBuilder<PermissionCubit>` … `BlocBuilder<AuthCubit>` chain in
`AppBar.actions` with a single widget:
```dart
actions: [_UserDetailsAppBarActions(username: widget.username)],
```

The `BlocListener<UpdateUserTierCubit>` inside `body` is unchanged.

IMPORTANT: `IconButton.onPressed` uses `context.router` and `context.read` in a
callback — this is correct (`context.read` in callbacks is safe). Do not add `mounted`
checks inside `_UserDetailsAppBarActions` — it is a `StatelessWidget` and the guard
is not needed there. If a mounted check is desired for the async push, add it only if
the existing `user_details_screen.dart` pattern includes it.

---

## Step 10 — PostDetailsScreen: extract _PostDetailsActions and _PostDetailsBody

**File:** `lib/features/posts/post_details/presentation/post_details_screen.dart`

After extraction `_PostDetailsScreenState.build()` is:

```dart
@override
Widget build(BuildContext context) {
  final t = context.t;
  return Scaffold(
    appBar: AppBar(
      title: Text(t.posts.postDetails.title),
      actions: [
        _PostDetailsActions(username: widget.username, id: widget.id),
      ],
    ),
    body: _PostDetailsBody(username: widget.username, id: widget.id),
  );
}
```

### _PostDetailsActions (private StatelessWidget at bottom of file):
```dart
class _PostDetailsActions extends StatelessWidget {
  const _PostDetailsActions({required this.username, required this.id});

  final String username;
  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostDetailsCubit, PostDetailsState>(
      builder: (context, postState) {
        if (postState is! PostDetailsLoaded) return const SizedBox.shrink();
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final currentUser = authState is AuthAuthenticated
                ? authState.currentUser
                : null;
            final isAuthor = currentUser?.username == username;
            final isSuperuser = currentUser?.isSuperuser ?? false;
            final showErase = isSuperuser && !isAuthor;
            if (!isAuthor && !showErase) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAuthor) ...[
                  DeletePostButton(username: username, id: id),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: context.t.posts.editPost.title,
                    onPressed: () async {
                      final cubit = context.read<PostDetailsCubit>();
                      await context.router.push(
                        EditPostRoute(
                          post: postState.post,
                          username: username,
                        ),
                      );
                      unawaited(cubit.load(username, id));
                    },
                  ),
                ],
                if (showErase)
                  EraseDbPostButton(username: username, id: id),
              ],
            );
          },
        );
      },
    );
  }
}
```

### _PostDetailsBody (private StatelessWidget at bottom of file):
```dart
class _PostDetailsBody extends StatelessWidget {
  const _PostDetailsBody({required this.username, required this.id});

  final String username;
  final int id;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocBuilder<PostDetailsCubit, PostDetailsState>(
      builder: (context, state) => switch (state) {
        PostDetailsInitial() || PostDetailsLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        PostDetailsError() => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.posts.postDetails.loadError),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => unawaited(
                  context.read<PostDetailsCubit>().load(username, id),
                ),
                child: Text(t.common.retry),
              ),
            ],
          ),
        ),
        PostDetailsLoaded(:final post) => BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final currentUser = authState is AuthAuthenticated
                ? authState.currentUser
                : null;
            final isAuthor =
                post.username != null &&
                currentUser?.username == post.username;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: Theme.of(context).textTheme.titleLarge),
                  if (isAuthor) ...[
                    const SizedBox(height: 8),
                    PostStatusChip(status: post.status),
                  ],
                  if (post.mediaUrl != null) ...[
                    const SizedBox(height: 12),
                    Image.network(
                      post.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 48),
                    ),
                  ],
                  const SizedBox(height: 12),
                  MarkdownBody(data: post.text),
                  const SizedBox(height: 12),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(post.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        ),
      },
    );
  }
}
```

Both widgets are `StatelessWidget`. The `StatefulWidget` wrapper (`PostDetailsScreen`)
keeps its `initState` that loads the post.

---

## Step 11 — Tests

### 11a. `test/features/users/create_user/application/create_user_cubit_test.dart`

Update or add:

- `submit()` with `MessageValidationFailure(message: 'Username taken')` →
  emits `[CreateUserSubmitting, CreateUserValidationError(message: 'Username taken')]`
- `submit()` with `ConflictFailure(message: 'Already exists')` →
  emits `[CreateUserSubmitting, CreateUserConflict(message: 'Already exists')]`
- `submit()` with `NetworkFailure()` →
  emits `[CreateUserSubmitting, CreateUserFailure(NetworkFailure())]`
- Remove the existing test that asserts `failure` variant for `ConflictFailure` (it
  will now emit `CreateUserConflict` instead).
- `clearError()` from `CreateUserValidationError` state → emits `[CreateUserIdle]`.

### 11b. `test/features/users/create_user/application/create_user_cubit_test.dart` — adapter test update

`test/features/users/create_user/data/create_user_adapter_test.dart` — if it has a
test for 422 that asserts `Failure.validation(fieldErrors: {'error': 'msg'})`, update
the assertion to `MessageValidationFailure(message: 'msg')`.

### 11c. New: `test/features/users/user_details/presentation/user_action_visibility_test.dart`

Unit test for `UserActionVisibility.from(...)`:

- `from(permissions: {Permission.eraseUsers}, auth: AuthAuthenticated(currentUser: CurrentUser(username: 'alice', ...)), username: 'bob')` →
  `showErase: true`, `showEdit: false`, `showDelete: false`, `isMe: false`
- `from(permissions: {}, auth: AuthAuthenticated(currentUser: CurrentUser(username: 'alice', ...)), username: 'alice')` →
  `showEdit: true`, `showDelete: true`, `showErase: false`, `isMe: true`
- `from(permissions: {Permission.manageModerators}, auth: AuthUnauthenticated(), username: 'alice')` →
  `canManageModerators: true`, `isMe: false`, `showEdit: false`
- `from(permissions: {Permission.editUserTier, Permission.eraseUsers}, auth: AuthUnauthenticated(), username: 'x')` →
  `canEditTier: true`, `showErase: true`, `showAny: true`

### 11d. New/update: CreateUserScreen widget test

Location: `test/features/users/create_user/presentation/create_user_screen_test.dart`
(create if absent).

- Pump `CreateUserScreen` wrapped with `BlocProvider<CreateUserCubit>` backed by a mock.
- Emit `CreateUserValidationError(message: 'Username taken')` via cubit → assert
  `Text('Username taken')` appears in the tree; assert no `errorText` on any
  `TextFormField`.
- Emit `CreateUserConflict(message: 'Conflict')` → assert snackbar with 'Conflict'.
- Emit `CreateUserIdle` after `CreateUserValidationError` → assert error text gone.

### 11e. New: `test/features/posts/post_details/presentation/post_details_actions_test.dart`

Widget test for `_PostDetailsActions` via a friend import or by testing through
`PostDetailsScreen`. Because `_PostDetailsActions` is a private class, test it by
building `PostDetailsScreen` with a mocked `PostDetailsCubit` and `AuthCubit`:

- `PostDetailsLoaded` + `AuthAuthenticated(isAuthor: true)` → edit and delete buttons
  visible; erase button absent.
- `PostDetailsLoaded` + `AuthAuthenticated(isSuperuser: true, isAuthor: false)` →
  erase button visible; edit and delete absent.
- `PostDetailsLoading` → no action buttons.

### 11f. New: `test/features/posts/post_details/presentation/post_details_body_test.dart`

- `PostDetailsLoading` → `CircularProgressIndicator` present.
- `PostDetailsError` → retry button present.
- `PostDetailsLoaded` + `isAuthor: true` → `PostStatusChip` present.
- `PostDetailsLoaded` + `isAuthor: false` → `PostStatusChip` absent.

For all widget tests: use `MockPostDetailsCubit extends MockCubit<PostDetailsState>`
(mocktail) and provide it via `BlocProvider`.

---

## Files changed (summary)

| File | Change type |
|---|---|
| `lib/core/errors/failure.dart` | Modify — add sealed ValidationFailure subhierarchy |
| `lib/features/users/create_user/data/create_user_adapter.dart` | Modify — `MessageValidationFailure` |
| `lib/features/tiers/create_tier/data/create_tier_adapter.dart` | Modify — `MessageValidationFailure` |
| `lib/features/users/edit_user/data/update_user_adapter.dart` | Modify — `FieldValidationFailure` |
| `lib/features/users/edit_user/domain/usecases/update_user_usecase.dart` | Modify — `FieldValidationFailure` |
| `lib/features/users/create_user/application/create_user_state.dart` | Modify — add 2 variants |
| `lib/features/users/create_user/application/create_user_cubit.dart` | Modify — flat failure mapping |
| `lib/features/users/create_user/presentation/create_user_screen.dart` | Modify — flat listener, new builder |
| `lib/features/tiers/create_tier/presentation/create_tier_screen.dart` | Modify — type match update |
| `lib/features/users/edit_user/presentation/edit_user_screen.dart` | Modify — type match update |
| `lib/features/users/user_details/presentation/user_action_visibility.dart` | **New** — value object |
| `lib/features/users/user_details/presentation/user_details_screen.dart` | Modify — extract `_UserDetailsAppBarActions` |
| `lib/features/posts/post_details/presentation/post_details_screen.dart` | Modify — extract `_PostDetailsActions`, `_PostDetailsBody` |
| `test/features/users/create_user/application/create_user_cubit_test.dart` | Modify — new variants |
| `test/features/users/create_user/data/create_user_adapter_test.dart` | Modify — assertion update |
| `test/features/users/user_details/presentation/user_action_visibility_test.dart` | **New** — unit tests |
| `test/features/users/create_user/presentation/create_user_screen_test.dart` | New/modify — widget tests |
| `test/features/posts/post_details/presentation/post_details_actions_test.dart` | **New** — widget tests |
| `test/features/posts/post_details/presentation/post_details_body_test.dart` | **New** — widget tests |

---

## DO NOT

- Add new routes, screens, Cubits, or DI modules.
- Change `EditUserForm`, `EditUserCubit`, or `edit_user_state.dart` — the field
  rendering logic is correct and unchanged.
- Modify `delete_user`, `erase_db_user`, `update_user_tier`, or any other slice not
  listed above.
- Add `@visibleForTesting` to `UserActionVisibility` — it is a normal non-private class.
- Use `context.watch` inside `build()` anywhere; use `context.select` with a projector.
- Add a `mounted` check inside `_UserDetailsAppBarActions.build()` — it is a
  `StatelessWidget`; the async push callback may need one if the original pattern has it.
- Attempt to run `build_runner` for files that do not use `@freezed` or `@injectable`.

---

## Verification

```
dart run build_runner build --delete-conflicting-outputs
dart analyze --fatal-infos
dart format . --set-exit-if-changed
flutter test test/features/users/create_user/
flutter test test/features/users/user_details/
flutter test test/features/posts/post_details/
flutter test test/features/tiers/create_tier/
flutter test test/features/users/edit_user/
```

All tests green. `dart analyze` zero warnings.
