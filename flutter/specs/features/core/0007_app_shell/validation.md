# Validation: 0007 — AppShell Navigation

## Manual Testing Scenarios

### Tab Visibility
- [ ] Unauthenticated user: only the Users tab is visible, Tiers is absent
- [ ] Logged-in user with `isSuperuser == false`: only the Users tab is visible
- [ ] Logged-in user with `isSuperuser == true`: both tabs are visible

### Navigation
- [ ] Tapping Users → the user list opens
- [ ] Tapping Tiers (superuser) → the tier list opens
- [ ] The active tab is visually highlighted
- [ ] Navigating to `/tiers` without permissions → redirect to login (guard works)

### Authorization During Use
- [ ] Superuser on the Tiers tab → logs out → automatically switches to Users, the Tiers tab disappears
- [ ] Superuser on the Tiers tab → token expires (SessionExpiredEvent) → switches to Users

### State Preservation
- [ ] Navigate Users → UserDetails → back: returns to Users, Users tab is active
- [ ] Navigate Tiers → CreateTier → back: returns to Tiers, Tiers tab is active

### Regression
- [ ] FAB on Users (add user) works
- [ ] FAB on Tiers (add tier, superuser) works
- [ ] Pull-to-refresh on both screens works
- [ ] AppBar buttons (auth action) work correctly

## Tests

- [ ] widget test AppShellScreen: unauthenticated → 1 tab
- [ ] widget test AppShellScreen: superuser → 2 tabs
- [ ] widget test AppShellScreen: regular user → 1 tab
- [ ] widget test AppShellScreen: superuser on Tiers → logout → activeIndex == 0
