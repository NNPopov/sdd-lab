# Implementation prompt: create_tier (0006)

## 1. TITLE

Task: create a new slice `create_tier` in the `tiers` feature.
The user taps the FAB on the tier list screen, lands on a form
with one field (name), fills it in and saves. On success —
snackbar "Tier created", pop back, list refreshes.

At the same time, a **preliminary refactoring task** is required:
move `TiersApiClient`, `TierDto`, and `Tier` from `list_tiers/`
to `tiers/_shared/`, since two slices will now use them together.

---

## 2. CONTEXT

```
READ:
- @CLAUDE.md in full
- @lib/features/users/create_user/**  — closest analog (do NOT copy, use as reference)
- @lib/features/tiers/list_tiers/data/tiers_api_client.dart
- @lib/features/tiers/list_tiers/data/dto/tier_dto.dart
- @lib/features/tiers/list_tiers/domain/entities/tier.dart
- @lib/features/tiers/list_tiers/data/list_tiers_adapter.dart
- @lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart
- @lib/features/tiers/list_tiers/presentation/list_tiers_route.dart
- @lib/features/tiers/tiers_feature_module.dart
- @lib/core/routing/app_router.dart       — we will add the route
- @lib/core/errors/failure.dart
- @lib/core/rbac/permission.dart          — Permission.manageTiers
- @lib/core/i18n/i18n/en.json
- @lib/core/i18n/i18n/ru.json
- @.claude/skills/bloc/SKILL.md

DO NOT READ:
- @lib/features/tiers/list_tiers/application/**
- @lib/features/tiers/list_tiers/domain/usecases/**
- @lib/features/tiers/list_tiers/domain/ports/**
- @lib/features/users/list_users/**
- @lib/features/users/edit_user/**
- @lib/features/users/delete_user/**
```

---

## 3. API

```
POST http://127.0.0.1:8000/api/v1/tier
Header: Authorization: Bearer <token>  (required — server requires authentication)
Content-Type: application/json
Body: { "name": "free" }

Response 200/201: { "id": 1, "name": "free" }
  → TierDto (already exists, id required, name String)

Errors:
- 401 — token invalid → UnauthorizedFailure
- 403 — insufficient permissions → ForbiddenFailure
- 409 — tier with this name already exists → ConflictFailure
- 422 — server-side validation error → ValidationFailure(fieldErrors)
- 5xx — server error → ServerFailure
```

Use-case return type: `Either<Failure, Tier>`.
After success the Cubit passes `Tier` to the `CreateTierSuccess(tier)` state,
so the calling screen can return it as a navigation result.

---

## 4. TARGET STRUCTURE

### Step 0 — move to _shared/ (refactoring, done FIRST)

```
lib/features/tiers/
├── _shared/
│   ├── data/
│   │   ├── dto/
│   │   │   └── tier_dto.dart          # moved from list_tiers/data/dto/
│   │   └── tiers_api_client.dart      # moved + createTier method added
│   └── domain/
│       └── entities/
│           └── tier.dart              # moved from list_tiers/domain/entities/
```

After moving:
- `list_tiers/data/dto/tier_dto.dart` — DELETE (+ .freezed.dart, .g.dart)
- `list_tiers/data/tiers_api_client.dart` — DELETE (+ .g.dart)
- `list_tiers/domain/entities/tier.dart` — DELETE
- Update imports in `list_tiers_adapter.dart`, `tiers_feature_module.dart`,
  `list_tiers/data/dto/paginated_tiers_dto.dart`

### Step 1 — new create_tier slice

```
lib/features/tiers/create_tier/
├── domain/
│   ├── entities/
│   │   └── new_tier_data.dart         # this slice's value object: { name: String }
│   ├── ports/
│   │   └── create_tier_port.dart      # Future<Either<Failure, Tier>> call(NewTierData)
│   └── usecases/
│       └── create_tier_usecase.dart   # delegates to port, checks Permission.manageTiers
├── data/
│   └── create_tier_adapter.dart       # implements CreateTierPort; double catch
├── application/
│   ├── create_tier_cubit.dart
│   └── create_tier_state.dart         # sealed: initial | submitting | success(Tier) | failure(Failure)
└── presentation/
    ├── create_tier_route.dart          # @RoutePage(), BlocProvider<CreateTierCubit>
    └── create_tier_screen.dart         # form: one name field + submit button
```

### Files being modified (not created)

| File | What changes |
|---|---|
| `tiers_feature_module.dart` | update TiersApiClient import → `_shared/data/` |
| `list_tiers/data/list_tiers_adapter.dart` | update TierDto and Tier imports → `_shared/` |
| `list_tiers/data/dto/paginated_tiers_dto.dart` | update TierDto import → `_shared/` |
| `list_tiers/presentation/list_tiers_screen.dart` | add FAB → navigate to CreateTierRoute |
| `list_tiers/presentation/list_tiers_route.dart` | add BlocListener: on pop with Tier — call refresh() |
| `core/routing/app_router.dart` | add CreateTierRoute with guards |
| `core/i18n/i18n/en.json` | add `tiers.createTier.*` keys |
| `core/i18n/i18n/ru.json` | add `tiers.createTier.*` keys |

---

## 5. WHAT TO DO

### Step 0. Move to _shared/ (refactoring)

1. Create `lib/features/tiers/_shared/data/dto/tier_dto.dart`:
   - Copy content from `list_tiers/data/dto/tier_dto.dart`
   - Update `Tier` import → `../../domain/entities/tier.dart`
   - Update `part` directives (new paths)

2. Create `lib/features/tiers/_shared/domain/entities/tier.dart`:
   - Copy content from `list_tiers/domain/entities/tier.dart` (unchanged)

3. Create `lib/features/tiers/_shared/data/tiers_api_client.dart`:
   - Move content from `list_tiers/data/tiers_api_client.dart`
   - Add `createTier` method:
     ```dart
     @POST('/tier')
     Future<TierDto> createTier(@Body() CreateTierRequestDto body);
     ```
   - `CreateTierRequestDto` — simple freezed DTO: `{ required String name }`
     Create in `_shared/data/dto/create_tier_request_dto.dart`

4. Update imports in all `list_tiers/` files:
   - `list_tiers_adapter.dart`: TierDto, Tier → `_shared/`
   - `paginated_tiers_dto.dart`: TierDto → `_shared/`
   - `tiers_feature_module.dart`: TiersApiClient → `_shared/`

5. Delete original files from `list_tiers/`:
   - `list_tiers/data/tiers_api_client.dart` and `.g.dart`
   - `list_tiers/data/dto/tier_dto.dart` and `.freezed.dart`, `.g.dart`
   - `list_tiers/domain/entities/tier.dart`

6. Run codegen: `dart run build_runner build --delete-conflicting-outputs`
   Verify that `list_tiers` compiles without errors.

### Step 1. domain (create_tier)

**`domain/entities/new_tier_data.dart`:**
```dart
class NewTierData {
  const NewTierData({required this.name});
  final String name;
}
```

**`domain/ports/create_tier_port.dart`:**
```dart
abstract class CreateTierPort {
  Future<Either<Failure, Tier>> call(NewTierData data);
}
```

**`domain/usecases/create_tier_usecase.dart`:**
- Takes `CreateTierPort` and `PermissionCubit`
- Checks `Permission.manageTiers` → `Left(const Failure.permissionDenied())`
- Delegates to the port and returns the result

### Step 2. data (create_tier)

**`data/create_tier_adapter.dart`:**
- `@LazySingleton(as: CreateTierPort)`
- Takes `TiersApiClient` and `AppLogger`
- Calls `_api.createTier(CreateTierRequestDto(name: data.name))`
- HTTP error mapping:
  - 401 → `UnauthorizedFailure`
  - 403 → `ForbiddenFailure`
  - 409 → `ConflictFailure`
  - 422 → `ValidationFailure` (parse from response data)
  - others → `ServerFailure`
- Outer `catch (e, st)` → log + `Left(const Failure.unknown())`

### Step 3. application (create_tier)

**`application/create_tier_state.dart`:** sealed via freezed:
```dart
@freezed
sealed class CreateTierState with _$CreateTierState {
  const factory CreateTierState.initial() = CreateTierInitial;
  const factory CreateTierState.submitting() = CreateTierSubmitting;
  const factory CreateTierState.success(Tier tier) = CreateTierSuccess;
  const factory CreateTierState.failure(Failure failure) = CreateTierFailure;
}
```

**`application/create_tier_cubit.dart`:**
- `@injectable`
- Takes `CreateTierUseCase`
- Method `submit(NewTierData data)`: emit submitting → use-case → fold → emit success/failure

### Step 4. presentation (create_tier)

**`presentation/create_tier_route.dart`:**
- `@RoutePage()` widget `CreateTierPage`
- `BlocProvider<CreateTierCubit>` creates via `getIt<CreateTierCubit>()`
- Wraps `CreateTierScreen`

**`presentation/create_tier_screen.dart`:**
- One `TextFormField` for `name`
- Validation: non-empty field
- `BlocConsumer`:
  - listener: `CreateTierSuccess` → snackbar + `context.router.maybePop(tier)`
  - listener: `CreateTierFailure` + `ValidationFailure` → server errors into form
  - listener: `CreateTierFailure` + `ConflictFailure` → snackbar with message
  - listener: other `CreateTierFailure` → generic error snackbar
  - builder: disables button during `CreateTierSubmitting`

### Step 5. Integration (changes in existing files)

**`list_tiers/presentation/list_tiers_screen.dart`:**
- Add `floatingActionButton: FloatingActionButton(...)` to `Scaffold`
- In `onPressed`:
  ```dart
  final tier = await context.router.push<Tier>(CreateTierRoute());
  if (tier != null && mounted) {
    context.read<ListTiersCubit>().refresh();
  }
  ```
- Icon `Icons.add`, tooltip — `t.tiers.createTier.fabTooltip`

**`core/routing/app_router.dart`:**
- Add import `create_tier_route.dart`
- Add route:
  ```dart
  AutoRoute(
    page: CreateTierRoute.page,
    path: '/tiers/new',
    guards: [
      authGuard,
      PermissionGuard({Permission.manageTiers}, permissionCubit),
    ],
  ),
  ```
  IMPORTANT: add **before** the `list_tiers` route, since auto_route
  matches in order.

### Step 6. Localization

**`en.json`** — add to the `tiers` section:
```json
"createTier": {
  "title": "Create Tier",
  "name": "Name",
  "submit": "Create",
  "fabTooltip": "Add tier",
  "success": "Tier created",
  "errors": {
    "required": "This field is required",
    "generic": "Failed to create tier"
  }
}
```

**`ru.json`** — add the equivalent block with Russian translations.

After editing run: `dart run slang`

---

## 6. TESTS

```
test/features/tiers/create_tier/
├── domain/usecases/create_tier_usecase_test.dart
├── data/create_tier_adapter_test.dart
└── application/create_tier_cubit_test.dart
```

**`create_tier_usecase_test.dart`:**
- `manageTiers` in permissions → delegates to port, returns Right(tier)
- `manageTiers` in permissions → port returned Left(failure) → returns Left(failure)
- `manageTiers` NOT in permissions → Left(PermissionDenied), port NOT called

**`create_tier_adapter_test.dart`:**
- success: api returned TierDto → Right(Tier)
- DioException 401 → Left(UnauthorizedFailure)
- DioException 403 → Left(ForbiddenFailure)
- DioException 409 → Left(ConflictFailure)
- DioException 422 → Left(ValidationFailure)
- DioException 5xx → Left(ServerFailure)
- Unexpected Exception (TypeError) → Left(UnknownFailure), logger.error called with stackTrace

**`create_tier_cubit_test.dart`:**
- submit success → emits [submitting, success(tier)]
- submit failure → emits [submitting, failure(failure)]

---

## 7. REPORT

Upon completion provide:

- List of all created files
- List of all modified files
- Confirmation that the `list_tiers` slice is not broken (all tests green)
- Confirmation that codegen was run (`build_runner` + `slang`)
- UX walkthrough:
  1. Open the tiers screen
  2. Tap FAB → navigate to the create form
  3. Submit empty form → see validation error
  4. Fill in name → submit → snackbar "Tier created", return to list
  5. List refreshed (new tier is visible)
  6. Try to create a tier with the same name → ConflictFailure snackbar

---

## 8. WHAT NOT TO DO

- Do NOT add the `createTier` method to `list_tiers/data/tiers_api_client.dart` —
  the file is being moved to `_shared/`, the old one is deleted
- Do NOT create a separate API client for `create_tier` — use the shared one from `_shared/`
- Do NOT add fields other than `name` to the form — the API only accepts `name`
- Do NOT check permissions only in the UI — the use-case must check `Permission.manageTiers`
- Do NOT call `context.router.pop()` without passing `tier` — the list won't know about success
- Do NOT use `BlocListener` in `list_tiers_route.dart` for refresh —
  `await router.push` and checking the result in `list_tiers_screen.dart` is sufficient
- Do NOT touch other features (`users`, `auth`)
- Do NOT add new dependencies to `pubspec.yaml` — everything is already there
