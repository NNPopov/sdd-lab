# 0002 · refactor_create_user_adapter — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test database empty or clean (no pre-existing `alice@example.com` / `alice`
  rows).
- No authentication required for `POST /api/v1/user`.

## Manual scenarios

This slice is a pure refactor. The observable API contract is unchanged.
Manual scenarios verify that no regression was introduced in the three paths
that the adapter is responsible for.

### S1 — Successful user creation (happy path)

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/user \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice", "username": "alice", "email": "alice@example.com", "password": "Pa$$w0rd1"}' \
  | python -m json.tool
```

**Expected:**

- HTTP status **201**.
- Response body contains `id`, `name`, `username`, `email` matching the
  submitted values.
- Password field is **absent** from the response.

**Covers:** F7.

---

### S2 — Duplicate email returns 409

**Steps:**

1. Run S1 to create the `alice@example.com` row.
2. Run the same curl again (same email, same or different username).

**Expected:**

- HTTP status **409**.
- Response body `{"message": "Email is already registered"}` (or equivalent
  duplicate-value message configured in the use case).

**Covers:** F8 (IntegrityError → DuplicateValueDomainError path).

---

### S3 — Duplicate username returns 409

**Steps:**

1. Run S1 to create `alice`.
2. Run curl again with the same `username` but a different email.

**Expected:**

- HTTP status **409**.
- Response body contains a `message` field indicating the conflict.

**Covers:** F8 (use-case check path via `username_exists`).

---

### S4 — Infrastructure failure returns 500, not UnknownDomainError

**Steps:**

1. Stop the PostgreSQL server (or revoke the DB user's connection privileges).
2. Send a `POST /api/v1/user` request.

**Expected:**

- HTTP status **500**.
- Response body `{"message": "Internal error"}` — the global handler's
  standard response.
- Application logs show the original `OperationalError` (or similar) with
  full traceback, logged by the global `_catch_all` handler.
- The error is **not** wrapped as `UnknownDomainError` in the log.

**Covers:** F3, F6, F9; N1, N2, N3.

*Note: this scenario is harder to set up and is acceptable to skip in a local
dev environment if the adapter unit tests covering propagation (F3, F6, F9)
are green.*

---

### S5 — Missing required field returns 422

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/user \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice", "email": "alice@example.com", "password": "Pa$$w0rd1"}' \
  | python -m json.tool
```

**Expected:**

- HTTP status **422** (Pydantic validation error — `username` is missing).
- Response body contains a `detail` array identifying the missing field.

**Covers:** regression guard only (Pydantic layer, unchanged by this slice).

---

## Code review checklist

### Adapter error handling (primary focus for this slice)

- [ ] `email_exists` body contains **no** `try/except` — bare session query
      only. (Requirement F3; `agent_docs/error_handling.md` § Right shape:
      read-only query)
- [ ] `username_exists` body contains **no** `try/except` — bare session
      query only. (Requirement F6)
- [ ] `create` has exactly **one** `try/except` block, scoped only to
      `await session.commit()`. `session.add()` and `session.refresh()` are
      outside the `try`. (Requirement F8, F9; plan.md step 6)
- [ ] The `except` clause catches `IntegrityError` only, not `Exception`.
      (Requirement N1; `agent_docs/error_handling.md` § Forbidden patterns)
- [ ] `raise DuplicateValueDomainError(...) from exc` preserves the cause.
      (Requirement F8)
- [ ] No `except Exception` block anywhere in the adapter file. (N1)
- [ ] No `UnknownDomainError` import or usage in the adapter. (N3;
      `agent_docs/error_handling.md` — `UnknownDomainError` is explicitly
      withdrawn)
- [ ] No `structlog` import or `logger` usage in the adapter. (N2;
      `agent_docs/error_handling.md` § Logging policy)

### Port and adapter binding

- [ ] `CreateUserPort` is decorated with `@runtime_checkable` on the line
      immediately before the class definition. (Requirement F10, N6;
      `agent_docs/architecture.md` § Port pattern)
- [ ] `from typing import Protocol, runtime_checkable` — both names imported.
- [ ] `class CreateUserAdapter(CreateUserPort):` — explicit port inheritance
      in the class declaration. (Requirement F11, N7;
      `agent_docs/architecture.md` § Adapter pattern)
- [ ] `CreateUserPort` is imported in `adapter.py` from the correct relative
      path (`..domain.ports.create_user_port`).

### Files and headers

- [ ] `create_user_port.py` retains `# FEATURE: create_user — port protocol.`
      on line 1. (N4; `agent_docs/stable_vs_feature.md`)
- [ ] `adapter.py` retains `# FEATURE: create_user — data adapter.` on line 1.
      (N4)
- [ ] No STABLE file was modified. (N5; `agent_docs/stable_vs_feature.md`)

### Import hygiene

- [ ] All imports inside `src/app/` are relative. No `from app...` or
      `from src.app...` inside the adapter or port. (N8 implicit;
      `agent_docs/architecture.md` § Import conventions)
- [ ] No unused imports remain (verified by `ruff check`). Specifically:
      `structlog`, `logger`, and `UnknownDomainError` are absent from
      `adapter.py`. (plan.md step 2)

### Quality gates

Run from the project root before approving:

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

All four must pass. The `pytest` run includes `tests/smoke/test_app_starts.py`,
which boots the app in a subprocess and pings `/health`. If the smoke test
fails, the slice is **not done** — it typically means a relative import was
accidentally written as an absolute import inside `src/app/`.

### Tests

- [ ] Adapter unit tests exist at
      `tests/features/users/0002_refactor_create_user_adapter/data/test_adapter.py`.
- [ ] `email_exists` happy-path cases (True/False) are covered. (F1, F2)
- [ ] `email_exists` propagation case is covered (F3).
- [ ] `username_exists` happy-path cases (True/False) are covered. (F4, F5)
- [ ] `username_exists` propagation case is covered (F6).
- [ ] `create` success case is covered (F7).
- [ ] `create` `IntegrityError` → `DuplicateValueDomainError` case is covered
      (F8).
- [ ] `create` non-`IntegrityError` propagation case is covered (F9).
- [ ] Existing slice 0001 tests (use-case, endpoint, outside-in) all still
      pass — no regression introduced by this refactor.
