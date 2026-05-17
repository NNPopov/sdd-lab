# Validation: create_tier (0006)

## Pre-submission checklist

### _shared/ refactoring

- [ ] `_shared/domain/entities/tier.dart` created, original deleted
- [ ] `_shared/data/dto/tier_dto.dart` created, original deleted (+ .freezed.dart, .g.dart)
- [ ] `_shared/data/tiers_api_client.dart` created, original deleted (+ .g.dart)
- [ ] `_shared/data/dto/create_tier_request_dto.dart` created
- [ ] Imports in `list_tiers_adapter.dart` updated — compiles
- [ ] Imports in `paginated_tiers_dto.dart` updated — compiles
- [ ] Imports in `tiers_feature_module.dart` updated — compiles

### create_tier slice

- [ ] `domain/entities/new_tier_data.dart` created
- [ ] `domain/ports/create_tier_port.dart` created (narrow, 1 method)
- [ ] `domain/usecases/create_tier_usecase.dart` created with `Permission.manageTiers` check
- [ ] `data/create_tier_adapter.dart` created with double-catch + AppLogger
- [ ] `application/create_tier_state.dart` created (sealed + freezed)
- [ ] `application/create_tier_cubit.dart` created
- [ ] `presentation/create_tier_route.dart` created (`@RoutePage`)
- [ ] `presentation/create_tier_screen.dart` created

### Integration

- [ ] FAB added to `list_tiers_screen.dart`
- [ ] FAB navigation passes `Tier` back on success
- [ ] `ListTiersCubit.refresh()` is called on return with a result
- [ ] `CreateTierRoute` registered in `app_router.dart` with guards
- [ ] `tiers.createTier.*` keys added to `en.json` and `ru.json`
- [ ] `dart run slang` executed successfully

### Codegen

- [ ] `dart run build_runner build --delete-conflicting-outputs` passed without errors
- [ ] No dead `.g.dart` and `.freezed.dart` files from deleted originals

### Tests

- [ ] `create_tier_usecase_test.dart` written and green
- [ ] `create_tier_adapter_test.dart` written and green (including unexpected exception)
- [ ] `create_tier_cubit_test.dart` written and green
- [ ] Existing `list_tiers` tests are not broken

### UX

- [ ] FAB is not visible to a user without `Permission.manageTiers`
- [ ] Empty name → validation error, request not sent
- [ ] Successful creation → snackbar + list refreshed
- [ ] Conflict → snackbar with message (not generic)
- [ ] Button is disabled during submission
