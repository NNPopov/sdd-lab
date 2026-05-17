# Requirements: create_tier (0006)

## Functional requirements

| # | Requirement |
|---|---|
| F-01 | The tier list screen displays a FAB with a `+` icon |
| F-02 | The FAB is visible only to users with `Permission.manageTiers` |
| F-03 | Tapping the FAB opens the tier creation screen (`/tiers/new`) |
| F-04 | The creation screen contains one field: **Name** (name) |
| F-05 | The name field cannot be empty (client-side validation) |
| F-06 | During form submission the button is disabled until a response is received |
| F-07 | On success: snackbar "Tier created", pop back, list refreshes |
| F-08 | On conflict (409): snackbar with an error message |
| F-09 | On server validation error (422): errors shown below the fields |
| F-10 | On other errors: generic snackbar |

## Non-functional requirements

| # | Requirement |
|---|---|
| N-01 | The `/tiers/new` route is protected by `AuthGuard` + `PermissionGuard(manageTiers)` |
| N-02 | The use-case duplicates the `Permission.manageTiers` check |
| N-03 | The adapter implements double-catch (DioException + catch-all with logging) |
| N-04 | UI strings only via slang (no hardcoded strings) |
| N-05 | `TiersApiClient`, `TierDto`, `Tier` are moved to `_shared/` |

## Out of scope

- Fields other than `name` (e.g. `description`, `price`)
- Editing a tier
- Deleting a tier
