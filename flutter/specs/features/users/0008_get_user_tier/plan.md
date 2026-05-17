# Plan — 0008 get_user_tier

Task: create a new slice `get_user_tier` in the `users` feature.
Lazily load user tier information and display `tier_name`
instead of the current `tier_id`, as well as the `tier_created_at` date formatted as
`2026-04-25 15:55` on the `UserDetailsScreen`.

---

## CONTEXT

READ:
- @CLAUDE.md fully
- @lib/features/users/user_details/** — the slice being modified (analog and integration point)
- @lib/features/users/_shared/data/users_api_client.dart — add method here
- @lib/features/users/_shared/domain/entities/user.dart — check the `tierId` field
- @lib/features/users/user_details/data/get_user_adapter.dart — adapter example
- @lib/core/errors/failure.dart
- @lib/core/i18n/i18n/en.json — check existing keys (tier may already be there)
- @.claude/skills/bloc/SKILL.md

DO NOT READ:
- @lib/features/users/list_users/**
- @lib/features/users/create_user/**
- @lib/features/users/edit_user/**
- @lib/features/users/delete_user/**
- @lib/features/users/erase_db_user/**
- @lib/features/tiers/**
- @lib/core/routing/app_router.gr.dart

---

## API

```
GET /api/v1/user/{username}/tier
Header: Authorization: Bearer <token>

Response 200:
{
  "tier_name": "Free",
  "tier_id": 1,
  "tier_created_at": "2026-04-25T15:55:28.836478Z"
}
```

Errors:
- 401 — token invalid → `UnauthorizedFailure`
- 403 — no access → `ForbiddenFailure`
- 404 — user not found or tier not assigned → `NotFoundFailure`
- 5xx — server error → `ServerFailure`
- network error → `NetworkFailure`

Notes:
- If the user has no tier — the server returns 404.
  In the UI this is handled silently: the Tier row simply is not shown.
- The request requires authorization.

---

## Target structure

```
lib/features/users/get_user_tier/
├── domain/
│   ├── entities/
│   │   └── user_tier.dart              # { tierName: String, tierCreatedAt: DateTime? }
│   ├── ports/
│   │   └── get_user_tier_port.dart     # Future<Either<Failure, UserTier>> call(String username)
│   └── usecases/
│       └── get_user_tier_usecase.dart
├── data/
│   ├── dto/
│   │   └── user_tier_dto.dart          # freezed, soft contract (all fields nullable/default)
│   └── get_user_tier_adapter.dart      # double catch + AppLogger
├── application/
│   ├── get_user_tier_cubit.dart        # @injectable
│   └── get_user_tier_state.dart        # sealed: initial | loading | loaded(UserTier) | error(Failure)
└── presentation/
    └── (no widgets — rendering via parameter in UserDetailsView)
```

Note: `get_user_tier` has no dedicated screen, route, or widget component.
Data is passed to `UserDetailsView` via primitive parameters.

Modified existing files:
- `lib/features/users/_shared/data/users_api_client.dart` — +1 method
- `lib/features/users/user_details/presentation/user_details_route.dart` — `MultiBlocProvider`
- `lib/features/users/user_details/presentation/user_details_screen.dart` — `BlocListener` + `BlocBuilder`
- `lib/features/users/user_details/presentation/widgets/user_details_view.dart` — params `tierName`, `tierCreatedAt`, `tierLoading`
- `lib/core/i18n/i18n/en.json` + `ru.json` — new key `users.details.tierSince`

---

## WHAT TO DO

### 1) _SHARED — add endpoint to API client

File: `lib/features/users/_shared/data/users_api_client.dart`

Add method:
```dart
@GET('/user/{username}/tier')
Future<UserTierDto> getUserTier(@Path('username') String username);
```

IMPORTANT: `UserTierDto` is a new DTO from `get_user_tier/data/dto/` — it must be
imported in `users_api_client.dart`.

Pause and confirm with the user that modifying `_shared/data/` is acceptable
(this is a standard extension of the feature's shared API client).

### 2) DOMAIN

**a) `domain/entities/user_tier.dart`**

```dart
@freezed
sealed class UserTier with _$UserTier {
  const factory UserTier({
    required String tierName,
    DateTime? tierCreatedAt,
  }) = _UserTier;
}
```

`tierId` is not included in the domain entity — it is not needed for the UI.
`tierCreatedAt` is nullable — defensive contract: the mapper may receive `null`
from the DTO and pass it to the domain without data loss.

**b) `domain/ports/get_user_tier_port.dart`**

```dart
abstract class GetUserTierPort {
  Future<Either<Failure, UserTier>> call(String username);
}
```

**c) `domain/usecases/get_user_tier_usecase.dart`**

Delegates to the port. See the analog `GetUserUseCase` in `user_details/domain/usecases/`.

### 3) DATA

**a) `data/dto/user_tier_dto.dart`**

Soft contract (CLAUDE.md §8.2). `tierId` and `tierName` are `required` (without them the DTO
is semantically meaningless). Other fields are nullable or have `@Default`.

```dart
@freezed
sealed class UserTierDto with _$UserTierDto {
  const factory UserTierDto({
    @JsonKey(name: 'tier_id') required int tierId,
    @JsonKey(name: 'tier_name') required String tierName,
    @JsonKey(name: 'tier_created_at') DateTime? tierCreatedAt,
  }) = _UserTierDto;

  factory UserTierDto.fromJson(Map<String, dynamic> json) =>
      _$UserTierDtoFromJson(json);
}
```

**b) `data/get_user_tier_adapter.dart`**

`@LazySingleton(as: GetUserTierPort)`. Double catch per CLAUDE.md §8.4.

HTTP error mapping:
- 401 → `UnauthorizedFailure`
- 403 → `ForbiddenFailure`
- 404 → `NotFoundFailure` (tier not assigned — expected case)
- other → `NetworkFailure`
- catch-all → `UnknownFailure` + `_logger.error`

`toDomain()` on DTO — direct field mapping without transformations. `tierId` from the DTO
is not passed to `UserTier` — the domain entity does not contain it.

### 4) APPLICATION

**a) `application/get_user_tier_state.dart`**

```dart
@freezed
sealed class GetUserTierState with _$GetUserTierState {
  const factory GetUserTierState.initial() = GetUserTierInitial;
  const factory GetUserTierState.loading() = GetUserTierLoading;
  const factory GetUserTierState.loaded(UserTier tier) = GetUserTierLoaded;
  const factory GetUserTierState.error(Failure failure) = GetUserTierError;
}
```

**b) `application/get_user_tier_cubit.dart`**

`@injectable` (not singleton — one instance per screen).

Method `load(String username)`:
- emit loading
- await usecase(username)
- fold: error → emit error, success → emit loaded

### 5) INTEGRATION in user_details

**a) `user_details_route.dart`** → `MultiBlocProvider`

```dart
return MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => getIt<UserDetailsCubit>()),
    BlocProvider(create: (_) => getIt<GetUserTierCubit>()),
  ],
  child: UserDetailsScreen(username: username),
);
```

**b) `user_details_screen.dart`** → add `BlocListener`

Wrap the body in `BlocListener<UserDetailsCubit>`. When state becomes
`UserDetailsLoaded` — call `context.read<GetUserTierCubit>().load(username)`:

```dart
BlocListener<UserDetailsCubit, UserDetailsState>(
  listener: (context, state) {
    if (state is UserDetailsLoaded) {
      context.read<GetUserTierCubit>().load(widget.username);
    }
  },
  child: BlocBuilder<UserDetailsCubit, UserDetailsState>(
    builder: (context, state) => switch (state) {
      UserDetailsInitial() => const SizedBox.shrink(),
      UserDetailsLoading() => const Center(child: CircularProgressIndicator()),
      UserDetailsLoaded(:final user) =>
        BlocBuilder<GetUserTierCubit, GetUserTierState>(
          builder: (context, tierState) => UserDetailsView(
            user: user,
            tierName: tierState is GetUserTierLoaded
                ? tierState.tier.tierName
                : null,
            tierCreatedAt: tierState is GetUserTierLoaded
                ? tierState.tier.tierCreatedAt
                : null,
            tierLoading: tierState is GetUserTierLoading,
          ),
        ),
      UserDetailsError(:final failure) => ... (unchanged),
    },
  ),
)
```

IMPORTANT: `user_details_screen.dart` imports `GetUserTierCubit` and
`GetUserTierState` from `get_user_tier/application/`. This is a legitimate
integration point — analogous to how this file already imports
`DeleteAccountButton` from `delete_user/presentation/`.

**c) `user_details_view.dart`** → params `tierName`, `tierCreatedAt`, `tierLoading`

- Remove the old block `if (user.tierId != null) _InfoRow(tier, tierId.toString())`
- Add new rows:

```dart
if (tierLoading)
  _InfoRow(label: t.users.details.tier, value: t.common.loading)
else if (tierName != null) ...[
  _InfoRow(label: t.users.details.tier, value: tierName),
  if (tierCreatedAt != null)
    _InfoRow(
      label: t.users.details.tierSince,
      value: _formatDate(tierCreatedAt),
    ),
],
```

Helper date formatting method (in the widget or as an extension):
```dart
String _formatDate(DateTime dt) =>
    DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
```

`DateFormat` requires `import 'package:intl/intl.dart'`.
`intl` is almost certainly already in `pubspec.yaml` as a transitive dependency
of `slang`/`flutter_localizations` — check before adding an explicit dependency.

Widget parameters:
```dart
final String? tierName;         // null → do not show tier block
final DateTime? tierCreatedAt;  // null → do not show date row
final bool tierLoading;         // true → show "Loading..."
```

`UserDetailsView` does not import anything from `get_user_tier` — it knows only
about primitive parameters.

### 6) LOCALIZATION

The key `users.details.tier` already exists — used for the tier name row.
The key `common.loading` already exists — used for the loading state.

Add a new key for the date row:

`lib/core/i18n/i18n/en.json` — in the `users.details` section:
```json
"tierSince": "Tier since"
```

`lib/core/i18n/i18n/ru.json` — in the `users.details` section:
```json
"tierSince": "Тариф с"
```

After adding the keys, run `dart run slang` to regenerate.

---

## TESTS

```
test/features/users/get_user_tier/
├── data/
│   └── get_user_tier_adapter_test.dart
└── application/
    └── get_user_tier_cubit_test.dart
```

**a) `get_user_tier_adapter_test.dart`**

- success with date: api returned `UserTierDto` with `tierCreatedAt` → `Right(UserTier(tierName: ..., tierCreatedAt: ...))`
- success without date: `tier_created_at: null` in DTO → `Right(UserTier(tierName: ..., tierCreatedAt: null))`
- 401 → `Left(UnauthorizedFailure)`
- 403 → `Left(ForbiddenFailure)`
- 404 → `Left(NotFoundFailure)` (tier not assigned)
- 5xx → `Left(NetworkFailure)` or `Left(ServerFailure)` depending on the code
- unexpected exception (FormatException) → `Left(UnknownFailure)`,
  `_logger.error` called with stackTrace

**b) `get_user_tier_cubit_test.dart`**

- success: `load(username)` → emits `[GetUserTierLoading, GetUserTierLoaded(tier)]`,
  `tier.tierName` and `tier.tierCreatedAt` match data from usecase
- failure (any Failure) → emits `[GetUserTierLoading, GetUserTierError(failure)]`
- calling `load` twice: the second call correctly overwrites the result of the first

---

## REPORT

On completion provide:
- List of all new files
- List of modified files with a brief description of changes
- Confirmation that `list_users`, `create_user`, `edit_user`, `delete_user`,
  `erase_db_user` slices were not touched
- Tests: count of new tests, all green

---

## WHAT NOT TO DO

- Do NOT create a separate screen or route for `get_user_tier` — this is an embedded slice
- Do NOT add `UserTierDto` to `_shared/data/dto/` — it belongs to `get_user_tier/data/dto/`
- Do NOT extract a `UserTierSection` widget into a separate file — `tierName: String?` is sufficient
- Do NOT show an error state on tier load failure — silent failure (the row simply
  is not displayed)
- Do NOT block rendering of the main user data while waiting for the tier
- Do NOT make `GetUserTierCubit` a singleton — it is created for each details screen
- Do NOT add `tierId` to the `UserTier` domain entity — it is not used in the UI;
  keep it only in the DTO
- Do NOT format the date as a hardcoded string in the adapter or use-case — formatting
  is exclusively in the presentation layer (`UserDetailsView._formatDate`)
- Do NOT store the formatted string in `UserTier` — the domain stores `DateTime`,
  the view formats it
