# 0011 · edit_tier — Plan

## Task

Create the `edit_tier` slice in the `tiers` feature.
Rename a tier via a separate screen with a form. Available only to `is_superuser` users.
After success — return to `tier_details` with a reload using the new name.

---

## Closest analog

`create_tier` — same single-field form screen with `BlocConsumer`.
`edit_user` — pattern "push → get result → update parent screen".

---

## Target structure

```
lib/features/tiers/edit_tier/
├── domain/
│   ├── entities/
│   │   └── edit_tier_data.dart          # value object: tierCurrentName + newName
│   ├── ports/
│   │   └── edit_tier_port.dart          # Future<Either<Failure, Unit>> call(...)
│   └── usecases/
│       └── edit_tier_usecase.dart       # isSuperuser check + port call
├── data/
│   ├── dto/
│   │   └── edit_tier_request_dto.dart   # freezed + json_serializable: {name}
│   └── edit_tier_adapter.dart           # @LazySingleton(as: EditTierPort)
├── application/
│   ├── edit_tier_cubit.dart
│   └── edit_tier_state.dart             # sealed: Initial | Submitting | Success | Failure
└── presentation/
    ├── edit_tier_screen.dart
    └── edit_tier_route.dart             # @RoutePage(), receives tierName from PathParam
```

**Existing files being modified:**

| File | What changes |
|---|---|
| `tiers/_shared/data/tiers_api_client.dart` | Add `patchTier(String name, EditTierRequestDto body)` |
| `tiers/tier_details/presentation/tier_details_screen.dart` | Add edit button to AppBar (only for `isSuperuser`) |
| `core/routing/app_router.dart` | Register `EditTierRoute` with `PermissionGuard({Permission.manageTiers})` |
| `core/i18n/i18n/en.json` + `ru.json` | Add `tiers.editTier.*` keys |

---

## Step-by-step implementation

### Step 1 — `_shared/data`: add endpoint to the API client

File: `tiers/_shared/data/tiers_api_client.dart`

Add method:
```dart
@PATCH('/tier/{name}')
Future<void> patchTier(
  @Path('name') String name,
  @Body() EditTierRequestDto body,
);
```

Create DTO: `tiers/edit_tier/data/dto/edit_tier_request_dto.dart`
```dart
@freezed
sealed class EditTierRequestDto with _$EditTierRequestDto {
  const factory EditTierRequestDto({required String name}) = _EditTierRequestDto;
  factory EditTierRequestDto.fromJson(Map<String, dynamic> json) =>
      _$EditTierRequestDtoFromJson(json);
}
```

### Step 2 — Domain

**`domain/entities/edit_tier_data.dart`** — slice value object:
```dart
class EditTierData {
  const EditTierData({required this.tierCurrentName, required this.newName});
  final String tierCurrentName;
  final String newName;
}
```

**`domain/ports/edit_tier_port.dart`** — narrow port:
```dart
abstract class EditTierPort {
  Future<Either<Failure, Unit>> call({
    required EditTierData data,
    required bool isSuperuser,
  });
}
```

**`domain/usecases/edit_tier_usecase.dart`** — orchestration:
- If `!isSuperuser` → `return Left(const Failure.permissionDenied())`
- Otherwise → delegate to port
- Returns `Either<Failure, Unit>`

### Step 3 — Data

**`data/edit_tier_adapter.dart`** — `@LazySingleton(as: EditTierPort)`:
- Inner `try` → `on DioException` → mapping:
  - 404 → `NotFoundFailure`
  - 403 → `ForbiddenFailure`
  - other → `ServerFailure`
- Outer `catch (e, st)` → `_logger.error(...)` → `Left(Failure.unknown())`

### Step 4 — Application

**`application/edit_tier_state.dart`** — sealed via freezed:
```dart
@freezed
sealed class EditTierState with _$EditTierState {
  const factory EditTierState.initial() = EditTierInitial;
  const factory EditTierState.submitting() = EditTierSubmitting;
  const factory EditTierState.success({required String newName}) = EditTierSuccess;
  const factory EditTierState.failure(Failure failure) = EditTierFailure;
}
```

**`application/edit_tier_cubit.dart`**:
```dart
Future<void> submit({
  required EditTierData data,
  required bool isSuperuser,  // passed from presentation
}) async {
  emit(const EditTierSubmitting());
  final result = await _useCase(data: data, isSuperuser: isSuperuser);
  result.fold(
    (f) => emit(EditTierFailure(f)),
    (_) => emit(EditTierSuccess(newName: data.newName)),
  );
}
```

### Step 5 — Presentation

**`presentation/edit_tier_route.dart`** — `@RoutePage()`:
- Receives `@PathParam('name') String tierName`
- `BlocProvider(create: (_) => getIt<EditTierCubit>(), child: EditTierScreen(tierName: tierName))`

**`presentation/edit_tier_screen.dart`** — analogous to `create_tier_screen.dart`:
- Form with one `TextFormField` (name), pre-populated from `widget.tierName`
- `BlocConsumer`:
  - `listener`: `EditTierSuccess` → snackbar + `context.router.maybePop(newName)`
  - `listener`: `EditTierFailure` → snackbar with `_errorMessage(failure, t)`
  - `builder`: disables button during `EditTierSubmitting`
- `_submit()` reads `AuthCubit.currentUser?.isSuperuser ?? false` from context and passes it to the cubit

### Step 6 — Integration into existing files

**`tier_details_screen.dart`** — add edit button:
- Wrap actions in `BlocBuilder<AuthCubit, AuthState>`
- Show `IconButton(Icons.edit)` only if `currentUser?.isSuperuser == true`
- On press:
  ```dart
  final newName = await context.router.push<String>(
    EditTierRoute(tierName: widget.tierName),
  );
  if (!mounted || newName == null) return;
  unawaited(context.router.replace(TierDetailsRoute(tierName: newName)));
  ```
- IMPORTANT: `context.router.replace` is needed because the URL contains the tier name (`/tier/:name`). After renaming the old URL is stale.

**`app_router.dart`** — add route:
```dart
AutoRoute(
  page: EditTierRoute.page,
  path: '/tier/:name/edit',
  guards: [
    authGuard,
    PermissionGuard({Permission.manageTiers}, permissionCubit),
  ],
),
```

### Step 7 — Localization

Add keys to `en.json` and `ru.json` under `tiers.editTier`:

```json
"editTier": {
  "title": "Edit Tier",
  "name": "Name",
  "save": "Save",
  "success": "Tier updated",
  "errors": {
    "required": "This field is required",
    "notFound": "Tier not found",
    "permissionDenied": "Access denied",
    "generic": "Failed to update tier"
  }
}
```

After adding keys: `dart run slang`.

### Step 8 — Tests

`test/features/tiers/edit_tier/`

**`application/edit_tier_cubit_test.dart`**:
- `submit(isSuperuser: true)` + useCase success → emits `[Submitting, Success(newName)]`
- `submit(isSuperuser: true)` + useCase returns `NotFoundFailure` → emits `[Submitting, Failure(NotFoundFailure)]`
- `submit(isSuperuser: false)` → useCase returns `PermissionDenied` → emits `[Submitting, Failure(PermissionDenied)]`

**`data/edit_tier_adapter_test.dart`**:
- API 200 → `Right(unit)`
- API 404 → `Left(NotFoundFailure)`
- API 403 → `Left(ForbiddenFailure)`
- unexpected exception → `Left(UnknownFailure)`, `logger.error` called with stackTrace

**`domain/usecases/edit_tier_usecase_test.dart`**:
- `isSuperuser: false` → `Left(PermissionDenied)`, port NOT called
- `isSuperuser: true` + port success → `Right(unit)`
- `isSuperuser: true` + port failure → propagates `Left(failure)`

---

## Codegen

After all changes:
```
dart run build_runner build --delete-conflicting-outputs
dart run slang
```

---

## What NOT to do

- Do NOT add an edit button to `list_tiers` — only from `tier_details`
- Do NOT use `context.router.pop()` without returning `newName` — tier_details won't be able to update
- Do NOT return the full `TierDetail` object from edit — the API returns only `{"message": "Tier updated"}`, `newName` is known on the client
- Do NOT check permissions only in the UI — the use-case must check `isSuperuser` and return `Left(PermissionDenied)` as the final line of defense
- Do NOT add `Permission.editTiers` — use the existing `manageTiers` at the route level (RBAC guard), `isSuperuser` is checked separately in the use-case as a more precise predicate
- Do NOT make `patchTier` a separate API client — the method is added to the shared `TiersApiClient`
- Do NOT touch other tier slices (`list_tiers`, `create_tier`)
