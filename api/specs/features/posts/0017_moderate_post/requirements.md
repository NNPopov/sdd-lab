# 0017 · moderate_post — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `POST /api/v1/posts/{post_uuid}/moderate` accepts a path param
  `post_uuid: UUID` and a `ModeratePostRequest` body with fields `action` and optional
  `message`, and returns `ModeratePostResponse` with fields `post_uuid`, `status`, and
  `log_entry` at HTTP 200 on success.

- **F2.** `ModeratePostRequest` validates `action` as one of the two `Literal` values
  `"approved"` or `"changes_requested"`; any other value is rejected at the schema
  boundary with HTTP 422.

- **F3.** A `@model_validator(mode="after")` on `ModeratePostRequest` raises
  `ValueError` (→ HTTP 422) when `action = "changes_requested"` and `message` is `None`.

- **F4.** The endpoint returns HTTP 401 when no valid Bearer token is provided, enforced
  by `get_current_moderator_or_superuser` → `get_current_user`.

- **F5.** `get_current_moderator_or_superuser` in `features/users/dependencies.py`
  raises `ForbiddenException` (→ HTTP 403) when the resolved user has neither
  `is_moderator = True` nor `is_superuser = True`, and returns the full user dict
  otherwise.

- **F6.** `ModeratePostUseCase.__call__` raises `ForbiddenDomainError` when
  `command.requester_is_privileged` is `False`; `port.get_post_by_uuid` is never called
  in this case.

- **F7.** `ModeratePostUseCase.__call__` raises `NotFoundDomainError("Post not found")`
  when `port.get_post_by_uuid(command.post_uuid)` returns `None`; `port.apply_decision`
  is never called in this case.

- **F8.** `ModeratePostUseCase.__call__` raises
  `ForbiddenDomainError("Moderators may not review their own posts")` when
  `post.created_by_user_id == command.requester_user_id`.

- **F9.** `ModeratePostUseCase.__call__` raises
  `DuplicateValueDomainError("Post is already approved")` when `post.status == "approved"`.

- **F10.** `ModeratePostUseCase.__call__` raises
  `ForbiddenDomainError("A message is required when requesting changes")` when
  `command.action == "changes_requested"` and `command.message is None`.

- **F11.** When all guards pass, `ModeratePostUseCase.__call__` calls
  `port.apply_decision(post.id, post.uuid, command.action, command.requester_user_id,
  command.message)` and returns the resulting `ModeratedPostResult` unchanged.

- **F12.** `ModeratePostAdapter.get_post_by_uuid` returns `None` when no post with the
  given UUID exists in the database.

- **F13.** `ModeratePostAdapter.get_post_by_uuid` returns a `PostForModeration` with
  fields `id`, `uuid`, `status`, and `created_by_user_id` populated from the database
  row when a matching post exists.

- **F14.** `ModeratePostAdapter.apply_decision` atomically updates `Post.status` to
  `action` and `Post.updated_at` to the current UTC time, and inserts a
  `PostModerationLog` row with `event_type = "moderator_review"`, `action`, `message`,
  `post_id`, and `user_id = moderator_user_id`, all within the same session and a single
  `commit`.

- **F15.** `ModeratePostAdapter.apply_decision` returns a `ModeratedPostResult`
  populated with `post_uuid`, the new `status`, and a `ModerationLogEntry` built from
  the inserted `PostModerationLog` row including its server-generated `id` and
  `created_at`.

- **F16.** The `PostModerationLog` table is append-only; `ModeratePostAdapter` never
  issues an `UPDATE` or `DELETE` on that table.

- **F17.** The `log_entry.event_type` field in `ModeratePostResponse` is always
  `"moderator_review"`.

- **F18.** A superuser (with `is_superuser = True` and `is_moderator = False`) can
  successfully call the endpoint and receive HTTP 200.

## Non-functional requirements

- **N1.** `ModeratePostUseCase` is a class with a single public method `__call__()`;
  invoked as `await use_case(command)` per `agent_docs/architecture.md` § Use-case
  shape.

- **N2.** `ModeratePostAdapter` catches no infrastructure exceptions; no `try/except`
  block is present, because no mutation in this slice produces a business-meaningful
  `IntegrityError`; unknown failures propagate to the global handler per
  `agent_docs/error_handling.md` § Adapter: catch only when there is business meaning
  to translate.

- **N3.** All Pydantic schemas (`ModeratePostRequest`, `ModerationLogEntrySchema`,
  `ModeratePostResponse`, `PostForModeration`, `ModerationLogEntry`,
  `ModeratedPostResult`) use `model_config = ConfigDict(from_attributes=True)` per
  `agent_docs/entry_points/fastapi.md`.

- **N4.** Every new `.py` file starts with `# FEATURE: moderate_post — <purpose>` per
  `agent_docs/stable_vs_feature.md`.

- **N5.** `ModeratePostUseCase` never raises `HTTPException`; all failure paths raise
  `DomainError` subclasses per `agent_docs/error_handling.md`.

- **N6.** No imports cross slice boundaries except through the own feature's
  `_shared/`; `moderate_post` does not import from other slices' `domain/`, `data/`, or
  `presentation/` folders per `agent_docs/architecture.md` § Layer rules.

- **N7.** All database I/O is `async def` + `await`; no synchronous SQLAlchemy calls
  per CLAUDE.md § Locked technology stack.

- **N8.** `mypy src/app` strict passes for all new and modified files.

- **N9.** `ruff format src/app` and `ruff check src/app` pass for all new and modified
  files.

- **N10.** All imports inside `src/app/` use relative paths (`from ..domain...`); tests
  use absolute imports through `app.*` per `agent_docs/architecture.md` § Import
  conventions.

- **N11.** `ModeratePostAdapter` explicitly inherits from `ModeratePostPort`:
  `class ModeratePostAdapter(ModeratePostPort):` per `agent_docs/architecture.md` §
  Adapter pattern (canonical).

- **N12.** `ModeratePostPort` carries the `@runtime_checkable` decorator per
  `agent_docs/architecture.md` § Port pattern (canonical).

## Out of scope

- Transitioning an `approved` post to any other state.
- Moderating a post in `changes_requested` state (only `pending_review` posts are
  moderated through this endpoint).
- Returning the full post body (title, text, media_url) in the moderation response.
- Paginating or filtering the moderation log; only the newly created entry is returned.
- Notifications (email or in-app) to the post author.
- Bulk moderation.
- `get_current_moderator_or_superuser` gating on `list_pending_posts` — introduced here,
  reused in slice 0019.
- Rate limiting — endpoint is behind moderator/superuser auth.
- Cache invalidation — no caching currently applied to post detail reads.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (200 cases), outside-in test |
| F2 | endpoint integration test (422 — invalid action) |
| F3 | endpoint integration test (422 — missing message) |
| F4 | endpoint integration test (401 case) |
| F5 | endpoint integration test (401, 403 — unprivileged cases) |
| F6 | use-case unit test (privilege check case) |
| F7 | use-case unit test (not found case), endpoint integration test (404) |
| F8 | use-case unit test (self-review case), endpoint integration test (403 — self-review) |
| F9 | use-case unit test (already approved case), endpoint integration test (409) |
| F10 | use-case unit test (message required case) |
| F11 | use-case unit test (happy path — approve, happy path — changes_requested), outside-in test |
| F12 | adapter unit test (get_post_by_uuid — not found) |
| F13 | adapter unit test (get_post_by_uuid — found) |
| F14 | adapter unit test (apply_decision — both actions), outside-in test |
| F15 | adapter unit test (apply_decision — both actions), outside-in test |
| F16 | adapter unit test, code review |
| F17 | adapter unit test, endpoint integration test (200 cases) |
| F18 | endpoint integration test (superuser can moderate case), outside-in test |
| N1–N12 | code review checklist in validation.md |
