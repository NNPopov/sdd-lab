# CLAUDE.md — universal rules for this Python project

This file is loaded into every session. Anything written here is mandatory and
overrides anything in `agent_docs/`, in individual skills, or in source code.

Topical references live in `agent_docs/`. Read them by relevance to the task.
Reusable procedures live in `.claude/skills/` and are invoked by name.

## Project at a glance

- Async FastAPI service, Python 3.11+.
- Architecture: **Vertical Slice + Hexagonal + Skeleton**.
- Slice = a single **use-case** (not a resource). Each use-case has its own folder
  with `domain/`, `data/`, `presentation/` subfolders.
- Use-case is a **class** with `__call__()`; called as `await use_case(command)`.
- Error handling: **native Python exceptions** through a `DomainError` hierarchy.
  Use-case never raises `HTTPException`; only `DomainError` subclasses.
- DI: **`dependency_injector`** container wraps providers; FastAPI `Depends`
  composes them at the endpoint boundary.
- Database: PostgreSQL via SQLAlchemy 2.0 async + asyncpg + Alembic.
- Backend may later host Celery tasks and Langgraph nodes from the same
  use-cases; only FastAPI entry points are documented here for now.

## Locked technology stack

| Concern | Choice |
|---|---|
| Language | Python 3.11+, full type hints |
| Web framework | FastAPI |
| Validation | Pydantic v2 (`model_config = ConfigDict(from_attributes=True)`) |
| ORM | SQLAlchemy 2.0 async (`Mapped[T]`, `mapped_column`, `MappedAsDataclass`) |
| Driver | asyncpg |
| Migrations | Alembic (autogenerate) |
| DI | `dependency_injector` + `Annotated[X, Depends(Provide[Container.x])]` |
| Cache | Redis via project `@cache` decorator |
| Testing | pytest + pytest-asyncio + pytest-mock + httpx.AsyncClient |
| Lint/format | Ruff |
| Type check | mypy strict on `src/app/**` |

Anything not on this list requires explicit approval before use.

## Forbidden without explicit user approval

- **FastCRUD** (or any generic CRUD wrapper). Adapters are written by hand.
- Synchronous database calls. All I/O is `async def`.
- ORM models inside `domain/`. ORM lives in `adapters/db/models/`.
- `HTTPException` raised inside `use_cases/`. Use `DomainError` subclasses.
- A use-case implemented as a free function. Use-cases are classes.
- Cross-slice imports other than from the same feature's `_shared/`.
- A new `*.py` file without a `# STABLE:` or `# FEATURE:` header on line 1.
- `model.dict()`. Use `model.model_dump()`.
- `Result[T, E]` / `Either`-style return types. We use exceptions.
- Absolute imports inside `src/app/` (`from app...` or `from src.app...`).
  Source uses **relative imports** (`from ..domain...`); tests use absolute
  imports through `app.*` with `pythonpath = ["src"]` in `pyproject.toml`.
  See `agent_docs/architecture.md` § Import conventions.
- Adapter class without explicit `(PortName)` inheritance. The line
  `class CreateUserAdapter(CreateUserPort):` is mandatory so the
  port→adapter binding is greppable. See `agent_docs/architecture.md` §
  Terminology: port and adapter.
- Port without `@runtime_checkable` decorator. Every Port carries it; the
  cost is one line, the benefit is `isinstance()` works for diagnostics.

## Universal hard rules

These rules apply to every change, every file, every PR. Violations are
non-negotiable.

1. **Use-case never raises `HTTPException`.** It raises a `DomainError`
   subclass. Translation to HTTP happens once in
   `adapters/http/exception_handlers.py`.
2. **`domain/` imports only stdlib and pydantic.** Never `adapters/`, never
   `core/`, never any framework.
3. **`ports/` imports only `domain/`.** Defines `Protocol` or ABC interfaces.
4. **`adapters/` imports `domain/`, `ports/`, `core/`.** Never `features/`.
5. **`core/` imports stdlib and third-party only.** Never `features/`, never
   `adapters/`.
6. **`features/<resource>/<use_case>/` is the unit of work.** Inside one
   use-case folder, layers are split across `domain/`, `data/`, `presentation/`.
7. **Cross-slice imports go through `_shared/`.** A slice may import from its own
   feature's `_shared/`; never from another slice's `domain/`, `data/`, or
   `presentation/`.
8. **Adapter catches only business-meaningful infrastructure exceptions**
   (e.g. `IntegrityError` → `DuplicateValueDomainError`). It does **not**
   wrap operations in `try/except Exception`. Unknown failures propagate
   to the global exception handler in `adapters/http/exception_handlers.py`,
   which logs and returns HTTP 500. See `agent_docs/error_handling.md`.
9. **Every new `.py` file starts with `# STABLE:` or `# FEATURE:`.** See
   `agent_docs/stable_vs_feature.md`. STABLE files are not modified without
   explicit user approval (one exception: `bootstrap/router.py` accepts new
   feature-router registrations).
10. **Use-case input is a `*Command` (or `*Query`) from `domain/commands.py`**,
    not the HTTP `*Request` schema. Router converts Request → Command. This
    keeps `domain/` independent of the transport.

## Where to look when working on a task

Read by relevance. Always read `architecture.md`, `error_handling.md`, and
`spec_workflow.md` for any non-trivial change.

| You are doing | Read this |
|---|---|
| Designing a new slice | `agent_docs/architecture.md` |
| Splitting a feature into slices | `agent_docs/architecture.md`, skill `slice-decomposition` |
| Writing or modifying an adapter | `agent_docs/error_handling.md` |
| Writing a FastAPI endpoint | `agent_docs/entry_points/fastapi.md` |
| Writing tests | `agent_docs/testing.md` |
| Working with the spec chain (PRD/plan/etc) | `agent_docs/spec_workflow.md`, skill `spec-workflow` |
| Creating any new `.py` file | `agent_docs/stable_vs_feature.md` |
| Celery task | will be documented when the first real task lands |
| Langgraph node | will be documented when the first real node lands |

## Slice spec workflow

A new slice gets a complete spec folder with **five markdown files** at
`specs/features/<resource>/<NNNN>_<slice>/`:

| File | Generated by | Sources |
|---|---|---|
| `prd.md` | `/to-prd` | the conversation; user stories and product decisions |
| `plan.md` | `/feature-spec` | prd.md + reading existing slices for context |
| `requirements.md` | `/feature-requirements` | prd.md + plan.md |
| `validation.md` | `/feature-validation` | prd.md + plan.md + requirements.md |
| `tests.md` | `/feature-tests` | all four above |

Plus one Dart-equivalent — here, a **Python file** — outside `specs/`:

| File | Generated by | Sources |
|---|---|---|
| `<slice>_outside_in_test.py` (RED) | `/slice-test-red` | tests.md + plan.md + agent_docs/testing.md |

**Run the commands in this order**, one at a time. Each command produces its
file and returns. Do not skip steps — later files depend on earlier ones.

```
/grill-me              (optional discovery interview)
/to-prd                → prd.md
/feature-spec          → plan.md
/feature-requirements  → requirements.md
/feature-validation    → validation.md
/feature-tests         → tests.md
/slice-test-red        → <slice>_outside_in_test.py (verified RED)
implementation         → until the outside-in test turns GREEN
```

The outside-in test is the **acceptance gate**. The slice is not done until that
single test passes. Other tests (unit tests on use-case, adapter, integration
through the endpoint) are written after the green is reached, per
`agent_docs/testing.md`.

### Optional zeroth step: `/grill-me`

The user may invoke `/grill-me` before `/to-prd` to stress-test a plan through
an interview. `grill-me` produces **only conversation in the chat** — questions,
answers, and a final summary. It does **not** write files, run commands, or
create spec files. When the interview ends, it outputs a summary and the line
"Next step: /to-prd". The user issues the next command.

This boundary applies regardless of how the `grill-me` skill itself is worded.

### Modifying an existing slice

When behavior changes on a slice that is already green:

1. Update `tests.md` first to describe the new expected behavior. If the change
   affects requirements, update `requirements.md` first, then `tests.md`.
2. Update `<slice>_outside_in_test.py` to match the new tests.md. Run it and
   confirm it is **red** against the current implementation.
3. Change the implementation until the outside-in test is green again.
4. Update affected unit tests as a final step.

For pure refactors with no behavior change, the outside-in test stays green
throughout. If it goes red during a refactor, the change is not a refactor — it
is a behavior change, and tests.md must be updated first.

## Default test coverage for a new slice

Every new slice has all four levels by default:

- **Use-case unit test** with mocked port. Validates business logic and branches.
- **Adapter unit test** with mocked async session. Validates that
  business-meaningful infrastructure exceptions (e.g. `IntegrityError` from
  a unique violation) are translated into the right `DomainError` subclass.
  Validates that other infrastructure exceptions propagate **unchanged** —
  the adapter does not catch them. See `agent_docs/error_handling.md`.
- **Endpoint integration test** through `httpx.AsyncClient` against the running
  app with the test Postgres. Validates router wiring, request/response schemas,
  status codes, and exception handler translation.
- **Outside-in test** as the acceptance gate (see workflow above).

Tests may be opted out **only** when the relevant layer is trivial and adds no
behavior — see `agent_docs/testing.md` for the exact criteria.

## Where generated specs go

- `specs/roadmap.md` — global index of slices. **Owned by `/to-prd`.** Other
  skills read it but never write to it.
- `specs/features/<resource>/<NNNN>_<slice>/` — per-slice folder with the five
  markdown files. `NNNN` is global (max+1 from roadmap), not per-feature.

## Working with context during modifications

When changing an existing slice, **read only the files of that slice plus
direct dependencies**. Do not load the whole project. If the change touches a
cross-cutting concern (config, security, DB session), read just that file in
isolation.

## Conflict resolution

If two documents conflict, this file wins. If a skill conflicts with an
`agent_docs/` file, the skill wins for its scope and the agent_docs entry should
be updated to match.

## Verifying changes

After any code change, run in this order:

```
ruff format src/app          # apply formatting
ruff check src/app           # lint
mypy src/app                 # type check
pytest                       # full test suite, includes tests/smoke/
```

`tests/smoke/test_app_starts.py` is the **import-level smoke test**. It boots
the app in a subprocess and pings `/health`. It runs as part of `pytest` and
catches issues that unit/integration tests miss — for example, a wrong import
path that works under pytest's PYTHONPATH but breaks under uvicorn's. If the
smoke test fails, the slice is **not done**, even if every other test is
green. See `agent_docs/testing.md` § Smoke tests.

For schema or model changes:

```
alembic revision --autogenerate -m "<description>"
alembic upgrade head
```

Outside-in test for the slice you are working on:

```
pytest tests/features/<resource>/<NNNN>_<slice>/<slice>_outside_in_test.py -v
```

A change is not complete until all of the above pass.

## Language and tone

All generated artifacts (PRDs, plans, requirements, validations, tests,
markdown specs, code comments, docstrings, log messages) are written in
**English**. The conversation with the user may be in another language.
