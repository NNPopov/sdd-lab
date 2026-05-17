---
name: feature-spec
description: This skill should be used when the user wants to generate plan.md for a slice. Trigger when the user invokes /feature-spec, says "write the plan", "spec out this slice", or asks for the implementation plan after prd.md exists. Reads prd.md plus architectural context plus the nearest reference slice. Produces plan.md only.
disable-model-invocation: false
---

# feature-spec

Generate `plan.md` for a slice. The plan translates the PRD into a concrete
implementation blueprint: file paths, class names, method signatures, and the
sequence of steps to implement.

## Process

### 1. Find the target slice

The slice is the one currently being worked on:

1. If the user named a slice path, use it.
2. Else find the most recently modified `prd.md` under `specs/features/*/*/`.
3. If ambiguous, ask.

The output path is
`specs/features/<feature>/<NNNN>_<slice>/plan.md`. The folder already exists
because `/to-prd` created it.

### 2. Read the inputs

Mandatory reads:

- The slice's `prd.md`.
- `CLAUDE.md`.
- `agent_docs/architecture.md`.
- `agent_docs/error_handling.md`.
- `agent_docs/stable_vs_feature.md`.
- `agent_docs/entry_points/fastapi.md` (if the slice has an HTTP entry point —
  almost always).

Reference slice: search `specs/roadmap.md` for the most recent existing slice
with the **same operation shape** (e.g. for `delete_post`, look for
`delete_tier` or `delete_user`). Read its `plan.md`. If no shape-match exists,
state this in the new `plan.md` and proceed.

### 3. Write `plan.md`

Use this structure. Section names are fixed.

```markdown
# NNNN · slice_name — Implementation plan

## 1. Header

- **Feature:** <resource>
- **Slice:** <NNNN>_<slice_name>
- **PRD:** ./prd.md
- **Reference slice (if any):** ../<reference>/plan.md
- **HTTP path:** `<METHOD> /api/v1/...`
- **STABLE files touched:** list any (typically just `bootstrap/router.py`
  for router registration and `bootstrap/container.py` for wiring).

## 2. Context summary

One paragraph: what does this slice do, who calls it, what does it return?
Drawn from the PRD; no new product decisions.

## 3. API contract

- **Request body** (`<Slice>Request`): list of fields with types and
  validation constraints.
- **Path/query params:** list with types and validation.
- **Response body** (`<Slice>Response`): list of fields with types.
- **Status codes:**
  - 2xx success codes.
  - 4xx domain failures (each mapped to a specific `DomainError` subclass).
  - 5xx not enumerated; the catch-all handler covers them.

## 4. File structure

```
src/app/features/<resource>/<slice>/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py          # <Slice>Command
│   ├── ports/
│   │   ├── __init__.py
│   │   └── <slice>_port.py  # <Slice>Port
│   └── use_case.py          # <Slice>UseCase
├── data/
│   ├── __init__.py
│   └── adapter.py           # <Slice>Adapter
└── presentation/
    ├── __init__.py
    ├── router.py
    └── schemas.py           # <Slice>Request, <Slice>Response
```

If the slice needs a new ORM model: list its path under
`src/app/adapters/db/models/`.

If the slice needs new fields on the feature's `_shared/schemas.py`: list them
explicitly.

## 5. Implementation steps

Numbered list, layer by layer. For each step: what file, what to put in it,
what to verify.

1. **Domain — Command.** Create `domain/commands.py` with `<Slice>Command`
   (`BaseModel` with fields, validation).
2. **Domain — Port.** Create `domain/ports/<slice>_port.py` with `<Slice>Port`.
   It must use `@runtime_checkable` decorator and inherit from
   `typing.Protocol`. One method per use-case responsibility (typically one).
3. **Domain — Entity (if new).** If the slice introduces a new domain entity
   not already in `_shared/schemas.py`, add it to `domain/entities.py`. If
   adding to `_shared/`, note that this is a STABLE-adjacent change requiring
   awareness (the feature's `_shared/` is technically FEATURE but shared
   across slices).
4. **Domain — Use case.** Create `domain/use_case.py` with `<Slice>UseCase`.
   Constructor takes the port. `__call__()` takes the command, returns the
   entity, may raise `DomainError` subclasses.
5. **Data — Adapter.** Create `data/adapter.py` with `class <Slice>Adapter(<Slice>Port):`
   — **explicit inheritance from the port is mandatory**. Adapter is the only
   place SQLAlchemy is touched. Error handling per
   `agent_docs/error_handling.md`.
6. **Presentation — Schemas.** Create `presentation/schemas.py` with
   `<Slice>Request` and `<Slice>Response`.
7. **Presentation — Router.** Create `presentation/router.py`. Endpoint
   function converts Request → Command, awaits use-case, converts entity →
   Response.
8. **DI wiring.** Add provider entries in `bootstrap/container.py`:
   `<slice>_adapter` (Factory), `<slice>_use_case` (Factory, takes adapter).
   Add the router module to `Container.wiring_config.modules`.
9. **Router registration.** Add one line in `bootstrap/router.py` that
   `include_router`s the new router under `/api/v1`.
10. **Migration (if new model).** Run
    `alembic revision --autogenerate -m "<description>"`, review the migration,
    commit.
11. **Verify.** `ruff format`, `ruff check`, `mypy src/app`, then write tests
    (next stage).

## 6. Tests planned

Four levels, per `agent_docs/testing.md`:

- **Use-case unit test** — `tests/features/<resource>/<NNNN>_<slice>/domain/test_use_case.py`.
  Mocks the port. Validates each branch and each `DomainError` raised.
- **Adapter unit test** — `tests/features/<resource>/<NNNN>_<slice>/data/test_adapter.py`.
  Mocks the async session factory. Validates inner-catch mapping for each
  expected exception and the outer-catch path.
- **Endpoint integration test** — `tests/features/<resource>/<NNNN>_<slice>/presentation/test_router.py`.
  Uses `httpx.AsyncClient` against test Postgres. Validates request/response,
  status codes, exception handler translation.
- **Outside-in test** — `tests/features/<resource>/<NNNN>_<slice>/<slice>_outside_in_test.py`.
  Full HTTP stack with real adapter, test Postgres, mocks only at external
  boundaries.

**Opt-outs (if any):** state explicitly which level is skipped and why. The
default is no opt-outs.

## 7. Out of scope for this slice

Bullet list of things this slice does **not** do. Examples:

- No caching (handled by a follow-up).
- No rate limiting (only applied to public endpoints).
- No bulk variant (separate slice if needed).

## 8. Open questions

Anything unresolved at planning time. If none, write "None."
```

### 4. Save and confirm

Write to `specs/features/<feature>/<NNNN>_<slice>/plan.md`. Tell the user the
file was created, summarize the eight sections, and suggest the next step:

> Next step: `/feature-requirements` to produce requirements.md.

## Style rules

- **English only** in spec files.
- **Concrete file paths and class names**, not placeholders. Write
  `CreateUserCommand`, not `<Slice>Command`, in the actual plan.
- **Reference the relevant agent_docs section** when a rule is invoked
  ("error handling per agent_docs/error_handling.md").
- **No new architectural patterns invented inside the plan.** If you find
  yourself needing one, stop and ask the user. Adding a new pattern is an ADR,
  not a plan.

## Hard limits

- ❌ Writing any file other than `plan.md`.
- ❌ Writing source code or test code.
- ❌ Modifying `prd.md` or `roadmap.md`.
- ❌ Running shell commands.

## Common mistakes

- ❌ Skipping the reference-slice read. Without it, naming and structure
  drift from the rest of the codebase.
- ❌ Producing a plan that touches STABLE files beyond `bootstrap/router.py`
  and `bootstrap/container.py` (and `adapters/db/models/__init__.py` for new
  models). If the plan needs to change `core/`, stop and ask.
- ❌ Inventing a new `DomainError` subclass inside the slice. New subclasses
  go in `app/domain/errors.py` (STABLE) and require explicit user approval —
  flag this as an open question.
- ❌ A plan with more than ~12 implementation steps. The slice is likely two
  slices; re-decompose per the `slice-decomposition` skill.
- ❌ A plan that includes business decisions ("we will allow soft delete
  here"). Business decisions belong in the PRD; the plan references them.
