# 0049 · rate_limits_route_to_user_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `GET /api/v1/user/{user_id}/rate_limits` accepts `user_id: int` as a
  path parameter and, when the user exists and has a tier with rate-limit rows,
  returns HTTP 200 with a body carrying the user fields plus a populated
  `tier_rate_limits` list.
- **F2.** The endpoint returns HTTP 200 with `tier_rate_limits == []` when the
  user exists but has no tier assigned (`tier_id is None`); in this case the tier
  and rate-limit repositories are not queried.
- **F3.** `read_user_rate_limits` looks the user up by integer primary key:
  it calls `crud_users.get(db=db, id=user_id, schema_to_select=UserRead)`
  (replacing the former `username=username` lookup).
- **F4.** `read_user_rate_limits` raises `NotFoundDomainError("User not found")`
  when `crud_users.get` returns `None`.
- **F5.** `read_user_rate_limits` raises `NotFoundDomainError("Tier not found")`
  when the user has a `tier_id` but `crud_tiers.get` returns `None`.
- **F6.** When the user has a valid tier, `tier_rate_limits` is set to the
  `["data"]` payload returned by `crud_rate_limits.get_multi(db=db, tier_id=db_tier["id"])`,
  and the response body otherwise matches the serialized `UserRead` fields
  (`id`, `name`, `username`, `email`, `profile_image_url`, `tier_id`).
- **F7.** The endpoint returns HTTP 401 for a request with no/invalid
  credentials, enforced by the route-level `Depends(get_current_superuser)`.
- **F8.** The endpoint returns HTTP 403 for an authenticated non-superuser,
  enforced by the route-level `Depends(get_current_superuser)`.
- **F9.** The endpoint returns HTTP 404 when `user_id` matches no user, and HTTP
  404 when the user's referenced tier row is absent — `NotFoundDomainError` is
  translated to HTTP 404 by the global exception handler in
  `adapters/http/exception_handlers.py`.
- **F10.** The endpoint returns HTTP 422 when `user_id` is a non-integer value
  (e.g. `"abc"`), enforced by FastAPI's path parameter type coercion.
- **F11.** The route is registered as
  `router.get("/user/{user_id}/rate_limits", dependencies=[Depends(get_current_superuser)])(read_user_rate_limits)`
  in `features/users/router.py` (path segment changed from `{username}` to
  `{user_id}`; auth dependency unchanged).

## Non-functional requirements

- **N1.** `read_user_rate_limits` raises only `DomainError` subclasses
  (`NotFoundDomainError`); no `HTTPException` is raised in the function. Per
  `agent_docs/error_handling.md`.
- **N2.** The function performs only read-only repository calls and adds no
  `try/except`; unknown infrastructure exceptions propagate to the global
  handler, and the function does not log. Per `agent_docs/error_handling.md`
  § read-only query, no catch.
- **N3.** No new `DomainError` subclass is introduced; only the existing
  `NotFoundDomainError` (STABLE, `app/domain/errors.py`) is used. Per
  `agent_docs/error_handling.md` § DomainError hierarchy.
- **N4.** No cross-slice imports beyond the allowed `repository.py` cross-imports
  (`crud_tiers`, `crud_rate_limits`); no other slice's `schemas.py` or `router.py`
  is imported. Per `agent_docs/architecture.md` § Layer rules and `src/CLAUDE.md`
  § Dependency Rules.
- **N5.** All database operations remain `async def` + `await`; no synchronous DB
  calls. Per the locked technology stack in `CLAUDE.md`.
- **N6.** The modified FEATURE files retain `# FEATURE: <purpose>` on line 1
  (`user_rate_limits_get.py`, `router.py`). Per `agent_docs/stable_vs_feature.md`.
- **N7.** No STABLE file is modified; the route lives in `features/users/router.py`
  (FEATURE), and the function requires no `bootstrap/container.py` provider,
  `wiring_config` entry, or `.importlinter` entry. Per
  `agent_docs/stable_vs_feature.md`.
- **N8.** All imports inside `src/app/` are relative; test imports are absolute
  through `app.*`. Per `agent_docs/architecture.md` § Import conventions.
- **N9.** `mypy src/app` (strict) passes with no new errors introduced by this
  slice.
- **N10.** `ruff format src/app` and `ruff check src/app` pass with no new
  violations.

## Out of scope

- `patch_user_tier` / `update_user_tier` route (`PATCH /user/{username}/tier`) —
  slice 0050.
- The `{tier_name}` routes in the `rate_limits` feature
  (`GET /tier/{tier_name}/rate_limits`) — separate task.
- Other routes in the `{username}` → `{user_id}` migration series (0041–0050, 0042).
- Refactoring the endpoint into a hexagonal slice (port/adapter/use-case) — the
  PRD intentionally keeps it a shallow aggregator function.
- Changing the response shape, adding a `response_model`, caching, or rate
  limiting — none are added here.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (200 with tier); outside-in test |
| F2 | endpoint integration test (200 empty rate limits); function-level unit test |
| F3 | function-level unit test (asserts `crud_users.get` called with `id=user_id`) |
| F4 | function-level unit test (user `None` → NotFoundDomainError); endpoint integration test (404) |
| F5 | function-level unit test (tier `None` → NotFoundDomainError) |
| F6 | function-level unit test (tier_rate_limits == repository data); endpoint integration test |
| F7 | endpoint integration test (401 case) |
| F8 | endpoint integration test (403 case) |
| F9 | endpoint integration test (404 case); outside-in test (unknown id) |
| F10 | endpoint integration test (422 case) |
| F11 | endpoint integration test (route reachable at new path); smoke test |
| N1–N10 | code review checklist in validation.md |
