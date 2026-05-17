---
name: project-memory
description: This skill should be used when the user asks about the project's history, asks where a decision is recorded, or wants to know how to record a new one. It points to the roadmap, ADRs, and per-slice spec folders as the project's three forms of memory, and explains who writes to each.
disable-model-invocation: false
---

# project-memory

Reference for the project's persistent memory: roadmap, ADRs, and per-slice
spec folders. These three together are the single source of truth for "what
exists, why, and when."

## When to trigger

- User asks "where do we record this decision?"
- User asks "what was decided about X?"
- User asks "how do I see the list of slices?"
- User mentions the roadmap or an ADR.

## The three layers

### Layer 1: `specs/roadmap.md`

A flat list of every slice in the project, with state.

- **Owned by `/to-prd`.** No other skill writes to it.
- Format: a markdown table, one row per slice, columns `NNNN | feature |
  slice | state | created | notes`.
- `NNNN` is global (max+1 across the whole project), zero-padded.
- States match the spec workflow: Started, Planned, Formalized, Validated,
  Test-specified, Red gate set, Complete.

Read it to:

- Find the next `NNNN`.
- Find a reference slice of the same operation shape.
- See what is in flight.

Do not edit it directly. Run `/to-prd` for new slices; later `/to-prd`
invocations update the row state too (see that skill).

### Layer 2: `specs/features/<feature>/<NNNN>_<slice>/`

A folder per slice with five markdown files: `prd.md`, `plan.md`,
`requirements.md`, `validation.md`, `tests.md`. Plus, outside `specs/`, the
outside-in test file `tests/features/<feature>/<NNNN>_<slice>/<slice>_outside_in_test.py`.

Each file is owned by exactly one skill:

| File | Owner |
|---|---|
| `prd.md` | `/to-prd` |
| `plan.md` | `/feature-spec` |
| `requirements.md` | `/feature-requirements` |
| `validation.md` | `/feature-validation` |
| `tests.md` | `/feature-tests` |
| `*_outside_in_test.py` | `/slice-test-red` |

Read these to:

- Reconstruct why a slice was built the way it was.
- Find the requirements traceability for a bug or a regression.
- Use a recent slice as a reference for a new similar slice.

### Layer 3: `docs/adr/`

Architecture Decision Records. One file per cross-cutting decision that
affects multiple slices or stable infrastructure.

ADRs are written when:

- A STABLE file is changed (new `DomainError` subclass, new ORM mixin, etc.).
- A FEATURE file is promoted to STABLE (see `agent_docs/stable_vs_feature.md`).
- A library or framework decision is changed (e.g. swapping DI library).
- A pattern is introduced that does not yet exist (the spec workflow document
  flags this as a stop-and-ask moment).

Format: short, plain English. Standard ADR template (context, decision,
consequences). Numbered `ADR-NNN-short-name.md`.

ADRs are written by the user, optionally with Claude's help. There is no skill
that owns ADRs because they are rare and irregular.

## How to find something

| Question | Where to look |
|---|---|
| What slices exist in the project? | `specs/roadmap.md` |
| Why was slice X built? | `specs/features/<feature>/<NNNN>_<slice>/prd.md` |
| How was slice X implemented? | `specs/features/<feature>/<NNNN>_<slice>/plan.md` |
| What does slice X promise to do? | `specs/features/<feature>/<NNNN>_<slice>/requirements.md` |
| How do we verify slice X manually? | `specs/features/<feature>/<NNNN>_<slice>/validation.md` |
| What is the acceptance test for slice X? | `tests/features/<feature>/<NNNN>_<slice>/<slice>_outside_in_test.py` |
| Why was the DI library chosen? | `docs/adr/` |
| Why is X marked STABLE? | `docs/adr/` (if promoted from FEATURE) or `agent_docs/stable_vs_feature.md` |

## Hard rules

- ❌ Writing to `specs/roadmap.md` from any skill other than `/to-prd`.
- ❌ Skipping a spec layer for a slice ("just plan and code, skip
  requirements"). Every slice has all five files. Optionality is decided per
  slice in `plan.md`, not by skipping files.
- ❌ Recording cross-cutting decisions inside a slice folder. Cross-cutting
  decisions go in an ADR; the slice references the ADR.
- ❌ Editing past spec files to retroactively change history. Past spec
  files are immutable once the slice is Complete. If something needs to
  change, the slice is reopened (new modification flow per `CLAUDE.md`).

## Common mistakes

- ❌ Hunting for "the architecture document" in the project root. The
  architecture lives in `agent_docs/architecture.md`; the project root has
  `CLAUDE.md` (universal rules) and `README.md` (how to run).
- ❌ Looking for a slice in `src/app/features/` to understand "why." The
  source code answers "how," not "why." Read `prd.md` for "why."
- ❌ Creating an ADR for a single slice's decision. Slice-local decisions go
  in `plan.md`. ADRs are for decisions that affect multiple slices.
