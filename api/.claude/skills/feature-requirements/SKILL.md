---
name: feature-requirements
description: This skill should be used when the user wants to generate requirements.md for a slice. Trigger when the user invokes /feature-requirements, says "formalize the requirements", or asks for the F/N traceability after plan.md exists. Reads prd.md and plan.md. Produces requirements.md only — formal functional (F) and non-functional (N) requirements with IDs that the validation and tests phases trace back to.
disable-model-invocation: false
---

# feature-requirements

Generate `requirements.md` for a slice. Translates the PRD and plan into
formal, ID-bearing requirements that downstream documents (`validation.md`,
`tests.md`, and code review) can reference.

## Process

### 1. Find the target slice

Same determination as in `/feature-spec`:

1. User-named path.
2. Most recently modified `plan.md` under `specs/features/*/*/`.
3. If ambiguous, ask.

Output: `specs/features/<feature>/<NNNN>_<slice>/requirements.md`.

### 2. Read the inputs

Mandatory:

- The slice's `prd.md`.
- The slice's `plan.md`.
- `CLAUDE.md`.
- `agent_docs/architecture.md`.
- `agent_docs/error_handling.md`.

If `plan.md` is missing, stop and ask the user to run `/feature-spec` first.

### 3. Write `requirements.md`

Use this structure:

```markdown
# NNNN · slice_name — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

Numbered as F1, F2, F3... Each is a single testable statement.

- **F1.** The endpoint `<METHOD> /api/v1/...` accepts `<Slice>Request` with
  fields `<a, b, c>` and returns `<Slice>Response` with status `<code>` on
  success.
- **F2.** The use-case rejects with `ValidationDomainError` when `<field>`
  fails business rule `<X>`.
- **F3.** The use-case rejects with `ForbiddenDomainError` when the acting
  user does not satisfy `<auth predicate>`.
- **F4.** The adapter maps `IntegrityError` (unique violation) to
  `DuplicateValueDomainError`.
- **F5.** The adapter maps `NoResultFound` to `NotFoundDomainError`.
- ...

Cover every branch in the use-case, every infrastructure exception the adapter
maps, every authorization rule, every status code the endpoint can return.

## Non-functional requirements

Numbered N1, N2, N3...

- **N1.** Use-case is a class with `__call__()`; called as
  `await use_case(command)`. Per `agent_docs/architecture.md`.
- **N2.** Adapter catches only business-meaningful infrastructure
  exceptions (e.g. `IntegrityError` → `DuplicateValueDomainError`). Other
  infrastructure exceptions propagate to the global handler per
  `agent_docs/error_handling.md`. The adapter does not log; the global
  handler does.
- **N3.** Pydantic schemas use `model_config = ConfigDict(from_attributes=True)`
  for entities that come from the ORM.
- **N4.** All new files start with `# FEATURE: <slice> — <purpose>`.
- **N5.** No `HTTPException` raised inside the use-case.
- **N6.** No cross-slice imports.
- **N7.** No synchronous DB calls; everything is `async def` + `await`.
- **N8.** mypy strict passes for new code.
- **N9.** Ruff format and lint pass for new code.

The N list is mostly stable across slices. Copy it from the previous slice's
requirements and adjust only what is slice-specific. Do not invent new N
requirements — those belong in `agent_docs/`.

## Out of scope

Bullet list, copied or adapted from `plan.md` section 7.

## Traceability

Mapping from requirement ID to where it is verified.

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test |
| F2, F3 | use-case unit test |
| F4, F5 | adapter unit test |
| F1 (happy path) | outside-in test |
| N1–N9 | code review checklist in validation.md |
```

### 4. Save and confirm

Write to `specs/features/<feature>/<NNNN>_<slice>/requirements.md`. Tell the
user the file was created, list the count of F and N requirements, and suggest:

> Next step: `/feature-validation` to produce validation.md.

## Style rules

- **English only**.
- **One sentence per requirement.** A requirement that needs two sentences is
  two requirements.
- **Concrete identifiers** (class names, file paths, status codes), not
  placeholders.
- **Reference agent_docs** for each N requirement that comes from a project
  rule. The reference is the source of truth; the N entry is just a pointer.
- **Stable N list.** If a non-functional requirement is project-wide, it
  appears in every slice's requirements.md with the same wording. Drift
  between slices is a smell.

## Hard limits

- ❌ Writing any file other than `requirements.md`.
- ❌ Modifying `prd.md`, `plan.md`, or `roadmap.md`.
- ❌ Inventing new architectural rules. If a requirement does not have a
  basis in `agent_docs/`, it does not belong in N. Ask the user.
- ❌ Running shell commands.

## Common mistakes

- ❌ A functional requirement that does not name the operation observably:
  "the use-case handles errors properly." Specify which error, which input,
  which response.
- ❌ A non-functional requirement that is actually a plan detail: "the
  adapter uses SQLAlchemy `select()` syntax." That's implementation, not a
  requirement.
- ❌ Skipping the traceability table. Without it, downstream skills (and
  human reviewers) can't see what verifies what.
- ❌ Requirements that contradict the plan. If `plan.md` says
  `ForbiddenDomainError`, requirements.md cannot say `ValidationDomainError`.
  If you find a contradiction, surface it; do not silently choose.
