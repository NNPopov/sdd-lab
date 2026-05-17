# 0024 · get_moderation_log — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `GET /api/v1/posts/{post_uuid}/moderation-log` accepts a
  `post_uuid` UUID path parameter from an authenticated caller and returns
  `GetModerationLogResponse` with status `200 OK` on success.
- **F2.** A request without a valid Bearer token receives HTTP `401 Unauthorized`
  (raised by `get_current_user` before the use-case is reached).
- **F3.** The use-case raises `NotFoundDomainError` (→ HTTP 404) when no post with
  the given UUID exists in the database.
- **F4.** The use-case raises `NotFoundDomainError` (→ HTTP 404) when a post with the
  given UUID exists but has `is_deleted = True`.
- **F5.** The use-case raises `ForbiddenDomainError` (→ HTTP 403) when the requester
  satisfies none of: `requester_user_id == post.created_by_user_id`,
  `requester_is_moderator == True`, `requester_is_superuser == True`.
- **F6.** The use-case permits access when `requester_user_id == post.created_by_user_id`
  (the requester is the post's author), regardless of moderator or superuser status.
- **F7.** The use-case permits access when `requester_is_moderator == True`, regardless
  of authorship.
- **F8.** The use-case permits access when `requester_is_superuser == True`, regardless
  of authorship.
- **F9.** The use-case permits access when the requester is both the post's author and
  a moderator (reading the log is not a conflict of interest).
- **F10.** When no `PostModerationLog` entries exist for the post, the endpoint returns
  HTTP `200 OK` with `GetModerationLogResponse(items=[])`.
- **F11.** Log entries are returned ordered ascending by `created_at` (oldest entry first).
- **F12.** Each `ModerationLogEntrySchema` in the response includes the fields `id`,
  `event_type`, `action`, `message`, `created_at`, `actor_user_id`, and `actor_username`.
- **F13.** `actor_username` in each log entry is resolved from the `User` table via a
  JOIN on `PostModerationLog.user_id = User.id` in the adapter query.
- **F14.** The adapter's `get_post_by_uuid` method returns `None` (not an exception)
  when no matching non-deleted post is found; the use-case translates `None` into
  `NotFoundDomainError`.

## Non-functional requirements

- **N1.** `GetModerationLogUseCase` is a class with a single `__call__(command)` method;
  called as `await use_case(query)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `GetModerationLogAdapter` contains no `try/except` blocks — its two methods are
  read-only queries with no business-meaningful exception paths; all infrastructure
  exceptions propagate to the global handler. Per `agent_docs/error_handling.md` §
  Right shape: read-only query, no catch.
- **N3.** All Pydantic response schemas (`ModerationLogEntrySchema`,
  `GetModerationLogResponse`) use `model_config = ConfigDict(from_attributes=True)`.
  Per `agent_docs/entry_points/fastapi.md` § Request and Response schemas.
- **N4.** Every new `.py` file in the slice starts with
  `# FEATURE: get_moderation_log — <purpose>` on line 1.
  Per `agent_docs/stable_vs_feature.md`.
- **N5.** `GetModerationLogUseCase` never raises `HTTPException`; it raises only
  `NotFoundDomainError` and `ForbiddenDomainError`.
  Per `agent_docs/error_handling.md` § Use-case: raises, does not catch.
- **N6.** No imports from another slice's `domain/`, `data/`, or `presentation/`;
  shared types are defined fresh in this slice's `domain/entities.py`.
  Per `agent_docs/architecture.md` § Cross-slice imports go through `_shared/`.
- **N7.** All database calls use `async def` and `await`; no synchronous SQLAlchemy calls.
  Per `CLAUDE.md` § Locked technology stack.
- **N8.** `mypy src/app` passes with no new errors introduced by this slice.
  Per `CLAUDE.md` § Verifying changes.
- **N9.** `ruff format src/app` and `ruff check src/app` pass with no new violations.
  Per `CLAUDE.md` § Verifying changes.
- **N10.** All imports inside `src/app/` are relative; absolute imports (`from app.*` or
  `from src.app.*`) are forbidden in source files.
  Per `agent_docs/architecture.md` § Import conventions.

## Out of scope

- Pagination or filtering of the moderation log.
- Filtering entries by `event_type`, `action`, or date range.
- Exposing the log to unauthenticated users, even for approved posts.
- A notification or badge system to alert authors when new log entries appear.
- Caching the moderation log response.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2 | endpoint integration test |
| F3 | use-case unit test; endpoint integration test |
| F4 | use-case unit test; adapter unit test; endpoint integration test |
| F5 | use-case unit test; endpoint integration test |
| F6 | use-case unit test; endpoint integration test |
| F7 | use-case unit test; endpoint integration test |
| F8 | use-case unit test; endpoint integration test |
| F9 | use-case unit test |
| F10 | use-case unit test; endpoint integration test; outside-in test |
| F11 | adapter unit test; outside-in test |
| F12 | endpoint integration test; outside-in test |
| F13 | adapter unit test |
| F14 | use-case unit test; adapter unit test |
| N1–N10 | code review checklist in validation.md |
