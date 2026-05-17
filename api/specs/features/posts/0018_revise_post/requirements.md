# 0018 · revise_post — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `PATCH /api/v1/posts/{post_uuid}/revise` accepts a `RevisePostRequest`
  body with fields `title`, `text`, and `message` and returns a `RevisePostResponse` with
  HTTP 200 on success.
- **F2.** `RevisePostRequest` raises HTTP 422 at the schema boundary when both `title` and
  `text` are `null` or absent, enforced by a `@model_validator(mode="after")` before the
  use-case is invoked.
- **F3.** The endpoint returns HTTP 401 when the request carries no valid Bearer token,
  enforced by the `get_current_user` dependency.
- **F4.** `RevisePostUseCase` raises `NotFoundDomainError("Post not found")` when
  `port.get_post_by_uuid()` returns `None`, without calling `port.apply_revision`.
- **F5.** `RevisePostUseCase` raises `ForbiddenDomainError("You may only revise your own posts")`
  when `post.created_by_user_id` does not equal `command.requester_user_id`, without calling
  `port.apply_revision`.
- **F6.** `RevisePostUseCase` raises `ForbiddenDomainError("Post is not in changes_requested status")`
  when `post.status` is anything other than `"changes_requested"`, without calling
  `port.apply_revision`.
- **F7.** On the happy path, `RevisePostUseCase` calls `port.apply_revision` with `post_id`,
  `post_uuid`, `title`, `text`, `author_user_id`, and `message` forwarded unchanged from the
  port lookup and the command, and returns the resulting `RevisedPostResult`.
- **F8.** `RevisePostAdapter.apply_revision` sets `Post.status = "pending_review"` and
  refreshes `Post.updated_at` in every successful call.
- **F9.** `RevisePostAdapter.apply_revision` includes `Post.title` in the UPDATE SET clause
  only when `title` is non-`None`; a `None` title means "leave unchanged" and must never
  overwrite the existing non-nullable column value.
- **F10.** `RevisePostAdapter.apply_revision` includes `Post.text` in the UPDATE SET clause
  only when `text` is non-`None`; a `None` text means "leave unchanged" and must never
  overwrite the existing non-nullable column value.
- **F11.** `RevisePostAdapter.apply_revision` inserts a `PostModerationLog` row with
  `event_type = "author_revision"`, `action = None`, `user_id = author_user_id`, and
  `message = message` within the same session commit as the post UPDATE.
- **F12.** `RevisePostAdapter.apply_revision` returns a `RevisedPostResult` whose `title`
  and `text` reflect the post row state after the UPDATE (unchanged fields retain their
  pre-revision values, not the `None` inputs).
- **F13.** `RevisePostAdapter.get_post_by_uuid` returns `None` when no post with the given
  UUID exists in the database.
- **F14.** `RevisePostAdapter.get_post_by_uuid` returns a `PostForRevision` with `id`,
  `uuid`, `status`, and `created_by_user_id` populated from the matching row when found.
- **F15.** The `RevisePostResponse` body includes `post_uuid`, `title`, `text`, `status`
  (always `"pending_review"`), `updated_at`, and a nested `log_entry` with `id`,
  `event_type` (always `"author_revision"`), `action` (always `null`), `message`, and
  `created_at`.

## Non-functional requirements

- **N1.** `RevisePostUseCase` is a class with `__call__(command: RevisePostCommand) ->
  RevisedPostResult`; invoked as `await use_case(command)`. Per
  `agent_docs/architecture.md` § Use-case shape.
- **N2.** `RevisePostAdapter` does not wrap operations in `try/except Exception`; unknown
  infrastructure failures propagate to the global exception handler in
  `adapters/http/exception_handlers.py`, which logs and returns HTTP 500. Per
  `agent_docs/error_handling.md` § Adapter: catch only when there is business meaning.
- **N3.** All Pydantic schemas (`RevisePostRequest`, `RevisionLogEntrySchema`,
  `RevisePostResponse`, domain entities) use
  `model_config = ConfigDict(from_attributes=True)`.
- **N4.** Every new `.py` file in this slice starts with
  `# FEATURE: revise_post — <purpose>` on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** `RevisePostUseCase` never raises `HTTPException`; only `DomainError` subclasses.
  Per `agent_docs/error_handling.md` § Use-case: raises, does not catch.
- **N6.** The slice imports nothing from another slice's `domain/`, `data/`, or
  `presentation/`; shared dependencies come only from `features/posts/_shared/` or
  `features/users/_shared/`. Per `agent_docs/architecture.md` § Layer rules.
- **N7.** All database operations in `RevisePostAdapter` are `async def` with `await`; no
  synchronous SQLAlchemy calls.
- **N8.** `mypy src/app` in strict mode passes without errors for all new files in this
  slice.
- **N9.** `ruff format src/app` and `ruff check src/app` pass without errors for all new
  files in this slice.
- **N10.** `RevisePostAdapter` explicitly inherits from `RevisePostPort` —
  `class RevisePostAdapter(RevisePostPort):` — so the port→adapter binding is greppable.
  Per `agent_docs/architecture.md` § Adapter pattern (canonical).
- **N11.** `RevisePostPort` carries the `@runtime_checkable` decorator. Per
  `agent_docs/architecture.md` § Port pattern (canonical).

## Out of scope

- Revising a post in `pending_review` or `approved` status — only `changes_requested`
  posts are revisable.
- Revising a post authored by another user — ownership is verified against the JWT.
- Updating fields other than `title` and `text` (e.g. `media_url`).
- Returning the full `PostModerationLog` history — only the log entry created by this
  revision is returned in the response.
- Notifications (email or in-app) to the moderator when a revision is submitted.
- The `pending_review` → `approved` and `pending_review` → `changes_requested` transitions
  — those are slice 0017.
- The `list_pending_posts` endpoint — that is slice 0019.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (200 cases) |
| F2 | endpoint integration test (422 case) |
| F3 | endpoint integration test (401 case) |
| F4 | use-case unit test (post not found case) |
| F5 | use-case unit test (ownership check case) |
| F6 | use-case unit test (wrong status — pending_review and approved cases) |
| F7 | use-case unit test (happy path cases) |
| F8 | adapter unit test (apply_revision — status and updated_at) |
| F9 | adapter unit test (apply_revision — title-only and text-only cases) |
| F10 | adapter unit test (apply_revision — title-only and text-only cases) |
| F11 | adapter unit test (apply_revision — log row created case) |
| F12 | adapter unit test (apply_revision — unchanged field values in result) |
| F13 | adapter unit test (get_post_by_uuid — not found case) |
| F14 | adapter unit test (get_post_by_uuid — found case) |
| F15 | endpoint integration test (200 response body assertions) |
| F1, F7, F8, F11, F15 | outside-in test (primary happy path) |
| N1–N11 | code review checklist in validation.md |
