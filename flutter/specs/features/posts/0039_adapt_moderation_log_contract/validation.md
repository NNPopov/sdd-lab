# 0039 · adapt_moderation_log_contract — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Log in as a moderator and navigate to the Pending tab. | The post list loads and all pending posts are displayed — no error state, no permanently spinning indicator. |
| M2 | With at least one post in `changes_requested` status (which has a non-empty moderation log), navigate to the Pending tab. | That post appears in the list alongside any `pending_review` posts — the non-empty log does not block rendering. |
| M3 | On the Pending tab, pull down to refresh. | The list reloads and continues to show all posts without entering an error state. |
| M4 | On the Pending tab, tap a post that has at least one moderation log entry. Navigate to the Moderate Post screen. | The screen opens and the moderation log section renders — no exception dialog, no blank error widget. |
| M5 | In the Moderate Post screen, observe the actor username area of a moderation log tile whose entry has no actor fields. | The username area is blank (empty string) — no null-assertion crash, no "null" literal displayed. |
| M6 | As an author whose post is in `changes_requested` status, open the Edit Post screen. | The moderation log panel renders and shows the log entries — no exception, no blank screen. |
| M7 | In the Edit Post screen moderation log panel, observe the actor username area of an entry that has no actor fields. | The username area is blank — same safe rendering as M5. |
| M8 | Navigate to the Pending tab when there are no posts at all. | The empty-state message is shown (not an error-state message). |
| M9 | Trigger a network error (e.g. kill the backend) and navigate to the Pending tab. | The error state is shown with a retry button; the fix does not interfere with the existing error path. |
| M10 | Press the retry button after the network is restored. | The list loads successfully. |

## Code review

- [ ] `ModerationLogEntryDto.actorUserId` is declared as `int?` (not `required int`)
- [ ] `ModerationLogEntryDto.actorUsername` is declared as `String?` (not `required String`)
- [ ] `ModerationLogEntry.actorUserId` field type is `final int?`
- [ ] `ModerationLogEntry.actorUsername` field type is `final String?`
- [ ] Both `actorUserId` and `actorUsername` constructor parameters in `ModerationLogEntry` are optional (no `required` keyword)
- [ ] `moderation_log_entry_dto.freezed.dart` and `moderation_log_entry_dto.g.dart` are updated via codegen, not hand-edited
- [ ] No new `lib/features/posts/0039_*/` folder exists — the diff contains only changes in `_shared/` and two presentation widgets
- [ ] `?? ''` null-coalescing for `actorUsername` appears only in `moderation_log_panel.dart` and `moderation_log_list_view.dart` — not in the adapter or entity
- [ ] `PendingPostsAdapter` passes `logDto.actorUserId` and `logDto.actorUsername` directly to `ModerationLogEntry(...)` without any conversion or fallback
- [ ] `ModerationLogEntry` has no `@freezed` annotation — it remains a plain Dart class
- [ ] `PendingPostsAdapter.call` retains the double-catch: inner `on DioException` and outer `catch (e, st)` with `logger.error`
- [ ] No cubit, use-case, port, route, or `PostsApiClient` file appears in the diff
- [ ] New adapter test case: a response with a moderation log entry that omits actor fields returns `Right(...)` with `actorUserId == null` and `actorUsername == null`
- [ ] New adapter test case: a response with actor fields present maps them to the entity correctly
- [ ] Widget test (or equivalent): pumping a moderation log entry with `actorUsername == null` does not throw
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
