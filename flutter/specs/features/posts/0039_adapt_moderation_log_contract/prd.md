# PRD: adapt_moderation_log_contract (0039)

## Problem Statement

The backend's `/posts/pending` response includes a `moderation_log` array on each post
item. When any entry in that array is present, the Flutter client crashes during JSON
deserialization because `ModerationLogEntryDto` declares `actor_user_id` and
`actor_username` as required non-nullable fields — but the backend never sends them.

The crash propagates silently: the outer adapter catch block converts the exception into
`Failure.unknown()`, the cubit emits an error state, and the Pending Posts screen shows
an error message instead of the post list. A moderator navigating to the Pending tab
therefore sees nothing when at least one post has a non-empty moderation history. The
same deserialization failure exists on any other screen that fetches moderation log
entries (the moderation log panel on the Edit Post screen and the moderation log list on
the Moderate Post screen).

## Solution

Align the `ModerationLogEntryDto` and the `ModerationLogEntry` domain entity with the
actual API contract by making `actorUserId` and `actorUsername` optional (nullable).
Update every widget that renders `actorUsername` to handle the null case gracefully so
the UI degrades cleanly rather than throwing a null-assertion error.

## User Stories

1. As a moderator, I want the Pending Posts screen to display all posts with a
   `pending_review` status, so that I can review and act on them.
2. As a moderator, I want the Pending Posts screen to display all posts with a
   `changes_requested` status, so that I can track posts that are awaiting author
   revision.
3. As a moderator, I want to open a post that already has moderation log entries without
   seeing an error, so that I can review its moderation history before taking action.
4. As a moderator, I want to see moderation log entries in the Moderate Post screen, so
   that I can understand the full review history of a post.
5. As an author, I want to see the moderation log panel on the Edit Post screen without
   encountering an error, so that I can read the feedback left by the moderator.
6. As a developer, I want `ModerationLogEntryDto` to tolerate absent `actor_user_id` and
   `actor_username` JSON fields, so that the adapter does not throw on any valid backend
   response.
7. As a developer, I want `ModerationLogEntry` to reflect the actual API contract with
   nullable actor fields, so that the domain layer is an honest model of what the backend
   provides.
8. As a developer, I want widgets that display `actorUsername` to fall back to a safe
   empty-string value when the field is null, so that the UI never throws a
   null-assertion error.
9. As a developer, I want the existing `PendingPostsAdapter` unit tests to cover a
   response payload containing moderation log entries without actor fields, so that this
   regression cannot be re-introduced silently.
10. As a developer, I want the existing moderation log widget tests to cover the null
    actor case, so that the null-safe rendering path is verified.

## Implementation Decisions

### ModerationLogEntryDto changes

`actor_user_id` and `actor_username` change from required non-nullable to optional
nullable fields in the DTO. Deserialization of a JSON object that omits either key now
succeeds and produces `null` for the missing field.

The `freezed`/`json_serializable` generated files must be regenerated after the change.

### ModerationLogEntry entity changes

`actorUserId` and `actorUsername` change from `int` / `String` to `int?` / `String?` in
the domain entity. No other entity fields change. The entity constructor parameters
become optional (no default value needed — `null` is the natural default).

### Widget null-safety fixes

Two widgets read `entry.actorUsername` and pass it directly to a `Text` widget, which
requires a non-nullable `String`. Both must be updated to coalesce null to `''` (or an
equivalent safe value).

No other presentation-layer files require changes.

### No adapter logic changes

The `PendingPostsAdapter` already passes `logDto.actorUserId` and `logDto.actorUsername`
through to `ModerationLogEntry`. Once both types are nullable, the pass-through compiles
without modification.

### No use-case or cubit changes

The nullable actor fields are purely carried data — no use-case branches on them. Cubits
and states are unchanged.

### No API client changes

The Retrofit `PostsApiClient` return types are unchanged. No new endpoints are involved.

## Testing Decisions

Good tests for this slice verify observable adapter output and widget rendering — not
internal DTO structure.

Modules to test:

- **PendingPostsAdapter** — add a test case where the response contains a post with a
  non-empty `moderation_log` whose entries omit `actor_user_id` and `actor_username`.
  The adapter must return `Right(...)` with correctly mapped items (not `Left(...)`).
  Add a complementary case where both actor fields are present to confirm they still map
  correctly. Prior art: existing adapter tests in
  `test/features/posts/0034_pending_posts/data/`.
- **Moderation log widgets** — add widget test cases for null `actorUsername` in both
  the moderation log panel (edit_post) and the moderation log list view (moderate_post).
  The widget must render without throwing. Prior art: existing widget tests in
  `test/features/posts/0035_moderate_post/presentation/`.

## Out of Scope

- Displaying actor identity in the UI if the backend begins returning actor fields in
  the future — that is a separate presentational slice.
- Changes to any other DTO, entity, or API endpoint.
- Navigation or routing changes.
- Any change to how `moderation_log` entries without actor fields are handled on the
  backend.

## Further Notes

- The root cause is a contract mismatch introduced when slice 0035 (`moderate_post`)
  modelled actor fields as required based on an assumption that was not validated against
  the actual backend response shape. The backend moderation log entries carry only `id`,
  `event_type`, `action`, `message`, and `created_at`.
- This fix unblocks the Pending Posts screen (slice 0034) for any moderator whose queue
  contains at least one post with a non-empty `moderation_log`. Without this fix, the
  screen shows an error state for all users in that situation.
- Because `actorUserId` and `actorUsername` are carried-through nullable values with no
  business logic branching on them, the risk of this change is low and the blast radius
  is contained to the two widget fixes and the DTO/entity nullability update.
