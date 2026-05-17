# Validation: 0010 tier_details

## Automated checks

- [ ] `dart run build_runner build` completes without errors
- [ ] `dart run slang` completes without errors
- [ ] `flutter analyze` — 0 errors, 0 warnings
- [ ] `flutter test test/features/tiers/tier_details/` — all tests green

## UX walkthrough (manual)

### Happy path

1. Log in as a user with the `manageTiers` permission
2. Navigate to the Tiers tab — tier list loads
3. Tap any tier — the details screen opens
4. Screen shows: name (title), ID, creation date (not empty)
5. Press Back — return to the list, list is not reset

### Not found

1. (Test only or temporary substitution) Open URL `/tier/nonexistent`
2. Screen shows the message "Tier not found" (without Retry)

### Network / server error

1. Disconnect the network, open tier details
2. Screen shows an error message + Retry button
3. Reconnect the network, press Retry — data loads

### Permissions

1. Log in as a user WITHOUT the `manageTiers` permission
2. The Tiers tab is inaccessible (guard on list_tiers fires first)
3. Direct navigation to `/tier/Free` — the route guard returns to login or
   shows forbidden (depends on `PermissionGuard` behavior)

## Architecture checks

- [ ] `TierDetail` and `TierDetailDto` are declared in `tier_details/`, NOT in `_shared/`
- [ ] `GetTierAdapter` has double catch with `_logger.error(..., stackTrace: st)`
- [ ] `GetTierUsecase` checks `Permission.manageTiers`
- [ ] `TierDetailsRoute` is registered in `app_router.dart` with `PermissionGuard`
- [ ] `list_tiers` cubit/domain/data files were not modified (only presentation)
- [ ] No hardcoded strings in the UI — all via `context.t.tiers.tierDetails.*`
