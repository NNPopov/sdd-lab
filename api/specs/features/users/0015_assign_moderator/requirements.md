# 0015 · assign_moderator — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `PATCH /api/v1/user/{username}/assign-moderator` accepts no request
  body, takes `username` as a path parameter, and on success returns
  `AssignModeratorResponse` with HTTP 200.
- **F2.** `AssignModeratorCommand` carries exactly three fields:
  `target_username: str`, `requester_id: int`, and
  `requester_is_superuser: bool`.
- **F3.** The router constructs `AssignModeratorCommand` with
  `target_username=username` (path param), `requester_id=current_superuser["id"]`,
  and `requester_is_superuser=current_superuser["is_superuser"]`.
- **F4.** `AssignModeratorUseCase.__call__()` raises `ForbiddenDomainError`
  when `command.requester_is_superuser` is `False`, before any port method is
  called.
- **F5.** `AssignModeratorUseCase.__call__()` raises `NotFoundDomainError("User
  not found")` when `port.get_by_username()` returns `None`.
- **F6.** `AssignModeratorUseCase.__call__()` raises
  `DuplicateValueDomainError("User is already a moderator")` when the entity
  returned by `port.get_by_username()` has `is_moderator = True`.
- **F7.** On the happy path, `AssignModeratorUseCase.__call__()` calls
  `port.assign(command.target_username, command.requester_id)` and returns the
  resulting `AssignedUser` entity without modification.
- **F8.** `AssignModeratorAdapter.get_by_username()` returns `None` when no
  active (non-soft-deleted) `User` row matches the given username.
- **F9.** `AssignModeratorAdapter.get_by_username()` returns a mapped
  `AssignedUser` when an active `User` row is found; all fields (`id`, `name`,
  `username`, `email`, `profile_image_url`, `tier_id`, `is_moderator`) are
  populated from the row.
- **F10.** `AssignModeratorAdapter.assign()` writes `is_moderator = True` to
  the target `User` row in the database.
- **F11.** `AssignModeratorAdapter.assign()` writes
  `moderator_granted_by_user_id = granted_by_user_id` to the target `User` row
  in the database.
- **F12.** `AssignModeratorAdapter.assign()` returns a fully mapped
  `AssignedUser` entity reflecting the state of the row after the UPDATE has
  been committed.
- **F13.** `AssignModeratorResponse` contains the fields: `id: int`,
  `name: str`, `username: str`, `email: str`, `profile_image_url: str`,
  `tier_id: int | None`, and `is_moderator: bool`.
- **F14.** `AssignModeratorResponse.is_moderator` is `true` in every successful
  200 response.
- **F15.** The endpoint returns HTTP 401 when the `Authorization` header is
  missing or the Bearer token is invalid, enforced by `get_current_superuser`
  (via `get_current_user`).
- **F16.** The endpoint returns HTTP 403 when the authenticated user is not a
  superuser, enforced by the `get_current_superuser` dependency at the router
  level.
- **F17.** The endpoint returns HTTP 403 when `AssignModeratorUseCase` raises
  `ForbiddenDomainError`, translated by the global exception handler.
- **F18.** The endpoint returns HTTP 404 when `AssignModeratorUseCase` raises
  `NotFoundDomainError`, translated by the global exception handler.
- **F19.** The endpoint returns HTTP 409 when `AssignModeratorUseCase` raises
  `DuplicateValueDomainError`, translated by the global exception handler.

## Non-functional requirements

- **N1.** `AssignModeratorUseCase` is a class with `__call__()`; it is called
  as `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case
  shape.
- **N2.** `AssignModeratorAdapter` contains no broad `try/except` block;
  `assign()` wraps only `session.commit()` if a business-meaningful
  `IntegrityError` translation is needed — and for this slice no unique
  constraint is involved, so no `try/except` is present at all. Infrastructure
  failures propagate to the global handler. Per `agent_docs/error_handling.md`
  § Adapter: catch only when there is business meaning to translate.
- **N3.** `AssignModeratorResponse` uses
  `model_config = ConfigDict(from_attributes=True)`. Per
  `agent_docs/entry_points/fastapi.md` § Request and Response schemas.
- **N4.** Every new `.py` file in this slice starts with
  `# FEATURE: assign_moderator — <purpose>` on line 1. Per
  `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `AssignModeratorUseCase`; only
  `DomainError` subclasses are raised. Per CLAUDE.md § Universal hard rules.
- **N6.** `AssignedUser` is defined in
  `assign_moderator/domain/entities.py` and is not imported from the
  `get_user_by_username` slice; cross-slice domain imports are forbidden. Per
  `agent_docs/architecture.md` § Layer rules.
- **N7.** All database operations in `AssignModeratorAdapter` use `async def`
  and `await`; no synchronous DB calls are introduced. Per CLAUDE.md § Locked
  technology stack.
- **N8.** `mypy src/app` strict passes for all new files in this slice with no
  new type errors. Per CLAUDE.md § Verifying changes.
- **N9.** `ruff format src/app` and `ruff check src/app` pass for all new files
  in this slice. Per CLAUDE.md § Verifying changes.
- **N10.** `AssignModeratorPort` carries the `@runtime_checkable` decorator.
  Per `agent_docs/architecture.md` § Terminology: port and adapter.
- **N11.** The adapter class declaration is
  `class AssignModeratorAdapter(AssignModeratorPort):` — explicit inheritance
  from the port is mandatory. Per `agent_docs/architecture.md` § Adapter
  pattern (canonical).

## Out of scope

- Revoking moderator status — slice 0016.
- `get_current_moderator` auth dependency — introduced in slices 0017 and 0019.
- Exposing `moderator_granted_by_user_id` in any response schema.
- Full moderator grant history audit log.
- Cache invalidation for user profile responses.
- Rate limiting on the endpoint.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (happy path); outside-in test (step 4) |
| F2 | code review (command field count and types) |
| F3 | code review (router command construction) |
| F4 | use-case unit test (superuser-check case) |
| F5 | use-case unit test (not-found case) |
| F6 | use-case unit test (already-moderator case) |
| F7 | use-case unit test (happy-path case) |
| F8 | adapter unit test (`get_by_username` — not found case) |
| F9 | adapter unit test (`get_by_username` — found case) |
| F10 | adapter unit test (`assign` happy path — DB row assertion) |
| F11 | adapter unit test (`assign` happy path — DB row assertion) |
| F12 | adapter unit test (`assign` happy path — returned entity assertion) |
| F13 | endpoint integration test (response body field check) |
| F14 | endpoint integration test (happy path); outside-in test (step 4) |
| F15 | endpoint integration test (401 case) |
| F16 | endpoint integration test (403 non-superuser case) |
| F17 | endpoint integration test (403 non-superuser via use-case — covered by same 403 test) |
| F18 | endpoint integration test (404 case) |
| F19 | endpoint integration test (409 case) |
| N1–N11 | code review checklist in `validation.md` |
