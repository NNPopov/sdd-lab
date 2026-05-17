# 0035 · moderate_post — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Log in as a user with `Permission.moderatePosts` and tap any tile on the Pending Posts screen. | The moderation screen opens and the post title and body text are visible immediately — no separate loading indicator for post content. |
| M2 | Log in as a regular user (no `moderatePosts` permission) and attempt to navigate directly to `/pending/<any-uuid>/moderate`. | Navigation is blocked; the user is redirected away from the route (guard fires). |
| M3 | Open the app without logging in and attempt to navigate directly to `/pending/<any-uuid>/moderate`. | Navigation is blocked; the user is redirected to the login screen (auth guard fires). |
| M4 | As a moderator, tap a tile on the pending posts screen. | The moderation screen opens with the post title, body text, and (if present) media image rendered before the moderation panel loads — no loading delay for post content. |
| M5 | Inspect the post content pane of the moderation screen. | Title and body text are visible. There are no Edit or Delete buttons — the view is read-only. |
| M6 | Open the moderation screen for a post that has a media URL. | The media image is displayed in the post content pane. |
| M7 | Open the moderation screen on a device or resized window that is ≥ 600 dp wide. | Two panes are visible side by side — the post content on the left, the moderation panel on the right — separated by a vertical divider. |
| M8 | Open the moderation screen on a device or resized window that is < 600 dp wide. | A two-tab layout is shown with "Post" as the active tab by default and "Moderation" visible as the second tab. |
| M9 | On narrow layout (< 600 dp), tap the "Moderation" tab. | The moderation panel becomes visible, containing the log area, message field, and action buttons. |
| M10 | On wide layout (≥ 600 dp), open the moderation screen and immediately observe the log pane. | A loading indicator is visible in the log pane — the log has started loading without any user interaction. |
| M11 | On narrow layout (< 600 dp), open the moderation screen and observe the Post tab. | Only post content is visible; no log network request is triggered. Now tap the Moderation tab. | The log begins loading (loading indicator appears in the panel). |
| M12 | On narrow layout, after the log has loaded, switch back to the Post tab and then back to the Moderation tab. | The previously loaded log entries are shown immediately — no second loading indicator, no second network request. |
| M13 | Open the moderation screen for a post with several moderation log entries. | Each log entry displays: actor username, formatted timestamp, event-type indicator, an action label ("Approved" or "Changes Requested") for `moderator_review` events, and the message text if present. |
| M14 | Open the moderation screen for a freshly submitted post that has no moderation history. | The log area displays a localised empty-state message (e.g. "No moderation history yet") — not a blank area or an error. |
| M15 | On wide layout, immediately after the screen opens, observe the log pane before loading completes. | A loading indicator (spinner or shimmer) is shown in the log pane. |
| M16 | In the moderation panel, tap the message text field and type a multi-line comment. | Text is accepted, displayed, and the field scrolls or expands as needed. |
| M17 | Leave the message field empty and tap "Approve". | The action is submitted. The screen pops back to the pending list. No validation error is shown. |
| M18 | Leave the message field empty and tap "Request Changes". | A localised validation error message is shown in the UI. The screen remains open. No network request is made. |
| M19 | Type a non-empty message and tap "Request Changes". | The action is submitted successfully. The screen pops back to the pending list. |
| M20 | Tap "Approve" and immediately inspect the button row before the response arrives. | Both "Approve" and "Request Changes" buttons are disabled while the request is in flight. |
| M21 | Observe the navigation after a successful "Approve" or "Request Changes" action completes. | The screen automatically pops back to the pending posts list — no back button press required. |
| M22 | After a successful moderation action, observe the pending posts list. | The post that was just moderated is no longer present in the list. |
| M23 | Simulate (or provoke) a 403 response from the moderation endpoint. | A localised permission-denied error message is displayed — not the generic error. |
| M24 | Simulate a 404 response from the moderation endpoint. | A localised post-not-found error message is displayed — not the generic error. |
| M25 | Simulate a 409 response from the moderation endpoint (post already moderated). | A specific localised conflict message is displayed (e.g. "This post has already been moderated. Return to the queue.") — not the generic error. |
| M26 | Disable the network and tap "Approve". | A localised generic error message is displayed. The screen remains open and does not crash. |
| M27 | Log in as a superuser, navigate to the Pending tab, open a pending post. | The moderation screen is accessible, and performing an Approve action completes end-to-end successfully. |
| M28 | On narrow layout, switch to the Moderation tab before the log has finished loading. | A loading indicator is shown in the moderation log area while the request is in flight. |

## Code review

- [ ] No hardcoded string literals in widget files — all user-visible text uses `context.t.posts.moderatePost.*` via slang.
- [ ] `ModeratePostAdapter` has an inner `on DioException catch` block mapping 403 → `ForbiddenFailure`, 404 → `NotFoundFailure`, 409 → `ConflictFailure`, plus an outer `catch (Object e, StackTrace st)` block that calls `_logger.error(...)` and returns `Left(Failure.unknown())`.
- [ ] `ModerationLogAdapter` has the same double-catch structure with 401 → `UnauthorizedFailure`, 403 → `ForbiddenFailure`, 404 → `NotFoundFailure`, outer catch logs and returns `Left(Failure.unknown())`.
- [ ] `IModeratePostPort` declares exactly one method (`call`) and lives in `moderate_post/domain/ports/`.
- [ ] `IModerationLogPort` declares exactly one method (`call`) and lives in `moderate_post/domain/ports/`.
- [ ] `ModeratePostUseCase` returns `Left(Failure.validation(...))` when `action == 'changes_requested'` and message is null or empty — the port is **not** called in this path.
- [ ] `ModeratePostState` is declared as `@freezed sealed class` via freezed.
- [ ] `ModerationLogState` is declared as `@freezed sealed class` via freezed.
- [ ] `PostModeratedEvent(postUuid)` is emitted on `PostEventBus` inside `ModeratePostCubit.moderate()` — no widget or route file touches the event bus directly.
- [ ] `context.router.pop()` is called inside a `BlocListener<ModeratePostCubit, ModeratePostState>` in the presentation layer — not inside the cubit.
- [ ] No file under `lib/features/posts/moderate_post/` imports from any other named post slice (`list_posts`, `pending_posts`, `create_post`, `edit_post`, etc.) — only `_shared/` and `core/` are allowed.
- [ ] No file under `lib/features/posts/moderate_post/domain/` imports `package:flutter/...`, `package:dio/...`, or any package other than `dartz`, `freezed_annotation`, or pure Dart.
- [ ] The route in `app_router.dart` is declared with `PermissionGuard({Permission.moderatePosts}, permissionCubit)` in its `guards` list.
- [ ] `ModeratePostAdapter` is annotated with `@LazySingleton(as: IModeratePostPort)`.
- [ ] `ModerationLogAdapter` is annotated with `@LazySingleton(as: IModerationLogPort)`.
- [ ] `ModeratePostRequestDto`, `ModeratePostResultDto`, and `ModerationLogResponseDto` are all `@freezed sealed class` with a `fromJson` factory — no raw `Map<String, dynamic>` access in adapter method bodies.
- [ ] `ModeratePostScreen` reads the breakpoint as `AppBreakpoints.medium` inside `LayoutBuilder` — the literal `600` does not appear in the widget file.
- [ ] `ModerationLogCubit` has a guard (e.g. a `bool _loaded` flag) that prevents more than one network call per screen lifecycle when `load()` is called multiple times.
- [ ] `posts_api_client.dart` contains a `@POST('/posts/{post_uuid}/moderate')` method and a `@GET('/posts/{post_uuid}/moderation-log')` method.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
