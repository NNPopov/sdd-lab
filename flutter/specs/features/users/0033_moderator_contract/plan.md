# Plan: moderator_contract (0033)

## Overview

This slice is a cross-cutting contract extension. It has no dedicated screen. It:

1. Extends the `User` and `CurrentUser` data contracts with `isModerator`.
2. Adds `Permission.manageModerators` and updates `PermissionCubit` to emit
   `moderatePosts` for moderators (currently only emitted for the admin role).
3. Adds two new API endpoints (assign / revoke moderator) to `UsersApiClient`.
4. Creates a new `moderator_contract` slice with port, use-cases, adapter, cubit,
   and a single `AssignModeratorButton` widget.
5. Extends `user_details_screen` and `UserDetailsView` with the badge and button.

---

## Task: create slice `moderator_contract` in feature `users`

**Goal:** Surface `isModerator` in data contracts, emit correct permissions, and let
superusers assign/revoke moderator status from the user-details screen.

---

## CONTEXT

### READ:
- `CLAUDE.md` — fully
- `lib/core/rbac/permission.dart` — will be modified (add `manageModerators`)
- `lib/core/rbac/role_policy.dart` — will be modified (moderator branch in cubit)
- `lib/core/rbac/permission_cubit.dart` — will be modified (moderator branch)
- `lib/core/auth/domain/entities/current_user.dart` — will be modified
- `lib/core/auth/data/dto/current_user_dto.dart` — will be modified
- `lib/features/users/_shared/domain/entities/user.dart` — will be modified
- `lib/features/users/_shared/data/dto/user_dto.dart` — will be modified
- `lib/features/users/_shared/data/users_api_client.dart` — will be modified
- `lib/features/users/user_details/presentation/user_details_screen.dart` — will be modified
- `lib/features/users/user_details/presentation/widgets/user_details_view.dart` — will be modified
- `lib/features/users/update_user_tier/**` — nearest structural analog (button widget
  without its own screen/route; adapter with double-catch; cubit with sealed state)
- `lib/core/errors/failure.dart` — verify `ConflictFailure` and `ForbiddenFailure` exist
- `.claude/skills/bloc/SKILL.md`
- `agent_docs/error_handling.md`
- `agent_docs/localization.md`

### DO NOT READ:
- `lib/features/users/delete_user/**`
- `lib/features/users/edit_user/**`
- `lib/features/users/list_users/**`
- `lib/features/users/create_user/**`
- Any `*.gr.dart` or `*.config.dart` generated files

---

## API

```
PATCH /user/{username}/assign-moderator
Header: Authorization: Bearer <token>
Body: (none)
Response 200: (no body — Future<void>)
Errors:
  403 → ForbiddenFailure   (caller is not a superuser)
  404 → NotFoundFailure    (user not found)
  409 → ConflictFailure    (user is already a moderator)

PATCH /users/{username}/revoke-moderator
Header: Authorization: Bearer <token>
Body: (none)
Response 200: (no body — Future<void>)
Errors:
  403 → ForbiddenFailure   (caller is not a superuser)
  404 → NotFoundFailure    (user not found)
  409 → ConflictFailure    (user is not a moderator, cannot revoke)
```

`ConflictFailure` and `ForbiddenFailure` already exist in `core/errors/failure.dart` —
no new variants needed.

---

## Target file tree

```
lib/features/users/moderator_contract/       ← new slice, no screen/route
├── domain/
│   ├── ports/
│   │   └── moderator_management_port.dart   # assignModerator / revokeModerator
│   └── usecases/
│       ├── assign_moderator_usecase.dart
│       └── revoke_moderator_usecase.dart
├── data/
│   └── moderator_management_adapter.dart    # implements port, double-catch
├── application/
│   ├── assign_moderator_cubit.dart          # single cubit for both assign+revoke
│   └── assign_moderator_state.dart          # sealed: initial/loading/success/error
└── presentation/
    └── widgets/
        └── assign_moderator_button.dart     # visible only with manageModerators

```

**Modified existing files (outside the new slice):**

| File | Change |
|---|---|
| `lib/core/rbac/permission.dart` | Add `manageModerators` |
| `lib/core/rbac/permission_cubit.dart` | Add moderator branch |
| `lib/core/auth/domain/entities/current_user.dart` | Add `isModerator: bool` |
| `lib/core/auth/data/dto/current_user_dto.dart` | Add `is_moderator @Default(false)` |
| `lib/features/users/_shared/domain/entities/user.dart` | Add `isModerator: bool` |
| `lib/features/users/_shared/data/dto/user_dto.dart` | Add `is_moderator @Default(false)` |
| `lib/features/users/_shared/data/users_api_client.dart` | Add two PATCH endpoints |
| `lib/features/users/user_details/presentation/user_details_screen.dart` | Add `AssignModeratorButton` |
| `lib/features/users/user_details/presentation/widgets/user_details_view.dart` | Add moderator badge |

---

## What to do

### Step 1 — Extend data contracts

#### 1a. `User` entity (`_shared/domain/entities/user.dart`)
Add `required bool isModerator` to the `User` freezed factory. No default —
the field is required; every call site that constructs `User` directly (e.g. tests)
must supply it.

#### 1b. `UserDto` (`_shared/data/dto/user_dto.dart`)
Add `@JsonKey(name: 'is_moderator') @Default(false) bool isModerator` to the freezed
factory (soft-failure default so old responses without the field deserialise safely).
Update `UserDtoMapper.toDomain()` to pass `isModerator: isModerator`.

#### 1c. `CurrentUser` entity (`core/auth/domain/entities/current_user.dart`)
`CurrentUser` is a handwritten `@immutable final class` (not freezed). Add:
- `required this.isModerator` to the constructor.
- `isModerator` field declaration.
- Include `isModerator` in `==` and `hashCode` (`Object.hash(..., isModerator)`).

#### 1d. `CurrentUserDto` (`core/auth/data/dto/current_user_dto.dart`)
Add `@JsonKey(name: 'is_moderator') @Default(false) bool isModerator` to the freezed
factory. Update `CurrentUserDtoX.toDomain()` to pass `isModerator: isModerator`.

After these four changes, run `build_runner` once to regenerate `.freezed.dart`
and `.g.dart` files before proceeding.

---

### Step 2 — Extend the permission system

#### 2a. `permission.dart`
Add `manageModerators` to the `Permission` enum after `moderatePosts`.

#### 2b. `role_policy.dart`
No change needed. `UserRole.admin: {...Permission.values}` already expands to all
values including the new `manageModerators`.

The `manager` role currently has `moderatePosts` explicitly. That stays as-is — a
manager is not a moderator in the per-user sense; they get `moderatePosts` via their
static role. The new cubit branch handles per-user moderator status separately.

#### 2c. `permission_cubit.dart`
Insert a new branch **between** the superuser branch and the plain-user branch:

```
AuthAuthenticated where isSuperuser == true  → kRolePolicy[admin]   (unchanged)
AuthAuthenticated where isModerator == true  → kRolePolicy[user] + {moderatePosts}
AuthAuthenticated (regular user)             → kRolePolicy[user]    (unchanged)
_ (guest)                                   → kRolePolicy[guest]   (unchanged)
```

The moderator set is `{...kRolePolicy[UserRole.user]!, Permission.moderatePosts}`.
`manageModerators` is intentionally **not** included — only superusers get that (via
the admin policy which contains all values).

IMPORTANT: `isModerator` is a per-user flag on `CurrentUser`, not a static role —
do not add a new `UserRole` entry to `role_policy.dart`.

---

### Step 3 — New API endpoints in `UsersApiClient`

Add two methods to `users_api_client.dart`:

```dart
@PATCH('/user/{username}/assign-moderator')
Future<void> assignModerator(@Path('username') String username);

@PATCH('/user/{username}/revoke-moderator')
Future<void> revokeModerator(@Path('username') String username);
```

Run `build_runner` after to regenerate `users_api_client.g.dart`.

---

### Step 4 — Domain layer (new slice)

#### `moderator_management_port.dart`
```dart
abstract interface class ModeratorManagementPort {
  Future<Either<Failure, void>> assignModerator(String username);
  Future<Either<Failure, void>> revokeModerator(String username);
}
```

#### `assign_moderator_usecase.dart` and `revoke_moderator_usecase.dart`
Each is a thin delegating use-case:

```dart
class AssignModeratorUseCase {
  AssignModeratorUseCase(this._port);
  final ModeratorManagementPort _port;
  Future<Either<Failure, void>> call(String username) =>
      _port.assignModerator(username);
}
```

No Flutter imports; pure Dart + dartz.

---

### Step 5 — Data layer (adapter)

`moderator_management_adapter.dart` — implements `ModeratorManagementPort`, uses
`UsersApiClient`. Double-catch pattern as in `UpdateUserTierAdapter`:

```
outer catch (e, st) → logger.error + Left(Failure.unknown())
inner DioException  → _mapHttp(e)
```

`_mapHttp` switch:
- 403 → `Failure.forbidden(message: 'Permission denied')`
- 404 → `Failure.notFound()`
- 409 → `Failure.conflict(message: 'Conflict')`  ← already exists in failure.dart
- _   → `Failure.server(statusCode: e.response?.statusCode)`

Register with `@LazySingleton(as: ModeratorManagementPort)`.

---

### Step 6 — Application layer (cubit)

`assign_moderator_state.dart` — sealed via freezed:
```
initial
loading
success({required bool isModerator})   ← new moderator status after action
error(Failure failure)
```

`assign_moderator_cubit.dart` — `@injectable`, takes `AssignModeratorUseCase` and
`RevokeModeratorUseCase`:

```dart
Future<void> assign(String username) async { ... }
Future<void> revoke(String username) async { ... }
```

Both follow the same pattern: emit `loading`, call use-case, fold into
`success(isModerator: true/false)` or `error(failure)`.

The `success` state carries the **new** `isModerator` value (true after assign, false
after revoke). The screen uses this to patch its local `User` copy without a full
reload.

---

### Step 7 — Presentation layer

#### `assign_moderator_button.dart`
A self-contained widget with its own `BlocProvider<AssignModeratorCubit>` and
`BlocListener` for side effects (snackbar on error). Receives `username` and initial
`isModerator` value as constructor parameters; tracks the current value in a local
variable updated on `success` state.

The parent screen passes the button visibility guard — the button is only added to
the AppBar actions when `permissions.contains(Permission.manageModerators)`. The
widget itself does not re-check the permission.

Loading state: show a `SizedBox(width: 24, child: CircularProgressIndicator(strokeWidth: 2))`.

#### Moderator badge in `UserDetailsView`
Add a small `Chip` or `Icon + Text` widget in the profile header area, rendered only
when `user.isModerator == true`. This is inlined in `UserDetailsView`, not a
separate file.

#### Wiring in `user_details_screen.dart`
Inside the `BlocBuilder<PermissionCubit>` block, add:

```dart
final canManageModerators = permissions.contains(Permission.manageModerators);
```

Add to the `Row` of actions:
```dart
if (canManageModerators && state is UserDetailsLoaded)
  BlocProvider(
    create: (_) => getIt<AssignModeratorCubit>(),
    child: AssignModeratorButton(
      username: widget.username,
      isModerator: state.user.isModerator,
    ),
  ),
```

IMPORTANT: The `UserDetailsLoaded` state access needs restructuring —
`AssignModeratorButton` must only be rendered when user data is available.
Keep the outer BlocBuilder on `UserDetailsCubit` and check the state type.

---

### Step 8 — Localisation

Add to `lib/core/i18n/i18n/en.json` under `users`:

```json
"moderator": {
  "badge": "Moderator",
  "assign": "Assign Moderator",
  "revoke": "Revoke Moderator",
  "errors": {
    "conflict": "Action not applicable — moderator status is already in sync.",
    "forbidden": "You do not have permission to manage moderators.",
    "generic": "Failed to update moderator status. Please try again."
  }
}
```

Mirror keys in `ru.json`. Run slang after.

---

### Step 9 — DI

`moderator_management_adapter.dart` uses `@LazySingleton(as: ModeratorManagementPort)`.
`assign_moderator_cubit.dart` uses `@injectable` (not singleton — one per screen).
Use-cases use `@injectable`.

Run `build_runner` after to regenerate `injection.config.dart`.

---

## Tests

```
test/features/users/0033_moderator_contract/
├── data/
│   └── moderator_management_adapter_test.dart
│       — assign 200 → Right(null)
│       — revoke 200 → Right(null)
│       — assign 403 → Left(ForbiddenFailure)
│       — assign 409 → Left(ConflictFailure)
│       — assign 404 → Left(NotFoundFailure)
│       — unexpected exception → Left(UnknownFailure), logger.error called
│       — revoke 403 / 409 / unexpected (same coverage as assign)
├── domain/
│   └── usecases/
│       ├── assign_moderator_usecase_test.dart
│       │   — delegates to port.assignModerator(username) → passes result through
│       └── revoke_moderator_usecase_test.dart
│           — delegates to port.revokeModerator(username) → passes result through
├── application/
│   └── assign_moderator_cubit_test.dart
│       — assign: emits [loading, success(isModerator: true)] on Right
│       — revoke: emits [loading, success(isModerator: false)] on Right
│       — assign failure: emits [loading, error(failure)]
│       — revoke failure: emits [loading, error(failure)]
└── presentation/
    └── assign_moderator_button_test.dart
        — with manageModerators permission + isModerator:false → shows "Assign Moderator"
        — with manageModerators permission + isModerator:true  → shows "Revoke Moderator"
        — loading state → shows CircularProgressIndicator
        — error state → shows snackbar with error text
        — success state → label toggles to opposite

Additionally, the existing PermissionCubit test at
test/core/rbac/permission_cubit_test.dart must be extended (not replaced) to cover:
  — superuser → contains {moderatePosts, manageModerators}
  — moderator (isModerator:true, isSuperuser:false) → contains moderatePosts,
    does NOT contain manageModerators
  — regular user → contains neither
```

---

## Report

On completion provide:
- List of all new files created (with paths)
- List of all modified files (with paths)
- Confirmation that no other slices were touched
- Confirmation that `dart format .` passes, `dart analyze` returns no warnings
- Confirmation that `build_runner` was run after each codegen-affecting batch
- Count of new tests and their pass status

---

## What NOT to do

- Do NOT create a route or screen for `moderator_contract` — this slice has no
  dedicated screen.
- Do NOT add a new `UserRole` to `role.dart` or `role_policy.dart` — the moderator
  case is handled inline in `PermissionCubit` using the per-user `isModerator` flag.
- Do NOT include `manageModerators` in the moderator's permission set — only
  superusers receive it (via `kRolePolicy[admin]`).
- Do NOT reload `UserDetailsCubit` on assign/revoke success — carry the new
  `isModerator` boolean in `AssignModeratorState.success` and update the local
  display only.
- Do NOT hardcode any UI string — all labels via `slang`.
- Do NOT re-check `manageModerators` permission inside `AssignModeratorButton` — the
  parent screen controls visibility; the widget is always rendered as visible.
- Do NOT modify `role_policy.dart` — `admin: {...Permission.values}` already covers
  the new `manageModerators` value automatically.
- Do NOT touch any slice other than `user_details` when wiring the presentation.
