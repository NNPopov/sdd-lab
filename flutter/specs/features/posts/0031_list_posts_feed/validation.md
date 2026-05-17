# 0031 · list_posts_feed — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Open the app while logged out. Navigate to the Posts tab. | Posts list loads automatically. No login prompt is shown. |
| M2 | Open the app while logged in. Navigate to the Posts tab. | Posts list loads automatically. The same content is visible as when logged out. |
| M3 | While the Posts tab is loading on a slow connection, observe the screen. | A full-screen `CircularProgressIndicator` is visible. No post tiles are shown yet. |
| M4 | Wait for the list to finish loading. Inspect one post card. | The card shows: post title (bold), a plain-text preview ≤ 100 characters (markdown stripped), the publication date in "d MMM yyyy" format, and the author's username. |
| M5 | Inspect a post card whose body is longer than 100 characters. | The preview text ends with `...` at or before the 100-character limit. |
| M6 | Scroll down to the bottom of the loaded list when more posts exist. | Additional posts append to the list automatically without any button tap. A spinner is briefly visible at the bottom while the next page loads. |
| M7 | Scroll to the last available page of posts. Continue scrolling. | No further network request is made. The spinner does not appear again. |
| M8 | Pull the list downward and release. | The list resets to page 1 and reloads. Posts at the top are fresh (including any newly published ones). |
| M9 | With the server running, kill the network connection. Open the Posts tab from a cold state. | A full-screen error message is shown together with a Retry button. |
| M10 | While the error screen from M9 is showing, restore the network and tap Retry. | The list loads successfully. The error screen is replaced by the post list. |
| M11 | With a loaded list, kill the network. Scroll to the bottom to trigger a load-more request. | A Retry button appears at the bottom of the list (not a full-screen error). The existing posts remain visible. |
| M12 | Tap the load-more Retry button from M11 after restoring the network. | The next page of posts appends to the list normally. |
| M13 | Connect to a backend with zero posts. Open the Posts tab. | The empty-state message "No posts yet" (or equivalent locale string) is displayed. No list or spinner is shown. |
| M14 | Tap "Open" on any post card. | The post detail screen opens within the Posts tab. The correct post is displayed. The back button returns to the Posts list. |
| M15 | Log out. Navigate to the Posts tab. Verify the FAB area. | No floating action button is visible. |
| M16 | Log in. Navigate to the Posts tab. Verify the FAB area. | A floating action button (+ icon) is visible with the tooltip "New post". |
| M17 | Tap the FAB while logged in. | The create-post screen opens. The username field (or URL path) is pre-populated with the logged-in user's own username. |
| M18 | While viewing the Posts tab with a loaded list, navigate to the detail screen of one post and delete that post. Return to the Posts tab. | The deleted post no longer appears in the list. No manual refresh was performed. |
| M19 | Switch to a different tab and back to the Posts tab while the list is already loaded. | The previously loaded list is shown immediately. No redundant network request is made. |

## Code review

- [ ] `lib/features/posts/_shared/data/dto/paginated_posts_dto.dart` exists and contains `PaginatedPostsDto`.
- [ ] `lib/features/posts/_shared/domain/entities/paginated_posts.dart` exists and contains `PaginatedPosts`.
- [ ] `user_posts/data/dto/paginated_posts_dto.dart` does **not** exist (deleted after migration).
- [ ] `user_posts/domain/entities/paginated_posts.dart` does **not** exist (deleted after migration).
- [ ] `PostsApiClient` imports `PaginatedPostsDto` from `_shared/data/dto/`, not from any `user_posts/` path.
- [ ] `PostsApiClient` contains a `getPosts({required int page, required int perPage})` method annotated `@GET('/posts')`.
- [ ] `ListPostsAdapter` is annotated `@LazySingleton(as: ListPostsPort)`.
- [ ] `ListPostsAdapter` has an inner `on DioException catch` block and an outer `on Object catch (e, st)` block that calls `_logger.error(...)`.
- [ ] `ListPostsState` is declared `@freezed sealed class` with variants `initial`, `loading`, `loaded`, `error`.
- [ ] `LoadMoreStatus` enum is defined inside `list_posts_state.dart`; no import of `LoadMoreStatus` from `user_posts_state.dart` exists anywhere in `list_posts/`.
- [ ] `ListPostsCubit` constructor calls `_eventBus.stream.listen(_onPostEvent)` and stores the subscription.
- [ ] `ListPostsCubit.close()` calls `unawaited(_sub.cancel())` before `super.close()`.
- [ ] `ListPostsCubit.load()`, `refresh()`, and `loadMore()` have no `username` parameter.
- [ ] `ListPostsRoute.build` wraps `ListPostsScreen` in `BlocProvider(create: (_) => getIt<ListPostsCubit>())`.
- [ ] No `setState` call exists in any file under `list_posts/presentation/`.
- [ ] No `import` statement in any `list_posts/` file references a path inside `user_posts/`, `create_post/`, `edit_post/`, `post_details/`, or any other sibling slice.
- [ ] `ListPostTile` is located in `list_posts/presentation/widgets/list_post_tile.dart` and is not re-exported from `user_posts/`.
- [ ] A `_stripMarkdown` function is defined locally within `list_posts/presentation/widgets/`; it is not imported from `user_posts/`.
- [ ] `list_posts/domain/ports/list_posts_port.dart` and `list_posts/domain/usecases/list_posts_usecase.dart` contain no `import 'package:flutter/` or `import 'package:dio/` statements.
- [ ] `hasMore` in `PaginatedPosts` is computed as `page * itemsPerPage < totalCount`.
- [ ] The `ListPostsRoute` entry in `app_router.dart` has no `guards` list.
- [ ] No string literals appear in widget `build` methods under `list_posts/presentation/`; all user-facing strings use `context.t.posts.listPosts.*` or `context.t.common.*`.
- [ ] `pubspec.yaml` is unchanged (no new dependencies added).
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
