# validation.md — 0016 · post_details

## Automated Tests

| File | Scenarios | Status |
|---|---|---|
| `test/.../get_post_usecase_test.dart` | success → Right(post); failure → Left(failure) | ✅ |
| `test/.../post_details_cubit_test.dart` | load → [loading, loaded]; load → [loading, error(NotFound)]; load → [loading, error(Unknown)] | ✅ |

## Acceptance Criteria (by user stories)

### US-1, US-11 — Public access
- [ ] Open the URL `/user/testuser/posts/1` without authorisation (logged out or guest browser)
- [ ] The screen loads without redirecting to `/login`

### US-2, US-3, US-4, US-5 — Post content
- [ ] The post title is displayed first
- [ ] If `media_url` is not null — the image is visible below the title
- [ ] Markdown is rendered: `**bold**` → bold, `- item` → list, `\n` → line break
- [ ] Date in the format `dd MMM yyyy, HH:mm` (example: `15 Jan 2026, 14:30`)

### US-6 — Loading state
- [ ] When the screen first opens, a `CircularProgressIndicator` is visible
- [ ] The AppBar with the title "Post" is visible during loading

### US-7 — Error and Retry
- [ ] Disable network → open the screen → an error message + "Retry" button are visible
- [ ] AppBar is visible in the error state
- [ ] Tap "Retry" with the network restored → the post loads

### US-8 — AppBar
- [ ] AppBar shows the title "Post"
- [ ] The back button works and returns to the previous screen

### US-9 — Scrolling
- [ ] Open a post with long text → the entire text is accessible when scrolling

### US-10 — Image fallback
- [ ] Post with an invalid `media_url` → a placeholder icon instead of the image
- [ ] Title, text, and date are displayed normally

## Edge Cases

| Scenario | Expected behaviour |
|---|---|
| `media_url` = null | Image is not rendered, no spacing |
| `created_at` = null (server returned null) | Date is displayed as `01 Jan 1970, ...` (fallback DateTime(0)) |
| Post with an `id` that does not exist (404) | Error message + Retry |
| Post text = empty string | `MarkdownBody` renders an empty block without errors |

## Out of Scope

- Widget test `PostDetailsScreen`
- Navigation to the screen from `list_posts` / `user_posts`
- Test for adapter `GetPostAdapter`
