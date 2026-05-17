# 0035 · moderate_post — Outside-in test spec

## Goal

Prove that `ModeratePostCubit.moderate()` correctly wires the real use-case and
adapter to the mocked HTTP boundary: on a 200 response it emits the correct state
sequence and publishes `PostModeratedEvent` on `PostEventBus`; when the use-case
rejects the action client-side it emits an error state without touching the network.

## Entry point

`cubit.moderate(postUuid: 'post-uuid-abc-123', action: <action>, message: <message>)`

Both scenarios call this method on a freshly constructed cubit wired through real
production layers.

## Wired real (production code in the test)

- `ModeratePostAdapter` (data layer — calls `PostsApiClient.moderatePost`, maps
  `ModeratePostResultDto` → `PostStatus`)
- `PostsApiClient` (Retrofit client — receives the mocked `Dio` instance)
- `IModeratePostPort` (bound to `ModeratePostAdapter` — wired manually, no DI container)
- `ModeratePostUseCase` (domain layer — validates message requirement, delegates to port)
- `ModeratePostCubit` (application layer — system under test)
- `PostEventBus` (real in-memory broadcast stream — wired real to observe the
  `PostModeratedEvent` side-effect via `expectLater` before the action)

## Mocked (system boundaries only)

- **Dio**: intercepted with a mock HTTP handler; returns a pre-configured response for
  `POST /posts/post-uuid-abc-123/moderate`.
- **AppLogger**: a no-op mock instance — satisfies `ModeratePostAdapter`'s constructor
  parameter without capturing calls (not the focus of these scenarios).

---

## Test scenarios

### Scenario 1: Approve without a message — full pipeline, success state and PostModeratedEvent

**Setup:**
- Dio mock returns status `200` for `POST /posts/post-uuid-abc-123/moderate` with body:
  ```
  {"post_uuid": "post-uuid-abc-123", "status": "approved"}
  ```
- **Before calling `cubit.moderate()`**, register an `expectLater` assertion on
  `PostEventBus.stream` that it emits one `PostModeratedEvent` whose `postUuid`
  equals `'post-uuid-abc-123'`.

**Act:**
- `cubit.moderate(postUuid: 'post-uuid-abc-123', action: 'approved', message: null)`

**Expect:**
- States emitted by the Cubit:
  `[ModeratePostLoading(), ModeratePostSuccess(PostStatus.approved)]`
- Side effects observed: the `expectLater` future resolves — `PostEventBus.stream`
  delivered exactly one `PostModeratedEvent(postUuid: 'post-uuid-abc-123')`.
- Mocks verified: Dio received exactly one POST request to
  `/posts/post-uuid-abc-123/moderate`.

---

### Scenario 2: Request Changes with an empty message — client-side validation, Dio not called

**Setup:**
- Dio mock is configured for the route but expected to receive **zero** requests.
- No `expectLater` on `PostEventBus.stream` (nothing should be emitted).

**Act:**
- `cubit.moderate(postUuid: 'post-uuid-abc-123', action: 'changes_requested', message: '')`

**Expect:**
- States emitted by the Cubit:
  `[ModeratePostLoading(), ModeratePostError(ValidationFailure(fieldErrors: {'message': 'required'}))]`
- Side effects observed: `PostEventBus.stream` emits nothing — no
  `PostModeratedEvent` is published.
- Mocks verified: Dio received zero POST requests — the use-case short-circuits
  before the adapter is invoked.

---

## Out of scope for this test

- `ModerationLogCubit.load()` path (covered by `ModerationLogCubit` unit tests and
  `ModerationLogAdapter` unit tests).
- 409 conflict, 403 forbidden, and 404 not-found HTTP error paths from
  `ModeratePostAdapter` (covered by `moderate_post_adapter_test.dart` unit tests).
- Widget rendering — adaptive layout, tab switching, button disable states
  (covered by widget tests separately).
- Route navigation and `context.router.pop()` after success (covered by widget
  tests separately).
- Manual UX scenarios from validation.md that do not change Cubit-observable state.
