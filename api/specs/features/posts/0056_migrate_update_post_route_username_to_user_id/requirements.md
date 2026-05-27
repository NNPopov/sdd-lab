# 0056 · migrate_update_post_route_username_to_user_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `PATCH /api/v1/{user_id}/post/{id}` accepts an `UpdatePostRequest` (optional `title`, `text`, `media_url`) and returns HTTP 200 with an `UpdatePostResponse` body (`{"message": "Post updated"}`) when the authenticated requester is the target user and the post exists.
- **F2.** The `UpdatePostRequest` shape and validation are unchanged from slice 0028: `title` 2–30 chars, `text` 1–63206 chars, `media_url` matches the URL pattern, all optional, `extra="forbid"`; a body violating these returns HTTP 422.
- **F3.** The `UpdatePostResponse` shape is unchanged: a single `message: str` field.
- **F4.** When the request has no or invalid credentials, the endpoint returns HTTP 401 via the `get_current_user` dependency (the use-case is not reached).
- **F5.** When `target_user_id` matches no active user (unknown id or soft-deleted), `UpdatePostUseCase` raises `NotFoundDomainError("User not found")`, translated to HTTP 404.
- **F6.** When the author is resolved but the authenticated requester is not that author (`requester_user_id != author.id`), `check_post_owner` raises a bare `ForbiddenDomainError()`, translated to HTTP 403.
- **F7.** When the author is resolved and ownership passes but `get_post_by_id(post_id)` returns `None`, `UpdatePostUseCase` raises `NotFoundDomainError("Post not found")`, translated to HTTP 404.
- **F8.** The use-case preserves the 404(user) → 403(owner) → 404(post) ordering: the author is resolved first, ownership is checked second, the post is fetched third, the update runs last.
- **F9.** When the user lookup returns `None`, neither `get_post_by_id` nor `update` is called; when ownership fails, neither `get_post_by_id` nor `update` is called; when the post fetch returns `None`, `update` is not called.
- **F10.** FastAPI rejects a request whose `{user_id}` path segment is not a valid integer with HTTP 422.
- **F11.** The old `/{username}/post/{id}` URL is gone: calling `PATCH /api/v1/<non-integer-string>/post/{id}` returns HTTP 422 because the author path parameter is now typed `int`.
- **F12.** `UpdatePostCommand` exposes `target_user_id: int` and `requester_user_id: int`; the former fields `target_username: str` and `requester_username: str` no longer exist. `post_id`, `title`, `text`, `media_url` are unchanged.
- **F13.** `UpdatePostAdapter` is unchanged — `get_post_by_id(post_id: int)` and `update(command)` read only `post_id` and the content fields and never referenced the renamed author fields.
- **F14.** The `update_post` router reads `user_id: int` and `id: int` from the path and constructs `UpdatePostCommand` with `target_user_id=user_id`, `requester_user_id=current_user["id"]`, `post_id=id`, and `**body.model_dump()`.
- **F15.** The `@cache` decorator on the endpoint uses `key_prefix="{user_id}_post_cache"` and `pattern_to_invalidate_extra=["{user_id}_posts:*"]`, with `resource_id_name="id"` unchanged; the former `{username}_…` keys no longer appear.
- **F16.** A successful update invalidates the `{user_id}_post_cache` single-post entry and the `{user_id}_posts:*` list entries, so a read immediately after an update returns the updated content (no stale read), realigning with `get_post` (0054) and `list_posts` (0042).
- **F17.** The previous `update_post`-specific 403 message ("You can only update your own posts") is removed; the 403 now carries no message (bare `ForbiddenDomainError()`), matching `create_post` and `erase_post`.
- **F18.** The pre-existing no-owner-filter gap is preserved: `get_post_by_id(post_id)` fetches by post id only and is not given an owner filter by this slice.
- **F19.** The use-case resolves the author via the shared `get_active_user_by_id` and delegates ownership to the shared `check_post_owner`; it no longer calls `get_active_user_by_username` and no longer performs an inline username comparison.

## Non-functional requirements

- **N1.** `UpdatePostUseCase` is a class with `__call__()`; called as `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `UpdatePostAdapter` (unchanged) keeps its write-path behaviour; no new `try/except` is introduced. Business-meaningful infrastructure exceptions would map to a `DomainError`; other infrastructure exceptions propagate to the global handler. The adapter does not log. Per `agent_docs/error_handling.md`.
- **N3.** Pydantic schemas use `model_config = ConfigDict(from_attributes=True)` for types built from ORM rows. Per `CLAUDE.md` locked stack.
- **N4.** All modified files retain their `# FEATURE: <slice> — …` header on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `UpdatePostUseCase` or `UpdatePostAdapter`; the only domain errors raised are `NotFoundDomainError` and (via `check_post_owner`) `ForbiddenDomainError`, existing STABLE subclasses. Per `CLAUDE.md` rule 1.
- **N6.** No cross-slice imports; `update_post` imports only its own files, the feature's `_shared/`, and STABLE layers (`adapters/`, `core/`, `domain/`). Per `CLAUDE.md` rule 7 and `agent_docs/architecture.md` § Layer rules.
- **N7.** All I/O in `UpdatePostAdapter` is `async def` + `await`; no synchronous DB calls. Per `CLAUDE.md` locked stack.
- **N8.** `UpdatePostAdapter` inherits explicitly from `UpdatePostPort` (`class UpdatePostAdapter(UpdatePostPort):`). Per `agent_docs/architecture.md` § Terminology: port and adapter.
- **N9.** `UpdatePostPort` and the shared `UserLookupPort` carry the `@runtime_checkable` decorator and inherit `typing.Protocol`. Per `agent_docs/architecture.md` § Port pattern.
- **N10.** All imports inside `src/app/` are relative (`from .....domain…`, `from ..._shared…`); tests use absolute `from app…`. Per `agent_docs/architecture.md` § Import conventions.
- **N11.** `mypy src/app` strict passes with no new errors introduced by this slice.
- **N12.** `ruff format` and `ruff check` pass with no new violations; the import-linter architecture contracts still pass; the full suite (including `tests/smoke/test_app_starts.py`) has zero net-new failures relative to the pre-change baseline.

## Out of scope

- Migrating the `erase_post` (route) and `erase_db_post` routes — separate slices; `erase_post` was already adapted to the id-based policy by slice 0055 and is not touched here.
- Modifying the shared `posts/_shared` helpers — `get_active_user_by_id` and the id-based `check_post_owner` already exist (introduced by 0055); used, not modified.
- Removing `get_active_user_by_username` from `UserLookupPort`/`UserLookupAdapter` — deferred to the final cleanup slice.
- `get_post` (slice 0054), `create_post` (slice 0055), and `list_posts` (slice 0042) — already migrated.
- Adding an owner filter to `get_post_by_id` — the pre-existing gap is intentionally preserved.
- Adding a user-facing 403 message.
- Changing the post `id` to a UUID.
- ORM model change or Alembic migration (`Post.created_by_user_id` already exists).
- Flutter client changes (separate working dir).

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (200 owner); use-case unit test (happy path); outside-in test |
| F2 | endpoint integration test (422 invalid body) |
| F3 | endpoint integration test (response body); outside-in test |
| F4 | endpoint integration test (401 unauthenticated) |
| F5 | endpoint integration test (404 unknown user); use-case unit test (user not found) |
| F6 | endpoint integration test (403 non-owner); use-case unit test (not owner) |
| F7 | endpoint integration test (404 unknown post); use-case unit test (post not found) |
| F8 | use-case unit test (ordering: lookup → ownership → post fetch); endpoint integration test (404 vs 403) |
| F9 | use-case unit test (downstream ports never called on each failure branch) |
| F10 | endpoint integration test (422 non-integer user_id) |
| F11 | endpoint integration test (old string route → 422); outside-in test |
| F12 | use-case unit test (command fields); mypy |
| F13 | existing 0028 adapter test (unchanged); use-case unit test (update receives command) |
| F14 | endpoint integration test (requester resolution); outside-in test |
| F15 | endpoint integration test (cache invalidation); code review |
| F16 | endpoint integration test (read-after-update no stale); outside-in test (GET reflects updated title) |
| F17 | endpoint integration test (403 carries no message) |
| F18 | code review (no owner filter added to get_post_by_id) |
| F19 | use-case unit test (get_active_user_by_id + check_post_owner used; no username comparison) |
| N1–N12 | code review checklist in validation.md |
