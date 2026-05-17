# PRD: moderate_post (0035)

## Problem Statement

Moderators can now see a queue of pending posts (slice C), but there is no screen where
they can actually act on a post — review its content, read the moderation history, write
a comment, and approve or request changes. Without this screen the entire moderation
workflow is blocked at the last step.

## Solution

Introduce a moderation screen reachable from the pending-posts queue. The screen uses an
adaptive layout: on wide displays (≥ 600 dp) the post content and the moderation panel
appear side-by-side; on narrow displays they occupy two separate tabs. The moderation
panel shows the full chronological moderation log and an action area where the moderator
can write a message and choose "Approve" or "Request Changes". After a successful action
the app fires a domain event, removes the post from the queue automatically, and returns
the moderator to the pending list.

## User Stories

1. As a moderator, I want to open a post from the pending queue and see its full content,
   so that I can judge whether it meets the community guidelines.
2. As a moderator, I want to see the complete moderation history for a post alongside the
   content, so that I understand the context of any previous review rounds.
3. As a moderator on a wide screen, I want the post content on one side and the
   moderation panel on the other, so that I can read and act without switching views.
4. As a moderator on a narrow screen, I want to switch between a "Post" tab and a
   "Moderation" tab, so that I can read the post and then act on it without the layout
   feeling cramped.
5. As a moderator, I want the moderation log to load lazily (on narrow: when I first
   switch to the Moderation tab; on wide: immediately after the main UI renders), so
   that the post content is available instantly with no wait.
6. As a moderator, I want to type a message in the moderation panel, so that I can
   explain my decision to the author.
7. As a moderator, I want to approve a post without writing a message, so that
   straightforward approvals are fast.
8. As a moderator, I want to request changes and be required to provide a message, so
   that the author always knows what to fix.
9. As a moderator, I want to see a validation error if I try to request changes without
   a message, so that I cannot accidentally submit a rejection with no explanation.
10. As a moderator, I want to see a loading indicator while my moderation decision is
    being submitted, so that I know the request is in flight.
11. As a moderator, I want to be returned to the pending queue automatically after a
    successful action, so that I can move on to the next post without extra navigation.
12. As a moderator, I want to see the moderated post disappear from the queue on my
    return, so that I do not accidentally review the same post twice.
13. As a moderator, I want to see a readable error message if my action fails (network
    error, 409 conflict, 403 forbidden), so that I understand what went wrong.
14. As a moderator, I want to see a 409 conflict presented as a specific message ("this
    post has already been moderated"), so that I understand it is a state issue, not a
    bug.
15. As a moderator, I want the moderation log to show each event's type (moderator
    review or author revision), actor username, timestamp, action label, and message, so
    that I can follow the full conversation thread.
16. As a moderator, I want an empty moderation log to display an empty-state message
    rather than an error, so that a freshly submitted post (with no prior events) looks
    correct.
17. As a moderator, I want the post view on the moderation screen to show the full post
    content (title, media, body text), so that I do not need to open a separate screen.
18. As a superuser acting as a moderator, I want the same screen and the same actions
    available to me, so that I can moderate without any additional configuration.

## Implementation Decisions

### Route and navigation

The moderation screen lives at `/pending/:post_uuid/moderate` as a child of
`PendingTabRoute`. It is guarded by `authGuard` and
`PermissionGuard({Permission.moderatePosts})`.

`PendingPostItem` (defined in `posts/_shared/` in slice C) is passed as an auto_route
extra so the screen can render the post immediately without an extra network fetch.
`post_uuid` is also a path parameter (used to construct API request URLs inside the
cubit/use-case).

After a successful moderation action: `context.router.pop()` returns to the pending
list. `PostModeratedEvent(postUuid)` is emitted on `PostEventBus`; `PendingPostsCubit`
(slice C) removes the item reactively.

### New API endpoints in PostsApiClient

Two methods are added:

`POST /posts/{post_uuid}/moderate` — body: `ModeratePostRequestDto`
(`action: String`, `message: String?`). Response: moderate-post result DTO containing
the new status. Errors: 403 → `ForbiddenFailure`, 404 → `NotFoundFailure`,
409 → `ConflictFailure`.

`GET /posts/{post_uuid}/moderation-log` — no body. Response: list wrapper DTO whose
`items` are `ModerationLogEntryDto` (schema defined in slice C; DTO is new here).
Errors: 401 → `UnauthorizedFailure`, 403 → `ForbiddenFailure`,
404 → `NotFoundFailure`.

### New DTOs

`ModeratePostRequestDto` — request body for the moderate endpoint:
`action: String`, `message: String?`.

`ModeratePostResultDto` — response from the moderate endpoint: `postUuid`,
`status: String`. Mapped to `PostStatus` by the adapter.

`ModerationLogResponseDto` — paginated-style wrapper for the log response:
`items: List<ModerationLogEntryDto>`. `ModerationLogEntryDto` mirrors the entity
defined in `posts/_shared/` (slice C).

### Domain ports and adapters

`IModeratePostPort` — single method:
`moderate(String postUuid, String action, String? message)`
→ `Either<Failure, PostStatus>`.

`IModerationLogPort` — single method:
`getModerationLog(String postUuid)`
→ `Either<Failure, List<ModerationLogEntry>>`.

Each port has a dedicated adapter with the standard double-catch error mapping
(`DioException` → typed `Failure`; `Object` → `Failure.unknown()` with `AppLogger`).

### Use-case

`ModeratePostUseCase` validates client-side that `message` is non-null and non-empty
when `action == "changes_requested"`, returning a `ValidationFailure` before making any
network call. On success it returns the new `PostStatus`.

### ModeratePostCubit

Manages the approve / request-changes action.

States: `initial`, `loading`, `success(PostStatus newStatus)`, `error(Failure)`.

On `success`, the screen emits `PostModeratedEvent` on the event bus and calls
`context.router.pop()`.

### ModerationLogCubit

Manages lazy loading of the moderation log.

States: `initial`, `loading`, `loaded(List<ModerationLogEntry>)`, `error(Failure)`.

Method: `load(String postUuid)`. Called once — on wide layout, immediately after the
screen widget mounts; on narrow layout, the first time the user switches to the
"Moderation" tab.

### Adaptive layout — ModeratePostScreen

`LayoutBuilder` checks against `AppBreakpoints.medium` (600 dp, defined in slice C).

**Wide layout (≥ 600 dp):**
`Row` with two `Expanded` children. Moderation panel has `flex: 1` (fixed minimum
share). Post view has `flex: 1` as well, but grows with available space because Flutter
distributes remaining pixels proportionally — at exactly 600 dp the split is 50/50; on
wider screens the post view gains more space as its flex share of the remaining pixels
increases. A `VerticalDivider` separates the two panes.

`ModerationLogCubit.load()` is called in `initState` (wide path).

**Narrow layout (< 600 dp):**
`DefaultTabController` with two tabs: "Post" and "Moderation".

`ModerationLogCubit.load()` is called inside an `IndexedStack` or
`TabBarView` + `didChangeDependencies` that detects first switch to the Moderation tab.

### Moderation panel widget

Top to bottom:
1. Scrollable `ModerationLogListView` — chronological log entries, each showing:
   event-type icon, actor username, formatted timestamp, action chip (Approved /
   Changes Requested, only for `moderator_review` events), message text.
   Empty state: a centred message ("No moderation history yet").
   Loading state: shimmer / `CircularProgressIndicator`.
2. Divider.
3. `TextField` for message (multiline, optional label clarifying it is required for
   rejection).
4. Row of two action buttons: "Approve" (primary/filled) and "Request Changes"
   (outlined/secondary). Both disabled while `ModeratePostCubit` is loading.

### Post view widget

Read-only display of `PendingPostItem` content: title (headline), optional media image,
body text. No edit/delete actions. Reuses visual style of `PostDetailsView` but is a
new stateless widget inside this slice.

### Localisation

All strings (tab labels, button labels, empty-state text, error messages, validation
message for missing rejection comment) via `slang` JSON. No hardcoded strings.

## Testing Decisions

Good tests assert on observable state and rendered output, not on internal DTO field
names or call order.

**Modules to test:**

- **ModeratePostAdapter** — cover: 200 success maps to correct `PostStatus`; 403 →
  `ForbiddenFailure`; 404 → `NotFoundFailure`; 409 → `ConflictFailure`; unexpected
  exception → `Failure.unknown()` with log. Prior art: adapter tests in
  `test/features/posts/*/data/`.
- **ModerationLogAdapter** — cover: 200 success maps all `ModerationLogEntry` fields
  correctly (both event types, null vs non-null action/message); 403 →
  `ForbiddenFailure`; 404 → `NotFoundFailure`; unexpected exception →
  `Failure.unknown()`. Same prior art.
- **ModeratePostUseCase** — cover: `changes_requested` with empty message →
  `ValidationFailure` without calling adapter; `approved` with null message → calls
  adapter and returns `PostStatus`; adapter failure propagates. Prior art: use-case
  unit tests in `test/features/posts/*/domain/`.
- **ModeratePostCubit** — cover: loading → success emits correct `PostStatus`; loading
  → error on adapter failure; `ValidationFailure` from use-case surfaces as error state.
  Prior art: cubit tests in `test/features/posts/*/application/`.
- **ModerationLogCubit** — cover: `load()` → loading → loaded with correct entry list;
  `load()` → error on adapter failure; empty list → loaded with empty list (not error).
  Same prior art.
- **ModeratePostScreen widget (wide)** — render: both panes visible; "Approve" and
  "Request Changes" buttons present; log loading indicator shown while
  `ModerationLogCubit` is loading; buttons disabled during `ModeratePostCubit` loading.
  Prior art: widget tests in `test/features/posts/*/presentation/`.
- **ModeratePostScreen widget (narrow)** — render: only Post tab visible initially;
  switch to Moderation tab shows panel; `ModerationLogCubit.load()` called on first
  tab switch only. Same prior art.

## Out of Scope

- The author's revision flow (slice E, `revise_post`).
- Post-status display in `post_details` (slice F, `post_status_display`).
- Push notifications when a moderation decision is made.
- Moderator being able to edit or delete the post content.
- Pagination of the moderation log (backend returns all entries in one response).

## Further Notes

- **Dependency order:** depends on slice A (`post_status_contract`, for `PostStatus`),
  slice B (`moderator_contract`, for `Permission.moderatePosts`), and slice C
  (`pending_posts`, for `PendingPostItem`, `ModerationLogEntry`, `AppBreakpoints`, and
  the `PendingTabRoute` stack this screen is a child of).
- The `PostModeratedEvent` type is introduced in this slice and added to `PostEventBus`.
  `PendingPostsCubit` (slice C) already subscribes to it — implementation order must
  ensure the event type exists before the cubit is compiled. In practice both slices
  ship together.
- The message field is optional for `approved` but the UI always shows it, allowing
  moderators to leave positive feedback even on approved posts.
- `ConflictFailure` (HTTP 409) means the post is no longer in `pending_review` — it was
  acted on by another moderator. The error message should tell the user to return to the
  queue.
