# PRD: post_status_display (0037)

## Problem Statement

An author who opens one of their own posts in `post_details` has no idea whether the
post is awaiting moderation, has been approved, or was sent back for revision. The
screen looks identical regardless of status. The author must navigate away and check
the user_posts list — which, after slice A, will show all statuses — to figure out
what is happening with their post. This makes the moderation feedback loop opaque and
frustrating.

## Solution

Extend `post_details` to display a status chip to the post's author. The chip is shown
beneath the post title and reads `Pending Review`, `Approved`, or `Changes Requested`
depending on `Post.status`. It is visible only to the author; other viewers (including
superusers) do not see it. No additional API call is made: `Post.status` is already
returned by the single-post endpoint after slice A. The Save/Edit button visibility
rules that govern what the author can do next are handled by slice E (`revise_post`);
this slice is purely about surfacing the status to the author in the view.

## User Stories

1. As an author, I want to see a status chip on my post's detail screen, so that I
   immediately know whether my post is pending review, approved, or awaiting my
   corrections.
2. As an author with a `pending_review` post, I want to see a "Pending Review" chip, so
   that I know the post has been submitted and is in the moderation queue.
3. As an author with an `approved` post, I want to see an "Approved" chip, so that I
   know the post is live and no further action is needed.
4. As an author with a `changes_requested` post, I want to see a "Changes Requested"
   chip, so that I know a moderator has reviewed it and is waiting for me to revise.
5. As any user who is not the post's author, I want the status chip to be invisible, so
   that the moderation lifecycle is not surfaced to readers who cannot act on it.
6. As an author, I want the status chip to use distinct colours for each status, so that
   I can recognise the state at a glance without reading the label.
7. As an author, I want the status chip to appear immediately when the screen loads (no
   extra spinner), so that there is no perceived delay in seeing my post's status.
8. As an author, I want the status chip to update automatically after I return from
   revising my post, so that I can confirm the post is back in `pending_review` without
   manually refreshing.
9. As an author, I want the status chip to update automatically after I return from
   editing a `pending_review` post, so that the screen reflects the current state.
10. As an author viewing an `approved` post, I want the edit button to still be visible,
    so that I can open the editor even though saving is disabled (handled by slice E).
11. As an author viewing a `changes_requested` post, I want the edit button to be
    visible and reachable quickly, so that I can act on the moderator's feedback without
    extra navigation.

## Implementation Decisions

### Scope: extension of post_details, no new files

All changes are inside the existing `post_details` slice. No new port, adapter,
use-case, or cubit is added. `Post.status` (a `PostStatus` enum value introduced in
slice A) is read directly from the already-loaded `PostDetailsLoaded` state.

### Status chip placement

The chip is inserted in the `PostDetailsLoaded` branch of the body `Column`, directly
below the post title and above the media image (or above the markdown body if there is
no media). This makes the status immediately visible without scrolling.

### Chip visibility condition

The chip is rendered only when the current `AuthState` is `AuthAuthenticated` and
`currentUser.username == post.createdByUsername`. The `post.createdByUserId`/username
matching logic already exists in the AppBar actions section of `PostDetailsScreen`; the
chip reuses the same `isAuthor` boolean already derived there, avoiding duplicate
`BlocBuilder` nesting.

Because `Post` (after slice A) carries `username` (the author's username), the
`isAuthor` check is `currentUser.username == post.username`.

### Chip colour semantics

| Status | Colour role |
|---|---|
| `pendingReview` | `ColorScheme.tertiary` / `tertiaryContainer` |
| `approved` | `ColorScheme.primary` / `primaryContainer` |
| `changesRequested` | `ColorScheme.error` / `errorContainer` |

Colours are taken from the active `Theme` so they adapt to light/dark mode without
hardcoded values.

### No additional network call

`Post.status` is populated by the existing `GET /{username}/post/{id}` call (updated
in slice A). The `PostDetailsCubit` and `GetPostAdapter` are unchanged. The screen
reads `postState.post.status` directly.

### Automatic refresh on return from edit/revise

The existing `PostDetailsScreen` already calls `cubit.load(username, id)` after
`context.router.push(EditPostRoute(...))` returns. This means that after a successful
revision (`changes_requested → pending_review`) or a regular edit, the cubit reloads
the post and the status chip updates to the new value automatically. No additional
wiring is required.

### Edit button: unchanged visibility

The edit button (IconButton with `Icons.edit_outlined`) remains visible to the author
for all statuses. The Save-button gating inside the edit screen is slice E's
responsibility; `post_details` does not need to know about it.

### Localisation

Three new translation keys are added for the chip labels: `postStatus.pendingReview`,
`postStatus.approved`, `postStatus.changesRequested`. Keys live under the `posts`
namespace in the `slang` JSON files. No hardcoded strings.

## Testing Decisions

Good tests assert on what the widget renders given a specific cubit state and auth
state — not on which method the cubit calls internally.

**Modules to test:**

- **PostDetailsScreen widget** — this is the only module that changes. Cover:
  - Author viewing a `pendingReview` post → chip with "Pending Review" label is visible.
  - Author viewing an `approved` post → chip with "Approved" label is visible.
  - Author viewing a `changesRequested` post → chip with "Changes Requested" label is
    visible.
  - Non-author (different username) viewing the same post → chip is absent.
  - Unauthenticated user viewing the post → chip is absent.
  - `PostDetailsLoading` state → no chip (loading indicator shown instead).
  - `PostDetailsError` state → no chip (error/retry shown instead).
  - Chip colour: not asserted (implementation detail of Theme); label text is the
    assertion target.
  - Prior art: `test/features/posts/post_details/presentation/` widget tests using a
    mocked `PostDetailsCubit` and a mocked `AuthCubit`.

No adapter, use-case, or cubit tests are added for this slice — the observable contract
of those layers is unchanged.

## Out of Scope

- Showing post status in the `user_posts` list tiles (the backend already filters the
  list correctly for the author; surfacing status in list tiles is a separate decision
  not requested).
- Showing moderator messages in `post_details` (author reads the full moderation log
  only in the edit/revise screen — slice E).
- Status visibility for moderators or superusers on other authors' posts.
- Any change to how `post_details` works for non-authors (the screen is unmodified for
  them).
- Push notifications or badges when post status changes.

## Further Notes

- **Dependency order:** depends only on slice A (`post_status_contract`, which adds
  `PostStatus` and `Post.status`). This is the lightest slice in the moderation set and
  can be implemented immediately after slice A is merged, independently of slices B–F.
- The status chip intentionally does not reflect real-time status changes. If a
  moderator approves the post while the author is on the screen, the chip will not
  update until the author navigates away and back (triggering `cubit.load()`). This is
  acceptable for the current scope.
- `post.username` (author username) was introduced as a nullable field in the existing
  `Post` entity. After slice A it remains nullable but will always be populated for
  posts fetched from the single-post endpoint, since the backend guarantees it. The
  `isAuthor` check should treat a null `post.username` as non-author.
