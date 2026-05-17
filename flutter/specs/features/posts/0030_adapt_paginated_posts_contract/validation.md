# 0030 · adapt_paginated_posts_contract — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Navigate to a user's posts page (e.g. `/user/alice/posts`) while the server returns the new contract shape. | Post list loads and all posts are visible; no empty list or crash. |
| M2 | On a user with more than one page of posts, scroll slowly to the bottom of the first page. | A loading spinner appears at the bottom and the next page of posts is appended. |
| M3 | Continue scrolling past the last page (where no more posts exist on the server). | No additional spinner appears and no further network call is made. |
| M4 | With a user whose post count is exactly one page size (e.g. 10 posts, `items_per_page = 10`), scroll to the bottom. | No spinner appears after the list renders; the screen does not attempt to load a second page. |
| M5 | On a loaded user posts screen, pull down to refresh. | A refresh spinner appears and the list reloads from page 1; previously appended pages are replaced, not stacked. |
| M6 | After reaching the last page via infinite scroll, pull down to refresh. | List reloads from page 1 and scrolling to the bottom again stops at the last page without a spinner. |
| M7 | Disable the network, navigate to a user's posts page, and wait for the error state. | An error message and a Retry button are shown; the app does not crash. |
| M8 | On the error screen from M7, re-enable the network and tap Retry. | The posts list loads successfully. |
| M9 | From the user posts screen, tap a post to open post details. | Post details load correctly (verifying `getPost` is unaffected by the DTO change). |
| M10 | From post details, tap Edit (as the post owner) and save a change. | Edit completes successfully and the updated post is reflected (verifying `patchPost` is unaffected). |
| M11 | Tap the FAB on the user posts screen (as the owner) and create a new post. | Post is created; returning to the list and refreshing shows the new post (verifying `createPost` is unaffected). |

## Code review

- [ ] `PostItemDto` is a `@freezed sealed class`; `id: int` and `username: String` are `required`; `title`, `text`, `mediaUrl`, `createdAt`, `createdByUserId` are either nullable or carry a `@Default` value (N1).
- [ ] `PaginatedPostsDto` declares `items`, `totalCount`, `page`, and `itemsPerPage` all as `required`; none of these envelope fields has `@Default` (N2).
- [ ] `PaginatedPosts` exposes `bool get hasMore => page * itemsPerPage < totalCount` as a getter; its constructor has no `hasMore` parameter (N3).
- [ ] `UserPostsAdapter` constructs `PaginatedPosts(items: …, totalCount: dto.totalCount, page: dto.page, itemsPerPage: dto.itemsPerPage)` — no `hasMore:` argument (N4).
- [ ] `UserPostsAdapter` contains both an inner `on DioException catch` block and an outer `catch (e, st)` that calls `_logger.error(…, error: e, stackTrace: st)` and returns `Left(const Failure.unknown())` (N5).
- [ ] `lib/features/posts/_shared/data/dto/post_dto.dart` is unchanged (diff shows no modifications) (N6).
- [ ] `PostItemDto` does not import or extend `PostDto` (N6).
- [ ] `Post.username` is declared as `String? username` in an optional named parameter position; existing `Post(…)` call sites that omit `username` compile without modification (N7).
- [ ] `user_posts_cubit.dart`, `user_posts_state.dart`, `user_posts_usecase.dart`, and `user_posts_port.dart` are unchanged (diff shows no modifications) (N8).
- [ ] No file under `lib/features/posts/user_posts/presentation/` is modified (N9).
- [ ] No file under any other post slice (`list_posts`, `create_post`, `post_details`, `edit_post`, `delete_post`, `erase_db_post`) is modified (N10).
- [ ] `paginated_posts_dto.freezed.dart`, `paginated_posts_dto.g.dart`, `post_item_dto.freezed.dart`, and `post_item_dto.g.dart` are all present and up-to-date (N11).
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
