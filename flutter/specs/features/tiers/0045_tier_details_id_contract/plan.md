# Plan 0045 — tier_details: switch get-tier contract from name to id

## Overview

This is a **modification of an existing slice** (`tier_details`). The backend
changed `GET /tier/{name}` to `GET /tier/{id}` (integer path param). Nine files
need updating across all four layers plus routing. No new files are created
except for two missing test files.

---

## Files to Modify

### 1. `_shared` — API client (retrofit)

**File:** `lib/features/tiers/_shared/data/tiers_api_client.dart`

> ⚠️ This is a shared file. Confirm before touching it during implementation.
> Only the `getTier` method signature changes; `patchTier` and `deleteTier`
> (still name-based) are **not** touched.

Change:
```dart
// BEFORE
@GET('/tier/{name}')
Future<TierDetailDto> getTier(@Path('name') String name);

// AFTER
@GET('/tier/{id}')
Future<TierDetailDto> getTier(@Path('id') int id);
```

Regenerate: `dart run build_runner build --delete-conflicting-outputs`
(updates `tiers_api_client.g.dart`).

---

### 2. Domain — port

**File:** `lib/features/tiers/tier_details/domain/ports/get_tier_port.dart`

Change call signature from `String name` to `int id`:
```dart
abstract class GetTierPort {
  Future<Either<Failure, TierDetail>> call(int id);
}
```

---

### 3. Domain — use-case

**File:** `lib/features/tiers/tier_details/domain/usecases/get_tier_usecase.dart`

Change call signature from `String name` to `int id`; pass through to port:
```dart
Future<Either<Failure, TierDetail>> call(int id) {
  if (!_permissions.has(Permission.manageTiers)) {
    return Future.value(const Left(Failure.permissionDenied()));
  }
  return _port(id);
}
```

---

### 4. Data — adapter

**File:** `lib/features/tiers/tier_details/data/get_tier_adapter.dart`

Change call signature from `String name` to `int id`; pass to `_api.getTier`:
```dart
@override
Future<Either<Failure, TierDetail>> call(int id) async {
  try {
    try {
      final dto = await _api.getTier(id);
      return Right(dto.toDomain());
    } on DioException catch (e) {
      return Left(_mapHttp(e));
    }
  } on Object catch (e, st) {
    _logger.error('GetTierAdapter.call failed', error: e, stackTrace: st);
    return const Left(Failure.unknown());
  }
}
```

Error mapping (`_mapHttp`) is unchanged.

---

### 5. Application — cubit

**File:** `lib/features/tiers/tier_details/application/tier_details_cubit.dart`

Change `load` and `retry` from `String name` to `int id`:
```dart
Future<void> load(int id) async {
  emit(const TierDetailsState.loading());
  final result = await _usecase(id);
  result.fold(
    (f) => emit(TierDetailsState.error(failure: f)),
    (tier) => emit(TierDetailsState.loaded(tier: tier)),
  );
}

Future<void> retry(int id) => load(id);
```

---

### 6. Presentation — route page

**File:** `lib/features/tiers/tier_details/presentation/tier_details_route.dart`

Replace `@PathParam('name') String tierName` with two params: a path int and a
query string. Pass both down to `TierDetailsScreen`:

```dart
@RoutePage()
class TierDetailsPage extends StatelessWidget {
  const TierDetailsPage({
    @PathParam('id') required this.tierId,
    @QueryParam('name') required this.tierName,
    super.key,
  });

  final int tierId;
  final String tierName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TierDetailsCubit>(),
      child: TierDetailsScreen(tierId: tierId, tierName: tierName),
    );
  }
}
```

Regenerate auto_route: `dart run build_runner build --delete-conflicting-outputs`
(updates `app_router.gr.dart`).

---

### 7. Presentation — screen

**File:** `lib/features/tiers/tier_details/presentation/tier_details_screen.dart`

**Constructor:** add `int tierId`; keep `String tierName` for initial AppBar
display.

**`initState`:** call `load(widget.tierId)` instead of `load(widget.tierName)`.

**AppBar title:** replace the static `Text(widget.tierName)` with a
`BlocBuilder<TierDetailsCubit, TierDetailsState>` that shows:
- `widget.tierName` — when `TierDetailsInitial | TierDetailsLoading | TierDetailsError`
- `tier.name` — when `TierDetailsLoaded`

**Retry button:** call `retry(widget.tierId)`.

**Edit button** (currently uses `widget.tierName`):
- Passes `widget.tierName` to `EditTierRoute(tierName: ...)` (edit_tier still
  uses name — unchanged per PRD scope).
- After a successful rename, replace the current route with
  `TierDetailsRoute(tierId: widget.tierId, tierName: newName)` so the AppBar
  reflects the new name and the URL stays id-based.

**Delete button:** `DeleteTierButton(tierName: widget.tierName)` — unchanged
(delete_tier still uses name; covered by PRD 0047).

---

### 8. Routing — `app_router.dart`

**File:** `lib/core/routing/app_router.dart`

Change the tiers tab child route from `path: ':name'` to `path: ':id'`:
```dart
// BEFORE
AutoRoute(
  page: TierDetailsRoute.page,
  path: ':name',
  guards: [...],
),

// AFTER
AutoRoute(
  page: TierDetailsRoute.page,
  path: ':id',
  guards: [...],
),
```

---

### 9. Navigation call-site — list tiers screen

**File:** `lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart`

Update the `onTap` that pushes `TierDetailsRoute`:
```dart
// BEFORE
TierDetailsRoute(tierName: tiers[index].name)

// AFTER
TierDetailsRoute(tierId: tiers[index].id, tierName: tiers[index].name)
```

`Tier` entity already carries `id: int`, so no entity changes are needed.

---

## Tests to Update

### Existing: adapter test

**File:** `test/features/tiers/tier_details/data/get_tier_adapter_test.dart`

All `adapter('Free')` calls → `adapter(1)`.  
Helper `_dioError` path string is cosmetic; keep or update to `/tier/1`.  
`apiClient.getTier(any())` matcher stays valid (value-agnostic).

### Existing: cubit test

**File:** `test/features/tiers/tier_details/application/tier_details_cubit_test.dart`

All `cubit.load('Free')` → `cubit.load(1)`.  
All `cubit.retry('Free')` → `cubit.retry(1)`.  
Update test description strings accordingly.

---

## Tests to Add

### New: use-case test

**File:** `test/features/tiers/tier_details/domain/usecases/get_tier_usecase_test.dart`

Scenarios:
- `manageTiers` absent → returns `Left(PermissionDenied)` without calling port.
- `manageTiers` present, port returns `Right(tier)` → use-case returns same Right.
- `manageTiers` present, port returns `Left(failure)` → use-case returns same Left.

### New: widget test

**File:** `test/features/tiers/tier_details/presentation/tier_details_screen_test.dart`

Scenarios (mock `TierDetailsCubit`):
- State `TierDetailsLoading` → AppBar shows `tierName` ("Free"), spinner visible.
- State `TierDetailsLoaded(tier)` where `tier.name = 'Premium'` → AppBar shows
  `'Premium'`, card content visible.
- State `TierDetailsError(NotFoundFailure)` → not-found text visible, no retry
  button.
- State `TierDetailsError(UnknownFailure)` → generic error text visible, retry
  button present.

---

## Codegen Summary

Run once after all code changes:
```
dart run build_runner build --delete-conflicting-outputs
```

This regenerates:
- `lib/features/tiers/_shared/data/tiers_api_client.g.dart` (retrofit)
- `lib/core/routing/app_router.gr.dart` (auto_route)

---

## Verification

```
dart format .
dart analyze
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/tiers/tier_details/
```
