# 0030 · adapt_paginated_posts_contract — Outside-in test spec

## Goal

Prove that `UserPostsCubit.load()` correctly parses the new `GET /{username}/posts`
response shape (`items`, `total_count`, `page`, `items_per_page`), maps the new
`username` field onto the `Post` entity, and derives `hasMore` from the numeric
pagination fields.

## Entry point

`cubit.load('userson1')`

Called once per scenario against a freshly constructed Cubit wired to real production
layers (Adapter → UseCase → Cubit), with Dio mocked at the network boundary.

## Wired real (production code in the test)

- `UserPostsAdapter` (data layer — parses `PaginatedPostsDto`/`PostItemDto`, maps to `PaginatedPosts`/`Post`)
- `UserPostsPort` (bound to `UserPostsAdapter` — wired manually, no DI container)
- `UserPostsUseCase` (domain layer — delegates to the port)
- `UserPostsCubit` (application layer — system under test)

## Mocked (system boundaries only)

- **Dio**: intercepted with a mock HTTP handler; returns a pre-configured JSON body
  for `GET /{username}/posts`.
- **PostEventBus**: mock that exposes an empty broadcast stream — required because
  `UserPostsCubit` subscribes to the event bus in its constructor; the subscription
  must not throw, but no events need to be delivered for these scenarios.
- **AppLogger**: mock that records calls — needed to verify it is NOT called on the
  success path.

---

## Test scenarios

### Scenario 1: first-page load — new contract parsed, `username` mapped, `hasMore = true`

**Setup:**
- Dio returns `200` for `GET /userson1/posts?page=1&items_per_page=10` with body:
  ```json
  {
    "items": [
      {
        "id": 2,
        "title": "Test Post",
        "text": "test",
        "media_url": null,
        "created_at": "2026-04-29T21:26:38.178566Z",
        "created_by_user_id": 2,
        "username": "userson1"
      }
    ],
    "total_count": 100,
    "page": 1,
    "items_per_page": 10
  }
  ```

**Act:**
- `cubit.load('userson1')`

**Expect:**
- States emitted by the Cubit:
  `[UserPostsLoading(), UserPostsLoaded(posts: [Post(id: 2, title: 'Test Post', text: 'test', createdByUserId: 2, username: 'userson1')], page: 1, hasMore: true)]`
- `hasMore` is `true` because `1 × 10 < 100`.
- `Post.username` is `'userson1'` (new field, correctly mapped from the item DTO).
- `AppLogger.error` is NOT called.

---

### Scenario 2: single-page load — `hasMore = false` when `totalCount == page × itemsPerPage`

**Setup:**
- Dio returns `200` for `GET /userson1/posts?page=1&items_per_page=10` with body:
  ```json
  {
    "items": [
      {
        "id": 2,
        "title": "Test Post",
        "text": "test",
        "media_url": null,
        "created_at": "2026-04-29T21:26:38.178566Z",
        "created_by_user_id": 2,
        "username": "userson1"
      }
    ],
    "total_count": 10,
    "page": 1,
    "items_per_page": 10
  }
  ```

**Act:**
- `cubit.load('userson1')`

**Expect:**
- States emitted by the Cubit:
  `[UserPostsLoading(), UserPostsLoaded(posts: [Post(id: 2, ...)], page: 1, hasMore: false)]`
- `hasMore` is `false` because `1 × 10 < 10` is false (last page, exactly full).
- `AppLogger.error` is NOT called.

---

## Out of scope for this test

- Network failure paths (covered by `user_posts_adapter_test.dart` unit tests).
- `loadMore()` and `refresh()` cubit flows (covered by `user_posts_cubit_test.dart` unit tests).
- Widget rendering, load-more indicator visibility, pull-to-refresh gesture (covered by widget tests and manual M-scenarios in `validation.md`).
- `PostDto` field mapping for single-post endpoints — unchanged; covered by existing unit tests.
- `PostDeleted` event-bus integration (covered by `user_posts_cubit_test.dart` unit tests).
