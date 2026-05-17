# 0036 · revise_post — Outside-in test spec

## Goal

Prove that calling `EditPostCubit.submit()` with a `changesRequested` post and a
non-empty revision message routes the request through `RevisePostAdapter` to
`PATCH /posts/{post_uuid}/revise` and emits the correct state sequence.

## Entry point

`cubit.submit(UpdatedPostData(username: 'alice', id: 1, postUuid: 'post-uuid-001', status: PostStatus.changesRequested, title: 'Revised Title', text: 'Revised body text with enough content to pass validation.', revisionMessage: 'Addressed the moderator feedback on paragraph structure.'))`

## Wired real (production code in the test)

- `RevisePostAdapter` — implements `IRevisePostPort`, calls `PostsApiClient.revisePost`
- `EditPostAdapter` — implements `EditPostPort`, wired so the use-case compiles; not invoked in the `changesRequested` path
- `EditPostUseCase` — branches on `status`, delegates to `RevisePostAdapter` for `changesRequested`
- `EditPostCubit` — the system under test; calls `EditPostUseCase.call()` and emits states

## Mocked (system boundaries only)

- **Dio**: intercepted at the HTTP layer via `mockito`-style response or a test `Interceptor`; configured per scenario below.
- **AuthCubit**: `currentUser` returns a `CurrentUser` with `username: 'alice'`; no real token or network call.

## Test scenarios

### Scenario 1: successful revision of a `changesRequested` post

**Setup:**
- `Dio` returns HTTP 204 (no body) for `PATCH /posts/post-uuid-001/revise`.
- `AuthCubit.currentUser` returns `CurrentUser(username: 'alice')`.

**Act:**
- `cubit.submit(UpdatedPostData(username: 'alice', id: 1, postUuid: 'post-uuid-001', status: PostStatus.changesRequested, title: 'Revised Title', text: 'Revised body text with enough content to pass validation.', revisionMessage: 'Addressed the moderator feedback on paragraph structure.'))`

**Expect:**
- States emitted by the Cubit: `[EditPostLoading, EditPostSuccess]`
- Mocks verified: `Dio` received exactly one PATCH request to a path matching `/posts/post-uuid-001/revise`; the request body contained `message: 'Addressed the moderator feedback on paragraph structure.'`
- Side effects: none at this layer — `PostRevisedEvent` is published by the screen's `BlocListener`, which is out of scope for this test.

### Scenario 2: revision rejected with 409 (post no longer in `changes_requested` state)

**Setup:**
- `Dio` returns HTTP 409 for `PATCH /posts/post-uuid-001/revise`.
- `AuthCubit.currentUser` returns `CurrentUser(username: 'alice')`.

**Act:**
- Same `cubit.submit(...)` call as Scenario 1.

**Expect:**
- States emitted by the Cubit: `[EditPostLoading, EditPostError]` where the error state wraps a `ConflictFailure`.
- Mocks verified: `Dio` received exactly one PATCH request to `/posts/post-uuid-001/revise`.
- Side effects: none — no `PostRevisedEvent` is published.

## Out of scope for this test

- Widget rendering and adaptive layout (wide/narrow) — covered by widget tests after the outside-in test turns green.
- Route navigation (`maybePop`) and `PostRevisedEvent` publication — these happen in the `BlocListener` inside the screen widget; covered by widget tests.
- The `pendingReview` path through `EditPostAdapter` — covered by existing `edit_post` unit tests.
- Empty-revision-message validation returning `ValidationFailure` — covered by `EditPostUseCase` unit tests.
- `ModerationLogCubit` and log loading — covered by unit tests on `ModerationLogCubit` and `ModerationLogAdapter`.
- Manual UX scenarios from `validation.md` that require UI rendering.
