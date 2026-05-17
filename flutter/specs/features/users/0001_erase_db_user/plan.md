# Plan: erase_db_user

## Task

Create a new slice `erase_db_user` in the `users` feature.
Hard delete an account from the database: confirmation dialog → `DELETE /api/v1/db_user/{username}` →
`forceLogout(notifyUser: false)` → `replaceAll([UsersRoute()])` + snackbar "Account erased".

The UX flow is identical to `delete_user`; only the endpoint and localization strings differ.
The slice has NO dedicated screen or route — only a button widget embedded in `user_details_screen`.

---

## CONTEXT

**READ:**
- `CLAUDE.md` fully
- `lib/features/users/delete_user/**` — reference analog (do NOT copy, use patterns as a guide)
- `lib/features/users/_shared/data/users_api_client.dart` — add `eraseDbUser` here
- `lib/features/users/user_details/presentation/user_details_screen.dart` — embed the button here
- `lib/core/auth/application/auth_cubit.dart` — for `forceLogout(notifyUser: false)`
- `lib/core/errors/failure.dart` — error types
- `lib/core/routing/app_router.dart` — for `replaceAll([UsersRoute()])`
- `.claude/skills/bloc/SKILL.md`

**DO NOT READ:**
- `lib/features/users/list_users/**`
- `lib/features/users/create_user/**`
- `lib/features/users/edit_user/**`
- `lib/features/auth/**`
- `**/*.gr.dart`, `**/*.config.dart`, `**/*.freezed.dart`, `**/*.g.dart`

---

## API

```
DELETE /api/v1/db_user/{username}
Header: Authorization: Bearer <token>
Response 200: {"message": "User deleted from the database"}
```

**Server-side effects:**
- The user record is PHYSICALLY deleted from the database (unlike soft-delete `/user/{username}`)
- The server **blacklists the caller's token** (same mechanism as `/user/{username}`)
- This means: after a successful response, the next request with the old token will return 401

**CRITICAL:** Perform an explicit `forceLogout(notifyUser: false)` before the interceptor
encounters a 401 from a random background request.
The `notifyUser: false` parameter prevents the global "Session expired" snackbar —
we show our own "Account erased" instead.

**Error codes:**
- `401` — token invalid → `UnauthorizedFailure`
- `403` — not own profile → `ForbiddenFailure`
- `404` — user not found → `NotFoundFailure`
- others → `NetworkFailure` (from `e.message`)

---

## Target structure

```
lib/features/users/erase_db_user/
├── domain/
│   ├── ports/
│   │   └── erase_db_user_port.dart          # Future<Either<Failure, Unit>> call(String username)
│   └── usecases/
│       └── erase_db_user_usecase.dart
├── data/
│   └── erase_db_user_adapter.dart           # @LazySingleton(as: EraseDbUserPort)
├── application/
│   ├── erase_db_user_cubit.dart
│   └── erase_db_user_state.dart             # sealed via freezed, 5 states
└── presentation/
    ├── erase_db_user_button.dart            # button widget with BlocProvider + BlocListener
    └── widgets/
        └── erase_db_user_confirmation_dialog.dart

Modified existing files:
- lib/features/users/_shared/data/users_api_client.dart  — add eraseDbUser
- lib/features/users/user_details/presentation/user_details_screen.dart — add EraseDbUserButton
- lib/core/i18n/i18n/strings.en.json   — keys users.eraseDbUser.*
- lib/core/i18n/i18n/strings.ru.json   — keys users.eraseDbUser.*
```

---

## What to do

### 1) _SHARED — add method to UsersApiClient

File: `lib/features/users/_shared/data/users_api_client.dart`

Add method after `deleteUser`:

```dart
@DELETE('/db_user/{username}')
Future<void> eraseDbUser(@Path('username') String username);
```

Then regenerate: `dart run build_runner build --delete-conflicting-outputs`

### 2) DOMAIN — port

File: `lib/features/users/erase_db_user/domain/ports/erase_db_user_port.dart`

```dart
abstract class EraseDbUserPort {
  Future<Either<Failure, Unit>> call(String username);
}
```

### 3) DOMAIN — usecase

File: `lib/features/users/erase_db_user/domain/usecases/erase_db_user_usecase.dart`

Analogous to `DeleteUserUseCase` — a thin delegate to the port, with `@injectable`.

### 4) DATA — adapter

File: `lib/features/users/erase_db_user/data/erase_db_user_adapter.dart`

`@LazySingleton(as: EraseDbUserPort)`, constructor accepts `UsersApiClient` and `AppLogger`.

Method `call(String username)`:
- Calls `_api.eraseDbUser(username)`
- Two-level catch (see §8.4 CLAUDE.md):
  - inner `on DioException`: mapping 401/403/404/default — analogous to `DeleteUserAdapter`
  - outer `catch (e, st)`: `_logger.error('EraseDbUserAdapter.call failed unexpectedly', ...)` → `Left(Failure.unknown())`

### 5) APPLICATION — state

File: `lib/features/users/erase_db_user/application/erase_db_user_state.dart`

Sealed class via freezed, 5 factories — analogous to `DeleteUserState`:

```dart
@freezed
sealed class EraseDbUserState with _$EraseDbUserState {
  const factory EraseDbUserState.initial()              = EraseDbUserInitial;
  const factory EraseDbUserState.confirming()           = EraseDbUserConfirming;
  const factory EraseDbUserState.deleting()             = EraseDbUserDeleting;
  const factory EraseDbUserState.success()              = EraseDbUserSuccess;
  const factory EraseDbUserState.failure(Failure failure) = EraseDbUserFailure;
}
```

### 6) APPLICATION — cubit

File: `lib/features/users/erase_db_user/application/erase_db_user_cubit.dart`

`@injectable`, accepts `EraseDbUserUseCase` and `AuthCubit`.

Three public methods:
- `requestConfirmation()` → emit `confirming`
- `cancel()` → if `confirming`, emit `initial`
- `confirmAndDelete(String username)`:
  1. emit `deleting`
  2. call `_eraseDbUser(username)`
  3. on failure → emit `failure(f)`
  4. on success:
     - `await _authCubit.forceLogout(notifyUser: false)` — CRITICAL: before `emit(success)`,
       so the interceptor cannot catch the 401 first
     - emit `success`

### 7) PRESENTATION — button

File: `lib/features/users/erase_db_user/presentation/erase_db_user_button.dart`

Public `EraseDbUserButton({required String username})` — `StatelessWidget`.
Creates `BlocProvider(create: (_) => getIt<EraseDbUserCubit>())` as root,
inside — private `_EraseDbUserButtonInner`.

`_EraseDbUserButtonInner` contains `BlocListener` + `BlocBuilder` (analogous to `delete_account_button.dart`):

**BlocListener:**
- `EraseDbUserConfirming` → `showDialog<bool>(EraseDbUserConfirmationDialog)`:
  - `true` → `cubit.confirmAndDelete(username)`
  - otherwise → `cubit.cancel()`
- `EraseDbUserSuccess` → `ScaffoldMessenger.showSnackBar(t.users.eraseDbUser.success)` + `router.replaceAll([UsersRoute()])`
- `EraseDbUserFailure` → `showSnackBar(_failureMessage(failure))`
- others → `break`

**BlocBuilder:**
- `isDeleting` → `CircularProgressIndicator(strokeWidth: 2)` sized 20×20
- otherwise → `Icon(Icons.delete_forever, color: colorScheme.error)`
- `tooltip: t.users.eraseDbUser.tooltip`
- `onPressed`: if `deleting` → `null`, otherwise → `cubit.requestConfirmation()`

### 8) PRESENTATION — dialog

File: `lib/features/users/erase_db_user/presentation/widgets/erase_db_user_confirmation_dialog.dart`

`StatelessWidget`, analogous to `DeleteConfirmationDialog`.
Uses keys `t.users.eraseDbUser.confirmTitle`, `confirmMessage`, `confirmButton`.

**IMPORTANT:** `confirmMessage` must contain an explicit warning about irreversibility
(this is a hard delete, not a soft delete). Reflect this in the localization strings.

### 9) INTEGRATION — user_details_screen

File: `lib/features/users/user_details/presentation/user_details_screen.dart`

In `AppBar.actions`, inside the `isMe == true` block, next to `DeleteAccountButton`
add `EraseDbUserButton(username: widget.username)`.

Button order: edit → delete → erase (left to right).

### 10) LOCALIZATION

Files: `lib/core/i18n/i18n/strings.en.json` and `strings.ru.json`

Add to the `users` section:

```json
"eraseDbUser": {
  "tooltip": "Erase from database",
  "confirmTitle": "Erase account permanently?",
  "confirmMessage": "This will permanently delete your account from the database. This action cannot be undone.",
  "confirmButton": "Erase permanently",
  "success": "Account erased from the database",
  "errors": {
    "forbidden": "You can only erase your own account",
    "unauthorized": "Session expired. Please log in again",
    "notFound": "User not found",
    "generic": "Failed to erase account. Please try again"
  }
}
```

Then: `dart run slang`

---

## Tests

### a) `test/features/users/erase_db_user/application/erase_db_user_cubit_test.dart`

- `requestConfirmation()` → emits `[EraseDbUserConfirming]`
- `cancel()` from `confirming` → emits `[EraseDbUserInitial]`
- `cancel()` from `initial` → emits nothing
- `confirmAndDelete` success:
  → emits `[EraseDbUserDeleting, EraseDbUserSuccess]`
  → `mockAuthCubit.forceLogout(notifyUser: false)` was called
- `confirmAndDelete` failure (any):
  → emits `[EraseDbUserDeleting, EraseDbUserFailure]`
  → `forceLogout` was NOT called

### b) `test/features/users/erase_db_user/data/erase_db_user_adapter_test.dart`

- success: `_api.eraseDbUser` returned `void` → `Right(unit)`
- 401 → `Left(UnauthorizedFailure)`
- 403 → `Left(ForbiddenFailure)`
- 404 → `Left(NotFoundFailure)`
- `DioException` without code → `Left(NetworkFailure)`
- unexpected `Exception` → `Left(UnknownFailure)`, `mockLogger.error` called with stackTrace

---

## Report (on completion)

- List of all new files (8 slice files)
- List of modified files (4 existing)
- Confirmation that `delete_user`, `list_users`, `edit_user`, `create_user` were NOT touched
- All tests green
- UX walkthrough: button visible only for own profile, dialog opens, confirm → logout → redirect, cancel → return

---

## What NOT to do

- Do NOT create `erase_db_user_route.dart` — slice has no screen or route
- Do NOT add the button to `list_users_screen` — only `user_details_screen`
- Do NOT call regular `logout()` — the server has already blacklisted the token,
  a repeated API request will fail with 401
- Do NOT show "Session expired" — use `notifyUser: false` and our own snackbar
- Do NOT add logic to `DeleteUserCubit` or `DeleteUserAdapter` — this is a separate slice
- Do NOT reuse `DeleteConfirmationDialog` — create a new one with different text
- Do NOT remove the token from storage before sending the request
