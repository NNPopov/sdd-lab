# 0014 · user_posts — Validation Checklist

## Manual Testing

| # | Step | Expected result |
|---|---|---|
| M1 | Open `/user/testuser/posts` while unauthenticated | The page opens, the list of posts loads |
| M2 | Open `/user/testuser/posts` while authenticated | The page opens, the list of posts loads |
| M3 | Scroll to the end of the list (if `has_more=true`) | The next page is automatically loaded |
| M4 | Pull-to-refresh | The list reloads from page 1 |
| M5 | User with no posts | "No posts yet" is shown |
| M6 | Open `/user/nonexistent/posts` | An error is shown + a Retry button |
| M7 | Tap on a post card | Nothing happens |
| M8 | Post text with Markdown (`**bold**`, `# Header`, `[link](url)`) | The preview shows plain text without syntax |
| M9 | Post text longer than 100 characters | The preview is truncated to 100 characters + "..." |
| M10 | Post text shorter than 100 characters | The preview is shown in full without "..." |
| M11 | Tap Retry after an error | The list reloads |

## Code Review

- [ ] No hardcoded strings in the UI — all through `context.t.posts.userPosts.*`
- [ ] `UserPostsRoute` is registered in `app_router.dart` with the path `/user/:username/posts` and no guards
- [ ] The `Post` entity is located in `user_posts/domain/entities/`, not in `_shared/`
- [ ] `PostsApiClient` is registered in `posts_feature_module.dart`
- [ ] `user_posts_adapter.dart` contains the double catch (inner DioException + outer catch-all)
- [ ] `_stripMarkdown` is a private function, only in `post_tile.dart`, with no new dependencies
- [ ] `flutter_markdown` is not added to `pubspec.yaml`
- [ ] The `list_posts` slice is not modified
- [ ] `UserPostsState` uses `sealed class` + `freezed` + `LoadMoreStatus` enum
- [ ] `username` is not stored in Cubit fields, it is passed as a parameter to each method
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no errors
- [ ] All tests green
