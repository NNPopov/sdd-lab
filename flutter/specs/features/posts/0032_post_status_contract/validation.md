# 0032 · post_status_contract — Validation Checklist

## Manual testing

> This slice has no UI. All three scenarios validate that the existing post-loading
> screens continue working after the data contract change (no crash, no regression).

| # | Step | Expected result |
|---|---|---|
| M1 | Launch the app, navigate to the Posts tab, scroll through the list. | Post list loads without errors or crashes; existing post fields (title, text, author) display normally. |
| M2 | From the Users tab, open any user profile and tap "Posts". | User post list loads without errors or crashes. |
| M3 | Tap any post in any list to open the post-details screen. | Post details load without errors or crashes. |
| M4 | With a backend that returns `"status": "approved"` for a post, open any list or detail view. | App loads the post without error; no exception logged. |
| M5 | With a backend that returns `"status": "pending_review"` for a post, open any view. | App loads the post without error. |
| M6 | With a backend that returns `"status": "changes_requested"` for a post, open any view. | App loads the post without error. |
| M7 | With a backend that returns an unrecognised status string (e.g. `"status": "archived"`), open a post list or detail view. | App does not crash; the post is shown; a warning (not error) is emitted to the app logger. |

## Code review

- [ ] `lib/features/posts/_shared/domain/entities/post_status.dart` exists with exactly three enum values: `pendingReview`, `approved`, `changesRequested`.
- [ ] `post_status.dart` has no imports — it is a plain Dart enum.
- [ ] `Post` class has a required `postUuid: String` field and a required `status: PostStatus` field (both non-nullable).
- [ ] `PostDto` contains `@JsonKey(name: 'post_uuid') required String postUuid` and `required String status` (String, not enum) inside the freezed factory.
- [ ] `PostItemDto` contains the same two new fields as `PostDto`.
- [ ] `GetPostAdapter`: `Post(...)` constructor call includes `postUuid: dto.postUuid` and `status: _parseStatus(dto.status)`.
- [ ] `UserPostsAdapter`: every `Post(...)` constructor call in the `.map()` includes `postUuid: p.postUuid` and `status: _parseStatus(p.status)`.
- [ ] `ListPostsAdapter`: same as `UserPostsAdapter`.
- [ ] Each of the three updated adapters has a `_parseStatus` helper (or equivalent inline switch) that maps `'approved'` → `PostStatus.approved`, `'changes_requested'` → `PostStatus.changesRequested`, and all other strings → `PostStatus.pendingReview`.
- [ ] The unknown-status path calls `_logger.warning(...)`, **not** `_logger.error(...)`.
- [ ] Each adapter still contains both the inner `on DioException catch` block and the outer `on Object catch (e, st)` block that calls `_logger.error(...)` and returns `const Left(Failure.unknown())`.
- [ ] `PostsApiClient` is unchanged — no new endpoints, no changed return types.
- [ ] No adapters other than `GetPostAdapter`, `UserPostsAdapter`, and `ListPostsAdapter` are touched.
- [ ] No cubit, usecase, port, screen, route, or localization file is modified.
- [ ] No new `lib/features/posts/0032_post_status_contract/` folder exists.
- [ ] `test/features/posts/post_details/data/get_post_adapter_test.dart` covers all three valid status values, the unknown-status fallback with `logger.warning` verification, and `postUuid` round-trip.
- [ ] `test/features/posts/user_posts/data/user_posts_adapter_test.dart` covers the same five cases for `PostItemDto` mapping.
- [ ] `test/features/posts/list_posts/data/list_posts_adapter_test.dart` covers the same five cases for `PostItemDto` mapping.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
