---
name: feature-validation
description: This skill should be used when the user wants to generate validation.md for a slice. Trigger when the user invokes /feature-validation, says "write the validation checklist", or asks for manual scenarios after requirements.md exists. Reads prd.md, plan.md, requirements.md. Produces validation.md with manual scenarios and code review checklist.
disable-model-invocation: false
---

# feature-validation

Generate `validation.md` for a slice. It contains two things:

1. **Manual test scenarios** — what a human (or curl) tries against a running
   service to confirm the slice works.
2. **Code review checklist** — what a reviewer looks for in the PR before
   approving.

This is **not** an automated test specification. The automated outside-in test
lives in `tests.md` and `<slice>_outside_in_test.py`.

## Process

### 1. Find the target slice

Same determination as in `/feature-requirements`.

Output: `specs/features/<feature>/<NNNN>_<slice>/validation.md`.

### 2. Read the inputs

Mandatory:

- The slice's `prd.md`, `plan.md`, `requirements.md`.
- `CLAUDE.md`.
- `agent_docs/architecture.md`, `agent_docs/error_handling.md`,
  `agent_docs/stable_vs_feature.md`, `agent_docs/testing.md`.

If `requirements.md` is missing, stop and ask the user to run
`/feature-requirements` first.

### 3. Write `validation.md`

Use this structure:

```markdown
# NNNN · slice_name — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload`).
- Test database seeded with a default user/tier/superuser as appropriate.
- For authenticated endpoints, a valid Bearer token at hand.

## Manual scenarios

Numbered scenarios. Each lists steps, expected result, and the requirement ID
it covers.

### S1 — Happy path

**Steps:**

1. `curl -X POST http://localhost:8000/api/v1/users -H "Content-Type: application/json" -d '{"username": "alice", "email": "a@b.c", "password": "Pa$$w0rd"}'`

**Expected:**

- Status 201.
- Body matches `CreateUserResponse` shape with `id` set.
- DB contains a row in `users` with the username.

**Covers:** F1.

### S2 — Duplicate username

**Steps:**

1. Run S1 to create `alice`.
2. Run S1 again with the same username.

**Expected:**

- Status 409.
- Body `{"message": "Username or email already taken"}`.

**Covers:** F4.

### S3 — Unauthorized access (if applicable)

**Steps:** ...

**Expected:** Status 401, message.

**Covers:** F3.

### S4 — Forbidden (if applicable)

...

### S5 — Validation failure

**Steps:** request with password under 8 chars.

**Expected:** Status 422, `field_errors` payload names `password`.

**Covers:** F2.

(Add as many as needed. Cover at minimum: happy path, every distinct error
status code from requirements, and any boundary condition that is easy to miss.)

## Code review checklist

For the reviewer (human or AI) to verify on the PR. Each line is a yes/no
question. Reject the PR until all are yes.

### Architecture

- [ ] Slice folder exists at `src/app/features/<resource>/<slice>/` with
      `domain/`, `data/`, `presentation/` subfolders.
- [ ] Use-case is a class with `__call__()`, takes a `Command`, returns a
      domain entity.
- [ ] Port lives in `domain/ports/`, uses `@runtime_checkable` decorator
      and inherits from `typing.Protocol`.
- [ ] Adapter class signature is `class XAdapter(XPort):` — explicit
      inheritance from the port is mandatory (greppability + reader intent).
- [ ] Adapter is the only place SQLAlchemy / Redis / HTTP libraries are used.
- [ ] Router accepts `Request`, converts to `Command`, awaits use-case,
      returns `Response`.
- [ ] No cross-slice imports outside `_shared/`.
- [ ] All imports inside `src/app/` are **relative** (`from ..domain...`,
      `from ...._shared...`). No `from app...` or `from src.app...` anywhere
      inside source. Tests use absolute `from app...` only.
- [ ] No `HTTPException` raised inside the use-case.
- [ ] No `try/except` block in the use-case other than for raising
      `DomainError`.

### Error handling

- [ ] Adapter catches **only** business-meaningful infrastructure exceptions
      (e.g. `IntegrityError` → `DuplicateValueDomainError`). No broad
      `except Exception` blocks in the adapter.
- [ ] Read-only operations (existence checks, lookups) have **no
      `try/except`** — failures propagate to the global handler.
- [ ] Each `except` clause names a specific exception type, not `Exception`.
- [ ] `raise DomainError(...) from exc` preserves the cause.
- [ ] Adapter does **not** log exceptions. Logging is the global handler's
      responsibility.
- [ ] No new `DomainError` subclass was added in the slice folder. All
      domain errors live in `app/domain/errors.py`.
- [ ] No `UnknownDomainError` or similar catch-all "domain" error is
      introduced. Unknown failures stay as `Exception` and propagate.

### Files and headers

- [ ] Every new `.py` file starts with `# FEATURE: <slice> — <purpose>` on
      line 1 (or `# STABLE:` for the very rare STABLE additions).
- [ ] No STABLE file was modified beyond `bootstrap/router.py`,
      `bootstrap/container.py` wiring entries, and `adapters/db/models/__init__.py`
      (for new model registration).
- [ ] Pydantic schemas use `model_config = ConfigDict(from_attributes=True)`
      where they wrap ORM models.
- [ ] No `model.dict()` — only `model.model_dump()`.

### DI

- [ ] Provider for adapter added to `Container`.
- [ ] Provider for use-case added to `Container`, takes the adapter.
- [ ] Router module path added to `Container.wiring_config.modules`.
- [ ] Endpoint uses `Annotated[X, Depends(Provide[Container.x])]`.

### Tests

- [ ] Use-case unit test exists and passes.
- [ ] Adapter unit test exists and covers all inner-catch exceptions plus
      the outer-catch path.
- [ ] Endpoint integration test exists and uses `httpx.AsyncClient` with
      `db_session`.
- [ ] Outside-in test exists, is the acceptance gate, and is GREEN.
- [ ] Test database transaction rollback works (no test leaves rows in the DB).

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest                       # includes tests/smoke/test_app_starts.py
alembic upgrade head    # if model changes
```

All must pass. The smoke test inside `pytest` boots the app in a subprocess
and pings `/api/v1/health`. If it fails, the slice is **not done** even if
every other test is green — it usually means an import path that works under
pytest but breaks under uvicorn (e.g. accidental `from app...` inside
`src/app/`).
```

### 4. Save and confirm

Write to `specs/features/<feature>/<NNNN>_<slice>/validation.md`. Tell the
user the file was created, list the scenario count and checklist groups, and
suggest:

> Next step: `/feature-tests` to produce tests.md (outside-in test spec).

## Style rules

- **English only**.
- **Concrete curl commands** in manual scenarios — copyable, runnable.
- **Yes/no checklist items.** Anything that needs a paragraph to explain is a
  scenario, not a checklist item.
- **Coverage:** every functional requirement has at least one scenario.
  Cross-check by listing requirement IDs under "Covers."
- **Code review checklist is mostly stable.** Copy from previous slice and
  adjust only slice-specific entries.

## Hard limits

- ❌ Writing any file other than `validation.md`.
- ❌ Including automated test code. Manual scenarios are curl commands;
  automated tests live in `tests.md` and the test files.
- ❌ Inventing new code review rules. The checklist mirrors agent_docs;
  novel rules belong in agent_docs first.
- ❌ Modifying earlier spec files.

## Common mistakes

- ❌ Manual scenarios that require running pytest. Manual scenarios are for
  humans poking the running service with curl or a browser.
- ❌ Checklist items that overlap functional requirements. The checklist is
  about **how the code is shaped**, not about **whether features work**.
  Feature correctness is verified by tests.
- ❌ Scenarios for edge cases that no automated test covers. Either add an
  automated test or accept that the manual scenario is the only check —
  document this explicitly.
- ❌ Skipping the "Covers" line under a scenario. The traceability matters
  during review.
