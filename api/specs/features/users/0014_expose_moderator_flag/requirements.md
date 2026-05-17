# 0014 · expose_moderator_flag — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `FoundUser` in `get_user_by_username/domain/entities.py` carries `is_moderator: bool` as a required, non-nullable field.
- **F2.** `GetUserByUsernameAdapter.get()` maps `row.is_moderator` from the fetched `User` ORM row to `FoundUser.is_moderator`; no change to the SQL query is needed.
- **F3.** `GetUserByUsernameResponse` in `get_user_by_username/presentation/schemas.py` includes `is_moderator: bool`.
- **F4.** The `get_user_by_username` router passes `is_moderator=entity.is_moderator` as an explicit keyword argument when constructing `GetUserByUsernameResponse`.
- **F5.** `GET /api/v1/user/{username}` returns `"is_moderator": false` in the JSON response body when the user's `is_moderator` column is `False`.
- **F6.** `GET /api/v1/user/{username}` returns `"is_moderator": true` in the JSON response body when the user's `is_moderator` column is `True`.
- **F7.** `GET /api/v1/user/{username}` returns `is_moderator` without requiring the caller to be authenticated (the endpoint remains public).
- **F8.** `UserMeRead` in `features/users/schemas.py` includes `is_moderator: bool`.
- **F9.** `GET /api/v1/user/me/` returns `"is_moderator": false` in the JSON response body when the authenticated user's `is_moderator` column is `False`.
- **F10.** `GET /api/v1/user/me/` returns `"is_moderator": true` in the JSON response body when the authenticated user's `is_moderator` column is `True`.
- **F11.** `UserRead` (the base class used by the list-users response) is not modified; `GET /api/v1/users` does not include `is_moderator` in its response.
- **F12.** `is_moderator` is always a boolean in both response bodies — never absent, never `null`.

## Non-functional requirements

- **N1.** `GetUserByUsernameUseCase` is unchanged and remains a class with `__call__()`; it is called as `await use_case(query)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `GetUserByUsernameAdapter.get()` contains no `try/except`; it is a read-only query and unexpected infrastructure failures propagate unchanged to the global handler. Per `agent_docs/error_handling.md` § Right shape: read-only query, no catch.
- **N3.** `GetUserByUsernameResponse` retains `model_config = ConfigDict(from_attributes=True)`. Per `agent_docs/entry_points/fastapi.md` § Request and Response schemas.
- **N4.** All modified files retain their `# FEATURE:` header on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised anywhere in the modified files; domain errors propagate as `DomainError` subclasses. Per CLAUDE.md § Universal hard rules.
- **N6.** No cross-slice imports are introduced by this slice; `features/users/schemas.py` is shared within the `users` feature only. Per `agent_docs/architecture.md` § `_shared/` rules.
- **N7.** All modified code paths use `async def` and `await`; no synchronous DB calls are introduced. Per CLAUDE.md § Locked technology stack.
- **N8.** `mypy src/app` strict passes for all modified files with no new type errors. Per CLAUDE.md § Verifying changes.
- **N9.** `ruff format src/app` and `ruff check src/app` pass for all modified files. Per CLAUDE.md § Verifying changes.

## Out of scope

- Assigning or revoking the moderator role — slices 0015 and 0016.
- Exposing `is_moderator` on `GET /api/v1/users` (list users) — parent PRD explicitly excludes it.
- Exposing `moderator_granted_by_user_id` in any response schema.
- A `get_current_moderator` auth dependency — introduced in slices that require it (0017, 0019).
- Caching changes — `get_user_by_username` is not cached; no invalidation logic is needed.
- Any change to `UserRead` base class or other schemas besides `UserMeRead`.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | adapter unit test; code review |
| F2 | adapter unit test |
| F3 | code review (schema field present) |
| F4 | code review (router keyword argument) |
| F5 | endpoint integration test (`GET /user/{username}`, non-moderator case); outside-in test (step 3) |
| F6 | endpoint integration test (`GET /user/{username}`, moderator case); outside-in test (step 6) |
| F7 | endpoint integration test (request sent without `Authorization` header) |
| F8 | code review (schema field present) |
| F9 | endpoint integration test (`GET /user/me/`, non-moderator case); outside-in test (step 4) |
| F10 | endpoint integration test (`GET /user/me/`, moderator case); outside-in test (step 7) |
| F11 | code review (`UserRead` diff is empty) |
| F12 | adapter unit test; endpoint integration tests; outside-in test |
| N1–N9 | code review checklist in `validation.md` |
