# Plan: list_tiers — full implementation (skeleton extension)

## Task

Extend the existing skeleton slice `list_tiers` into a full implementation:
add domain/data/application layers, replace the placeholder screen
with a real paginated tier list with pull-to-refresh and load-more.

UX: the `/tiers` screen — a list of tiers with pull-down refresh, loading the next
page when scrolling to the bottom, and an error state with a Retry button.

---

## CONTEXT

**READ:**
- `@CLAUDE.md` in full
- `@lib/features/users/list_users/**` — reference slice for a paginated list
  (do NOT copy blindly, use as a pattern reference)
- `@lib/features/users/users_feature_module.dart` — API client registration pattern
- `@lib/features/tiers/list_tiers/presentation/list_tiers_route.dart` — to be modified
- `@lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart` — to be modified
- `@lib/core/errors/failure.dart`
- `@lib/core/logging/domain/app_logger.dart`
- `@lib/core/rbac/permission.dart` — need `Permission.manageTiers`
- `@lib/core/rbac/permission_cubit.dart`
- `@lib/core/i18n/i18n/en.json` — add keys
- `@lib/core/i18n/i18n/ru.json` — add keys
- `@.claude/skills/bloc/SKILL.md`

**DO NOT READ:**
- `@lib/features/users/create_user/**`
- `@lib/features/users/edit_user/**`
- `@lib/features/users/delete_user/**`
- `@lib/features/users/user_details/**`
- `@lib/features/auth/**`
- `@**/*.gr.dart`, `@**/*.config.dart`, `@**/*.freezed.dart`, `@**/*.g.dart`

---

## API

```
GET http://127.0.0.1:8000/api/v1/tiers?page=1&items_per_page=10
Header: Authorization: Bearer <token>
```

Response 200 — `PaginatedListResponse[TierRead]`, structure identical to `PaginatedUsersDto`:

```json
{
  "data": [
    { "id": 1, "name": "Basic" }
  ],
  "total_count": 42,
  "has_more": true,
  "page": 1,
  "items_per_page": 10
}
```

**IMPORTANT: the fields of TierRead need to be confirmed with the backend developer.**
Minimum guaranteed fields are `id: int` and `name: str`. All other fields should be made
nullable / `@Default(...)` per rule §8.2 of CLAUDE.md.

Errors:
- `401` — Unauthorized (handled globally in ErrorInterceptor)
- `403` — Forbidden (user lacks `manageTiers`)
- `5xx` — ServerFailure

---

## Target structure

```
lib/features/tiers/
├── tiers_feature_module.dart            # NEW: TiersApiClient DI registration
└── list_tiers/
    ├── domain/
    │   ├── entities/
    │   │   ├── tier.dart                # NEW: Tier(id, name, ...)
    │   │   └── paginated_tiers.dart     # NEW: PaginatedTiers value object
    │   ├── ports/
    │   │   └── list_tiers_port.dart     # NEW: Future<Either<Failure, PaginatedTiers>> call(...)
    │   └── usecases/
    │       └── list_tiers_usecase.dart  # NEW: manageTiers check + delegate to port
    ├── data/
    │   ├── dto/
    │   │   ├── tier_dto.dart            # NEW: freezed sealed + json_serializable
    │   │   └── paginated_tiers_dto.dart # NEW: freezed sealed
    │   ├── tiers_api_client.dart        # NEW: Retrofit @RestApi (getTiers)
    │   └── list_tiers_adapter.dart      # NEW: @LazySingleton(as: ListTiersPort)
    ├── application/
    │   ├── list_tiers_cubit.dart        # NEW: @injectable
    │   └── list_tiers_state.dart        # NEW: freezed sealed
    └── presentation/
        ├── list_tiers_route.dart        # MODIFY: add BlocProvider
        ├── list_tiers_screen.dart       # MODIFY: replace placeholder with real ListView
        └── widgets/
            └── tier_tile.dart           # NEW: ListTile for a single tier

Note on _shared/: do NOT create `tiers/_shared/` — there is only one slice,
the API client lives in `list_tiers/data/`. Move to `_shared/` only
when a second slice appears.
```

---

## What to do

### 1) DI MODULE — register the API client

File: `lib/features/tiers/tiers_feature_module.dart` (NEW)

```dart
import 'package:dio/dio.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/data/tiers_api_client.dart';
import 'package:injectable/injectable.dart';

@module
abstract class TiersFeatureModule {
  @lazySingleton
  TiersApiClient tiersApiClient(Dio dio) => TiersApiClient(dio);
}
```

### 2) DATA — API client

File: `lib/features/tiers/list_tiers/data/tiers_api_client.dart` (NEW)

```dart
@RestApi()
abstract class TiersApiClient {
  factory TiersApiClient(Dio dio) = _TiersApiClient;

  @GET('/tiers')
  Future<PaginatedTiersDto> getTiers({
    @Query('page') required int page,
    @Query('items_per_page') required int perPage,
  });
}
```

### 3) DATA — DTO

**`tier_dto.dart`** — soft contract (§8.2 CLAUDE.md):

```dart
@freezed
sealed class TierDto with _$TierDto {
  const factory TierDto({
    required int id,        // DTO is meaningless without id
    @Default('') String name,
    // ADD remaining TierRead fields here after confirming with backend
  }) = _TierDto;

  factory TierDto.fromJson(Map<String, dynamic> json) => _$TierDtoFromJson(json);
}
```

**`paginated_tiers_dto.dart`** — identical to `PaginatedUsersDto`, but with `TierDto`:

```dart
@freezed
sealed class PaginatedTiersDto with _$PaginatedTiersDto {
  const factory PaginatedTiersDto({
    required List<TierDto> data,
    @JsonKey(name: 'total_count') required int totalCount,
    @JsonKey(name: 'has_more') required bool hasMore,
    required int page,
    @JsonKey(name: 'items_per_page') required int itemsPerPage,
  }) = _PaginatedTiersDto;

  factory PaginatedTiersDto.fromJson(Map<String, dynamic> json) =>
      _$PaginatedTiersDtoFromJson(json);
}
```

Add a `toDomain()` method on `TierDto` returning a `Tier`.

### 4) DOMAIN — entity and value object

**`tier.dart`** — plain class (not freezed, no need for equals/hashCode):

```dart
class Tier {
  const Tier({required this.id, required this.name});
  final int id;
  final String name;
  // add remaining fields after confirmation
}
```

**`paginated_tiers.dart`** — analogous to `PaginatedUsers`:

```dart
class PaginatedTiers {
  const PaginatedTiers({
    required this.tiers,
    required this.totalCount,
    required this.hasMore,
    required this.page,
    required this.itemsPerPage,
  });

  final List<Tier> tiers;
  final int totalCount;
  final bool hasMore;
  final int page;
  final int itemsPerPage;
}
```

### 5) DOMAIN — port and usecase

**`list_tiers_port.dart`:**

```dart
abstract class ListTiersPort {
  Future<Either<Failure, PaginatedTiers>> call({
    required int page,
    required int perPage,
  });
}
```

**`list_tiers_usecase.dart`** — checks `manageTiers` (§7 CLAUDE.md):

```dart
@lazySingleton
class ListTiersUseCase {
  const ListTiersUseCase(this._port);
  final ListTiersPort _port;

  Future<Either<Failure, PaginatedTiers>> call({
    required Set<Permission> permissions,
    int page = 1,
    int perPage = 10,
  }) async {
    if (!permissions.contains(Permission.manageTiers)) {
      return const Left(Failure.permissionDenied());
    }
    return _port(page: page, perPage: perPage);
  }
}
```

`Permission` — pure Dart enum, can be imported from `core/rbac/permission.dart`
without violating the "domain does not import flutter" rule.

### 6) DATA — adapter

File: `lib/features/tiers/list_tiers/data/list_tiers_adapter.dart`

Double-catch pattern (§8.4 CLAUDE.md). Analogous to `ListUsersAdapter`:

```dart
@LazySingleton(as: ListTiersPort)
class ListTiersAdapter implements ListTiersPort {
  ListTiersAdapter(this._api, this._logger);

  final TiersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, PaginatedTiers>> call({
    required int page,
    required int perPage,
  }) async {
    try {
      try {
        final dto = await _api.getTiers(page: page, perPage: perPage);
        return Right(PaginatedTiers(
          tiers: dto.data.map((t) => t.toDomain()).toList(),
          totalCount: dto.totalCount,
          hasMore: dto.hasMore,
          page: dto.page,
          itemsPerPage: dto.itemsPerPage,
        ));
      } on DioException catch (e) {
        final failure = e.error;
        if (failure is Failure) return Left(failure);
        return Left(Failure.network(message: e.message));
      }
    } on Object catch (e, st) {
      _logger.error(
        'ListTiersAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }
}
```

### 7) APPLICATION — state

File: `lib/features/tiers/list_tiers/application/list_tiers_state.dart`

Analogous to `UsersListState`:

```dart
enum LoadMoreStatus { idle, loading, error }

@freezed
sealed class ListTiersState with _$ListTiersState {
  const factory ListTiersState.initial() = ListTiersInitial;
  const factory ListTiersState.loading() = ListTiersLoading;
  const factory ListTiersState.loaded({
    required List<Tier> tiers,
    required int page,
    required bool hasMore,
    @Default(LoadMoreStatus.idle) LoadMoreStatus loadMoreStatus,
    Failure? loadMoreError,
  }) = ListTiersLoaded;
  const factory ListTiersState.error(Failure failure) = ListTiersError;
}
```

### 8) APPLICATION — cubit

File: `lib/features/tiers/list_tiers/application/list_tiers_cubit.dart`

```dart
const int _pageSize = 10;

@injectable
class ListTiersCubit extends Cubit<ListTiersState> {
  ListTiersCubit(this._useCase, this._permissionCubit)
      : super(const ListTiersState.initial());

  final ListTiersUseCase _useCase;
  final PermissionCubit _permissionCubit;

  Future<void> load() async {
    emit(const ListTiersState.loading());
    final result = await _useCase(
      permissions: _permissionCubit.state,
      perPage: _pageSize,
    );
    result.fold(
      (failure) => emit(ListTiersState.error(failure)),
      (paginated) => emit(ListTiersState.loaded(
        tiers: paginated.tiers,
        page: paginated.page,
        hasMore: paginated.hasMore,
      )),
    );
  }

  Future<void> refresh() async {
    final result = await _useCase(
      permissions: _permissionCubit.state,
      perPage: _pageSize,
    );
    result.fold(
      (failure) => emit(ListTiersState.error(failure)),
      (paginated) => emit(ListTiersState.loaded(
        tiers: paginated.tiers,
        page: paginated.page,
        hasMore: paginated.hasMore,
      )),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ListTiersLoaded) return;
    if (!current.hasMore) return;
    if (current.loadMoreStatus == LoadMoreStatus.loading) return;

    emit(current.copyWith(
      loadMoreStatus: LoadMoreStatus.loading,
      loadMoreError: null,
    ));

    final result = await _useCase(
      permissions: _permissionCubit.state,
      page: current.page + 1,
      perPage: _pageSize,
    );
    result.fold(
      (failure) => emit(current.copyWith(
        loadMoreStatus: LoadMoreStatus.error,
        loadMoreError: failure,
      )),
      (paginated) => emit(ListTiersState.loaded(
        tiers: [...current.tiers, ...paginated.tiers],
        page: paginated.page,
        hasMore: paginated.hasMore,
      )),
    );
  }

  Future<void> retryLoadMore() => loadMore();
}
```

### 9) PRESENTATION — route (modify)

File: `lib/features/tiers/list_tiers/presentation/list_tiers_route.dart`

```dart
@RoutePage()
class ListTiersPage extends StatelessWidget {
  const ListTiersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<ListTiersCubit>();
        unawaited(cubit.load());
        return cubit;
      },
      child: const ListTiersScreen(),
    );
  }
}
```

### 10) PRESENTATION — TierTile widget

File: `lib/features/tiers/list_tiers/presentation/widgets/tier_tile.dart`

Simple `ListTile`: shows `tier.id` and `tier.name`. If Tier has other
fields — display them in the subtitle. No onTap yet (no tier_details slice).

### 11) PRESENTATION — screen (modify)

File: `lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart`

Analogous to `UsersScreen`:
- `StatefulWidget` with `ScrollController` for load-more
- `RefreshIndicator` for pull-to-refresh
- `BlocBuilder<ListTiersCubit, ListTiersState>` with exhaustive switch
- States: initial → shrink, loading → spinner, loaded → ListView, error → text + Retry
- When loading the next page in `loaded` — show indicator / error after the last element

### 12) LOCALIZATION

Files: `lib/core/i18n/i18n/en.json` and `ru.json`

Add to the `"tiers"` section:

```json
// en.json
"tiers": {
  "listTiers": {
    "title": "Tiers",
    "loadError": "Failed to load tiers",
    "loadMoreError": "Failed to load more tiers",
    "empty": "No tiers found"
  }
}

// ru.json
"tiers": {
  "listTiers": {
    "title": "Тиры",
    "loadError": "Не удалось загрузить тиры",
    "loadMoreError": "Не удалось загрузить следующую страницу",
    "empty": "Тиры не найдены"
  }
}
```

Remove the `placeholder` key — it is no longer needed.

After changes: `dart run slang`

### 13) CODEGEN

After all changes:
```
dart run build_runner build --delete-conflicting-outputs
dart run slang
dart analyze
```

---

## Tests

### a) `test/features/tiers/list_tiers/application/list_tiers_cubit_test.dart`

Structure `group('ListTiersCubit', ...)`.

Scenarios:

| Test | Input conditions | Expected states |
|---|---|---|
| load — success | usecase → Right(paginated) | loading → loaded(tiers, page=1, hasMore) |
| load — permissionDenied | permissions = {} | loading → error(PermissionDenied) |
| load — failure | usecase → Left(NetworkFailure) | loading → error(NetworkFailure) |
| refresh — success | loaded state, usecase → Right | loaded(new data) |
| loadMore — success | loaded(hasMore=true), usecase → Right(page2) | loaded with merged list |
| loadMore — failure | loaded(hasMore=true), usecase → Left | loaded.copyWith(loadMoreStatus=error) |
| loadMore — skips if no more | loaded(hasMore=false) | emits nothing |
| loadMore — skips if loading | loaded(loadMoreStatus=loading) | emits nothing |

Mock `ListTiersUseCase` and `PermissionCubit` via `mocktail`.

### b) `test/features/tiers/list_tiers/data/list_tiers_adapter_test.dart`

| Test | Condition | Result |
|---|---|---|
| success | api → PaginatedTiersDto | Right(PaginatedTiers) |
| DioException with Failure in error | e.error is NetworkFailure | Left(NetworkFailure) |
| DioException without Failure | generic DioException | Left(Failure.network(...)) |
| unexpected exception | api throws TypeError | Left(Failure.unknown()), logger.error called |

---

## Report (upon completion)

- List of new files (12 files)
- List of modified files (4 files: route, screen, en.json, ru.json)
- Confirmation: `core/` was not modified (except i18n JSON)
- `dart analyze` — zero errors
- `flutter test test/features/tiers/` — all green
- UX walkthrough: open `/tiers`, verify the list loads, pull-to-refresh,
  scroll to bottom → load-more, disconnect network → retry

---

## What NOT to do

- Do NOT create `tiers/_shared/` — there is only one slice, the API client lives in `list_tiers/data/`
- Do NOT add onTap to TierTile — no tier_details slice yet
- Do NOT add a FAB to create a tier — no create_tier slice yet
- Do NOT modify `core/routing/app_router.dart` — the route is already registered
- Do NOT modify `core/rbac/permission.dart` — `manageTiers` is already there
- Do NOT modify `lib/main.dart` — AppRouter wiring is already done
- Do NOT make `LoadMoreStatus` global — define it locally in `list_tiers_state.dart`
  (analogous to `UsersListState`)
- Do NOT skip the catch-all in `ListTiersAdapter` (§8.4 CLAUDE.md)
- Do NOT hardcode UI strings (everything via slang)
