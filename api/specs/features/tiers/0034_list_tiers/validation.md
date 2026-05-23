# 0034 · list_tiers — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test database is running and reachable (`.env` configured).
- A superuser token is available to seed tier data via `POST /api/v1/tier`.
  Obtain it with:

```bash
curl -s -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=<superuser_password>" \
  | jq '.access_token'
```

Store the token in `$TOKEN` for convenience:

```bash
TOKEN=<paste_token_here>
```

Seed two tiers before running scenarios that require existing data:

```bash
curl -s -X POST http://localhost:8000/api/v1/tier \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "free"}'

curl -s -X POST http://localhost:8000/api/v1/tier \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "pro"}'
```

## Manual scenarios

### S1 — Happy path: paginated list with seeded tiers

**Steps:**

1. Seed two tiers (`free`, `pro`) as shown in Prerequisites.
2. Call:
```bash
curl -s http://localhost:8000/api/v1/tiers | jq .
```

**Expected:**

- Status 200.
- Body contains `items`, `total_count`, `page`, `items_per_page` — no `data`
  key, no `has_more` field.
- `total_count` is `2`.
- `items` has two entries, each with `id` (int), `name` (str), `created_at`
  (datetime string).
- Items are ordered by `id` ascending (`free` before `pro` if created in that
  order).

**Covers:** F1, F6, F7, F10.

---

### S2 — Default query parameters

**Steps:**

1. Call without any query parameters:
```bash
curl -s "http://localhost:8000/api/v1/tiers" | jq '{page, items_per_page}'
```

**Expected:**

- `page` is `1`.
- `items_per_page` is `10`.

**Covers:** F1 (default values).

---

### S3 — Empty database returns 200 with empty list

**Steps:**

1. Ensure no tiers exist in the database (use a fresh test DB or truncate the
   `tier` table).
2. Call:
```bash
curl -s http://localhost:8000/api/v1/tiers | jq .
```

**Expected:**

- Status 200.
- `items` is `[]`.
- `total_count` is `0`.
- `page` is `1`, `items_per_page` is `10`.

**Covers:** F2.

---

### S4 — `page=0` is rejected

**Steps:**

1. Call:
```bash
curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000/api/v1/tiers?page=0"
```

**Expected:**

- Status 422.
- Body contains validation error referencing the `page` parameter.

**Covers:** F3.

---

### S5 — `items_per_page=0` is rejected

**Steps:**

1. Call:
```bash
curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000/api/v1/tiers?items_per_page=0"
```

**Expected:**

- Status 422.

**Covers:** F4.

---

### S6 — `items_per_page=101` is rejected

**Steps:**

1. Call:
```bash
curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000/api/v1/tiers?items_per_page=101"
```

**Expected:**

- Status 422.

**Covers:** F4.

---

### S7 — No authentication required

**Steps:**

1. Call without any `Authorization` header:
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/v1/tiers
```

**Expected:**

- Status 200 (not 401 or 403).

**Covers:** F5.

---

### S8 — Pagination: `total_count` reflects full count; `items` is truncated

**Steps:**

1. Seed three tiers (`free`, `pro`, `enterprise`).
2. Call page 1 with `items_per_page=2`:
```bash
curl -s "http://localhost:8000/api/v1/tiers?page=1&items_per_page=2" | jq '{total_count, items_count: (.items | length)}'
```
3. Call page 2 with `items_per_page=2`:
```bash
curl -s "http://localhost:8000/api/v1/tiers?page=2&items_per_page=2" | jq '{total_count, items_count: (.items | length)}'
```

**Expected:**

- Both calls return status 200.
- Both return `total_count: 3`.
- Page 1: `items_count: 2`.
- Page 2: `items_count: 1`.

**Covers:** F11.

---

### S9 — Stable ordering by `id`

**Steps:**

1. Seed two tiers in order: `free` first, then `pro`.
2. Call:
```bash
curl -s http://localhost:8000/api/v1/tiers | jq '[.items[].name]'
```
3. Call again immediately.

**Expected:**

- Both calls return `["free", "pro"]` (ascending `id` order).
- Order is identical between calls.

**Covers:** F10.

---

### S10 — Old response shape is gone

**Steps:**

1. Call:
```bash
curl -s http://localhost:8000/api/v1/tiers | jq 'keys'
```

**Expected:**

- Response keys are `["items", "items_per_page", "page", "total_count"]`.
- No `data` key.
- No `has_more` key.

**Covers:** F7, F12.

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/tiers/list_tiers/` with
      `domain/`, `data/`, `presentation/` subfolders, each containing
      `__init__.py`.
- [ ] `ListTiersUseCase` is a class; `__call__(query: ListTiersQuery) -> TierPage`
      is the only public method; no free-function use-case.
- [ ] `ListTiersPort` lives in `domain/ports/list_tiers_port.py`, is decorated
      `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `ListTiersAdapter` class signature is
      `class ListTiersAdapter(ListTiersPort):` — explicit port inheritance is
      present.
- [ ] `ListTiersAdapter` is the only place SQLAlchemy is used; no SQLAlchemy
      imports in `domain/` or `presentation/`.
- [ ] Router function converts query params → `ListTiersQuery`, awaits
      use-case, converts result → `ListTiersResponse`; no business logic in
      the router function body.
- [ ] No cross-slice imports: nothing imported from another feature's `domain/`,
      `data/`, or `presentation/`. Imports from `tiers/_shared/entities.py` are
      permitted (same feature).
- [ ] All imports inside `src/app/features/tiers/list_tiers/` are **relative**
      (`from ..domain...`, `from ...._shared...`). No `from app...` or
      `from src.app...` inside source.
- [ ] No `HTTPException` raised anywhere in `list_tiers/`.
- [ ] `TierItem` and `TierPage` are imported from
      `tiers/_shared/entities.py`; they are not redefined locally.

### Error handling

- [ ] `ListTiersAdapter.list()` contains **no `try/except` block** — this is
      a read-only query and no business-meaningful exception path exists.
- [ ] No broad `except Exception` anywhere in the slice.
- [ ] Adapter does not log exceptions; no `logger.error` or `logger.warning`
      calls in the adapter.
- [ ] No new `DomainError` subclass added inside the slice folder. No new
      subclass in `app/domain/errors.py` either (none is required for this
      slice).

### Files and headers

- [ ] Every new `.py` file starts with `# FEATURE: list_tiers — <purpose>` on
      line 1.
- [ ] No STABLE file was modified beyond `bootstrap/container.py` (two new
      providers + one `wiring_config` entry) and `features/tiers/router.py`
      (removal of `read_tiers` handler + inclusion of `list_tiers_router`).
- [ ] `TierItemSchema` and `ListTiersResponse` have
      `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` calls; `model.model_dump()` is used where needed.

### DI wiring

- [ ] `list_tiers_adapter = providers.Factory(ListTiersAdapter, session_factory=session_factory)`
      added to `Container`.
- [ ] `list_tiers_use_case = providers.Factory(ListTiersUseCase, port=list_tiers_adapter)`
      added to `Container`.
- [ ] `f"{_app_pkg}.features.tiers.list_tiers.presentation.router"` added to
      `Container.wiring_config.modules`.
- [ ] Endpoint uses
      `Annotated[ListTiersUseCase, Depends(Provide[Container.list_tiers_use_case])]`.
- [ ] `@inject` decorator is present on the endpoint function.

### `features/tiers/router.py` aggregator

- [ ] `read_tiers` handler is removed from `features/tiers/router.py`.
- [ ] FastCRUD imports (`compute_offset`, `paginated_response`,
      `PaginatedListResponse`) are removed if they are no longer used by any
      remaining handler.
- [ ] `from .list_tiers.presentation.router import router as list_tiers_router`
      is added.
- [ ] `router.include_router(list_tiers_router)` is called.
- [ ] Remaining handlers (`read_tier`, `patch_tier`, `erase_tier`) are
      untouched.

### Tests

- [ ] Use-case unit test exists at
      `tests/features/tiers/0034_list_tiers/domain/test_use_case.py` and
      passes.
- [ ] Adapter unit test exists at
      `tests/features/tiers/0034_list_tiers/data/test_adapter.py`; covers
      happy path, pagination, and empty-table case; uses real Postgres — no
      mocks for the session.
- [ ] Endpoint integration test exists at
      `tests/features/tiers/0034_list_tiers/presentation/test_router.py`;
      uses `httpx.AsyncClient` with test Postgres; covers happy path, empty DB,
      pagination truncation, unauthenticated access, and 422 for invalid params.
- [ ] Outside-in test exists at
      `tests/features/tiers/0034_list_tiers/list_tiers_outside_in_test.py`
      and is GREEN.
- [ ] No test leaves rows in the DB after it completes (transaction rollback or
      explicit cleanup is in place).

### Quality gates

Run from the project root before approving:

```bash
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. In particular:

- `tests/smoke/test_app_starts.py` must pass — it boots the app in a subprocess
  and pings `/api/v1/health`. A failure here (even with all other tests green)
  means the slice is **not done**; it usually signals a relative/absolute import
  mix-up that uvicorn catches but pytest's PYTHONPATH hides.
- `pytest tests/features/tiers/0034_list_tiers/list_tiers_outside_in_test.py -v`
  must be GREEN before the PR is considered complete.
