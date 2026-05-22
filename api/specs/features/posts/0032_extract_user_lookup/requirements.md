# 0032 · extract_user_lookup — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

### Shared entity

- **F1.** `posts/_shared/entities.py` contains a `UserIdentity` class with fields `id: int`
  and `username: str`, and `model_config = ConfigDict(from_attributes=True)`.
- **F2.** `PostAuthor` is fully deleted from `posts/_shared/entities.py`; no remaining
  reference to `PostAuthor` exists anywhere under `src/app/features/posts/`.

### Shared port

- **F3.** `posts/_shared/user_lookup_port.py` defines `UserLookupPort` as a
  `@runtime_checkable` `Protocol` with a single method:
  `async def get_active_user_by_username(self, username: str) -> UserIdentity | None`.
- **F4.** `UserLookupPort` carries the `@runtime_checkable` decorator so that
  `isinstance(adapter, UserLookupPort)` returns `True` at runtime.

### Shared adapter

- **F5.** `UserLookupAdapter` implements `UserLookupPort` with an async SQLAlchemy query
  filtering on `User.username == username` AND `User.is_deleted.is_(False)`.
- **F6.** `UserLookupAdapter.get_active_user_by_username` returns a `UserIdentity` instance
  (validated via `UserIdentity.model_validate(user)`) when an active user is found.
- **F7.** `UserLookupAdapter.get_active_user_by_username` returns `None` when no user record
  matches the given username.
- **F8.** `UserLookupAdapter.get_active_user_by_username` returns `None` when a user record
  exists but `is_deleted = True`.

### Per-slice port cleanup

- **F9.** `CreatePostPort` declares only `create(command: CreatePostInternalCommand) -> CreatedPost`;
  the `get_user_by_username` method is removed.
- **F10.** `UpdatePostPort` declares only `get_post_by_id` and `update`; `get_user_by_username`
  is removed.
- **F11.** `ErasePostPort` declares only `find_post` and `soft_delete`; `get_user_by_username`
  is removed.
- **F12.** `EraseDbPostPort` declares only `find_post` and `hard_delete`; `get_user_by_username`
  is removed.

### Per-slice adapter cleanup

- **F13.** `CreatePostAdapter`, `UpdatePostAdapter`, `ErasePostAdapter`, and `EraseDbPostAdapter`
  no longer implement or import any `get_user_by_username` method.

### Use-case updates

- **F14.** `CreatePostUseCase.__init__` accepts `port: CreatePostPort` and
  `user_lookup: UserLookupPort` as constructor parameters.
- **F15.** `CreatePostUseCase.__call__` calls
  `self._user_lookup.get_active_user_by_username(command.target_username)`; raises
  `NotFoundDomainError("User not found")` when the result is `None`.
- **F16.** `CreatePostUseCase.__call__` raises `ForbiddenDomainError` when
  `command.requester_username` does not equal the resolved user's `username`.

- **F17.** `UpdatePostUseCase.__init__` accepts `port: UpdatePostPort` and
  `user_lookup: UserLookupPort` as constructor parameters.
- **F18.** `UpdatePostUseCase.__call__` calls
  `self._user_lookup.get_active_user_by_username(command.target_username)`; raises
  `NotFoundDomainError("User not found")` when the result is `None`.
- **F19.** `UpdatePostUseCase.__call__` raises `ForbiddenDomainError` when
  `command.requester_username` does not equal the resolved user's `username`.

- **F20.** `ErasePostUseCase.__init__` accepts `port: ErasePostPort` and
  `user_lookup: UserLookupPort` as constructor parameters.
- **F21.** `ErasePostUseCase.__call__` calls
  `self._user_lookup.get_active_user_by_username(command.username)`; raises
  `NotFoundDomainError("User not found")` when the result is `None`.
- **F22.** `ErasePostUseCase.__call__` raises `ForbiddenDomainError` (via `check_post_owner`)
  when the requester username does not match the resolved user's `username`.

- **F23.** `EraseDbPostUseCase.__init__` accepts `port: EraseDbPostPort` and
  `user_lookup: UserLookupPort` as constructor parameters.
- **F24.** `EraseDbPostUseCase.__call__` calls
  `self._user_lookup.get_active_user_by_username(command.username)`; raises
  `NotFoundDomainError("User not found")` when the result is `None`.

### DI wiring

- **F25.** `bootstrap/container.py` declares a single `user_lookup_adapter` provider:
  `providers.Factory(UserLookupAdapter, session_factory=session_factory)`.
- **F26.** Each of the four post use-case providers (`create_post_use_case`,
  `update_post_use_case`, `erase_post_use_case`, `erase_db_post_use_case`) receives
  `user_lookup=user_lookup_adapter`.

### Acceptance gate

- **F27.** The four existing outside-in tests for `create_post`, `update_post`, `erase_post`,
  and `erase_db_post` pass green without modification after the refactor is complete.

## Non-functional requirements

- **N1.** `UserLookupAdapter` explicitly inherits from `UserLookupPort`
  (`class UserLookupAdapter(UserLookupPort):`). Per `agent_docs/architecture.md`
  § Terminology: port and adapter.
- **N2.** `UserLookupPort` carries `@runtime_checkable`. Per `CLAUDE.md` hard rules.
- **N3.** `UserLookupAdapter.get_active_user_by_username` contains no `try/except`; any
  infrastructure exception (e.g. `OperationalError`) propagates unchanged to the global
  handler. Per `agent_docs/error_handling.md` § Right shape: read-only query, no catch.
- **N4.** All new `.py` files (`user_lookup_port.py`, `user_lookup_adapter.py`) start with
  `# FEATURE: posts._shared — <purpose>` on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** Files under `src/app/` use relative imports; test files use absolute imports
  through `app.*`. Per `agent_docs/architecture.md` § Import conventions.
- **N6.** No `HTTPException` is raised inside any use-case. Per `CLAUDE.md` hard rule 1.
- **N7.** No cross-slice imports; `posts/_shared/` is the only cross-use-case boundary within
  the feature. Per `CLAUDE.md` hard rule 7.
- **N8.** All I/O is `async def` + `await`; no synchronous DB calls. Per `CLAUDE.md` locked
  stack.
- **N9.** `mypy` strict passes for all new and modified files under `src/app/`. Per `CLAUDE.md`
  § Verifying changes.
- **N10.** `ruff format` and `ruff check` pass for all new and modified files. Per `CLAUDE.md`
  § Verifying changes.
- **N11.** `UserIdentity` uses `model_config = ConfigDict(from_attributes=True)` so that
  `UserIdentity.model_validate(orm_instance)` works correctly. Per `CLAUDE.md` locked stack
  (Pydantic v2).

## Out of scope

- Applying the same extraction to user-feature slices (`delete_user`, `delete_db_user`,
  `revoke_moderator`, etc.). Phase 2, separate slice.
- Promoting `UserIdentity`, `UserLookupPort`, or `UserLookupAdapter` to the STABLE layer.
  Phase 2 only.
- Any change to HTTP endpoints, request/response schemas, or OpenAPI contracts.
- Any database migration.
- Role or permission checking beyond what already exists in `posts/_shared/policies.py`.
- The `get_user_by_username` slice in `features/users/` (slice 0004); unrelated.

## Traceability

| Requirement | Verified by |
|---|---|
| F1, F2 | code review (`_shared/entities.py`; grep for `PostAuthor`) |
| F3, F4 | code review (`_shared/user_lookup_port.py`) |
| F5–F8 | `UserLookupAdapter` unit test (`test_user_lookup_adapter.py`) |
| F9–F13 | code review (four port files and four adapter files) |
| F14–F16 | `CreatePostUseCase` unit test |
| F17–F19 | `UpdatePostUseCase` unit test |
| F20–F22 | `ErasePostUseCase` unit test |
| F23–F24 | `EraseDbPostUseCase` unit test |
| F25, F26 | code review (`bootstrap/container.py`) |
| F27 | four existing outside-in tests (primary acceptance gate) |
| N1–N11 | code review checklist in `validation.md` |
