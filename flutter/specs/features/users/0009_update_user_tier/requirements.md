# Requirements — update_user_tier

## Functional requirements

### FR-1: Button visibility
The "Change Tier" button is displayed in the AppBar of the `user_details` screen only if
the current user has `Permission.editUserTier` (granted to superusers).
For all other roles the button is hidden (`SizedBox.shrink()` via the existing
`BlocBuilder<PermissionCubit>`).

### FR-2: Tier list
When the button is tapped, a Modal Bottom Sheet opens which
loads the list of all available tiers via `GET /tiers`.

### FR-3: Tier selection
The bottom sheet displays a dropdown (`DropdownButtonFormField`) with tier names.
Nothing is selected by default. The Confirm button is disabled until a tier is selected.

### FR-4: Confirm update
When Confirm is tapped, `PATCH /user/{username}/tier` is sent with the selected `tier_id`.

### FR-5: Success
After a successful update:
1. The bottom sheet closes
2. A snackbar with the text "User tier updated" is shown
3. The tier in `UserDetailsView` is updated (via `GetUserTierCubit.load()`)

### FR-6: Errors
On error a snackbar with an error description is shown. The tier list stays open,
the user can retry. Separate texts for:
- PermissionDenied (422)
- NotFound (404)
- Forbidden (403)
- Unauthorized (401)
- Generic

### FR-7: Tier loading
While tiers are loading — `CircularProgressIndicator` in the center of the sheet.
On tier load error — error message + Retry button.

## Non-functional requirements

### NFR-1: RBAC — two levels
- **UI level**: button is hidden for non-superusers
- **Use-case level**: `UpdateUserTierUseCase` returns `Left(PermissionDenied())`
  if `isSuperuser == false`

### NFR-2: Slice isolation
- Slice does not import from other slices of the `users` feature
- Slice does not import from `features/tiers/`
- `TierOption` is a separate domain entity of the slice (does not reuse `Tier` from the tiers feature)

### NFR-3: Defensive adapters
Both adapters have a two-level catch per CLAUDE.md §8.4.

### NFR-4: Localization
All strings via slang. No hardcoded strings in the UI.

### NFR-5: Tests
Coverage: cubit (all states), both adapters (happy path + all HTTP errors + unexpected exception).
