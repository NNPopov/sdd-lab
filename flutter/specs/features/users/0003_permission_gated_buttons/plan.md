# Plan: permission_gated_buttons — agent prompt

## Task

Adjust the visibility rules for the Delete and Erase buttons on `user_details_screen`
and add permission checks in use-cases.

Rules after the task:
- Delete button → only `isMe`
- Erase button → only `isSuperuser` (via `Permission.eraseUsers`)
- Use-case `DeleteUserUseCase` → checks account ownership
- Use-case `EraseDbUserUseCase` → checks `isSuperuser`

**This is a modification of existing code, not a new slice.**
All files to be modified are already implemented.

---

## CONTEXT

### READ:
- `@CLAUDE.md` — fully (§7 RBAC, §8 errors, dependency rules)
- `@lib/core/rbac/permission.dart` — add `eraseUsers`
- `@lib/core/rbac/role_policy.dart` — verify that admin gets eraseUsers automatically
- `@lib/core/auth/domain/entities/current_user.dart` — field `isSuperuser`
- `@lib/core/auth/application/auth_cubit.dart` — getter `currentUser`
- `@lib/core/errors/failure.dart` — `Failure.permissionDenied()`
- `@lib/features/users/delete_user/domain/ports/delete_user_port.dart`
- `@lib/features/users/delete_user/domain/usecases/delete_user_usecase.dart`
- `@lib/features/users/delete_user/application/delete_user_cubit.dart`
- `@lib/features/users/erase_db_user/domain/ports/erase_db_user_port.dart`
- `@lib/features/users/erase_db_user/domain/usecases/erase_db_user_usecase.dart`
- `@lib/features/users/erase_db_user/application/erase_db_user_cubit.dart`
- `@lib/features/users/user_details/presentation/user_details_screen.dart`
- `@test/features/users/delete_user/application/delete_user_cubit_test.dart`
- `@test/features/users/erase_db_user/application/erase_db_user_cubit_test.dart`

### DO NOT READ:
- `lib/features/users/list_users/**`
- `lib/features/users/create_user/**`
- `lib/features/users/edit_user/**`
- `lib/features/users/delete_user/data/**` — adapter is not changing
- `lib/features/users/erase_db_user/data/**` — adapter is not changing
- `lib/core/rbac/permission_cubit.dart` — not changing
- `**/*.gr.dart`, `**/*.config.dart`, `**/*.freezed.dart`, `**/*.g.dart`

---

## API

No API changes. All modifications are client-side only.

---

## WHAT TO DO

### 1) `lib/core/rbac/permission.dart` — add `eraseUsers`

```dart
enum Permission {
  viewCatalog,
  editCatalog,
  viewUsers,
  editUsers,
  viewReports,
  eraseUsers,  // new: admin gets it automatically via {...Permission.values}
}
```

`kRolePolicy` in `role_policy.dart` **do not change** —
`UserRole.admin` already uses `{...Permission.values}`, so `eraseUsers`
will enter the admin policy automatically.

`PermissionCubit` **do not change** — it already emits
`kRolePolicy[UserRole.admin]!` for superusers.

### 2) `lib/features/users/delete_user/domain/usecases/delete_user_usecase.dart`

Change `call` signature to named params + add ownership check:

```dart
Future<Either<Failure, Unit>> call({
  required String username,
  required String currentUsername,
}) async {
  if (username != currentUsername) return Left(Failure.permissionDenied());
  return _port(username);
}
```

**The port (`DeleteUserPort`) is NOT changed** — the permission check lives in the use-case,
not in the adapter.

### 3) `lib/features/users/delete_user/application/delete_user_cubit.dart`

In the `confirmAndDelete` method, pass `currentUsername`:

```dart
Future<void> confirmAndDelete(String username) async {
  emit(const DeleteUserState.deleting());
  final result = await _deleteUser(
    username: username,
    currentUsername: _authCubit.currentUser?.username ?? '',
  );
  await result.fold(
    (f) async => emit(DeleteUserState.failure(f)),
    (_) async {
      await _authCubit.forceLogout(notifyUser: false);
      emit(const DeleteUserState.success());
    },
  );
}
```

Empty string `''` as fallback: if `currentUser == null`,
the use-case will return `PermissionDenied` — correct behavior for
an unauthenticated state.

### 4) `lib/features/users/erase_db_user/domain/usecases/erase_db_user_usecase.dart`

Change `call` signature + add isSuperuser check:

```dart
Future<Either<Failure, Unit>> call({
  required String username,
  required bool isSuperuser,
}) async {
  if (!isSuperuser) return Left(Failure.permissionDenied());
  return _port(username);
}
```

**The port (`EraseDbUserPort`) is NOT changed.**

### 5) `lib/features/users/erase_db_user/application/erase_db_user_cubit.dart`

In the `confirmAndDelete` method, pass `isSuperuser`:

```dart
Future<void> confirmAndDelete(String username) async {
  emit(const EraseDbUserState.deleting());
  final result = await _eraseDbUser(
    username: username,
    isSuperuser: _authCubit.currentUser?.isSuperuser ?? false,
  );
  await result.fold(
    (f) async => emit(EraseDbUserState.failure(f)),
    (_) async {
      await _authCubit.forceLogout(notifyUser: false);
      emit(const EraseDbUserState.success());
    },
  );
}
```

`false` as fallback: if `currentUser == null`,
the use-case will return `PermissionDenied` — correct behavior.

### 6) `lib/features/users/user_details/presentation/user_details_screen.dart`

Change the conditional rendering logic for buttons inside nested `BlocBuilder`s.

**BEFORE:** a single `if (!isMe && !canEdit) return SizedBox.shrink()`,
then a Row with [Edit, Delete, Erase] — all three always together.

**AFTER:** each button shown by its own condition.
Structure (pseudocode):

```dart
BlocBuilder<PermissionCubit, Set<Permission>>(
  builder: (context, permissions) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isMe = authState is AuthAuthenticated &&
            authState.currentUser?.username == widget.username;
        final canEdit = permissions.contains(Permission.editUsers);
        final canErase = permissions.contains(Permission.eraseUsers);

        final showEdit = isMe || canEdit;
        final showDelete = isMe;
        final showErase = canErase;

        if (!showEdit && !showDelete && !showErase) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showEdit)
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: t.users.edit.title,
                onPressed: () async { /* ... as before ... */ },
              ),
            if (showDelete)
              DeleteAccountButton(username: widget.username),
            if (showErase)
              EraseDbUserButton(username: widget.username),
          ],
        );
      },
    );
  },
)
```

Import of `Permission` is already present — only add a reference to `Permission.eraseUsers`.

---

## TESTS

### a) NEW: `test/features/users/delete_user/domain/usecases/delete_user_usecase_test.dart`

Create (analogous to `create_user_usecase_test.dart`):

- success (username == currentUsername): port called → `Right(unit)`
- permission denied (username != currentUsername): port **not called** → `Left(PermissionDenied)`

### b) UPDATE: `test/features/users/delete_user/application/delete_user_cubit_test.dart`

Changes:
1. In `setUp` add stub for `authCubit.currentUser`:
   ```dart
   when(() => authCubit.currentUser).thenReturn(
     const CurrentUser(username: 'testuser', email: '', name: '', isSuperuser: false),
   );
   ```
2. Update `when(() => deleteUser(any()))` to named parameters:
   ```dart
   when(
     () => deleteUser(
       username: any(named: 'username'),
       currentUsername: any(named: 'currentUsername'),
     ),
   ).thenAnswer(...)
   ```
3. Add new test case in the `confirmAndDelete` group:
   ```
   'emits [deleting, failure(PermissionDenied)] when use-case returns PermissionDenied'
   ```

### c) NEW: `test/features/users/erase_db_user/domain/usecases/erase_db_user_usecase_test.dart`

Create:

- success (isSuperuser == true): port called → `Right(unit)`
- permission denied (isSuperuser == false): port **not called** → `Left(PermissionDenied)`

### d) UPDATE: `test/features/users/erase_db_user/application/erase_db_user_cubit_test.dart`

Changes:
1. In `setUp` add stub:
   ```dart
   when(() => authCubit.currentUser).thenReturn(
     const CurrentUser(username: 'testuser', email: '', name: '', isSuperuser: true),
   );
   ```
2. Update `when(() => eraseDbUser(any()))` to named parameters:
   ```dart
   when(
     () => eraseDbUser(
       username: any(named: 'username'),
       isSuperuser: any(named: 'isSuperuser'),
     ),
   ).thenAnswer(...)
   ```
3. Add new test case:
   ```
   'emits [deleting, failure(PermissionDenied)] when use-case returns PermissionDenied'
   ```

---

## REPORT

On completion provide:

- List of modified files (with description of what changed)
- List of new files (use-case tests)
- Confirmation that adapters, ports, `kRolePolicy`, `PermissionCubit` **were not changed**
- Confirmation that `list_users`, `create_user`, `edit_user` are not affected
- Result of `dart analyze` — zero errors
- Result of `flutter test` — all tests green
- UX walkthrough: see validation.md

---

## WHAT NOT TO DO

- ❌ Do NOT change `DeleteUserPort` and `EraseDbUserPort` — ports remain with `call(String username)`
- ❌ Do NOT change adapters — permission logic is not in the data layer
- ❌ Do NOT change `kRolePolicy` — admin already gets all permissions
- ❌ Do NOT change `PermissionCubit` — it already correctly maps `isSuperuser → admin`
- ❌ Do NOT check `isSuperuser` directly from `AuthCubit` in the UI — use `permissions.contains(Permission.eraseUsers)` for consistency
- ❌ Do NOT add the Erase button to `list_users`
- ❌ Do NOT give the superuser a Delete button on another user's profile — Erase is the stronger operation
- ❌ Do NOT delete existing test cases in cubit tests — only update mock signatures and add new cases
