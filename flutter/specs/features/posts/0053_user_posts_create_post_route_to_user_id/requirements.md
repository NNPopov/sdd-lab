# 0053 · user_posts_create_post_route_to_user_id — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The author-posts list shall load from the id-keyed route `/{user_id}/posts`. |
| F2 | The author-posts list shall preserve the existing content, pagination, infinite scroll, pull-to-refresh, empty state, and error/retry state with no observable change. |
| F3 | The author-posts screen shall display the `@username` AppBar title for the author whose posts are shown. |
| F4 | The author-posts screen shall show the create-post button only when the current user's id equals the route's user id, and hide it otherwise. |
| F5 | A post-deleted event shall remove the corresponding post from the loaded author-posts list, as before. |
| F6 | Tapping a post in the author-posts list shall open its detail screen keyed by the post's author id. |
| F7 | Tapping the create-post button on one's own posts list shall open the create screen keyed by the current user's id. |
| F8 | The create-post screen shall publish a new post via the id-keyed route `/{user_id}/post`. |
| F9 | The create-post request body (title, text, media URL) shall be sent unchanged. |
| F10 | The create-post form, its field validation, the markdown preview, the success-pop navigation, and the failure messages shall behave with no observable change. |
| F11 | A create attempt where the current user's id differs from the target user id (or no user is authenticated) shall be refused before any network call, returning a forbidden failure. |
| F12 | List and create failures (not found, unauthorized, forbidden, validation, server, network) shall surface the same messages as before the migration. |
| F13 | The global feed's create button shall open the create screen keyed by the current user's id. |
| F14 | The app header "my posts" menu item shall open the current user's posts list keyed by the current user's id. |
| F15 | The user-details "Posts" action shall open that user's posts list keyed by that user's id. |
| F16 | The users-list per-row navigation shall open the selected user's posts list keyed by that user's id. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | `getUserPosts` and `createPost` on `PostsApiClient` shall declare an integer `user_id` path parameter (`@Path('user_id') int`) on the paths `/{user_id}/posts` and `/{user_id}/post`. |
| N2 | The `user_posts` page shall declare `@PathParam('user_id') int userId` and carry the author's `username` as a required non-path route argument used only for the AppBar title. |
| N3 | The `create_post` page shall declare `@PathParam('user_id') int userId` and shall carry no display handle. |
| N4 | `UserPostsPort`, `UserPostsUseCase`, and `UserPostsCubit` (`load`/`refresh`/`loadMore`) shall take `int userId` instead of `String username`. |
| N5 | `NewPostData` shall carry `int userId` instead of `username`, while `CreatePostPort`, `CreatePostUseCase`, and `CreatePostCubit` keep their `NewPostData` method signatures unchanged. |
| N6 | The `user_posts` FAB-visibility check and the `CreatePostUseCase` ownership guard shall both compare identity as `currentUser.id == userId`. |
| N7 | The author's `username` shall be treated only as a displayed handle (the `@username` title) and shall never appear as a URL path segment. |
| N8 | `UserPostsAdapter` and `CreatePostAdapter` shall retain their nested `try`/`catch` with a catch-all `catch (e, st)` that logs via `logger.error` and returns `Failure.unknown()`, per `agent_docs/error_handling.md`. |
| N9 | The adapters shall preserve their existing HTTP failure mapping (user_posts: 404 / ≥500 / network; create_post: 401 / 403 / 422 / network / server). |
| N10 | No UI strings shall be added or changed; all displayed text continues to come from `slang`. |
| N11 | The `users` feature and `core/routing` shall reach the by-author posts surface only by constructing the shared route classes from `core/routing`, without importing the `posts` feature. |
| N12 | No post DTO shall change; `created_by_user_id` remains a required `int` (tightened in slice 0051). |
| N13 | Three route path strings shall change `:username` → `:user_id` (`user/:user_id/posts`, `user/:user_id/posts/create`, `:user_id/posts/create`); the already-migrated single-post paths and the non-username feed/pending/`post_uuid` paths shall remain untouched. |
| N14 | Codegen (retrofit client, auto_route pages/args, freezed if applicable) shall be regenerated via `build_runner`, and `dart format` and `dart analyze` shall be clean. |
| N15 | No new package dependency shall be added to `pubspec.yaml`. |
| N16 | The slice shall introduce no new screens, routes, states, or behavior — it is a pure identifier migration (`username` → author `user_id`). |

## Out of scope

- `getPost` / `patchPost` and the `post_details`/`edit_post` read/update path (migrated in 0051).
- `deletePost` / `eraseDbPost` and the `delete_post`/`erase_db_post` verticals (migrated in 0052).
- The global feed route (`/posts`, `getPosts`) and the pending-posts route — not username-based.
- `post_uuid`-based routes (`revisePost`, `moderatePost`, `getModerationLog`) — never carried a username.
- The `created_by_user_id` DTO contract and any other DTO shape.
- The create POST body (`CreatePostRequestDto`), the `username` handle as display (`@username`), and `AuthSession`.
