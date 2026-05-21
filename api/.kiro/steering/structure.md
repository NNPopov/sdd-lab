# Project Structure

## Root Layout

```
src/app/          # all application code
tests/            # all tests (mirrors src/app/ structure)
specs/            # slice spec documents (PRD, plan, requirements, validation, tests)
agent_docs/       # architecture and workflow reference docs for LLM agents
migrations/       # Alembic migration files (inside src/)
scripts/          # one-off admin scripts (create superuser, seed tiers, etc.)
docker-compose.yml
pyproject.toml
.importlinter     # import architecture contracts
```

## Application Layout (`src/app/`)

```
src/app/
├── main.py                        # STABLE — entry point, imports bootstrap only
├── shared_dependencies.py         # STABLE — cross-feature FastAPI dependencies
├── bootstrap/                     # STABLE — composition root
│   ├── container.py               # dependency_injector Container (all providers)
│   ├── factory.py                 # create_app(), lifespan, exception handler registration
│   └── router.py                  # aggregates all feature routers under /api/v1
├── domain/                        # STABLE — pure Python, no framework imports
│   ├── errors.py                  # DomainError hierarchy
│   └── shared/                    # cross-feature domain types
├── ports/                         # STABLE — @runtime_checkable Protocol interfaces
├── adapters/                      # STABLE — concrete infrastructure implementations
│   ├── db/                        # SQLAlchemy session, base, mixins, ORM models
│   ├── cache/                     # Redis cache adapter
│   ├── queue/                     # arq queue adapter
│   ├── rate_limit/
│   └── http/
│       └── exception_handlers.py  # DomainError → HTTP status mapping
├── core/                          # STABLE — config, security, logging
│   ├── config.py
│   ├── security.py
│   └── logger.py
└── features/                      # FEATURE — vertical slices live here
    └── <resource>/
        ├── _shared/               # shared within this feature only
        │   ├── entities.py / schemas.py
        │   ├── policies.py
        │   └── dependencies.py
        └── <use_case>/            # one folder per use-case
            ├── domain/
            │   ├── commands.py    # *Command / *Query input types
            │   ├── entities.py    # domain entities (if not in _shared)
            │   ├── ports/
            │   │   └── <use_case>_port.py
            │   └── use_case.py    # class with __call__()
            ├── data/
            │   └── adapter.py     # implements the port
            └── presentation/
                ├── router.py      # FastAPI endpoint
                └── schemas.py     # *Request / *Response Pydantic models
```

## Current Features

| Feature | Slices |
|---|---|
| `users` | create, delete, delete_db, get_by_username, get_tier, list, update, assign_moderator, revoke_moderator |
| `posts` | create, get, list, list_all, list_pending, update, revise, erase, erase_db, moderate, get_moderation_log |
| `auth` | authenticate |
| `tiers` | CRUD (pre-VSA flat pattern) |
| `rate_limits` | CRUD (pre-VSA flat pattern) |
| `tasks` | background task endpoints |
| `health` | health check |

## Test Layout (`tests/`)

Mirrors `src/app/features/` structure:

```
tests/
├── conftest.py                    # engine, db_session, app, client fixtures
├── features/
│   └── <resource>/
│       └── <NNNN>_<slice>/
│           ├── conftest.py
│           ├── domain/test_use_case.py
│           ├── data/test_adapter.py
│           ├── presentation/test_router.py
│           └── <slice>_outside_in_test.py   # acceptance gate
├── architecture/                  # pytestarch import rule tests
├── adapters/                      # adapter-level tests
├── helpers/
│   ├── generators.py              # test data factories
│   └── mocks.py
└── smoke/test_app_starts.py       # boots real app via uvicorn subprocess
```

## Spec Layout (`specs/`)

```
specs/
├── roadmap.md                     # global slice index (owned by /to-prd)
└── features/
    └── <resource>/
        └── <NNNN>_<slice>/
            ├── prd.md
            ├── plan.md
            ├── requirements.md
            ├── validation.md
            └── tests.md
```

## Layer Import Rules

| Layer | May import | Must never import |
|---|---|---|
| `domain/` | stdlib, pydantic | anything else from `app/` |
| `ports/` | `domain/` | `adapters/`, `core/`, `features/` |
| `adapters/` | `domain/`, `ports/`, `core/` | `features/` |
| `core/` | stdlib, third-party | `features/`, `adapters/` |
| `features/<X>/<Y>/` | `domain/`, `ports/`, `adapters/`, `core/`, own `_shared/` | other features; other slices' internals |

**Import style**: relative imports inside `src/app/`; absolute `from app.*` imports inside `tests/`.

## File Header Convention

Every new `.py` file must start with either:
- `# STABLE:` — part of the shared infrastructure; not modified without explicit approval
- `# FEATURE:` — belongs to a specific slice; freely modified within that slice
