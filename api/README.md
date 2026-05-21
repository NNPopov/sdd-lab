# t_automation — API

Async **FastAPI** service implementing the sdd-lab backend.

Cloned from [benavlabs/fastapi-boilerplate](https://github.com/benavlabs/fastapi-boilerplate) and reworked into **Vertical Slice + Hexagonal** architecture described in `agent_docs/architecture.md`.

Development is iterative and spec-driven: each new slice goes through a full specification cycle — PRD → plan → requirements → validation → tests — and is considered done only when the outside-in acceptance test turns green.

## Stack

| Concern | Choice |
|---|---|
| Language | Python 3.11+ · full type hints |
| Web framework | FastAPI |
| Database | PostgreSQL · SQLAlchemy 2.0 async · asyncpg · Alembic |
| Cache | Redis via `@cache` decorator |
| DI | `dependency_injector` + `Annotated[X, Depends(...)]` |
| Errors | `DomainError` hierarchy — never `HTTPException` in use-cases |
| Lint / format | Ruff (F E W C UP I B N) |
| Type check | mypy strict on `src/app/**` |
| Tests | pytest · pytest-asyncio · httpx.AsyncClient |
| Architecture | import-linter · pytestarch |

## Quick start

```bash
uv sync
docker-compose up -d        # PostgreSQL + Redis
alembic upgrade head
uvicorn src.app.main:app --reload
```

```bash
pytest
```

## Architecture enforcement

Layer isolation is verified at two levels:

**import-linter** (`.importlinter`) — five contracts checked via `lint-imports` (run from `src/` or via `scripts/check_arch.py`):

| Contract | Rule |
|---|---|
| `adapters-no-features` | Adapters must not import Features |
| `core-no-features` | Core must not import Features |
| `core-no-adapters` | Core must not import Adapters |
| `ports-isolation` | Ports must not import Adapters, Core, or Features |
| `vsa-feature-independence` | VSA Feature Domains are independent (`users` ↔ `posts`) |

**pytestarch** (`tests/architecture/test_architecture.py`) — the same contracts run as part of `pytest`, so violations are caught automatically in CI.

**Ruff extended rules** (`pyproject.toml`) — two rule sets added on top of the base configuration:
- `B` (flake8-bugbear) — opinionated bug-pattern detection
- `N` (pep8-naming) — enforces PEP 8 naming conventions

## Slices

**29 complete, 2 planned.** Features: `users`, `posts`, `moderation`, `infra`.
See `specs/roadmap.md` for the full index.
