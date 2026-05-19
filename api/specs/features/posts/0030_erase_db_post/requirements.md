# 0030 · erase_db_post — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `DELETE /api/v1/{username}/db_post/{id}` returns HTTP 200 with body
  `{"message": "Post deleted from the database"}` when called by a superuser,
  `username` resolves to an active (non-soft-deleted) user, and `id` identifies
  a non-soft-deleted post owned by that user.
- **F2.** `EraseDbPostUseCase.__call__` raises `NotFoundDomainError("User not found")`
  when `EraseDbPostPort.get_user_by_username` returns `None`.
- **F3.** `EraseDbPostUseCase.__call__` raises `NotFoundDomainError("Post not found")`
  when the user is found but `EraseDbPostPort.find_post` returns `None`.
- **F4.** When both existence checks pass, `EraseDbPostUseCase.__call__` calls
  `EraseDbPostPort.hard_delete(post_id)` and returns `None` without raising.
- **F5.** `EraseDbPostAdapter.get_user_by_username` returns a `PostAuthor` when the
  user exists and `is_deleted` is `False`; returns `None` when the user does not
  exist or `is_deleted` is `True`.
- **F6.** `EraseDbPostAdapter.find_post` returns an `EraseDbPostRecord` when a post
  with the given `id` exists, its `created_by_user_id` matches `owner_id`, and
  `is_deleted` is `False`; returns `None` in all other cases (post absent, owned
  by a different user, or soft-deleted).
- **F7.** `EraseDbPostAdapter.hard_delete` permanently removes the post row from the
  database; the row does not exist in the `post` table after the call.
- **F8.** The endpoint returns HTTP 403 when the caller is authenticated but is not a
  superuser (`get_current_superuser` raises `ForbiddenDomainError` before the use
  case runs).
- **F9.** The endpoint returns HTTP 401 when the request carries no valid
  authentication token.
- **F10.** On each successful hard-delete the `@cache` decorator invalidates the
  `{username}_post_cache` entry keyed by `id` and the `{username}_posts` cache
  entry keyed by `{username}`.
- **F11.** The use-case never raises `ForbiddenDomainError`; a superuser who supplies
  a mismatched `username` namespace receives `NotFoundDomainError("Post not found")`
  (HTTP 404) because `find_post` returns `None` when `created_by_user_id` does not
  match `owner_id`.

## Non-functional requirements

- **N1.** `EraseDbPostUseCase` is a class with `__call__(command: EraseDbPostCommand) -> None`;
  invoked as `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `EraseDbPostAdapter` catches no exceptions; all infrastructure exceptions
  propagate unchanged to the global handler. Per `agent_docs/error_handling.md`
  § Adapter: catch only when there is business meaning to translate.
- **N3.** `EraseDbPostAdapter` explicitly inherits from `EraseDbPostPort`
  (`class EraseDbPostAdapter(EraseDbPostPort):`). Per `agent_docs/architecture.md`
  § Adapter pattern.
- **N4.** `EraseDbPostPort` carries the `@runtime_checkable` decorator. Per
  `agent_docs/architecture.md` § Port pattern.
- **N5.** All new `.py` files start with `# FEATURE: erase_db_post — <purpose>`
  on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N6.** `EraseDbPostUseCase` never raises `HTTPException`. Per CLAUDE.md rule 1.
- **N7.** No cross-slice imports other than from `posts/_shared/`. Per CLAUDE.md
  rule 7.
- **N8.** All new I/O operations use `async def` and `await`; no synchronous DB calls.
  Per CLAUDE.md locked technology stack.
- **N9.** `mypy` strict passes for all new code under `src/app/`. Per CLAUDE.md
  § Verifying changes.
- **N10.** `ruff format` and `ruff check` pass for all new code. Per CLAUDE.md
  § Verifying changes.
- **N11.** All imports inside `src/app/` are relative; no `from app.*` or
  `from src.app.*` inside source files. Per `agent_docs/architecture.md`
  § Import conventions.
- **N12.** The router module path
  `app.features.posts.erase_db_post.presentation.router` is added to
  `Container.wiring_config.modules` in `bootstrap/container.py`. Per
  `agent_docs/entry_points/fastapi.md` § Dependency injection at the endpoint.
- **N13.** An `ignore_imports` entry
  `app.features.posts.erase_db_post.presentation.router -> app.bootstrap.container`
  is added to `.importlinter`. Per `agent_docs/entry_points/fastapi.md`
  § Dependency injection at the endpoint.

## Out of scope

- Soft-delete of posts (`erase_post`, slice 0029) — separate completed slice.
- Hard-deletion of already-soft-deleted posts — a future data-purge slice if needed.
- Adoption of `posts/_shared/policies.py::check_post_owner` — no caller-identity
  check in the use case.
- Cache key rotation or invalidation strategy changes — existing contract preserved.
- Rate-limit configuration — handled cross-cuttingly by existing middleware.
- Moderation-status-based deletion gates — out of scope.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (happy path); outside-in test (step 5) |
| F2 | use-case unit test |
| F3 | use-case unit test |
| F4 | use-case unit test |
| F5 | adapter unit test |
| F6 | adapter unit test |
| F7 | adapter unit test; outside-in test (step 6 DB assertion) |
| F8 | endpoint integration test; outside-in test (step 4) |
| F9 | endpoint integration test |
| F10 | endpoint integration test; outside-in test (step 7 GET → 404) |
| F11 | use-case unit test; outside-in test (step 3) |
| N1–N13 | code review checklist in validation.md |
