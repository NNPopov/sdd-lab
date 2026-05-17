# 0014 · user_posts — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The route `/user/:username/posts` opens the posts page for the user with the given `username` |
| F2 | The AppBar shows `"@{username}'s posts"` |
| F3 | Access is open to any user, including unauthenticated ones — no AuthGuard or PermissionGuard |
| F4 | The list displays posts paginated in groups of 10 |
| F5 | Each list item shows: title, text preview (first 100 characters of plain text after markdown strip + "..."), creation date in the format `"29 Apr 2026"` |
| F6 | When scrolled to the end of the list, the next page is automatically loaded (infinite scroll) if `has_more=true` |
| F7 | Pull-to-refresh resets the list to page 1 and reloads |
| F8 | If there are no posts, the message "No posts yet" is shown |
| F9 | On a network error during the initial load — an error message + a Retry button |
| F10 | Tapping a post card does nothing (navigation will be added later) |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | All UI strings via slang — no hardcoding |
| N2 | The post text is stored as-is in the domain (Markdown). Stripping happens only in the UI widget |
| N3 | DTO — soft contract: all fields except `id` have `@Default` or are nullable |
| N4 | The adapter implements the double catch pattern per CLAUDE.md §8.4 |
| N5 | The slice does not import `list_posts` or other slices of the `posts` feature |
| N6 | The `Post` entity is not moved to `_shared/` until a second slice that actually uses it appears |

## Out of Scope

- Post detail page (Markdown rendering)
- Navigation to `user_posts` from `UserDetailsScreen`
- Creating, editing, deleting posts
- Authorised access / access control for viewing
