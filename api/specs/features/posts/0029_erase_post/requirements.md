# 0029 · erase_post — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `DELETE /api/v1/{username}/post/{id}` returns HTTP 200 with body
  `{"message": "Post deleted"}` when the authenticated requester is the author
  of the identified post.
- **F2.** The endpoint requires a valid auth token; `get_current_user` returns
  HTTP 401 before the use case is invoked when the token is missing or invalid.
- **F3.** `ErasePostUseCase` raises `NotFoundDomainError("User not found")`
  when `ErasePostPort.get_user_by_username` returns `None` for the path
  `username`.
- **F4.** `ErasePostUseCase` raises `ForbiddenDomainError` when
  `command.requester_username` differs from the resolved `user.username`, by
  delegating to `check_post_owner` in `posts/_shared/policies.py`.
- **F5.** `ErasePostUseCase` raises `NotFoundDomainError("Post not found")`
  when `ErasePostPort.find_post` returns `None` for the given `post_id` and
  `owner_id`.
- **F6.** `ErasePostUseCase` calls `ErasePostPort.soft_delete(post_id)` only
  after all three checks pass (user found, ownership confirmed, post found) and
  never otherwise.
- **F7.** `ErasePostAdapter.get_user_by_username` queries `User` filtered by
  `username` and `is_deleted == False`, returns `PostAuthor(id, username)` when
  a matching row exists, and returns `None` otherwise.
- **F8.** `ErasePostAdapter.find_post` queries `Post` filtered by
  `id == post_id`, `created_by_user_id == owner_id`, and `is_deleted == False`;
  returns `ErasePostRecord(id)` when all three conditions are satisfied and
  returns `None` otherwise (including when the post exists but belongs to a
  different user).
- **F9.** `ErasePostAdapter.soft_delete` executes an UPDATE setting
  `is_deleted = True` and `deleted_at = datetime.now(UTC)` on the row with
  `Post.id == post_id` and commits the transaction.
- **F10.** `check_post_owner(requester_username, owner_username)` in
  `posts/_shared/policies.py` raises `ForbiddenDomainError` when
  `requester_username != owner_username` and returns `None` otherwise.
- **F11.** On successful deletion the cache entry keyed
  `{username}_post_cache:{id}` is invalidated so that a subsequent
  `GET /{username}/post/{id}` does not return stale data.
- **F12.** On successful deletion the cache entries keyed `{username}_posts`
  are invalidated so that subsequent list-posts responses for `username` do
  not include the deleted post.

## Non-functional requirements

- **N1.** `ErasePostUseCase` is a class with `__call__()`; called as
  `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `ErasePostAdapter` contains no `try/except` — there are no
  business-meaningful infrastructure exceptions to translate for a soft-delete
  UPDATE or read-only SELECT. All infrastructure failures propagate to the
  global handler. Per `agent_docs/error_handling.md` § Adapter: catch only
  when there is business meaning to translate.
- **N3.** `PostAuthor` (returned by `get_user_by_username`) uses
  `model_config = ConfigDict(from_attributes=True)` because it is mapped from
  an ORM row. Per `agent_docs/architecture.md` and CLAUDE.md § Locked
  technology stack.
- **N4.** All new `.py` files start with `# FEATURE: erase_post — <purpose>`
  (or `# FEATURE: posts._shared — <purpose>` for the shared policy file). Per
  `agent_docs/stable_vs_feature.md`.
- **N5.** `ErasePostUseCase` never raises `HTTPException`; it raises only
  `DomainError` subclasses. Per CLAUDE.md rule 1.
- **N6.** The `erase_post` slice imports only from `posts/_shared/` within the
  posts feature; it does not import from any other slice's `domain/`, `data/`,
  or `presentation/`. Per CLAUDE.md rule 7.
- **N7.** All database operations in `ErasePostAdapter` are `async def` +
  `await`; no synchronous DB calls. Per CLAUDE.md § Locked technology stack.
- **N8.** `mypy` strict mode passes for all new source files. Per CLAUDE.md §
  Verifying changes.
- **N9.** `ruff format` and `ruff check` pass for all new source files. Per
  CLAUDE.md § Verifying changes.

## Out of scope

- Refactoring `erase_db_post` — remains as a flat function in
  `posts/router.py` and is a separate future slice.
- Hard (permanent) deletion — the `erase_db_post` endpoint is untouched.
- Cache key rotation or invalidation strategy changes — the existing key
  contract is preserved deliberately.
- Rate-limit configuration — handled cross-cuttingly by existing middleware.
- Moderation-status-based deletion gates (e.g. preventing deletion of an
  `approved` post) — the two-step port design accommodates this in a future
  slice without an interface change.
- Adopting `check_post_owner` in the existing `update_post` slice — that slice
  is already green; a refactor is a separate concern.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (happy path); outside-in test (step 5) |
| F2 | endpoint integration test (unauthenticated → 401) |
| F3 | use-case unit test (user not found branch) |
| F4 | use-case unit test (requester mismatch branch) |
| F5 | use-case unit test (post not found branch) |
| F6 | use-case unit test (happy path — asserts `soft_delete` called exactly once with correct arg) |
| F7 | adapter unit test (`get_user_by_username` assertions) |
| F8 | adapter unit test (`find_post` assertions — missing, wrong owner, soft-deleted) |
| F9 | adapter unit test (`soft_delete` — DB row state after call) |
| F10 | use-case unit test (ownership check branch); outside-in test (step 4) |
| F11 | outside-in test (step 7 — subsequent GET returns 404) |
| F12 | endpoint integration test (cache header / list response after deletion) |
| N1–N9 | code review checklist in validation.md |
