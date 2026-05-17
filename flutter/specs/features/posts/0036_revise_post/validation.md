# 0036 · revise_post — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Open the edit screen for a `changesRequested` post on a device with screen width ≥ 600 dp. | The moderation log panel and the post editor are displayed side-by-side, separated by a vertical divider; both panes load without switching tabs. |
| M2 | Open the edit screen for a `changesRequested` post on a device with screen width < 600 dp. | Two tabs are visible — "Edit" and "Log"; the "Edit" tab is selected and the log panel is not yet shown. |
| M3 | On the narrow layout, tap the "Log" tab. | The log panel appears and begins loading; a loading indicator is shown while the request is in flight. |
| M4 | On the narrow layout, switch from "Log" back to "Edit" and then to "Log" again. | No second network request is fired; the previously loaded log is shown immediately. |
| M5 | Open the edit screen for a `changesRequested` post. | A "Revision message" text field is visible below the content fields. |
| M6 | Open the edit screen for a `pendingReview` post. | No revision message field is shown. |
| M7 | Open the edit screen for an `approved` post. | No revision message field is shown. |
| M8 | With a `changesRequested` post, leave the revision message field empty and tap Save. | The form shows a validation error on the message field; no network request is made. |
| M9 | With a `changesRequested` post, type only whitespace in the revision message field and tap Save. | The form shows a validation error (whitespace is trimmed to empty); no network request is made. |
| M10 | With a `changesRequested` post, fill in the message field with a valid message and tap Save. | A loading indicator appears; on success the screen navigates back to `post_details`. |
| M11 | With a `pendingReview` post, edit the title and tap Save (no message field visible). | A loading indicator appears; on success the screen navigates back; the standard edit endpoint was called (verify in network log). |
| M12 | Open the edit screen for an `approved` post. | The Save button is visually disabled (greyed out, no press effect). |
| M13 | Open the edit screen for an `approved` post and inspect the area below the Save button. | A helper text is displayed explaining the post is approved and cannot be edited. |
| M14 | Open the edit screen for an `approved` post and tap the Save button area. | Nothing happens; the button does not respond to taps. |
| M15 | Open the edit screen for an `approved` post and switch to the "Log" tab (narrow) or inspect the log pane (wide). | The moderation log loads and is visible. |
| M16 | Submit a valid revision; observe the UI while the request is in flight. | The Save button shows a loading indicator and all form fields are disabled. |
| M17 | After a successful revision submission, observe the Pending Posts tab. | The revised post reappears in the pending queue with `pending_review` status. |
| M18 | Configure the server to return 403 on `PATCH /posts/{uuid}/revise`; submit a revision. | An error message telling the author they don't have permission is shown; the screen does not navigate away. |
| M19 | Configure the server to return 404; submit a revision. | A "post not found" error message is shown. |
| M20 | Configure the server to return 409 (post is no longer in `changes_requested`); submit a revision. | An error message tells the author to return to post details and check the current status. |
| M21 | Cut the device's network connection; submit a revision. | A generic error message is shown; the screen remains on the edit screen. |
| M22 | Open the Log tab (or pane) for a post that has moderation events. | Each entry shows event type label, actor username, timestamp, action label, and message text. |
| M23 | Open the Log tab (or pane) for a post that has no moderation events yet. | An empty-state message is displayed instead of an error or blank screen. |
| M24 | On narrow layout, switch to the Log tab before the log has loaded. | A loading indicator is displayed. |

## Code review

- [ ] No hardcoded strings in any `edit_post/` widget — all UI text via `context.t.posts.editPost.*` slang keys.
- [ ] `RevisePostAdapter` contains an inner `on DioException catch` block (HTTP error mapping) and an outer `on Object catch` block that calls `_logger.error(...)` and returns `Failure.unknown()`.
- [ ] No file inside `edit_post/` imports from `moderate_post/` or any other sibling slice; only `_shared/` imports are present.
- [ ] `IModerationLogPort`, `ModerationLogCubit`, `ModerationLogState`, `ModerationLogAdapter`, and `ModerationLogResponseDto` reside under `posts/_shared/`, not under `moderate_post/`.
- [ ] All `moderate_post/` Dart files compile correctly after import-path updates; no logic, state, or presentation code inside `moderate_post/` was altered.
- [ ] The endpoint-routing branch (`changesRequested` → revise port, other → edit port) is in `EditPostUseCase.call()`; `EditPostCubit.submit()` and `EditPostScreen` contain no such branch.
- [ ] `IRevisePostPort` declares exactly one abstract method: `Future<Either<Failure, void>> call(UpdatedPostData data)`.
- [ ] `UpdatedPostData` has exactly three new fields compared to the pre-slice version: `postUuid: String`, `status: PostStatus`, `revisionMessage: String?`; no other fields changed.
- [ ] `EditPostCubit.submit()` method signature is unchanged; `EditPostState` sealed class has no new variants.
- [ ] `EditPostUseCase.call()` returns `Left(ValidationFailure)` without calling any port when `status == changesRequested` and `revisionMessage` trims to empty.
- [ ] `RevisePostAdapter` class annotation is `@LazySingleton(as: IRevisePostPort)`.
- [ ] `ModerationLogCubit.load()` guards repeated calls with a `_loaded` boolean; a second `load()` call while `_loaded == true` is a no-op.
- [ ] `PostEventBus.publish(PostRevisedEvent(...))` is called inside a `BlocListener` on `EditPostSuccess` in the screen widget; the cubit does not reference `PostEventBus`.
- [ ] All files under `edit_post/domain/` import only `dartz`, `freezed_annotation`, `PostStatus`, and other pure-Dart entities; no `flutter/*` or `dio/*` imports.
- [ ] `EditPostState` remains a `@freezed` sealed class; no new state variants were added.
- [ ] `ModerationLogPanel` widget file is under `edit_post/presentation/widgets/`; it contains no import from `moderate_post/presentation/`.
- [ ] `EditPostUseCase.call()` contains no branch that blocks or short-circuits an `approved` post; the disabled button is enforced exclusively in the presentation layer (`onPressed == null`).
- [ ] `RevisePostRequestDto` is annotated `@freezed` (sealed class) and has a `fromJson` factory generated by `json_serializable`.
- [ ] `PendingPostsCubit._onPostEvent` handles `PostRevisedEvent` by calling `refresh()`; verify via grep or diff.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
