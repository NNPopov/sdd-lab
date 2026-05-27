# 0055 · migrate_create_post_route_username_to_user_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `POST /api/v1/{user_id}/post` accepts a `CreatePostRequest` (`title`, `text`, `media_url`) and returns HTTP 201 with a `CreatePostResponse` body when the authenticated requester is the target user.
- **F2.** The `CreatePostResponse` body shape is unchanged from slice 0011 — `id`, `title`, `text`, `media_url`, `created_by_user_id`, `created_at`, `status`, `post_uuid` — and contains no `username` field.
- **F3.** A newly created post is persisted with `created_by_user_id == target_user_id` and the default `status == "pending_review"`.
- **F4.** The `CreatePostRequest` validation is unchanged: `title` 1–30 chars, `text` 1–63206 chars, `media_url` optional, `extra="forbid"`; a body violating these returns HTTP 422.
- **F5.** When the request has no or invalid credentials, the endpoint returns HTTP 401 via the `get_current_user` dependency (the use-case is not reached).
- **F6.** When `target_user_id` matches no active user (unknown or soft-deleted), `CreatePostUseCase` raises `NotFoundDomainError("User not found")`, translated to HTTP 404.
- **F7.** When the author is resolved but the authenticated requester is not that author (`requester_user_id != author.id`), `check_post_owner` raises a bare `ForbiddenDomainError()`, translated to HTTP 403.
- **F8.** The use-case resolves the author before checking ownership, so an unknown `target_user_id` yields 404 (not 403) — 404-before-403 ordering.
- **F9.** When the lookup returns `None`, the create port is never called; when ownership fails, the create port is never called.
- **F10.** FastAPI rejects a request whose `{user_id}` path segment is not a valid integer with HTTP 422.
- **F11.** The old `/{username}/post` URL is gone: calling `POST /api/v1/<non-integer-string>/post` returns HTTP 422 because the path parameter is now typed `int`.
- **F12.** `CreatePostCommand` exposes `target_user_id: int` and `requester_user_id: int`; the former fields `target_username: str` and `requester_username: str` no longer exist. `title`, `text`, `media_url` are unchanged.
- **F13.** `CreatePostInternalCommand` is unchanged (it already carries `created_by_user_id: int`), and `CreatePostAdapter` is unchanged.
- **F14.** The `create_post` router reads `user_id: int` from the path and constructs `CreatePostCommand` with `target_user_id=user_id` and `requester_user_id=current_user["id"]`.
- **F15.** `UserLookupPort` declares `get_active_user_by_id(user_id: int) -> UserIdentity | None` **in addition to** the retained `get_active_user_by_username`.
- **F16.** `UserLookupAdapter.get_active_user_by_id` filters `User.id == user_id AND User.is_deleted == False`, returns a matching `UserIdentity`, returns `None` for an unknown id, and returns `None` for a soft-deleted user.
- **F17.** `check_post_owner(requester_user_id: int, owner_user_id: int)` raises a bare `ForbiddenDomainError()` when the ids differ and returns `None` when they match; the former username-based signature no longer exists.
- **F18.** The previous `create_post`-specific 403 message ("You can only post under your own username") is removed; the 403 now carries no message.
- **F19.** `erase_post` stays green after the policy conversion: `ErasePostCommand` exposes `requester_user_id: int` (was `requester_username: str`), the `erase_post` router passes `requester_user_id=current_user["id"]`, and the `erase_post` use-case calls `check_post_owner(command.requester_user_id, user.id)`.
- **F20.** The `erase_post` route (`DELETE /{username}/post/{id}`), its cache keys (`{username}_…`), and its `get_active_user_by_username(command.username)` target lookup are unchanged by this slice.

## Non-functional requirements

- **N1.** `CreatePostUseCase` is a class with `__call__()`; called as `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `CreatePostAdapter` (unchanged) keeps its write-path behaviour; no new `try/except` is introduced. Business-meaningful infrastructure exceptions would map to a `DomainError`; other infrastructure exceptions propagate to the global handler. The adapter does not log. Per `agent_docs/error_handling.md`.
- **N3.** Pydantic schemas use `model_config = ConfigDict(from_attributes=True)` for types built from ORM rows. Per `CLAUDE.md` locked stack.
- **N4.** All modified files retain their `# FEATURE: <slice> — …` header on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `CreatePostUseCase`, `CreatePostAdapter`, `check_post_owner`, or `UserLookupAdapter`; the only domain errors raised are `NotFoundDomainError` and `ForbiddenDomainError`, existing STABLE subclasses. Per `CLAUDE.md` rule 1.
- **N6.** No cross-slice imports; `create_post` and `erase_post` import only their own files, the feature's `_shared/`, and STABLE layers (`adapters/`, `core/`, `domain/`). Per `CLAUDE.md` rule 7 and `agent_docs/architecture.md` § Layer rules.
- **N7.** All I/O in `UserLookupAdapter.get_active_user_by_id` is `async def` + `await`; no synchronous DB calls. Per `CLAUDE.md` locked stack.
- **N8.** `UserLookupAdapter` inherits explicitly from `UserLookupPort`, and `CreatePostAdapter` from `CreatePostPort` (`class …Adapter(…Port):`). Per `agent_docs/architecture.md` § Terminology: port and adapter.
- **N9.** `UserLookupPort` and `CreatePostPort` carry the `@runtime_checkable` decorator and inherit `typing.Protocol`. Per `agent_docs/architecture.md` § Port pattern.
- **N10.** All imports inside `src/app/` are relative (`from ..domain…`, `from ..._shared…`); tests use absolute `from app…`. Per `agent_docs/architecture.md` § Import conventions.
- **N11.** `mypy src/app` strict passes with no new errors introduced by this slice (including `UserLookupAdapter` still satisfying the widened `UserLookupPort`).
- **N12.** `ruff format` and `ruff check` pass with no new violations; the import-linter architecture contracts still pass; the full suite has zero net-new failures relative to the pre-change baseline.

## Out of scope

- Migrating the `update_post`, `erase_post` (route), and `erase_db_post` routes — only `erase_post`'s ownership-check call site is touched, to keep the suite green.
- Removing `get_active_user_by_username` from `UserLookupPort`/`UserLookupAdapter` — deferred to the final cleanup slice.
- `get_post` (slice 0054) and `list_posts` (slice 0042) — already migrated.
- Adding a `username` field to the `create_post` response (it never had one).
- Adding/altering cache on `create_post` (it has no `@cache` decorator).
- Adding a user-facing 403 message.
- Changing the post `id` to a UUID.
- ORM model change or Alembic migration (`Post.created_by_user_id` already exists).
- Flutter client changes (separate working dir).

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (201 owner); use-case unit test (happy path); outside-in test |
| F2 | endpoint integration test (response fields); outside-in test |
| F3 | endpoint integration test (default status + created_by_user_id); use-case unit test (internal command); outside-in test |
| F4 | endpoint integration test (422 invalid body) |
| F5 | endpoint integration test (401 unauthenticated) |
| F6 | endpoint integration test (404 unknown user); use-case unit test (user not found) |
| F7 | endpoint integration test (403 non-owner); use-case unit test (not owner) |
| F8 | use-case unit test (lookup precedes ownership); endpoint integration test (404 vs 403) |
| F9 | use-case unit test (create port never called on 404 and on 403) |
| F10 | endpoint integration test (422 non-integer user_id) |
| F11 | endpoint integration test (old string route → 422); outside-in test |
| F12 | use-case unit test (command fields); mypy |
| F13 | use-case unit test (internal command carries created_by_user_id); existing 0011 adapter test |
| F14 | endpoint integration test (requester resolution); outside-in test |
| F15 | shared adapter unit test (0032); mypy |
| F16 | shared adapter unit test in 0032 (found / unknown id / soft-deleted) |
| F17 | use-case unit test (owner vs non-owner); erase_post use-case unit test |
| F18 | endpoint integration test (403 carries no message) |
| F19 | erase_post use-case unit test (id-based ownership); full-suite baseline |
| F20 | erase_post endpoint/outside-in tests unchanged and still green |
| N1–N12 | code review checklist in validation.md |
