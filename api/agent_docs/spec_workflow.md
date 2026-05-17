# Spec workflow

This document is the reference for the process around the slice spec chain.
Read it whenever you generate, read, or modify a spec file (prd.md, plan.md,
requirements.md, validation.md, tests.md).

For the architecture rules that the specs describe, see
`agent_docs/architecture.md`. For the commands that produce each file, see the
corresponding skills in `.claude/skills/`.

## Mindset: why specs are written in five steps

A slice spec is built up in five passes, each with its own focus and own input
set. Mixing focuses produces sloppy specs, so the order matters.

**Pass 1 — Requirements gathering (PRD).** What the system should do, from the
user's perspective. No technical details. No mention of layers, ports, or
adapters. Output: `prd.md`. Tool: `/to-prd`.

**Pass 2 — Architectural review.** Read the existing architecture and check:
does the new behavior fit existing patterns? Are there similar slices to use as
references? Is anything genuinely new? This is the **mental** step before
writing the plan; it does not produce a file. What it produces is **confidence**
that the plan can be written, or a **stop signal** that the team needs to
discuss something new.

**Pass 3 — Implementation plan.** How the requirements get implemented inside
the existing architecture. Specific files, specific signatures, specific
decisions. Output: `plan.md`. Tool: `/feature-spec`.

**Pass 4 — Formalization.** Turn the PRD and plan into formal, traceable
artifacts. Functional and non-functional requirements with IDs. Manual test
scenarios and code review checklist. Outputs: `requirements.md`,
`validation.md`. Tools: `/feature-requirements`, `/feature-validation`.

**Pass 5 — Outside-in test specification and red.** Define the single
integration test that proves the slice works end-to-end, first as markdown
(`tests.md`), then as failing Python code (`<slice>_outside_in_test.py`). The
red test is the **acceptance gate** for the implementation that follows.
Outputs: `tests.md`, `<slice>_outside_in_test.py` (RED). Tools:
`/feature-tests`, `/slice-test-red`.

The reason this is five steps and not one is the **mindset shift between
them**. You cannot write requirements while thinking about implementation.
You cannot write a plan while thinking about user stories. You cannot write the
red test without knowing the public surface from the plan. The five-step
rhythm forces each mindset to do its work cleanly.

## Always-read context

Every spec-stage skill loads this context before producing anything:

- `CLAUDE.md` — universal rules and forbidden lists.
- `agent_docs/architecture.md` — slice anatomy, layer rules, naming.
- `agent_docs/error_handling.md` — DomainError hierarchy, adapter pattern.
- `agent_docs/spec_workflow.md` — this file.
- `agent_docs/stable_vs_feature.md` — header convention.

If any of these is missing or empty, stop and ask the user before proceeding.

## Conditionally-read context

Read these only when relevant to the slice:

- `agent_docs/testing.md` — for `/feature-validation`, `/feature-tests`,
  `/slice-test-red`, or any plan that needs to describe tests.
- `agent_docs/entry_points/fastapi.md` — for any slice that has an HTTP entry
  point (almost all current slices).
- `specs/features/<feature>/<NNNN>_<reference>/` — read the most relevant
  existing slice as the reference for naming, structure, and idioms (see next
  section).

## Reference slice

Each spec-stage skill picks a **reference slice** — an existing slice with the
same operation shape — and reads its `plan.md` for context. The reference is
not copied; it sets the bar for naming, structure, and idiomatic patterns the
new slice should match.

Examples of operation-shape matching:

- New slice is `delete_post` → reference `delete_tier` if it exists.
- New slice is `list_orders` → reference `list_users` or `list_posts`.
- New slice is `create_subscription` → reference `create_user`.

If no operation-shape match exists in the codebase, the skill announces this
explicitly and asks the user whether to proceed without a reference. Producing
a slice without a reference is allowed but should be explicit, because the
first slice of a new pattern sets the template for everyone after.

## When you encounter a pattern that does not exist yet

If during planning you notice a recurring need that has no existing solution
(e.g. a generic pagination helper, a soft-delete pattern), do **not** invent
the pattern inside the slice. Stop, surface the question to the user, and
let them decide whether to introduce a new STABLE component or live with
duplication for now.

This is the single most important guard against architectural drift in
AI-assisted development.

## State of the slice folder: how to read it

A slice folder lives at `specs/features/<feature>/<NNNN>_<slice>/`. Its state
at any moment is one of these:

| State | Files present (in slice folder) | Outside-in test file | What's next |
|---|---|---|---|
| Empty / not created | none | absent | Run `/to-prd` to start |
| Started | `prd.md` only | absent | Run `/feature-spec` |
| Planned | `prd.md`, `plan.md` | absent | Run `/feature-requirements` |
| Formalized | `prd.md`, `plan.md`, `requirements.md` | absent | Run `/feature-validation` |
| Validated | + `validation.md` | absent | Run `/feature-tests` |
| Test-specified | all five `.md` files | absent | Run `/slice-test-red` |
| Red gate set | all five `.md` files | present and RED | Implement the slice |
| Complete | all five `.md` files | present and GREEN | Ready for unit-test pass and merge |

The `/spec-workflow` skill checks this state and tells the user the next step.
It does not run the next step itself — the user always issues the command.

## Hard limits for `/grill-me`

`/grill-me` is the optional discovery interview that a user may run **before**
`/to-prd`. Its only legitimate output is **the conversation itself** — a series
of questions, the user's answers, and a final summary in the chat.

The skill description (which may come from a third-party source) might be
vague about boundaries. The boundaries below are mandatory regardless of how
that description is worded; they apply whenever `/grill-me` is in use within
this project:

- ❌ Editing source files in `src/app/` — anything at all.
- ❌ Editing test files in `tests/`.
- ❌ Running `pytest`, `ruff`, `mypy`, `alembic`, or any other shell command.
- ❌ Creating, modifying, or deleting any file under `specs/` — including
  `prd.md`, `plan.md`, `requirements.md`, `validation.md`, `tests.md`, or
  `roadmap.md`.
- ❌ Creating any folder anywhere in the repo.

What `/grill-me` **may** do:

- Read existing source files to inform the questions it asks (read-only).
- Read existing spec files for the same reason.
- Ask the user clarifying questions, one at a time, with a recommended answer.
- After all branches of the decision tree are resolved, output a one-screen
  summary of decisions reached, ending with a single line: **"Next step:
  /to-prd"**.

The skill must not invoke `/to-prd` itself. The user runs the next command
when they choose. This preserves the "advise, don't act" principle that all
spec-stage skills follow in this project.

If at any point during a `/grill-me` session the user's answer triggers an
instinct to "just do it now" — stop. Finish the interview with a summary. The
user's "Ok" to a proposed answer is consent for **the answer**, not consent to
start implementing.

## Roadmap ownership

`specs/roadmap.md` is a flat list of every slice in the project with its
state. **It is owned by `/to-prd`.** Only `/to-prd` writes to it. Every other
skill may read it for context (to pick the next `NNNN` number, to find the
reference slice) but must not modify it.

`NNNN` numbering is **global**, not per-feature. The next slice across the
whole project gets `max(NNNN) + 1`. This makes the roadmap a single sortable
timeline rather than a per-feature ledger.

## Language and tone

All generated spec artifacts are written in **English**, regardless of the
conversation language. The conversation may be in any language; the files
themselves are English so they remain readable when shared, reviewed, or
machine-processed.

## Common workflow mistakes

- ❌ Running `/feature-spec` before `/to-prd`. The plan has no PRD to draw
  from and will invent its own user stories.
- ❌ Skipping `/feature-requirements` and going straight to
  `/feature-validation`. The validation cannot trace back to formal
  requirements, and the manual checklist drifts from the contract.
- ❌ Writing `tests.md` before `validation.md`. The test scenarios then
  duplicate the manual scenarios poorly.
- ❌ Producing all five files in a single tool call. Each pass requires its
  own mindset; merging them produces shallow output across the board.
- ❌ A skill writing to `roadmap.md` other than `/to-prd`. The roadmap then
  has multiple authors and inconsistent format.
- ❌ Implementing the slice before `/slice-test-red` produces a verified red
  test. Without the red test, "done" has no objective definition.
