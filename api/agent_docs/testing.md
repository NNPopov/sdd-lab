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

### Fixtures (per-slice `conftest.py`)

The top-level `tests/conftest.py` contains only legacy synchronous fixtures
(`TestClient`, synchronous `sessionmaker`) left over from the pre-VSA era.
**Do not use those for new VSA slices.**

Each VSA slice defines its own async fixtures in
`tests/features/<resource>/<NNNN>_<slice>/conftest.py`. The canonical pattern
uses **savepoint-mode rollback**: the outer transaction wraps the whole test;
`session.commit()` inside an adapter creates a SAVEPOINT instead of a real
commit; teardown rolls back the outer transaction, leaving the DB clean.

```python
# tests/features/tiers/0033_create_tier/conftest.py — reference pattern.
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.adapters.db.base import Base
from app.adapters.db.session import DATABASE_URL


@pytest_asyncio.fixture()
async def oit_engine():
    """Per-test async engine against the dev DB; ensures schema exists."""
    engine = create_async_engine(DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture()
async def async_client(oit_engine) -> AsyncClient:
    """HTTP client wired to the app with per-test transaction rollback.

    join_transaction_mode="create_savepoint" means every session.commit()
    inside an adapter creates a SAVEPOINT, not a real commit. Rolling back
    the outer transaction at teardown removes all test data.
    """
    from app.bootstrap.container import container as _di_container

    connection = await oit_engine.connect()
    transaction = await connection.begin()
    test_factory = async_sessionmaker(
        bind=connection,
        expire_on_commit=False,
        join_transaction_mode="create_savepoint",
    )
    _di_container.session_factory.override(test_factory)

    from app.main import app as _fastapi_app

    try:
        async with AsyncClient(
            transport=ASGITransport(app=_fastapi_app),
            base_url="http://test",
        ) as client:
            yield client
    finally:
        _di_container.session_factory.reset_override()
        await transaction.rollback()
        await connection.close()
```

Copy this pattern verbatim into every new slice's `conftest.py`. The
`oit_engine` + `async_client` fixtures replace the legacy `client` and
`db_session` fixtures for all VSA work.

### Seeding data in tests

Because the adapter and the test share the same overridden `session_factory`,
rows inserted before the HTTP call are visible to the adapter without a real
commit:

```python
async def test_list_tiers_happy_path(async_client: AsyncClient) -> None:
    from app.bootstrap.container import container as _di_container

    # Seed rows inside the savepoint transaction.
    async with _di_container.session_factory()() as session:
        await session.execute(
            text('INSERT INTO "tier" (name, created_at) VALUES (:name, NOW())'),
            [{"name": "free"}, {"name": "pro"}],
        )
        await session.commit()  # creates SAVEPOINT, not a real commit

    response = await async_client.get("/api/v1/tiers")
    ...
```

Use raw SQL (`sqlalchemy.text`) for both seeding and DB assertions to keep
the test black-box (no ORM model imports in the test file).

### DB assertions

After a write endpoint, verify the side effect through a raw SQL query on the
same session factory:

```python
async with _di_container.session_factory()() as session:
    result = await session.execute(
        text('SELECT name FROM "tier" WHERE name = :n'),
        {"n": "gold"},
    )
    row = result.first()
    assert row is not None
    assert row.name == "gold"
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
  Postgres** via `async_client` (savepoint rollback). The HTTP client makes
  real requests against the app, the app runs real exception handlers, the
  adapter writes to the test DB, the transaction rolls back. Slow but honest.
- **In outside-in tests:** wire **real** everything except external system
  boundaries. The point is to verify that all layers compose correctly.

### Container overrides

To swap a provider in a test:

```python
from app.bootstrap.container import container as _di_container

_di_container.create_user_adapter.override(mock_adapter)
try:
    # ... test code
finally:
    _di_container.create_user_adapter.reset_override()
```

The `async_client` fixture in slice `conftest.py` already overrides
`session_factory`. Slice-specific adapter overrides go in the same
`conftest.py` or inline in the test function.

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

## Fat-handler migration slices

Some slices migrate an existing fat FastAPI handler that calls `async_get_db`
directly rather than going through the DI container. This creates a conftest
problem: overriding `container.session_factory` is not enough, because the old
handler bypasses the container entirely.

**Symptom**: Scenario 1 unexpectedly passes in the red state (old handler writes to
the real DB and commits; the committed row is visible to all connections, including
the test-transaction session used for the DB assertion). Scenario 2 crashes with an
asyncpg `_start_transaction()` error rather than an AssertionError.

**Fix**: Override `async_get_db` in addition to `container.session_factory` so that
ALL database operations — old handler and new adapter alike — go through the same
savepoint-based test transaction:

```python
from app.adapters.db.session import async_get_db
...
async def _test_get_db():
    async with test_factory() as session:
        yield session

_fastapi_app.dependency_overrides[async_get_db] = _test_get_db
# In finally: _fastapi_app.dependency_overrides.pop(async_get_db, None)
```

**DB contamination from interrupted red-state runs**: If a previous test run was
interrupted before teardown, old-handler writes may have been committed to the dev
DB. Fix with an `autouse=True` fixture that deletes known test row names inside the
test transaction at the start of each test (the deletion is rolled back at teardown,
so the real DB is left clean).

**Red-state signal for migration slices**: Because the old handler may handle the
happy path correctly, Scenario 1 can pass in the red state. This is acceptable. The
red signal comes from Scenario 2: the old handler raises its legacy error message,
while the new adapter must raise a different one. Assert the new message; the
mismatch is the red indicator.

See `tests/features/tiers/0033_create_tier/conftest.py` for the complete working
pattern (includes both overrides and the `autouse` cleanup fixture).

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
- ❌ Constructing a fresh `AsyncClient` inside the test instead of using the
  `async_client` fixture. A manually constructed client bypasses the
  `session_factory` override and writes to the real DB without rollback.
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
