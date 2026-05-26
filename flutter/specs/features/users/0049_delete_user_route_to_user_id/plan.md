# Feature Spec — 0049 delete_user_route_to_user_id

> Implementation plan for the slice. Source: `prd.md` (this folder) + the current
> `delete_user` slice + the closest route-migration analog
> (`0047_delete_tier_id_contract`). Written after confirming the hard dependency on
> 0048 is satisfied: `CurrentUser.id` (`int`) exists.

---

## 1. Header

Migrate the **delete-user vertical** from username-as-identity to `int userId`, end
to end and **without behavior change**. The API method, port, adapter, use-case,
cubit, and button all switch their target identifier from `String username` to
`int userId`. The ownership guard stays in the use-case and becomes an id comparison
(`userId != currentUserId → PermissionDenied`), with `currentUserId` supplied by the
cubit from `AuthCubit.currentUser.id`. Confirmation dialog, success logout + snackbar,
failure messages, and the return-to-list are all unchanged.

This is a **modification of an existing, green slice** (not a new slice). Per the
"Modifying an existing slice" rule in `CLAUDE.md`, the contract change is driven from
the spec/test chain first; the outside-in test represents the **new** (id) contract.

---

## 2. Context

**READ:**
- `@CLAUDE.md` — fully.
- `@specs/features/users/0049_delete_user_route_to_user_id/prd.md` — the product spec.
- The whole current slice (it is the unit being modified):
  - `@lib/features/users/delete_user/domain/ports/delete_user_port.dart`
  - `@lib/features/users/delete_user/domain/usecases/delete_user_usecase.dart`
  - `@lib/features/users/delete_user/data/delete_user_adapter.dart`
  - `@lib/features/users/delete_user/application/delete_user_cubit.dart`
  - `@lib/features/users/delete_user/application/delete_user_state.dart`
  - `@lib/features/users/delete_user/presentation/delete_account_button.dart`
- `@lib/features/users/_shared/data/users_api_client.dart` — the `deleteUser` method
  whose `@DELETE` annotation and parameter migrate (regen target).
- `@lib/core/auth/application/auth_cubit.dart` — `currentUser` getter (now `.id`) and
  `forceLogout(notifyUser:)`. Unchanged by this slice; read-only dependency.
- `@lib/core/auth/domain/entities/current_user.dart` — confirms `int id` (0048).
- `@lib/features/users/user_details/presentation/user_details_screen.dart` — the
  **cross-slice edit site**: the actions row that constructs `DeleteAccountButton`.
- `@lib/features/users/user_details/application/user_details_state.dart` — confirms
  `UserDetailsLoaded(User user)` carries `user.id`.
- `@.claude/skills/bloc/SKILL.md` — Cubit conventions.
- Prior art (lean on, do **not** copy):
  - `@test/features/tiers/0047_delete_tier_id_contract/delete_tier_id_contract_outside_in_test.dart`
    — id-contract outside-in shape, incl. a mocked `AuthCubit` providing `CurrentUser`.
  - `@test/features/posts/erase_db_post/data/erase_db_post_adapter_test.dart`
    — full failure-mapping + double-catch + `logger.error`.

**DO NOT READ:**
- Sibling actions-row slices (`moderator_contract`, `update_user_tier`, `edit_user`,
  `erase_db_user`) — they stay username-keyed; this slice does not touch them.
- Other `users` slices (`list_users`, `create_user`, `get_user_tier`).
- Any `posts` or `auth/login` slice.
- Generated files (`*.g.dart`, `*.freezed.dart`, `*.config.dart`) — regenerated, not
  hand-edited.

---

## 3. API

```
DELETE http://127.0.0.1:8000/api/v1/user/{user_id}        ← was /user/{username}
Header: Authorization: Bearer <token>
Response 200: {"message": "User deleted"}
Returns: Future<void>  (no body consumed; success = no throw)
```

**Path parameter:** `user_id` is an **integer**. The retrofit annotation becomes
`@DELETE('/user/{user_id}')` with `@Path('user_id') int userId`.

**Server side effects (unchanged from before the migration):**
- Self-delete only: the server allows deleting **only your own** profile (else 403).
- On success the server **blacklists the token** → any subsequent request on the old
  token returns 401. The client therefore performs an explicit **local** logout
  (`forceLogout(notifyUser: false)`) before any background request can hit that 401.

**Errors (mapping preserved exactly):**
- `401` → `UnauthorizedFailure` (token invalid / expired).
- `403` → `ForbiddenFailure` (not your profile).
- `404` → `NotFoundFailure` (user not found).
- default → `e.error` if it is a `Failure`, else `NetworkFailure(message: e.message)`.
- any other thrown object → `UnknownFailure` + `logger.error` (catch-all).

---

## 4. Structure

No files are created or deleted. The slice keeps its current shape (no own screen/
route — presentation is a button embedded in `user_details_screen`). Only signatures
and the path/param of existing files change:

```
lib/features/users/delete_user/
├── domain/
│   ├── ports/
│   │   └── delete_user_port.dart        # call(String username) → call(int userId)
│   └── usecases/
│       └── delete_user_usecase.dart     # {username, currentUsername} → {userId, currentUserId}
├── data/
│   └── delete_user_adapter.dart         # param int userId; _api.deleteUser(userId); mapping unchanged
├── application/
│   ├── delete_user_cubit.dart           # confirmAndDelete(int userId); currentUserId from currentUser?.id ?? -1
│   └── delete_user_state.dart           # UNCHANGED (sealed freezed; no identifier in state)
└── presentation/
    ├── delete_account_button.dart       # DeleteAccountButton(int userId) → inner → confirmAndDelete
    └── widgets/
        └── delete_confirmation_dialog.dart   # UNCHANGED

lib/features/users/_shared/data/
└── users_api_client.dart                # @DELETE('/user/{user_id}') Future<void> deleteUser(@Path('user_id') int userId)
                                          # ← REQUIRES build_runner regen of users_api_client.g.dart

CROSS-SLICE (in scope, surgical — single construction site):
lib/features/users/user_details/presentation/
└── user_details_screen.dart             # actions row: pass loaded user's id, not username,
                                          # to DeleteAccountButton — selected from UserDetailsCubit
                                          # the same way isModerator already is.
```

---

## 5. What to do (by layer)

Migrate inside-out, finishing with the cross-slice construction site.

**1) `_shared` — API client (regen target).** In `users_api_client.dart`:
```dart
@DELETE('/user/{user_id}')
Future<void> deleteUser(@Path('user_id') int userId);
```
Then run `dart run build_runner build --delete-conflicting-outputs` to regenerate
`users_api_client.g.dart`. **Only the `deleteUser` method changes** — leave the other
nine methods (still `{username}`) untouched; their migration is out of scope.

**2) Domain — port.** `delete_user_port.dart`:
```dart
Future<Either<Failure, Unit>> call(int userId);
```

**3) Domain — use-case (guard stays here).** `delete_user_usecase.dart`:
```dart
Future<Either<Failure, Unit>> call({
  required int userId,
  required int currentUserId,
}) async {
  if (userId != currentUserId) {
    return const Left(Failure.permissionDenied());
  }
  return _port(userId);
}
```
Do **not** move the guard to the cubit or UI (CLAUDE.md forbids UI-only permission
checks). The guard is a pure id comparison.

**4) Data — adapter.** `delete_user_adapter.dart`:
```dart
Future<Either<Failure, Unit>> call(int userId) async { ... _api.deleteUser(userId); ... }
```
The double `try` (DioException switch + catch-all `catch (e, st)` with `logger.error`)
and the 401/403/404/default mapping are **copied verbatim** — only the parameter type
and the `_api.deleteUser(...)` argument change.

**5) Application — state.** `delete_user_state.dart` is **unchanged**: the sealed
states (`initial / confirming / deleting / success / failure(Failure)`) carry no
identifier.

**6) Application — cubit.** `delete_user_cubit.dart`:
```dart
Future<void> confirmAndDelete(int userId) async {
  emit(const DeleteUserState.deleting());
  final result = await _deleteUser(
    userId: userId,
    currentUserId: _authCubit.currentUser?.id ?? -1,   // non-matching sentinel when unauthenticated
  );
  await result.fold(
    (f) async => emit(DeleteUserState.failure(f)),
    (_) async {
      await _authCubit.forceLogout(notifyUser: false);   // unchanged: token blacklisted server-side
      emit(const DeleteUserState.success());
    },
  );
}
```
**CRITICAL — hard dep on 0048:** `_authCubit.currentUser?.id` is the line that needs
`CurrentUser.id`. The sentinel `-1` mirrors today's `?? ''`: a user id is never `-1`,
so an unauthenticated caller fails the guard (`userId != -1`) → `PermissionDenied`,
never an accidental match. `forceLogout(notifyUser: false)` and the state machine are
otherwise unchanged.

**7) Presentation — button.** `delete_account_button.dart`: `DeleteAccountButton` and
`_DeleteAccountButtonInner` take `final int userId` instead of `String username`;
thread it through to `confirmAndDelete(userId)`. The dialog, snackbar
(`users.delete.success`), `replaceAll([UsersRoute()])`, and `_failureMessage` switch
are unchanged.

**8) Cross-slice — actions row.** In `user_details_screen.dart`'s
`_UserDetailsAppBarActions`, select the loaded user's id the same way `isModerator` is
selected today, and pass it to `DeleteAccountButton`:
```dart
final int? userId = context.select<UserDetailsCubit, int?>(
  (c) {
    final s = c.state;
    return s is UserDetailsLoaded ? s.user.id : null;
  },
);
...
if (visibility.showDelete && userId != null)
  DeleteAccountButton(userId: userId),
```
This is the **only** construction site of `DeleteAccountButton`. The sibling buttons
(`AssignModeratorButton`, `UpdateUserTierButton`, edit `IconButton`,
`EraseDbUserButton`) keep passing `username` — a temporary **mixed-key actions row**,
accepted per PRD, not a regression.

**9) Localization.** No new strings — all `users.delete.*` keys already exist. No
`slang` regen.

---

## 6. Tests

The acceptance gate is the slice outside-in test (id contract). Unit/widget tests are
migrated from username to id as the final step. All four layers stay covered.

**Slice outside-in (acceptance gate) —**
`test/features/users/0049_delete_user_route_to_user_id/delete_user_route_to_user_id_outside_in_test.dart`:
- Wires the **real** adapter + use-case + cubit; mocks `UsersApiClient` and `AuthCubit`.
- `setUp` stubs `authCubit.currentUser` → a `CurrentUser(id: 1, …)` (matching id).
- **Scenario 1 (matching id, success):** `confirmAndDelete(1)` with
  `apiClient.deleteUser(1)` answering normally → emits `[deleting, success]`, and
  `verify(() => apiClient.deleteUser(1)).called(1)` — **proves the API is called with
  the integer id**. (Mirrors 0047; mocked at the API-client boundary, no live backend.)
- **Scenario 2 (matching id, 404):** `apiClient.deleteUser(1)` throws `DioException`
  with `statusCode: 404` → emits `[deleting, failure(NotFoundFailure)]`;
  `verify(... deleteUser(1)).called(1)`.
- **Scenario 3 (non-matching id, guard):** stub `currentUser` id `1`,
  `confirmAndDelete(2)` → emits `[deleting, failure(PermissionDenied)]` and
  `verifyNever(() => apiClient.deleteUser(any()))` — the guard refuses and never hits
  the API.

**Use-case (unit)** — `test/features/users/delete_user/domain/usecases/delete_user_usecase_test.dart`
(migrate the two existing tests from username to id):
- `userId == currentUserId` → delegates `_port(userId)`, returns `Right(unit)`.
- `userId != currentUserId` → returns `Left(PermissionDenied)`, port **never** called.

**Adapter (unit)** — `test/features/users/delete_user/data/delete_user_adapter_test.dart`:
- success: `deleteUser(<int>)` completes → `Right(unit)`.
- `401 → UnauthorizedFailure`, `403 → ForbiddenFailure`, `404 → NotFoundFailure`.
- unexpected (non-Dio) exception → `Left(UnknownFailure)` **and** `logger.error` verified.
- All driven with an `int` id argument.

**Cubit (`bloc_test`)** — `test/features/users/delete_user/application/delete_user_cubit_test.dart`:
- `requestConfirmation` → `[confirming]`.
- `confirmAndDelete(id)` success → `[deleting, success]`, and
  `forceLogout(notifyUser: false)` invoked.
- `confirmAndDelete(id)` failure → `[deleting, failure]`.
- `cancel` from confirming → `[initial]`.
- All driven with `int userId` and a stubbed `currentUser.id`.

**Button (widget)** — `test/features/users/delete_user/presentation/delete_account_button_test.dart`:
- confirmation dialog appears on tap; confirming triggers `confirmAndDelete(<int id>)`.
- success → snackbar + navigation to users list; failure → error snackbar.
- Built with `DeleteAccountButton(userId: …)`.

---

## 7. Report (what the implementer must hand back)

- Files changed: the 5 slice files (port, use-case, adapter, cubit, button), the
  `_shared` API client, and `user_details_screen.dart` — plus regenerated
  `users_api_client.g.dart`.
- Confirmation that `delete_user_state.dart`, `delete_confirmation_dialog.dart`, and
  the four sibling actions-row buttons were **not** changed.
- Confirmation that `core/` was not modified (auth is read-only here).
- `build_runner` run after the API-client edit; `dart format` clean; `dart analyze`
  clean.
- The outside-in test is GREEN; the four migrated unit/widget test files pass; no new
  failures introduced in unrelated user/auth/routing tests (route-migration slices are
  known to ripple — baseline before/after).

---

## 8. What NOT to do

- ❌ Do **not** migrate the sibling actions-row buttons (AssignModerator,
  UpdateUserTier, EditUser, EraseDbUser) — they stay username-keyed until their slices.
- ❌ Do **not** migrate any other `UsersApiClient` method, port, or adapter — only
  `deleteUser`.
- ❌ Do **not** touch the `user_details` route path or its `@PathParam` (slice 0050).
- ❌ Do **not** move the ownership guard out of the use-case into the cubit or UI.
- ❌ Do **not** change the logout/token behavior, the dialog, the snackbar messages,
  the navigation target, or the self-delete rule — this is a pure identifier migration.
- ❌ Do **not** hand-edit `users_api_client.g.dart` — regenerate it.
- ❌ Do **not** add a route/screen for delete — it has none and gains none.
- ❌ Do **not** touch `AuthCubit.isMe` or any other route/adapter outside the delete
  vertical.
