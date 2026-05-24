# 0041 · get_user_by_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `GET /api/v1/user/{user_id}` accepts `user_id` as an
  integer path parameter and returns `GetUserByIdResponse` with HTTP 200 when
  an active (non-deleted) user with that ID exists.
- **F2.** `GetUserByIdResponse` contains exactly seven fields: `id` (`int`),
  `name` (`str`), `username` (`str`), `email` (`str`), `profile_image_url`
  (`str`), `tier_id` (`int | None`), `is_moderator` (`bool`).
- **F3.** The endpoint returns HTTP 404 when no active user with the given
  `user_id` exists; the response body is
  `{"error": {"code": "notfound", "message": "User not found"}}`.
- **F4.** The endpoint returns HTTP 422 when `user_id` is not a valid integer
  (FastAPI coerces the path parameter; no custom logic is required).
- **F5.** `GetUserByIdUseCase.__call__` raises `NotFoundDomainError("User not
  found")` when `GetUserByIdPort.get` returns `None`.
- **F6.** `GetUserByIdUseCase.__call__` returns the `FoundUser` entity
  unchanged when `GetUserByIdPort.get` returns one.
- **F7.** `GetUserByIdAdapter.get` queries `User` by primary key
  (`User.id == query.user_id`) with an additional `User.is_deleted == False`
  filter.
- **F8.** `GetUserByIdAdapter.get` returns `None` when the query yields no
  matching row.
- **F9.** `GetUserByIdAdapter.get` returns `None` when the matching row has
  `is_deleted=True`.
- **F10.** The old route `GET /api/v1/user/{username}` (string path parameter)
  is removed; the endpoint no longer exists.
- **F11.** The endpoint requires no authentication (public endpoint).

## Non-functional requirements

- **N1.** `GetUserByIdUseCase` is a class with `__call__()`; called as
  `await use_case(query)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `GetUserByIdAdapter` contains no `try/except` — the read-only query
  has no business-meaningful infrastructure exception to translate; all
  infrastructure failures propagate to the global handler. Per
  `agent_docs/error_handling.md` § Right shape: read-only query, no catch.
- **N3.** `GetUserByIdResponse` uses `model_config = ConfigDict(from_attributes=True)`.
  Per `agent_docs/architecture.md` § Command vs Request, Entity vs Response.
- **N4.** All new files under `src/app/features/users/get_user_by_id/` start
  with `# FEATURE: get_user_by_id — <purpose>`. Per
  `agent_docs/stable_vs_feature.md`.
- **N5.** `GetUserByIdUseCase` never raises `HTTPException`; it raises only
  `DomainError` subclasses. Per `CLAUDE.md` Universal hard rule 1.
- **N6.** No cross-slice imports; `get_user_by_id` imports nothing from another
  slice's `domain/`, `data/`, or `presentation/`. Per `CLAUDE.md` Universal
  hard rule 7.
- **N7.** All database calls are `async def` + `await`; no synchronous ORM
  calls. Per `CLAUDE.md` Forbidden without explicit user approval.
- **N8.** `mypy src/app` passes with strict settings for all new code.
  Per `CLAUDE.md` Verifying changes.
- **N9.** `ruff format` and `ruff check` pass for all new code.
  Per `CLAUDE.md` Verifying changes.
- **N10.** `GetUserByIdAdapter` explicitly inherits from `GetUserByIdPort`
  (`class GetUserByIdAdapter(GetUserByIdPort):`). Per `agent_docs/architecture.md`
  § Terminology: port and adapter.
- **N11.** `GetUserByIdPort` carries `@runtime_checkable`. Per
  `agent_docs/architecture.md` § Port pattern (canonical).
- **N12.** `GetUserByIdUseCase` input is `GetUserByIdQuery`, not the HTTP path
  parameter directly; the router converts the path parameter to the query. Per
  `CLAUDE.md` Universal hard rule 10.
- **N13.** The `get_user_by_username` slice folder and all its files are fully
  removed; no `get_user_by_username` symbol remains in `src/`.

## Out of scope

- All other users routes (`update_user`, `delete_user`, `delete_db_user`,
  `assign_moderator`, `revoke_moderator`, `get_user_tier`) — slices 0043–0050.
- `list_posts` route migration — slice 0042.
- Username-based lookup for internal post author resolution (`UserLookupPort`).
- Caching (`@cache` decorator).
- Updating the existing outside-in test for slice 0004 (done separately after
  this slice lands).

## Traceability

| Requirement | Verified by |
|---|---|
| F1, F2 | endpoint integration test — happy path (200 + all fields) |
| F3 | endpoint integration test — 404 case; outside-in test step 2 |
| F4 | endpoint integration test — 422 case; outside-in test step 3 |
| F5 | use-case unit test — not-found branch |
| F6 | use-case unit test — happy-path branch |
| F7 | adapter unit test — found case (verifies PK filter + soft-delete filter) |
| F8 | adapter unit test — not-found case |
| F9 | adapter unit test — soft-deleted case |
| F10 | outside-in test step 3 (string username → 422) |
| F11 | endpoint integration test — no auth header required |
| N1–N13 | code review checklist in validation.md |
