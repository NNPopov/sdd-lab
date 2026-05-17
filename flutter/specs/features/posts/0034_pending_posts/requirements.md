# 0034 · pending_posts — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The "Pending" tab is visible in the app navigation bar only to authenticated users whose permission set includes `moderatePosts`. |
| F2 | The "Pending" tab is invisible to guests and to authenticated users whose permission set does not include `moderatePosts`. |
| F3 | When the "Pending" tab is opened, the system automatically fetches the first page of posts with `pending_review` status from `GET /posts/pending`. |
| F4 | While the first page is loading, a circular progress indicator is displayed in the screen body. |
| F5 | Each pending-post tile displays the post title, the author username, the creation date, and a chip showing the count of moderation-log events for that post. |
| F6 | When the user scrolls to within 200 px of the bottom of the list, the system fetches the next page and appends the new items. |
| F7 | While an additional-page fetch is in progress, a circular progress indicator is shown at the bottom of the list. |
| F8 | If an additional-page fetch fails, a retry button is shown at the bottom of the list; tapping it retries the page fetch. |
| F9 | Pull-to-refresh resets the list to page 1 and re-fetches from the server. |
| F10 | When the loaded list is empty, a localized empty-state message is displayed. |
| F11 | When the initial load fails, a localized error message and a Retry button are displayed; tapping Retry re-fetches page 1. |
| F12 | Tapping a pending-post tile navigates to the moderation screen for that post, passing the `PendingPostItem` as route extras. |
| F13 | When `PostModeratedEvent` is received for a post UUID present in the loaded list, that post is removed from the list without making a network request. |
| F14 | Tapping the "Pending" tab label when already on that tab resets the navigation stack to the list root. |
| F15 | If the user is logged out while the "Pending" tab is active, the app redirects to the Users tab (index 0). |
| F16 | The "Pending" tab route is declared at index 3 in `AutoTabsRouter.routes` regardless of its nav-bar visibility. |
| F17 | The "Pending" tab route tree is guarded by `authGuard` and `PermissionGuard({Permission.moderatePosts})`; unauthenticated or unpermitted navigation is rejected at the router level. |
| F18 | A superuser sees both the "Tiers" tab and the "Pending" tab simultaneously in the nav bar. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | All UI strings in the slice are served via `slang` (`context.t.*`); no string literals appear in widget files. |
| N2 | `PendingPostsAdapter` implements the double-catch pattern: inner `on DioException` maps HTTP codes to typed `Failure` variants; outer `on Object` logs via `AppLogger.error` and returns `Failure.unknown()`. |
| N3 | The adapter maps: 401 → `UnauthorizedFailure`, 403 → `PermissionDenied`, 404 → `NotFoundFailure`, 5xx → `ServerFailure(statusCode)`, network error → `NetworkFailure`; the 403 mapping duplicates the route-level guard defensively. |
| N4 | `PendingPostsState` is a `@freezed` sealed class with variants `initial`, `loading`, `loaded`, and `error`. |
| N5 | `LoadMoreStatus` enum is defined locally in `pending_posts_state.dart` and is not imported from any other slice's state file. |
| N6 | No file inside `pending_posts/` imports from any other named slice of the `posts` feature; only `posts/_shared/` imports are permitted across slice boundaries within the feature. |
| N7 | Files in `pending_posts/domain/` (`PendingPostsPort`, `GetPendingPostsUseCase`) do not import from `package:flutter/*`, `package:dio/*`, or any package outside `dartz`, `freezed_annotation`, or pure Dart. |
| N8 | `ModerationLogEntry`, `PendingPostItem`, and `PaginatedResult<T>` are placed in `posts/_shared/domain/entities/` so that slice D (`moderate_post`) can import them without violating slice-isolation rules. |
| N9 | New `@freezed` DTOs (`ModerationLogEntryDto`, `PendingPostItemDto`, `PendingPostsDto`) use `sealed class`, not `class`, to comply with the Dart 3.x abstract-mixin constraint. |
| N10 | No business logic is placed inside any widget `build()` method. |
| N11 | No `setState` call appears in any widget that owns a `PendingPostsCubit`. |
| N12 | Dio is never called directly from the presentation layer. |
| N13 | `PendingPostsCubit` is annotated `@injectable`; `PendingPostsAdapter` is annotated `@LazySingleton(as: PendingPostsPort)`. |
| N14 | The nav-bar visibility of the "Pending" tab is determined by reading `Permission.moderatePosts` from `PermissionCubit`, not by reading `isSuperuser` from `AuthCubit`. |
| N15 | The "Pending" tab is always at index 3 in `AutoTabsRouter.routes`; the declaration order in the router does not change based on user role. |
| N16 | `AppBreakpoints.medium = 600.0` is introduced as an `abstract final class` constant in `lib/core/theme/app_breakpoints.dart`, not inside the slice. |

## Out of scope

- The moderation screen itself (slice D, `moderate_post`).
- Displaying `pending_review` posts in the regular Posts feed or user_posts list.
- Push notifications for newly submitted pending posts.
- Sorting or filtering the pending queue beyond what the backend provides.
- Any changes to the `Post` entity or existing post DTOs (slice A).
- Any changes to the `User` entity or the `Permission` enum (slice B, `moderator_contract`).
