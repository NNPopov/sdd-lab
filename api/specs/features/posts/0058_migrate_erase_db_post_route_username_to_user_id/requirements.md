# 0058 · migrate_erase_db_post_route_username_to_user_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `DELETE /api/v1/{user_id}/db_post/{id}` returns HTTP 200 with an `EraseDbPostResponse` body (`{"message": "Post deleted from the database"}`) when the authenticated caller is a superuser, the `user_id` resolves to an active user, and the post exists and is owned by that user.
- **F2.** The `EraseDbPostResponse` shape is unchanged: a single `message: str` field.
- **F3.** When the request has no or invalid credentials, the endpoint returns HTTP 401 via the `get_current_superuser` dependency (the use-case is not reached).
- **F4.** When the authenticated caller is not a superuser, the endpoint returns HTTP 403 via the `get_current_superuser` dependency (the use-case is not reached); no `ForbiddenDomainError` is raised by the use-case.
- **F5.** When `user_id` matches no active user (unknown id or soft-deleted), `EraseDbPostUseCase` raises `NotFoundDomainError("User not found")`, translated to HTTP 404.
- **F6.** When the user resolves but `find_post(post_id, owner_id=user.id)` returns `None` (post absent, soft-deleted, or not owned by `user_id`), `EraseDbPostUseCase` raises `NotFoundDomainError("Post not found")`, translated to HTTP 404.
- **F7.** The use-case preserves the 404(user) → 404(post) ordering: the author is resolved first, the owner-scoped post is fetched second, the hard delete runs last; there is no ownership branch in the use-case.
- **F8.** When the user lookup returns `None`, neither `find_post` nor `hard_delete` is called; when the post fetch returns `None`, `hard_delete` is not called.
- **F9.** FastAPI rejects a request whose `{user_id}` path segment is not a valid integer with HTTP 422.
- **F10.** The old `/{username}/db_post/{id}` URL is gone: calling `DELETE /api/v1/<non-integer-string>/db_post/{id}` returns HTTP 422 because the author path parameter is now typed `int`.
- **F11.** `EraseDbPostCommand` exposes `user_id: int` and `post_id: int`; the former field `username: str` no longer exists; there is no requester field.
- **F12.** `EraseDbPostAdapter` is unchanged — `find_post(post_id: int, owner_id: int)` and `hard_delete(post_id: int)` read only `post_id` and the integer `owner_id` and never referenced `username`.
- **F13.** The `erase_db_post` router reads `user_id: int` and `id: int` from the path and constructs `EraseDbPostCommand(user_id=user_id, post_id=id)`; the auth dependency stays `get_current_superuser`.
- **F14.** The `@cache` decorator on the endpoint uses `key_prefix="{user_id}_post_cache"` and `to_invalidate_extra={"{user_id}_posts": "{user_id}"}`, with `resource_id_name="id"` unchanged; the former `{username}_…` keys no longer appear.
- **F15.** A successful hard delete invalidates the `{user_id}_post_cache` single-post entry and the `{user_id}_posts` list entries, so a read immediately after a delete returns HTTP 404 (no stale read), realigning with `get_post` (0054) and `list_posts` (0042).
- **F16.** The endpoint performs no per-post ownership check: a superuser may hard-delete any user's post; authorization is the superuser gate only.
- **F17.** The use-case resolves the author via the shared `get_active_user_by_id` and no longer calls `get_active_user_by_username`; after this slice `get_active_user_by_username` has no remaining consumer.
- **F18.** The `hard_delete` moderation-log cascade behaviour established in slice 0031 is preserved unchanged: hard-deleting a post with associated moderation logs succeeds without violating a foreign-key constraint.

## Non-functional requirements

- **N1.** `EraseDbPostUseCase` is a class with `__call__()`; called as `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `EraseDbPostAdapter` (unchanged) keeps its delete-path behaviour; no new `try/except` is introduced. Business-meaningful infrastructure exceptions would map to a `DomainError`; other infrastructure exceptions propagate to the global handler. The adapter does not log. Per `agent_docs/error_handling.md`.
- **N3.** Pydantic schemas use `model_config = ConfigDict(from_attributes=True)` for types built from ORM rows. Per `CLAUDE.md` locked stack.
- **N4.** All modified files retain their `# FEATURE: <slice> — …` header on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `EraseDbPostUseCase` or `EraseDbPostAdapter`; the only domain errors raised are `NotFoundDomainError`, an existing STABLE subclass. Per `CLAUDE.md` rule 1.
- **N6.** No cross-slice imports; `erase_db_post` imports only its own files, the feature's `_shared/`, and STABLE layers (`adapters/`, `core/`, `domain/`). Per `CLAUDE.md` rule 7 and `agent_docs/architecture.md` § Layer rules.
- **N7.** All I/O in `EraseDbPostAdapter` is `async def` + `await`; no synchronous DB calls. Per `CLAUDE.md` locked stack.
- **N8.** `EraseDbPostAdapter` inherits explicitly from `EraseDbPostPort` (`class EraseDbPostAdapter(EraseDbPostPort):`). Per `agent_docs/architecture.md` § Terminology: port and adapter.
- **N9.** `EraseDbPostPort` and the shared `UserLookupPort` carry the `@runtime_checkable` decorator and inherit `typing.Protocol`. Per `agent_docs/architecture.md` § Port pattern.
- **N10.** All imports inside `src/app/` are relative (`from .....domain…`, `from ..._shared…`); tests use absolute `from app…`. Per `agent_docs/architecture.md` § Import conventions.
- **N11.** `mypy src/app` strict passes with no new errors introduced by this slice.
- **N12.** `ruff format` and `ruff check` pass with no new violations; the import-linter architecture contracts still pass; the full suite has zero net-new failures relative to the pre-change baseline.

## Out of scope

- Removing `get_active_user_by_username` from `UserLookupPort`/`UserLookupAdapter` and updating its adapter test (`tests/features/posts/0032_extract_user_lookup/`) — that is the cleanup slice's job; this slice only removes the last caller.
- Adding a per-post ownership check — `erase_db_post` is superuser-only by design; no ownership check is added.
- The `find_post` soft-delete filter and the `hard_delete` moderation-log cascade — preserved exactly as established in slices 0030 / 0031.
- `get_post` (slice 0054), `create_post` (slice 0055), `update_post` (slice 0056), `erase_post` (slice 0057), and `list_posts` (slice 0042) — already migrated.
- Changing the post `id` to a UUID — frozen; the integer `id` is retained.
- ORM model change or Alembic migration (`Post.created_by_user_id` already exists).
- Flutter client changes (separate working dir).

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (200 superuser); use-case unit test (happy path); outside-in test |
| F2 | endpoint integration test (response body); outside-in test |
| F3 | endpoint integration test (401 unauthenticated) |
| F4 | endpoint integration test (403 non-superuser) |
| F5 | endpoint integration test (404 unknown user); use-case unit test (user not found) |
| F6 | endpoint integration test (404 unknown post); use-case unit test (post not found / not owned) |
| F7 | use-case unit test (ordering: lookup → post fetch → hard delete) |
| F8 | use-case unit test (downstream ports never called on each failure branch) |
| F9 | endpoint integration test (422 non-integer user_id) |
| F10 | endpoint integration test (old string route → 422); outside-in test |
| F11 | use-case unit test (command fields); mypy |
| F12 | existing 0030/0031 adapter tests (unchanged); use-case unit test (hard_delete receives post_id) |
| F13 | endpoint integration test (request wiring); outside-in test |
| F14 | endpoint integration test (cache invalidation); code review |
| F15 | endpoint integration test (read-after-delete returns 404); outside-in test (GET → 404 after delete) |
| F16 | endpoint integration test (200 superuser deletes another user's post); code review |
| F17 | use-case unit test (get_active_user_by_id used; no username lookup) |
| F18 | existing 0031 adapter/cascade test (unchanged); outside-in test (delete succeeds) |
| N1–N12 | code review checklist in validation.md |
</content>
