# 0031 · list_posts_feed — Outside-in test spec

## Goal

Prove that `ListPostsCubit.load()` correctly calls `GET /posts`, parses the
paginated response including the `username` field on each item, maps it to domain
objects, computes `hasMore` from the numeric pagination fields, and emits the
right state sequence — wiring the real adapter, use case, and cubit together with
Dio mocked at the HTTP boundary.

## Entry point

`cubit.load()`

Called once per scenario against a freshly constructed Cubit wired to real
production layers (Adapter → UseCase → Cubit), with Dio mocked at the network
boundary.

## Wired real (production code in the test)

- `ListPostsAdapter` (data layer — calls `PostsApiClient.getPosts`, parses `PaginatedPostsDto` / `PostItemDto`, maps to `PaginatedPosts` / `Post`)
- `ListPostsPort` (bound to `ListPostsAdapter` — wired manually, no DI container)
- `ListPostsUseCase` (domain layer — delegates to the port)
- `ListPostsCubit` (application layer — system under test)

## Mocked (system boundaries only)

- **Dio**: intercepted with a mock HTTP handler; returns a pre-configured JSON body for `GET /posts`.
- **PostEventBus**: mock that exposes an empty broadcast stream — required because `ListPostsCubit` subscribes in its constructor; the subscription must not throw, but no events need to be delivered for these scenarios.
- **AppLogger**: mock that records calls — needed to verify it is NOT called on the success path.

---

## Test scenarios

### Scenario 1: first-page load — endpoint called, username mapped, `hasMore = true`

**Setup:**
- Dio returns `200` for `GET /posts?page=1&items_per_page=10` with body:
  ```
  {
    "items": [
      {
        "id": 7,
        "title": "Hello World",
        "text": "some body text",
        "media_url": null,
        "created_at": "2026-05-14T12:00:00.000Z",
        "created_by_user_id": 3,
        "username": "alice"
      }
    ],
    "total_count": 100,
    "page": 1,
    "items_per_page": 10
  }
  ```

**Act:**
- `cubit.load()`

**Expect:**
- States emitted by the Cubit:
  `[ListPostsLoading(), ListPostsLoaded(posts: [Post(id: 7, title: 'Hello World', text: 'some body text', createdByUserId: 3, username: 'alice')], page: 1, hasMore: true)]`
- `hasMore` is `true` because `1 × 10 < 100`.
- `Post.username` is `'alice'` — the `username` field from the item DTO is correctly mapped onto the domain entity.
- `AppLogger.error` is NOT called.

---

### Scenario 2: server error — adapter maps 500 to `ServerFailure`, cubit emits error state

**Setup:**
- Dio returns `500` for `GET /posts?page=1&items_per_page=10` with no body.

**Act:**
- `cubit.load()`

**Expect:**
- States emitted by the Cubit:
  `[ListPostsLoading(), ListPostsError(ServerFailure(statusCode: 500))]`
- `AppLogger.error` is NOT called (a mapped HTTP error is not an unexpected exception; only the outer catch-all calls the logger).

---

## Out of scope for this test

- `loadMore()` and `refresh()` cubit flows (covered by `list_posts_cubit_test.dart` unit tests).
- Network failure path — `DioException` without a response (covered by `list_posts_adapter_test.dart` unit tests).
- `hasMore = false` boundary case (covered by `list_posts_cubit_test.dart` and `list_posts_adapter_test.dart`).
- `PostDeleted` event-bus integration (covered by `list_posts_cubit_test.dart` unit tests).
- Widget rendering, scroll behaviour, FAB visibility, pull-to-refresh gesture (covered by widget tests and manual M-scenarios in `validation.md`).
- Route navigation (covered by widget tests).
