# 0034 · pending_posts — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Log in as a moderator (non-superuser with `moderatePosts` permission), open the app shell. | The "Pending" tab label is visible in the nav bar. |
| M2 | Log in as a superuser, open the app shell. | Both the "Tiers" and "Pending" tab labels are visible in the nav bar simultaneously. |
| M3 | Log in as a regular user (no `moderatePosts` permission), open the app shell. | The "Pending" tab label is absent from the nav bar. |
| M4 | Browse the app as a guest (not authenticated), open the app shell. | The "Pending" tab label is absent from the nav bar. |
| M5 | As a moderator, tap the "Pending" tab. | The pending-posts list begins loading immediately without requiring a manual refresh. |
| M6 | As a moderator, tap the "Pending" tab while the server responds slowly. | A circular progress indicator is visible in the screen body during the initial page fetch. |
| M7 | After the pending list loads, inspect a tile in the list. | The tile displays the post title, the author username, the creation date, and a chip showing the count of moderation-log events. |
| M8 | As a moderator with more than 10 pending posts, scroll to the bottom of the list. | The next page is fetched automatically and new tiles are appended below the existing ones. |
| M9 | While the additional-page fetch is in progress (slow network), observe the bottom of the list. | A circular progress indicator is shown below the last tile. |
| M10 | With the list loaded, simulate a network failure, then scroll to the bottom. | A retry button appears at the bottom; tapping it retries the page fetch and loads the next page on success. |
| M11 | On the pending list, pull down from the top to trigger a refresh. | A refresh indicator appears, the list resets to page 1, and fresh items replace the current ones. |
| M12 | Open the Pending tab when the server returns an empty item array. | A localized empty-state message is displayed and no list tiles are rendered. |
| M13 | Open the Pending tab while the server is unreachable or returns an error. | A localized error message and a Retry button are displayed; tapping Retry re-fetches page 1. |
| M14 | In the pending list, tap a tile. | The moderation screen for that post opens (slice D route). |
| M15 | Open the pending list, then moderate a post from the moderation screen so that `PostModeratedEvent` is published. | The moderated post disappears from the list without a manual refresh or additional network call. |
| M16 | Navigate from the Pending list into the moderation screen (one level deep), then tap the "Pending" tab label. | The navigation stack resets to the pending-posts list root. |
| M17 | While the Pending tab is active, log out. | The app redirects to the Users tab (index 0) without showing the protected screen. |
| M18 | Attempt direct URL navigation to `/pending` while logged in as a regular user (no `moderatePosts`). | The route guard rejects the navigation and the user does not reach the pending screen. |
| M19 | Log in as a superuser, then log out. | After logout the app is on the Users tab and neither the "Tiers" nor "Pending" tab is active. |

## Code review

- [ ] No hardcoded strings in `pending_posts/presentation/` — all UI text uses `context.t.posts.pendingPosts.*` and `context.t.nav.pending`.
- [ ] `PendingPostsAdapter` contains an inner `on DioException` catch (typed HTTP mapping) and an outer `on Object` catch-all that calls `_logger.error` and returns `Failure.unknown()`.
- [ ] Adapter maps: 401 → `UnauthorizedFailure`, 403 → `PermissionDenied`, 404 → `NotFoundFailure`, status ≥ 500 → `ServerFailure(statusCode)`, network → `NetworkFailure`.
- [ ] `PendingPostsState` declaration uses `@freezed sealed class` with variants `initial`, `loading`, `loaded`, and `error`.
- [ ] `LoadMoreStatus` enum is defined inside `pending_posts_state.dart` — no import of `LoadMoreStatus` from `list_posts_state.dart` or `user_posts_state.dart`.
- [ ] No file under `lib/features/posts/pending_posts/` imports from `list_posts/`, `user_posts/`, `create_post/`, `edit_post/`, `post_details/`, or any other named slice.
- [ ] Files under `pending_posts/domain/` import only `dartz`, `freezed_annotation`, or pure Dart packages — no `package:flutter/*` or `package:dio/*`.
- [ ] `ModerationLogEntry`, `PendingPostItem`, and `PaginatedResult<T>` are located in `lib/features/posts/_shared/domain/entities/`.
- [ ] `ModerationLogEntryDto`, `PendingPostItemDto`, and `PendingPostsDto` use `sealed class` (not bare `class`) in their `@freezed` annotation.
- [ ] No business logic inside any `build()` method — `load()`, `loadMore()`, and scroll listener registration are in `initState` or the Cubit.
- [ ] `PendingPostsScreen` and `PendingPostTile` contain no `setState` call.
- [ ] No `import 'package:dio/dio.dart'` in any file under `pending_posts/presentation/`.
- [ ] `PendingPostsCubit` is annotated `@injectable`; `PendingPostsAdapter` is annotated `@LazySingleton(as: PendingPostsPort)`.
- [ ] `_AppNavBar` in `app_shell_screen.dart` reads `permissions.contains(Permission.moderatePosts)` from `PermissionCubit` (not `isSuperuser` from `AuthCubit`) to toggle the "Pending" tab.
- [ ] `PendingTabRoute()` is the fourth entry (index 3) in the `AutoTabsRouter.routes` list in `app_shell_screen.dart`.
- [ ] `AppShellScreen` `listenWhen` covers both `tabsRouter.activeIndex == 2` (Tiers) and `tabsRouter.activeIndex == 3` (Pending) for the logout redirect.
- [ ] `PostModeratedEvent` in `post_event.dart` carries a `postUuid: String` field; `PendingPostsCubit` filters on `postUuid` to remove the moderated item.
- [ ] `PendingTabRoute` in `app_router.dart` is guarded by both `authGuard` and `PermissionGuard({Permission.moderatePosts}, permissionCubit)`.
- [ ] `AppBreakpoints.medium = 600.0` is declared as a constant in `lib/core/theme/app_breakpoints.dart` inside an `abstract final class`.
- [ ] Existing tests for `ListPostsCubit` and `UserPostsCubit` still pass after the `post_event.dart` modification (no regression from adding `PostModeratedEvent`).
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
