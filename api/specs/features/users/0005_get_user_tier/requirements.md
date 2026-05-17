# 0005 · get_user_tier — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `GET /api/v1/user/{username}/tier` accepts a `username`
  path parameter and returns a `GetUserTierResponse` with status `200` when the
  user exists and has a tier assigned.
- **F2.** `GetUserTierResponse` contains exactly three fields: `tier_id: int`,
  `tier_name: str`, `tier_created_at: datetime`.
- **F3.** The endpoint returns HTTP `200` with a `null` body when the user
  exists but has `tier_id = None`.
- **F4.** The endpoint returns HTTP `404` with body
  `{"error": {"code": "notfound", "message": "User not found"}}` when no active
  (non-deleted) user row exists for the given username.
- **F5.** The endpoint returns HTTP `404` with body
  `{"error": {"code": "notfound", "message": "Tier not found"}}` when the user
  has a non-null `tier_id` but the corresponding tier row does not exist.
- **F6.** The use case raises `NotFoundDomainError("User not found")` when the
  port returns a `UserNotFound` sentinel.
- **F7.** The use case raises `NotFoundDomainError("Tier not found")` when the
  port returns a `TierNotFound` sentinel.
- **F8.** The use case returns `None` when the port returns `None` (user has no
  tier assigned).
- **F9.** The use case returns the `FoundUserTier` entity unchanged when the
  port returns a populated `FoundUserTier`.
- **F10.** The adapter returns `UserNotFound()` when the `User` query yields no
  row matching `username` with `is_deleted = False`.
- **F11.** The adapter returns `None` when the user row is found but
  `user.tier_id` is `None`.
- **F12.** The adapter returns a `FoundUserTier` with fields `tier_id`,
  `tier_name`, `tier_created_at` populated from the `Tier` row when both the
  user and tier rows are found.
- **F13.** The adapter returns `TierNotFound()` when the user row is found with
  a non-null `tier_id` but the corresponding `Tier` query yields no row.
- **F14.** The adapter applies the soft-delete filter
  `User.is_deleted == False` to the user query.
- **F15.** The adapter issues two separate queries: one for `User`, one for
  `Tier`; it does not use a JOIN.
- **F16.** The old free function `read_user_tier` in
  `use_cases/user_tier_get.py` is deleted once the slice is wired, leaving no
  dead code.
- **F17.** The HTTP route and method remain `GET /user/{username}/tier`
  (identical to the current implementation).

## Non-functional requirements

- **N1.** `GetUserTierUseCase` is a class with `__call__()`; called as
  `await use_case(query)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** The adapter catches no infrastructure exceptions; read-only queries
  have no business-meaningful exceptions to translate. Other infrastructure
  failures propagate to the global handler per `agent_docs/error_handling.md` §
  Right shape: read-only query, no catch.
- **N3.** `GetUserTierResponse` uses `model_config = ConfigDict(from_attributes=True)`.
- **N4.** All new `.py` files start with `# FEATURE: get_user_tier — <purpose>`
  on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** `GetUserTierUseCase` never raises `HTTPException`; it raises only
  `NotFoundDomainError`. Per `agent_docs/error_handling.md` § Three layers, three
  responsibilities.
- **N6.** No import crosses slice boundaries except through the feature's
  `_shared/` or via ORM models in `adapters/db/models/`. Per
  `agent_docs/architecture.md` § Layer rules.
- **N7.** All database access is `async def` + `await`; no synchronous ORM
  calls. Per `CLAUDE.md` locked technology stack.
- **N8.** `mypy src/app` passes with strict settings for all new files in this
  slice.
- **N9.** `ruff format src/app` and `ruff check src/app` pass for all new files
  in this slice.
- **N10.** `GetUserTierAdapter` explicitly inherits from `GetUserTierPort`
  (`class GetUserTierAdapter(GetUserTierPort):`). Per `agent_docs/architecture.md`
  § Terminology: port and adapter.
- **N11.** `GetUserTierPort` carries the `@runtime_checkable` decorator. Per
  `agent_docs/architecture.md` § Port pattern (canonical).
- **N12.** `domain/` files import only stdlib and pydantic; no SQLAlchemy, no
  FastAPI. Per `agent_docs/architecture.md` § Layer rules.
- **N13.** All imports inside `src/app/` are relative; tests use absolute
  imports via `app.*`. Per `agent_docs/architecture.md` § Import conventions.

## Out of scope

- Auth / access control — endpoint stays public.
- Caching (`@cache` decorator) — not present today; not added.
- Query parameters beyond `username`.
- Refactoring other old-style `use_cases/` free functions.
- JOIN optimisation — two separate queries are intentional.
- Changes to `User` or `Tier` ORM models or Alembic migrations.

## Traceability

| Requirement | Verified by |
|---|---|
| F1, F2 | endpoint integration test — happy path (user with tier) |
| F3 | endpoint integration test — user found, no tier |
| F4 | endpoint integration test — username not found |
| F5 | endpoint integration test — dangling tier_id |
| F6 | use-case unit test — port returns `UserNotFound()` |
| F7 | use-case unit test — port returns `TierNotFound()` |
| F8 | use-case unit test — port returns `None` |
| F9 | use-case unit test — port returns `FoundUserTier` |
| F10 | adapter unit test — user row absent |
| F11 | adapter unit test — user row found, tier_id is None |
| F12 | adapter unit test — user and tier rows found |
| F13 | adapter unit test — user row found, tier row absent |
| F14 | adapter unit test — soft-delete filter verified via query predicate |
| F15 | adapter unit test — two separate mock-session calls observed |
| F16 | code review checklist in validation.md |
| F17 | outside-in test + endpoint integration test |
| N1–N13 | code review checklist in validation.md |
