# 0054 · migrate_get_post_route_username_to_user_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `GET /api/v1/{user_id}/post/{id}` returns HTTP 200 with a `GetPostResponse` body for a post that exists, belongs to `user_id`, and is visible to the requester.
- **F2.** FastAPI rejects a request whose `{user_id}` (or `{id}`) path segment is not a valid integer with HTTP 422.
- **F3.** When the post's `status == "approved"`, the endpoint returns it with HTTP 200 regardless of whether the request is authenticated.
- **F4.** When the post is non-approved and the request is authenticated with `optional_user["id"] == user_id` (the author), the endpoint returns the post with HTTP 200.
- **F5.** When the post is non-approved and the requester is a privileged viewer (`optional_user["is_superuser"]` or `optional_user["is_moderator"]`), the endpoint returns the post with HTTP 200 regardless of authorship.
- **F6.** When the post is non-approved and the requester is neither the author nor privileged (including unauthenticated requesters), the use-case raises `NotFoundDomainError("Post not found")`, translated to HTTP 404.
- **F7.** When no post matches the given `user_id` and `post_id`, the adapter returns `None` and the use-case raises `NotFoundDomainError("Post not found")` (HTTP 404).
- **F8.** When `user_id` does not correspond to any user, the endpoint returns HTTP 404 (generic "Post not found"); no distinct "user not found" response is produced and no user-existence lookup is performed.
- **F9.** The old `/{username}/post/{id}` URL is gone: calling `GET /api/v1/<non-integer-string>/post/{id}` returns HTTP 422 because the path parameter is now typed `int`.
- **F10.** The `GetPostResponse` body includes a `username` field populated from the `User` JOIN (`Post.created_by_user_id == User.id`), not echoed from the path; the full field set (`id`, `title`, `text`, `media_url`, `created_at`, `created_by_user_id`, `username`, `status`, `post_uuid`) is unchanged from slice 0026.
- **F11.** `GetPostAdapter.get` filters the post on `Post.created_by_user_id == query.user_id` (not on `User.username`), pinned by `Post.id == query.post_id`.
- **F12.** `GetPostAdapter.get` retains the `Post → User` JOIN and the `User.is_deleted == False` and `Post.is_deleted == False` guards, returning `None` for a soft-deleted post or a soft-deleted author and sourcing `PostItem.username` from the JOIN.
- **F13.** `GetPostUseCase` computes the author check as `query.requester_user_id == query.user_id`; `requester_user_id is None` (anonymous) yields `False` and falls through to the privileged-viewer check.
- **F14.** `GetPostQuery` exposes `user_id: int` and `requester_user_id: int | None = None`; the former fields `username: str` and `requester_username: str | None` no longer exist. `post_id: int` and `requester_is_privileged: bool = False` are unchanged.
- **F15.** The router derives `requester_user_id = optional_user["id"] if optional_user else None` and `requester_is_privileged = bool(optional_user and (optional_user["is_superuser"] or optional_user["is_moderator"]))`, and constructs `GetPostQuery` with `user_id` and `post_id` from the path parameters.
- **F16.** The `@cache` decorator on the endpoint uses `key_prefix="{user_id}_post_cache"` and `resource_id_name="id"`.

## Non-functional requirements

- **N1.** `GetPostUseCase` is a class with `__call__()`; called as `await use_case(query)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `GetPostAdapter` performs a read-only query and contains **no `try/except`** — there is no business-meaningful infrastructure exception to translate; all infrastructure exceptions propagate to the global handler. The adapter does not log. Per `agent_docs/error_handling.md`.
- **N3.** Pydantic response schemas use `model_config = ConfigDict(from_attributes=True)` for types built from ORM rows. Per `CLAUDE.md` locked stack.
- **N4.** All modified files retain their `# FEATURE: get_post — …` header on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `GetPostUseCase` or `GetPostAdapter`; the only domain error raised is `NotFoundDomainError`, an existing STABLE subclass. Per `CLAUDE.md` rule 1.
- **N6.** No cross-slice imports; `get_post` imports only its own files, the feature's `_shared/`, and STABLE layers (`adapters/`, `core/`). Per `CLAUDE.md` rule 7 and `agent_docs/architecture.md` § Layer rules.
- **N7.** All I/O in `GetPostAdapter` is `async def` + `await`; no synchronous DB calls. Per `CLAUDE.md` locked stack.
- **N8.** `GetPostAdapter` inherits explicitly from `GetPostPort`: `class GetPostAdapter(GetPostPort):`. Per `agent_docs/architecture.md` § Terminology: port and adapter.
- **N9.** `GetPostPort` carries the `@runtime_checkable` decorator and inherits `typing.Protocol`. Per `agent_docs/architecture.md` § Port pattern.
- **N10.** All imports inside `src/app/` are relative (`from ..domain…`, `from ....adapters…`); tests use absolute `from app…`. Per `agent_docs/architecture.md` § Import conventions.
- **N11.** `mypy src/app` strict passes with no new errors introduced by this slice.
- **N12.** `ruff format` and `ruff check` pass with no new violations; the import-linter architecture contracts still pass.

## Out of scope

- Migrating `create_post`, `update_post`, `erase_post`, `erase_db_post`.
- `list_posts` (`GET /{user_id}/posts`) — already migrated in slice 0042.
- Touching `UserLookupPort` / `UserLookupAdapter` and the `check_post_owner` policy in `posts/_shared/`.
- Adding a distinct "user not found" (404) response.
- Removing `username` from the response body.
- Changing the post `id` to a UUID.
- Explicit cache flush of stale `{username}_post_cache:...` keys (they expire via the existing TTL).
- Flutter client changes (separate working dir).

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (200 happy path); outside-in test |
| F2 | endpoint integration test (422 non-integer path) |
| F3 | endpoint integration test (200 approved unauthenticated); use-case unit test (approved); outside-in test |
| F4 | endpoint integration test (200 non-approved author); use-case unit test (author view); outside-in test |
| F5 | endpoint integration test (200 non-approved privileged); use-case unit test (privileged view) |
| F6 | endpoint integration test (404 non-approved non-author); use-case unit test (non-author non-privileged) |
| F7 | endpoint integration test (404 unknown post); use-case unit test (post missing); adapter unit test (missing/wrong author) |
| F8 | endpoint integration test (404 unknown user_id) |
| F9 | endpoint integration test (old string route → 422); outside-in test |
| F10 | adapter unit test (username from JOIN); endpoint integration test (response fields); outside-in test |
| F11 | adapter unit test (found by id, wrong author) |
| F12 | adapter unit test (soft-deleted post, soft-deleted author, username from JOIN) |
| F13 | use-case unit test (author check; anonymous fall-through) |
| F14 | use-case unit test (query fields); mypy |
| F15 | endpoint integration test (requester resolution); use-case unit test (query carries requester fields) |
| F16 | endpoint integration test (cache key behaviour) |
| N1–N12 | code review checklist in validation.md |
