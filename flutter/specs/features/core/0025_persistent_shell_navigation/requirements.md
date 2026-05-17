# 0025 · persistent_shell_navigation — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The app shell (AppBar and tab bar) remains visible when the user navigates from a tab's root page to a detail, edit, or create page within the same tab. |
| F2 | A back-arrow button appears in the AppBar whenever the active tab's navigation stack contains more than one page. |
| F3 | The back-arrow is absent when the user is on the root page of the active tab. |
| F4 | Tapping the back-arrow navigates exactly one level back within the active tab's stack. |
| F5 | On Android, the hardware back button navigates one level back within the active tab's stack. |
| F6 | After a user account is successfully deleted, the Users tab stack is replaced with the Users list page and the shell remains visible. |
| F7 | After a post is successfully deleted, the active tab's stack returns to the immediately preceding page (User Posts list when entered from the Users tab; Posts list when entered from the Posts tab). |
| F8 | After a tier is successfully deleted, the Tiers tab stack returns to the Tiers list page and the shell remains visible. |
| F9 | The Create User form opens as a page within the Users tab stack. |
| F10 | The Edit User form opens as a page within the Users tab stack. |
| F11 | The User Posts page (posts belonging to a specific user) opens within the Users tab stack. |
| F12 | Post Details reached from within the Users tab stack (e.g., via User Posts) opens within the Users tab stack. |
| F13 | Post Details reached from the global Posts list opens within the Posts tab stack. |
| F14 | The Create Post form opens within the tab stack from which it was initiated (Posts tab for global creation; Users tab for user-context creation). |
| F15 | The Edit Post form opens within the tab stack from which it was initiated (Posts tab for global context; Users tab for user context). |
| F16 | The Create Tier form opens within the Tiers tab stack. |
| F17 | The Edit Tier form opens within the Tiers tab stack. |
| F18 | When the authenticated session ends while the Tiers tab is active, the shell automatically switches to the Users tab. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | The three tab wrapper pages (`UsersTabPage`, `PostsTabPage`, `TiersTabPage`) are `@RoutePage()` classes whose `build` method returns `const AutoRouter()`, with no business logic, no DI provision, and no `BlocProvider`. |
| N2 | Navigation guards (`authGuard`, `PermissionGuard`) remain on individual child routes; the tab wrapper pages carry no guards. |
| N3 | `AutoLeadingButton` is rendered by `AppShellScreen` as the `leading` property of the `AppBar`; no individual page widget manages the back-arrow. |
| N4 | No navigation call within a delete-action presentation widget uses `context.router.root`; all `pop()` and `replaceAll()` calls operate on the active tab's inner router. |
| N5 | The three tab wrapper route files reside in `lib/core/routing/tabs/`; all route registration remains in `app_router.dart`. |
| N6 | `dart run build_runner build --delete-conflicting-outputs` is executed after introducing the three new `@RoutePage()` classes to regenerate `app_router.gr.dart`. |
| N7 | No file outside `lib/core/routing/` is modified, except for any delete-button presentation file whose navigation call is found to require correction per the plan's Step 4 audit. |
| N8 | The Tiers tab index value `2` used in `AppShellScreen`'s `listenWhen` guard is not changed. |
| N9 | All UI strings introduced or changed pass through `slang`; no hardcoded string literals appear in widget files. |
| N10 | `dart format .` produces no diff and `dart analyze` reports no warnings after all changes. |

## Out of scope

- Changing the visual design of the tab bar or AppBar beyond adding `AutoLeadingButton`.
- Deep-link URL ambiguity resolution for routes that appear in multiple tab stacks.
- Cross-tab navigation (e.g., tapping a username inside the Posts tab navigates to Users tab).
- AppBar title changes per page.
- Replacing the top tab bar with a bottom navigation bar.
