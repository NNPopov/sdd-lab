# requirements.md — 0016 · post_details

## Functional Requirements

| ID | Requirement | Source |
|---|---|---|
| FR-01 | The screen is accessible at the URL `/user/:username/posts/:id` without authentication | US-1, US-11 |
| FR-02 | The AppBar displays the title "Post" and a standard back button | US-8 |
| FR-03 | The post title is displayed first in the screen body | US-2 |
| FR-04 | If the post has a `media_url`, the image is displayed below the title with `BoxFit.cover` | US-3 |
| FR-05 | If `media_url` is present but the image fails to load, a placeholder icon is shown; the rest of the content remains | US-10 |
| FR-06 | The post text is rendered with Markdown formatting (`MarkdownBody`) | US-4 |
| FR-07 | The publication date is displayed below the text in the format `dd MMM yyyy, HH:mm` (local time) | US-5 |
| FR-08 | While the post is loading, a `CircularProgressIndicator` is shown centred on the screen | US-6 |
| FR-09 | On any loading error, an error message and a "Retry" button are shown | US-7 |
| FR-10 | Tapping "Retry" repeats the request | US-7 |
| FR-11 | If the post content is longer than the screen, the page scrolls vertically | US-9 |
| FR-12 | The AppBar and back button are visible in all states: loading, error, success | Arch |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| NFR-01 | No new dependencies — `flutter_markdown` and `intl` are already in `pubspec.yaml` |
| NFR-02 | The adapter must have the double catch (§8.4 CLAUDE.md): inner `on DioException`, outer `catch (e, st)` with `AppLogger` |
| NFR-03 | All UI strings via `slang` (no hardcoding) |
| NFR-04 | No logic in `build()` — only in Cubit/use-case |

## Constraints

- The screen is read-only — editing and deletion are out of scope
- The author's name is not shown (`created_by_user_id` is an `int`, request for profile is not in scope)
- Navigation to the screen from `list_posts` / `user_posts` — out of scope for this slice
- `media_url` is treated as an image; content type is not validated
