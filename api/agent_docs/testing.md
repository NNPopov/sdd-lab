# Testing

This document is the reference for how to test the project. Read it before
writing any test, mock, or fixture.

For overall architecture, see `agent_docs/architecture.md`. For the spec/test
workflow (which test gets written when), see `agent_docs/spec_workflow.md`.

## Test stack

| Tool | Role |
|---|---|
| `pytest` | runner |
| `pytest-asyncio` | async test support, `@pytest.mark.asyncio` |
| `pytest-mock` | `mocker` fixture for AsyncMock and MagicMock |
| `httpx.AsyncClient` | integration tests against the running app |
| Postgres (Docker) | isolated test database, transaction rollback per test |
| `dependency_injector` overrides | swap real providers for mocks in integration |

Run the full suite with `pytest`. Run a single slice with
`pytest tests/features/<resource>/<NNNN>_<slice>/`.

## Folder layout

Mirror the `src/app/` structure. For every slice in
`src/app/features/<resource>/<NNNN>_<slice>/`, tests live at
`tests/features/<resource>/<NNNN>_<slice>/`:

```
tests/features/users/0001_create_user/
├── conftest.py                              # slice-specific fixtures, if any
├── domain/
│   └── test_use_case.py                     # unit test on the use-case
├── data/
│   └── test_adapter.py                      # unit test on the adapter (mocked session)
├── presentation/
│   └── test_router.py                       # integration test through httpx
└── create_user_outside_in_test.py           # the outside-in acceptance test
```

Filename conventions:

- Unit/integration tests: `test_<what_is_tested>.py`. pytest collects these.
- Outside-in test: `<slice>_outside_in_test.py`. The non-`test_` prefix marks
  the acceptance test as a distinct category; pytest still collects it because
  the filename contains `_test.py`. We use this name to make it grep-able.

## Coverage requirements (default)

For a new slice, all four levels are mandatory:

1. **Use-case unit test** — `domain/test_use_case.py`. Mocks the port. Validates
   business rules, branches, raised `DomainError` subclasses.
2. **Adapter unit test** — `data/test_adapter.py`. Mocks the async session
   factory. For each catch the adapter declares (typically one or two), the
   test configures the mock to raise the expected infrastructure exception
   and verifies the translation into a `DomainError` subclass. Also verifies
   that an unexpected infrastructure exception (e.g. `OperationalError`)
   propagates **unchanged** — the adapter does not catch it. See
   `agent_docs/error_handling.md`.
3. **Endpoint integration test** — `presentation/test_router.py`. Uses
   `httpx.AsyncClient` against the running app with the test Postgres. Validates
   request/response schema, status codes, exception handler translation.
4. **Outside-in test** — `<slice>_outside_in_test.py`. Full stack through
   `httpx.AsyncClient`; mocks only at system boundaries (external HTTP APIs,
   Redis sometimes). The acceptance gate.

A level may be **opted out** only when the relevant layer is trivial:

- Skip use-case test if the use-case is `return await self._port(command)` with
  no branches, no validations, no authorization. (The adapter and integration
  tests then carry the full burden.)
- Skip adapter test if the adapter has **no try/except at all** (read-only
  lookups with nothing business-meaningful to translate). When there are
  exception translations, the adapter test is non-negotiable.
- Skip endpoint integration test if the slice has no HTTP entry point (e.g.
  pure internal use-case called only from Celery later).
- Skip outside-in test never. It is the acceptance gate.

The decision to skip a level is recorded in the slice's `plan.md` with a brief
rationale.

## Smoke tests

The four levels above do **not** catch one important class of bugs: code that
imports fine under pytest but breaks under `uvicorn`, `alembic`, or any other
real entry point. The cause is usually PYTHONPATH differences — pytest with
`pythonpath = ["src"]` resolves `from app...` correctly, while uvicorn run
from the project root sees only `src.app...` and refuses to import.

A dedicated smoke test catches this. Single file at the project level,
runs as part of every `pytest` invocation, and uses a subprocess to boot the
real app the way uvicorn would.

```python
# FEATURE: smoke — application boot smoke test.
import socket
import subprocess
import sys
import time
from contextlib import closing

import httpx
import pytest


def _free_port() -> int:
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as s:
        s.bind(("127.0.0.1", 0))
        return int(s.getsockname()[1])


def test_app_boots_and_health_responds() -> None:
    """The app imports cleanly and serves /api/v1/health on a real port."""
    port = _free_port()
    proc = subprocess.Popen(
        [
            sys.executable,
            "-m",
            "uvicorn",
            "src.app.main:app",
            "--host",
            "127.0.0.1",
            "--port",
            str(port),
            "--log-level",
            "warning",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    try:
        deadline = time.time() + 10
        last_error: Exception | None = None
        while time.time() < deadline:
            try:
                response = httpx.get(f"http://127.0.0.1:{port}/api/v1/health", timeout=1.0)
                if response.status_code == 200:
                    return
                last_error = AssertionError(f"unexpected status {response.status_code}")
            except Exception as exc:
                last_error = exc
            # Check the process has not died with an import error.
            if proc.poll() is not None:
                stdout, stderr = proc.communicate()
                pytest.fail(
                    f"app exited during boot with code {proc.returncode}.\n"
                    f"stdout:\n{stdout.decode(errors='replace')}\n"
                    f"stderr:\n{stderr.decode(errors='replace')}"
                )
            time.sleep(0.2)
        pytest.fail(f"app did not respond on /api/v1/health within 10s: {last_error}")
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
```

Save as `tests/smoke/test_app_starts.py`. It needs a `/api/v1/health`
endpoint that returns 200 (the project's existing health feature provides
this; adjust the path if your project uses a different one). The test fails
if:

- The app cannot be imported (`ModuleNotFoundError` and similar — the case
  this whole section was added to address).
- The app boots but does not respond on `/health` within ten seconds.
- The subprocess exits with non-zero before timeout — captured stdout and
  stderr are printed.

Add this once. It runs on every `pytest` invocation and protects every
slice automatically.

## Postgres test database

Postgres runs in Docker. The compose file exposes the test DB on a separate port
under database `app_test`. Locally, start it once:

```
docker compose up test-db -d
```

In CI, the same container starts as a service.

### Fixtures (in top-level `tests/conftest.py`)

The fixture chain has four levels of scope, designed so the engine is built
once, migrations run once, but each test gets a fresh transaction:

```python
# tests/conftest.py — STABLE.

import pytest_asyncio
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.adapters.db.base import Base
from app.core.config import settings


@pytest_asyncio.fixture(scope="session")
async def test_engine():
    engine = create_async_engine(settings.test_database_url, echo=False)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture(scope="session")
async def _apply_migrations(test_engine):
    """Run Alembic migrations once for the session."""
    # In practice: subprocess call to `alembic upgrade head` against TEST_DATABASE_URL.
    # Or for simple test schemas: Base.metadata.create_all on the engine.
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


@pytest_asyncio.fixture()
async def db_session(test_engine, _apply_migrations) -> AsyncSession:
    """Per-test transaction. Rolled back at teardown."""
    connection = await test_engine.connect()
    transaction = await connection.begin()
    Session = async_sessionmaker(bind=connection, expire_on_commit=False)
    session = Session()
    try:
        yield session
    finally:
        await session.close()
        await transaction.rollback()
        await connection.close()
```

Every test that touches the database receives `db_session` and writes through
it. At teardown, the transaction rolls back; the database is identical to its
pre-test state.

### Integration client fixture

For tests that go through the HTTP layer:

```python
# tests/conftest.py — STABLE.

import pytest_asyncio
from httpx import AsyncClient
from httpx import ASGITransport

from app.bootstrap.factory import create_app
from app.bootstrap.container import Container


@pytest_asyncio.fixture()
async def app(db_session):
    """App configured to use the per-test transaction."""
    app = create_app()
    container: Container = app.container  # type: ignore[attr-defined]
    # Override session_factory to return the test transaction's session.
    container.session_factory.override(lambda: db_session)
    yield app
    container.session_factory.reset_override()


@pytest_asyncio.fixture()
async def client(app):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c
```

## Mocking strategy

The project uses **`pytest-mock`** through the `mocker` fixture. Do not import
`unittest.mock` directly.

### Use `AsyncMock` for async dependencies

```python
async def test_use_case_calls_port(mocker):
    port = mocker.AsyncMock(spec=CreateUserPort)
    port.username_exists.return_value = False
    port.create.return_value = User(id=1, username="alice", email="a@b.c", is_superuser=False)

    use_case = CreateUserUseCase(port=port)
    result = await use_case(CreateUserCommand(username="alice", email="a@b.c", password="x"))

    port.username_exists.assert_awaited_once_with("alice")
    port.create.assert_awaited_once()
    assert result.username == "alice"
```

### What to mock and what to wire real

- **In use-case unit tests:** wire **real** use-case, mock the **port** with
  `AsyncMock(spec=...)`. No DB, no HTTP. Fast.
- **In adapter unit tests:** wire **real** adapter, mock the **session
  factory** with `AsyncMock`. Validate the inner-catch mapping by configuring
  the mock to raise the expected SQLAlchemy exception.
- **In endpoint integration tests:** wire **real** adapter, use the **test
  Postgres** via `db_session`. The HTTP client makes real requests against the
  app, the app runs real exception handlers, the adapter writes to the test DB,
  the transaction rolls back. Slow but honest.
- **In outside-in tests:** wire **real** everything except external system
  boundaries. The point is to verify that all layers compose correctly.

### Container overrides

To swap a provider in a test:

```python
container.create_user_adapter.override(mock_adapter)
try:
    # ... test code
finally:
    container.create_user_adapter.reset_override()
```

For the common case, the `client` fixture above already overrides
`session_factory`. Slice-specific overrides go in slice `conftest.py`.

## Reference tests

When you need a working example for a non-trivial pattern, read the file
directly rather than relying on a snippet here. Real tests stay in sync with
the codebase; documented snippets drift over time.

- **Adapter test with specific exception translation** —
  *to be filled in once the first slice lands.*
- **Outside-in test through httpx with Postgres rollback** —
  *to be filled in once the first slice lands.*

When the first slice is implemented and tested, update this section with the
two pointers. Subsequent slices read these files instead of guessing.

## Common mistakes

- ❌ Forgetting `@pytest.mark.asyncio` on an async test function. The test
  silently passes because no coroutine is awaited.
- ❌ Using `Mock` instead of `AsyncMock` for an async dependency. Calls return
  unawaited coroutines and assertions silently match the wrong thing.
- ❌ Asserting on `mock.called` instead of `mock.assert_awaited_once_with(...)`.
  The first form does not check arguments.
- ❌ Forgetting `spec=PortClass` on the mock. Without `spec`, typos in method
  names go undetected.
- ❌ Calling `session.commit()` inside a test that uses the `db_session`
  fixture. The fixture relies on the outer transaction; manual commit defeats
  the rollback.
- ❌ Constructing a fresh `AsyncClient` without the `app` fixture. The
  client then talks to a different app instance with no test overrides.
- ❌ Mocking `dependency_injector` providers directly with `mocker.patch`.
  Use `container.X.override(...)` and `reset_override()`.
- ❌ Writing an integration test that bypasses the router and calls the
  use-case directly. That is a unit test, not integration. Integration tests
  exercise the full HTTP path.
- ❌ Asserting on internal call order between use-case and port. Assert on
  observable behavior (returned value, raised exception, DB state through the
  port).
- ❌ Forgetting to seed the test DB with required fixtures (e.g. a tier row
  before creating users that reference it). Use factory fixtures in the
  slice's `conftest.py`.
- ❌ Running tests against the production Postgres by misconfiguring
  `TEST_DATABASE_URL`. The fixture should refuse to run if the URL does not
  contain `_test` in the database name — add this guard in
  `tests/conftest.py`.
- ❌ Skipping `tests/smoke/test_app_starts.py` because "the rest is green."
  pytest with `pythonpath = ["src"]` resolves imports differently than
  uvicorn started from the project root. The smoke test is the only thing
  that catches an import that works in pytest but fails in production.
- ❌ Using `from app...` inside `src/app/` (in either source or tests
  imported from source). Source uses relative imports; absolute imports are
  reserved for the `tests/` tree. Mixing the two breaks under at least one
  entry point. See `agent_docs/architecture.md` § Import conventions.
