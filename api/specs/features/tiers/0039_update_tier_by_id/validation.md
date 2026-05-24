# 0039 · update_tier_by_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `uvicorn src.app.main:app --reload` (from the `api/` root).
- Test Postgres running: `docker compose up test-db -d`.
- A tier row seeded in the DB and its `id` known (see S1 setup).
- A valid superuser Bearer token in `$TOKEN` (obtain via `POST /api/v1/login`).
- A second terminal for DB verification queries (use `psql` or a GUI client against the dev DB).

## Manual scenarios

### S1 — Happy path: rename by id

**Setup:**

```sql
INSERT INTO tier (name, created_at) VALUES ('silver', NOW()) RETURNING id;
-- note the returned id, e.g. 42
```

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/42 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "gold"}' | python -m json.tool
```

**Expected:**

- HTTP 200.
- Body: `{"message": "Tier updated"}`.
- DB: row with `id=42` now has `name='gold'` and a non-null `updated_at`; no row with `name='silver'` remains.

```sql
SELECT id, name, updated_at FROM tier WHERE id = 42;
```

**Covers:** F1, F9, F10, F12, F14.

---

### S2 — Tier not found: id does not exist

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/999999 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "whatever"}' | python -m json.tool
```

**Expected:**

- HTTP 404.
- Body: `{"error": {"code": "notfound", "message": "Tier not found"}}`.

**Covers:** F7, F8, F13.

---

### S3 — Duplicate name: target name already taken

**Setup:**

```sql
INSERT INTO tier (name, created_at) VALUES ('bronze', NOW()) RETURNING id;
-- e.g. id 43
INSERT INTO tier (name, created_at) VALUES ('diamond', NOW());
```

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/43 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "diamond"}' | python -m json.tool
```

**Expected:**

- HTTP 409.
- Body: `{"error": {"code": "duplicatevalue", "message": "Tier name already exists"}}`.
- DB: both rows unchanged.

**Covers:** F11, F15.

---

### S4 — Forbidden: authenticated non-superuser

**Steps** (use a non-superuser token `$USER_TOKEN`):

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/1 \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "any"}' | python -m json.tool
```

**Expected:**

- HTTP 403.

**Covers:** F6.

---

### S5 — Unauthorized: no bearer token

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "any"}' | python -m json.tool
```

**Expected:**

- HTTP 401.

**Covers:** F5.

---

### S6 — Validation: missing `name` field

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' | python -m json.tool
```

**Expected:**

- HTTP 422.
- Body contains `"loc": ["body", "name"]`.

**Covers:** F2.

---

### S7 — Validation: empty `name` field

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": ""}' | python -m json.tool
```

**Expected:**

- HTTP 422.
- Body contains `"loc": ["body", "name"]`.

**Covers:** F3.

---

### S8 — Validation: non-integer id in path

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/not-a-number \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "any"}' | python -m json.tool
```

**Expected:**

- HTTP 422.
- Body contains `"loc": ["path", "id"]`.

**Covers:** F4.

---

## Code review checklist

This checklist is for a modification of the existing `update_tier` slice (0036). No new slice folder is created; all changes are in-place edits to existing source and test files.

### Modified files

- [ ] Every modified `.py` file retains its existing `# FEATURE: update_tier — <purpose>` header unchanged on line 1.
- [ ] No new `.py` files have been created that are missing a `# FEATURE:` or `# STABLE:` header.
- [ ] No STABLE files were modified. (`bootstrap/container.py`, `bootstrap/router.py`, `.importlinter` are all **unchanged** — the DI providers already exist and the router entry already exists.)

### Domain layer

- [ ] `UpdateTierCommand` has fields `id: int` and `name: str` (not `new_name`).
- [ ] `UpdateTierPort` protocol methods are `get(self, tier_id: int) -> TierItem | None` and `update(self, tier_id: int, name: str) -> None`.
- [ ] `UpdateTierPort` retains the `@runtime_checkable` decorator.
- [ ] `UpdateTierPort` retains `Protocol` as base class.
- [ ] `UpdateTierUseCase.__call__` passes `command.id` to `port.get` and `(command.id, command.name)` to `port.update`.
- [ ] Use-case raises `NotFoundDomainError("Tier not found")` — exact message — when `port.get` returns `None`.
- [ ] Use-case does not catch `DuplicateValueDomainError`; it propagates naturally.
- [ ] No `HTTPException` raised inside the use-case.
- [ ] `domain/` imports only stdlib and pydantic — no SQLAlchemy, no `adapters/`, no framework.

### Adapter layer

- [ ] `UpdateTierAdapter` class signature remains `class UpdateTierAdapter(UpdateTierPort):` — explicit port inheritance.
- [ ] `adapter.get` filters by `Tier.id == tier_id`, not by `Tier.name`.
- [ ] `adapter.get` has no `try/except` block (read-only, nothing business-meaningful to catch).
- [ ] `adapter.update` filters by `Tier.id == tier_id` and sets `name=name, updated_at=func.now()`.
- [ ] `adapter.update` wraps both `execute` and `commit` in the same `try` block (asyncpg raises `IntegrityError` at execute time for UPDATE, not at commit time).
- [ ] `adapter.update` catches only `IntegrityError`, not `Exception`.
- [ ] `raise DuplicateValueDomainError("Tier name already exists") from exc` preserves the original cause.
- [ ] No other exception types are caught in the adapter.
- [ ] Adapter does not log exceptions.

### Presentation layer

- [ ] Router path is `/tier/{id}` (integer, not string).
- [ ] Endpoint parameter is `id: int`, not `name: str`.
- [ ] `UpdateTierRequest` has field `name: str = Field(min_length=1)` — not `new_name`.
- [ ] Router builds `UpdateTierCommand(id=id, name=body.name)`.
- [ ] No `try/except` in the router function.
- [ ] `UpdateTierResponse` is unchanged (`message: str = "Tier updated"`).

### Import hygiene

- [ ] All imports inside `src/app/` are relative (`from ..domain...`, `from ...._shared...`). No `from app...` inside source.
- [ ] No cross-slice imports (no imports from another slice's `domain/`, `data/`, or `presentation/`).
- [ ] Import depths match existing 0036 adapter depths (4 dots from `data/` to `tiers/`, 5 dots from `data/` to `app/`).

### Tests

- [ ] `test_use_case.py`: `_CMD` uses `UpdateTierCommand(id=1, name="gold")`; happy-path asserts `port.update.assert_called_once_with(1, "gold")`.
- [ ] `test_adapter.py`: `_seed_tier` returns `int` (from `RETURNING id`); all `adapter.get` and `adapter.update` calls use integer ids.
- [ ] `test_router.py`: endpoint template is `/api/v1/tier/{id}`; JSON body uses `"name"` key; ids come from `RETURNING id`.
- [ ] `update_tier_outside_in_test.py`: both INSERT statements use `RETURNING id`; endpoint URLs include the captured id; body uses `"name"`.
- [ ] No test file imports from `src/app/` using absolute paths (`from app...` only, never `from src.app...`).
- [ ] All test functions that use async operations are decorated with `pytest.mark.asyncio` (or inherit from `pytestmark`).

### Quality gates

Run from the `api/` directory before merging:

```bash
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest tests/features/tiers/0036_update_tier/ -v
pytest
```

- [ ] `ruff format` reports no changes.
- [ ] `ruff check` reports zero violations.
- [ ] `mypy src/app` reports zero errors.
- [ ] All tests in `tests/features/tiers/0036_update_tier/` are GREEN.
- [ ] `tests/smoke/test_app_starts.py` passes (app boots and `/api/v1/health` responds 200).
- [ ] Full `pytest` suite is GREEN (no regressions in other slices).
