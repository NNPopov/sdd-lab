# Tech Stack

## Language & Runtime
- Python 3.11+ (pinned via `.python-version`)
- All I/O is `async def` — no synchronous DB or network calls

## Core Framework & Libraries

| Concern | Library |
|---|---|
| Web framework | FastAPI |
| Validation | Pydantic v2 (`model_config = ConfigDict(from_attributes=True)`) |
| ORM | SQLAlchemy 2.0 async (`Mapped[T]`, `mapped_column`, `MappedAsDataclass`) |
| DB driver | asyncpg |
| Migrations | Alembic (autogenerate) |
| Dependency injection | `dependency_injector` |
| Cache | Redis (`redis` library) via project `@cache` decorator |
| Background jobs | arq |
| HTTP client | httpx |
| Logging | structlog + rich |
| Admin UI | crudadmin |
| Auth | python-jose (JWT) + bcrypt |
| Settings | pydantic-settings |

## Build & Package Management
- **Package manager**: `uv` (lockfile: `uv.lock`)
- **Build backend**: hatchling (`pyproject.toml`)
- Source root: `src/` — all app code lives under `src/app/`

## Linting & Formatting
- **Ruff** — lint + format (line length 120, target py311)
  - Rules: F, E, W, C, UP, I, B, N
- **mypy** — strict type checking on `src/app/**` (`disallow_untyped_defs = true`)
- **import-linter** — enforces layer isolation contracts (see `.importlinter`)
- **pre-commit** — runs ruff, pyupgrade, docformatter, mdformat on commit

## Testing
- **pytest** + **pytest-asyncio** (asyncio_mode = "auto") + **pytest-mock**
- **httpx.AsyncClient** for integration/outside-in tests
- `pythonpath = ["src"]` in `pyproject.toml` — tests use absolute `from app.*` imports
- Test DB: Postgres in Docker (`app_test` database), transaction rollback per test
- Smoke test at `tests/smoke/test_app_starts.py` — boots the real app via uvicorn subprocess

## Infrastructure (Docker)
- **Postgres 15** — port 5432, DB `app_db`
- **Redis 7** — port 6379

## Common Commands

```bash
# Start infrastructure
docker compose up -d

# Start test DB only
docker compose up test-db -d

# Run the app (dev)
uv run uvicorn src.app.main:app --reload

# Format & lint
ruff format src/app
ruff check src/app

# Type check
mypy src/app

# Run all tests
uv run pytest

# Run a single slice's tests
pytest tests/features/<resource>/<NNNN>_<slice>/

# Run outside-in test for a slice
pytest tests/features/<resource>/<NNNN>_<slice>/<slice>_outside_in_test.py -v

# DB migrations
alembic revision --autogenerate -m "<description>"
alembic upgrade head

# Check import architecture
cd src && lint-imports --config ../.importlinter
```

## Verification Order (after any code change)
```bash
ruff format src/app
ruff check src/app
mypy src/app
pytest
```
All four must pass. A change is not complete until they do.
