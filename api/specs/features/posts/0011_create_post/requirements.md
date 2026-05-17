# 0011 · create_post — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `POST /api/v1/{username}/post` accepts a `CreatePostRequest` body with
  fields `title` (str), `text` (str), and `media_url` (str | None) and returns a
  `CreatePostResponse` with HTTP status 201 on success.
- **F2.** `CreatePostRequest` requires `title` with `min_length=1` and `max_length=30`;
  a missing or empty `title` yields HTTP 422.
- **F3.** `CreatePostRequest` requires `text` with `min_length=1` and `max_length=63206`;
  a missing or empty `text` yields HTTP 422.
- **F4.** `CreatePostRequest` treats `media_url` as optional (defaults to `None`); omitting it
  does not yield an error.
- **F5.** `CreatePostRequest` is configured with `extra="forbid"`; an unknown field in the
  request body yields HTTP 422.
- **F6.** The endpoint reads `username` from the URL path and `current_user["username"]` from
  the `get_current_user` auth dependency, then builds `CreatePostCommand` with
  `target_username=username` and `requester_username=current_user["username"]`.
- **F7.** `CreatePostUseCase.__call__` calls `port.get_user_by_username(command.target_username)`;
  when the result is `None`, it raises `NotFoundDomainError("User not found")`, which the
  global exception handler maps to HTTP 404.
- **F8.** `CreatePostUseCase.__call__` raises `ForbiddenDomainError` when
  `command.requester_username != author.username` (where `author` is the `PostAuthor` returned
  by the port); the global exception handler maps this to HTTP 403.
- **F9.** On the happy path, `CreatePostUseCase.__call__` builds `CreatePostInternalCommand`
  with `created_by_user_id=author.id` and delegates to `port.create(internal)`, returning
  the resulting `CreatedPost`.
- **F10.** `CreatePostAdapter.get_user_by_username` returns a `PostAuthor` (with `id` and
  `username` fields) for an existing active user (where `is_deleted=False`).
- **F11.** `CreatePostAdapter.get_user_by_username` returns `None` when no user row exists for
  the given username.
- **F12.** `CreatePostAdapter.get_user_by_username` returns `None` for a user whose
  `is_deleted=True`.
- **F13.** `CreatePostAdapter.create` inserts a `Post` row with `created_by_user_id`,
  `title`, `text`, and `media_url` from the command, commits, refreshes, and returns a
  `CreatedPost` with all required fields (`id`, `title`, `text`, `media_url`,
  `created_by_user_id`, `created_at`).
- **F14.** `CreatePostResponse` includes exactly the fields: `id`, `title`, `text`,
  `media_url`, `created_by_user_id`, `created_at`; no private or internal fields are exposed.
- **F15.** The old `write_post` handler is removed from `features/posts/router.py`; only the
  new slice router handles `POST /{username}/post`.
- **F16.** `CreatePostUseCase` is wired into the DI container via `create_post_adapter`
  (Factory, receives `session_factory`) and `create_post_use_case` (Factory, receives
  `create_post_adapter`) providers in `bootstrap/container.py`.

## Non-functional requirements

- **N1.** `CreatePostUseCase` is a class with a single public method `__call__(command:
  CreatePostCommand) -> CreatedPost`; it is invoked as `await use_case(command)`. Per
  `agent_docs/architecture.md` § Use-case shape.
- **N2.** `CreatePostAdapter` catches only business-meaningful infrastructure exceptions;
  since neither the user lookup nor the post insert has a unique-constraint path that maps
  to a domain concept, no `try/except` is needed. Other infrastructure exceptions propagate
  unchanged to the global handler. Per `agent_docs/error_handling.md`.
- **N3.** Domain entities (`PostAuthor`, `CreatedPost`) and response schema
  (`CreatePostResponse`) use `model_config = ConfigDict(from_attributes=True)` to support
  direct `.model_validate(orm_row)`. Per `agent_docs/entry_points/fastapi.md`.
- **N4.** Every new `.py` file in `features/posts/create_post/` starts with
  `# FEATURE: create_post — <purpose>` on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** `CreatePostUseCase` never raises `HTTPException`; it raises only `DomainError`
  subclasses (`NotFoundDomainError`, `ForbiddenDomainError`). Per CLAUDE.md hard rule 1.
- **N6.** No file within `features/posts/create_post/` imports from another slice's
  `domain/`, `data/`, or `presentation/`. Per CLAUDE.md hard rule 7.
- **N7.** All database operations in `CreatePostAdapter` use `async def` and `await`; no
  synchronous calls. Per CLAUDE.md locked technology stack.
- **N8.** `mypy --strict src/app` reports no errors for all new files. Per CLAUDE.md
  `Verifying changes`.
- **N9.** `ruff format src/app` and `ruff check src/app` produce no warnings or errors for
  all new files. Per CLAUDE.md `Verifying changes`.
- **N10.** `CreatePostPort` carries the `@runtime_checkable` decorator and inherits from
  `typing.Protocol`. Per CLAUDE.md forbidden list and `agent_docs/architecture.md` § Port pattern.
- **N11.** `CreatePostAdapter` explicitly inherits from `CreatePostPort`
  (`class CreatePostAdapter(CreatePostPort):`). Per CLAUDE.md forbidden list and
  `agent_docs/architecture.md` § Adapter pattern.
- **N12.** All imports inside `src/app/features/posts/create_post/` use relative paths;
  absolute `from app.*` imports are forbidden inside `src/app/`. Per
  `agent_docs/architecture.md` § Import conventions.

## Out of scope

- Migrating `read_post`, `patch_post`, `erase_post`, or `erase_db_post` to the vertical
  slice pattern.
- Deleting `PostCreate` or `PostCreateInternal` from `posts/schemas.py`.
- Media upload handling (`media_url` is a plain optional string).
- Rate limiting on the create-post endpoint.
- `@cache` decorator or cache invalidation.
- Adding a `_shared/` folder for the posts feature.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2, F3, F4, F5 | endpoint integration test (HTTP 422 cases) |
| F6 | endpoint integration test; outside-in test |
| F7 | use-case unit test (NotFoundDomainError branch); endpoint integration test (HTTP 404) |
| F8 | use-case unit test (ForbiddenDomainError branch); endpoint integration test (HTTP 403) |
| F9 | use-case unit test (happy path — port.create called with correct internal command) |
| F10 | adapter unit test (active user found) |
| F11 | adapter unit test (unknown username returns None) |
| F12 | adapter unit test (soft-deleted user returns None) |
| F13 | adapter unit test (create returns correct CreatedPost) |
| F14 | endpoint integration test (response body shape) |
| F15 | endpoint integration test (old handler no longer reachable) |
| F16 | smoke test (`tests/smoke/test_app_starts.py`) |
| N1–N12 | code review checklist in validation.md |
