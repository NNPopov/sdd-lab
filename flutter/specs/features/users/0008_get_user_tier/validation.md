# Validation — 0008 get_user_tier

## Manual verification checklist

### Main flow
- [ ] Open the user details screen for a user with an assigned tier
- [ ] Verify that main data (name, email, avatar) are displayed immediately
- [ ] The Tier row shows `common.loading` while loading is in progress
- [ ] After loading the Tier row shows `tier_name` (e.g., `"Free"`)
- [ ] The "Tier since" row shows the date in format `2026-04-25 15:55` (local time)
- [ ] `tier_id` as a number is not shown anywhere

### Edge cases
- [ ] User without a tier (`tierId == null` in `User`) → Tier block is absent,
      screen does not break, no API request is sent
- [ ] API `/tier` returned 404 → Tier block is silently hidden, screen works normally
- [ ] Network error during tier loading → Tier block is hidden, main data visible
- [ ] API response contains `tier_created_at: null` → "Tier" row exists, "Tier since" — does not
- [ ] Tap Retry on main data error → the whole page is recreated,
      tier loads again after a successful response

### Regression
- [ ] Other `users` slices are not affected: list, create, edit, delete, erase_db work
- [ ] `user_details_route.dart` correctly provides both Cubits via DI
- [ ] Tests: `get_user_tier_adapter_test.dart` and `get_user_tier_cubit_test.dart`
      are green, cover happy path + all Failures + unexpected exception

## Architectural check

- [ ] `get_user_tier/domain/` does not import Flutter, Dio or other packages
      other than `dartz`, `freezed`, pure Dart
- [ ] `GetUserTierAdapter` has double catch with `_logger.error(..., stackTrace: st)`
- [ ] `UserDetailsView` does not import from `get_user_tier/` — it accepts only
      `String? tierName`, `DateTime? tierCreatedAt`, `bool tierLoading`
- [ ] Date formatting happens in `UserDetailsView._formatDate`, not in the adapter
      or use-case
- [ ] `intl` is not added to `pubspec.yaml` explicitly if it already exists as a transitive dependency
- [ ] `GetUserTierCubit` is not a singleton (`@injectable`, not `@lazySingleton`)
