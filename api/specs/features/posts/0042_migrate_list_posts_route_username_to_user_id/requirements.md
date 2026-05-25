# 0042 · migrate_list_posts_route_username_to_user_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `GET /api/v1/{user_id}/posts` returns HTTP 200 with a `ListPostsResponse` body (`items`, `total_count`, `page`, `items_per_page`) for a valid integer `user_id`.
- **F2.** FastAPI rejects a request whose `{user_id}` path segment is not a valid integer with HTTP 422.
- **F3.** When the request is unauthenticated, the response contains only posts with `status == "approved"` for that author (public view).
- **F4.** When the request is authenticated and `optional_user["id"] == user_id` (the author), the response contains all of that author's non-deleted posts regardless of `status` (author view).
- **F5.** When the request is authenticated but `optional_user["id"] != user_id` (a non-author), the response contains only posts with `status == "approved"` (public view).
- **F6.** When the `user_id` owns no posts visible to the caller, the endpoint returns HTTP 200 with `items == []` and `total_count == 0`.
- **F7.** When `user_id` does not correspond to any user, the endpoint returns HTTP 200 with `items == []` and `total_count == 0` (no 404).
- **F8.** Each item in `items` includes a `username` field populated from the `User` JOIN (`Post.created_by_user_id == User.id`), not echoed from the path.
- **F9.** Pagination query params `page` (`ge=1`, default 1) and `items_per_page` (`ge=1`, `le=100`, default 10) behave identically to slice 0009, slicing the result set by `offset = (page - 1) * items_per_page`.
- **F10.** The old `/{username}/posts` URL is gone: calling `GET /api/v1/<non-integer-string>/posts` returns HTTP 422 because the path parameter is now typed `int`.
- **F11.** `ListPostsAdapter.list` filters the post set on `Post.created_by_user_id == query.user_id` (not on `User.username`), in both the count statement and the rows statement.
- **F12.** `ListPostsAdapter.list` computes `is_author = query.requester_user_id == query.user_id`; `requester_user_id is None` yields `is_author == False` (public view).
- **F13.** `ListPostsAdapter.list` retains the `Post → User` JOIN and the `User.is_deleted == False` guard so that `total_count` and `items` stay consistent for a soft-deleted author, and so each `PostItem.username` is sourced from the JOIN.
- **F14.** `ListPostsQuery` exposes `user_id: int` and `requester_user_id: int | None = None`; the former fields `username: str` and `requester_username: str | None` no longer exist.
- **F15.** The router's `_get_view` dependency returns `"author"` when `optional_user` is present and `optional_user.get("id") == user_id`, and `"public"` otherwise.
- **F16.** The router constructs `ListPostsQuery` with `user_id` from the path parameter and `requester_user_id = user_id if view == "author" else None`.
- **F17.** The `@cache` decorator on the endpoint uses `key_prefix="{user_id}_posts:{view}:page_{page}:items_per_page:{items_per_page}"` and `resource_id_name="user_id"`.
- **F18.** The `ListPostsResponse` envelope and `PostItemSchema` field set are unchanged from slice 0009 (response contract is not part of this migration).

## Non-functional requirements

- **N1.** `ListPostsUseCase` is a class with `__call__()`; called as `await use_case(query)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `ListPostsAdapter` performs read-only queries and contains **no `try/except`** — there is no business-meaningful infrastructure exception to translate; all infrastructure exceptions propagate to the global handler. The adapter does not log. Per `agent_docs/error_handling.md`.
- **N3.** Pydantic response schemas use `model_config = ConfigDict(from_attributes=True)` for types built from ORM rows. Per `CLAUDE.md` locked stack.
- **N4.** All modified files retain their `# FEATURE: list_posts — …` header on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `ListPostsUseCase` or `ListPostsAdapter`. Per `CLAUDE.md` rule 1.
- **N6.** No cross-slice imports; `list_posts` imports only its own files, the feature's `_shared/`, and STABLE layers (`adapters/`, `core/`). Per `CLAUDE.md` rule 7 and `agent_docs/architecture.md` § Layer rules.
- **N7.** All I/O in `ListPostsAdapter` is `async def` + `await`; no synchronous DB calls. Per `CLAUDE.md` locked stack.
- **N8.** `ListPostsAdapter` inherits explicitly from `ListPostsPort`: `class ListPostsAdapter(ListPostsPort):`. Per `agent_docs/architecture.md` § Terminology: port and adapter.
- **N9.** `ListPostsPort` carries the `@runtime_checkable` decorator and inherits `typing.Protocol`. Per `agent_docs/architecture.md` § Port pattern.
- **N10.** All imports inside `src/app/` are relative (`from ..domain…`, `from ....adapters…`); tests use absolute `from app…`. Per `agent_docs/architecture.md` § Import conventions.
- **N11.** `mypy src/app` strict passes with no new errors introduced by this slice.
- **N12.** `ruff format` and `ruff check` pass with no new violations; the import-linter architecture contracts still pass.

## Out of scope

- Migrating `create_post`, `get_post`, `update_post`, `erase_post`, `erase_db_post`.
- Touching `UserLookupPort` / `UserLookupAdapter` in `posts/_shared/`.
- `list_all_posts` (`GET /posts/`) and `list_pending_posts`.
- Removing `username` from the response item.
- Returning 404 for an unknown `user_id` (stays 200 + empty list).
- Explicit cache flush of stale `{username}_posts:...` keys.
- Admin UI (CRUDAdmin) changes.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (200 happy path); outside-in test |
| F2 | endpoint integration test (422 non-integer path); outside-in test (old string route) |
| F3 | endpoint integration test (unauthenticated public view); adapter unit test (public view) |
| F4 | endpoint integration test (author view); adapter unit test (author view); outside-in test |
| F5 | endpoint integration test (non-author authenticated view) |
| F6 | endpoint integration test (empty); adapter unit test (empty result) |
| F7 | endpoint integration test (unknown user_id → empty) |
| F8 | adapter unit test (username from JOIN); outside-in test (item fields) |
| F9 | endpoint integration test (pagination) |
| F10 | endpoint integration test (422 string path); outside-in test |
| F11 | adapter unit test (filter on created_by_user_id) |
| F12 | adapter unit test (is_author public vs author); use-case unit test |
| F13 | adapter unit test (JOIN + is_deleted guard, count==len(items)) |
| F14 | use-case unit test (query fields); mypy |
| F15 | endpoint integration test (author vs public view selection) |
| F16 | use-case unit test (query carries requester_user_id); endpoint integration test |
| F17 | endpoint integration test (cache key behaviour) |
| F18 | endpoint integration test (response shape); outside-in test (item fields) |
| N1–N12 | code review checklist in validation.md |
