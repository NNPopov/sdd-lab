# PRD — Slice 0020: create_post_status

## Problem Statement

When an author creates a post, the response does not include the post's current
moderation status. Because every newly created post automatically enters the
`pending_review` state (enforced by the DB default set in slice 0013), the
author has no programmatic way to know that their post is awaiting approval —
they must infer it. The `create_post` response must surface the `status` field
so that the frontend can display the correct state immediately after submission.

Additionally, the adapter currently relies silently on the ORM default
(`status = "pending_review"`). Making the assignment explicit in the adapter
makes the intent readable and keeps the layer honest about what it is setting.

## Solution

Extend the `create_post` slice with a minimal, additive change:

1. Add `status: str` to the `CreatedPost` domain entity so the use-case layer
   carries status information through its return value.
2. Add `status: str` to `CreatePostResponse` so the HTTP client receives the
   field.
3. Make the adapter pass `status="pending_review"` explicitly when constructing
   the `Post` ORM object, removing the implicit reliance on the column default.

No routing, DI wiring, port interface signature, or use-case logic changes.

## User Stories

1. As an authenticated author, I want the create-post API response to include
   the `status` field set to `pending_review`, so that I immediately know my
   post is awaiting moderation after it is created.
2. As a frontend developer, I want `POST /users/{username}/post` to return a
   `status` field alongside the post data, so that I can render the correct
   moderation-state badge without a follow-up request.
3. As an authenticated author, I want the `status` value in the response to
   always be `pending_review` at creation time, so that I can rely on its
   meaning without additional validation.
4. As a frontend developer, I want the response contract to remain stable for
   existing fields (`id`, `title`, `text`, `media_url`, `created_by_user_id`,
   `created_at`), so that adding `status` is non-breaking for consumers that
   ignore unknown fields.
5. As a developer reading the `create_post` adapter, I want the `status` value
   set explicitly in the `Post` constructor call, so that the intent is clear
   without needing to know the ORM column default.
6. As a maintainer, I want the `status` field on `CreatedPost` (domain entity)
   to be `str` (not `PostStatus` enum), consistent with the rest of the
   moderation slice entities, so that the layer boundary stays thin.

## Implementation Decisions

### Modules modified

- **`create_post/domain/entities.py`** — `CreatedPost` gains `status: str`.
  Pydantic will populate it from the ORM row via `model_validate`, so no
  use-case logic change is required.

- **`create_post/presentation/schemas.py`** — `CreatePostResponse` gains
  `status: str`. The router already calls `CreatePostResponse.model_validate(result)`
  where `result` is a `CreatedPost`; once the entity carries `status`, the
  schema picks it up automatically.

- **`create_post/data/adapter.py`** — the `Post(...)` constructor call gains
  `status="pending_review"` as an explicit keyword argument. The DB column
  default remains in place as a safety net but is no longer the sole mechanism.

### Modules NOT modified

- `create_post/domain/ports/create_post_port.py` — port signature is
  `async def create(...) -> CreatedPost`; the return type already covers the
  new field once the entity is updated. No protocol changes needed.
- `create_post/domain/use_case.py` — passes the `CreatedPost` through
  unchanged. No logic change required.
- `create_post/presentation/router.py` — no routing or response-model
  registration change required.
- `bootstrap/container.py` — no DI wiring change required.
- ORM model `adapters/db/models/post.py` — `status` column already exists
  (added in slice 0013); no migration needed.

### API contract change

`POST /users/{username}/post` response gains one new field:

```
status: "pending_review"   # always this value at creation time
```

All existing response fields are unchanged.

## Testing Decisions

Good tests verify observable behaviour through the public interface — HTTP
status codes, response bodies, and DB state — rather than asserting which
internal methods were called.

### Use-case unit test

Not required for this slice. The use-case contains no new logic; it is a pure
pass-through. Adding a test would only verify that Pydantic serialises `status`
from `CreatedPost`, which is framework behaviour, not domain logic.

### Adapter unit test

Verify that a `Post` row written by `CreatePostAdapter.create()` has
`status = "pending_review"` in the database. Uses a real async session against
the test Postgres database (consistent with the adapter-test pattern established
in `tests/features/posts/0011_create_post/`).

### Endpoint integration test

Extend (or add a new case to) the existing `0011_create_post` integration test:
- Assert that `POST /users/{username}/post` returns HTTP 201 with a JSON body
  that includes `"status": "pending_review"`.
- All existing assertions (status code, field presence) must remain green.

Prior art: `tests/features/posts/0011_create_post/`.

### Outside-in test

One outside-in acceptance test that covers the full happy path end-to-end:

1. Register and authenticate an author.
2. `POST /users/{username}/post` with valid title and text.
3. Assert HTTP 201 and `response.json()["status"] == "pending_review"`.

The slice is not done until this test is green.

## Out of Scope

- Returning the full `PostModerationLog` in the create-post response — the log
  is empty at creation time and is not needed here.
- Exposing `post_uuid` in the create-post response — already out of scope for
  the original `create_post` slice.
- Validating or enforcing the status transition rules at post creation time —
  the only valid creation status is `pending_review`; transitions are the
  responsibility of `moderate_post` and `revise_post` slices.
- Any change to `list_posts` or `list_all_posts` visibility filtering — those
  are handled by slices 0021 and 0022.
- Cache invalidation — `create_post` does not currently use the `@cache`
  decorator on the creation endpoint; no change needed.

## Further Notes

- The `Post.status` column default (`"pending_review"`) was introduced in slice
  0013 and is already applied to all rows created since then. Slice 0020 makes
  this explicit in the adapter but does not change observable DB behaviour.
- Existing outside-in tests for `create_post` (slice 0011) must remain green
  throughout. If the added `status` field causes any existing assertion to fail,
  that test must be updated to expect the new field before implementation begins.
- The response field is typed `str` rather than a `Literal["pending_review"]`
  to remain consistent with how other moderation-related entities in this
  codebase represent status (plain strings, not enums or Literals).
