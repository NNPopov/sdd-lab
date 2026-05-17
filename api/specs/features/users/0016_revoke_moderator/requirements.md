# 0016 · revoke_moderator — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `PATCH /api/v1/users/{username}/revoke-moderator` requires
  a Bearer JWT; any request without a valid token receives HTTP 401.
- **F2.** The endpoint returns HTTP 403 when the authenticated user is not a
  superuser (enforced by the `get_current_superuser` dependency before the
  use-case is called).
- **F3.** The use-case raises `ForbiddenDomainError` when
  `command.requester_is_superuser` is `False`; `port.get_by_username` is not
  called in this case.
- **F4.** The use-case raises `NotFoundDomainError("User not found")` when
  `port.get_by_username(command.target_username)` returns `None`; `port.revoke`
  is not called in this case.
- **F5.** The use-case raises `DuplicateValueDomainError("User is not a moderator")`
  when `port.get_by_username` returns a user with `is_moderator = False`;
  `port.revoke` is not called in this case.
- **F6.** On success, the use-case calls `port.revoke(command.target_username)`
  and returns the resulting `RevokedUser` entity to the caller unchanged.
- **F7.** The adapter's `revoke` method writes `is_moderator = False` and
  `moderator_granted_by_user_id = None` to the target user row and commits
  within a single session context.
- **F8.** The adapter's `revoke` method returns a `RevokedUser` entity whose
  fields reflect the post-update state of the database row.
- **F9.** The adapter's `get_by_username` method returns `None` for a username
  that does not exist in the database.
- **F10.** The adapter's `get_by_username` method returns a `RevokedUser` entity
  with fields matching the database row for an existing, active (non-soft-deleted)
  user.
- **F11.** Soft-deleted users are excluded from `get_by_username` results and
  are treated as not found.
- **F12.** On success, the endpoint returns HTTP 200 with a
  `RevokeModeratorResponse` body; the `is_moderator` field in the response is
  always `false`.
- **F13.** The endpoint returns HTTP 404 when the superuser calls with a
  `username` that does not exist or belongs to a soft-deleted user.
- **F14.** The endpoint returns HTTP 409 when the superuser calls with a
  `username` that belongs to an existing user whose `is_moderator` is already
  `false`.
- **F15.** After a successful revocation, a subsequent `GET /users/user/{username}`
  (read path) returns `is_moderator: false`, confirming the change is persisted.

## Non-functional requirements

- **N1.** `RevokeModeratorUseCase` is a class with a single `__call__()`
  method; called as `await use_case(command)`. Per `agent_docs/architecture.md`
  § Use-case shape.
- **N2.** `RevokeModeratorAdapter` catches no infrastructure exceptions — there
  are no unique constraints on `is_moderator` that produce a business-meaningful
  `IntegrityError` in the normal revoke flow; all unexpected failures propagate
  to the global handler. Per `agent_docs/error_handling.md` § Adapter: catch
  only when there is business meaning to translate.
- **N3.** `RevokeModeratorResponse` uses `model_config = ConfigDict(from_attributes=True)`.
  Per `agent_docs/entry_points/fastapi.md` § Request and Response schemas.
- **N4.** Every new `.py` file in this slice starts with
  `# FEATURE: revoke_moderator — <purpose>` on line 1. Per
  `agent_docs/stable_vs_feature.md`.
- **N5.** `RevokeModeratorUseCase` never raises `HTTPException`; it raises only
  `DomainError` subclasses. Per CLAUDE.md universal hard rule 1.
- **N6.** No cross-slice imports: `RevokedUser` is defined in this slice's
  `domain/entities.py` and is not imported from `assign_moderator` or any other
  slice. Per `agent_docs/architecture.md` § Layer rules.
- **N7.** All database I/O in `RevokeModeratorAdapter` uses `async def` and
  `await`. No synchronous ORM calls. Per CLAUDE.md locked technology stack.
- **N8.** `mypy` strict passes for all new code under `src/app/`. Per CLAUDE.md
  § Verifying changes.
- **N9.** `ruff format` and `ruff check` pass for all new code. Per CLAUDE.md
  § Verifying changes.
- **N10.** `RevokeModeratorAdapter` explicitly inherits from `RevokeModeratorPort`:
  `class RevokeModeratorAdapter(RevokeModeratorPort):`. Per
  `agent_docs/architecture.md` § Adapter pattern (canonical).
- **N11.** `RevokeModeratorPort` carries the `@runtime_checkable` decorator. Per
  `agent_docs/architecture.md` § Port pattern (canonical).
- **N12.** All files under `src/app/` use relative imports only; absolute
  imports (`from app.…`) are used only in test files. Per
  `agent_docs/architecture.md` § Import conventions.

## Out of scope

- Assigning moderator status — slice 0015.
- `get_current_moderator` auth dependency — slices 0017 and 0019.
- Exposing `moderator_granted_by_user_id` in any response.
- Full revocation history audit log.
- Cache invalidation for user profile responses.
- Rate limiting on this endpoint.
- Preventing a superuser from revoking their own moderator flag.
- Cascading effects on existing moderation decisions when a moderator is revoked.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (401 case) |
| F2 | endpoint integration test (403 case) |
| F3 | use-case unit test (superuser check branch) |
| F4 | use-case unit test (not found branch); endpoint integration test (404 case) |
| F5 | use-case unit test (not a moderator branch); endpoint integration test (409 case) |
| F6 | use-case unit test (happy path) |
| F7 | adapter unit test (revoke happy path — direct DB assertion) |
| F8 | adapter unit test (revoke happy path — returned entity assertion) |
| F9 | adapter unit test (get_by_username not found) |
| F10 | adapter unit test (get_by_username found) |
| F11 | adapter unit test (get_by_username soft-deleted excluded) |
| F12 | endpoint integration test (200 happy path); outside-in test |
| F13 | endpoint integration test (404 case) |
| F14 | endpoint integration test (409 case) |
| F15 | outside-in test (step 5 — GET read path assertion) |
| N1–N12 | code review checklist in validation.md |
