# Feature Spec — 0054 user_tier_routes_to_user_id

> Implementation plan for the slice. Source: `prd.md` (this folder) + the two current
> tier slices (`get_user_tier`, `update_user_tier`) + the closest route-migration
> analog (`0049_delete_user_route_to_user_id`). Written after confirming this slice has
> **no** 0048 dependency: neither tier use-case compares identity — the read path has no
> guard, and the update guard is `isSuperuser` (sourced from `AuthCubit`), not an id
> comparison.

---

## 1. Header

Migrate the **two user-tier verticals** — `get_user_tier` (read) and
`update_user_tier` (write) — from username-as-identity to `int userId`, end to end and
**without behavior change**. For each vertical the API method, port, adapter, use-case,
and cubit switch their target identifier from `String username` to `int userId`; the
update vertical also switches its button and bottom sheet. The `isSuperuser` guard in
`UpdateUserTierUseCase`, the tier dropdown, the submit/success/error flow, the
snackbars, and the read-path failure mapping (incl. `404 → "Tier not assigned"`) are
all unchanged.

Per `CONTEXT.md`, the value passed into `getUserTier(...)` / `patchUserTier(...)` is
**path-identity** — it names *which* user the tier request targets — so it migrates to
`user_id: int`. No **handle** is touched: the `@username` title, the post-navigation
`username`, and `AssignModeratorButton`'s identifier all stay. The target id is the
viewed `User.id`, already present in `UserDetailsCubit` state and at
`UserDetailsScreen.userId`.

This is a **modification of two existing, green slices** (not a new slice). Per the
"Modifying an existing slice" rule in `CLAUDE.md`, the contract change is driven from
the spec/test chain first; the outside-in test represents the **new** (id) contract.
Two verticals are bundled into one slice because they share the same screen surface,
the same `_shared/users_api_client.dart`, and the same identity-migration rationale.

---

## 2. Context

**READ:**
- `@CLAUDE.md` — fully.
- `@specs/features/users/0054_user_tier_routes_to_user_id/prd.md` — the product spec.
- The whole **get_user_tier** vertical (unit being modified):
  - `@lib/features/users/get_user_tier/domain/ports/get_user_tier_port.dart`
  - `@lib/features/users/get_user_tier/domain/usecases/get_user_tier_usecase.dart`
  - `@lib/features/users/get_user_tier/data/get_user_tier_adapter.dart`
  - `@lib/features/users/get_user_tier/application/get_user_tier_cubit.dart`
  - `@lib/features/users/get_user_tier/application/get_user_tier_state.dart` — confirm
    no identifier in state (read-only check).
- The **update_user_tier** vertical (unit being modified) — only the
  `update_user_tier` path (NOT `fetch_tiers`, see below):
  - `@lib/features/users/update_user_tier/domain/ports/update_user_tier_port.dart`
  - `@lib/features/users/update_user_tier/domain/usecases/update_user_tier_usecase.dart`
  - `@lib/features/users/update_user_tier/data/update_user_tier_adapter.dart`
  - `@lib/features/users/update_user_tier/application/update_user_tier_cubit.dart`
  - `@lib/features/users/update_user_tier/application/update_user_tier_state.dart` —
    confirm no identifier in state (read-only check).
  - `@lib/features/users/update_user_tier/presentation/update_user_tier_button.dart`
  - `@lib/features/users/update_user_tier/presentation/widgets/update_user_tier_sheet.dart`
- `@lib/features/users/_shared/data/users_api_client.dart` — the `getUserTier` and
  `patchUserTier` methods whose `@GET`/`@PATCH` annotations and path params migrate
  (regen target). Both are singular `/user/` — there is **no** plural asymmetry here.
- `@lib/core/auth/application/auth_cubit.dart` — `currentUser.isSuperuser` getter used
  by `UpdateUserTierCubit`. Unchanged by this slice; read-only dependency.
- `@lib/features/users/user_details/presentation/user_details_screen.dart` — the
  **cross-slice edit site**: the two `GetUserTierCubit.load(...)` call sites and the
  `UpdateUserTierButton` construction in the actions row.
- `@lib/features/users/user_details/presentation/user_action_visibility.dart` — confirm
  `canEditTier`; the visibility gate drops the `username != null` clause.
- `@.claude/skills/bloc/SKILL.md` — Cubit conventions.
- Prior art (lean on, do **not** copy):
  - `@specs/features/users/0049_delete_user_route_to_user_id/plan.md` and
    `@test/features/users/0049_delete_user_route_to_user_id/delete_user_route_to_user_id_outside_in_test.dart`
    — id-contract outside-in shape, mocked at the `UsersApiClient` boundary, with a
    mocked `AuthCubit`.
  - The existing `get_user_tier` and `update_user_tier` unit/cubit/widget tests —
    migrated in place from the username contract to the id contract.

**DO NOT READ:**
- The **fetch_tiers** half of `update_user_tier` (`fetch_tiers_port.dart`,
  `fetch_tiers_usecase.dart`, `fetch_tiers_adapter.dart`, `getTiersForSelection`,
  the tier-option DTOs/entities). `getTiersForSelection` is `/tiers` — it carries no
  user identity and does **not** migrate.
- The moderator vertical (`moderator_contract`, `assignModerator`/`revokeModerator`) —
  slice 0055; `AssignModeratorButton` stays username-keyed.
- Sibling actions-row slices (`delete_user`, `erase_db_user`, `edit_user`) — already
  migrated or out of scope; this slice does not touch them.
- Other `users` slices (`list_users`, `create_user`), any `posts`/`tiers`/`auth` slice.
- Generated files (`*.g.dart`, `*.freezed.dart`, `*.config.dart`) — regenerated, not
  hand-edited.

---

## 3. API

Two routes migrate; bodies and response shapes are unchanged.

```
GET   http://127.0.0.1:8000/api/v1/user/{user_id}/tier     ← was /user/{username}/tier
Header: Authorization: Bearer <token>
Response 200: UserTierDto (tier_name, tier_created_at, …) — unchanged
Returns: Future<UserTierDto>

PATCH http://127.0.0.1:8000/api/v1/user/{user_id}/tier     ← was /user/{username}/tier
Header: Authorization: Bearer <token>
Body: UpdateUserTierRequestDto { tier_id: int }            — unchanged
Returns: Future<void>  (success = no throw)
```

**Path parameter:** `user_id` is an **integer** on both routes. The retrofit
annotations become:
- `@GET('/user/{user_id}/tier')` with `@Path('user_id') int userId`.
- `@PATCH('/user/{user_id}/tier')` with `@Path('user_id') int userId` (body arg
  unchanged).

Both routes are **singular** `/user/`; the intentional plural
`/users/{user_id}/revoke-moderator` asymmetry belongs only to the moderator routes
(slice 0055) and is out of scope here.

**Errors — read path (`get_user_tier`), mapping preserved exactly:**
- `401` → `UnauthorizedFailure(message: detail ?? 'Session expired')`.
- `403` → `ForbiddenFailure(message: detail ?? 'Forbidden')`.
- `404` → `NotFoundFailure(message: 'Tier not assigned')` — the "Tier not assigned"
  not-found case.
- default → `e.error` if it is a `Failure`, else `NetworkFailure(message: e.message)`.
- any other thrown object → `UnknownFailure` + `logger.error` (catch-all).

**Errors — write path (`update_user_tier`), mapping preserved exactly:**
- `401` → `UnauthorizedFailure(message: 'Session expired')`.
- `403` → `ForbiddenFailure(message: 'Permission denied')`.
- `404` → `NotFoundFailure(message: 'User or tier not found')`.
- default → `ServerFailure(statusCode: e.response?.statusCode)`.
- any other thrown object → `UnknownFailure` + `logger.error` (catch-all).

The `isSuperuser == false` guard short-circuits in the use-case **before** the adapter
is reached → `PermissionDenied`, no HTTP call.

---

## 4. Structure

No files are created or deleted. Both verticals keep their current shape (no own
screen/route — presentation is a button + sheet embedded in `user_details_screen`).
Only signatures and the path/param of existing files change:

```
lib/features/users/get_user_tier/
├── domain/
│   ├── ports/
│   │   └── get_user_tier_port.dart        # call(String username) → call(int userId)
│   └── usecases/
│       └── get_user_tier_usecase.dart     # call(String username) → call(int userId); pure delegation
├── data/
│   └── get_user_tier_adapter.dart         # param int userId; _api.getUserTier(userId); mapping unchanged
└── application/
    ├── get_user_tier_cubit.dart           # load(String username) → load(int userId)
    └── get_user_tier_state.dart           # UNCHANGED (no identifier in state)

lib/features/users/update_user_tier/
├── domain/
│   ├── ports/
│   │   └── update_user_tier_port.dart     # call({String username, int tierId}) → call({int userId, int tierId})
│   └── usecases/
│       └── update_user_tier_usecase.dart  # call({String username,…}) → call({int userId,…}); isSuperuser guard UNCHANGED
├── data/
│   └── update_user_tier_adapter.dart      # param int userId; _api.patchUserTier(userId, body); mapping unchanged
├── application/
│   ├── update_user_tier_cubit.dart        # submit(String username) → submit(int userId); isSuperuser source unchanged
│   └── update_user_tier_state.dart        # UNCHANGED (no identifier in state)
└── presentation/
    ├── update_user_tier_button.dart       # UpdateUserTierButton(int userId) → sheet
    └── widgets/
        └── update_user_tier_sheet.dart    # UpdateUserTierSheet(int userId); _TiersBody(int userId) → submit(userId)

OUT OF SCOPE within update_user_tier (do NOT touch):
  fetch_tiers_port.dart, fetch_tiers_usecase.dart, fetch_tiers_adapter.dart,
  getTiersForSelection (/tiers), the tier-option DTOs/entities — no user identity.

lib/features/users/_shared/data/
└── users_api_client.dart                  # @GET('/user/{user_id}/tier')  Future<UserTierDto> getUserTier(@Path('user_id') int userId)
                                            # @PATCH('/user/{user_id}/tier') Future<void> patchUserTier(@Path('user_id') int userId, @Body() …)
                                            # ← REQUIRES build_runner regen of users_api_client.g.dart

CROSS-SLICE (in scope, surgical — single screen):
lib/features/users/user_details/presentation/
└── user_details_screen.dart               # (a) both GetUserTierCubit.load(...) call sites: user.username → user.id
                                            # (b) UpdateUserTierButton(userId: widget.userId) — constructed with the screen's id
                                            # (c) drop the `username != null` clause on the tier button; gate on canEditTier only
                                            # (d) the `username` local STAYS for AssignModeratorButton (slice 0055)
```

---

## 5. What to do (by layer)

Migrate each vertical inside-out, then the shared client, finishing with the
cross-slice screen.

**1) `_shared` — API client (regen target).** In `users_api_client.dart`:
```dart
@GET('/user/{user_id}/tier')
Future<UserTierDto> getUserTier(@Path('user_id') int userId);

@PATCH('/user/{user_id}/tier')
Future<void> patchUserTier(
  @Path('user_id') int userId,
  @Body() UpdateUserTierRequestDto body,
);
```
Then run `dart run build_runner build --delete-conflicting-outputs` to regenerate
`users_api_client.g.dart`. **Only these two methods change** — `getTiersForSelection`,
`assignModerator`, `revokeModerator`, and any remaining `{username}` method stay
untouched; their migration is out of scope.

**2) get_user_tier — port.** `get_user_tier_port.dart`:
```dart
Future<Either<Failure, UserTier>> call(int userId);
```

**3) get_user_tier — use-case (no guard).** `get_user_tier_usecase.dart`:
```dart
Future<Either<Failure, UserTier>> call(int userId) => _port(userId);
```
Pure delegation — no permission check on the read path.

**4) get_user_tier — adapter.** `get_user_tier_adapter.dart`: parameter becomes
`int userId`; the call becomes `_api.getUserTier(userId)`. The double `try`
(DioException switch + catch-all `catch (e, st)` with `logger.error`) and the
`401 / 403 / 404="Tier not assigned" / default` mapping are **copied verbatim** — only
the parameter type and the argument change.

**5) get_user_tier — cubit.** `get_user_tier_cubit.dart`:
```dart
Future<void> load(int userId) async {
  emit(const GetUserTierState.loading());
  final result = await _getUserTier(userId);
  result.fold(
    (f) => emit(GetUserTierState.error(f)),
    (tier) => emit(GetUserTierState.loaded(tier)),
  );
}
```
`get_user_tier_state.dart` is **unchanged**.

**6) update_user_tier — port.** `update_user_tier_port.dart`:
```dart
Future<Either<Failure, Unit>> call({
  required int userId,
  required int tierId,
});
```

**7) update_user_tier — use-case (guard stays here).** `update_user_tier_usecase.dart`:
```dart
Future<Either<Failure, Unit>> call({
  required int userId,
  required int tierId,
  required bool isSuperuser,
}) async {
  if (!isSuperuser) return const Left(Failure.permissionDenied());
  return _port(userId: userId, tierId: tierId);
}
```
The `if (!isSuperuser) → Left(PermissionDenied)` guard is **unchanged** and stays in
the use-case (CLAUDE.md forbids UI-only permission checks). It does **not** compare ids
— hence no 0048 dependency.

**8) update_user_tier — adapter.** `update_user_tier_adapter.dart`: parameter becomes
`int userId`; the call becomes `_api.patchUserTier(userId, UpdateUserTierRequestDto(tierId: tierId))`.
The double `try` + catch-all `logger.error` and the `401 / 403 / 404 / default-server`
mapping are **copied verbatim**.

**9) update_user_tier — cubit.** `update_user_tier_cubit.dart`:
```dart
Future<void> submit(int userId) async {
  final s = state;
  if (s is! UpdateUserTierTiersLoaded || s.selectedTierId == null) return;
  final tierId = s.selectedTierId!;
  final isSuperuser = _auth.currentUser?.isSuperuser ?? false;
  emit(UpdateUserTierState.submitting(tiers: s.tiers, selectedTierId: tierId));
  final result = await _updateTier(
    userId: userId,
    tierId: tierId,
    isSuperuser: isSuperuser,
  );
  result.fold(
    (f) => emit(UpdateUserTierState.error(f)),
    (_) => emit(const UpdateUserTierState.success()),
  );
}
```
`loadTiers`, `selectTier`, `reset`, the `isSuperuser` source
(`_auth.currentUser?.isSuperuser ?? false`), and the state machine
(`loadingTiers / tiersLoaded / submitting / success / error`) are **unchanged**.
`update_user_tier_state.dart` is **unchanged**.

**10) update_user_tier — button + sheet.**
- `update_user_tier_button.dart`: `UpdateUserTierButton` takes `final int userId`; pass
  it to `UpdateUserTierSheet(userId: userId)`. The `loadTiers` on open and `reset` on
  close are unchanged.
- `update_user_tier_sheet.dart`: `UpdateUserTierSheet` and the inner `_TiersBody` take
  `final int userId` instead of `String username`; the confirm `FilledButton` calls
  `context.read<UpdateUserTierCubit>().submit(userId)`. The dropdown, the
  success-closes-sheet listener, and `_ErrorBody` are unchanged.

**11) Cross-slice — user_details_screen.** In `user_details_screen.dart`:
- **Both `GetUserTierCubit.load(...)` call sites** switch from the handle to the id:
  - initial load on `UserDetailsLoaded`: `load(state.user.id)`.
  - refresh on `UpdateUserTierSuccess`: `load(detailsState.user.id)`.
- The tier button is constructed with the **screen's** id and its visibility gate drops
  the `username != null` clause — mirroring the migrated delete button:
  ```dart
  if (visibility.canEditTier)
    UpdateUserTierButton(userId: userId),
  ```
  (`userId` here is the `_UserDetailsAppBarActions.userId` field already in scope.)
- The `username` local in `_UserDetailsAppBarActions` **stays**, because
  `AssignModeratorButton` still consumes it (moderator routes are slice 0055). This
  leaves the actions row in the same accepted **mixed-key** state established by 0049 —
  not a regression.

**12) Localization.** No new strings — all `users.updateTier.*` and `users.details.*`
keys already exist. No `slang` regen.

---

## 6. Tests

The acceptance gate is the slice outside-in test (id contract) covering **both** paths.
Unit/cubit/widget tests are migrated from username to id as the final step. All four
layers stay covered for both verticals.

**Slice outside-in (acceptance gate) —**
`test/features/users/0054_user_tier_routes_to_user_id/user_tier_routes_to_user_id_outside_in_test.dart`:
- Wires the **real** adapter + use-case + cubit for **each** path; mocks
  `UsersApiClient` and (for the write path) `AuthCubit` to supply `isSuperuser`.
- **Read, success:** `GetUserTierCubit.load(7)` with `apiClient.getUserTier(7)`
  answering a `UserTierDto` → emits `[loading, loaded]`, and
  `verify(() => apiClient.getUserTier(7)).called(1)` — **proves the API is called with
  the integer id**.
- **Read, 404:** `apiClient.getUserTier(7)` throws `DioException(statusCode: 404)` →
  emits `[loading, error(NotFoundFailure "Tier not assigned")]`;
  `verify(... getUserTier(7)).called(1)`.
- **Write, superuser success:** stub `currentUser.isSuperuser == true`; drive
  `loadTiers` → `selectTier(<id>)` → `submit(7)` with `apiClient.patchUserTier(7, any)`
  answering normally → ends in `success`, and
  `verify(() => apiClient.patchUserTier(7, any())).called(1)` — **integer id asserted**.
- **Write, non-superuser guard:** stub `currentUser.isSuperuser == false`; after
  `loadTiers`/`selectTier`, `submit(7)` → emits `error(PermissionDenied)` and
  `verifyNever(() => apiClient.patchUserTier(any(), any()))` — guard refuses, no HTTP.

**get_user_tier use-case (unit)** —
`test/features/users/get_user_tier/domain/usecases/get_user_tier_usecase_test.dart`
(migrate existing tests username → id): delegates to the port with the given `int userId`
and returns its result (Right/Left passthrough).

**update_user_tier use-case (unit)** —
`test/features/users/update_user_tier/domain/usecases/update_user_tier_usecase_test.dart`
(migrate existing tests username → id):
- `isSuperuser == true` → delegates `_port(userId:, tierId:)`, returns its result.
- `isSuperuser == false` → `Left(PermissionDenied)`, port **never** called.

**Adapters (unit), both** —
`test/features/users/get_user_tier/data/get_user_tier_adapter_test.dart` and
`test/features/users/update_user_tier/data/update_user_tier_adapter_test.dart`:
- success: API method called with the `int` id → `Right(...)`.
- get: `401 → Unauthorized`, `403 → Forbidden`, `404 → NotFound("Tier not assigned")`,
  default → `e.error`/`NetworkFailure`.
- update: `401 → Unauthorized`, `403 → Forbidden`, `404 → NotFound`, default →
  `ServerFailure`.
- unexpected (non-Dio) exception → `Left(UnknownFailure)` **and** `logger.error` verified.
- All driven with an `int` id argument.

**Cubits (`bloc_test`)** —
`test/features/users/get_user_tier/application/get_user_tier_cubit_test.dart` and
`test/features/users/update_user_tier/application/update_user_tier_cubit_test.dart`:
- `GetUserTierCubit.load(<int>)` → `[loading, loaded]` on success; `[loading, error]` on
  failure.
- `UpdateUserTierCubit`: `loadTiers` → `tiersLoaded`; `selectTier`; `submit(<int>)` →
  `[submitting, success]`; `submit(<int>)` with non-superuser → `error(PermissionDenied)`,
  port never called. Driven with `int userId` and a stubbed `currentUser.isSuperuser`.

**Widget** —
`test/features/users/update_user_tier/presentation/…` with a mocked cubit:
`UpdateUserTierButton`/`UpdateUserTierSheet` built with `userId:` — opening the sheet
triggers `loadTiers`; confirming triggers `submit(<int>)`; success closes the sheet.

---

## 7. Report (what the implementer must hand back)

- Files changed: the 5 `get_user_tier` files touched (port, use-case, adapter, cubit;
  state unchanged), the 6 `update_user_tier` files touched (port, use-case, adapter,
  cubit, button, sheet; state unchanged), the `_shared` API client, and
  `user_details_screen.dart` — plus regenerated `users_api_client.g.dart`.
- Confirmation that the **fetch_tiers** half, the moderator vertical, and the sibling
  actions-row buttons (`AssignModeratorButton`, edit, delete, erase) were **not**
  changed, and that the `username` local in the actions row was **kept** for
  `AssignModeratorButton`.
- Confirmation that `core/` was not modified (auth is read-only here).
- `build_runner` run after the API-client edit; `dart format` clean; `dart analyze`
  clean.
- The outside-in test is GREEN; the migrated unit/cubit/adapter/widget test files pass;
  no new failures introduced in unrelated user/auth/routing tests (route-migration
  slices are known to ripple — baseline before/after).

---

## 8. What NOT to do

- ❌ Do **not** migrate `getTiersForSelection` / the `fetch_tiers` half — `/tiers`
  carries no user identity.
- ❌ Do **not** migrate the moderator routes (`assignModerator`/`revokeModerator`) or
  `AssignModeratorButton` — slice 0055, incl. the intentional plural asymmetry.
- ❌ Do **not** remove the `username` local from the user-details actions row — it still
  feeds `AssignModeratorButton`.
- ❌ Do **not** migrate any other `UsersApiClient` method, port, or adapter — only
  `getUserTier` and `patchUserTier`.
- ❌ Do **not** move the `isSuperuser` guard out of `UpdateUserTierUseCase` into the
  cubit or UI, and do **not** turn it into an id comparison — it stays exactly as is.
- ❌ Do **not** touch any **handle**: the `@username` title, the `username` passed to
  `UserPostsRoute`, the create/edit-user form, login, or any displayed `@username`.
- ❌ Do **not** change the tier panel, the bottom-sheet flow, the dropdown, the
  snackbar messages, or the not-found handling — this is a pure identifier migration.
- ❌ Do **not** hand-edit `users_api_client.g.dart` — regenerate it.
- ❌ Do **not** add a route/screen for either tier vertical — they have none and gain
  none.
