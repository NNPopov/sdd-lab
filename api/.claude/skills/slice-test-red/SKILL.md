---
name: slice-test-red
description: This skill should be used when the user wants to generate the executable Python outside-in test for a slice from its tests.md specification. Trigger when the user invokes /slice-test-red, says "generate the red test", "write the outside-in Python test", or asks to translate tests.md into runnable pytest code. Use only after tests.md exists. Reads tests.md plus architectural context, writes <slice>_outside_in_test.py, runs pytest, and verifies the test is RED.
disable-model-invocation: false
---

# slice-test-red

Translate a slice's `tests.md` markdown specification into an executable
pytest outside-in test, place it under
`tests/features/<feature>/<NNNN>_<slice>/`, run `pytest` against it, and
verify it is **red** — failing as expected because the slice's implementation
does not yet exist.

This is the "red" phase of outside-in TDD. The next step after this skill is
implementation, which proceeds until the same test turns green.

## Process

### 1. Find the target slice

Same determination as in `/feature-tests`:

1. User-named slice.
2. Most recently modified `tests.md` under `specs/features/*/*/`.
3. If ambiguous, ask.

### 2. Read the inputs

- `specs/features/<feature>/<NNNN>_<slice>/tests.md` — primary input.
- `specs/features/<feature>/<NNNN>_<slice>/plan.md` — for class names, paths,
  schema names.
- `agent_docs/testing.md` — for fixtures, mocking patterns, conventions.
- `agent_docs/entry_points/fastapi.md` — for the HTTP-call shape.
- `tests/conftest.py` — to know which fixtures are available (especially
  `client`, `db_session`).
- The reference test pointed to in `agent_docs/testing.md` (once it exists)
  for canonical structure.

If `tests.md` is missing, stop and tell the user to run `/feature-tests` first.

### 3. Decide the test file path

`tests/features/<feature>/<NNNN>_<slice>/<slice>_outside_in_test.py`.

The non-`test_` prefix marks the file as the acceptance test. pytest still
collects it because the filename ends in `_test.py`.

### 4. Generate the Python code

Structure of the produced file:

1. `# FEATURE: <slice> — outside-in acceptance test.` header on line 1.
2. Imports: `pytest`, `pytest_asyncio` is implicit, `httpx` types if needed
   for assertions, mock paths for any mocked external boundaries. Do **not**
   import the slice's use-case, adapter, or port (the test goes through HTTP).
3. Mock setup helpers if any external boundaries need patching. Use
   `mocker.patch(...)` from the `mocker` fixture.
4. One `async def test_<short_name>(...)` per scenario in tests.md, in the
   same order. Each function uses the `@pytest.mark.asyncio` marker.
5. For each scenario: setup (seed rows via fixtures or `db_session`,
   configure mocks), act (HTTP call via `client`), expect (assertions on
   status, response JSON, DB state).

Example skeleton:

```python
# FEATURE: create_user — outside-in acceptance test.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio


async def test_create_user_happy_path(client: AsyncClient, db_session):
    response = await client.post(
        "/api/v1/users",
        json={"username": "alice", "email": "a@b.c", "password": "Pa$$w0rd"},
    )

    assert response.status_code == 201
    body = response.json()
    assert body["username"] == "alice"
    assert body["is_superuser"] is False
    assert "id" in body

    # DB assertion
    result = await db_session.execute(
        text("SELECT username FROM users WHERE username = :u"),
        {"u": "alice"},
    )
    row = result.first()
    assert row is not None


async def test_create_user_duplicate_username(client: AsyncClient, db_session, _seeded_alice):
    response = await client.post(
        "/api/v1/users",
        json={"username": "alice", "email": "other@b.c", "password": "Pa$$w0rd"},
    )

    assert response.status_code == 409
    assert response.json() == {"error": {"code": "duplicatevalue", "message": "Username or email already taken"}}
```

Notes on the code:

- Use the `client` and `db_session` fixtures from `tests/conftest.py`.
- For slice-specific seeding fixtures (like `_seeded_alice` above), declare
  them in the slice's `tests/features/<resource>/<NNNN>_<slice>/conftest.py`.
- DB assertions use raw SQL through `db_session.execute(text(...))` to avoid
  importing ORM models in the test (keeps the test as black-box as possible).
- No `getIt` equivalent here; the DI container is already set up by the
  `app` fixture chain.

### 5. Verify the test is RED

After writing the Python file:

1. Run `pytest <path-to-the-test-file> -v` and capture the output.
2. Verify the test **fails**. Acceptable kinds of failure:
   - **Import error** because the slice's router/adapter does not exist yet.
     This is the expected red state at the start of TDD on a new slice.
   - **404 or 405** because the route is not registered. Also expected.
   - **AssertionError** because the response is wrong (e.g. some stub exists
     but logic is incomplete). Expected when the slice has skeletons.

If the test **passes**: something is wrong. Either the slice is already
implemented (and this is not a fresh red), or the test does not actually
check what it should. Stop and tell the user — do not declare red.

If the test fails with a **fixture error**, **conftest error**, **DB
connection error**, or any **environment problem**: this is not an acceptable
red. Fix the test or the fixture, do not ship it. The red must be from
missing **implementation**, not from a broken test.

### 6. Report

Output to the user, in this exact order:

1. **Path of the new test file.**
2. **Each scenario from tests.md**, mapped to its `test_<name>` function.
3. **Exact failure mode** (import error / 404 / assertion / etc.) with a
   one-line excerpt from the pytest output.
4. **Confirmation** that the test is in the expected red state.
5. **The implementation prompt block** described below.

### The implementation prompt block

The next session — implementation — is a separate conversation. To save the
user from re-typing the same prompt every slice, output a ready-to-copy
block at the end of the report. The user copies the text between the
separator lines, clears context, opens a new chat, and pastes.

Output the block **verbatim** in this shape, replacing `<feature>`,
`<NNNN>`, `<slice>` with concrete values for the slice you just produced
the test for:

```
─────────────────────────────────────────────────────────────────
COPY THIS PROMPT FOR THE IMPLEMENTATION SESSION
─────────────────────────────────────────────────────────────────

Implement slice <slice>. All specs and the test are already ready.

Sources (read in this order):
- specs/features/<feature>/<NNNN>_<slice>/plan.md
- specs/features/<feature>/<NNNN>_<slice>/requirements.md
- specs/features/<feature>/<NNNN>_<slice>/tests.md
- specs/features/<feature>/<NNNN>_<slice>/validation.md

Acceptance gate:
- tests/features/<feature>/<NNNN>_<slice>/<slice>_outside_in_test.py
  must turn GREEN.
- Do not touch the test file or conftest.py. If the test fails due to a bug
  in the implementation — fix the implementation, not the test.
- If the test fails due to a defect in the test itself — stop and ask,
  do not silently fix it.

Once the outside-in test is green — write the missing unit tests per the
plan (see plan.md section "Tests planned" and agent_docs/testing.md).

Quality gates before completion:
- ruff format src/app tests
- ruff check src/app tests
- mypy src/app
- pytest
- Architecture contracts: find and run the import-linter using .importlinter config

All must pass with no new warnings.

─────────────────────────────────────────────────────────────────
```

Rules for the block:

- **Exact paths**, not placeholders. By the time you produce this block
  you already know `<feature>`, `<NNNN>`, `<slice>` — substitute them.
- **No Markdown formatting** inside the block (no headers, no bold). The
  user pastes it raw into the next chat; Markdown would render
  inconsistently and might be misinterpreted.
- **One copy of the block per run.** Do not output it twice. Do not
  output it partially.
- **English wording** throughout the block.
- The block goes **last** in your reply. Nothing after it.

If for any reason the test is **not** in a verified red state (passing, or
failing on a fixture/environment error), do **not** output the
implementation prompt block. The block presupposes a valid red state;
emitting it on a broken test would mislead the user into starting
implementation against a test that does not actually represent the
contract.

## Style rules

- **English only** in test names, docstrings, and comments.
- **One `async def test_...` per scenario** in tests.md, named after the
  scenario heading (snake_case).
- **`pytestmark = pytest.mark.asyncio`** at module level to mark all tests
  async (avoids the per-function decorator).
- **No imports of the slice's internals** (use-case, adapter, port). The
  test exercises HTTP only.
- **DB assertions through raw SQL**, not through ORM model imports.
- **Imports sorted** per Ruff defaults.

## Hard limits

- ❌ Generating a test that passes. The whole point is red.
- ❌ Calling the use-case directly instead of going through HTTP. Outside-in
  means the boundary is HTTP for this project.
- ❌ Mocking the slice's adapter, port, or use-case. Wired real.
- ❌ Skipping the `pytest` run. The skill is not complete until the red state
  is observed and reported.
- ❌ Saving the test outside the slice's test folder.

## Common mistakes

- ❌ Forgetting `pytestmark = pytest.mark.asyncio`. The test silently passes.
- ❌ Asserting on the `client` fixture as if it were the app. The client is
  the HTTP client; assertions are on response objects.
- ❌ Constructing `AsyncClient` inside the test instead of using the `client`
  fixture. The fixture has DI overrides configured; a fresh client does not.
- ❌ Forgetting to await `db_session.execute(...)`. Async ORM calls must be
  awaited.
- ❌ Using `assert response.status == 201` instead of `response.status_code`.
- ❌ DB assertion that imports the ORM model and uses
  `db_session.scalar(select(User).where(...))`. This couples the test to
  internal ORM details; use raw SQL via `text(...)` for black-box checks.
- ❌ Reporting "test is red" without showing the failure mode. The kind of
  failure (import error vs assertion) tells the user where to start
  implementing.
