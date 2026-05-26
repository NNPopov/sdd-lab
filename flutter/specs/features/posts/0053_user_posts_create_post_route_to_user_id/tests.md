# 0053 · user_posts_create_post_route_to_user_id — Outside-in test spec

## Goal

Prove that the by-author posts surface is keyed by the author's integer `user_id`:
listing an author's posts calls `getUserPosts` with an `int` id, publishing calls
`createPost` with an `int` id and the unchanged body, and a create attempt as a
different user is refused by identity before any network call.

## Entry point

Two public-surface calls (the slice spans two independent verticals migrated together):

- `userPostsCubit.load(7)`
- `createPostCubit.submit(NewPostData(userId: 7, title: 'Hello world', text: <≥100-char body>, mediaUrl: null))`

## Wired real (production code in the test)

- `UserPostsAdapter` (the slice's adapter, bound to `UserPostsPort`)
- `UserPostsUseCase`
- `UserPostsCubit` (system under test for listing)
- `CreatePostAdapter` (bound to `CreatePostPort`)
- `CreatePostUseCase`
- `CreatePostCubit` (system under test for publishing)
- `NewPostData`, `PaginatedPosts`, `Post` domain entities and the DTO→entity mapping

## Mocked (system boundaries only)

- **PostsApiClient**: the API-client boundary (no live backend, no real Dio).
  - `getUserPosts(7, page: 1, perPage: 10)` returns a `PaginatedPostsDto` with one post
    item authored by user `7` (`createdByUserId: 7`, `username: 'alice'`), `page: 1`,
    `hasMore: false`.
  - `createPost(7, <CreatePostRequestDto>)` returns a `PostDto` (the adapter ignores the
    body of the response and returns `Right(null)`).
- **AuthCubit**: `currentUser` returns a `CurrentUser` fixture — `id: 7, username:
  'alice'` for the owner scenarios; `id: 99, username: 'mallory'` for the bypass scenario.
  (Only `CreatePostUseCase` consults it; `UserPostsCubit.load` does not.)
- **PostEventBus**: real or a test double — not asserted in this test (post-deleted
  propagation is covered by the cubit unit test).

## Test scenarios

### Scenario 1: listing an author's posts calls getUserPosts with the integer id

**Setup:**
- `PostsApiClient.getUserPosts(7, page: 1, perPage: 10)` returns a one-item
  `PaginatedPostsDto` (post authored by user `7`).

**Act:**
- `userPostsCubit.load(7)`

**Expect:**
- States emitted by the Cubit: `[UserPostsLoading, UserPostsLoaded]` where the loaded
  state holds exactly one post whose `createdByUserId == 7`.
- Mocks verified: `PostsApiClient.getUserPosts` called once with the **integer** `7`
  (not a string) and `page: 1, perPage: 10`.

### Scenario 2: publishing as oneself calls createPost with the integer id and unchanged body

**Setup:**
- `AuthCubit.currentUser` returns `CurrentUser(id: 7, username: 'alice', …)`.
- `PostsApiClient.createPost(7, any)` returns a `PostDto`.

**Act:**
- `createPostCubit.submit(NewPostData(userId: 7, title: 'Hello world', text: <≥100-char body>, mediaUrl: null))`

**Expect:**
- States emitted by the Cubit: `[CreatePostLoading, CreatePostSuccess]`.
- Mocks verified: `PostsApiClient.createPost` called once with the **integer** `7` and a
  `CreatePostRequestDto` carrying `title: 'Hello world'`, the same text, and `mediaUrl:
  null` (body unchanged by the migration).

### Scenario 3: publishing as a different user is refused by identity before any network call

**Setup:**
- `AuthCubit.currentUser` returns `CurrentUser(id: 99, username: 'mallory', …)` — a
  different user than the post's target `userId: 7`.

**Act:**
- `createPostCubit.submit(NewPostData(userId: 7, title: 'Hello world', text: <≥100-char body>, mediaUrl: null))`

**Expect:**
- States emitted by the Cubit: `[CreatePostLoading, CreatePostError]` whose failure is a
  `ForbiddenFailure`.
- Mocks verified: `PostsApiClient.createPost` is **never** called (the ownership guard
  `currentUser.id != data.userId` refuses before the network).

## Out of scope for this test

- Widget rendering — the `@username` AppBar title, the FAB visibility gated by
  `currentUser.id == userId`, and the form validation are covered by widget tests.
- Route navigation — `UserPostsRoute`/`CreatePostRoute` construction with the integer id
  and the display handle, and the migrated path strings, are covered by routing/widget
  tests.
- Pagination, pull-to-refresh, and post-deleted propagation through `PostEventBus` —
  covered by the `UserPostsCubit` unit test.
- Adapter HTTP failure mapping (404 / 401 / 403 / 422 / ≥500 / network) and the catch-all
  `logger.error` — covered by the adapter unit tests written after green.
