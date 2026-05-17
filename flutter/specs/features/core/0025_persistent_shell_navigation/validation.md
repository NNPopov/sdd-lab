# 0025 · persistent_shell_navigation — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | On the Users tab, tap any user in the list. | User Details page opens. The tab bar and AppBar remain visible. A back-arrow appears in the AppBar. |
| M2 | On the Posts tab, tap any post in the list. | Post Details page opens. The tab bar and AppBar remain visible. A back-arrow appears in the AppBar. |
| M3 | Log in as a superuser. On the Tiers tab, tap any tier. | Tier Details page opens. The tab bar and AppBar remain visible. A back-arrow appears in the AppBar. |
| M4 | Observe the AppBar while on the Users list (root of Users tab). | No back-arrow is shown in the AppBar. |
| M5 | Observe the AppBar while on the Posts list (root of Posts tab). | No back-arrow is shown in the AppBar. |
| M6 | Observe the AppBar while on the Tiers list (root of Tiers tab, superuser). | No back-arrow is shown in the AppBar. |
| M7 | Navigate to a User Details page. Tap the back-arrow in the AppBar. | The app returns to the Users list. The tab bar is still visible. |
| M8 | Navigate: Users tab → User Details → tap "Posts" → User Posts page → tap a post → Post Details. Tap the back-arrow three times, one at a time. | Each tap moves one level back: Post Details → User Posts → User Details → Users list. The tab bar remains visible at every level. |
| M9 | On Android, navigate to a User Details page. Press the hardware back button. | The app returns to the Users list. The tab bar is still visible. |
| M10 | Log in as the owner of an account. Open that account's User Details page. Delete the account (confirm the dialog). | After deletion: the Users list is shown, the shell (tab bar + AppBar) is still visible, and a "deleted" snackbar appears. The user is now logged out. |
| M11 | Log in. Navigate to a post via the global Posts list (Posts tab). Delete the post (confirm the dialog). | After deletion: the Posts list is shown within the Posts tab. The tab bar is still visible. A success snackbar appears. |
| M12 | Log in. Navigate to a user's User Posts page (via Users tab → User Details → Posts). Open a post the logged-in user owns. Delete it (confirm). | After deletion: the User Posts page is shown, still within the Users tab. The tab bar is still visible. A success snackbar appears. |
| M13 | Log in as a superuser. Navigate to Tier Details. Delete the tier (confirm). | After deletion: the Tiers list is shown within the Tiers tab. The tab bar is still visible. A success snackbar appears. |
| M14 | On the Users tab, tap the "Create User" button. | The Create User form opens. The tab bar and AppBar are still visible. |
| M15 | Navigate to User Details. Tap the Edit (pencil) button in the AppBar. | The Edit User form opens within the Users tab. The tab bar is still visible. Tapping the back-arrow (or saving) returns to User Details. |
| M16 | From User Details, tap the button that leads to the User Posts page. | The User Posts page opens. The tab bar is still visible. The back-arrow leads back to User Details. |
| M17 | On the User Posts page (accessed via Users tab), tap a post. | Post Details opens within the Users tab stack. The tab bar is still visible. The back-arrow leads back to User Posts. |
| M18 | On the Posts tab global list, tap a post. | Post Details opens within the Posts tab stack. The tab bar is still visible. The back-arrow leads back to the global Posts list. |
| M19 | On the Posts tab global list, tap "Create Post". | The Create Post form opens within the Posts tab. The tab bar is still visible. |
| M20 | On the User Posts page (via Users tab), tap "Create Post". | The Create Post form opens within the Users tab. The tab bar is still visible. |
| M21 | On Post Details accessed from the global Posts list, tap "Edit". | The Edit Post form opens within the Posts tab. The tab bar is still visible. |
| M22 | On Post Details accessed from User Posts (Users tab path), tap "Edit". | The Edit Post form opens within the Users tab. The tab bar is still visible. |
| M23 | On the Tiers tab, tap "Create Tier". | The Create Tier form opens within the Tiers tab. The tab bar is still visible. |
| M24 | On Tier Details, tap "Edit". | The Edit Tier form opens within the Tiers tab. The tab bar is still visible. |
| M25 | Log in as a superuser. Navigate to the Tiers tab. Log out (via the logout button in the AppBar). | The shell switches to the Users tab automatically. The tab bar and AppBar remain visible. |

## Code review

- [ ] `lib/core/routing/tabs/users_tab_route.dart`, `posts_tab_route.dart`, and `tiers_tab_route.dart` each exist and contain only a `@RoutePage()` class whose `build` returns `const AutoRouter()` — no `BlocProvider`, no `getIt`, no business logic.
- [ ] `app_router.dart`: `UsersTabRoute`, `PostsTabRoute`, `TiersTabRoute` appear as the three children of `AppShellRoute` — not `UsersRoute`, `ListPostsRoute`, or `ListTiersRoute` directly.
- [ ] `app_router.dart`: no `guard` is set on `UsersTabRoute`, `PostsTabRoute`, or `TiersTabRoute` themselves; guards remain only on individual child routes.
- [ ] `app_router.dart`: all detail, edit, and create routes previously at the top level (e.g. `UserDetailsRoute`, `EditUserRoute`, `PostDetailsRoute`, `CreatePostRoute`, `TierDetailsRoute`, `EditTierRoute`, etc.) are now listed as `children` of the appropriate tab route and are absent from the top-level route list.
- [ ] `app_router.dart`: `PostDetailsRoute.page` appears in the children of both `UsersTabRoute` and `PostsTabRoute` with appropriate relative path segments for each tab context.
- [ ] `app_shell_screen.dart`: `AutoTabsRouter` `routes` list references `[UsersTabRoute(), PostsTabRoute(), TiersTabRoute()]`.
- [ ] `app_shell_screen.dart`: `AppBar` has `leading: const AutoLeadingButton()`.
- [ ] `app_shell_screen.dart`: `listenWhen` guard still reads `tabsRouter.activeIndex == 2` — unchanged.
- [ ] Grep for `context.router.root` across all `presentation/` files — zero matches.
- [ ] `delete_account_button.dart` navigation on success uses `context.router.replaceAll([UsersRoute()])` (not `root.replaceAll`) — operates on the inner UsersTab router.
- [ ] `delete_post_button.dart` navigation on success uses `context.router.pop()` — no change needed.
- [ ] `delete_tier_button.dart` navigation on success uses `context.router.pop()` — no change needed.
- [ ] Git diff shows no modifications to any file outside `lib/core/routing/` other than the delete-button files confirmed unchanged by the plan Step 4 audit.
- [ ] No hardcoded string literals in any modified or created widget file — all UI text via `context.t.*`.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
