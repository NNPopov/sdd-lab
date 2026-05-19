# 0028 · update_post — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `PATCH /api/v1/{username}/post/{id}` accepts an `UpdatePostRequest` body with optional fields `title`, `text`, and `media_url`, and returns `UpdatePostResponse` with status `200` and `{"message": "Post updated"}` on success.
- **F2.** The endpoint requires a valid JWT bearer token; requests without a valid token receive `401 Unauthorized`.
- **F3.** The use-case raises `NotFoundDomainError("User not found")` when no active (non-soft-deleted) user exists for `target_username`.
- **F4.** The use-case raises `ForbiddenDomainError` when `requester_username` does not match the username of the resolved user.
- **F5.** The use-case raises `NotFoundDomainError("Post not found")` when no active (non-soft-deleted) post exists for `post_id`.
- **F6.** The use-case calls `port.update(command)` only after both the user existence check (F3) and the ownership check (F4) and the post existence check (F5) have passed.
- **F7.** The adapter's `get_user_by_username` returns `PostAuthor` (with `id` and `username`) when a matching active user exists, and `None` when the user is absent or soft-deleted.
- **F8.** The adapter's `get_post_by_id` returns `PostItem` when a matching active post exists, and `None` when the post is absent or soft-deleted.
- **F9.** The adapter's `update` method sets only the non-`None` content fields from the command, plus `updated_at = datetime.now(UTC)`, in the SQL `UPDATE` for the given `post_id`.
- **F10.** The `@cache` decorator on the endpoint invalidates the Redis key for `{username}_post_cache` (keyed by `id`) and the pattern `{username}_posts:*` on every successful update.
- **F11.** The endpoint returns `422 Unprocessable Entity` when a provided field fails Pydantic validation (e.g. `title` shorter than 2 characters, `media_url` not matching the URL pattern).
- **F12.** `PostAuthor` is defined in `features/posts/_shared/entities.py` and imported from there by both `create_post` and `update_post`; the local definition in `create_post/domain/entities.py` is removed.
- **F13.** The old inline `patch_post` handler in `features/posts/router.py` is deleted and replaced by `include_router(update_post_router)`.

## Non-functional requirements

- **N1.** `UpdatePostUseCase` is a class with `__call__(command: UpdatePostCommand) -> None`; called as `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** The adapter catches only business-meaningful infrastructure exceptions. The `update` method has no `try/except` (a plain update of owned content cannot raise a domain-meaningful integrity error); infrastructure failures propagate to the global handler. Per `agent_docs/error_handling.md`.
- **N3.** Pydantic schemas that are validated from ORM rows (`PostAuthor`, `PostItem`) use `model_config = ConfigDict(from_attributes=True)`. Per `agent_docs/architecture.md` § Command vs Request, Entity vs Response.
- **N4.** All new `.py` files in `src/app/` start with `# FEATURE: update_post — <purpose>`. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `UpdatePostUseCase`. Per `agent_docs/error_handling.md` § Use-case: raises, does not catch.
- **N6.** No cross-slice imports from another slice's `domain/`, `data/`, or `presentation/`. Cross-slice sharing uses `posts/_shared/`. Per `agent_docs/architecture.md` § Layer rules.
- **N7.** All database operations are `async def` with `await`; no synchronous DB calls. Per CLAUDE.md § Locked technology stack.
- **N8.** `mypy src/app` strict passes for all new and modified code. Per CLAUDE.md § Verifying changes.
- **N9.** `ruff format` and `ruff check` pass for all new and modified code. Per CLAUDE.md § Verifying changes.
- **N10.** `UpdatePostAdapter` explicitly inherits from `UpdatePostPort` (`class UpdatePostAdapter(UpdatePostPort):`). Per `agent_docs/architecture.md` § Adapter pattern (canonical).
- **N11.** `UpdatePostPort` carries the `@runtime_checkable` decorator. Per `agent_docs/architecture.md` § Port pattern (canonical).
- **N12.** The use-case input is `UpdatePostCommand` (domain type), not `UpdatePostRequest` (HTTP type); the router converts at the boundary. Per `agent_docs/architecture.md` § Command vs Request, Entity vs Response.
- **N13.** The router module path is added to `Container.wiring_config.modules`; omitting it causes `Provide[...]` to silently resolve to the provider sentinel. Per `agent_docs/entry_points/fastapi.md` § Dependency injection at the endpoint.

## Out of scope

- Migrating `erase_post` or `erase_db_post` to the vertical slice pattern.
- Returning the updated post in the PATCH response (CQRS: read-back via `GET`).
- Changing the post `status` field via this endpoint.
- Rate limiting on this endpoint.
- Removing `PostUpdate` or `PostUpdateInternal` from `features/posts/schemas.py`.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2 | endpoint integration test (missing/invalid token → 401) |
| F3 | use-case unit test; endpoint integration test (404 for unknown username) |
| F4 | use-case unit test; endpoint integration test (403 for wrong user) |
| F5 | use-case unit test; endpoint integration test (404 for unknown post) |
| F6 | use-case unit test (assert `port.update` not called when checks fail) |
| F7 | adapter unit test |
| F8 | adapter unit test |
| F9 | adapter unit test (assert DB row fields and `updated_at` after update) |
| F10 | endpoint integration test (verify cache invalidation via GET after PATCH) |
| F11 | endpoint integration test (422 for invalid field values) |
| F12 | code review; mypy (import path change) |
| F13 | code review; smoke test (`tests/smoke/test_app_starts.py`) |
| N1–N13 | code review checklist in `validation.md` |
