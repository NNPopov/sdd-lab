# 0039 · adapt_moderation_log_contract — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | When the backend returns a moderation log entry that omits `actor_user_id`, the system deserializes the entry without throwing an exception. |
| F2 | When the backend returns a moderation log entry that omits `actor_username`, the system deserializes the entry without throwing an exception. |
| F3 | The Pending Posts screen displays the full list of posts returned by the API even when one or more posts have a non-empty `moderation_log` whose entries lack actor fields. |
| F4 | The moderation log list view (Moderate Post screen) renders without error when a log entry's `actorUsername` is null. |
| F5 | The moderation log panel (Edit Post screen) renders without error when a log entry's `actorUsername` is null. |
| F6 | When `actorUsername` is null, the UI renders an empty string in its place. |
| F7 | When `actor_user_id` and `actor_username` are present in the JSON, the system maps them correctly onto the `ModerationLogEntry` entity fields. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | `ModerationLogEntryDto.actorUserId` is declared as `int?` and `ModerationLogEntryDto.actorUsername` as `String?`; neither is a required constructor parameter. |
| N2 | `ModerationLogEntry.actorUserId` is declared as `final int?` and `ModerationLogEntry.actorUsername` as `final String?`; neither is a required constructor parameter. |
| N3 | The freezed/json_serializable generated files for `ModerationLogEntryDto` are regenerated via `build_runner` after the DTO change; they are not hand-edited. |
| N4 | No new feature slice folder is created under `lib/features/posts/` for this fix; all changes land in `_shared/` and in two existing presentation widgets. |
| N5 | The null fallback (`?? ''`) for `actorUsername` is applied only at the widget render call-site, not inside the adapter or the domain entity. |
| N6 | The adapter passes `logDto.actorUserId` and `logDto.actorUsername` through to `ModerationLogEntry` unchanged; no conversion or fallback is added in the adapter. |
| N7 | No DI registration, cubit, use-case, port, route, or API client file is modified by this slice. |
| N8 | `ModerationLogEntry` is a plain Dart class (not freezed); no codegen is needed for the entity file after the nullability change. |
| N9 | The `PendingPostsAdapter` retains its existing double-catch structure: an inner `on DioException` catch and an outer `catch (e, st)` that calls `logger.error`. |
| N10 | `dart analyze` produces no warnings after the change (the project uses `very_good_analysis`). |

## Out of scope

- Displaying actor identity (user ID or username) as a named, styled UI element if the backend begins sending it in the future.
- Changes to any DTO, entity, or API endpoint other than `ModerationLogEntryDto` and `ModerationLogEntry`.
- Navigation or routing changes.
- Any change to how moderation log entries without actor fields are produced or stored on the backend.
