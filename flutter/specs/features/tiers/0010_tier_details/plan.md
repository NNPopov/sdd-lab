# Plan: 0010 tier_details

## Task

Create a new slice `tier_details` in the `tiers` feature.
Display detailed information about a single tier (name, id, created_at) on a separate
screen. The screen is opened by tapping an item in `list_tiers`. This slice is a
prerequisite for implementing `update_tier`.

---

## CONTEXT

READ:
- `@CLAUDE.md` in full
- `@lib/features/tiers/_shared/data/tiers_api_client.dart` — will be modified (adding a method)
- `@lib/features/tiers/_shared/domain/entities/tier.dart` — to understand the existing entity
- `@lib/features/tiers/_shared/data/dto/tier_dto.dart` — as a DTO example
- `@lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart` — will be modified (wire navigation)
- `@lib/features/tiers/list_tiers/presentation/widgets/tier_tile.dart` — will be modified (add onTap)
- `@lib/features/tiers/create_tier/**` — closest analog (do NOT copy, use as reference)
- `@lib/core/errors/failure.dart`
- `@lib/core/routing/app_router.dart` — will be modified (register route)
- `@lib/core/rbac/permission.dart`
- `@lib/core/rbac/permission_cubit.dart`
- `@lib/core/i18n/i18n/en.json` — will be modified
- `@lib/core/i18n/i18n/ru.json` — will be modified
- `@.claude/skills/bloc/SKILL.md`

DO NOT READ:
- `@lib/features/users/**`
- `@lib/features/auth/**`
- `@lib/features/tiers/list_tiers/application/**`
- `@lib/features/tiers/list_tiers/domain/**`
- `@lib/features/tiers/list_tiers/data/**`
- `@lib/core/di/injection.config.dart` (generated)
- `@lib/core/routing/app_router.gr.dart` (generated)

---

## API

```
GET http://127.0.0.1:8000/api/v1/tier/{name}
Header: Authorization: Bearer <token>

Response 200:
{
  "name": "Free",
  "id": 1,
  "created_at": "2026-04-25T15:55:28.836478Z"
}

Errors:
- 401 — token invalid      → UnauthorizedFailure
- 403 — no permissions     → ForbiddenFailure
- 404 — tier not found     → NotFoundFailure
          {"error": {"code": "notfound", "message": "Tier not found"}}
- 5xx — server error       → ServerFailure
```

Specifics:
- The path uses `name` (a string), NOT `id`.
- `created_at` is returned in ISO-8601 UTC; parse as `DateTime?` in the DTO
  (defensively nullable — the server could theoretically not return it).

---

## TARGET STRUCTURE

```
lib/features/tiers/tier_details/
├── domain/
│   ├── entities/
│   │   └── tier_detail.dart          # TierDetail(id, name, createdAt)
│   ├── ports/
│   │   └── get_tier_port.dart        # Future<Either<Failure, TierDetail>> call(String name)
│   └── usecases/
│       └── get_tier_usecase.dart     # checks Permission.manageTiers, calls port
├── data/
│   ├── dto/
│   │   └── tier_detail_dto.dart      # freezed+json; id required, name/created_at defensive
│   └── get_tier_adapter.dart         # @LazySingleton(as: GetTierPort), double catch
├── application/
│   ├── tier_details_cubit.dart
│   └── tier_details_state.dart       # sealed via freezed
└── presentation/
    ├── tier_details_screen.dart
    └── tier_details_route.dart       # @RoutePage()

Files modified outside the slice:
- lib/features/tiers/_shared/data/tiers_api_client.dart  — add getTier()
- lib/features/tiers/list_tiers/presentation/widgets/tier_tile.dart — add onTap
- lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart — wire navigation
- lib/core/routing/app_router.dart                       — register TierDetailsRoute
- lib/core/i18n/i18n/en.json                             — new keys
- lib/core/i18n/i18n/ru.json                             — new keys
```

---

## WHAT TO DO

### 1) _SHARED: add method to the API client

File: `lib/features/tiers/_shared/data/tiers_api_client.dart`

Add method and corresponding import:

```dart
@GET('/tier/{name}')
Future<TierDetailDto> getTier(@Path('name') String name);
```

DTO import: `package:flutter_application_1/features/tiers/tier_details/data/dto/tier_detail_dto.dart`

IMPORTANT: before making changes, verify that the `getTier` method does not already exist in the client.

After changes run codegen: `dart run build_runner build --delete-conflicting-outputs`

### 2) DOMAIN

**`tier_detail.dart`** — the slice's domain entity (not in `_shared/`, used only here):
```dart
class TierDetail {
  const TierDetail({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  final int id;
  final String name;
  final DateTime createdAt;
}
```
Not freezed — a simple immutable class is sufficient.

**`get_tier_port.dart`** — narrow port (one method):
```dart
abstract class GetTierPort {
  Future<Either<Failure, TierDetail>> call(String name);
}
```

**`get_tier_usecase.dart`** — orchestrates permission check and port call:
```dart
class GetTierUsecase {
  const GetTierUsecase(this._port, this._permissions);
  final GetTierPort _port;
  final PermissionCubit _permissions;

  Future<Either<Failure, TierDetail>> call(String name) async {
    if (!_permissions.has(Permission.manageTiers)) {
      return const Left(Failure.permissionDenied());
    }
    return _port(name);
  }
}
```

### 3) DATA

**`tier_detail_dto.dart`** — DTO with defensive values:
```dart
@freezed
sealed class TierDetailDto with _$TierDetailDto {
  const factory TierDetailDto({
    required int id,
    @Default('') String name,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _TierDetailDto;

  factory TierDetailDto.fromJson(Map<String, dynamic> json) =>
      _$TierDetailDtoFromJson(json);
}

extension TierDetailDtoX on TierDetailDto {
  TierDetail toDomain() => TierDetail(
        id: id,
        name: name,
        createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}
```

**`get_tier_adapter.dart`** — double catch is mandatory (CLAUDE.md §8.4):
```dart
@LazySingleton(as: GetTierPort)
class GetTierAdapter implements GetTierPort {
  const GetTierAdapter(this._api, this._logger);
  final TiersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, TierDetail>> call(String name) async {
    try {
      try {
        final dto = await _api.getTier(name);
        return Right(dto.toDomain());
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } catch (e, st) {
      _logger.error('GetTierAdapter.call failed', error: e, stackTrace: st);
      return Left(const Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) {
    return switch (e.response?.statusCode) {
      401 => Failure.unauthorized(message: e.message ?? ''),
      403 => Failure.forbidden(message: e.message ?? ''),
      404 => const Failure.notFound(),
      _ => Failure.server(statusCode: e.response?.statusCode),
    };
  }
}
```

### 4) APPLICATION

**`tier_details_state.dart`** — sealed via freezed:
```dart
@freezed
sealed class TierDetailsState with _$TierDetailsState {
  const factory TierDetailsState.initial() = TierDetailsInitial;
  const factory TierDetailsState.loading() = TierDetailsLoading;
  const factory TierDetailsState.loaded({required TierDetail tier}) = TierDetailsLoaded;
  const factory TierDetailsState.error({required Failure failure}) = TierDetailsError;
}
```

**`tier_details_cubit.dart`**:
```dart
@injectable
class TierDetailsCubit extends Cubit<TierDetailsState> {
  TierDetailsCubit(this._usecase) : super(const TierDetailsState.initial());
  final GetTierUsecase _usecase;

  Future<void> load(String name) async {
    emit(const TierDetailsState.loading());
    final result = await _usecase(name);
    result.fold(
      (f) => emit(TierDetailsState.error(failure: f)),
      (tier) => emit(TierDetailsState.loaded(tier: tier)),
    );
  }

  Future<void> retry(String name) => load(name);
}
```

### 5) PRESENTATION

**`tier_details_route.dart`**:
```dart
@RoutePage()
class TierDetailsPage extends StatelessWidget {
  const TierDetailsPage({@PathParam('name') required this.tierName, super.key});
  final String tierName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TierDetailsCubit>(),
      child: TierDetailsScreen(tierName: tierName),
    );
  }
}
```

**`tier_details_screen.dart`**:
- `StatefulWidget`, calls `context.read<TierDetailsCubit>().load(widget.tierName)` in `initState`
- AppBar with `title: Text(widget.tierName)`
- Body: `BlocBuilder<TierDetailsCubit, TierDetailsState>` with switch on state:
  - `initial/loading` → `CircularProgressIndicator`
  - `loaded` → card: name, ID, created_at (format via `DateFormat` or
    `toLocal().toString()` — without extra dependencies)
  - `error(NotFoundFailure)` → `t.tiers.tierDetails.notFound`
  - `error(PermissionDenied)` → `t.tiers.tierDetails.permissionDenied`
  - `error(_)` → `t.tiers.tierDetails.loadError` + Retry button

### 6) INTEGRATION

**`lib/features/tiers/list_tiers/presentation/widgets/tier_tile.dart`**

Add `onTap` parameter:
```dart
class TierTile extends StatelessWidget {
  const TierTile({required this.tier, this.onTap, super.key});
  final Tier tier;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('${tier.id}')),
      title: Text(tier.name),
      onTap: onTap,
    );
  }
}
```

**`lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart`**

In `itemBuilder` when `index < tiers.length` pass `onTap`:
```dart
TierTile(
  tier: tiers[index],
  onTap: () => context.router.push(
    TierDetailsRoute(name: tiers[index].name),
  ),
),
```

**`lib/core/routing/app_router.dart`**

Add import `tier_details_route.dart` and route:
```dart
AutoRoute(
  page: TierDetailsRoute.page,
  path: '/tier/:name',
  guards: [
    authGuard,
    PermissionGuard({Permission.manageTiers}, permissionCubit),
  ],
),
```

After changes run codegen: `dart run build_runner build --delete-conflicting-outputs`

### 7) LOCALIZATION

`lib/core/i18n/i18n/en.json` — add to the `tiers` section:
```json
"tierDetails": {
  "title": "Tier details",
  "id": "ID",
  "createdAt": "Created",
  "notFound": "Tier not found",
  "loadError": "Failed to load tier",
  "permissionDenied": "Access denied"
}
```

`lib/core/i18n/i18n/ru.json` — add to the `tiers` section:
```json
"tierDetails": {
  "title": "Детали уровня",
  "id": "ID",
  "createdAt": "Создан",
  "notFound": "Уровень не найден",
  "loadError": "Ошибка загрузки",
  "permissionDenied": "Нет доступа"
}
```

After changes run codegen: `dart run slang`

### 8) TESTS

`test/features/tiers/tier_details/`

**`application/tier_details_cubit_test.dart`:**
- `load(name)` → success → emits `[loading, loaded(tier)]`
- `load(name)` → `NotFoundFailure` → emits `[loading, error(NotFoundFailure)]`
- `load(name)` → `PermissionDenied` → emits `[loading, error(PermissionDenied)]`
- `load(name)` → `UnknownFailure` → emits `[loading, error(UnknownFailure)]`
- `retry(name)` → success → emits `[loading, loaded(tier)]`

**`data/get_tier_adapter_test.dart`:**
- api.getTier returns dto → `Right(TierDetail)`
- api.getTier throws `DioException(401)` → `Left(UnauthorizedFailure)`
- api.getTier throws `DioException(403)` → `Left(ForbiddenFailure)`
- api.getTier throws `DioException(404)` → `Left(NotFoundFailure)`
- api.getTier throws `DioException(500)` → `Left(ServerFailure)`
- api.getTier throws unexpected `Exception` → `Left(UnknownFailure)`,
  `logger.error` called with stackTrace

---

## REPORT

Upon completion provide:
- List of created files (new + modified)
- Confirmation that other `tiers` slices (except `list_tiers` presentation) were NOT touched
- Confirmation that other features (`users`, `auth`) were NOT touched
- List of changes in `core/` (routing, i18n)
- Test results: how many new tests, all green

---

## WHAT NOT TO DO

- Do NOT add `created_at` to the existing `TierDto` in `_shared/` — it has a different
  context (list response). A separate `TierDetailDto` is needed for the detail view.
- Do NOT add `createdAt` to the `Tier` entity in `_shared/` — `Tier` is used in the
  list context where `created_at` is not needed. `TierDetail` is a separate entity for this slice.
- Do NOT create a separate API client for a single method — add `getTier` to the
  existing `TiersApiClient` in `_shared/data/`.
- Do NOT navigate to `tier_details` from anywhere other than `list_tiers`.
- Do NOT implement tier editing on this screen — view only.
- Do NOT add the `manageTiers` guard to `TierTile` — the guard is on the route,
  and in `list_tiers` all users with `manageTiers` have already passed the guard.
- Do NOT modify the `list_tiers` cubit/domain/data — only presentation files.
- Do NOT touch `tiers_feature_module.dart` if injectable codegen handles it automatically.
