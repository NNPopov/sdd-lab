## Task

Create the `update_user_tier` slice in the `users` feature.

A button on the user details screen (accessible only to superusers) opens a
bottom sheet with a list of available tiers. The superuser selects a new tier,
confirms — a success snackbar is shown, and the tier in `UserDetailsView` is updated.

Slice without its own screen: only widgets embedded in `user_details_screen`.

---

## ====== CONTEXT ======

### READ:

- `@CLAUDE.md` — fully
- `@lib/features/users/get_user_tier/**` — nearest structural analog (do NOT copy, use as reference)
- `@lib/features/users/_shared/data/users_api_client.dart` — **will be modified**: add 2 methods
- `@lib/features/users/_shared/domain/entities/user.dart`
- `@lib/features/users/user_details/presentation/user_details_route.dart` — **will be modified**: BlocProvider
- `@lib/features/users/user_details/presentation/user_details_screen.dart` — **will be modified**: button + listener
- `@lib/core/auth/application/auth_cubit.dart` — for `currentUser?.isSuperuser`
- `@lib/core/auth/application/auth_state.dart`
- `@lib/core/rbac/permission.dart` — **will be modified**: add `editUserTier`
- `@lib/core/errors/failure.dart`
- `@lib/core/i18n/i18n/en.json` — **will be modified**: new keys
- `@lib/core/i18n/i18n/ru.json` — **will be modified**: new keys
- `@.claude/skills/bloc/SKILL.md`

### DO NOT READ:

- `@lib/features/users/list_users/**`
- `@lib/features/users/create_user/**`
- `@lib/features/users/edit_user/**`
- `@lib/features/users/delete_user/**`
- `@lib/features/tiers/**` — cross-feature import is forbidden

---

## ====== API ======

### 1. List of tiers (for dropdown in the bottom sheet)

```
GET /api/v1/tiers?page=1&items_per_page=100
Header: Authorization: Bearer <token>
```

Response 200:
```json
{
  "data": [
    {"id": 1, "name": "Free", "created_at": "2024-01-01T00:00:00"},
    {"id": 2, "name": "Pro",  "created_at": "2024-01-01T00:00:00"}
  ],
  "total_count": 2,
  "has_more": false
}
```

Errors:
- 401 → `UnauthorizedFailure`
- 5xx → `ServerFailure`

### 2. Update user tier

```
PATCH /api/v1/user/{username}/tier
Header: Authorization: Bearer <token>
Content-Type: application/json
Body: {"tier_id": 2}
```

Response 200:
```json
{"message": "User {name} Tier updated"}
```

The response does not contain updated data — `Future<void>` at the API client level.

Errors:
- 401 → `UnauthorizedFailure`
- 403 → `ForbiddenFailure` (no permission)
- 404 → `NotFoundFailure` (user or tier not found)
- 5xx → `ServerFailure`

---

## ====== Target structure ======

```
lib/features/users/update_user_tier/
├── domain/
│   ├── entities/
│   │   └── tier_option.dart                   # {id, name} — lightweight entity for dropdown
│   ├── ports/
│   │   ├── fetch_tiers_port.dart              # Future<Either<Failure, List<TierOption>>> call()
│   │   └── update_user_tier_port.dart         # Future<Either<Failure, Unit>> call({username, tierId})
│   └── usecases/
│       ├── fetch_tiers_usecase.dart
│       └── update_user_tier_usecase.dart      # checks isSuperuser via parameter
├── data/
│   ├── dto/
│   │   ├── tier_option_dto.dart               # {id, name} freezed + json_serializable
│   │   ├── paginated_tier_options_dto.dart    # {data: List<TierOptionDto>, ...} wrapper
│   │   └── update_user_tier_request_dto.dart  # {tier_id} freezed + json_serializable
│   ├── fetch_tiers_adapter.dart               # implements FetchTiersPort
│   └── update_user_tier_adapter.dart          # implements UpdateUserTierPort
├── application/
│   ├── update_user_tier_cubit.dart
│   └── update_user_tier_state.dart            # sealed via freezed
└── presentation/
    ├── update_user_tier_button.dart           # IconButton, opens bottom sheet
    └── widgets/
        └── update_user_tier_sheet.dart        # bottom sheet with dropdown + confirm

Files outside the slice to be modified (only these, nothing else):
- lib/features/users/_shared/data/users_api_client.dart    # + getTiersForSelection + patchUserTier
- lib/features/users/user_details/presentation/user_details_route.dart  # + BlocProvider<UpdateUserTierCubit>
- lib/features/users/user_details/presentation/user_details_screen.dart # + button + BlocListener
- lib/core/rbac/permission.dart                             # + editUserTier
- lib/core/i18n/i18n/en.json
- lib/core/i18n/i18n/ru.json
```

---

## ====== WHAT TO DO ======

### Step 0 — `core/rbac/permission.dart`

Add `editUserTier` to the `Permission` enum.

**Why:** `PermissionCubit` when `isSuperuser == true` emits `kRolePolicy[UserRole.admin]!`
= `{...Permission.values}`, meaning all enum values automatically.
`role_policy.dart` and `permission_cubit.dart` **do not touch** — the enum change propagates automatically.

---

### Step 1 — `_shared/data/users_api_client.dart`

Add two methods (before the closing brace of the class):

```dart
@GET('/tiers')
Future<PaginatedTierOptionsDto> getTiersForSelection({
  @Query('page') @Default(1) int page,
  @Query('items_per_page') @Default(100) int perPage,
});

@PATCH('/user/{username}/tier')
Future<void> patchUserTier(
  @Path('username') String username,
  @Body() UpdateUserTierRequestDto body,
);
```

`PaginatedTierOptionsDto` and `UpdateUserTierRequestDto` will be declared in step 2.
Add the corresponding imports once the DTOs are created.

**IMPORTANT:** This is a modification of a file outside the slice. Per CLAUDE.md §3.1 it must be
explicitly confirmed before modification. Since this plan.md is the approval — proceed without
an additional question.

---

### Step 2 — DOMAIN

#### `domain/entities/tier_option.dart`

```dart
// Bounded context: Tier in the update_user_tier context — only id and name for dropdown.
// Does not use Tier from features/tiers/ — this is a different context.
@freezed
sealed class TierOption with _$TierOption {
  const factory TierOption({
    required int id,
    required String name,
  }) = _TierOption;
}
```

#### `domain/ports/fetch_tiers_port.dart`

```dart
abstract class FetchTiersPort {
  Future<Either<Failure, List<TierOption>>> call();
}
```

#### `domain/ports/update_user_tier_port.dart`

```dart
abstract class UpdateUserTierPort {
  Future<Either<Failure, Unit>> call({
    required String username,
    required int tierId,
  });
}
```

#### `domain/usecases/fetch_tiers_usecase.dart`

Simple pass-through:
```dart
@injectable
class FetchTiersUseCase {
  const FetchTiersUseCase(this._port);
  final FetchTiersPort _port;
  Future<Either<Failure, List<TierOption>>> call() => _port();
}
```

#### `domain/usecases/update_user_tier_usecase.dart`

**RBAC check is passed as a parameter** (pattern from `DeleteUserUseCase` — see
`lib/features/users/delete_user/domain/usecases/delete_user_usecase.dart`):

```dart
@injectable
class UpdateUserTierUseCase {
  const UpdateUserTierUseCase(this._port);
  final UpdateUserTierPort _port;

  Future<Either<Failure, Unit>> call({
    required String username,
    required int tierId,
    required bool isSuperuser,   // passed from Cubit, checked here
  }) async {
    if (!isSuperuser) return const Left(Failure.permissionDenied());
    return _port(username: username, tierId: tierId);
  }
}
```

---

### Step 3 — DATA

#### `data/dto/tier_option_dto.dart`

```dart
@freezed
sealed class TierOptionDto with _$TierOptionDto {
  const factory TierOptionDto({
    required int id,
    @Default('') String name,
  }) = _TierOptionDto;

  factory TierOptionDto.fromJson(Map<String, dynamic> json) =>
      _$TierOptionDtoFromJson(json);
}

extension TierOptionDtoMapper on TierOptionDto {
  TierOption toDomain() => TierOption(id: id, name: name);
}
```

#### `data/dto/paginated_tier_options_dto.dart`

```dart
@freezed
sealed class PaginatedTierOptionsDto with _$PaginatedTierOptionsDto {
  const factory PaginatedTierOptionsDto({
    @Default([]) List<TierOptionDto> data,
    @JsonKey(name: 'total_count') @Default(0) int totalCount,
    @JsonKey(name: 'has_more') @Default(false) bool hasMore,
  }) = _PaginatedTierOptionsDto;

  factory PaginatedTierOptionsDto.fromJson(Map<String, dynamic> json) =>
      _$PaginatedTierOptionsDtoFromJson(json);
}
```

#### `data/dto/update_user_tier_request_dto.dart`

```dart
@freezed
sealed class UpdateUserTierRequestDto with _$UpdateUserTierRequestDto {
  const factory UpdateUserTierRequestDto({
    @JsonKey(name: 'tier_id') required int tierId,
  }) = _UpdateUserTierRequestDto;

  factory UpdateUserTierRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserTierRequestDtoFromJson(json);
}
```

#### `data/fetch_tiers_adapter.dart`

Two-level catch per CLAUDE.md §8.4:

```dart
@LazySingleton(as: FetchTiersPort)
class FetchTiersAdapter implements FetchTiersPort {
  FetchTiersAdapter(this._api, this._logger);
  final UsersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, List<TierOption>>> call() async {
    try {
      try {
        final dto = await _api.getTiersForSelection();
        return Right(dto.data.map((d) => d.toDomain()).toList());
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } catch (e, st) {
      _logger.error('FetchTiersAdapter.call failed', error: e, stackTrace: st);
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) {
    final code = e.response?.statusCode;
    return switch (code) {
      401 => Failure.unauthorized(message: 'Session expired'),
      _ => Failure.server(statusCode: code),
    };
  }
}
```

#### `data/update_user_tier_adapter.dart`

```dart
@LazySingleton(as: UpdateUserTierPort)
class UpdateUserTierAdapter implements UpdateUserTierPort {
  UpdateUserTierAdapter(this._api, this._logger);
  final UsersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, Unit>> call({
    required String username,
    required int tierId,
  }) async {
    try {
      try {
        await _api.patchUserTier(
          username,
          UpdateUserTierRequestDto(tierId: tierId),
        );
        return const Right(unit);
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } catch (e, st) {
      _logger.error('UpdateUserTierAdapter.call failed', error: e, stackTrace: st);
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) {
    final code = e.response?.statusCode;
    return switch (code) {
      401 => Failure.unauthorized(message: 'Session expired'),
      403 => Failure.forbidden(message: 'Permission denied'),
      404 => Failure.notFound(message: 'User or tier not found'),
      _ => Failure.server(statusCode: code),
    };
  }
}
```

---

### Step 4 — APPLICATION

#### `application/update_user_tier_state.dart`

```dart
@freezed
sealed class UpdateUserTierState with _$UpdateUserTierState {
  const factory UpdateUserTierState.initial() = UpdateUserTierInitial;
  const factory UpdateUserTierState.loadingTiers() = UpdateUserTierLoadingTiers;
  const factory UpdateUserTierState.tiersLoaded({
    required List<TierOption> tiers,
    int? selectedTierId,
  }) = UpdateUserTierTiersLoaded;
  const factory UpdateUserTierState.submitting({
    required List<TierOption> tiers,
    required int selectedTierId,
  }) = UpdateUserTierSubmitting;
  const factory UpdateUserTierState.success() = UpdateUserTierSuccess;
  const factory UpdateUserTierState.error(Failure failure) = UpdateUserTierError;
}
```

#### `application/update_user_tier_cubit.dart`

```dart
@injectable
class UpdateUserTierCubit extends Cubit<UpdateUserTierState> {
  UpdateUserTierCubit(
    this._fetchTiers,
    this._updateTier,
    this._auth,
  ) : super(const UpdateUserTierState.initial());

  final FetchTiersUseCase _fetchTiers;
  final UpdateUserTierUseCase _updateTier;
  final AuthCubit _auth;

  Future<void> loadTiers() async {
    emit(const UpdateUserTierState.loadingTiers());
    final result = await _fetchTiers();
    result.fold(
      (f) => emit(UpdateUserTierState.error(f)),
      (tiers) => emit(UpdateUserTierState.tiersLoaded(tiers: tiers)),
    );
  }

  void selectTier(int tierId) {
    final s = state;
    if (s is UpdateUserTierTiersLoaded) {
      emit(s.copyWith(selectedTierId: tierId));
    }
  }

  Future<void> submit(String username) async {
    final s = state;
    if (s is! UpdateUserTierTiersLoaded || s.selectedTierId == null) return;
    final tierId = s.selectedTierId!;
    final isSuperuser = _auth.currentUser?.isSuperuser ?? false;

    emit(UpdateUserTierState.submitting(tiers: s.tiers, selectedTierId: tierId));

    final result = await _updateTier(
      username: username,
      tierId: tierId,
      isSuperuser: isSuperuser,
    );

    result.fold(
      (f) => emit(UpdateUserTierState.error(f)),
      (_) => emit(const UpdateUserTierState.success()),
    );
  }

  void reset() => emit(const UpdateUserTierState.initial());
}
```

---

### Step 5 — PRESENTATION

#### `presentation/update_user_tier_button.dart`

IconButton (`Icons.swap_vert` or `Icons.edit_note`), on tap calls `loadTiers()`
and opens a bottom sheet:

```dart
class UpdateUserTierButton extends StatelessWidget {
  const UpdateUserTierButton({required this.username, super.key});
  final String username;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return IconButton(
      icon: const Icon(Icons.manage_accounts),
      tooltip: t.users.updateTier.tooltip,
      onPressed: () async {
        unawaited(context.read<UpdateUserTierCubit>().loadTiers());
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => BlocProvider.value(
            value: context.read<UpdateUserTierCubit>(),
            child: UpdateUserTierSheet(username: username),
          ),
        );
        // reset after closing so the next open starts fresh
        if (context.mounted) {
          context.read<UpdateUserTierCubit>().reset();
        }
      },
    );
  }
}
```

#### `presentation/widgets/update_user_tier_sheet.dart`

Bottom sheet with a tier dropdown and a confirm button.
- While `loadingTiers` — shows `CircularProgressIndicator`.
- On `error` — error text + Retry button (`loadTiers()`).
- On `tiersLoaded` — `DropdownButtonFormField<int>` with tiers, Confirm button.
- On `submitting` — button disabled + loading indicator.
- On `success` — `BlocListener` closes the sheet via `Navigator.pop(context)`.

**IMPORTANT**: The `success` state is handled in `user_details_screen.dart` via `BlocListener`
(step 6), not inside the sheet. The sheet closes on `success` via a listener inside the sheet itself.

---

### Step 6 — INTEGRATION

#### `user_details_route.dart`

Add `BlocProvider<UpdateUserTierCubit>` to `MultiBlocProvider`:

```dart
BlocProvider(create: (_) => getIt<UpdateUserTierCubit>()),
```

#### `user_details_screen.dart`

**Add button to AppBar:**

In the existing `BlocBuilder<PermissionCubit>` add:
```dart
final canEditTier = permissions.contains(Permission.editUserTier);
```

And in the button Row:
```dart
if (canEditTier)
  UpdateUserTierButton(username: widget.username),
```

**Add BlocListener for tier update after success:**

Wrap the existing `BlocListener<UserDetailsCubit>` in `MultiBlocListener`
(or add a separate `BlocListener<UpdateUserTierCubit>`):

```dart
BlocListener<UpdateUserTierCubit, UpdateUserTierState>(
  listener: (context, state) {
    if (state is UpdateUserTierSuccess) {
      // Update the displayed tier
      unawaited(context.read<GetUserTierCubit>().load(widget.username));
      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.users.updateTier.success)),
      );
    }
    if (state is UpdateUserTierError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_updateTierErrorMessage(state.failure, context.t))),
      );
    }
  },
),
```

Add a private method `_updateTierErrorMessage(Failure, Translations)` analogous
to the existing `_errorMessage`.

---

### Step 7 — LOCALIZATION

Add to `lib/core/i18n/i18n/en.json` in the `"users"` section:

```json
"updateTier": {
  "tooltip": "Change tier",
  "sheetTitle": "Change User Tier",
  "selectTier": "Select tier",
  "confirm": "Confirm",
  "success": "User tier updated",
  "errors": {
    "permissionDenied": "You don't have permission to change tiers.",
    "notFound": "User or tier not found.",
    "forbidden": "Permission denied.",
    "unauthorized": "Session expired.",
    "generic": "Failed to update tier. Please try again."
  }
}
```

In `ru.json` — Russian translation.

After adding the keys, run: `dart run slang`

---

### Step 8 — TESTS

```
test/features/users/update_user_tier/
├── application/
│   └── update_user_tier_cubit_test.dart
└── data/
    ├── fetch_tiers_adapter_test.dart
    └── update_user_tier_adapter_test.dart
```

#### `update_user_tier_cubit_test.dart`

- `loadTiers` success → emits `[loadingTiers, tiersLoaded([tier1, tier2])]`
- `loadTiers` failure → emits `[loadingTiers, error(ServerFailure)]`
- `selectTier` in state `tiersLoaded` → emits `tiersLoaded(selectedTierId: 2)`
- `selectTier` outside state `tiersLoaded` → state does not change
- `submit` success (isSuperuser=true) → emits `[submitting, success]`
- `submit` permissionDenied (isSuperuser=false) → emits `[submitting, error(PermissionDenied)]`
- `submit` with `selectedTierId == null` → state does not change, `_updateTier` not called
- `reset` returns to `initial`

Mock: `FetchTiersUseCase`, `UpdateUserTierUseCase`, `AuthCubit`.

#### `fetch_tiers_adapter_test.dart`

- success: API returned a list → `Right([TierOption(id:1, name:'Free'), ...])`
- 401 → `Left(UnauthorizedFailure)`
- 500 → `Left(ServerFailure)`
- `TypeError` during parsing → `Left(UnknownFailure)`, `logger.error` called with `stackTrace`

#### `update_user_tier_adapter_test.dart`

- success: API returned 200 → `Right(unit)`
- 401 → `Left(UnauthorizedFailure)`
- 403 → `Left(ForbiddenFailure)`
- 404 → `Left(NotFoundFailure)`
- 500 → `Left(ServerFailure)`
- unexpected exception → `Left(UnknownFailure)`, `logger.error` called with `stackTrace`

---

## ====== REPORT ======

On completion provide:

1. List of created files (new) and modified files (with description of what was added)
2. Confirmation that other slices (`list_users`, `create_user`, `edit_user`, `delete_user`, `get_user_tier`) **were not modified**
3. List of `core/` changes:
   - `permission.dart` — `editUserTier` added
   - `i18n/` — keys added, `dart run slang` executed
4. UX walkthrough: button visible only to superuser → sheet opens → tier selection → confirm → snackbar → tier updated in UI
5. Tests: count of new tests, all green

---

## ====== WHAT NOT TO DO ======

- Do NOT create `update_user_tier_route.dart` — slice has no dedicated screen or route
- Do NOT import anything from `lib/features/tiers/` — this is a cross-feature import
- Do NOT reuse `UserTierDto` from `get_user_tier/data/dto/` — this is a different bounded context
- Do NOT add the button on any screen other than `user_details_screen`
- Do NOT check permissions only in the UI — the use-case must check `isSuperuser` itself
- Do NOT use `PermissionCubit` directly in the use-case — pass `isSuperuser: bool` as a parameter
- Do NOT change `role_policy.dart` and `permission_cubit.dart` — `editUserTier` will enter admin automatically
- Do NOT add the button in `user_details_screen` without checking `permissions.contains(Permission.editUserTier)`
- Do NOT create a separate BlocProvider for UpdateUserTierCubit inside the bottom sheet — the cubit is provided at the route level and passed through `BlocProvider.value`
- Do NOT make a fat port with multiple methods — two narrow ports: `FetchTiersPort` and `UpdateUserTierPort`
- Do NOT add anything to `_shared/` for this slice "for future use" — it already uses `users_api_client.dart` from `_shared/`
