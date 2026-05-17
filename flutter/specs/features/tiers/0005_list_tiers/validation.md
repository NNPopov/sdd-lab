# Validation: list_tiers — full implementation

## Static checks

- [ ] `dart analyze` — zero errors in new and modified files
- [ ] `dart run build_runner build --delete-conflicting-outputs` — completed without errors
- [ ] `dart run slang` — completed, generated files updated

## Architectural invariants

- [ ] `tiers/_shared/` is NOT created — no second slice exists
- [ ] `TiersApiClient` is registered only through `TiersFeatureModule` (not via @injectable on the class)
- [ ] `ListTiersAdapter` has double-catch: `on DioException` + `on Object catch (e, st)`
- [ ] `ListTiersCubit` is annotated with `@injectable` (NOT `@lazySingleton`)
- [ ] `list_tiers_usecase.dart` checks `Permission.manageTiers` and returns `Left(Failure.permissionDenied())` when the permission is absent
- [ ] `features/tiers/` does not import `features/users/` or other features
- [ ] `tier_dto.dart` — all fields except `id` are nullable or @Default

## Tests

- [ ] `list_tiers_cubit_test.dart` contains >= 8 test cases (see plan.md)
- [ ] `list_tiers_adapter_test.dart` contains >= 4 test cases
- [ ] `flutter test test/features/tiers/` — all green

## UX scenarios (manual verification)

### Scenario 1: basic load

1. Log in as a superuser
2. Navigate to `/tiers`
3. Expected: `CircularProgressIndicator` → list of tiers (id + name in each ListTile)
4. AppBar title: "Tiers" / "Тиры"

### Scenario 2: pull-to-refresh

1. Pull down on the list screen
2. Expected: `RefreshIndicator` animation → list refreshed

### Scenario 3: load-more

1. More than 10 tiers in the database, scroll to the bottom of the first page
2. Expected: `CircularProgressIndicator` below the last element → new tiers appended at the bottom

### Scenario 4: load error

1. Stop the backend, navigate to `/tiers`
2. Expected: error text (`loadError`) + Retry button
3. Start the backend, press Retry → list loads

### Scenario 5: load-more error

1. Stop the backend after the first page loads, scroll to the bottom
2. Expected: `loadMoreError` message below the list

### Scenario 6: access without permissions (regression guard)

1. Log in as a regular user (without `manageTiers`)
2. Try to navigate to `/tiers` directly
3. Expected: navigation is blocked

## Regression check

- [ ] All previously working routes (`list_users`, `user_details`, `edit_user`, `login`) work without changes
- [ ] `PermissionGuard` on the `/tiers` route is still active
- [ ] `AuthGuard` fires before `PermissionGuard` for unauthenticated users
