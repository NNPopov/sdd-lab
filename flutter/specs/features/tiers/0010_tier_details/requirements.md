# Requirements: 0010 tier_details

## Business goal

Show detailed information about a single tier (name, ID, creation date) on a separate
screen accessible from the list. This slice is a prerequisite for `update_tier`.

## What must work

### Functional requirements

1. **Navigation from the list.** Tapping a `TierTile` in `list_tiers` opens the details screen.
2. **Data loading.** The screen performs `GET /api/v1/tier/{name}` and displays the response.
3. **Fields.** The screen shows: name, id, created_at (formatted date).
4. **Screen states:**
   - Loading — spinner while the request is in progress
   - Loaded — card with data
   - Error (404) — message "Tier not found"
   - Error (other) — error message + Retry button
5. **Retry.** The Retry button re-initiates the load.

### Permissions (RBAC)

- The `/tier/:name` route is protected by `PermissionGuard({Permission.manageTiers})` —
  the same permissions as `list_tiers`.
- The use-case checks `Permission.manageTiers` and returns `Left(PermissionDenied())`
  when the permission is absent.

## Out of scope

- Editing a tier — this will be `update_tier` (a separate slice).
- Deleting a tier — a separate slice.
- Navigation to tier_details from anywhere other than `list_tiers`.
