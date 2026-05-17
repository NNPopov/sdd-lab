# STABLE vs FEATURE headers

This document is the reference for the file-header convention that distinguishes
the **infrastructure skeleton** from the **AI-changeable surface**. Read it
whenever you create a new `.py` file or before modifying any existing file.

## The two header types

Every Python file in `src/app/` starts with **one** of these two headers on
**line 1**:

```python
# STABLE: <module description>. Change only when infrastructure changes.
```

```python
# FEATURE: <slice-name> — <file purpose>.
```

The header is mandatory. Files without a header are out of contract and treated
as suspicious during review.

## Why the convention exists

When an AI agent edits code, it needs a signal at the file level for "this is
safe to change" vs "do not touch unless explicitly asked." Type hints and folder
structure communicate part of that, but not all. The header is a one-line
contract:

- `# STABLE:` — this file is part of the skeleton. Changing it affects the
  whole app. Modifications require explicit user approval, never autonomous
  rewrites.
- `# FEATURE: <slice-name>` — this file belongs to a single slice. Changing it
  is part of normal feature work and does not require special approval beyond
  the change itself.

The convention also helps humans: a quick glance at line 1 tells the reader
what they are looking at.

## STABLE file list

The following files and directories are **STABLE**. Treat them as read-only
unless the user explicitly asks for an infrastructure change.

```
src/app/main.py
src/app/bootstrap/factory.py
src/app/bootstrap/container.py
src/app/bootstrap/router.py                  # see exception below
src/app/domain/errors.py
src/app/domain/shared/**
src/app/ports/**
src/app/adapters/db/base.py
src/app/adapters/db/session.py
src/app/adapters/db/mixins.py
src/app/adapters/db/models/**                # adding a model = STABLE change
src/app/adapters/cache/**
src/app/adapters/queue/**
src/app/adapters/http/exception_handlers.py
src/app/adapters/http/middleware/**
src/app/core/**
src/app/shared_dependencies.py
src/app/admin/**
tests/conftest.py
```

### The one exception: `bootstrap/router.py`

`bootstrap/router.py` is STABLE in the sense that its structure is fixed, but
**adding a single line that registers a new feature router is permitted**
during a normal feature-addition flow. No special approval is needed for that
line. Any change beyond registering a router (reordering, removing,
restructuring) does require approval.

The same exception applies to `adapters/db/models/__init__.py`: adding an
import for a new ORM model is permitted as part of feature work. Anything else
in that file is STABLE.

## FEATURE file list

Everything under `src/app/features/` is FEATURE. Every new file in a slice
must carry the header:

```python
# FEATURE: create_user — use case.
# FEATURE: create_user — adapter.
# FEATURE: create_user — router.
# FEATURE: create_user — request/response schemas.
# FEATURE: users._shared — User domain entity.
```

The `<slice-name>` is the use-case folder name (`create_user`, `list_users`).
For shared files inside a feature's `_shared/`, use the form
`<resource>._shared`. The purpose suffix after `—` is free-form, kept short.

## When to convert FEATURE to STABLE

A FEATURE file may earn promotion to STABLE if and only if **all three**
conditions hold:

1. Three or more slices already depend on it.
2. Its interface has been stable for at least four weeks of development.
3. The promotion is recorded in a brief ADR under `docs/adr/` documenting the
   decision and the date.

Without all three, the file stays FEATURE and is duplicated as needed.
Premature promotion creates a STABLE file that turns out to need frequent
changes, which then erodes the meaning of the STABLE label.

## When a STABLE change is unavoidable

Some changes are genuinely infrastructure-level: adding a new `DomainError`
subclass, adding a new ORM mixin, changing the session factory configuration.
For these:

1. The user must explicitly request or approve the change.
2. The change is made in isolation, in its own commit.
3. The PR description names the STABLE file(s) changed and the reason.

An agent should never modify a STABLE file as a side effect of feature work.
If a feature seems to require a STABLE change, stop and ask the user.

## How to detect missing or wrong headers

A simple lint can enforce this:

```python
# scripts/check_headers.py — runs in CI
import sys
from pathlib import Path

STABLE_PREFIX = "# STABLE:"
FEATURE_PREFIX = "# FEATURE:"
EXCLUDE = {"__init__.py"}  # empty __init__.py is allowed without header

def main() -> int:
    bad: list[str] = []
    for path in Path("src/app").rglob("*.py"):
        if path.name in EXCLUDE and path.stat().st_size == 0:
            continue
        first_line = path.read_text(encoding="utf-8").splitlines()[:1]
        if not first_line:
            bad.append(f"{path}: empty file")
            continue
        line = first_line[0].strip()
        if not (line.startswith(STABLE_PREFIX) or line.startswith(FEATURE_PREFIX)):
            bad.append(f"{path}: missing STABLE/FEATURE header on line 1")
    if bad:
        print("\n".join(bad))
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

Adding this script in CI catches missed headers early.

## Common mistakes

- ❌ A new file in `features/` with `# STABLE:`. The header is wrong; correct
  it to `# FEATURE: <slice> — <purpose>`.
- ❌ A new file in `adapters/` with `# FEATURE:`. The header is wrong; correct
  it to `# STABLE: ...`.
- ❌ Header on line 2 because of a `from __future__ import annotations` on
  line 1. The header must be on line 1; the future import goes on line 2.
- ❌ Header reads `# STABLE: <feature> — <purpose>`. The dash and slice name
  form is reserved for FEATURE headers. STABLE headers describe the module,
  not a feature.
- ❌ Editing a STABLE file without user approval because "it was just one
  line." Even one-line changes to `domain/errors.py` or `core/config.py`
  require explicit approval.
- ❌ Adding a new `DomainError` subclass inside a feature folder. All domain
  errors live in `app/domain/errors.py` (STABLE) and changes go through the
  approval path.
