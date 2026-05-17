# 0002 · PermissionCubit — Implementation Plan (Agent Prompt)

## Task

Create `PermissionCubit` in `core/rbac/`, subscribed to `AuthCubit`,
reactively emitting the current user's `Set<Permission>` based on the
`isSuperuser` flag from `CurrentUser`.
Wire `PermissionCubit` into DI and the widget tree.
Use the resulting permissions on the `UserDetailsScreen`.

---

## CONTEXT

### READ:

- `@CLAUDE.md` — in full (architecture, DI rules §3, RBAC §7)
- `@lib/core/auth/application/auth_cubit.dart` — stream, CurrentUser
- `@lib/core/auth/application/auth_state.dart` — AuthAuthenticated, currentUser
- `@lib/core/auth/domain/entities/current_user.dart` — isSuperuser field
- `@lib/core/auth/data/dto/current_user_dto.dart` — confirm isSuperuser is already present (it is)
- `@lib/core/rbac/permission.dart` — enum Permission
- `@lib/core/rbac/role.dart` — enum UserRole
- `@lib/core/rbac/role_policy.dart` — kRolePolicy
- `@lib/features/users/user_details/presentation/user_details_screen.dart` — where the permission check will be added
- `@lib/main.dart` — where PermissionCubit will be provided

### DO NOT READ:

- `lib/features/users/list_users/**` — not needed for this task
- `lib/features/users/create_user/**`
- `lib/features/users/edit_user/**`
- `lib/features/users/delete_user/**`
- `lib/core/di/injection.config.dart` — generated, do not edit manually

---

## API

No API changes. `GET /api/v1/user/me/` already returns `is_superuser`.

Full response (for reference):
```json
{
  "id": 0,
  "name": "User Userson",
  "username": "userson",
  "email": "user.userson@example.com",
  "profile_image_url": "string",
  "tier_id": 0,
  "is_superuser": true
}
```

`CurrentUserDto` and `CurrentUser` already support `isSuperuser` — DO NOT MODIFY these files.

---

## TARGET STRUCTURE

New files:

```
lib/core/rbac/
├── permission.dart          (exists, do not modify)
├── role.dart                (exists, do not modify)
├── role_policy.dart         (exists, do not modify)
├── permission_cubit.dart    ← NEW
└── permission_state.dart    ← NEW (optional, can be inlined in cubit)
```

Existing files to modify:

```
lib/main.dart                ← add BlocProvider<PermissionCubit>
lib/features/users/user_details/presentation/user_details_screen.dart
                             ← use Permission.editUsers
```

---

## WHAT TO DO

### 1) `lib/core/rbac/permission_cubit.dart`

Create `PermissionCubit extends Cubit<Set<Permission>>`:

```dart
@lazySingleton
class PermissionCubit extends Cubit<Set<Permission>> {
  PermissionCubit(this._auth) : super(kRolePolicy[UserRole.guest]!) {
    _sub = _auth.stream.listen(_onAuthState);
    // recalculate immediately from current state
    _onAuthState(_auth.state);
  }

  final AuthCubit _auth;
  late final StreamSubscription<AuthState> _sub;

  void _onAuthState(AuthState state) {
    final permissions = switch (state) {
      AuthAuthenticated(:final currentUser) when currentUser?.isSuperuser == true
          => kRolePolicy[UserRole.admin]!,
      AuthAuthenticated() => kRolePolicy[UserRole.user]!,
      _ => kRolePolicy[UserRole.guest]!,
    };
    emit(Set.unmodifiable(permissions));
  }

  bool has(Permission permission) => state.contains(permission);

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
```

**IMPORTANT:** `_onAuthState` is called immediately in the constructor (recalculate
from current state) and on every `AuthCubit` state change. This guarantees that
`PermissionCubit` is always up to date, even if created after `AuthCubit` has already
transitioned to `AuthAuthenticated`.

`permission_state.dart` is not needed — the state is simply `Set<Permission>`.

### 2) `lib/main.dart`

Add `BlocProvider<PermissionCubit>` to the tree alongside `BlocProvider<AuthCubit>`.
Order matters: `AuthCubit` must be above `PermissionCubit` in the tree
(because `PermissionCubit` receives `AuthCubit` via DI, not via `context`).

`PermissionCubit` is taken from DI: `getIt<PermissionCubit>()`.

Example (adapt to the actual `main.dart`):

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => getIt<AuthCubit>()),
    BlocProvider(create: (_) => getIt<PermissionCubit>()),
  ],
  child: AppWidget(),
)
```

### 3) Run codegen

After adding `@lazySingleton` to `PermissionCubit`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4) `lib/features/users/user_details/presentation/user_details_screen.dart`

Update the condition controlling visibility of the Edit / Delete / EraseDb buttons:

```dart
// BEFORE:
final isMe = authState is AuthAuthenticated &&
    authState.currentUser?.username == widget.username;
if (!isMe) return const SizedBox.shrink();

// AFTER:
final isMe = authState is AuthAuthenticated &&
    authState.currentUser?.username == widget.username;
final canEdit = context.read<PermissionCubit>().has(Permission.editUsers);
if (!isMe && !canEdit) return const SizedBox.shrink();
```

**IMPORTANT:** `context.read<PermissionCubit>()` is used inside a `BlocBuilder`
callback (a callback context, not the `build` method directly) — this is correct
per flutter_bloc rules.

However, if buttons must react to live permission changes (e.g., session expiry)
— use `BlocBuilder<PermissionCubit, Set<Permission>>` instead of `context.read`.
Use `BlocBuilder`.

Final logic:

```dart
BlocBuilder<PermissionCubit, Set<Permission>>(
  builder: (context, permissions) {
    BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isMe = authState is AuthAuthenticated &&
            authState.currentUser?.username == widget.username;
        final canEdit = permissions.contains(Permission.editUsers);
        if (!isMe && !canEdit) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(...),
            DeleteAccountButton(username: widget.username),
            if (isMe || permissions.contains(Permission.editUsers))
              EraseDbUserButton(username: widget.username),
          ],
        );
      },
    );
  },
)
```

Adapt to the actual code structure in the file.

---

## TESTS

```
test/core/rbac/permission_cubit_test.dart
```

Cover:

a) **Initial state**
   - With `AuthUnknown` (initial state of `AuthCubit`) → `Set == kRolePolicy[UserRole.guest]`

b) **Superuser**
   - With `AuthAuthenticated(currentUser: CurrentUser(isSuperuser: true, ...))`
     → `Set == kRolePolicy[UserRole.admin]` (all permissions)
   - `has(Permission.editUsers)` returns `true`

c) **Regular user**
   - With `AuthAuthenticated(currentUser: CurrentUser(isSuperuser: false, ...))`
     → `Set == kRolePolicy[UserRole.user]`
   - `has(Permission.editUsers)` returns `false`
   - `has(Permission.viewCatalog)` returns `true`

d) **Logout**
   - After `AuthAuthenticated` → `AuthUnauthenticated`
     → `Set == kRolePolicy[UserRole.guest]`

e) **null currentUser**
   - `AuthAuthenticated(currentUser: null)` → guest permissions

Use `MockAuthCubit extends MockCubit<AuthState> implements AuthCubit`
via `mocktail`. Control the stream via `StreamController<AuthState>`.

---

## REPORT

Upon completion, provide:

- List of files created
- List of files modified
- Confirmation that `injection.config.dart` was updated after codegen
- Result: `has(Permission.editUsers)` returns `true` for superuser,
  `false` for regular user
- Tests: number of new tests, all green
- Confirmation that other slices (`list_users`, `create_user`, etc.) were NOT touched

---

## WHAT NOT TO DO

- ❌ DO NOT add `isSuperuser` field to `CurrentUserDto` or `CurrentUser` — it already exists
- ❌ DO NOT create a `UserRole` field in `CurrentUser` — role is derived from `isSuperuser`
- ❌ DO NOT make `PermissionCubit` depend on `context` — only on `AuthCubit` via DI
- ❌ DO NOT check permissions via `context.read` directly in the `build` method — only in `BlocBuilder`
- ❌ DO NOT add `PermissionGuard` to routes — out of scope for this task
- ❌ DO NOT create a `PermissionBuilder` widget — out of scope for this task
- ❌ DO NOT modify `kRolePolicy` — the policy is defined, use it as-is
- ❌ DO NOT edit `injection.config.dart` manually — only via codegen
