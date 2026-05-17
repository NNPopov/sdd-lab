# 0019 · list_pending_posts — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `GET /api/v1/posts/pending` accepts `page` (int, default 1, ge=1)
  and `items_per_page` (int, default 10, ge=1, le=100) query parameters and
  returns `ListPendingPostsResponse` with HTTP 200 on success.
- **F2.** The response body contains `items` (list of `PendingPostItemSchema`),
  `total_count` (int), `page` (int), and `items_per_page` (int).
- **F3.** Each `PendingPostItemSchema` contains `post_uuid`, `title`, `text`,
  `media_url` (nullable), `status`, `created_at`, `updated_at` (nullable),
  `author_username`, and `moderation_log` (list of
  `PendingModerationLogEntrySchema`).
- **F4.** Each `PendingModerationLogEntrySchema` contains `id`, `event_type`,
  `action` (nullable), `message` (nullable), and `created_at`.
- **F5.** Only posts with `status` equal to `pending_review` or
  `changes_requested` appear in the response; posts with any other status are
  excluded.
- **F6.** Posts with `is_deleted = True` are excluded from results and from
  `total_count`.
- **F7.** Posts whose author has `is_deleted = True` are excluded from results
  and from `total_count`.
- **F8.** Posts are ordered by `Post.created_at` descending (newest first).
- **F9.** Moderation log entries within each item are ordered by
  `PostModerationLog.created_at` ascending (oldest first).
- **F10.** `author_username` is resolved via a SQL JOIN between `Post` and
  `User` on `Post.created_by_user_id = User.id`.
- **F11.** When no pending posts exist the endpoint returns HTTP 200 with
  `items = []` and `total_count = 0`.
- **F12.** `page` and `items_per_page` parameters control pagination via SQL
  `OFFSET = (page - 1) * items_per_page` and `LIMIT = items_per_page`; only
  the posts for the requested page appear in `items`.
- **F13.** `total_count` reflects the total number of matching posts before
  pagination is applied.
- **F14.** `ListPendingPostsUseCase.__call__` raises `ForbiddenDomainError`
  when `query.requester_is_privileged` is `False`.
- **F15.** An unauthenticated request (missing or invalid Bearer token) receives
  HTTP 401 before the use-case is invoked.
- **F16.** An authenticated request from a user who is neither a moderator nor
  a superuser receives HTTP 403.
- **F17.** An authenticated request from a moderator receives HTTP 200.
- **F18.** An authenticated request from a superuser receives HTTP 200.
- **F19.** `GET /api/v1/posts/pending?page=0` returns HTTP 422.
- **F20.** `GET /api/v1/posts/pending?items_per_page=101` returns HTTP 422.
- **F21.** The adapter performs exactly two database queries per call: one
  count + paginated posts query and one bulk log query; it does not issue
  a separate query per post (no N+1).

## Non-functional requirements

- **N1.** `ListPendingPostsUseCase` is a class with a single public method
  `__call__()`; it is invoked as `await use_case(query)`. Per
  `agent_docs/architecture.md` § Use-case shape.
- **N2.** `ListPendingPostsAdapter` catches no exceptions; all infrastructure
  failures propagate to the global `_catch_all` handler. Per
  `agent_docs/error_handling.md` § Right shape: read-only query, no catch.
- **N3.** All Pydantic response schemas use
  `model_config = ConfigDict(from_attributes=True)`. Per `CLAUDE.md`
  Locked technology stack.
- **N4.** Every new `.py` file starts with `# FEATURE: list_pending_posts — <purpose>`.
  Per `agent_docs/stable_vs_feature.md`.
- **N5.** `ListPendingPostsUseCase` never raises `HTTPException`; it raises
  `ForbiddenDomainError` only. Per `CLAUDE.md` Universal hard rule 1.
- **N6.** No cross-slice imports; domain entities defined in this slice's
  `domain/entities.py` are not imported from or into any other slice. Per
  `CLAUDE.md` Universal hard rule 7.
- **N7.** All database operations in `ListPendingPostsAdapter` are `async def`
  with `await`. Per `CLAUDE.md` Locked technology stack.
- **N8.** `mypy src/app` (strict) passes for all new code. Per `CLAUDE.md`
  Verifying changes.
- **N9.** `ruff format src/app` and `ruff check src/app` pass for all new
  code. Per `CLAUDE.md` Verifying changes.
- **N10.** `ListPendingPostsAdapter` explicitly inherits from
  `ListPendingPostsPort` in its class declaration. Per
  `agent_docs/architecture.md` § Adapter pattern (canonical).
- **N11.** `ListPendingPostsPort` carries the `@runtime_checkable` decorator.
  Per `agent_docs/architecture.md` § Port pattern (canonical).
- **N12.** All imports inside `src/app/` are relative; absolute imports via
  `app.*` are used only in `tests/`. Per `agent_docs/architecture.md` §
  Import conventions.
- **N13.** `domain/` files import only stdlib and pydantic; no imports from
  `adapters/`, `core/`, or `features/`. Per `CLAUDE.md` Universal hard rule 2.

## Out of scope

- Filtering the queue by status (only `pending_review` or only
  `changes_requested`).
- Sorting options other than `Post.created_at DESC`.
- Searching or filtering by author username.
- Pagination on the per-post moderation log within each item.
- Caching the pending queue.
- Any changes to the `approved` terminal state.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2 | endpoint integration test |
| F3 | endpoint integration test |
| F4 | endpoint integration test |
| F5 | adapter unit test; endpoint integration test |
| F6 | adapter unit test; endpoint integration test |
| F7 | adapter unit test |
| F8 | adapter unit test |
| F9 | adapter unit test; outside-in test |
| F10 | adapter unit test; endpoint integration test |
| F11 | adapter unit test; endpoint integration test |
| F12 | adapter unit test |
| F13 | adapter unit test |
| F14 | use-case unit test |
| F15 | endpoint integration test |
| F16 | endpoint integration test |
| F17 | endpoint integration test; outside-in test |
| F18 | endpoint integration test |
| F19 | endpoint integration test |
| F20 | endpoint integration test |
| F21 | adapter unit test (count of queries via query logging or fixture inspection) |
| N1–N13 | code review checklist in validation.md |
