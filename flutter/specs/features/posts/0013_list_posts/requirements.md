# 0013 · posts / list_posts — Requirements

## Functional Requirements

| # | Requirement |
|---|---|
| F1 | The "Posts" menu item is displayed in the navigation bar between Users and Tiers |
| F2 | The Posts tab is visible to all users, including unauthenticated ones |
| F3 | Tapping the Posts tab opens a screen with the title "Posts" |
| F4 | The Posts screen is empty (a stub) — no content, no logic |
| F5 | The Tiers tab is still visible only to superusers |
| F6 | Logging out while the Tiers tab is active still switches to Users (index 0) |

## Non-functional Requirements

| # | Requirement |
|---|---|
| N1 | The string "Posts" is localised via slang (key `nav.posts`), not hardcoded |
| N2 | The slice contains no domain/, data/, application/ — only presentation/ |
| N3 | The ListPostsRoute has no guards |
| N4 | posts_feature_module.dart exists and is annotated with @module |

## Out of Scope

- A real list of posts
- API integration
- Pagination, filtering
- Authorisation for Posts
