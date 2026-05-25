# 0050 · update_user_tier_route_to_user_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `PATCH /api/v1/user/{user_id}/tier` accepts `user_id: int` as a path
  parameter and a `UserTierUpdate` request body (`{"tier_id": int}`), and when
  the user and the requested tier both exist, updates the user's tier and returns
  HTTP 200 with body `{"message": "User <name> Tier updated"}`.
- **F2.** `patch_user_tier` looks the user up by integer primary key: it calls
  `crud_users.get(db=db, id=user_id, schema_to_select=UserRead)` (replacing the
  former `username=username` lookup).
- **F3.** `patch_user_tier` performs the update keyed by integer primary key: it
  calls `crud_users.update(db=db, object=values.model_dump(), id=user_id)`
  (replacing the former `username=username` filter).
- **F4.** `patch_user_tier` raises `NotFoundDomainError("User not found")` when
  `crud_users.get` returns `None`, and does not call `crud_users.update`.
- **F5.** `patch_user_tier` raises `NotFoundDomainError("Tier not found")` when
  `crud_tiers.get(db=db, id=values.tier_id, schema_to_select=TierRead)` returns
  `None`, and does not call `crud_users.update`.
- **F6.** On success the response body is `{"message": f"User {db_user['name']} Tier updated"}`,
  using the user's `name` from the `UserRead` lookup; the tier lookup by
  `values.tier_id` and the success message are unchanged from the pre-migration
  behaviour.
- **F7.** The endpoint returns HTTP 401 for a request with no/invalid
  credentials, enforced by the route-level `Depends(get_current_superuser)`.
- **F8.** The endpoint returns HTTP 403 for an authenticated non-superuser,
  enforced by the route-level `Depends(get_current_superuser)`.
- **F9.** The endpoint returns HTTP 404 when `user_id` matches no user, and HTTP
  404 when `values.tier_id` matches no tier — `NotFoundDomainError` is translated
  to HTTP 404 by the global exception handler in
  `adapters/http/exception_handlers.py`.
- **F10.** The endpoint returns HTTP 422 when `user_id` is a non-integer value
  (e.g. `"abc"`) or the request body is malformed, enforced by FastAPI/Pydantic
  validation.
- **F11.** The route is registered as
  `router.patch("/user/{user_id}/tier", dependencies=[Depends(get_current_superuser)])(patch_user_tier)`
  in `features/users/router.py` (path segment changed from `{username}` to
  `{user_id}`; method and auth dependency unchanged).

## Non-functional requirements

- **N1.** `patch_user_tier` raises only `DomainError` subclasses
  (`NotFoundDomainError`); no `HTTPException` is raised in the function. Per
  `agent_docs/error_handling.md`.
- **N2.** The function adds no `try/except`; unknown infrastructure exceptions
  propagate to the global handler, and the function does not log. Per
  `agent_docs/error_handling.md` § DomainError hierarchy.
- **N3.** No new `DomainError` subclass is introduced; only the existing
  `NotFoundDomainError` (STABLE, `app/domain/errors.py`) is used. Per
  `agent_docs/error_handling.md` § DomainError hierarchy.
- **N4.** No cross-slice imports beyond the allowed `repository.py` cross-imports
  (`crud_tiers`); no other slice's `schemas.py` or `router.py` is imported. Per
  `agent_docs/architecture.md` § Layer rules and `src/CLAUDE.md` § Dependency Rules.
- **N5.** All database operations remain `async def` + `await`; no synchronous DB
  calls. Per the locked technology stack in `CLAUDE.md`.
- **N6.** The modified FEATURE files retain `# FEATURE: <purpose>` on line 1
  (`user_tier_patch.py`, `router.py`). Per `agent_docs/stable_vs_feature.md`.
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

- `get_user_tier` route (`GET /user/{user_id}/tier`) — slice 0048 (done).
- `read_user_rate_limits` route (`GET /user/{user_id}/rate_limits`) — slice 0049
  (done).
- The `{tier_name}` routes in the `rate_limits` feature — separate task.
- Other routes in the `{username}` → `{user_id}` migration series.
- Refactoring the endpoint into a hexagonal slice (port/adapter/use-case) — the
  PRD intentionally keeps it a shallow aggregator function.
- Changing the request/response shape, adding a `response_model`, caching, or
  rate limiting — none are added here.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (200 happy path); outside-in test |
| F2 | function-level unit test (asserts `crud_users.get` called with `id=user_id`) |
| F3 | function-level unit test (asserts `crud_users.update` called with `id=user_id`) |
| F4 | function-level unit test (user `None` → NotFoundDomainError, no update); endpoint integration test (404) |
| F5 | function-level unit test (tier `None` → NotFoundDomainError, no update); endpoint integration test (404) |
| F6 | function-level unit test (success message); endpoint integration test; outside-in test (GET reflects new tier) |
| F7 | endpoint integration test (401 case) |
| F8 | endpoint integration test (403 case) |
| F9 | endpoint integration test (404 cases); outside-in test (unknown id) |
| F10 | endpoint integration test (422 case) |
| F11 | endpoint integration test (route reachable at new path); smoke test |
| N1–N10 | code review checklist in validation.md |
