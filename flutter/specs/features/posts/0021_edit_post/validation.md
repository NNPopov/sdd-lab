# 0021 · edit_post — Validation Checklist

## Manual Testing

| # | Step | Expected result |
|---|---|---|
| M1 | Open the details of another user's post | No Edit button in the AppBar |
| M2 | Open the details of your own post while unauthenticated | No Edit button |
| M3 | Open the details of your own post while authenticated | The Edit button (pencil) is visible in the AppBar |
| M4 | Tap Edit | The edit form opens with pre-filled title, text, mediaUrl fields |
| M5 | Check the fields when the form opens | Title, Text contain current values; Media URL contains the current URL or is empty |
| M6 | Tap Save with empty required fields | Validation errors below Title and Text; request not sent |
| M7 | Enter a Title of 1 character, tap Save | Error below Title: "Title must be at least 2 characters" |
| M8 | Enter a Title of 31 characters, tap Save | Error below Title: "Title must be at most 30 characters" |
| M9 | Enter a space in the Media URL field, tap Save | Error below Media URL: field cannot be empty |
| M10 | Clear the Media URL field, tap Save | No error below Media URL; the field is sent as null |
| M11 | Enter Text shorter than 100 characters, tap Save | Error below Text: "Text must be at least 100 characters" |
| M12 | Change the text in the Text field | Live Markdown preview updates in real time |
| M13 | Fill in all fields correctly, tap Save | Button is disabled, loading indicator is shown |
| M14 | Successful save | Return to PostDetailsScreen; post content is updated |
| M15 | Tap Save again during loading | Button is disabled, a duplicate request is not sent |
| M16 | Server returned an error | Inline error message without a dialog; button is re-enabled |
| M17 | After an error, change the data and tap Save again | The request is retried with new data |
| M18 | Tap Back without saving | Return to PostDetailsScreen without changes; post is not updated |
| M19 | Scroll the edit screen down | Preview and the Save button are visible in a single scrollable stream |

## Code Review

- [ ] No hardcoded strings in the UI — all via `context.t.posts.editPost.*`
- [ ] `MarkdownPreview` is moved to `posts/_shared/presentation/widgets/markdown_preview.dart`
- [ ] `MarkdownPreview` accepts a `label` parameter instead of a hardcoded key
- [ ] The `MarkdownPreview` import in `create_post_screen.dart` is updated; `create_post` compiles
- [ ] The old file `create_post/presentation/widgets/markdown_preview.dart` is deleted
- [ ] `UpdatePostRequestDto` is created in `_shared/data/dto/` with `@JsonKey(name: 'media_url')` for mediaUrl
- [ ] `PostsApiClient` contains the `patchPost(username, id, body)` method with `@PATCH`
- [ ] `edit_post_adapter.dart` contains the double catch (inner DioException + outer catch-all with logging)
- [ ] `EditPostUseCase` returns `Left(ForbiddenFailure)` without calling the port when `currentUser == null`
- [ ] `EditPostUseCase` returns `Left(ForbiddenFailure)` without calling the port on username mismatch
- [ ] `PostDetailsScreen` is converted to `StatefulWidget`; load functionality is not changed
- [ ] The Edit button is hidden while `PostDetailsState` is not `PostDetailsLoaded`
- [ ] The Edit button is hidden for unauthenticated users
- [ ] The Edit button is hidden when viewing another user's post
- [ ] After pushing `EditPostRoute` and returning, `PostDetailsCubit.load(username, id)` is called
- [ ] `EditPostRoute` is registered in `app_router.dart` with `authGuard` and path `/user/:username/posts/:id/edit`
- [ ] `username` is passed to `EditPostRoute` as a named Dart parameter, not via `@PathParam`
- [ ] Live preview is managed by `TextEditingController`, no preview state in Cubit
- [ ] Form validation is via `validator:` in `TextFormField`, not in Cubit
- [ ] `list_posts`, `user_posts` slices are not modified
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no errors
- [ ] All tests green (use-case: 4 cases, adapter: 7 cases, cubit: 2 cases)
