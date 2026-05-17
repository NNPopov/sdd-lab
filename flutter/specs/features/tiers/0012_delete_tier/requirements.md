# 0012 delete_tier — Requirements

## Business requirement

A superuser can delete a tier directly from the details screen. The operation is irreversible,
so it requires explicit confirmation via a dialog. After success the user returns
to the tier list and the list refreshes.

## Actors and permissions

- **Sees the Delete button:** only `currentUser.isSuperuser == true`
- **Use-case protection:** `isSuperuser` is passed as an explicit parameter,
  the use-case returns `Left(Failure.permissionDenied())` if false
- **Unauthenticated user:** no button, use-case is not called

## UX scenarios

### Happy path
1. Superuser opens `tier_details_screen`
2. In the AppBar alongside the Edit button a Delete button appears (icon `delete_outline`, red)
3. Presses Delete → confirmation dialog appears with the tier name
4. Confirms → button shows a loading indicator
5. API responds 200 → snackbar "Tier deleted" + `router.pop()` to `list_tiers`
6. `list_tiers` automatically refreshes the list

### Cancel
- Pressed Cancel in the dialog → dialog closes, state returns to initial

### 404 (tier already deleted)
- API returned 404 → snackbar "Tier not found" + `router.pop()` to `list_tiers`
- Tactically this is also a "success" from the UX perspective: the tier is gone, the goal is achieved

### Errors
- 403 / `PermissionDenied` → snackbar with error text, remain on screen
- Network / Server / Unknown → snackbar with error text, remain on screen

## Scope limitations

- The Delete button is placed **only** in `tier_details_screen`
- Deletion from `list_tiers` (swipe, long-press) — out of scope
- The slice has no own route or screen
