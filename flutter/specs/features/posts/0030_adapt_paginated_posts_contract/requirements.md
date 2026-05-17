# 0030 · adapt_paginated_posts_contract — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The user posts list loads and displays correctly when the backend returns the new contract shape (`items`, `total_count`, `page`, `items_per_page`). |
| F2 | Infinite scroll triggers a new page load when the server indicates more posts are available. |
| F3 | Infinite scroll does not trigger a new page load when all posts have been loaded. |
| F4 | Whether more posts are available is determined by `page × items_per_page < total_count`; a page where `page × items_per_page == total_count` is treated as the last page. |
| F5 | Pull-to-refresh reloads posts from page 1 and displays the refreshed list. |
| F6 | The load-more indicator disappears once the last page is reached. |
| F7 | A `PostItemDto` type is available in the shared posts DTO folder for use by future list-oriented slices. |
| F8 | Single-post endpoints (`createPost`, `getPost`, `editPost`) continue to function correctly and are unaffected by this change. |
| F9 | The `Post` domain entity includes an optional `username` field populated from the per-item server response. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | `PostItemDto` is a `@freezed sealed class`; `id: int` and `username: String` are `required`; all remaining fields are nullable or carry a `@Default` value, per the soft-contract rule in `agent_docs/error_handling.md`. |
| N2 | `PaginatedPostsDto` declares all four envelope fields (`items`, `total_count`, `page`, `items_per_page`) as `required` with no `@Default` fallbacks; a response missing any envelope field must fail deserialization. |
| N3 | `PaginatedPosts` exposes `hasMore` as a computed getter (`bool get hasMore => page * itemsPerPage < totalCount`) and does not accept `hasMore` as a constructor parameter. |
| N4 | `UserPostsAdapter` constructs `PaginatedPosts` with `totalCount`, `page`, and `itemsPerPage` from the DTO; it does not pass `hasMore` to the constructor. |
| N5 | `UserPostsAdapter` retains the mandatory double-catch: inner `on DioException` maps to a typed `Failure`; outer `catch (e, st)` calls `AppLogger.error` with the stack trace and returns `Left(Failure.unknown())`. |
| N6 | `PostDto` is not modified; `PostItemDto` is an independent `@freezed sealed class` and does not extend or import `PostDto`. |
| N7 | `Post.username` is declared as an optional nullable named parameter (`String? username`) so all existing call sites that construct `Post` without it continue to compile unchanged. |
| N8 | `UserPostsCubit`, `UserPostsState`, `UserPostsUseCase`, and `UserPostsPort` are not modified. |
| N9 | No presentation file (screen, route, or widget) is modified. |
| N10 | No slice other than `user_posts` (and `_shared/`) under `lib/features/posts/` is modified. |
| N11 | Generated files (`*.freezed.dart`, `*.g.dart`) are regenerated via `dart run build_runner build --delete-conflicting-outputs` after any DTO edit. |
| N12 | `dart analyze` produces no warnings after all changes. |
| N13 | All tests in `test/features/posts/user_posts/` pass after the update. |

## Out of scope

- Any change to the presentation layer or user-visible behaviour.
- Displaying `username` on `PostTile` or any other widget.
- Adapting `list_posts` or any other post slice to a new contract.
- Modifying `PostDto` or any single-post endpoint adapter.
- Adding or removing pagination parameters from `UserPostsPort`.
