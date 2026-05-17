# 0032 · post_status_contract — Outside-in test spec

## Goal

Prove that `GetPostAdapter` correctly maps `post_uuid` and `status` from the backend
JSON all the way through to the `Post` domain entity held in `PostDetailsLoaded`,
including the fallback-to-`pendingReview` path for unknown status strings.

## Entry point

`cubit.load('alice', 42)` — triggers `GetPostUseCase` → `GetPostAdapter` →
`PostsApiClient.getPost('alice', 42)`.

## Wired real (production code in the test)

- `GetPostAdapter` (the slice's adapter, implements `PostDetailsPort`)
- `GetPostUseCase` (the slice's use-case)
- `PostDetailsCubit` (the system under test; its `PostDetailsLoaded` state carries the
  `Post` entity where the new fields are visible)

## Mocked (system boundaries only)

- **PostsApiClient**: stubbed to return a `PostDto` fixture with controlled
  `post_uuid` and `status` values.
- **AppLogger**: stubbed to capture `warning(...)` calls; verified in Scenario 2.

## Test scenarios

### Scenario 1: Known status — `approved` maps correctly, postUuid round-trips

**Setup:**
- `PostsApiClient.getPost('alice', 42)` returns a `PostDto` with:
  - `id: 42`, `title: 'Hello'`, `text: 'World'`
  - `post_uuid: 'post-uuid-abc'`
  - `status: 'approved'`
  - `created_at`: any valid `DateTime`
  - `created_by_user_id: 7`

**Act:**
- `cubit.load('alice', 42)`

**Expect:**
- States emitted by the Cubit: `[PostDetailsLoading, PostDetailsLoaded]`
- The `PostDetailsLoaded.post.postUuid` equals `'post-uuid-abc'`.
- The `PostDetailsLoaded.post.status` equals `PostStatus.approved`.
- `AppLogger.warning` is **not** called.

---

### Scenario 2: Unknown status — fallback to `pendingReview`, warning logged

**Setup:**
- `PostsApiClient.getPost('alice', 42)` returns a `PostDto` with:
  - `id: 42`, `title: 'Hello'`, `text: 'World'`
  - `post_uuid: 'post-uuid-xyz'`
  - `status: 'archived'` (not a recognised value)
  - `created_at`: any valid `DateTime`
  - `created_by_user_id: 7`

**Act:**
- `cubit.load('alice', 42)`

**Expect:**
- States emitted by the Cubit: `[PostDetailsLoading, PostDetailsLoaded]`
- The `PostDetailsLoaded.post.status` equals `PostStatus.pendingReview`.
- The `PostDetailsLoaded.post.postUuid` equals `'post-uuid-xyz'` (UUID still
  round-trips even when status falls back).
- `AppLogger.warning` is called exactly once.
- `AppLogger.error` is **not** called.

## Out of scope for this test

- `UserPostsAdapter` and `ListPostsAdapter` status mapping (covered by the extended
  unit tests for those adapters, per plan.md).
- Widget rendering of `Post.status` or `Post.postUuid` (no UI in this slice; covered
  by widget tests in slices 0033–0037).
- Route navigation (no navigation in this slice).
- HTTP error paths (404, 500, network) — covered by `GetPostAdapter` unit tests.
