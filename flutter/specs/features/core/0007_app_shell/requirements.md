# Requirements: 0007 — AppShell Navigation

## Business Requirements

1. A navigation bar with two items appears at the top of all main screens.
2. The **Users** item — always visible.
3. The **Tiers** item — visible only if the user is logged in AND `currentUser.isSuperuser == true`.
4. Tapping an item navigates to the corresponding screen without rebuilding the AppBar.
5. If the user logs out (or the token expires) while on the Tiers tab — the app automatically switches to Users.
6. Direct URL navigation to `/tiers` without permissions remains protected by a guard (403/redirect to login).

## Constraints

- No new API calls.
- No new Permissions in the enum — `isSuperuser` is used for tab visibility, not `manageTiers`.
- `manageTiers` remains as a route guard on the Tiers route (for direct URL protection).
