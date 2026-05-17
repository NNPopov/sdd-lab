# PRD: revise_post (0036)

## Problem Statement

When a moderator requests changes on a post, the author receives a `changes_requested`
status but has no way to act on it. The existing edit screen sends the post to the
regular PATCH endpoint, which ignores moderation context entirely — no revision message,
no state transition, no dialogue with the moderator. The author also cannot see the
moderation history while editing, so they do not know what they are expected to fix.

## Solution

Extend the `edit_post` slice so the edit screen becomes moderation-aware. The use-case
inspects the post's current `status` and routes the save action to the correct endpoint:
`PATCH /posts/{post_uuid}/revise` for `changes_requested` posts, and the existing edit
endpoint for all other statuses. The screen gains an adaptive layout that mirrors the
moderation screen: wide displays show the editor and the full moderation log
side-by-side; narrow displays use two tabs. A revision-message field appears — and is
required — when the post is in `changes_requested` status. The Save button is disabled
only for `approved` posts, which are terminal. After a successful revision the app
emits a domain event and returns to `post_details`.

## User Stories

1. As an author whose post received `changes_requested`, I want to open the edit screen
   and see the full moderation dialogue alongside the editor, so that I know exactly what
   the moderator asked me to fix.
2. As an author, I want the moderation log to load lazily (immediately on wide screens,
   on tab switch on narrow screens) so that the editor is usable from the first frame.
3. As an author on a wide screen, I want the post editor on one side and the moderation
   log on the other, so that I can reference the moderator's comments while typing.
4. As an author on a narrow screen, I want to switch between an "Edit" tab and a "Log"
   tab, so that I can read the history and then make my changes.
5. As an author with a `changes_requested` post, I want a required message field in the
   editor, so that I can explain what I changed to the moderator.
6. As an author, I want to see a validation error if I try to save a `changes_requested`
   post without writing a message, so that I cannot accidentally submit without context.
7. As an author with a `changes_requested` post, I want my save action to call the
   `/revise` endpoint, so that the post transitions back to `pending_review` and enters
   the moderation queue again.
8. As an author with a `pending_review` post, I want to be able to save edits using the
   regular edit endpoint (no message required, no revision flow), so that minor fixes
   before first review are not blocked by moderation rules.
9. As an author with an `approved` post, I want the Save button to be visually disabled
   when I open the editor, so that I know the post is finalised and cannot be changed.
10. As an author with an `approved` post, I want to still be able to open the editor and
    read the moderation log, so that I can review the approval history.
11. As an author, I want to see a loading indicator while my revision is being submitted,
    so that I know the request is in flight.
12. As an author, I want to be returned to `post_details` automatically after a
    successful revision, so that I can see the updated `pending_review` status.
13. As an author, I want to see a clear error message if the revision fails (network
    error, 409 conflict, 403 forbidden), so that I understand what went wrong.
14. As an author, I want the moderation log to show each event's type, actor, timestamp,
    action label, and message, so that I can follow the full dialogue thread.
15. As an author, I want an empty moderation log to display an empty-state message rather
    than an error, so that a freshly submitted post (with no prior events) looks correct.
16. As a moderator viewing a user's pending queue, I want the post to reappear in the
    pending list after the author revises it, so that I can pick it up for a second
    review.

## Implementation Decisions

### Scope: extension of edit_post, not a new slice

All changes live inside the existing `edit_post` slice folder. No new top-level slice
directory is created. The route, screen widget, cubit, and use-case are modified in
place; new files (port, adapter, request DTO) are added alongside the existing ones.

### UpdatedPostData extended

`UpdatedPostData` gains three new fields: `postUuid: String` (required, from
`Post.postUuid` introduced in slice A), `status: PostStatus` (required, used by the
use-case to branch), and `revisionMessage: String?` (nullable, populated only in the
`changes_requested` path).

### EditPostUseCase — smart endpoint routing

The use-case now branches on `data.status`:

- `PostStatus.changesRequested` → validates that `data.revisionMessage` is non-empty
  (returns `ValidationFailure` if not) → calls `IRevisePostPort`.
- Any other status → calls the existing `EditPostPort` as before. No message is sent.

The use-case owns the routing decision entirely; neither the cubit nor the screen
need to know which endpoint is being called.

### New port: IRevisePostPort

A narrow interface with a single method:
`revise(UpdatedPostData data) → Either<Failure, void>`.

### New adapter: RevisePostAdapter

Implements `IRevisePostPort`. Calls
`PATCH /posts/{post_uuid}/revise` with a `RevisePostRequestDto`
(`title: String?`, `text: String?`, `message: String`). Uses the standard double-catch
pattern (`DioException` → typed `Failure`; `Object` → `Failure.unknown()` with
`AppLogger`). Error mapping: 403 → `ForbiddenFailure`, 404 → `NotFoundFailure`,
409 → `ConflictFailure` (post not in `changes_requested` state), 422 →
`ValidationFailure`.

### New DTO: RevisePostRequestDto

`title: String?`, `text: String?`, `message: String`. All three sent as JSON; `title`
and `text` are nullable because the backend requires at least one of them — the client
always sends both (pre-filled from the form) so both will be non-null in practice, but
the DTO models the contract faithfully.

### New API endpoint in PostsApiClient

`PATCH /posts/{post_uuid}/revise` with body `RevisePostRequestDto`, returning `void`
(204 or 200 with no body consumed by the client). Added alongside the existing
`patchPost` method.

### EditPostCubit — unchanged interface, extended submit

`submit(UpdatedPostData data)` is unchanged in signature. Internally it calls the
unified `EditPostUseCase` which now returns from either port. States remain:
`initial`, `loading`, `success`, `error(Failure)`.

On `success`, the screen listener emits `PostRevisedEvent(postUuid)` on `PostEventBus`
and calls `context.router.maybePop()`.

### PostEventBus: PostRevisedEvent

A new `PostRevisedEvent(String postUuid)` event type is added to `PostEventBus`.
`PendingPostsCubit` (slice C) subscribes to it and calls `refresh()` so the revised
post reappears in the pending queue.

### Shared moderation log infrastructure

`IModerationLogPort` and `ModerationLogCubit` are placed in `posts/_shared/` (not in
slice D's folder) so both the moderation screen (slice D) and this slice can import
them without violating slice-isolation rules. The API endpoint
`GET /posts/{post_uuid}/moderation-log` and its adapter are also part of
`posts/_shared/data/`. This is a correction to the scope described in slice D's PRD:
the log port, adapter, and cubit are shared infrastructure, not slice-D-local code.

`ModerationLogCubit` is provided alongside `EditPostCubit` in the DI module for the
edit screen route, exactly as `GetUserTierCubit` is co-provided with `UserDetailsCubit`
on the user-details screen.

### EditPostScreen — adaptive layout

`LayoutBuilder` checks against `AppBreakpoints.medium` (600 dp, defined in slice C).

**Wide layout (≥ 600 dp):**
`Row` with two panes separated by a `VerticalDivider`. Moderation log panel at `flex: 1`
(minimum share); post editor at `flex: 1` baseline, grows with additional screen width.
`ModerationLogCubit.load(postUuid)` is called in `initState`.

**Narrow layout (< 600 dp):**
`DefaultTabController` with two tabs: "Edit" and "Log". `ModerationLogCubit.load()` is
called the first time the user switches to the "Log" tab.

### Revision message field

Rendered only when `post.status == PostStatus.changesRequested`. Appears below the
existing form fields and above the Save button. Multiline `TextFormField` with a label
clarifying that a message is required. Validation is enforced both in the form validator
(immediate feedback) and in the use-case (authoritative gate).

### Save button gating

- `PostStatus.approved` → `FilledButton.onPressed = null` (disabled). A helper text
  below explains that approved posts cannot be edited.
- `PostStatus.pendingReview` → enabled, calls regular edit endpoint.
- `PostStatus.changesRequested` → enabled, triggers the revise path with message
  validation.

### Localisation

All new strings (tab labels, message field label, "approved — cannot edit" hint,
revision-specific error messages) added via `slang` JSON. No hardcoded strings.

## Testing Decisions

Good tests assert on observable cubit state and rendered widget output, not on DTO
field names or the internal branching logic of the use-case's if/switch.

**Modules to test:**

- **RevisePostAdapter** — cover: 200/204 success; 403 → `ForbiddenFailure`; 404 →
  `NotFoundFailure`; 409 → `ConflictFailure`; 422 → `ValidationFailure`; unexpected
  exception → `Failure.unknown()` with log. Prior art: `EditPostAdapter` tests in
  `test/features/posts/edit_post/data/`.
- **EditPostUseCase (extended)** — cover: `changesRequested` + empty message →
  `ValidationFailure` without adapter call; `changesRequested` + non-empty message →
  calls revise adapter; `pendingReview` → calls edit adapter; `approved` → calls edit
  adapter (Save button is disabled in the UI but the use-case itself does not block
  `approved`); adapter failure propagates. Prior art: use-case tests in
  `test/features/posts/edit_post/domain/`.
- **EditPostCubit** — existing tests remain green (no state changes); add: `submit()`
  with `changesRequested` data → loading → success emits correctly. Prior art: existing
  cubit test in `test/features/posts/edit_post/application/`.
- **EditPostScreen widget — wide layout** — render: both panes visible; message field
  present and required when `status == changesRequested`; Save disabled when
  `status == approved`; log loading indicator shown while `ModerationLogCubit` is
  loading. Prior art: widget tests in `test/features/posts/edit_post/presentation/`.
- **EditPostScreen widget — narrow layout** — render: only "Edit" tab visible initially;
  switch to "Log" tab shows log panel and triggers `ModerationLogCubit.load()`;
  `load()` not called again on second switch. Same prior art.

## Out of Scope

- Creating a new top-level slice or route for the revision flow (the existing edit route
  is extended in place).
- Status display in `post_details` (slice F, `post_status_display`).
- Moderator actions (approve / request changes) — covered by slice D.
- The pending-posts tab and queue — covered by slice C.
- An author sending a standalone message without editing post content (not supported by
  the current API contract; `/revise` requires at least one of `title` / `text`).

## Further Notes

- **Dependency order:** depends on slice A (`post_status_contract`, for `PostStatus` and
  `Post.postUuid`), slice C (`pending_posts`, for `AppBreakpoints.medium`), and slice D
  (`moderate_post`, whose PRD should be read alongside this one for the shared log
  infrastructure correction). Can be implemented in parallel with slice D once slices A
  and C are merged.
- The `PostRevisedEvent` type introduced here should be defined in `PostEventBus` before
  slice C's `PendingPostsCubit` subscribes to it. In practice D and E ship close
  together; coordinate the event-type definition in the shared event bus file.
- The `ConflictFailure` (409) on `/revise` means the post is not in `changes_requested`
  state. This can happen if a moderator approves the post while the author is in the
  middle of editing. The error message should tell the author to return to `post_details`
  to check the current status.
- This slice deliberately does not re-fetch the post from the network on open; it
  receives the `Post` object as a route extra (already loaded by `post_details`). After
  slice A, `Post` carries `postUuid` and `status`, providing everything the use-case
  needs.
