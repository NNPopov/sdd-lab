# 0034 · list_tiers — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `GET /api/v1/tiers` accepts `page` (int, default 1) and
  `items_per_page` (int, default 10) as query parameters and returns
  `ListTiersResponse` with fields `items`, `total_count`, `page`,
  `items_per_page` and HTTP 200 on success.
- **F2.** When no tiers exist in the database, the endpoint returns HTTP 200
  with `items: []` and `total_count: 0`.
- **F3.** The `page` query parameter must be `>= 1`; a value of `0` or less
  causes HTTP 422 without invoking the use-case.
- **F4.** The `items_per_page` query parameter must be `>= 1` and `<= 100`; a
  value outside this range causes HTTP 422 without invoking the use-case.
- **F5.** The endpoint requires no authentication; an unauthenticated request
  returns HTTP 200.
- **F6.** Each entry in `items` contains `id` (int), `name` (str), and
  `created_at` (datetime) sourced from the corresponding `tier` table row.
- **F7.** The response shape is `items`, `total_count`, `page`,
  `items_per_page` — no `data` key, no `has_more` flag.
- **F8.** `ListTiersUseCase.__call__` delegates entirely to
  `ListTiersPort.list(query)` and returns the result unchanged; it raises no
  `DomainError` subclass under any input.
- **F9.** `ListTiersAdapter.list()` issues exactly two SQLAlchemy statements in
  a single session: `SELECT COUNT(*) FROM tier` for the total count, then
  `SELECT … FROM tier ORDER BY id LIMIT :limit OFFSET :offset` for the page.
- **F10.** Items are ordered by `tier.id` ascending; the order is stable and
  reproducible across identical requests.
- **F11.** When `items_per_page` is smaller than the total tier count, only
  `items_per_page` items are returned; `total_count` still reflects the full
  count of all tiers.
- **F12.** The `read_tiers` handler is removed from
  `src/app/features/tiers/router.py`; after this slice is live, the old
  FastCRUD-based handler is not reachable through any route.

## Non-functional requirements

- **N1.** `ListTiersUseCase` is a class with `__init__(port: ListTiersPort)`
  and `async def __call__(query: ListTiersQuery) -> TierPage`; invoked as
  `await use_case(query)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `ListTiersAdapter` catches no exceptions; the read-only query has no
  business-meaningful exception path. Infrastructure failures propagate to the
  global `_catch_all` handler. Per `agent_docs/error_handling.md` § Right
  shape: read-only query, no catch.
- **N3.** `TierItemSchema` and `ListTiersResponse` carry
  `model_config = ConfigDict(from_attributes=True)`. Per
  `agent_docs/entry_points/fastapi.md` § Request and Response schemas.
- **N4.** All new `.py` files start with
  `# FEATURE: list_tiers — <purpose>` on line 1. Per
  `agent_docs/stable_vs_feature.md`.
- **N5.** `ListTiersUseCase` raises no `HTTPException`; HTTP status translation
  happens only in `adapters/http/exception_handlers.py`. Per CLAUDE.md hard
  rule 1.
- **N6.** Files under `list_tiers/` import only from `tiers/_shared/`,
  `adapters/db/models/`, `domain/`, and (at presentation layer only)
  `bootstrap/container`. No imports from other feature slices. Per CLAUDE.md
  hard rule 7.
- **N7.** All database calls in `ListTiersAdapter` use `async def` and
  `await`; no synchronous SQLAlchemy calls. Per CLAUDE.md locked technology
  stack.
- **N8.** `mypy --strict` passes for all new files under `src/app/`. Per
  CLAUDE.md § Verifying changes.
- **N9.** `ruff format` and `ruff check` pass for all new files. Per CLAUDE.md
  § Verifying changes.
- **N10.** `ListTiersPort` is decorated with `@runtime_checkable` and inherits
  from `typing.Protocol`. Per `agent_docs/architecture.md` § Port pattern
  (canonical).
- **N11.** `ListTiersAdapter` explicitly inherits from `ListTiersPort` in its
  class definition (`class ListTiersAdapter(ListTiersPort):`). Per
  `agent_docs/architecture.md` § Adapter pattern (canonical).
- **N12.** All imports inside `src/app/features/tiers/list_tiers/` use relative
  paths; absolute imports are used only in test files. Per
  `agent_docs/architecture.md` § Import conventions.

## Out of scope

- Migrating `create_tier`, `get_tier`, `update_tier`, or `delete_tier` (slices
  0033, 0035–0037).
- Filtering or sorting tiers by name.
- Cursor-based pagination.
- Authentication or authorisation checks on `GET /tiers`.
- Exposing `updated_at` on tier items.
- Removing `tiers/schemas.py` or `tiers/repository.py` (still referenced by
  `rate_limits/` and `users/` features).
- Caching the response.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2 | endpoint integration test (empty DB case); adapter unit test (empty table) |
| F3 | endpoint integration test (`page=0` → 422) |
| F4 | endpoint integration test (`items_per_page=0` or `> 100` → 422) |
| F5 | endpoint integration test (unauthenticated request → 200) |
| F6 | adapter unit test (field values); endpoint integration test (JSON shape) |
| F7 | endpoint integration test (JSON shape); outside-in test |
| F8 | use-case unit test (mock port returns value; use-case returns it unchanged) |
| F9 | adapter unit test (COUNT + SELECT verified via seeded data and pagination) |
| F10 | adapter unit test (order of items matches id ascending) |
| F11 | adapter unit test (pagination: seed 3, request page 1 / items_per_page 2) |
| F12 | smoke test (`tests/smoke/test_app_starts.py`); endpoint integration test (no old route) |
| N1–N12 | code review checklist in `validation.md` |
