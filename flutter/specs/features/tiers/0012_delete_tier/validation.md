# 0012 delete_tier — Validation Checklist

## Functionality

- [ ] Delete button is visible in AppBar only for superusers
- [ ] Delete button is not visible for regular users
- [ ] Pressing the button shows a dialog with the tier name
- [ ] Cancel in the dialog closes it, state returns to initial
- [ ] Confirmation triggers an API call, button shows spinner
- [ ] Successful deletion: snackbar "Tier deleted" + pop to list_tiers
- [ ] 404: snackbar "Tier not found" + pop to list_tiers
- [ ] Network/server error: snackbar with error text, remain on screen
- [ ] After returning to list_tiers the list automatically refreshes

## Architecture

- [ ] Use-case checks `isSuperuser` and returns `PermissionDenied` if false
- [ ] Adapter has double try/catch (CLAUDE.md §8.4)
- [ ] `NotFoundFailure` does not end up in `DeleteTierFailure` — handled separately in cubit
- [ ] Slice does not import other tiers slices directly
- [ ] `tiers_api_client.g.dart` regenerated after adding `deleteTier`
- [ ] `translations.g.dart` regenerated after adding keys

## Tests

- [ ] Cubit: 7 scenarios (see plan.md §12a)
- [ ] Adapter: 6 scenarios (see plan.md §12b)
- [ ] All tests green
