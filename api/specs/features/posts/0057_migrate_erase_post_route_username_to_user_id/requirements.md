# 0057 · migrate_erase_post_route_username_to_user_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `DELETE /api/v1/{user_id}/post/{id}` takes no request body and returns HTTP 200 with an `ErasePostResponse` body (`{"message": "Post deleted"}`) when the authenticated requester is the target user and the owner-scoped post exists.
- **F2.** The `ErasePostResponse` shape is unchanged: a single `message: str` field.
- **F3.** When the request has no or invalid credentials, the endpoint returns HTTP 401 via the `get_current_user` dependency (the use-case is not reached).
- **F4.** When `user_id` matches no active user (unknown id or soft-deleted), `ErasePostUseCase` raises `NotFoundDomainError("User not found")`, translated to HTTP 404.
- **F5.** When the author is resolved but the authenticated requester is not that author (`requester_user_id != user.id`), `check_post_owner` raises a bare `ForbiddenDomainError()`, translated to HTTP 403.
- **F6.** When the author is resolved and ownership passes but `find_post(post_id, owner_id=user.id)` returns `None`, `ErasePostUseCase` raises `NotFoundDomainError("Post not found")`, translated to HTTP 404.
- **F7.** The use-case preserves the 404(user) → 403(owner) → 404(post) ordering: the author is resolved first, ownership is checked second, the owner-scoped post is fetched third, the soft delete runs last.
- **F8.** When the user lookup returns `None`, neither `find_post` nor `soft_delete` is called; when ownership fails, neither `find_post` nor `soft_delete` is called; when the post fetch returns `None`, `soft_delete` is not called.
- **F9.** FastAPI rejects a request whose `{user_id}` path segment is not a valid integer with HTTP 422.
- **F10.** The old `/{username}/post/{id}` URL is gone: calling `DELETE /api/v1/<non-integer-string>/post/{id}` returns HTTP 422 because the author path parameter is now typed `int`.
- **F11.** `ErasePostCommand` exposes `user_id: int`, `post_id: int`, and `requester_user_id: int`; the former field `username: str` no longer exists. `post_id` and `requester_user_id` are unchanged from slice 0055.
- **F12.** `ErasePostAdapter` and `ErasePostPort` are unchanged — `find_post(post_id: int, owner_id: int)` and `soft_delete(post_id: int)` read only `post_id` and the integer `owner_id` and never referenced `username`.
- **F13.** The `erase_post` router reads `user_id: int` and `id: int` from the path and constructs `ErasePostCommand` with `user_id=user_id`, `post_id=id`, and `requester_user_id=current_user["id"]`.
- **F14.** The `@cache` decorator on the endpoint uses `key_prefix="{user_id}_post_cache"` and `to_invalidate_extra={"{user_id}_posts": "{user_id}"}`, with `resource_id_name="id"` unchanged; the former `{username}_…` keys no longer appear, and the `to_invalidate_extra` dict form (not `pattern_to_invalidate_extra`) is preserved.
- **F15.** A successful delete invalidates the `{user_id}_post_cache` single-post entry and the `{user_id}_posts` list entries, so a read immediately after a delete returns HTTP 404 (no stale read), realigning with `get_post` (0054) and `list_posts` (0042).
- **F16.** The 403 carries no message (bare `ForbiddenDomainError()`); this is unchanged from slice 0055 (no message change in this slice).
- **F17.** The use-case resolves the author via the shared `get_active_user_by_id` and delegates ownership to the shared `check_post_owner`; it no longer calls `get_active_user_by_username`.
- **F18.** The owner-scoped post fetch is preserved: `find_post` is given `owner_id=user.id`, so a post not owned by `user_id` is reported as 404 "Post not found".

## Non-functional requirements

- **N1.** `ErasePostUseCase` is a class with `__call__()`; called as `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `ErasePostAdapter` (unchanged) keeps its behaviour; no new `try/except` is introduced. Business-meaningful infrastructure exceptions would map to a `DomainError`; other infrastructure exceptions propagate to the global handler. The adapter does not log. Per `agent_docs/error_handling.md`.
- **N3.** Pydantic schemas use `model_config = ConfigDict(from_attributes=True)` for types built from ORM rows. Per `CLAUDE.md` locked stack.
- **N4.** All modified files retain their `# FEATURE: <slice> — …` header on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `ErasePostUseCase` or `ErasePostAdapter`; the only domain errors raised are `NotFoundDomainError` and (via `check_post_owner`) `ForbiddenDomainError`, existing STABLE subclasses. Per `CLAUDE.md` rule 1.
- **N6.** No cross-slice imports; `erase_post` imports only its own files, the feature's `_shared/`, and STABLE layers (`adapters/`, `core/`, `domain/`). Per `CLAUDE.md` rule 7 and `agent_docs/architecture.md` § Layer rules.
- **N7.** All I/O in `ErasePostAdapter` is `async def` + `await`; no synchronous DB calls. Per `CLAUDE.md` locked stack.
- **N8.** `ErasePostAdapter` inherits explicitly from `ErasePostPort` (`class ErasePostAdapter(ErasePostPort):`). Per `agent_docs/architecture.md` § Terminology: port and adapter.
- **N9.** `ErasePostPort` and the shared `UserLookupPort` carry the `@runtime_checkable` decorator and inherit `typing.Protocol`. Per `agent_docs/architecture.md` § Port pattern.
- **N10.** All imports inside `src/app/` are relative (`from .....domain…`, `from ..._shared…`); tests use absolute `from app…`. Per `agent_docs/architecture.md` § Import conventions.
- **N11.** `mypy src/app` strict passes with no new errors introduced by this slice.
- **N12.** `ruff format` and `ruff check` pass with no new violations; the import-linter architecture contracts still pass; the full suite (including `tests/smoke/test_app_starts.py`) has zero net-new failures relative to the pre-change baseline.

## Out of scope

- Migrating the `erase_db_post` route — a separate slice (superuser hard delete); not touched here. It remains the only `{username}` post route and the only remaining consumer of `get_active_user_by_username` after this slice.
- Modifying the shared `posts/_shared` helpers — `get_active_user_by_id` and the id-based `check_post_owner` already exist (introduced by 0055); used, not modified.
- Removing `get_active_user_by_username` from `UserLookupPort`/`UserLookupAdapter` — deferred to the final cleanup slice (still needed by `erase_db_post`).
- `get_post` (slice 0054), `create_post` (slice 0055), `update_post` (slice 0056), and `list_posts` (slice 0042) — already migrated.
- Changing the ownership mechanism or adding a user-facing 403 message — already id-based and message-less since 0055.
- Changing the post `id` to a UUID.
- ORM model change or Alembic migration (`Post.created_by_user_id` already exists).
- Flutter client changes (separate working dir).

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (200 owner); use-case unit test (happy path); outside-in test |
| F2 | endpoint integration test (response body); outside-in test |
| F3 | endpoint integration test (401 unauthenticated) |
| F4 | endpoint integration test (404 unknown user); use-case unit test (user not found) |
| F5 | endpoint integration test (403 non-owner); use-case unit test (not owner) |
| F6 | endpoint integration test (404 unknown post); use-case unit test (post not found) |
| F7 | use-case unit test (ordering: lookup → ownership → post fetch); endpoint integration test (404 vs 403) |
| F8 | use-case unit test (downstream ports never called on each failure branch) |
| F9 | endpoint integration test (422 non-integer user_id) |
| F10 | endpoint integration test (old string route → 422); outside-in test |
| F11 | use-case unit test (command fields); mypy |
| F12 | existing 0029 adapter test (unchanged); use-case unit test (find_post / soft_delete receive ints) |
| F13 | endpoint integration test (requester resolution); outside-in test |
| F14 | endpoint integration test (cache invalidation); code review |
| F15 | endpoint integration test (read-after-delete → 404); outside-in test (GET after DELETE → 404) |
| F16 | endpoint integration test (403 carries no message) |
| F17 | use-case unit test (get_active_user_by_id + check_post_owner used; no username lookup) |
| F18 | use-case unit test (find_post called with owner_id); endpoint integration test (404 unknown post) |
| N1–N12 | code review checklist in validation.md |
