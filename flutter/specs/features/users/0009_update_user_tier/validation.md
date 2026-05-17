# Validation — update_user_tier

## Implementation verification checklist

### Button accessibility

- [ ] Log in as a regular user (`isSuperuser: false`) → "Change Tier" button is **not visible** in the AppBar
- [ ] Log in as a superuser (`isSuperuser: true`) → button is **visible**
- [ ] Button is present only in `user_details_screen`, not in `list_users`

### Tier loading

- [ ] Tap button → bottom sheet opens with a loading indicator
- [ ] After loading → dropdown is filled with tiers
- [ ] On network error → error message + Retry button

### Selection and confirmation

- [ ] Confirm button is disabled until a tier is selected
- [ ] Select a tier → Confirm becomes active
- [ ] Tap Confirm → button shows a loading indicator (disabled)

### Success

- [ ] After a successful PATCH → sheet closes
- [ ] Snackbar "User tier updated" is shown
- [ ] Tier in `UserDetailsView` is updated (new tierName is visible)
- [ ] Open the sheet again → dropdown is reset (initial state)

### Errors

- [ ] 403 from server → snackbar "Permission denied"
- [ ] 404 from server → snackbar "User or tier not found"
- [ ] No network → snackbar with generic error

### RBAC use-case

- [ ] In test: `isSuperuser: false` → `Left(PermissionDenied())`, port not called
- [ ] In test: `isSuperuser: true` → port called

### Isolation

- [ ] No imports from `features/tiers/**`
- [ ] No imports from other slices of the `users` feature
- [ ] `TierOption` is a separate class, not `Tier` from the tiers feature

### Tests

- [ ] `update_user_tier_cubit_test.dart` — all scenarios green
- [ ] `fetch_tiers_adapter_test.dart` — all scenarios green
- [ ] `update_user_tier_adapter_test.dart` — all scenarios green
- [ ] logger.error is called with `stackTrace` in unexpected exception tests

### Localization

- [ ] `dart run slang` executed after adding keys
- [ ] All new UI strings use `context.t.users.updateTier.*`
- [ ] Keys are present in `en.json` and `ru.json`
