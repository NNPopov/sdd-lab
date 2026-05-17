# 0012 delete_tier — Implementation Plan

Task: create a new slice `delete_tier` in the `tiers` feature.
Delete a tier from the details screen: confirmation dialog,
snackbar on success/error, `router.pop()` to `list_tiers` + list refresh.

---

====== CONTEXT ======

READ:
- @CLAUDE.md in full
- @lib/features/users/delete_user/** — closest analog (do NOT copy, use as reference)
- @lib/features/tiers/_shared/data/tiers_api_client.dart — will add deleteTier
- @lib/features/tiers/tier_details/presentation/tier_details_screen.dart — will add button
- @lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart — will add refresh after pop
- @lib/features/tiers/edit_tier/domain/usecases/edit_tier_usecase.dart — isSuperuser pattern in use-case
- @lib/core/errors/failure.dart
- @lib/core/auth/application/auth_cubit.dart
- @lib/core/routing/app_router.dart
- @lib/core/i18n/i18n/en.json
- @lib/core/i18n/i18n/ru.json
- @.claude/skills/bloc/SKILL.md

DO NOT READ:
- @lib/features/tiers/create_tier/**
- @lib/features/tiers/list_tiers/application/**, data/**, domain/**
- @lib/features/tiers/tier_details/application/**, data/**, domain/**
- @lib/features/users/list_users/**
- @lib/features/users/create_user/**
- @lib/features/auth/**

---

====== API ======

DELETE http://127.0.0.1:8000/api/v1/tier/{name}
Header: Authorization: Bearer <token>
Path parameter: name — string, tier name (e.g. "Free")

Response 200:
```json
{ "message": "Tier deleted" }
```
The response body is not used on the client — `Future<void>` is sufficient.

Errors:
- 401 — token invalid → `UnauthorizedFailure`
- 403 — no permissions (not superuser) → `ForbiddenFailure`
- 404 — tier not found → `NotFoundFailure`
- 5xx — server error → `ServerFailure`
- Network error → `NetworkFailure`

IMPORTANT: a 404 response is treated as a "soft success" in UX:
show snackbar "Tier not found" and do `router.pop()`.
The tier does not exist — the goal of deleting it is achieved.

---

====== Target structure ======

```
lib/features/tiers/delete_tier/
├── domain/
│   ├── ports/
│   │   └── delete_tier_port.dart       # Future<Either<Failure, Unit>> call(String name)
│   └── usecases/
│       └── delete_tier_usecase.dart    # checks isSuperuser, delegates to port
├── data/
│   └── delete_tier_adapter.dart        # implements DeleteTierPort
├── application/
│   ├── delete_tier_cubit.dart
│   └── delete_tier_state.dart          # sealed via freezed
└── presentation/
    ├── delete_tier_button.dart         # BlocProvider + BlocListener + IconButton
    └── widgets/
        └── delete_tier_confirmation_dialog.dart
```

Note: `delete_tier` does NOT have its own screen or route.
`presentation/` contains only widgets embedded into `tier_details_screen`.

Files being modified (outside the slice):
- `lib/features/tiers/_shared/data/tiers_api_client.dart` — add `deleteTier`
- `lib/features/tiers/tier_details/presentation/tier_details_screen.dart` — add `DeleteTierButton`
- `lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart` — await push + refresh
- `lib/core/i18n/i18n/en.json` and `ru.json` — `tiers.deleteTier` keys

---

====== WHAT TO DO ======

### 1) _SHARED: add method to TiersApiClient

File: `lib/features/tiers/_shared/data/tiers_api_client.dart`

Add method:
```dart
@DELETE('/tier/{name}')
Future<void> deleteTier(@Path('name') String name);
```

After changes run `dart run build_runner build --delete-conflicting-outputs`
to regenerate `tiers_api_client.g.dart`.

---

### 2) DOMAIN: Port

File: `lib/features/tiers/delete_tier/domain/ports/delete_tier_port.dart`

```dart
abstract class DeleteTierPort {
  Future<Either<Failure, Unit>> call(String name);
}
```

---

### 3) DOMAIN: UseCase

File: `lib/features/tiers/delete_tier/domain/usecases/delete_tier_usecase.dart`

Analogous to `edit_tier_usecase.dart` — takes `isSuperuser` bool,
returns `Left(Failure.permissionDenied())` if false:

```dart
@injectable
class DeleteTierUseCase {
  const DeleteTierUseCase(this._port);
  final DeleteTierPort _port;

  Future<Either<Failure, Unit>> call({
    required String name,
    required bool isSuperuser,
  }) {
    if (!isSuperuser) {
      return Future.value(const Left(Failure.permissionDenied()));
    }
    return _port(name);
  }
}
```

No separate domain entity: `name` is a primitive `String`, no value object needed.

---

### 4) DATA: Adapter

File: `lib/features/tiers/delete_tier/data/delete_tier_adapter.dart`

Analogous to `delete_user_adapter.dart`. Double catch is mandatory (CLAUDE.md §8.4):

```dart
@LazySingleton(as: DeleteTierPort)
class DeleteTierAdapter implements DeleteTierPort {
  DeleteTierAdapter(this._api, this._logger);
  final TiersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, Unit>> call(String name) async {
    try {
      try {
        await _api.deleteTier(name);
        return const Right(unit);
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } catch (e, st) {
      _logger.error('DeleteTierAdapter.call failed', error: e, stackTrace: st);
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) => switch (e.response?.statusCode) {
    401 => Failure.unauthorized(message: e.message ?? ''),
    403 => Failure.forbidden(message: e.message ?? ''),
    404 => const Failure.notFound(),
    _ => Failure.server(statusCode: e.response?.statusCode, message: e.message),
  };
}
```

---

### 5) APPLICATION: State

File: `lib/features/tiers/delete_tier/application/delete_tier_state.dart`

Sealed class via freezed, analogous to `delete_user_state.dart`:

```dart
@freezed
sealed class DeleteTierState with _$DeleteTierState {
  const factory DeleteTierState.initial()            = DeleteTierInitial;
  const factory DeleteTierState.confirming()         = DeleteTierConfirming;
  const factory DeleteTierState.deleting()           = DeleteTierDeleting;
  const factory DeleteTierState.success()            = DeleteTierSuccess;
  const factory DeleteTierState.notFound()           = DeleteTierNotFound;   // 404 — soft success
  const factory DeleteTierState.failure(Failure failure) = DeleteTierFailure;
}
```

IMPORTANT: `notFound` is a separate state (not `failure`), because in the UI
it is handled differently: pop + specific snackbar instead of "stay on screen".

---

### 6) APPLICATION: Cubit

File: `lib/features/tiers/delete_tier/application/delete_tier_cubit.dart`

Analogous to `delete_user_cubit.dart`, but without forceLogout.
Takes `AuthCubit` to get `isSuperuser`:

```dart
@injectable
class DeleteTierCubit extends Cubit<DeleteTierState> {
  DeleteTierCubit(this._deleteTier, this._authCubit)
      : super(const DeleteTierState.initial());

  final DeleteTierUseCase _deleteTier;
  final AuthCubit _authCubit;

  void requestConfirmation() => emit(const DeleteTierState.confirming());

  void cancel() {
    if (state is DeleteTierConfirming) {
      emit(const DeleteTierState.initial());
    }
  }

  Future<void> confirmAndDelete(String tierName) async {
    emit(const DeleteTierState.deleting());
    final isSuperuser = _authCubit.currentUser?.isSuperuser ?? false;
    final result = await _deleteTier(name: tierName, isSuperuser: isSuperuser);
    result.fold(
      (failure) => failure is NotFoundFailure
          ? emit(const DeleteTierState.notFound())
          : emit(DeleteTierState.failure(failure)),
      (_) => emit(const DeleteTierState.success()),
    );
  }
}
```

---

### 7) PRESENTATION: Confirmation dialog

File: `lib/features/tiers/delete_tier/presentation/widgets/delete_tier_confirmation_dialog.dart`

AlertDialog with the tier name in the text, Cancel / Delete buttons.
Parameter: `tierName` — displayed in the text ("Delete tier «Free»?").

---

### 8) PRESENTATION: Button

File: `lib/features/tiers/delete_tier/presentation/delete_tier_button.dart`

Analogous to `delete_account_button.dart`.
Pattern: the outer StatelessWidget creates `BlocProvider(create: (_) => getIt<DeleteTierCubit>())`,
the inner widget (`_DeleteTierButtonInner`) contains `BlocListener` + `BlocBuilder`.

Parameter: `tierName: String`.

`BlocListener` handles states:
- `DeleteTierConfirming` → show `DeleteTierConfirmationDialog`;
  if confirmed → `cubit.confirmAndDelete(tierName)`;
  if cancelled → `cubit.cancel()`
- `DeleteTierSuccess` →
  ```dart
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.t.tiers.deleteTier.success)),
  );
  context.router.pop();
  ```
- `DeleteTierNotFound` →
  ```dart
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.t.tiers.deleteTier.errors.notFound)),
  );
  context.router.pop();
  ```
- `DeleteTierFailure(:final failure)` → snackbar with `_failureMessage(failure, context)`
- `DeleteTierInitial / DeleteTierDeleting` → nothing

`BlocBuilder` renders `IconButton`:
- `DeleteTierDeleting` → `SizedBox(20x20, child: CircularProgressIndicator(strokeWidth: 2))`
- otherwise → `Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error)`
- `onPressed: null` while `isDeleting`, otherwise → `cubit.requestConfirmation()`
- tooltip: `context.t.tiers.deleteTier.tooltip`

---

### 9) INTEGRATION: tier_details_screen

File: `lib/features/tiers/tier_details/presentation/tier_details_screen.dart`

In the `BlocBuilder<AuthCubit, AuthState>` block alongside the Edit button add
`DeleteTierButton`:

```dart
if (isSuperuser) ...[
  DeleteTierButton(tierName: widget.tierName),
  IconButton(
    icon: const Icon(Icons.edit),
    onPressed: () async { ... },
  ),
],
```

IMPORTANT: Delete is to the left of Edit (standard order for destructive actions in AppBar).

---

### 10) INTEGRATION: list_tiers_screen

File: `lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart`

Modify the `onTap` in `TierTile` so that the list refreshes after returning
from the details screen (regardless of the reason — deletion, name change):

```dart
onTap: () async {
  await context.router.push(
    TierDetailsRoute(tierName: tiers[index].name),
  );
  if (context.mounted) {
    unawaited(context.read<ListTiersCubit>().refresh());
  }
},
```

IMPORTANT: always refresh the list on return from tier_details —
this is correct both for renaming (edit) and for deletion.

---

### 11) LOCALIZATION

File: `lib/core/i18n/i18n/en.json` — add to the `tiers` section:

```json
"deleteTier": {
  "tooltip": "Delete tier",
  "confirmTitle": "Delete tier",
  "confirmMessage": "Are you sure you want to delete tier \"{name}\"? This action cannot be undone.",
  "confirmButton": "Delete",
  "cancelButton": "Cancel",
  "success": "Tier deleted",
  "errors": {
    "notFound": "Tier not found",
    "forbidden": "Access denied",
    "unauthorized": "Session expired",
    "generic": "Failed to delete tier"
  }
}
```

File: `lib/core/i18n/i18n/ru.json` — likewise with Russian strings.

After changes run: `dart run slang`

---

### 12) TESTS

`test/features/tiers/delete_tier/`

**a) `application/delete_tier_cubit_test.dart`:**
- `requestConfirmation` → emits `[DeleteTierConfirming]`
- `cancel` from confirming → emits `[DeleteTierInitial]`
- `cancel` from non-confirming → emits nothing
- `confirmAndDelete` success → emits `[DeleteTierDeleting, DeleteTierSuccess]`
- `confirmAndDelete` 404 → emits `[DeleteTierDeleting, DeleteTierNotFound]`
- `confirmAndDelete` failure → emits `[DeleteTierDeleting, DeleteTierFailure]`
- `confirmAndDelete` isSuperuser=false → emits `[DeleteTierDeleting, DeleteTierFailure(PermissionDenied)]`

**b) `data/delete_tier_adapter_test.dart`:**
- API returned void → `Right(unit)`
- DioException 401 → `Left(UnauthorizedFailure)`
- DioException 403 → `Left(ForbiddenFailure)`
- DioException 404 → `Left(NotFoundFailure)`
- DioException 500 → `Left(ServerFailure)`
- unexpected Exception → `Left(UnknownFailure)`, `logger.error` called with stackTrace

---

====== REPORT ======

Upon completion provide:
- List of new files
- List of modified files outside the slice (with an explanation of each)
- Confirmation that `create_tier`, `tier_details` (domain/data/application) were not touched
- UX walkthrough: happy path + cancel + error
- Tests: number of new tests, all green

---

====== WHAT NOT TO DO ======

- Do NOT create `delete_tier_route.dart` — the slice has no route or screen
- Do NOT call `forceLogout` — deleting a tier does not invalidate the user's token
- Do NOT treat 404 as `DeleteTierFailure` — it is a separate `DeleteTierNotFound` state
  with pop navigation, not "stay on screen"
- Do NOT add a Delete button to `list_tiers_screen` (swipe/long-press) — out of scope
- Do NOT add a new `Permission` to the enum — use `isSuperuser` directly,
  analogous to `edit_tier_usecase`
- Do NOT change `tier_details` files outside of `presentation/tier_details_screen.dart`
  (do not touch tier_details domain/, data/, application/)
- Do NOT refresh only on success — always refresh the list on return
  from tier_details (covers both edit and delete)
