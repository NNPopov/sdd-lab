# 0051 · post_details_edit_post_route_to_user_id — Outside-in test spec

## Goal

Prove that reading and updating a single post both address the post by the author's
**integer `user_id`**: `PostDetailsCubit.load` makes the client call `getPost(<int>, id)`,
`EditPostCubit.submit` makes it call `patchPost(<int>, id, body)` with the unchanged body,
and authorship is decided by id (a user whose id ≠ the target author id is forbidden).

## Entry point

Two cubits exercise the two migrated verticals through their public surface:

- `postDetailsCubit.load(42, 7)` — the read vertical.
- `editPostCubit.submit(UpdatedPostData(userId: 42, id: 7, …))` — the update vertical.

## Wired real (production code in the test)

- `GetPostAdapter` (the post_details Adapter), bound as `PostDetailsPort`.
- `GetPostUseCase`.
- `PostDetailsCubit` (system under test for the read vertical).
- `EditPostAdapter` (the edit_post Adapter), bound as `EditPostPort`.
- `RevisePostAdapter`, bound as `IRevisePostPort` (constructed, not exercised — the
  edit path here is the non-revise branch).
- `EditPostUseCase`.
- `EditPostCubit` (system under test for the update vertical).
- The `Post` and `UpdatedPostData` domain entities.

## Mocked (system boundaries only)

- **`PostsApiClient`**: the HTTP boundary.
  - `getPost(42, 7)` returns a `PostDto(id: 7, postUuid: 'uuid-7', status: 'pending_review',
    title: 'Hello', text: 'Body', createdAt: <fixed DateTime>, mediaUrl: null,
    createdByUserId: 42)`.
  - `patchPost(42, 7, any)` completes normally (server returns no body).
- **`AuthCubit`**: `currentUser` returns a `CurrentUser` fixture whose `id` is the value
  under test (id `42` for the author scenario, id `99` for the forbidden scenario).

## Test scenarios

### Scenario 1: reading a post calls `getPost` with the integer user id

**Setup:**
- `PostsApiClient.getPost(42, 7)` returns the `PostDto` fixture above.

**Act:**
- `postDetailsCubit.load(42, 7)`

**Expect:**
- States emitted by the Cubit: `[PostDetailsLoading, PostDetailsLoaded(post)]` where
  `post.id == 7` and `post.createdByUserId == 42`.
- Mocks verified: `PostsApiClient.getPost(42, 7)` called exactly once with the **integer**
  `42` (not a username string).

### Scenario 2: the author updating a post calls `patchPost` with the integer user id and unchanged body

**Setup:**
- `AuthCubit.currentUser` returns a fixture with `id: 42`.
- `PostsApiClient.patchPost(42, 7, any)` completes normally.

**Act:**
- `editPostCubit.submit(UpdatedPostData(userId: 42, id: 7, postUuid: 'uuid-7',
  status: PostStatus.pendingReview, title: 'Updated title', text: 'Updated body',
  mediaUrl: null, revisionMessage: null))`

**Expect:**
- States emitted by the Cubit: `[EditPostLoading, EditPostSuccess]`.
- Mocks verified: `PostsApiClient.patchPost(42, 7, body)` called exactly once with the
  **integer** `42` and a body carrying `title: 'Updated title'`, `text: 'Updated body'`,
  `mediaUrl: null` (the body is unchanged by the migration).

### Scenario 3: a non-author is forbidden by id and no update is sent

**Setup:**
- `AuthCubit.currentUser` returns a fixture with `id: 99` (≠ the target author id `42`).

**Act:**
- `editPostCubit.submit(UpdatedPostData(userId: 42, id: 7, postUuid: 'uuid-7',
  status: PostStatus.pendingReview, title: 'Updated title', text: 'Updated body',
  mediaUrl: null, revisionMessage: null))`

**Expect:**
- States emitted by the Cubit: `[EditPostLoading, EditPostError(ForbiddenFailure)]`.
- Mocks verified: `PostsApiClient.patchPost` is **never** called (ownership decided by
  `currentUser.id == data.userId`).

## Out of scope for this test

- Widget rendering — the detail content, the id-gated Edit action, the body status chip,
  and the hidden Delete/Erase bridge are covered by widget tests separately.
- Route navigation and `@PathParam` parsing (`user_id`) — covered by routing/widget tests.
- The adapters' HTTP failure mapping (getPost 404/≥500/network; patchPost 401/403/422/
  network/server) and the catch-all `logger.error` — covered by adapter unit tests.
- DTO deserialization of the now-required `created_by_user_id` — covered by DTO unit tests.
- The changes-requested revise branch — covered by use-case/adapter unit tests.
