---
name: spec-workflow
description: This skill should be used when the user references slice spec work, mentions a slice folder (specs/features/...), asks "what's next" on a slice, or invokes the spec chain. It auto-loads the architectural context, inspects the current slice folder, determines which stage the slice is in, and advises which command to run next. This skill advises only; it does not write spec files itself.
disable-model-invocation: false
---

# spec-workflow

Dispatcher for the slice spec chain. Reads the architectural context, inspects
the slice folder state, and tells the user which command to run next. Does not
produce spec files.

## When to trigger

- User mentions a slice by name, by folder path, or by feature/operation pair.
- User asks "what's next" on a slice.
- User invokes the spec chain without a specific command (e.g. "start working
  on delete_post").
- User references `specs/features/...`.
- User talks about implementing a slice and the slice has no `tests.md` yet.

Do not trigger on pure implementation questions ("how do I write the
adapter?"). Those go to `agent_docs/architecture.md` and `error_handling.md`
directly.

## Process

### 1. Load context (mandatory)

Read these files before doing anything else:

- `CLAUDE.md`
- `agent_docs/architecture.md`
- `agent_docs/error_handling.md`
- `agent_docs/spec_workflow.md`
- `agent_docs/stable_vs_feature.md`

These are always read together. If any is missing, stop and ask the user.

### 2. Find the target slice

Determine the slice in this order:

1. If the user named a slice path (`specs/features/users/0003_delete_user/`),
   use it.
2. If the user named a feature/operation pair ("delete_user"), search
   `specs/features/*/` for a matching folder and use it.
3. If the user just said "next" or "current," use the slice whose folder has
   the most recently modified file under `specs/features/*/*/`.
4. If ambiguous, list the candidates and ask.

If no matching slice folder exists, treat the request as "new slice" — the
next step is `/to-prd`.

### 3. Inspect state

Determine which of these states the slice is in:

| State | Files present (in slice folder) | Outside-in test file |
|---|---|---|
| Empty | none | absent |
| Started | `prd.md` only | absent |
| Planned | `prd.md`, `plan.md` | absent |
| Formalized | + `requirements.md` | absent |
| Validated | + `validation.md` | absent |
| Test-specified | + `tests.md` (all five .md) | absent |
| Red gate set | all five .md | present (assumed RED) |
| Complete | all five .md | present (assumed GREEN) |

Conditionally read `agent_docs/testing.md` if state is at or beyond Validated.
Conditionally read `agent_docs/entry_points/fastapi.md` if the slice has an
HTTP entry point (almost always true).

### 4. Advise

Reply with three things:

1. **Current state** of the slice, named (e.g. "Planned").
2. **Recommended next command**, in backticks.
3. **One sentence** of context for the user (what the next command will produce
   and roughly how long it will take).

Example reply:

> The slice `specs/features/posts/0004_delete_post/` is in state **Planned**.
> Next step: `/feature-requirements`. This will produce `requirements.md` with
> functional and non-functional requirement IDs, tracing back to the PRD.

For state **Red gate set**, the next step is not a command but
implementation:

> The slice is in state **Red gate set**. The outside-in test at
> `tests/features/posts/0004_delete_post/delete_post_outside_in_test.py` is
> RED. Next step: implement the slice (domain → data → presentation) until
> that test turns GREEN.

For state **Complete**, advise on follow-up unit tests per
`agent_docs/testing.md`.

### 5. Stop

Do not execute the recommended command. The user issues it. This skill
advises only.

## Hard limits

- ❌ Writing or modifying any file under `specs/`.
- ❌ Writing or modifying any file under `src/app/` or `tests/`.
- ❌ Running shell commands (`pytest`, `alembic`, `ruff`).
- ❌ Invoking other spec-stage skills (`/to-prd`, `/feature-spec`, etc.) on
  the user's behalf.

This skill is read-only and advisory.

## What this skill is NOT

- Not a producer. It does not create spec files.
- Not a tester. It does not run tests.
- Not a planner. It picks the next command from a fixed table based on the
  slice's state.

## Common mistakes

- ❌ Treating a slice with `prd.md` only as "Complete" because the folder
  exists. State depends on the **files inside** the folder, not on the folder
  itself.
- ❌ Recommending `/to-prd` for an existing slice. `/to-prd` is for **new**
  slices and creates the folder.
- ❌ Failing to mention the outside-in test file when advising about a slice
  in state Red gate set or Complete. The test file is part of the slice state.
- ❌ Skipping the architectural-context read in step 1. Without it, the
  advice may contradict project rules.
