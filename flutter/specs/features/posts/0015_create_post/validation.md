# 0015 · create_post — Validation Checklist

## Manual Testing

| # | Step | Expected result |
|---|---|---|
| M1 | Open `/user/myusername/posts/create` while unauthenticated | Redirect to `/login` |
| M2 | Open `/user/myusername/posts/create` while authenticated | The post creation form opens |
| M3 | Tap Publish with empty fields | Validation errors below Title and Text; request not sent |
| M4 | Enter a Title of 1 character, tap Publish | Error below Title: "Title must be at least 2 characters" |
| M5 | Enter a Title of 31 characters, tap Publish | Error below Title: "Title must be at most 30 characters" |
| M6 | Enter a Title of 2–30 characters — no error displayed | The field passes validation |
| M7 | Enter a space in the Media URL field, tap Publish | Error below Media URL: field cannot be empty |
| M8 | Leave Media URL empty, tap Publish | No error below Media URL; the field is ignored |
| M9 | Enter Text shorter than 100 characters, tap Publish | Error below Text: "Text must be at least 100 characters" |
| M10 | Enter Text longer than 63206 characters, tap Publish | Error below Text: "Text must be at most 63206 characters" |
| M11 | Enter text in the Text field | Live Markdown preview updates in real time below the field |
| M12 | Enter `**bold**` in the Text field | Preview shows bold text |
| M13 | Fill in all fields correctly, tap Publish | Button is disabled, loading indicator is shown |
| M14 | Successful publishing | Redirect to `/user/:username/posts`; the post appears at the top of the list |
| M15 | Tap Publish again during loading | Button is disabled, a duplicate request is not sent |
| M16 | Server returned an error (e.g. network error) | Inline error message without a dialog; button is re-enabled |
| M17 | After an error, tap Publish again with the same data | The request is retried |
| M18 | Scroll the screen down | Preview and the Publish button are visible; the form and preview are in a single scrollable stream |
| M19 | Attempt to open `/user/otheruser/posts/create` while authenticated as `myuser` | The form opens, tapping Publish shows the error "You can only publish posts as yourself" |

## Code Review

- [ ] No hardcoded strings in the UI — all via `context.t.posts.createPost.*`
- [ ] `CreatePostRoute` is registered in `app_router.dart` with the path `/user/:username/posts/create` and `authGuard`
- [ ] `Post` entity moved to `_shared/domain/entities/post.dart` + `mediaUrl?` and `createdByUserId` added
- [ ] `PostDto` moved to `_shared/data/dto/post_dto.dart` + `media_url` and `created_by_user_id` added
- [ ] `CreatePostRequestDto` created in `_shared/data/dto/`
- [ ] Imports in `user_posts/` updated to the new paths from `_shared/`; `user_posts` compiles
- [ ] `PostsApiClient` contains the `createPost(username, body)` method
- [ ] `create_post_adapter.dart` contains the double catch (inner DioException + outer catch-all with logging)
- [ ] `CreatePostUseCase` checks ownership and returns `Left(ForbiddenFailure)` without calling the port on mismatch
- [ ] Live preview is managed by `TextEditingController`, no preview state in Cubit
- [ ] Form validation is via `validator:` in `TextFormField`, not in Cubit
- [ ] `flutter_markdown` is added to `pubspec.yaml` and used only in the `MarkdownPreview` widget
- [ ] `PaginatedPosts` and `PaginatedPostsDto` remain in `user_posts/` (not moved to `_shared/`)
- [ ] The `list_posts` slice is not modified
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no errors
- [ ] All tests green (use-case: 4 cases, adapter: 6 cases, cubit: 2 cases)
