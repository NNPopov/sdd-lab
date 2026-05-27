# Feature Spec — 0055 moderator_routes_to_user_id

> Implementation plan for the slice. Source: `prd.md` (this folder) + the current
> `moderator_contract` vertical + the verified near-identical template
> `0054_user_tier_routes_to_user_id`. Written after confirming this slice has **no**
> 0048 dependency: neither moderator use-case compares identity — assign/revoke are
> pure delegation, gated by the `canManageModerators` permission in the UI and a
> superuser check on the backend, not by an id comparison.

---

## 1. Header

Migrate the **single `moderator_contract` vertical** — which serves **both** assign and
revoke — from username-as-identity to `int userId`, end to end and **without behavior
change**. The two API client methods, the shared `ModeratorManagementPort` (both
methods), the single adapter (both methods), the two use-cases
(`AssignModeratorUseCase` / `RevokeModeratorUseCase`), the `AssignModeratorCubit` (both
`assign` and `revoke`), and the `AssignModeratorButton` all switch their target
identifier from `String username` to `int userId`.

The client mirrors the backend paths **verbatim, including the intentional asymmetry**:
`assignModerator` stays **singular** `PATCH /user/{user_id}/assign-moderator`, while
`revokeModerator` becomes **plural** `PATCH /users/{user_id}/revoke-moderator`. The
revoke route is corrected on **two axes at once**: `{username}` → `{user_id}` *and*
singular `/user/` → plural `/users/`. The assign/revoke toggle, the `isModerator`
success callback, the loading spinner, and the error snackbars
(`403 → forbidden`, `404 → not-found`, `409 → conflict`, default → server) are unchanged.

Per `CONTEXT.md`, the value passed into `assignModerator(...)` / `revokeModerator(...)`
is **path-identity** — it names *which* user is being promoted/demoted, is only fed to
the API call, and is never displayed or stored as a handle — so it migrates cleanly to
`int`. No **handle** is touched: the `@username` title, login, the create/edit-user
form, the post-navigation `username`, and any displayed `@username` label all stay.

This is a **modification of an existing, green slice** (not a new slice). Per the
"Modifying an existing slice" rule in `CLAUDE.md`, the contract change is driven from the
spec/test chain first; the outside-in test represents the **new** (id) contract. This is
the **final** user-action route migration: because the moderator button was the **last**
consumer of the actions-row `username` local that 0054 deliberately kept, that local now
has no remaining reader and is removed — resolving the accepted **mixed-key** actions row
(introduced by 0049, carried by 0054) into a **fully id-keyed** row.

---

## 2. Context

**READ:**
- `@CLAUDE.md` — fully.
- `@specs/features/users/0055_moderator_routes_to_user_id/prd.md` — the product spec.
- The whole **moderator_contract** vertical (the unit being modified):
  - `@lib/features/users/moderator_contract/domain/ports/moderator_management_port.dart`
    — both methods (`assignModerator`, `revokeModerator`).
  - `@lib/features/users/moderator_contract/domain/usecases/assign_moderator_usecase.dart`
  - `@lib/features/users/moderator_contract/domain/usecases/revoke_moderator_usecase.dart`
  - `@lib/features/users/moderator_contract/data/moderator_management_adapter.dart`
    — both methods + the shared `_mapHttp` failure mapping.
  - `@lib/features/users/moderator_contract/application/assign_moderator_cubit.dart`
    — `assign` and `revoke`.
  - `@lib/features/users/moderator_contract/application/assign_moderator_state.dart`
    — confirm **no identifier** in state (read-only check; carries only `isModerator`).
  - `@lib/features/users/moderator_contract/presentation/widgets/assign_moderator_button.dart`
- `@lib/features/users/_shared/data/users_api_client.dart` — the `assignModerator` and
  `revokeModerator` methods whose `@PATCH` annotations and path params migrate
  (regen target). Note the load-bearing singular/plural split (see §3).
- `@lib/features/users/user_details/presentation/user_details_screen.dart` — the
  **cross-slice edit site**: the `AssignModeratorButton` construction in the actions row,
  its visibility gate, and the now-orphaned `username` local to remove.
- `@lib/features/users/user_details/presentation/user_action_visibility.dart` — confirm
  `canManageModerators` (= `Permission.manageModerators`); the visibility gate keeps
  `canManageModerators && isModerator != null` and drops `username != null`.
- `@.claude/skills/bloc/SKILL.md` — Cubit conventions.
- Prior art (lean on, do **not** copy):
  - `@specs/features/users/0054_user_tier_routes_to_user_id/plan.md` and
    `@test/features/users/0054_user_tier_routes_to_user_id/user_tier_routes_to_user_id_outside_in_test.dart`
    — the verified id-contract outside-in shape, mocked at the `UsersApiClient` boundary.
  - `@test/features/users/0033_moderator_contract/` — the existing moderator suite
    (use-case, adapter, cubit, button, outside-in), migrated **in place** from username
    to id; and the 0033 button test for the `getIt`-provided-cubit widget pattern.

**DO NOT READ:**
- The tier verticals (`get_user_tier`, `update_user_tier`) — migrated in slice 0054, done.
- Sibling actions-row slices (`delete_user`, `erase_db_user`, `edit_user`) — already
  migrated; this slice does not touch them.
- Other `users` slices (`list_users`, `create_user`, `user_details` application/data),
  any `posts`/`tiers`/`auth` slice.
- `core/` (auth, routing, DI) — this slice has **no** 0048/`CurrentUser.id` dependency
  and changes nothing in `core/`.
- Generated files (`*.g.dart`, `*.freezed.dart`, `*.config.dart`) — regenerated, not
  hand-edited.

---

## 3. API

Two routes migrate; there are **no** request bodies and the success response is empty
(success = no throw). The asymmetry between the two paths is **intentional and
load-bearing** — pinned by the backend (`api/.../revoke_moderator/.../router.py`).

```
PATCH http://127.0.0.1:8000/api/v1/user/{user_id}/assign-moderator   ← was /user/{username}/assign-moderator
Header: Authorization: Bearer <token>
Body: none
Returns: Future<void>  (success = no throw)
    SINGULAR /user/ — unchanged segment style, only {username} → {user_id}.

PATCH http://127.0.0.1:8000/api/v1/users/{user_id}/revoke-moderator  ← was /user/{username}/revoke-moderator
Header: Authorization: Bearer <token>
Body: none
Returns: Future<void>  (success = no throw)
    PLURAL /users/ — corrected on TWO axes: {username} → {user_id} AND /user/ → /users/.
```

**Path parameter:** `user_id` is an **integer** on both routes. The retrofit annotations
become:
- `@PATCH('/user/{user_id}/assign-moderator')` with `@Path('user_id') int userId`.
- `@PATCH('/users/{user_id}/revoke-moderator')` with `@Path('user_id') int userId`.

⚠️ **The plural `/users/` on revoke is not a typo and must not be "tidied" to singular.**
The validation checklist asserts the plural segment explicitly so a future refactor
cannot silently normalize it.

**Errors — both methods, shared `_mapHttp`, mapping preserved exactly:**
- `403` → `ForbiddenFailure(message: 'Permission denied')`.
- `404` → `NotFoundFailure()` (no message).
- `409` → `ConflictFailure(message: 'Conflict')`.
- default → `ServerFailure(statusCode: e.response?.statusCode)`.
- any other thrown object → `UnknownFailure` + `logger.error` (the per-method catch-all).

There is **no** use-case guard and **no** identity comparison — both use-cases are pure
delegation to the port. The manage-moderators permission is enforced by the UI
visibility gate (`canManageModerators`) and the backend superuser check, so the slice has
**no** dependency on slice 0048 (`CurrentUser.id`).

---

## 4. Structure

No files are created or deleted. The vertical keeps its current shape (no own
screen/route — presentation is a single button embedded in `user_details_screen`). One
port/adapter/cubit/button serves **both** assign and revoke. Only signatures and the
path/param of existing files change:

```
lib/features/users/moderator_contract/
├── domain/
│   ├── ports/
│   │   └── moderator_management_port.dart      # assignModerator(String) → assignModerator(int userId)
│   │                                            # revokeModerator(String) → revokeModerator(int userId)
│   └── usecases/
│       ├── assign_moderator_usecase.dart        # call(String) → call(int userId); pure delegation, no guard
│       └── revoke_moderator_usecase.dart        # call(String) → call(int userId); pure delegation, no guard
├── data/
│   └── moderator_management_adapter.dart        # both methods param int userId; _api.assign/revokeModerator(userId)
│                                                 # double-try + catch-all logger.error + _mapHttp UNCHANGED
├── application/
│   ├── assign_moderator_cubit.dart              # assign(String) → assign(int userId); revoke(String) → revoke(int userId)
│   └── assign_moderator_state.dart              # UNCHANGED (carries isModerator only; no identifier)
└── presentation/
    └── widgets/
        └── assign_moderator_button.dart         # AssignModeratorButton(int userId); inner widget threads userId
                                                  # → cubit.assign(userId) / cubit.revoke(userId)

lib/features/users/_shared/data/
└── users_api_client.dart                        # @PATCH('/user/{user_id}/assign-moderator')  Future<void> assignModerator(@Path('user_id') int userId)
                                                  # @PATCH('/users/{user_id}/revoke-moderator') Future<void> revokeModerator(@Path('user_id') int userId)
                                                  # ← REQUIRES build_runner regen of users_api_client.g.dart
                                                  # ← PRESERVE the singular/plural asymmetry verbatim

CROSS-SLICE (in scope, surgical — single screen):
lib/features/users/user_details/presentation/
└── user_details_screen.dart                     # (a) AssignModeratorButton(userId: <viewed user's id>) — source the id, not the handle
                                                  # (b) visibility gate: drop `username != null`, keep `canManageModerators && isModerator != null`
                                                  # (c) REMOVE the now-orphaned `username` local in _UserDetailsAppBarActions
                                                  #     (its last consumer is gone → row is fully id-keyed)
                                                  # (d) the app-bar TITLE's `username` (display handle, different scope) STAYS
```

---

## 5. What to do (by layer)

Migrate the vertical inside-out, then the shared client, finishing with the cross-slice
screen.

**1) `_shared` — API client (regen target).** In `users_api_client.dart`:
```dart
@PATCH('/user/{user_id}/assign-moderator')
Future<void> assignModerator(@Path('user_id') int userId);

@PATCH('/users/{user_id}/revoke-moderator')
Future<void> revokeModerator(@Path('user_id') int userId);
```
Keep `assign` **singular** and `revoke` **plural** exactly as written. Then run
`dart run build_runner build --delete-conflicting-outputs` to regenerate
`users_api_client.g.dart`. **Only these two methods change** — every other client method
stays untouched.

**2) port.** `moderator_management_port.dart`:
```dart
abstract interface class ModeratorManagementPort {
  Future<Either<Failure, void>> assignModerator(int userId);
  Future<Either<Failure, void>> revokeModerator(int userId);
}
```

**3) use-cases (no guard).** `assign_moderator_usecase.dart` and
`revoke_moderator_usecase.dart`:
```dart
Future<Either<Failure, void>> call(int userId) => _port.assignModerator(userId);
// and
Future<Either<Failure, void>> call(int userId) => _port.revokeModerator(userId);
```
Pure delegation — no permission check, no identity comparison (hence no 0048 dependency).

**4) adapter.** `moderator_management_adapter.dart`: both method parameters become
`int userId`; the calls become `_api.assignModerator(userId)` / `_api.revokeModerator(userId)`.
The double `try` (DioException switch + catch-all `catch (e, st)` with `logger.error`) and
the shared `_mapHttp` mapping (`403 → Forbidden`, `404 → NotFound`, `409 → Conflict`,
default → `ServerFailure`) are **copied verbatim** — only the parameter type and the
argument change.

**5) cubit.** `assign_moderator_cubit.dart`:
```dart
Future<void> assign(int userId) async {
  emit(const AssignModeratorState.loading());
  final result = await _assign(userId);
  result.fold(
    (f) => emit(AssignModeratorState.error(f)),
    (_) => emit(const AssignModeratorState.success(isModerator: true)),
  );
}

Future<void> revoke(int userId) async {
  emit(const AssignModeratorState.loading());
  final result = await _revoke(userId);
  result.fold(
    (f) => emit(AssignModeratorState.error(f)),
    (_) => emit(const AssignModeratorState.success(isModerator: false)),
  );
}
```
The state machine (`initial / loading / success(isModerator) / error`) is **unchanged**;
`assign_moderator_state.dart` is **unchanged** (it carries only `isModerator`).

**6) button (presentation).** `assign_moderator_button.dart`: `AssignModeratorButton` and
the inner `_AssignModeratorButtonInner` take `final int userId` instead of
`String username`. The tap handler calls `cubit.revoke(userId)` / `cubit.assign(userId)`.
The `BlocProvider(create: (_) => getIt<AssignModeratorCubit>())`, the `onToggled`
success callback, the loading spinner, the assign/revoke label toggle, and the
`_errorMessage` switch are **all unchanged**.

**7) Cross-slice — user_details_screen.** In `_UserDetailsAppBarActions`
(`user_details_screen.dart`):
- Construct the button with the viewed user's **id** (the same source as `isModerator` —
  `UserDetailsCubit` state; `_UserDetailsAppBarActions.userId` is already in scope):
  ```dart
  if (visibility.canManageModerators && isModerator != null)
    AssignModeratorButton(
      userId: userId,
      isModerator: isModerator,
      onToggled: (val) =>
          context.read<UserDetailsCubit>().updateIsModerator(val),
    ),
  ```
- The visibility gate **drops** the `username != null` clause and **keeps**
  `canManageModerators && isModerator != null` (the button still needs `isModerator` to
  decide assign vs revoke).
- **Remove** the now-orphaned `username` local (the
  `context.select<UserDetailsCubit, String?>(...)` block) — its last consumer
  (`AssignModeratorButton`) is gone, so the actions row is now **fully id-keyed**.
- The **app-bar title's** `username` `context.select` (a different scope, in
  `_UserDetailsScreenState.build`, the display handle) is **unaffected** and stays.

**8) Localization.** No new strings — all `users.moderator.*` keys
(`assign`, `revoke`, `errors.conflict`, `errors.forbidden`, `errors.generic`) already
exist. No `slang` regen.

---

## 6. Tests

The acceptance gate is the slice outside-in test (id contract) covering **both** assign
and revoke. Unit/cubit/widget tests are migrated from username to id (in place, under
`test/features/users/0033_moderator_contract/`) as the final step. All four layers stay
covered.

**One honest limitation to record (from the PRD's Testing Decisions):** because tests
mock at the `UsersApiClient` method boundary, they can verify `revokeModerator(<int>)` is
*called with the integer id* but **cannot** observe the actual URL path string (singular
vs plural lives in the generated Dio code). The plural-revoke / singular-assign path
correctness is therefore enforced by `validation.md`'s code-review checklist and a manual
network-log step, **not** by a mocked-test assertion.

**Slice outside-in (acceptance gate) —**
`test/features/users/0055_moderator_routes_to_user_id/moderator_routes_to_user_id_outside_in_test.dart`:
- Wires the **real** adapter + both use-cases + cubit; mocks `UsersApiClient` (and the
  `AppLogger` for the catch-all path).
- **Assign, success:** `cubit.assign(7)` with `apiClient.assignModerator(7)` answering
  normally → emits `[loading, success(isModerator: true)]`, and
  `verify(() => apiClient.assignModerator(7)).called(1)` — **proves the API is called
  with the integer id**.
- **Revoke, success:** `cubit.revoke(7)` with `apiClient.revokeModerator(7)` answering
  normally → emits `[loading, success(isModerator: false)]`, and
  `verify(() => apiClient.revokeModerator(7)).called(1)` — **integer id asserted for
  revoke too**.
- (Optional failure leg, for parity with 0033's outside-in) `assign(7)` with a
  `DioException(statusCode: 409)` → `[loading, error(ConflictFailure)]`;
  `verify(... assignModerator(7)).called(1)`.
- Mocked at the API-client boundary; no live backend.

**Use-cases (unit), both** —
`test/features/users/0033_moderator_contract/domain/usecases/assign_moderator_usecase_test.dart`
and `…/revoke_moderator_usecase_test.dart` (migrate existing tests username → id):
delegate the given `int userId` to the port (`assignModerator`/`revokeModerator`) and
pass the port's `Right`/`Left` straight through (no guard).

**Adapter (unit), both methods** —
`test/features/users/0033_moderator_contract/data/moderator_management_adapter_test.dart`:
- success: API method called with the `int` id → `Right(null)`.
- `403 → Forbidden`, `404 → NotFound`, `409 → Conflict`, default → `ServerFailure`.
- unexpected (non-Dio) exception → `Left(UnknownFailure)` **and** `logger.error` verified
  (the outer catch-all).
- All driven with an `int` id argument, for both `assignModerator` and `revokeModerator`.

**Cubit (`bloc_test`)** —
`test/features/users/0033_moderator_contract/application/assign_moderator_cubit_test.dart`:
- `assign(<int>)` → `[loading, success(isModerator: true)]`.
- `revoke(<int>)` → `[loading, success(isModerator: false)]`.
- failure → `[loading, error(<Failure>)]`.
- Driven with `int userId`.

**Button (widget)** —
`test/features/users/0033_moderator_contract/presentation/assign_moderator_button_test.dart`:
- built with `userId:`; when `isModerator` is false the button shows "Assign" and tapping
  triggers `assign(<int>)`; when true it shows "Revoke" and tapping triggers
  `revoke(<int>)`; the in-flight loading spinner renders; an error state shows the
  snackbar. Mocked cubit injected via `getIt.registerFactory` + `unregister` in tear-down
  (the button creates its cubit through `getIt`).

---

## 7. Report (what the implementer must hand back)

- Files changed: the port, the two use-cases, the adapter, the cubit, the button (state
  unchanged), the `_shared` API client, and `user_details_screen.dart` — plus regenerated
  `users_api_client.g.dart`.
- Confirmation that `assignModerator` stayed **singular** `/user/{user_id}/...` and
  `revokeModerator` is **plural** `/users/{user_id}/...` in the regenerated client.
- Confirmation that the actions-row `username` local was **removed** (its last consumer
  gone → row fully id-keyed) and that the **app-bar title** `username` was **kept**.
- Confirmation that no **handle** was touched (title, login, create/edit form,
  `UserPostsRoute` username) and that the tier and sibling buttons were not changed.
- Confirmation that `core/` was not modified (no 0048 dependency).
- `build_runner` run after the API-client edit; `dart format` clean; `dart analyze`
  clean.
- The outside-in test is GREEN; the migrated unit/cubit/adapter/widget test files pass;
  no new failures introduced in unrelated user/auth/routing tests (route-migration slices
  are known to ripple — baseline before/after).

---

## 8. What NOT to do

- ❌ Do **not** change the backend, and do **not** normalize the revoke route to singular
  — `revokeModerator` is **plural** `/users/{user_id}/revoke-moderator` on purpose.
- ❌ Do **not** make `assignModerator` plural — it stays **singular**
  `/user/{user_id}/assign-moderator`.
- ❌ Do **not** migrate any other `UsersApiClient` method, port, or adapter — only
  `assignModerator` and `revokeModerator`.
- ❌ Do **not** add an identity guard or `CurrentUser.id` comparison to the use-cases —
  they are pure delegation; the permission gate lives in the UI + backend (no 0048 dep).
- ❌ Do **not** keep the `username != null` clause on the moderator button's visibility
  gate, and do **not** remove the `canManageModerators && isModerator != null` part.
- ❌ Do **not** remove or alter the **app-bar title** `username` — only the orphaned
  actions-row `username` local is removed.
- ❌ Do **not** touch any **handle**: the `@username` title, the `username` passed to
  `UserPostsRoute`, the create/edit-user form, login, or any displayed `@username`.
- ❌ Do **not** change the assign/revoke toggle, the `isModerator` callback, the spinner,
  the snackbar messages, or the `_mapHttp` mapping — this is a pure identifier migration.
- ❌ Do **not** hand-edit `users_api_client.g.dart` — regenerate it.
- ❌ Do **not** add a route/screen for the moderator vertical — it has none and gains none.
